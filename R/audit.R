#' Tuning constants for [audit()]
#'
#' The thresholds below are **conventions, not truths**. They are the
#' conventional cut-offs from the covariate-balance and propensity literature,
#' and they are exposed as arguments precisely because the right value is a
#' property of the study, not of the method. Report the numbers, not only the
#' verdict.
#'
#' @param smd_threshold Absolute standardized mean difference above which an
#'   environmental axis counts as shifted. The 0.1 convention comes from the
#'   propensity-score balance literature (Austin, 2011).
#' @param auc_threshold Out-of-fold AUC of the environmental propensity model
#'   above which retention counts as environmentally structured. 0.5 is
#'   no structure; 0.6 is a deliberately low bar, because in a reliability audit
#'   a false alarm is cheaper than false reassurance.
#' @param alpha Significance level for the energy-distance permutation test.
#' @param ess_threshold Effective sample size, as a fraction of the retained
#'   records, below which inverse-propensity weighting is treated as
#'   positivity-limited: the weights are then carried by a small number of
#'   records and global reweighting is fragile.
#' @param n_perm Permutations for the energy test. The smallest attainable
#'   p-value is `1 / (n_perm + 1)`; keep this well below `alpha` or the test
#'   will report its own resolution floor rather than the evidence.
#' @param max_n Common subsample size for the energy test, which bounds the
#'   \eqn{O(n^2)} pairwise-distance computation.
#' @param k Number of cross-validation folds.
#' @param quadratic Include squared environmental terms in the propensity model.
#'   Keep this on: a filter that trims environmental outliers leaves the mean
#'   untouched and is invisible to a linear propensity model.
#' @param pca Reduce the environmental block by PCA before fitting the
#'   propensity model. Useful when predictors are numerous and collinear, but
#'   conservative: it will tend to understate the environmental signal.
#' @param pca_var Proportion of variance retained when `pca = TRUE`.
#' @param trim Quantiles at which inverse-propensity weights are trimmed.
#' @param reference Reference sample for the energy test: `"all"` (the contrast
#'   a model fitted on filtered data actually experiences) or `"low"` (the
#'   disjoint high-versus-low contrast).
#'
#' @return A list of class `audit_control`.
#' @references
#' Austin, P. C. (2011). An introduction to propensity score methods for
#' reducing the effects of confounding in observational studies.
#' *Multivariate Behavioral Research*, 46(3), 399-424.
#' @export
#' @examples
#' audit_control(n_perm = 199, quadratic = FALSE)
audit_control <- function(smd_threshold = 0.1,
                          auc_threshold = 0.6,
                          alpha = 0.05,
                          ess_threshold = 0.1,
                          n_perm = 999L,
                          max_n = 1500L,
                          k = 5L,
                          quadratic = TRUE,
                          pca = FALSE,
                          pca_var = 0.95,
                          trim = c(0.01, 0.99),
                          reference = c("all", "low")) {
  reference <- match.arg(reference)
  structure(
    list(
      smd_threshold = smd_threshold,
      auc_threshold = auc_threshold,
      alpha = alpha,
      ess_threshold = ess_threshold,
      n_perm = as.integer(n_perm),
      max_n = as.integer(max_n),
      k = as.integer(k),
      quadratic = quadratic,
      pca = pca,
      pca_var = pca_var,
      trim = trim,
      reference = reference
    ),
    class = "audit_control"
  )
}

