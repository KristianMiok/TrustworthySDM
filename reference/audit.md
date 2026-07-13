# Audit a quality filter for environmental bias

`audit()` measures what a quality filter did to the environmental
distribution of a set of occurrence records, *before* any model is
fitted.

## Usage

``` r
audit(
  data,
  quality,
  env,
  metadata = NULL,
  spatial_block = NULL,
  control = audit_control()
)
```

## Arguments

- data:

  A data frame of occurrence records, one row per record. No rasters, no
  background points and no ground truth are needed.

- quality:

  Name of the retention column: logical or 0/1, `TRUE`/`1` for records
  the filter kept. See
  [`as_quality()`](https://kristianmiok.github.io/TrustworthySDM/reference/as_quality.md)
  for building it from CoordinateCleaner output or from a continuous
  coordinate-uncertainty field.

- env:

  Character vector of environmental column names.

- metadata:

  Optional character vector of record-metadata column names (year,
  source, collection era, institution, ...). Supplying these is what
  lets the audit separate an environmental shift from a provenance
  artefact.

- spatial_block:

  Optional name of a grouping column (basin, grid cell, region) used to
  block cross-validation, so that propensity discrimination is not
  inflated by spatial autocorrelation (Roberts et al., 2017).

- control:

  A list from
  [`audit_control()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit_control.md).

## Value

An object of class `sdm_audit`. See
[sdm_audit_methods](https://kristianmiok.github.io/TrustworthySDM/reference/sdm_audit_methods.md)
for [`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## The problem

Occurrence records are routinely filtered by coordinate accuracy before
species distribution modelling, on the tacit assumption that record
quality is random with respect to the environment. It usually is not.
Georeferencing precision depends on terrain, accessibility, mapping
density and the technology of the era, all of which vary across
environmental space. When quality is environmentally structured,
discarding the low-quality records removes them non-randomly across
environmental space, and the distribution the model learns from shifts.
Filtering is then not data hygiene but a covariate-shift operation.

Writing \\r = 1\\ for a retained record, the environmental distribution
of the retained set relates to the unfiltered one by the retention
propensity, \$\$p\_{\mathrm{high}}(e) \propto p\_{\mathrm{true}}(e)\\
P(r = 1 \mid e),\$\$ so filtering is neutral exactly when \\P(r = 1 \mid
e)\\ does not vary with the environment, and inverse-propensity weights
\\w = 1 / P(r = 1 \mid e)\\ undo the selection when it does (Horvitz &
Thompson, 1952).

## What is reported

- `$shift`:

  Per-axis standardized mean differences, KS distances and log variance
  ratios: which environmental axes filtering moves, and where to.

- `$energy`:

  A single model-free test of whether the retained records occupy a
  different region of environmental space, using the energy distance
  (Szekely & Rizzo, 2013) with a permutation test.

- `$propensity`:

  Out-of-fold discrimination of retention from the environment, from
  metadata, and from both, so that genuinely environmental structure can
  be separated from a provenance artefact.

- `$positivity`:

  Whether a weighting correction is supported by the data at all,
  through the effective sample size of the inverse-propensity weights.

- `$flag`:

  One of `"benign"`, `"structured"` or `"positivity-limited"`.

## What is *not* reported, and cannot be

The audit tells you whether filtering moved the niche and by how much.
It cannot tell you which way to correct. Hard filtering and
inverse-propensity weighting move the estimated niche in *opposite*
directions and bracket the truth between them; which side is right
depends on whether coordinate error is directed or merely noisy, and
that is not identifiable from occurrence data alone. The honest output
of an audit is therefore the width of the bracket, not a point estimate.
Treat any tool that hands you one filtered answer, this one included,
with that in mind.

## References

Horvitz, D. G. & Thompson, D. J. (1952). A generalization of sampling
without replacement from a finite universe. *Journal of the American
Statistical Association*, 47(260), 663-685.

Kish, L. (1965). *Survey Sampling*. Wiley.

Roberts, D. R. et al. (2017). Cross-validation strategies for data with
temporal, spatial, hierarchical, or phylogenetic structure. *Ecography*,
40(8), 913-929.

Szekely, G. J. & Rizzo, M. L. (2013). Energy statistics: a class of
statistics based on distances. *Journal of Statistical Planning and
Inference*, 143(8), 1249-1272.

## See also

[`ipw_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/ipw_weights.md),
[`trust_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/trust_weights.md),
[`as_quality()`](https://kristianmiok.github.io/TrustworthySDM/reference/as_quality.md),
[`sim_occ()`](https://kristianmiok.github.io/TrustworthySDM/reference/sim_occ.md)

## Examples

``` r
d <- sim_occ(n = 400, seed = 1)

# A filter driven by coordinate precision, where precision tracks elevation.
a <- audit(
  d,
  quality = "keep_precision",
  env = c("bio1", "bio12", "elev"),
  metadata = c("year", "source"),
  spatial_block = "basin",
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
```
