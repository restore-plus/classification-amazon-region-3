library(sits)
library(restoreutils)

#
# General definitions
#
memsize    <- 120
multicores <- 36

version <- "v2"

mask_years <- c(2000, 2005, 2010)

#
# Note: We start generating masks in 2023, as 2024 is the most recent data, and
#       all forest there is the current forest. So, there is no requirements for
#       extra data transformations
#
purrr::map(mask_years, function(mask_year) {
  restoreutils::prodes_generate_forest_mask(
    target_year   = mask_year,
    version       = version,
    multicores    = multicores,
    memsize       = memsize,
    prodes_loader = restoreclassificationeco3::load_prodes_2023_from_2023
  )
})
