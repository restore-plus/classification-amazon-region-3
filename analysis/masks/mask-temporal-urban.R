library(sits)
library(restoreutils)

#
# General definitions
#

# Local directories
base_masks_dir <- restoreutils::project_masks_dir()
base_classifications_dir <- restoreutils::project_classifications_dir()

# Mask - version
mask_version <- "v1"
mask_reference_version <- "prodes/v2"

# Mask - input files version
files_version <- "mask-prodes-step14"

# Mask - output files version
output_version <- "temporal-neighbor-urban"

# Mask - Urban Area class
urban_class_id      <- 18  # "Area_Urbanizada"

# Mask - Forest class
forest_class_id      <- 4 # "Floresta"

# Mask - Forest class (PRODES)
forest_class_id_mask <- 100 # Vegetação Nativa

# Hardware - Multicores
multicores <- 4

# Hardware - Memory size
memsize <- 6


#
# 1. Generate directories
#
output_dir <- create_data_dir(base_masks_dir / mask_version, "temporal-allyears")

output_file <- output_dir / "mask-temporal-urban.tif"

#
# 2. Get masks files
#
files <- restoreutils::get_restore_masks_files(
  mask_version = mask_version,
  files_version = files_version,
  multicores = multicores,
  memsize = memsize
)

files_mask <- restoreutils::get_restore_assets_files(
  mask_version  = mask_reference_version,
  files_version = "v1",
  multicores    = multicores,
  memsize       = memsize
)


#
# 3. Reclassify perene neighbor data
#
file_reclassified <- restoreutils::reclassify_rule20_temporal_trajectory_urban(
  files                 = files,
  files_mask            = files_mask,
  file_out              = output_file,
  urban_class_id        = urban_class_id,
  forest_class_id       = forest_class_id,
  forest_class_id_mask  = forest_class_id_mask,
  version               = output_version,
  multicores            = multicores,
  memsize               = memsize,
  output_dir            = output_dir
)


#
# 4. Save results as classification maps
#
restoreutils::reclassify_temporal_results_to_maps(
  files             = files,
  file_reclassified = file_reclassified,
  version           = output_version
)
