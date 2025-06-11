set.seed(777)

library(sf)
library(fs)
library(sits)
library(dplyr)

#
# Constants
#
SAMPLES_BASE_DIR <- fs::path("data/derived/ts-region-3")

#
# Auxiliary functions
#
cube_generate_indices <- function(cube, output_dir, multicores, memsize) {
  # Generate NDVI
  cube <- sits_apply(
    data       = cube,
    NDVI       = (NIR08 - RED) / (NIR08 + RED),
    output_dir = output_dir,
    multicores = multicores,
    memsize    = memsize,
    progress   = TRUE
  )

  # Generate EVI (https://www.usgs.gov/landsat-missions/landsat-enhanced-vegetation-index)
  cube <- sits_apply(
    data       = cube,
    EVI        = 2.5 * ((NIR08 - RED) / (NIR08 + 6 * RED - 7.5 * BLUE + 1)),
    output_dir = output_dir,
    multicores = multicores,
    memsize    = memsize,
    progress   = TRUE
  )

  # Generate MNDWI
  cube <- sits_apply(
    data       = cube,
    MNDWI      = (GREEN - SWIR16) / (GREEN + SWIR16),
    output_dir = output_dir,
    multicores = multicores,
    memsize    = memsize,
    progress   = TRUE
  )

  # 1.6. Generate NBR (https://www.usgs.gov/landsat-missions/landsat-normalized-burn-ratio)
  cube <- sits_apply(
    data       = cube,
    NBR        = (NIR08 - SWIR22) / (NIR08 + SWIR22),
    output_dir = output_dir,
    multicores = multicores,
    memsize    = memsize,
    progress   = TRUE
  )

  return(cube)
}


#
# General definitions
#

# Eco regions
eco_regions <- "data/raw/region/amazon-regions-bdc-md.gpkg"

# BDC tiles
bdc_tiles <- "data/raw/region/bdc-tiles/BDC_MD_V2Polygon.shp"

# Output dir
cube_dir <- "data/derived/cube-region-3"

# Bands
cube_bands <- c("BLUE", "GREEN", "RED", "NIR08" , "SWIR16", "SWIR22", "CLOUD")

# Processing years
regularization_years <- c(2014) # c(2022, 2021, 2020)

#
# Hardware definitions
#

# Multicores
multicores <- 38

# Memory size
memsize <- 220


#
# 1. Load eco regions
#
eco_regions <- sf::st_read(eco_regions)


#
# 2. Load BDC Tiles
#
bdc_tiles <- sf::st_read(bdc_tiles)


#
# 3. Convert ECO regions to BDC tiles CRS
#
eco_regions <- sf::st_transform(eco_regions, crs = sf::st_crs(bdc_tiles))


#
# 4. Filter eco regions (``eco_3`` only)
#
eco_regions <- dplyr::filter(eco_regions, layer == "eco_3") |>
  dplyr::select(-gid, -id, -grs_schema) |>
  sf::st_union() |>
  sf::st_convex_hull()


#
# 5. Filter BDC tiles
#
bdc_tiles <- sf::st_intersection(bdc_tiles, eco_regions)

#
# 6. Process cubes
#
ntfy::ntfy_send("generate-data > initialized!")

for (regularization_year in regularization_years) {
  ntfy::ntfy_send(paste("generate-data > processing", regularization_year))

  # Define cube dir
  cube_year_dir <- fs::path(cube_dir) / regularization_year
  fs::dir_create(cube_year_dir, recurse = TRUE)

  # Define cube ``start date`` and ``end date``
  cube_start_date <- paste0(regularization_year, "-01-01")
  cube_end_date   <- paste0(regularization_year, "-12-31")

  # Create cube timeline
  cube_timeline <- tibble::tibble(month = 1:12) |>
    dplyr::mutate(date = as.Date(paste0(
      regularization_year, "-", sprintf("%02d", month), "-01"
    ))) |>
    dplyr::pull()

  # Regularize tile by tile
  purrr::map(seq_len(nrow(bdc_tiles)), function(idx) {
    # Tile
    tile <- bdc_tiles[idx,]
    tile_name <- tile[["tile"]]
    tile_geometry <- sf::st_geometry(tile)

    # Load cube
    cube_year <- tryCatch({
      sits_cube(
        source     = "MPC",
        collection = "LANDSAT-C2-L2",
        roi        = tile_geometry,
        start_date = cube_start_date,
        end_date   = cube_end_date,
        bands      = cube_bands
      )
    }, error = function(e) {
      NULL
    })

    if (is.null(cube_year)) {
      ntfy::ntfy_send(paste("generate-data > skipped tile > ", tile_name))

      return(NULL)
    }

    # Regularize
    cube_year_reg <- sits_regularize(
      cube        = cube_year,
      period      = "P1M",
      res         = 30,
      multicores  = multicores,
      output_dir  = cube_year_dir,
      timeline    = cube_timeline,
      tile        = tile_name,
      grid_system = "BDC_MD_V2"
    )

    # Generate indices
    cube_year_reg <- cube_generate_indices(
      cube = cube_year_reg,
      output_dir = cube_year_dir,
      multicores = multicores,
      memsize = memsize
    )
  })

  ntfy::ntfy_send(paste("generate-data > finalizing", regularization_year))
}
