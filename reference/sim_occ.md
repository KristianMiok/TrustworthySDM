# Simulated occurrence records with three different quality filters

A small, self-contained data set for examples, tests and teaching. It is
a simulation, not data: no real occurrences are shipped with this
package.

## Usage

``` r
sim_occ(
  n = 800,
  n_basin = 20L,
  beta = 1.2,
  outlier_prop = 0.1,
  cert_cut = 0.6,
  leak = 0.02,
  seed = NULL
)
```

## Arguments

- n:

  Number of records.

- n_basin:

  Number of basins (used as the blocking variable).

- beta:

  Strength of the coupling between coordinate precision and elevation.
  `beta = 0` decouples quality from the environment entirely and makes
  `keep_precision` benign as well; raising it strengthens the shift.

- outlier_prop:

  Proportion of records removed by `keep_outlier`.

- cert_cut:

  Elevation (in standardised units) above which `keep_strict` almost
  always certifies a record.

- leak:

  Probability that `keep_strict` certifies a record below `cert_cut`
  anyway. Small values make positivity fail; `leak = 0` empties those
  environments completely and no weighting can recover them.

- seed:

  Optional RNG seed.

## Value

A data frame with environmental columns (`bio1`, `bio12`, `elev`),
metadata (`year`, `source`, `coord_uncertainty`), a blocking column
(`basin`), coordinates (`x`, `y`), and the three retention columns.

## Details

Records sit in `n_basin` river basins. Elevation carries a basin-level
random effect; temperature and precipitation are functions of elevation
plus noise, which is what makes the environment spatially structured in
the way that matters. Coordinate uncertainty is generated to depend on
elevation, so that record *quality* and the *environment* are coupled
through terrain, exactly as they are in real georeferenced data.

Three retention columns are supplied, and they are the point of the
object. Each is a filter, and each should receive a different verdict
from
[`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md):

- `keep_random`:

  Records dropped completely at random. The audit should call this
  **benign**, and if it does not, the audit is firing indiscriminately.

- `keep_precision`:

  Records dropped for imprecise coordinates, where imprecision tracks
  elevation. This is the ordinary case: a filter defined on metadata
  that projects onto the environment. The audit should detect a shift.

- `keep_outlier`:

  Records dropped for being environmental outliers, in the manner of a
  Mahalanobis-distance outlier screen. This filter is symmetric: it
  trims both tails, so it moves no mean and produces `smd` near zero. It
  is nonetheless severe, because it deflates the niche and drives the
  retention probability to zero at the environmental margins. It is here
  as a standing counter-example to any audit that looks only at mean
  shifts.

- `keep_strict`:

  A strict precision cut, leaking a subset of modern records that are
  precise whatever the terrain. The leaked records sit where the
  environment says retention is unlikely, so they carry enormous
  inverse-propensity weights and the effective sample size collapses.
  The audit should return **positivity-limited**: the shift is real, and
  reweighting cannot be trusted to undo it.

## Examples

``` r
d <- sim_occ(n = 300, seed = 1)
str(d)
#> 'data.frame':    300 obs. of  14 variables:
#>  $ id               : int  1 2 3 4 5 6 7 8 9 10 ...
#>  $ x                : num  21.6 16.1 14.4 22.8 17.5 ...
#>  $ y                : num  44.8 47.4 44.6 46.6 48.7 ...
#>  $ basin            : Factor w/ 20 levels "B01","B02","B03",..: 4 7 1 2 11 14 18 19 1 10 ...
#>  $ bio1             : num  13.25 10.51 16.74 9.67 14.46 ...
#>  $ bio12            : num  757 816 782 936 665 ...
#>  $ elev             : num  567 844 523 880 367 ...
#>  $ year             : int  1975 1994 1987 2004 1983 1997 1969 1994 1992 2020 ...
#>  $ source           : chr  "citizen" "survey" "museum" "citizen" ...
#>  $ coord_uncertainty: num  516 15 90 13 594 ...
#>  $ keep_random      : logi  TRUE FALSE TRUE TRUE TRUE FALSE ...
#>  $ keep_precision   : logi  FALSE TRUE TRUE TRUE FALSE FALSE ...
#>  $ keep_strict      : logi  FALSE TRUE FALSE TRUE FALSE FALSE ...
#>  $ keep_outlier     : logi  TRUE FALSE TRUE TRUE TRUE TRUE ...
colMeans(d[, c("keep_random", "keep_precision", "keep_outlier")])
#>    keep_random keep_precision   keep_outlier 
#>      0.5600000      0.5666667      0.9000000 
```