#' Audit a quality filter for environmental bias
#'
#' `audit()` measures what a quality filter did to the environmental
#' distribution of a set of occurrence records, *before* any model is fitted.
#'
#' @details
#' # The problem
#'
#' Occurrence records are routinely filtered by coordinate accuracy before
#' species distribution modelling, on the tacit assumption that record quality
#' is random with respect to the environment. It usually is not. Georeferencing
#' precision depends on terrain, accessibility, mapping density and the
#' technology of the era, all of which vary across environmental space. When
#' quality is environmentally structured, discarding the low-quality records
#' removes them non-randomly across environmental space, and the distribution
#' the model learns from shifts. Filtering is then not data hygiene but a
#' covariate-shift operation.
#'
#' Writing \eqn{r = 1} for a retained record, the environmental distribution of
#' the retained set relates to the unfiltered one by the retention propensity,
#' \deqn{p_{\mathrm{high}}(e) \propto p_{\mathrm{true}}(e)\, P(r = 1 \mid e),}
#' so filtering is neutral exactly when \eqn{P(r = 1 \mid e)} does not vary with
#' the environment, and inverse-propensity weights \eqn{w = 1 / P(r = 1 \mid e)}
#' undo the selection when it does (Horvitz & Thompson, 1952).
#'
#' # What is reported
#'
#' \describe{
#'   \item{`$shift`}{Per-axis standardized mean differences, KS distances and
#'     log variance ratios: which environmental axes filtering moves, and where
#'     to.}
#'   \item{`$energy`}{A single model-free test of whether the retained records
#'     occupy a different region of environmental space, using the energy
#'     distance (Szekely & Rizzo, 2013) with a permutation test.}
#'   \item{`$propensity`}{Out-of-fold discrimination of retention from the
#'     environment, from metadata, and from both, so that genuinely
#'     environmental structure can be separated from a provenance artefact.}
#'   \item{`$positivity`}{Whether a weighting correction is supported by the
#'     data at all, through the effective sample size of the inverse-propensity
#'     weights.}
#'   \item{`$flag`}{One of `"benign"`, `"structured"` or `"positivity-limited"`.}
#' }
#'
#' # What is *not* reported, and cannot be
#'
#' The audit tells you whether filtering moved the niche and by how much. It
#' cannot tell you which way to correct. Hard filtering and inverse-propensity
#' weighting move the estimated niche in *opposite* directions and bracket the
#' truth between them; which side is right depends on whether coordinate error
#' is directed or merely noisy, and that is not identifiable from occurrence
#' data alone. The honest output of an audit is therefore the width of the
#' bracket, not a point estimate. Treat any tool that hands you one filtered
#' answer, this one included, with that in mind.
#'
#' @param data A data frame of occurrence records, one row per record. No
#'   rasters, no background points and no ground truth are needed.
#' @param quality Name of the retention column: logical or 0/1, `TRUE`/`1` for
#'   records the filter kept. See [as_quality()] for building it from
#'   CoordinateCleaner output or from a continuous coordinate-uncertainty field.
#' @param env Character vector of environmental column names.
#' @param metadata Optional character vector of record-metadata column names
#'   (year, source, collection era, institution, ...). Supplying these is what
#'   lets the audit separate an environmental shift from a provenance artefact.
#' @param spatial_block Optional name of a grouping column (basin, grid cell,
#'   region) used to block cross-validation, so that propensity discrimination
#'   is not inflated by spatial autocorrelation (Roberts et al., 2017).
#' @param control A list from [audit_control()].
#'
#' @return An object of class `sdm_audit`. See [sdm_audit_methods] for
#'   `print()`, `summary()` and `plot()`.
#'
#' @references
#' Horvitz, D. G. & Thompson, D. J. (1952). A generalization of sampling without
#' replacement from a finite universe. *Journal of the American Statistical
#' Association*, 47(260), 663-685.
#'
#' Kish, L. (1965). *Survey Sampling*. Wiley.
#'
#' Roberts, D. R. et al. (2017). Cross-validation strategies for data with
#' temporal, spatial, hierarchical, or phylogenetic structure. *Ecography*,
#' 40(8), 913-929.
#'
#' Szekely, G. J. & Rizzo, M. L. (2013). Energy statistics: a class of statistics
#' based on distances. *Journal of Statistical Planning and Inference*, 143(8),
#' 1249-1272.
#'
#' @seealso [ipw_weights()], [trust_weights()], [as_quality()], [sim_occ()]
#' @export
#' @examples
#' d <- sim_occ(n = 400, seed = 1)
#'
#' # A filter driven by coordinate precision, where precision tracks elevation.
#' a <- audit(
#'   d,
#'   quality = "keep_precision",
#'   env = c("bio1", "bio12", "elev"),
#'   metadata = c("year", "source"),
#'   spatial_block = "basin",
#'   control = audit_control(n_perm = 99, max_n = 200)
#' )
#' a
audit <- function(data,
                  quality,
                  env,
                  metadata = NULL,
                  spatial_block = NULL,
                  control = audit_control()) {
  stopifnot(is.data.frame(data))
  if (!inherits(control, "audit_control")) {
    stop("`control` must come from audit_control().", call. = FALSE)
  }
  .need_cols(data, quality, "quality")
  .need_cols(data, env, "env")
  if (!is.null(metadata)) .need_cols(data, metadata, "metadata")
  if (!is.null(spatial_block)) .need_cols(data, spatial_block, "spatial_block")
  if (length(env) < 1L) stop("`env` must name at least one column.", call. = FALSE)

  r_raw <- .as_r(data[[quality]], quality)

  E_raw <- data[, env, drop = FALSE]
  if (!all(vapply(E_raw, is.numeric, logical(1)))) {
    stop("All `env` columns must be numeric.", call. = FALSE)
  }
  ok <- stats::complete.cases(E_raw) & !is.na(r_raw)
  n_drop <- sum(!ok)
  if (sum(ok) < 20L) {
    stop("Fewer than 20 records with complete environmental values.", call. = FALSE)
  }

  d <- data[ok, , drop = FALSE]
  r <- r_raw[ok]
  E <- as.matrix(E_raw[ok, , drop = FALSE])

  if (sum(r) < 5L || sum(!r) < 5L) {
    stop(
      "Need at least 5 retained and 5 discarded records; the filter kept or dropped almost everything.",
      call. = FALSE
    )
  }

  # --- standardised environment, used by shift and energy -------------------
  Ez <- scale(E)
  Ez[!is.finite(Ez)] <- 0

  shift <- .shift_axes(E, r)

  energy <- .energy_test(
    Ez, r,
    reference = control$reference,
    n_perm = control$n_perm,
    max_n = control$max_n
  )

  # --- propensity -----------------------------------------------------------
  Xe <- .env_design(E, quadratic = control$quadratic, pca = control$pca, pca_var = control$pca_var)
  Xm <- if (is.null(metadata)) NULL else .meta_design(d[, metadata, drop = FALSE])
  blk <- if (is.null(spatial_block)) NULL else d[[spatial_block]]
  fold <- .make_folds(nrow(d), k = control$k, block = blk)

  prop <- .propensity(Xe, Xm, r, fold, trim = control$trim)

  res <- list(
    call = match.call(),
    n = nrow(d),
    n_high = sum(r),
    prop_high = mean(r),
    n_incomplete = n_drop,
    env = env,
    metadata = metadata,
    spatial_block = spatial_block,
    blocked = !is.null(spatial_block),
    quality = quality,
    r = r,
    shift = shift,
    energy = energy,
    propensity = prop[setdiff(names(prop), "positivity")],
    positivity = prop$positivity,
    control = control
  )
  res$propensity$reliable <- !isTRUE(prop$auc_env < 0.5 - (control$auc_threshold - 0.5) / 2)
  res$flag <- .verdict(res)
  class(res) <- "sdm_audit"

  if (!res$propensity$reliable) {
    warning(
      sprintf(
        paste0(
          "The environmental propensity model is anti-predictive out of fold (AUC = %.3f). ",
          "That is a sign of misspecification, not of a benign filter: the fitted P(r = 1 | e) ",
          "and therefore ipw_weights() cannot be trusted here. Try control = audit_control(quadratic = TRUE), ",
          "or reduce the number of environmental predictors (pca = TRUE)."
        ),
        prop$auc_env
      ),
      call. = FALSE
    )
  }
  res
}

