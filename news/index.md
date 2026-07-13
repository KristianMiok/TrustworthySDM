# Changelog

## TrustworthySDM 0.1.0

First release. One module:
[`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md).

- [`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md)
  diagnoses whether a quality filter shifted the environmental
  distribution of a set of occurrence records, and returns one of three
  verdicts: `benign`, `structured`, `positivity-limited`.
- [`ipw_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/ipw_weights.md)
  and
  [`trust_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/trust_weights.md)
  implement the two defensible corrections. They move the niche in
  opposite directions, and that is the point.
- [`as_quality()`](https://kristianmiok.github.io/TrustworthySDM/reference/as_quality.md)
  bridges from CoordinateCleaner output or a continuous
  coordinate-uncertainty field.
- [`sim_occ()`](https://kristianmiok.github.io/TrustworthySDM/reference/sim_occ.md)
  simulates occurrence records under four filters, one for each verdict
  plus a symmetric outlier screen that is invisible to mean-shift
  diagnostics.
- No hard dependencies. The energy statistic is implemented in base R
  and tested for numerical identity against the `energy` package.
