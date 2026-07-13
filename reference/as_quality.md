# Build a retention indicator from the output of an existing cleaning tool

[`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md)
needs to know which records a filter kept. Cleaning tools express that
in different ways, and this function is the bridge. It exists so that
auditing a filter costs one line rather than a rewrite of your pipeline.

## Usage

``` r
as_quality(
  x,
  column = ".summary",
  threshold = NULL,
  keep = c("below", "above"),
  true_level = NULL
)
```

## Arguments

- x:

  A data frame, or a logical, numeric, character or factor vector.

- column:

  Column name to use when `x` is a data frame. Defaults to `.summary`.

- threshold:

  Numeric cut-off, required when `x` is numeric.

- keep:

  `"below"` (default) retains records with values at or below
  `threshold`, which is what you want for an uncertainty or error field;
  `"above"` retains those at or above it, which is what you want for a
  confidence or precision score.

- true_level:

  The level of a character or factor vector that denotes a retained
  record.

## Value

A logical vector, `TRUE` for retained records.

## Details

Three inputs are recognised.

- A data frame:

  The `.summary` column produced by **CoordinateCleaner** (Zizka et
  al., 2019) is used if present: `TRUE` means the record passed every
  test. Any other column can be named through `column`.

- A logical vector:

  Returned unchanged, after validation.

- A numeric vector:

  Thresholded. This is the case for a continuous coordinate-uncertainty
  field, e.g. GBIF's `coordinateUncertaintyInMeters`: `keep = "below"`
  retains records at or under `threshold`.

- A character or factor vector:

  Compared against `true_level`.

## On sweeping the threshold

When quality is continuous, there is no single correct cut. Auditing at
one threshold answers a question you chose; auditing across a range of
thresholds answers whether the answer depends on that choice. Sweep it.
If the shift grows as the cut gets stricter, then "cleaning harder" is
making the bias worse, and there is no bias-free threshold to find.

## References

Zizka, A. et al. (2019). CoordinateCleaner: standardized cleaning of
occurrence records from biological collection databases. *Methods in
Ecology and Evolution*, 10(5), 744-751.

## Examples

``` r
# A continuous coordinate-uncertainty field, as GBIF supplies it
unc <- c(10, 50, 120, 3000, NA, 80)
as_quality(unc, threshold = 100)
#> [1]  TRUE  TRUE FALSE FALSE    NA  TRUE

# The shape CoordinateCleaner returns
cc <- data.frame(x = 1:3, .summary = c(TRUE, FALSE, TRUE))
as_quality(cc)
#> [1]  TRUE FALSE  TRUE
```
