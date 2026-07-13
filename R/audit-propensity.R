#' Retention propensity: discrimination, confounding, and positivity
#'
#' Three logistic models of \eqn{P(r = 1 \mid \cdot)} are fitted and their
#' out-of-fold AUC reported: from the environment alone, from record metadata
#' alone, and from both.
#'
#' The number that carries the argument is `auc_env`. It answers the question
#' the audit exists to answer: *is retention environmentally structured?* An
#' `auc_env` near 0.5 means the filter, whatever it was defined on, left no
#' environmental signature, and filtering is expected to be unbiased.
#'
#' `auc_meta` is usually high and is **not** a finding: most filters are defined
#' on metadata (coordinate uncertainty, era, source), so a metadata model
#' recovering the filter is a sanity check, not evidence. Its purpose is to
#' support the third number.
#'
#' `auc_incremental` = `auc_both - auc_meta` is the *environmental residual*:
#' how much environmental structure survives after record provenance is
#' controlled for. A shift with no incremental environmental signal is a
#' metadata artefact; a shift with one is not.
#'
#' Positivity is the constraint on any weighting correction. Inverse-propensity
#' weights reconstruct the unfiltered environmental distribution only where
#' retained records exist; in environments whose retention probability
#' approaches zero, there is nothing to upweight. The effective sample size
#' (Kish, 1965), \eqn{ESS = (\sum w)^2 / \sum w^2}, measures how much of the
#' retained sample survives reweighting.
#'
#' @param Xe Environmental design matrix.
#' @param Xm Metadata design matrix, or `NULL`.
#' @param r Logical retention indicator.
#' @param fold Integer fold index (blocked, if a blocking variable was supplied).
#' @param trim Weight trimming quantiles.
#' @return List with propensity scores, AUCs, and positivity summaries.
#' @noRd
.propensity <- function(Xe, Xm, r, fold, trim = c(0.01, 0.99)) {
  cv_env <- .cv_auc(Xe, r, fold)
  cv_meta <- if (is.null(Xm)) NULL else .cv_auc(Xm, r, fold)
  cv_both <- if (is.null(Xm)) NULL else .cv_auc(cbind(Xe, Xm), r, fold)

  auc_env <- cv_env$auc
  auc_meta <- if (is.null(cv_meta)) NA_real_ else cv_meta$auc
  auc_both <- if (is.null(cv_both)) NA_real_ else cv_both$auc
  auc_inc <- if (is.na(auc_both) || is.na(auc_meta)) NA_real_ else auc_both - auc_meta

  # Weights need a propensity for every record, so this model is fitted on all
  # the data. Discrimination above is reported out-of-fold; these two things
  # must not be confused.
  e <- .fit_propensity(Xe, r)

  w_raw <- 1 / e[r]
  w <- .trim_normalise(w_raw, trim)
  ess <- .ess(w)
  # Trimming is not cosmetic: it is what stops a handful of near-zero-propensity
  # records from carrying the whole correction, and it can change the effective
  # sample size by orders of magnitude. Both numbers are reported, because "the
  # ESS" is not well defined until you say whether the weights were trimmed
  # first. If they disagree wildly, the correction rests on very few records.
  ess_untrimmed <- .ess(w_raw)
  n_hi <- sum(r)

  list(
    e = e,
    auc_env = auc_env,
    auc_meta = auc_meta,
    auc_both = auc_both,
    auc_incremental = auc_inc,
    auc_env_folds = cv_env$auc_folds,
    n_folds = length(unique(fold)),
    positivity = list(
      ess = ess,
      ess_ratio = ess / n_hi,
      ess_untrimmed = ess_untrimmed,
      ess_ratio_untrimmed = ess_untrimmed / n_hi,
      ess_pct_all = 100 * ess / length(r),
      min_e_high = min(e[r]),
      q01_e_high = unname(stats::quantile(e[r], 0.01)),
      max_weight = max(w),
      n_trimmed = sum(w_raw < stats::quantile(w_raw, trim[1]) |
        w_raw > stats::quantile(w_raw, trim[2])),
      trim = trim
    )
  )
}

#' Kish effective sample size
#' @noRd
.ess <- function(w) {
  w <- w[is.finite(w) & w > 0]
  if (length(w) == 0L) {
    return(0)
  }
  sum(w)^2 / sum(w^2)
}

#' Trim extreme weights and normalise their mass
#'
#' Trimming caps the weights at the given quantiles; mass normalisation rescales
#' them to sum to the number of weighted records, so that the total presence mass
#' is preserved and the weighted fit is comparable to the unweighted one.
#' @noRd
.trim_normalise <- function(w, trim = c(0.01, 0.99)) {
  if (!is.null(trim)) {
    qs <- stats::quantile(w, probs = trim, na.rm = TRUE)
    w <- pmin(pmax(w, qs[1]), qs[2])
  }
  w * length(w) / sum(w)
}
