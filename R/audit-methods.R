#' Print, summarise and plot an audit
#'
#' `print()` gives the headline numbers. `summary()` gives the reportable
#' verdict: the shifted axes, the multivariate test, the propensity
#' decomposition, the positivity limit, and what each of them licenses you to
#' do. `plot()` shows the two things worth looking at, which are the per-axis
#' shift and the separation of the propensity scores.
#'
#' The verdict is one of:
#'
#' \describe{
#'   \item{`benign`}{No environmental signature of the filter. Filtering and
#'     weighting will agree, and the filtering decision is not carrying your
#'     result.}
#'   \item{`structured`}{The filter moved the niche and positivity supports
#'     undoing it. Fit both ends of the bracket (filtered, and IPW-weighted) and
#'     report the spread.}
#'   \item{`positivity-limited`}{The filter moved the niche, but reweighting is
#'     carried by a handful of records. Global IPW is fragile here. Stratify, or
#'     report the bracket without committing to either end.}
#' }
#'
#' @param x,object An `sdm_audit` object from [audit()].
#' @param n_axes Number of environmental axes to show, ordered by `|smd|`.
#' @param ... Ignored.
#'
#' @return `print()` and `plot()` return their input invisibly. `summary()`
#'   returns an object of class `summary.sdm_audit`.
#' @name sdm_audit_methods
#' @seealso [audit()]
#' @examples
#' d <- sim_occ(n = 400, seed = 1)
#' a <- audit(d,
#'   quality = "keep_precision", env = c("bio1", "bio12", "elev"),
#'   metadata = "source", spatial_block = "basin",
#'   control = audit_control(n_perm = 99, max_n = 200)
#' )
#' a
#' summary(a)
NULL

#' @rdname sdm_audit_methods
#' @export
print.sdm_audit <- function(x, ...) {
  cat("\n<sdm_audit>", "\n")
  cat(sprintf(
    "  %s records, %s retained (%.1f%%) by `%s`\n",
    format(x$n, big.mark = ","), format(x$n_high, big.mark = ","),
    100 * x$prop_high, x$quality
  ))
  cat(sprintf(
    "  energy distance   %.3f   (permutation p = %s, %d perms)\n",
    x$energy$statistic, .fmt_p(x$energy$p_value, x$control$n_perm),
    x$control$n_perm
  ))
  cat(sprintf(
    "  propensity env-AUC %.3f  (%s cross-validation)\n",
    x$propensity$auc_env,
    if (x$blocked) paste0("blocked by `", x$spatial_block, "`") else "random"
  ))
  cat(sprintf(
    "  IPW effective n    %.0f    (%.1f%% of retained records)\n",
    x$positivity$ess, 100 * x$positivity$ess_ratio
  ))
  cat(sprintf("  verdict: %s\n\n", toupper(x$flag)))
  cat("  summary() for the reportable version.\n\n")
  invisible(x)
}

#' @rdname sdm_audit_methods
#' @export
summary.sdm_audit <- function(object, n_axes = 6L, ...) {
  s <- list(
    n = object$n,
    n_high = object$n_high,
    prop_high = object$prop_high,
    n_incomplete = object$n_incomplete,
    quality = object$quality,
    blocked = object$blocked,
    spatial_block = object$spatial_block,
    flag = object$flag,
    axes = utils::head(object$shift, n_axes),
    energy = object$energy,
    propensity = object$propensity,
    positivity = object$positivity,
    control = object$control,
    has_metadata = !is.null(object$metadata)
  )
  class(s) <- "summary.sdm_audit"
  s
}

