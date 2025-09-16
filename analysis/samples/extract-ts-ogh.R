set.seed(777)

library(sits)
library(restoreutils)

#
# Auxiliary function
#
update_samples_timeline_based_in_cube <- function(samples, cube) {
  cube_timeline <- sits_timeline(cube)

  samples[["cube"]] <- NULL
  samples[["time_series"]] <- NULL
  samples[["start_date"]] <- min(cube_timeline)
  samples[["end_date"]] <- max(cube_timeline)

  samples
}


#
# General definitions
#

# Local directories
base_cubes_dir <- restoreutils::project_cubes_dir() / "ogh"
base_classifications_dir <- restoreutils::project_classifications_dir()

# Samples base directory
base_samples_dir <- fs::path("data/derived/timeseries/")

# Samples base file
samples_file <- base_samples_dir / "samples-eco3.rds"

# Samples version
samples_version <- "samples_no-lbae-ogh-"

# Classification - years
reference_years <- c(2000, 2004, 2005, 2010, 2015)

# Hardware - Multicores
multicores <- 36


#
# 1. Extract time-series
#
for (reference_year in reference_years) {
  # Define data directories
  cube_dir <- restoreutils::create_data_dir(
    base_cubes_dir, reference_year
  )

  # Load cube
  cube <- sits_cube(
    source     = "OGH",
    collection = "LANDSAT-GLAD-2M",
    data_dir   = cube_dir
  )

  # Load samples (we always reload to avoid errors)
  samples <- readRDS(samples_file)

  # Update samples
  samples = update_samples_timeline_based_in_cube(
    samples = samples,
    cube = cube
  )

  # Extract time-series
  samples_ts <- sits_get_data(
    cube       = cube,
    samples    = samples,
    multicores = multicores
  )

  # Save samples
  saveRDS(samples_ts, base_samples_dir / paste0(samples_version, reference_year, ".rds"))
}
