
#' @export
get_restore_masks_files <- function(mask_version, files_version, multicores = 32, memsize = 120) {
  files_dir <- restoreutils::create_data_dir("data/derived/masks", mask_version)

  files_pattern <- paste0("^LANDSAT_OLI_MOSAIC_\\d{4}-01-01_\\d{4}-11-01_class_", files_version, "\\.tif$")

  files <- list.files(
    path = files_dir,
    pattern = files_pattern,
    recursive = TRUE,
    full.names = TRUE
  )

  years <- restoreutils::get_mask_file_year(files)

  # sort files by year
  ordered_indices <- order(years)
  files <- files[ordered_indices]
  years <- years[ordered_indices]

  expected_years <- seq(min(years), max(years))

  if (!all(years == expected_years)) {
    stop("Sanity check failed: years are missing or out of order.\nFound years: ", paste(years, collapse = ", "))
  }

  return(files)
}
