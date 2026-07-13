#' Inverse-propensity weights for the retained records
#'
#' Weights \eqn{w = 1 / P(r = 1 \mid e)} applied to the retained records
#' reconstruct the unfiltered environmental distribution in the limit of a
#' correct propensity model (Horvitz & Thompson, 1952). Extreme weights are
#' trimmed and the mass is normalised so that the total presence weight equals
#' the number of retained records, which keeps a weighted fit comparable to an
#' unweighted one.
#'
#' @section The direction matters:
#' Hard filtering and inverse-propensity weighting move the estimated niche in
#' **opposite** directions. Filtering downweights the environments where
#' low-quality records concentrate; IPW upweights the rare retained records in
#' exactly those environments, undoing the selection. The two corrections
#' therefore bracket the unbiased niche from opposite sides. Which side is
#' correct depends on whether coordinate error is directed or merely noisy, and
#' that is not identifiable from the occurrence data. Fitting with these weights
#' and reporting only the result silently commits your analysis to one end of
#' that bracket. Fit both ends.
#'
#' @section Positivity:
#' Weighting reconstructs the niche only where retained records exist. Where the
#' retention probability approaches zero there is nothing to upweight, and the
#' weights concentrate on a handful of records. Check
#' `x$positivity$ess_ratio` before trusting the result; if the audit flagged
#' `"positivity-limited"`, these weights are fragile by construction.
#'
#' @param x An `sdm_audit` object from [audit()].
#' @param trim Trimming quantiles. Defaults to the value used in the audit.
#' @param full_length If `TRUE`, return a vector as long as the audited data,
#'   with `NA` at the discarded records, which is convenient for `cbind()`ing
#'   back onto a data frame. If `FALSE` (default), return only the weights of
#'   the retained records.
#'
#' @return A numeric vector of weights, with a `"ess"` attribute.
#' @references
#' Horvitz, D. G. & Thompson, D. J. (1952). A generalization of sampling without
#' replacement from a finite universe. *Journal of the American Statistical
#' Association*, 47(260), 663-685.
#' @seealso [trust_weights()]
#' @export
#' @examples
#' d <- sim_occ(n = 400, seed = 1)
#' a <- audit(d,
#'   quality = "keep_precision", env = c("bio1", "bio12", "elev"),
#'   control = audit_control(n_perm = 99, max_n = 200)
#' )
#' w <- ipw_weights(a)
#' summary(w)
#' attr(w, "ess")
ipw_weights <- function(x, trim = NULL, full_length = FALSE) {
  stopifnot(inherits(x, "sdm_audit"))
  if (isFALSE(x$propensity$reliable)) {
    warning(
      "These weights come from a propensity model that was anti-predictive out of fold. They are not a correction; they are noise. See the warning from audit().",
      call. = FALSE
    )
  }
  if (is.null(trim)) trim <- x$control$trim
  w <- .trim_normalise(1 / x$propensity$e[x$r], trim)
  ess <- .ess(w)
  if (isTRUE(full_length)) {
    out <- rep(NA_real_, length(x$r))
    out[x$r] <- w
    w <- out
  }
  attr(w, "ess") <- ess
  attr(w, "ess_ratio") <- ess / x$n_high
  w
}

#' Trust weights: soft downweighting instead of a hard cut
#'
#' Trust weighting keeps **every** record but downweights those the propensity
#' model considers likely to be mislocated, with
#' \eqn{w = 1 - P(r = 0 \mid e)}, clipped at a floor so that no record is
#' annihilated. It is the continuous relaxation of hard filtering, and it moves
#' the niche in the **same** direction as filtering, not the opposite one. It is
#' therefore not an alternative to [ipw_weights()]; it sits on the same end of
#' the bracket as the filter.
#'
#' @param x An `sdm_audit` object from [audit()].
#' @param floor Minimum weight; prevents low-propensity records from being
#'   dropped in all but name.
#' @return A numeric vector of weights, one per audited record.
#' @seealso [ipw_weights()]
#' @export
#' @examples
#' d <- sim_occ(n = 400, seed = 1)
#' a <- audit(d,
#'   quality = "keep_precision", env = c("bio1", "bio12", "elev"),
#'   control = audit_control(n_perm = 99, max_n = 200)
#' )
#' w <- trust_weights(a)
#' range(w)
trust_weights <- function(x, floor = 0.05) {
  stopifnot(inherits(x, "sdm_audit"))
  w <- pmax(x$propensity$e, floor)
  w * length(w) / sum(w)
}
