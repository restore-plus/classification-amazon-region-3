set.seed(777)

library(sits)
library(restoreutils)

#
# General definitions
#
processing_context <- "eco 3"

# Local directories
base_cubes_dir <- fs::path("/data/projects/classification-region-3-bytile/data/derived/cube-region-3/") # restoreutils::project_cubes_dir()
base_classifications_dir <- restoreutils::project_classifications_dir()

# Model
model_version <- "random-forest-model_no-lbae" # "random-forest-model_no-lbae-ogh"

# Classification - version
classification_version <- "samples-v3-eco3-bdc"

# Classification - years
regularization_years <- c(2000, 2005, 2010) # c(2000, 2005, 2010, 2015) # c(2005, 2007, 2010, 2011, 2012, 2013, 2015)

# Hardware - Multicores
multicores <- 36

# Hardware - Memory size
memsize <- 180


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
                                               crs = restoreutils::crs_bdc(), as_convex = TRUE)


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
    source     = "BDC",
    collection = "LANDSAT-OLI-16D",
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
    # roi         = eco_region_roi,
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
    version    = classification_version
  )

  # Define classification labels
  class <- sits_label_classification(
    cube       = bayes,
    multicores = multicores,
    memsize    = memsize,
    output_dir = classification_dir,
    progress   = TRUE,
    version    = classification_version
  )

  # Mosaic cubes
  mosaic_cube <- sits_mosaic(
    cube       = class,
    multicores = multicores,
    output_dir = classification_dir,
    version    = classification_version
  )
}
