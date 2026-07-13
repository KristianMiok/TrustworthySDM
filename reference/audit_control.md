# Tuning constants for [`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md)

The thresholds below are **conventions, not truths**. They are the
conventional cut-offs from the covariate-balance and propensity
literature, and they are exposed as arguments precisely because the
right value is a property of the study, not of the method. Report the
numbers, not only the verdict.

## Usage

``` r
audit_control(
  smd_threshold = 0.1,
  auc_threshold = 0.6,
  alpha = 0.05,
  ess_threshold = 0.1,
  n_perm = 999L,
  max_n = 1500L,
  k = 5L,
  quadratic = TRUE,
  pca = FALSE,
  pca_var = 0.95,
  trim = c(0.01, 0.99),
  reference = c("all", "low")
)
```

## Arguments

- smd_threshold:

  Absolute standardized mean difference above which an environmental
  axis counts as shifted. The 0.1 convention comes from the
  propensity-score balance literature (Austin, 2011).

- auc_threshold:

  Out-of-fold AUC of the environmental propensity model above which
  retention counts as environmentally structured. 0.5 is no structure;
  0.6 is a deliberately low bar, because in a reliability audit a false
  alarm is cheaper than false reassurance.

- alpha:

  Significance level for the energy-distance permutation test.

- ess_threshold:

  Effective sample size, as a fraction of the retained records, below
  which inverse-propensity weighting is treated as positivity-limited:
  the weights are then carried by a small number of records and global
  reweighting is fragile.

- n_perm:

  Permutations for the energy test. The smallest attainable p-value is
  `1 / (n_perm + 1)`; keep this well below `alpha` or the test will
  report its own resolution floor rather than the evidence.

- max_n:

  Common subsample size for the energy test, which bounds the \\O(n^2)\\
  pairwise-distance computation.

- k:

  Number of cross-validation folds.

- quadratic:

  Include squared environmental terms in the propensity model. Keep this
  on: a filter that trims environmental outliers leaves the mean
  untouched and is invisible to a linear propensity model.

- pca:

  Reduce the environmental block by PCA before fitting the propensity
  model. Useful when predictors are numerous and collinear, but
  conservative: it will tend to understate the environmental signal.

- pca_var:

  Proportion of variance retained when `pca = TRUE`.

- trim:

  Quantiles at which inverse-propensity weights are trimmed.

- reference:

  Reference sample for the energy test: `"all"` (the contrast a model
  fitted on filtered data actually experiences) or `"low"` (the disjoint
  high-versus-low contrast).

## Value

A list of class `audit_control`.

## References

Austin, P. C. (2011). An introduction to propensity score methods for
reducing the effects of confounding in observational studies.
*Multivariate Behavioral Research*, 46(3), 399-424.

## Examples

``` r
audit_control(n_perm = 199, quadratic = FALSE)
#> $smd_threshold
#> [1] 0.1
#> 
#> $auc_threshold
#> [1] 0.6
#> 
#> $alpha
#> [1] 0.05
#> 
#> $ess_threshold
#> [1] 0.1
#> 
#> $n_perm
#> [1] 199
#> 
#> $max_n
#> [1] 1500
#> 
#> $k
#> [1] 5
#> 
#> $quadratic
#> [1] FALSE
#> 
#> $pca
#> [1] FALSE
#> 
#> $pca_var
#> [1] 0.95
#> 
#> $trim
#> [1] 0.01 0.99
#> 
#> $reference
#> [1] "all"
#> 
#> attr(,"class")
#> [1] "audit_control"
```
