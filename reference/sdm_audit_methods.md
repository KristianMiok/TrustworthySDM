# Print, summarise and plot an audit

[`print()`](https://rdrr.io/r/base/print.html) gives the headline
numbers. [`summary()`](https://rdrr.io/r/base/summary.html) gives the
reportable verdict: the shifted axes, the multivariate test, the
propensity decomposition, the positivity limit, and what each of them
licenses you to do.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) shows the two
things worth looking at, which are the per-axis shift and the separation
of the propensity scores.

## Usage

``` r
# S3 method for class 'sdm_audit'
print(x, ...)

# S3 method for class 'sdm_audit'
summary(object, n_axes = 6L, ...)

# S3 method for class 'summary.sdm_audit'
print(x, ...)

# S3 method for class 'sdm_audit'
plot(x, n_axes = 10L, ...)
```

## Arguments

- x, object:

  An `sdm_audit` object from
  [`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md).

- ...:

  Ignored.

- n_axes:

  Number of environmental axes to show, ordered by `|smd|`.

## Value

[`print()`](https://rdrr.io/r/base/print.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) return their
input invisibly. [`summary()`](https://rdrr.io/r/base/summary.html)
returns an object of class `summary.sdm_audit`.

## Details

The verdict is one of:

- `benign`:

  No environmental signature of the filter. Filtering and weighting will
  agree, and the filtering decision is not carrying your result.

- `structured`:

  The filter moved the niche and positivity supports undoing it. Fit
  both ends of the bracket (filtered, and IPW-weighted) and report the
  spread.

- `positivity-limited`:

  The filter moved the niche, but reweighting is carried by a handful of
  records. Global IPW is fragile here. Stratify, or report the bracket
  without committing to either end.

## See also

[`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md)

## Examples

``` r
d <- sim_occ(n = 400, seed = 1)
a <- audit(d,
  quality = "keep_precision", env = c("bio1", "bio12", "elev"),
  metadata = "source", spatial_block = "basin",
  control = audit_control(n_perm = 99, max_n = 200)
)
a
#> 
#> <sdm_audit> 
#>   400 records, 205 retained (51.2%) by `keep_precision`
#>   energy distance   52.717   (permutation p = <= 0.01, 99 perms)
#>   propensity env-AUC 0.881  (blocked by `basin` cross-validation)
#>   IPW effective n    101    (49.5% of retained records)
#>   verdict: STRUCTURED
#> 
#>   summary() for the reportable version.
#> 
summary(a)
#> 
#> Audit of quality filter `keep_precision`
#> ------------------------------------------------------------------ 
#> 400 records with complete environment; 205 retained (51.2%). 
#> 
#> 1. Which axes moved
#>    elev             smd +0.644   KS 0.614   log-var-ratio -0.129  *
#>    bio1             smd -0.604   KS 0.597   log-var-ratio -0.080  *
#>    bio12            smd +0.551   KS 0.505   log-var-ratio +0.026  *
#>    (* |smd| >= 0.10. Positive smd: retained records sit HIGHER on that axis.)
#> 
#> 2. Did the niche move at all
#>    energy distance 52.717, permutation p = <= 0.01 (99 permutations, n = 200 per sample)
#>    NOTE: p is at the resolution floor of the permutation test. Raise `n_perm`
#>          before reporting this number, or you are reporting the test, not the data.
#> 
#> 3. Is the structure environmental, or is it provenance
#>    env-AUC          0.881   (blocked by `basin` CV; 0.5 = retention is environmentally unstructured)
#>    metadata-AUC     0.554   (usually high: the filter was DEFINED on metadata;
#>                             this is a sanity check, not a finding)
#>    env + metadata   0.907
#>    incremental env  +0.353  (environmental structure surviving provenance)
#> 
#> 4. Can it be undone
#>    IPW effective sample size 101 = 49.5% of the retained records
#>    the same, without trimming:  82 = 40.2%
#>    lowest retention probability among retained records: 0.04218
#> ------------------------------------------------------------------ 
#> VERDICT: STRUCTURED
#>   The filter moved the niche, and positivity supports undoing it.
#>   Fit both ends of the bracket -- the filtered model, and the
#>   same model with ipw_weights() -- and report the spread. They
#>   move the niche in opposite directions and which end is correct
#>   depends on whether coordinate error is directed, which your
#>   data cannot tell you. A conclusion that survives the whole
#>   bracket is safe; one that does not is a choice you made, not a
#>   result you found.
#> ------------------------------------------------------------------ 
#> These thresholds are conventions, not truths (see audit_control).
#> Report the numbers, not only the verdict.
#> 
```
