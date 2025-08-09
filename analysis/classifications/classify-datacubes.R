set.seed(777)

library(sits)
library(restoreutils)

#
# General definitions
#
processing_context <- "eco 3"

# Local directories
base_cubes_dir <- restoreutils::project_cubes_dir()
base_classifications_dir <- restoreutils::project_classifications_dir()

# Model
model_version <- "random-forest-model_no-lbae"

# Classification - version
classification_version <- "samples-v2-eco3"

# Classification - years
regularization_years <- 2015:2024

# Hardware - Multicores
multicores <- 60

# Hardware - Memory size
memsize <- 220


#
# 1. Load model
#
model <- readRDS(
  restoreutils::project_model_file(version = model_version)
)


#
# 2. Load eco region 3 shape
#
eco_region_roi <- restoreutils::roi_ecoregions(region_id = 3,
                                               crs = restoreutils::crs_bdc())


#
# 3. Classify cubes
#
for (classification_year in regularization_years) {
  # Define output directories
  cube_dir <- restoreutils::create_data_dir(
    base_cubes_dir, classification_year
  )

  classification_dir <- restoreutils::create_data_dir(
    base_classifications_dir / classification_version, classification_year
  )

  # Load cube
  cube <- sits_cube(
    source     = "OGH",
    collection = "LANDSAT-GLAD-2M",
    data_dir   = cube_dir,
    roi        = eco_region_roi
  )

  # Classify cube
  probs <- sits_classify(
    data        = cube,
    ml_model    = model,
    multicores  = multicores,
    memsize     = memsize,
    output_dir  = classification_dir,
    roi         = eco_region_roi,
    progress    = TRUE,
    version     = classification_version
  )

  # Smooth cube
  bayes <- sits_smooth(
    cube       = probs,
    multicores = multicores,
    memsize    = memsize,
    output_dir = classification_dir,
    progress   = TRUE,
    version    = version
  )

  # Define classification labels
  class <- sits_label_classification(
    cube       = bayes,
    multicores = multicores,
    memsize    = memsize,
    output_dir = classification_dir,
    progress   = TRUE,
    version    = version
  )

  # Mosaic cubes
  mosaic_cube <- sits_mosaic(
    cube       = class,
    multicores = multicores,
    output_dir = classification_dir,
    version    = version
  )
}
