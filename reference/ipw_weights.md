# Inverse-propensity weights for the retained records

Weights \\w = 1 / P(r = 1 \mid e)\\ applied to the retained records
reconstruct the unfiltered environmental distribution in the limit of a
correct propensity model (Horvitz & Thompson, 1952). Extreme weights are
trimmed and the mass is normalised so that the total presence weight
equals the number of retained records, which keeps a weighted fit
comparable to an unweighted one.

## Usage

``` r
ipw_weights(x, trim = NULL, full_length = FALSE)
```

## Arguments

- x:

  An `sdm_audit` object from
  [`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md).

- trim:

  Trimming quantiles. Defaults to the value used in the audit.

- full_length:

  If `TRUE`, return a vector as long as the audited data, with `NA` at
  the discarded records, which is convenient for
  [`cbind()`](https://rdrr.io/r/base/cbind.html)ing back onto a data
  frame. If `FALSE` (default), return only the weights of the retained
  records.

## Value

A numeric vector of weights, with a `"ess"` attribute.

## The direction matters

Hard filtering and inverse-propensity weighting move the estimated niche
in **opposite** directions. Filtering downweights the environments where
low-quality records concentrate; IPW upweights the rare retained records
in exactly those environments, undoing the selection. The two
corrections therefore bracket the unbiased niche from opposite sides.
Which side is correct depends on whether coordinate error is directed or
merely noisy, and that is not identifiable from the occurrence data.
Fitting with these weights and reporting only the result silently
commits your analysis to one end of that bracket. Fit both ends.

## Positivity

Weighting reconstructs the niche only where retained records exist.
Where the retention probability approaches zero there is nothing to
upweight, and the weights concentrate on a handful of records. Check
`x$positivity$ess_ratio` before trusting the result; if the audit
flagged `"positivity-limited"`, these weights are fragile by
construction.

## References

Horvitz, D. G. & Thompson, D. J. (1952). A generalization of sampling
without replacement from a finite universe. *Journal of the American
Statistical Association*, 47(260), 663-685.

## See also

[`trust_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/trust_weights.md)

## Examples

``` r
d <- sim_occ(n = 400, seed = 1)
a <- audit(d,
  quality = "keep_precision", env = c("bio1", "bio12", "elev"),
  control = audit_control(n_perm = 99, max_n = 200)
)
w <- ipw_weights(a)
summary(w)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>  0.5613  0.5911  0.6896  1.0000  0.9018  7.4090 
attr(w, "ess")
#> [1] 101.463
```
