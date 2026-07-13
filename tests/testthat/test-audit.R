test_that("the three simulated filters get the three different verdicts", {
  # This is the load-bearing test. sim_occ() ships filters designed to be
  # benign, structured, and positivity-limited. If they collapse onto one
  # verdict, the audit is not discriminating and the package is decoration.
  d <- sim_occ(n = 1500, seed = 7)
  ctl <- audit_control(n_perm = 199, max_n = 400)
  env <- c("bio1", "bio12", "elev")

  a_ran <- audit(d, "keep_random", env, spatial_block = "basin", control = ctl)
  a_pre <- audit(d, "keep_precision", env, spatial_block = "basin", control = ctl)
  a_str <- audit(d, "keep_strict", env, spatial_block = "basin", control = ctl)

  expect_identical(a_ran$flag, "benign")
  expect_identical(a_pre$flag, "structured")
  expect_identical(a_str$flag, "positivity-limited")
})

test_that("a random filter leaves no environmental signature", {
  d <- sim_occ(n = 1500, seed = 3)
  a <- audit(d, "keep_random", c("bio1", "bio12", "elev"),
    spatial_block = "basin",
    control = audit_control(n_perm = 199, max_n = 400)
  )
  expect_lt(abs(a$propensity$auc_env - 0.5), 0.06)
  expect_gt(a$energy$p_value, 0.05)
  expect_lt(max(abs(a$shift$smd)), 0.1)
})

test_that("an outlier screen moves no mean but is caught anyway", {
  # A symmetric environmental-outlier filter shifts no mean. An audit that
  # looked only at standardized mean differences would call it benign. The
  # variance ratio and the quadratic propensity term are what catch it, and this
  # test exists to stop either of them being quietly removed.
  d <- sim_occ(n = 1500, seed = 7)
  a <- audit(d, "keep_outlier", c("bio1", "bio12", "elev"),
    spatial_block = "basin",
    control = audit_control(n_perm = 199, max_n = 400)
  )
  expect_lt(max(abs(a$shift$smd)), 0.15) # the mean barely moves
  expect_lt(min(a$shift$log_vr), -0.3) # the variance collapses
  expect_gt(a$propensity$auc_env, 0.65) # and the quadratic model sees it
  expect_false(a$flag == "benign")
})

test_that("a linear propensity model is blind to a symmetric filter", {
  d <- sim_occ(n = 1500, seed = 7)
  lin <- suppressWarnings(audit(d, "keep_outlier", c("bio1", "bio12", "elev"),
    spatial_block = "basin",
    control = audit_control(n_perm = 99, max_n = 300, quadratic = FALSE)
  ))
  quad <- audit(d, "keep_outlier", c("bio1", "bio12", "elev"),
    spatial_block = "basin",
    control = audit_control(n_perm = 99, max_n = 300, quadratic = TRUE)
  )
  expect_gt(quad$propensity$auc_env, lin$propensity$auc_env + 0.15)
})

test_that("audit rejects malformed input rather than guessing", {
  d <- sim_occ(n = 200, seed = 1)
  expect_error(audit(d, "nope", c("bio1")), "not found")
  expect_error(audit(d, "keep_random", "no_such_env"), "not found")
  expect_error(audit(d, "keep_random", "source"), "numeric")
  expect_error(audit(d, "keep_random", "bio1", control = list()), "audit_control")
})

test_that("print and summary run and return their input invisibly", {
  d <- sim_occ(n = 400, seed = 1)
  a <- audit(d, "keep_precision", c("bio1", "bio12"),
    control = audit_control(n_perm = 49, max_n = 150)
  )
  expect_output(print(a), "sdm_audit")
  expect_output(print(summary(a)), "VERDICT")
  expect_s3_class(summary(a), "summary.sdm_audit")
})
