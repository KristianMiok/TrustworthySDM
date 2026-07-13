#' Two-sample energy statistic from a precomputed distance matrix
#'
#' Computes the Szekely-Rizzo two-sample energy statistic
#' \deqn{E = \frac{nm}{n+m}\left(2A - B - C\right)}
#' where `A` is the mean between-group distance and `B`, `C` are the mean
#' within-group distances (means taken over all \eqn{n^2} and \eqn{m^2} pairs,
#' diagonal included).
#'
#' The permutation loop needs this quantity thousands of times, so it is
#' expressed through a single matrix-vector product. With `u` the 0/1 indicator
#' of group 1, `rs` the row sums of `D` and `S` their total:
#' \deqn{W_1 = u^\top D u,\quad T_1 = rs^\top u,\quad W_2 = S - 2T_1 + W_1,\quad
#'       B_{sum} = T_1 - W_1.}
#' This turns an \eqn{O(N^2)} subsetting operation into one BLAS call.
#'
#' @param D Symmetric distance matrix over the pooled sample.
#' @param rs Row sums of `D`.
#' @param S Total sum of `D`.
#' @param u 0/1 indicator of membership in group 1.
#' @return Scalar energy statistic.
#' @noRd
.energy_stat <- function(D, rs, S, u) {
  n <- sum(u)
  m <- length(u) - n
  if (n == 0 || m == 0) {
    return(NA_real_)
  }
  W1 <- sum(u * (D %*% u))
  T1 <- sum(rs * u)
  W2 <- S - 2 * T1 + W1
  Bs <- T1 - W1
  A <- Bs / (n * m)
  Bm <- W1 / (n * n)
  Cm <- W2 / (m * m)
  (n * m / (n + m)) * (2 * A - Bm - Cm)
}

#' Permutation test for the energy distance between two occurrence samples
#'
#' @param E Standardised environmental matrix, complete rows only.
#' @param r Logical retention indicator (`TRUE` = high quality).
#' @param reference `"all"` compares the high-quality subset against all
#'   records, which is the contrast that matters for a model fitted to the
#'   filtered data; `"low"` compares high against low quality, which is the
#'   disjoint version of the same question.
#' @param n_perm Number of label permutations. The smallest attainable p-value
#'   is `1 / (n_perm + 1)`; with the default this is 0.001.
#' @param max_n Both samples are subsampled to a common size of at most `max_n`,
#'   to bound the pairwise-distance computation.
#' @return List with the observed statistic, the permutation p-value, and the
#'   null distribution.
#' @noRd
.energy_test <- function(E, r, reference = "all", n_perm = 999L, max_n = 1500L) {
  idx_hi <- which(r)
  idx_ref <- if (identical(reference, "all")) seq_len(nrow(E)) else which(!r)
  if (length(idx_hi) < 5L || length(idx_ref) < 5L) {
    return(list(
      statistic = NA_real_, p_value = NA_real_, n_perm = n_perm,
      n_subsample = NA_integer_, reference = reference, null = numeric(0)
    ))
  }
  m <- min(max_n, length(idx_hi), length(idx_ref))
  s_hi <- sample(idx_hi, m)
  s_ref <- sample(idx_ref, m)

  X <- rbind(E[s_ref, , drop = FALSE], E[s_hi, , drop = FALSE])
  D <- as.matrix(stats::dist(X))
  rs <- rowSums(D)
  S <- sum(rs)
  N <- 2L * m

  u_obs <- c(rep(1, m), rep(0, m))
  obs <- .energy_stat(D, rs, S, u_obs)

  perm <- numeric(n_perm)
  for (b in seq_len(n_perm)) {
    perm[b] <- .energy_stat(D, rs, S, u_obs[sample.int(N)])
  }

  list(
    statistic = obs,
    p_value = (1 + sum(perm >= obs)) / (n_perm + 1),
    n_perm = n_perm,
    n_subsample = m,
    reference = reference,
    null = perm
  )
}