#' @rdname sdm_audit_methods
#' @export
print.summary.sdm_audit <- function(x, ...) {
  ctl <- x$control
  rule <- function() cat(strrep("-", 66), "\n")

  cat("\nAudit of quality filter `", x$quality, "`\n", sep = "")
  rule()
  cat(sprintf(
    "%s records with complete environment; %s retained (%.1f%%).",
    format(x$n, big.mark = ","), format(x$n_high, big.mark = ","),
    100 * x$prop_high
  ), "\n")
  if (x$n_incomplete > 0) {
    cat(sprintf(
      "%s records dropped for missing environmental values.\n",
      format(x$n_incomplete, big.mark = ",")
    ))
  }

  cat("\n1. Which axes moved\n")
  ax <- x$axes
  for (i in seq_len(nrow(ax))) {
    cat(sprintf(
      "   %-16s smd %+6.3f   KS %5.3f   log-var-ratio %+6.3f%s\n",
      ax$variable[i], ax$smd[i], ax$ks[i], ax$log_vr[i],
      if (abs(ax$smd[i]) >= ctl$smd_threshold) "  *" else ""
    ))
  }
  cat(sprintf(
    "   (* |smd| >= %.2f. Positive smd: retained records sit HIGHER on that axis.)\n",
    ctl$smd_threshold
  ))

  cat("\n2. Did the niche move at all\n")
  cat(sprintf(
    "   energy distance %.3f, permutation p = %s (%d permutations, n = %d per sample)\n",
    x$energy$statistic, .fmt_p(x$energy$p_value, ctl$n_perm),
    x$energy$n_perm, x$energy$n_subsample
  ))
  if (isTRUE(x$energy$p_value <= 1 / (ctl$n_perm + 1))) {
    cat("   NOTE: p is at the resolution floor of the permutation test. Raise `n_perm`\n")
    cat("         before reporting this number, or you are reporting the test, not the data.\n")
  }

  cat("\n3. Is the structure environmental, or is it provenance\n")
  cat(sprintf("   env-AUC          %.3f", x$propensity$auc_env))
  cat(sprintf(
    "   (%s CV; 0.5 = retention is environmentally unstructured)\n",
    if (x$blocked) paste0("blocked by `", x$spatial_block, "`") else "random"
  ))
  if (x$has_metadata) {
    cat(sprintf("   metadata-AUC     %.3f   (usually high: the filter was DEFINED on metadata;\n", x$propensity$auc_meta))
    cat("                            this is a sanity check, not a finding)\n")
    cat(sprintf("   env + metadata   %.3f\n", x$propensity$auc_both))
    cat(sprintf(
      "   incremental env  %+.3f  (environmental structure surviving provenance)\n",
      x$propensity$auc_incremental
    ))
  } else {
    cat("   metadata-AUC     not computed: no `metadata` supplied, so an environmental\n")
    cat("                    shift cannot be separated from a provenance artefact here.\n")
  }

  cat("\n4. Can it be undone\n")
  cat(sprintf(
    "   IPW effective sample size %.0f = %.1f%% of the retained records\n",
    x$positivity$ess, 100 * x$positivity$ess_ratio
  ))
  cat(sprintf(
    "   the same, without trimming:  %.0f = %.1f%%\n",
    x$positivity$ess_untrimmed, 100 * x$positivity$ess_ratio_untrimmed
  ))
  if (x$positivity$ess_ratio > 3 * x$positivity$ess_ratio_untrimmed) {
    cat("   NOTE: trimming is holding this number up. Untrimmed, the correction rests\n")
    cat("         on very few records. Report which of the two you mean.\n")
  }
  cat(sprintf(
    "   lowest retention probability among retained records: %.4g\n",
    x$positivity$min_e_high
  ))

  rule()
  cat("VERDICT: ", toupper(x$flag), "\n", sep = "")
  cat(strwrap(.advice(x$flag), width = 66, prefix = "  "), sep = "\n")
  rule()
  cat("These thresholds are conventions, not truths (see audit_control).\n")
  cat("Report the numbers, not only the verdict.\n\n")
  invisible(x)
}

