#' Simulated occurrence records with three different quality filters
#'
#' A small, self-contained data set for examples, tests and teaching. It is a
#' simulation, not data: no real occurrences are shipped with this package.
#'
#' Records sit in `n_basin` river basins. Elevation carries a basin-level random
#' effect; temperature and precipitation are functions of elevation plus noise,
#' which is what makes the environment spatially structured in the way that
#' matters. Coordinate uncertainty is generated to depend on elevation, so that
#' record *quality* and the *environment* are coupled through terrain, exactly
#' as they are in real georeferenced data.
#'
#' Three retention columns are supplied, and they are the point of the object.
#' Each is a filter, and each should receive a different verdict from [audit()]:
#'
#' \describe{
#'   \item{`keep_random`}{Records dropped completely at random. The audit should
#'     call this **benign**, and if it does not, the audit is firing
#'     indiscriminately.}
#'   \item{`keep_precision`}{Records dropped for imprecise coordinates, where
#'     imprecision tracks elevation. This is the ordinary case: a filter defined
#'     on metadata that projects onto the environment. The audit should detect a
#'     shift.}
#'   \item{`keep_outlier`}{Records dropped for being environmental outliers, in
#'     the manner of a Mahalanobis-distance outlier screen. This filter is
#'     symmetric: it trims both tails, so it moves no mean and produces
#'     `smd` near zero. It is nonetheless severe, because it deflates the niche
#'     and drives the retention probability to zero at the environmental margins.
#'     It is here as a standing counter-example to any audit that looks only at
#'     mean shifts.}
#'   \item{`keep_strict`}{A strict precision cut, leaking a subset of modern
#'     records that are precise whatever the terrain. The leaked records sit
#'     where the environment says retention is unlikely, so they carry enormous
#'     inverse-propensity weights and the effective sample size collapses. The
#'     audit should return **positivity-limited**: the shift is real, and
#'     reweighting cannot be trusted to undo it.}
#' }
#'
#' @param n Number of records.
#' @param n_basin Number of basins (used as the blocking variable).
#' @param beta Strength of the coupling between coordinate precision and
#'   elevation. `beta = 0` decouples quality from the environment entirely and
#'   makes `keep_precision` benign as well; raising it strengthens the shift.
#' @param outlier_prop Proportion of records removed by `keep_outlier`.
#' @param cert_cut Elevation (in standardised units) above which `keep_strict`
#'   almost always certifies a record.
#' @param leak Probability that `keep_strict` certifies a record below
#'   `cert_cut` anyway. Small values make positivity fail; `leak = 0` empties
#'   those environments completely and no weighting can recover them.
#' @param seed Optional RNG seed.
#'
#' @return A data frame with environmental columns (`bio1`, `bio12`, `elev`),
#'   metadata (`year`, `source`, `coord_uncertainty`), a blocking column
#'   (`basin`), coordinates (`x`, `y`), and the three retention columns.
#' @export
#' @examples
#' d <- sim_occ(n = 300, seed = 1)
#' str(d)
#' colMeans(d[, c("keep_random", "keep_precision", "keep_outlier")])
sim_occ <- function(n = 800,
                    n_basin = 20L,
                    beta = 1.2,
                    outlier_prop = 0.1,
                    cert_cut = 0.6,
                    leak = 0.02,
                    seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  basin <- sample(seq_len(n_basin), n, replace = TRUE)
  basin_elev <- stats::rnorm(n_basin, 0, 1)

  elev <- 600 + 250 * basin_elev[basin] + stats::rnorm(n, 0, 120)
  z_elev <- as.numeric(scale(elev))

  # Temperature falls with elevation; precipitation rises with it.
  bio1 <- 14 - 3.0 * z_elev + stats::rnorm(n, 0, 1.1)
  bio12 <- 850 + 130 * z_elev + stats::rnorm(n, 0, 70)

  x <- stats::runif(n, 13, 24)
  y <- stats::runif(n, 44, 49)

  year <- sample(1960:2024, n, replace = TRUE)
  source <- sample(c("museum", "survey", "citizen"), n,
    replace = TRUE, prob = c(0.25, 0.35, 0.40)
  )

  # Coordinate uncertainty: worse at low elevation (dense, low-gradient, hard to
  # place on the network) and worse for old museum records.
  lu <- 4.2 - beta * z_elev - 0.6 * (source == "survey") +
    0.9 * (year < 1990) + stats::rnorm(n, 0, 0.8)
  coord_uncertainty <- round(exp(lu))

  keep_precision <- coord_uncertainty <= 100
  keep_random <- stats::runif(n) < mean(keep_precision)

  # A near-deterministic certification rule: records are essentially never
  # certified below a terrain threshold, and essentially always above it. The
  # small leak below the threshold is what makes positivity fail: the fitted
  # retention probability there is close to zero, so the handful of records that
  # were certified anyway carry enormous inverse-propensity weights, and the
  # effective sample size collapses. Environments the filter emptied cannot be
  # repopulated by any weight.
  p_cert <- ifelse(z_elev > cert_cut, 0.95, leak)
  keep_strict <- stats::runif(n) < p_cert

  # Environmental outlier screen, Mahalanobis on the environmental block.
  Ez <- scale(cbind(bio1, bio12, elev))
  md <- stats::mahalanobis(Ez, center = rep(0, 3), cov = stats::cov(Ez))
  keep_outlier <- md <= stats::quantile(md, 1 - outlier_prop)

  data.frame(
    id = seq_len(n),
    x = x,
    y = y,
    basin = factor(paste0("B", sprintf("%02d", basin))),
    bio1 = bio1,
    bio12 = bio12,
    elev = elev,
    year = year,
    source = source,
    coord_uncertainty = coord_uncertainty,
    keep_random = keep_random,
    keep_precision = keep_precision,
    keep_strict = keep_strict,
    keep_outlier = unname(keep_outlier),
    stringsAsFactors = FALSE
  )
}
