#' Build a retention indicator from the output of an existing cleaning tool
#'
#' [audit()] needs to know which records a filter kept. Cleaning tools express
#' that in different ways, and this function is the bridge. It exists so that
#' auditing a filter costs one line rather than a rewrite of your pipeline.
#'
#' @details
#' Three inputs are recognised.
#'
#' \describe{
#'   \item{A data frame}{The `.summary` column produced by **CoordinateCleaner**
#'     (Zizka et al., 2019) is used if present: `TRUE` means the record passed
#'     every test. Any other column can be named through `column`.}
#'   \item{A logical vector}{Returned unchanged, after validation.}
#'   \item{A numeric vector}{Thresholded. This is the case for a continuous
#'     coordinate-uncertainty field, e.g. GBIF's
#'     `coordinateUncertaintyInMeters`: `keep = "below"` retains records at or
#'     under `threshold`.}
#'   \item{A character or factor vector}{Compared against `true_level`.}
#' }
#'
#' @section On sweeping the threshold:
#' When quality is continuous, there is no single correct cut. Auditing at one
#' threshold answers a question you chose; auditing across a range of thresholds
#' answers whether the answer depends on that choice. Sweep it. If the shift
#' grows as the cut gets stricter, then "cleaning harder" is making the bias
#' worse, and there is no bias-free threshold to find.
#'
#' @param x A data frame, or a logical, numeric, character or factor vector.
#' @param column Column name to use when `x` is a data frame. Defaults to
#'   `.summary`.
#' @param threshold Numeric cut-off, required when `x` is numeric.
#' @param keep `"below"` (default) retains records with values at or below
#'   `threshold`, which is what you want for an uncertainty or error field;
#'   `"above"` retains those at or above it, which is what you want for a
#'   confidence or precision score.
#' @param true_level The level of a character or factor vector that denotes a
#'   retained record.
#'
#' @return A logical vector, `TRUE` for retained records.
#' @references
#' Zizka, A. et al. (2019). CoordinateCleaner: standardized cleaning of
#' occurrence records from biological collection databases. *Methods in Ecology
#' and Evolution*, 10(5), 744-751.
#' @export
#' @examples
#' # A continuous coordinate-uncertainty field, as GBIF supplies it
#' unc <- c(10, 50, 120, 3000, NA, 80)
#' as_quality(unc, threshold = 100)
#'
#' # The shape CoordinateCleaner returns
#' cc <- data.frame(x = 1:3, .summary = c(TRUE, FALSE, TRUE))
#' as_quality(cc)
as_quality <- function(x,
                       column = ".summary",
                       threshold = NULL,
                       keep = c("below", "above"),
                       true_level = NULL) {
  keep <- match.arg(keep)

  if (is.data.frame(x)) {
    if (!column %in% names(x)) {
      stop(
        sprintf(
          "Column `%s` not found. CoordinateCleaner writes `.summary`; name another column via `column=`.",
          column
        ),
        call. = FALSE
      )
    }
    return(as_quality(x[[column]],
      threshold = threshold, keep = keep,
      true_level = true_level
    ))
  }

  if (is.logical(x)) {
    return(x)
  }

  if (is.numeric(x)) {
    u <- unique(stats::na.omit(x))
    if (is.null(threshold)) {
      if (all(u %in% c(0, 1))) {
        return(x == 1)
      }
      stop(
        "`x` is continuous; supply `threshold` (and see `keep`) to say where the cut falls.",
        call. = FALSE
      )
    }
    return(if (keep == "below") x <= threshold else x >= threshold)
  }

  if (is.character(x) || is.factor(x)) {
    x <- as.character(x)
    if (is.null(true_level)) {
      stop(
        sprintf(
          "`x` is categorical; supply `true_level` to say which level means 'retained'. Levels: %s",
          paste(utils::head(unique(x), 6), collapse = ", ")
        ),
        call. = FALSE
      )
    }
    return(x == true_level)
  }

  stop("Unsupported type for `x`.", call. = FALSE)
}
