# Trust weights: soft downweighting instead of a hard cut

Trust weighting keeps **every** record but downweights those the
propensity model considers likely to be mislocated, with \\w = 1 - P(r =
0 \mid e)\\, clipped at a floor so that no record is annihilated. It is
the continuous relaxation of hard filtering, and it moves the niche in
the **same** direction as filtering, not the opposite one. It is
therefore not an alternative to
[`ipw_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/ipw_weights.md);
it sits on the same end of the bracket as the filter.

## Usage

``` r
trust_weights(x, floor = 0.05)
```

## Arguments

- x:

  An `sdm_audit` object from
  [`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md).

- floor:

  Minimum weight; prevents low-propensity records from being dropped in
  all but name.

## Value

A numeric vector of weights, one per audited record.

## See also

[`ipw_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/ipw_weights.md)

## Examples

``` r
d <- sim_occ(n = 400, seed = 1)
a <- audit(d,
  quality = "keep_precision", env = c("bio1", "bio12", "elev"),
  control = audit_control(n_perm = 99, max_n = 200)
)
w <- trust_weights(a)
range(w)
#> [1] 0.09702734 1.93237968
```
