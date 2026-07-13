#' Per-axis environmental shift induced by a quality filter
#'
#' For each environmental variable, two quantities are reported.
#'
#' * **Standardized mean difference (SMD)**, computed between *all* records and
#'   the *retained* subset, and scaled by the standard deviation of all records:
#'   \deqn{SMD_j = (\bar{e}_{j,\mathrm{high}} - \bar{e}_{j,\mathrm{all}}) /
#'         sd_j(\mathrm{all}).}
#'   This is the quantity a downstream model actually feels: it says how far, in
#'   units of the full environmental spread, filtering moved the centre of the
#'   training data along axis `j`. The sign gives the direction.
#'
#' * **Kolmogorov-Smirnov distance**, computed between the retained and the
#'   discarded records, which is the disjoint contrast and is sensitive to
#'   distributional differences that leave the mean untouched.
#'
#' A **log variance ratio** is added for the same reason quadratic terms are
#' added to the propensity model: a filter that trims environmental outliers
#' shrinks the variance without moving the mean, and would otherwise pass an
#' SMD-only screen unnoticed.
#'
#' @param E Numeric matrix of environmental values (complete rows).
#' @param r Logical retention indicator.
#' @return A data frame, one row per environmental axis, sorted by `|smd|`.
#' @noRd
.shift_axes <- function(E, r) {
  E <- as.matrix(E)
  nm <- colnames(E)
  out <- data.frame(
    variable = nm,
    smd = NA_real_,
    ks = NA_real_,
    log_vr = NA_real_,
    mean_all = NA_real_,
    mean_high = NA_real_,
    sd_all = NA_real_,
    stringsAsFactors = FALSE
  )
  for (j in seq_along(nm)) {
    e <- E[, j]
    hi <- e[r]
    lo <- e[!r]
    s_all <- stats::sd(e)
    out$mean_all[j] <- mean(e)
    out$mean_high[j] <- mean(hi)
    out$sd_all[j] <- s_all
    out$smd[j] <- if (is.finite(s_all) && s_all > 0) (mean(hi) - mean(e)) / s_all else 0
    out$ks[j] <- if (length(hi) > 1L && length(lo) > 1L) {
      suppressWarnings(as.numeric(stats::ks.test(hi, lo)$statistic))
    } else {
      NA_real_
    }
    s_hi <- stats::sd(hi)
    s_lo <- stats::sd(lo)
    out$log_vr[j] <- if (is.finite(s_hi) && is.finite(s_lo) && s_hi > 0 && s_lo > 0) {
      log(s_hi / s_lo)
    } else {
      NA_real_
    }
  }
  out[order(-abs(out$smd)), , drop = FALSE]
}
