test_that("IPW weights are mass-normalised and finite", {
  d <- sim_occ(n = 800, seed = 2)
  a <- audit(d, "keep_precision", c("bio1", "bio12", "elev"),
    control = audit_control(n_perm = 49, max_n = 200)
  )
  w <- ipw_weights(a)
  expect_length(w, a$n_high)
  expect_true(all(is.finite(w)))
  expect_equal(sum(w), a$n_high, tolerance = 1e-8)
  expect_gt(attr(w, "ess"), 0)
})

test_that("full_length weights line up with the audited records", {
  d <- sim_occ(n = 800, seed = 2)
  a <- audit(d, "keep_precision", c("bio1", "bio12", "elev"),
    control = audit_control(n_perm = 49, max_n = 200)
  )
  w <- ipw_weights(a, full_length = TRUE)
  expect_length(w, a$n)
  expect_true(all(is.na(w[!a$r])))
  expect_true(all(!is.na(w[a$r])))
})

test_that("IPW upweights the records the filter under-represents", {
  # The whole point of the direction: records sitting in environments the filter
  # depleted are rare among the retained, so IPW must give them MORE weight.
  d <- sim_occ(n = 1200, seed = 5)
  a <- audit(d, "keep_precision", c("bio1", "bio12", "elev"),
    control = audit_control(n_perm = 49, max_n = 250)
  )
  w <- ipw_weights(a)
  e <- a$propensity$e[a$r]
  expect_lt(cor(e, w, method = "spearman"), -0.9)
})

test_that("trust weights move the same way as the filter, not against it", {
  d <- sim_occ(n = 1200, seed = 5)
  a <- audit(d, "keep_precision", c("bio1", "bio12", "elev"),
    control = audit_control(n_perm = 49, max_n = 250)
  )
  tw <- trust_weights(a)
  expect_length(tw, a$n)
  # trust weight rises with retention propensity; IPW weight falls with it
  expect_gt(cor(a$propensity$e, tw, method = "spearman"), 0.9)
})

test_that("trimming can only raise the effective sample size, never lower it", {
  # An invariant, not a tuning parameter: capping the largest weights reduces
  # their spread, and ESS = 1 / (1 + CV^2) rises. Any implementation that
  # violates this has its trimming the wrong way round.
  d <- sim_occ(n = 1200, seed = 4)
  for (q in c("keep_precision", "keep_strict")) {
    a <- suppressWarnings(audit(d, q, c("bio1", "bio12", "elev"),
      spatial_block = "basin",
      control = audit_control(n_perm = 49, max_n = 250)
    ))
    expect_gte(a$positivity$ess_ratio + 1e-9, a$positivity$ess_ratio_untrimmed)
  }
})

test_that("on a positivity-limited filter, trimming is holding the ESS up", {
  # The substantive point. Reporting "the ESS" without saying whether weights
  # were trimmed first is reporting an undefined number: here the two differ by
  # a factor that decides whether the correction looks fragile or fine.
  d <- sim_occ(n = 1500, seed = 7)
  a <- suppressWarnings(audit(d, "keep_strict", c("bio1", "bio12", "elev"),
    spatial_block = "basin",
    control = audit_control(n_perm = 99, max_n = 300)
  ))
  expect_lt(a$positivity$ess_ratio_untrimmed, 0.02)
  expect_gt(a$positivity$ess_ratio, 2 * a$positivity$ess_ratio_untrimmed)
})
