library(sits)
library(restoreutils)

#
# General definitions
#

# Local directories
base_masks_dir <- restoreutils::project_masks_dir()
base_classifications_dir <- restoreutils::project_classifications_dir()

# Mask - version
mask_version <- "mask-v1"

# Mask - input files version
files_version <- "mask-prodes-step13"

# Mask - output files version
output_version <- "temporal-neighbor-perene"

# Mask - perene class (to be reviewed in time)
perene_class_id      <- 2  # "Ag_perene"

# Mask - replacement class (class to replace perene if rule 14 is applied)
replacement_class_id <- 21 # "Pasto_Perene"

# Hardware - Multicores
multicores <- 40

# Hardware - Memory size
memsize <- 180


#
# 1. Generate directories
#
output_dir <- create_data_dir(base_masks_dir / mask_version, "temporal-allyears")


#
# 2. Get masks files
#
files <- restoreutils::get_restore_masks_files(
  mask_version = mask_version,
  files_version = files_version,
  multicores = multicores,
  memsize = memsize
)


#
# 3. Reclassify perene neighbor data
#
file_reclassified <- restoreutils::reclassify_rule14_temporal_neighbor_perene(
  files                 = files,
  perene_class_id       = perene_class_id,
  replacement_class_id  = replacement_class_id,
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
