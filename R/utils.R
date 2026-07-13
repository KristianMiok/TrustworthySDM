#' Coerce a quality column to a logical retention indicator
#'
#' @param q Vector to coerce.
#' @param name Name used in error messages.
#' @return Logical vector; `TRUE` = record retained by the filter.
#' @noRd
.as_r <- function(q, name = "quality") {
  if (is.logical(q)) {
    return(q)
  }
  if (is.numeric(q)) {
    u <- unique(stats::na.omit(q))
    if (!all(u %in% c(0, 1))) {
      stop(
        sprintf(
          "`%s` is numeric but not coded 0/1. Convert it first, e.g. with as_quality().",
          name
        ),
        call. = FALSE
      )
    }
    return(q == 1)
  }
  stop(
    sprintf(
      "`%s` must be logical or 0/1. For CoordinateCleaner output or a continuous uncertainty column, use as_quality().",
      name
    ),
    call. = FALSE
  )
}

#' Area under the ROC curve, from the Mann-Whitney U statistic
#'
#' @param score Numeric scores (any monotone transformation of predicted risk).
#' @param y Binary outcome (logical or 0/1).
#' @return Scalar AUC, or `NA_real_` if one class is absent.
#' @noRd
.auc <- function(score, y) {
  ok <- is.finite(score) & !is.na(y)
  score <- score[ok]
  y <- as.integer(y[ok])
  n1 <- sum(y == 1L)
  n0 <- sum(y == 0L)
  if (n1 == 0L || n0 == 0L) {
    return(NA_real_)
  }
  rk <- rank(score)
  (sum(rk[y == 1L]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

#' Assign cross-validation folds, optionally blocked by a grouping variable
#'
#' Blocking assigns whole groups to folds, so that spatially autocorrelated
#' records never straddle the train/test split (Roberts et al. 2017).
#'
#' @param n Number of records.
#' @param k Number of folds.
#' @param block Optional grouping vector of length `n`.
#' @return Integer fold index of length `n`.
#' @noRd
.make_folds <- function(n, k = 5L, block = NULL) {
  if (is.null(block)) {
    return(sample(rep_len(seq_len(k), n)))
  }
  b <- as.character(block)
  ub <- unique(b)
  if (length(ub) < 2L) {
    stop(
      "`spatial_block` has fewer than 2 distinct groups; blocked cross-validation is not possible.",
      call. = FALSE
    )
  }
  k <- min(k, length(ub))
  bf <- sample(rep_len(seq_len(k), length(ub)))
  bf[match(b, ub)]
}

#' Build the environmental design matrix used by the propensity model
#'
#' Columns are standardised. Quadratic terms are added by default: a filter that
#' removes environmental *outliers* symmetrically produces no mean shift, so a
#' linear logistic model cannot see it, whereas a quadratic one can.
#' Optionally the environmental block is first reduced by PCA, which is what one
#' does when predictors are numerous and collinear; note that this is
#' conservative, i.e. it tends to *understate* the environmental signal.
#'
#' @param E Numeric matrix or data frame of environmental values.
#' @param quadratic Add squared terms?
#' @param pca Reduce by PCA first?
#' @param pca_var Proportion of variance retained when `pca = TRUE`.
#' @return A data frame of design columns.
#' @noRd
.env_design <- function(E, quadratic = TRUE, pca = FALSE, pca_var = 0.95) {
  E <- as.matrix(E)
  storage.mode(E) <- "double"
  if (isTRUE(pca) && ncol(E) > 1L) {
    pr <- stats::prcomp(E, center = TRUE, scale. = TRUE)
    cv <- cumsum(pr$sdev^2) / sum(pr$sdev^2)
    kk <- max(1L, which(cv >= pca_var)[1L])
    E <- pr$x[, seq_len(kk), drop = FALSE]
    colnames(E) <- paste0("PC", seq_len(kk))
  }
  E <- scale(E)
  E[!is.finite(E)] <- 0 # constant columns
  E <- as.matrix(E)
  if (isTRUE(quadratic)) {
    Q <- E^2
    colnames(Q) <- paste0(colnames(E), "_sq")
    E <- cbind(E, Q)
  }
  as.data.frame(E)
}

#' Turn arbitrary metadata columns into a numeric model frame
#'
#' Character and factor columns become dummy variables; levels with fewer than
#' `min_level` records are pooled into "other" so that cross-validation folds do
#' not end up with unseen levels.
#'
#' @param M Data frame of metadata columns.
#' @param min_level Minimum level frequency before pooling.
#' @return A data frame of numeric columns, or `NULL` if nothing usable remains.
#' @noRd
.meta_design <- function(M, min_level = 10L) {
  if (is.null(M) || ncol(M) == 0L) {
    return(NULL)
  }
  M <- as.data.frame(M)
  out <- list()
  for (nm in names(M)) {
    x <- M[[nm]]
    if (is.numeric(x)) {
      s <- as.numeric(scale(x))
      s[!is.finite(s)] <- 0
      out[[nm]] <- s
    } else {
      x <- as.character(x)
      x[is.na(x)] <- "NA"
      tb <- table(x)
      rare <- names(tb)[tb < min_level]
      x[x %in% rare] <- "other"
      lv <- unique(x)
      if (length(lv) < 2L) next
      for (l in lv[-1L]) {
        out[[paste0(nm, "_", make.names(l))]] <- as.numeric(x == l)
      }
    }
  }
  if (length(out) == 0L) {
    return(NULL)
  }
  as.data.frame(out)
}

#' Out-of-fold AUC for a logistic model
#'
#' Predictions are pooled across folds and the AUC computed once on the pooled
#' out-of-fold scores; per-fold AUCs are also returned so that fold-to-fold
#' variability is visible.
#'
#' @param X Data frame of predictors.
#' @param y Logical outcome.
#' @param fold Integer fold index.
#' @return List with `auc` (pooled), `auc_folds`, and `pred` (out-of-fold).
#' @noRd
.cv_auc <- function(X, y, fold) {
  if (is.null(X) || ncol(X) == 0L) {
    return(list(auc = NA_real_, auc_folds = NA_real_, pred = rep(NA_real_, length(y))))
  }
  pred <- rep(NA_real_, length(y))
  folds <- sort(unique(fold))
  per <- rep(NA_real_, length(folds))
  for (i in seq_along(folds)) {
    te <- fold == folds[i]
    tr <- !te
    if (length(unique(y[tr])) < 2L) next
    d <- data.frame(.y = as.integer(y[tr]), X[tr, , drop = FALSE])
    fit <- try(
      suppressWarnings(stats::glm(.y ~ ., data = d, family = stats::binomial())),
      silent = TRUE
    )
    if (inherits(fit, "try-error")) next
    p <- try(
      suppressWarnings(
        stats::predict(fit, newdata = X[te, , drop = FALSE], type = "response")
      ),
      silent = TRUE
    )
    if (inherits(p, "try-error")) next
    pred[te] <- p
    per[i] <- .auc(pred[te], y[te])
  }
  list(auc = .auc(pred, y), auc_folds = per, pred = pred)
}

#' In-sample fitted propensities P(r = 1 | e)
#'
#' Used for the *weights*, not for the diagnostic AUC. Weighting needs a
#' propensity for every record, so it is fitted on all the data; discrimination
#' is reported out-of-fold, because an in-sample AUC would be optimistic.
#'
#' @param X Data frame of predictors.
#' @param y Logical outcome.
#' @return Numeric vector of fitted probabilities.
#' @noRd
.fit_propensity <- function(X, y) {
  d <- data.frame(.y = as.integer(y), X)
  fit <- suppressWarnings(stats::glm(.y ~ ., data = d, family = stats::binomial()))
  as.numeric(stats::predict(fit, newdata = X, type = "response"))
}
