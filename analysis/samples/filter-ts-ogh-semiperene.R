set.seed(777)

library(sits)
library(restoreutils)


#
# General definitions
#

# Filter version
filter_version <- "semiperene"

# Filter ROI
filter_roi_file <- fs::path("data/raw/region/roi-samples-semiperene.gpkg")

# Samples base directory
base_samples_dir <- fs::path("data/derived/timeseries/")

# Samples version
samples_version <- "samples_no-lbae-ogh-"

# Classification - years
reference_years <- c(2000, 2004, 2005, 2010, 2015)


#
# 1. Define output dir
#
base_output_dir <- base_samples_dir / "filter" / filter_version

fs::dir_create(base_output_dir)


#
# 2. Load filter ROI
#
filter_roi <- sf::st_read(filter_roi_file)


#
# 3. Extract time-series
#
for (reference_year in reference_years) {
  # Define file name
  samples_output_filename <- paste0(samples_version, reference_year)

  # Define samples file
  samples_file <- paste0(samples_output_filename, ".rds")
  samples_file_gpkg <- paste0(samples_output_filename, ".gpkg")

  # Load samples
  samples <- readRDS(base_samples_dir / samples_file)

  # Transform samples in SF object
  samples_sf <- sits_as_sf(samples)

  # Filter
  samples_filtered <- sf::st_intersection(samples_sf, filter_roi)

  # Save GPKG
  samples_filtered |>
    dplyr::select(-.data[["time_series"]]) |>
    sf::st_write(base_output_dir / samples_file_gpkg)

  # Save RDS
  class(samples_filtered) <- class(samples)

  samples_filtered |>
    dplyr::select(-.data[["geometry"]]) |>
    saveRDS(base_output_dir /samples_file)
}
