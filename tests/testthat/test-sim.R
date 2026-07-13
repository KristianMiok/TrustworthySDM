test_that("sim_occ is reproducible and well formed", {
  a <- sim_occ(n = 200, seed = 11)
  b <- sim_occ(n = 200, seed = 11)
  expect_identical(a, b)
  expect_equal(nrow(a), 200)
  expect_true(all(c(
    "bio1", "bio12", "elev", "basin", "year", "source",
    "keep_random", "keep_precision", "keep_outlier", "keep_strict"
  ) %in% names(a)))
  expect_true(all(vapply(
    a[, c("keep_random", "keep_precision", "keep_outlier", "keep_strict")],
    is.logical, logical(1)
  )))
})

test_that("beta = 0 decouples quality from the environment", {
  d <- sim_occ(n = 1500, beta = 0, seed = 4)
  a <- audit(d, "keep_precision", c("bio1", "bio12", "elev"),
    spatial_block = "basin",
    control = audit_control(n_perm = 199, max_n = 400)
  )
  expect_identical(a$flag, "benign")
})
