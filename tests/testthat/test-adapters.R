test_that("as_quality thresholds a continuous uncertainty field", {
  unc <- c(10, 50, 120, 3000, 80)
  expect_identical(as_quality(unc, threshold = 100), c(TRUE, TRUE, FALSE, FALSE, TRUE))
  expect_identical(
    as_quality(unc, threshold = 100, keep = "above"),
    c(FALSE, FALSE, TRUE, TRUE, FALSE)
  )
})

test_that("as_quality reads the CoordinateCleaner .summary column", {
  cc <- data.frame(x = 1:3, .summary = c(TRUE, FALSE, TRUE))
  expect_identical(as_quality(cc), c(TRUE, FALSE, TRUE))
})

test_that("as_quality refuses to guess", {
  expect_error(as_quality(c(10, 200, 3000)), "threshold")
  expect_error(as_quality(c("hi", "lo")), "true_level")
  expect_error(as_quality(data.frame(a = 1)), "not found")
})

test_that("as_quality handles categorical labels when told which level to keep", {
  q <- c("certified", "inferred", "certified")
  expect_identical(as_quality(q, true_level = "certified"), c(TRUE, FALSE, TRUE))
})
