# TrustworthySDM 0.1.0

First release. One module: `audit()`.

* `audit()` diagnoses whether a quality filter shifted the environmental
  distribution of a set of occurrence records, and returns one of three
  verdicts: `benign`, `structured`, `positivity-limited`.
* `ipw_weights()` and `trust_weights()` implement the two defensible
  corrections. They move the niche in opposite directions, and that is the
  point.
* `as_quality()` bridges from CoordinateCleaner output or a continuous
  coordinate-uncertainty field.
* `sim_occ()` simulates occurrence records under four filters, one for each
  verdict plus a symmetric outlier screen that is invisible to mean-shift
  diagnostics.
* No hard dependencies. The energy statistic is implemented in base R and tested
  for numerical identity against the `energy` package.