#' Turn the diagnostic numbers into one of three states
#'
#' * `benign` -- no environmental signature of the filter on any of the three
#'   screens. Filtering and weighting will agree; proceed.
#' * `structured` -- the filter moved the niche, and positivity supports undoing
#'   it. Report the filter-to-IPW bracket; both ends are defensible.
#' * `positivity-limited` -- the filter moved the niche, but reweighting is
#'   carried by a handful of records. Global IPW is fragile here; stratify, or
#'   report the bracket without committing to either end.
#'
#' Shift is declared on the *disjunction* of the three screens, not their
#' conjunction. That is deliberate and it is not neutral: it makes the audit
#' quick to raise an alarm and slow to give reassurance. In a reliability audit
#' that asymmetry is the right one, but it is an editorial choice and should be
#' reported as such.
#' @noRd
.verdict <- function(x) {
  ctl <- x$control
  smd_hit <- any(abs(x$shift$smd) >= ctl$smd_threshold, na.rm = TRUE)
  eng_hit <- isTRUE(x$energy$p_value < ctl$alpha)
  # The screen is on |AUC - 0.5|, not on AUC. An out-of-fold AUC materially
  # BELOW 0.5 is not absence of structure: it is structure that the propensity
  # model is getting the sign of, which happens when the model is misspecified
  # (a linear model against a filter that trims environmental outliers, say).
  # A one-sided `auc >= 0.6` screen would call exactly that case benign.
  auc_hit <- isTRUE(abs(x$propensity$auc_env - 0.5) >= (ctl$auc_threshold - 0.5))
  shifted <- smd_hit || eng_hit || auc_hit

  if (!shifted) {
    return("benign")
  }
  if (x$positivity$ess_ratio < ctl$ess_threshold) {
    return("positivity-limited")
  }
  "structured"
}

#' @noRd
.need_cols <- function(data, cols, arg) {
  miss <- setdiff(cols, names(data))
  if (length(miss)) {
    stop(
      sprintf("`%s`: column(s) not found in `data`: %s", arg, paste(miss, collapse = ", ")),
      call. = FALSE
    )
  }
  invisible(TRUE)
}
