library(sits)
library(restoreutils)

#
# General definitions
#
memsize <- 120
multicores <- 36

version <- "v2"

#
# Note: We start generating masks in 2023, as 2024 is the most recent data, and
#       all forest there is the current forest. So, there is no requirements for
#       extra data transformations
#

#
# 2023
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2023,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)


#
# 2022
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2022,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)


#
# 2021
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2021,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)


#
# 2020
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2020,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)

#
# 2019
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2019,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)

#
# 2018
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2018,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)

#
# 2017
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2017,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)

#
# 2016
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2016,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)

#
# 2015
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2015,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)

#
# 2010
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2010,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)

#
# 2005
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2005,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)

#
# 2000
#
restoreutils::prodes_generate_forest_mask(
  target_year = 2000,
  version     = version,
  multicores  = multicores,
  memsize     = memsize
)