#' @noRd
.advice <- function(flag) {
  switch(flag,
    "benign" = paste(
      "The filter left no environmental signature this audit can resolve.",
      "Filtering and inverse-propensity weighting will point the same way,",
      "so the filtering decision is not carrying your result. Note that a",
      "null here is a failure to resolve structure, not a proof of its",
      "absence: with few spatial blocks it is a cross-validation null."
    ),
    "structured" = paste(
      "The filter moved the niche, and positivity supports undoing it.",
      "Fit both ends of the bracket -- the filtered model, and the same",
      "model with ipw_weights() -- and report the spread. They move the",
      "niche in opposite directions and which end is correct depends on",
      "whether coordinate error is directed, which your data cannot tell",
      "you. A conclusion that survives the whole bracket is safe; one that",
      "does not is a choice you made, not a result you found."
    ),
    "positivity-limited" = paste(
      "The filter moved the niche, but reweighting is carried by a small",
      "number of records: there are environments the filter emptied, and",
      "no weight can conjure records back into them. Global IPW is fragile",
      "here. Stratify the weights, or report the filter-to-IPW bracket",
      "without committing to either end. Do not report a weighted model",
      "alone as if it were the corrected answer."
    ),
    ""
  )
}

#' @noRd
.fmt_p <- function(p, n_perm) {
  if (is.na(p)) {
    return("NA")
  }
  floor_p <- 1 / (n_perm + 1)
  if (p <= floor_p) paste0("<= ", format(floor_p, digits = 2)) else format(p, digits = 3)
}

#' @rdname sdm_audit_methods
#' @export
plot.sdm_audit <- function(x, n_axes = 10L, ...) {
  op <- graphics::par(mfrow = c(1, 2), mar = c(4.2, 8, 3, 1.2))
  on.exit(graphics::par(op), add = TRUE)

  ax <- utils::head(x$shift, n_axes)
  ax <- ax[order(ax$smd), , drop = FALSE]
  thr <- x$control$smd_threshold
  cols <- ifelse(abs(ax$smd) >= thr, "#B03A2E", "#7F8C8D")

  graphics::plot(ax$smd, seq_len(nrow(ax)),
    type = "n", yaxt = "n", ylab = "",
    xlab = "standardized mean difference (retained - all)",
    xlim = range(c(ax$smd, -thr, thr)) * 1.15,
    main = "Which axes moved"
  )
  graphics::abline(v = 0, col = "grey30")
  graphics::abline(v = c(-thr, thr), lty = 3, col = "grey60")
  graphics::segments(0, seq_len(nrow(ax)), ax$smd, seq_len(nrow(ax)), col = cols)
  graphics::points(ax$smd, seq_len(nrow(ax)), pch = 19, col = cols)
  graphics::axis(2, at = seq_len(nrow(ax)), labels = ax$variable, las = 1, cex.axis = 0.8)

  e <- x$propensity$e
  d_hi <- stats::density(e[x$r])
  d_lo <- stats::density(e[!x$r])
  graphics::par(mar = c(4.2, 4.2, 3, 1.2))
  graphics::plot(
    range(c(d_hi$x, d_lo$x)), c(0, max(c(d_hi$y, d_lo$y))),
    type = "n",
    xlab = "fitted P(retained | environment)", ylab = "density",
    main = sprintf("Propensity  (env-AUC %.3f)", x$propensity$auc_env)
  )
  graphics::polygon(d_lo, col = grDevices::adjustcolor("#7F8C8D", 0.35), border = "#7F8C8D")
  graphics::polygon(d_hi, col = grDevices::adjustcolor("#B03A2E", 0.35), border = "#B03A2E")
  graphics::legend("topleft",
    legend = c("discarded", "retained"),
    fill = grDevices::adjustcolor(c("#7F8C8D", "#B03A2E"), 0.35),
    border = c("#7F8C8D", "#B03A2E"), bty = "n", cex = 0.85
  )
  graphics::mtext(
    sprintf(
      "IPW effective n = %.0f (%.1f%% of retained)",
      x$positivity$ess, 100 * x$positivity$ess_ratio
    ),
    side = 1, line = 3, cex = 0.75, col = "grey30"
  )
  invisible(x)
}
