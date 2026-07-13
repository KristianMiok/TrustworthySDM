test_that("the energy statistic agrees with the reference implementation", {
  # The package computes the Szekely-Rizzo two-sample energy statistic in base R
  # rather than depending on the `energy` package. That is only defensible if the
  # two agree, so this test checks it against the authors' own implementation.
  skip_if_not_installed("energy")

  set.seed(42)
  x1 <- matrix(rnorm(120 * 3), 120, 3)
  x2 <- matrix(rnorm(80 * 3, mean = 0.7), 80, 3)
  X <- rbind(x1, x2)

  D <- as.matrix(dist(X))
  rs <- rowSums(D)
  S <- sum(rs)
  u <- c(rep(1, 120), rep(0, 80))

  mine <- .energy_stat(D, rs, S, u)
  theirs <- as.matrix(energy::edist(X, sizes = c(120, 80)))[2, 1]

  expect_equal(mine, theirs, tolerance = 1e-10)
})

test_that("the permutation test finds no shift where there is none", {
  set.seed(1)
  E <- matrix(rnorm(600 * 3), 600, 3)
  r <- runif(600) < 0.6 # retention independent of the environment
  res <- .energy_test(E, r, n_perm = 199, max_n = 250)
  expect_gt(res$p_value, 0.05)
})

test_that("the permutation test finds a shift where there is one", {
  set.seed(1)
  E <- matrix(rnorm(600 * 3), 600, 3)
  r <- E[, 1] > -0.2 # retention driven hard by the first axis
  res <- .energy_test(E, r, n_perm = 199, max_n = 250)
  expect_lte(res$p_value, 0.01)
})

test_that("the p-value cannot go below the resolution floor", {
  set.seed(1)
  E <- matrix(rnorm(400 * 2), 400, 2)
  r <- E[, 1] > 0
  res <- .energy_test(E, r, n_perm = 99, max_n = 150)
  expect_gte(res$p_value, 1 / (99 + 1))
})
