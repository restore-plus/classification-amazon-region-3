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
extract_ts <- function(cube, samples, output_dir, multicores = 44) {
  # Get tile (assiming cube with one tile)
  tile <- cube[["tile"]]

  # Prepare output dir
  output_file <- fs::path(output_dir) / paste0(tile, ".rds")

  # If file exists
  if (fs::file_exists(output_file)) {
    return(NULL)
  }

  # Check if samples intersects cube
  samples_row <- sits:::.intersects(samples, sits_as_sf(cube))
  samples_row <- samples[samples_row, ]

  if (nrow(samples_row) == 0) {
    return(NULL)
  }

  # Extract time-series
  res <- sits_get_data(cube = cube,
                       samples = samples_row,
                       multicores = multicores)

  # Save RDS
  saveRDS(res, output_file)
}

# Function to extract time series from the "Amostas-Embrapa-2018-2024" dataset
extract_amostas_embrapa_2018_2024 <- function(cube, year, multicores) {
  samples_name <- "Amostas-Embrapa-2018-2024"

  samples <- sf::st_read("data/raw/samples/Amostas-Embrapa-2018-2024/Amostas-Embrapa-2018-2024.shp")
  samples <- samples |>
    dplyr::mutate(
      data = dplyr::recode(
        data,
        "Mar/2018"     = "2018-03-01",
        "Out/2022"     = "2022-10-01",
        "Fev/2018"     = "2018-02-01",
        "Set/2019"     = "2019-09-01",
        "Mai-Jun/2023" = "2023-06-01",
        "Mai/2022"     = "2022-05-01",
        "Out/2021"     = "2021-10-01",
        "Abr/2018"     = "2018-04-01",
        "Nov/2021"     = "2021-11-01",
        "Mai/2024"     = "2024-05-01",
        "Maio/2024"    = "2024-05-01"
      )
    ) |>
    dplyr::mutate(label = classe_pri) |>
    dplyr::mutate(data = as.Date(data)) |>
    dplyr::filter(data >= "2020-01-01" & data <= "2022-12-31") |>
    sf::st_zm() |>
    sf::st_cast("POINT")

  output_dir <- SAMPLES_BASE_DIR / samples_name / year
  fs::dir_create(output_dir, recurse = TRUE)

  extract_ts(
    cube = cube,
    samples = samples,
    multicores = multicores,
    output_dir = output_dir
  )
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
regularization_years <- c(2022)

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
for (regularization_year in regularization_years) {
  # Define cube dir
  cube_year_dir <- fs::path(cube_dir) / regularization_year

  # Regularize tile by tile
  purrr::map(bdc_tiles[["tile"]], function(tile) {
    # Load cube
    cube_year_reg <- sits_cube(
      source     = "BDC",
      collection = "LANDSAT-OLI-16D",
      tiles      = tile,
      data_dir   = cube_year_dir
    )

    extract_amostas_embrapa_2018_2024(cube_year_reg, regularization_year, multicores)
  })
}
