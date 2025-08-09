library(sits)
library(ntfy)
library(sf)

#
# Auxiliary functions
#
cube2tiles <- function(cube,
                       output_dir,
                       multicores = 64,
                       bands = NULL,
                       roi_file = NULL) {
  ntfy::ntfy_send("cube2tiles > initialized")

  # convert output_dir to fs
  output_dir <- fs::path(output_dir)

  # create base output dirs
  output_mosaic_tile_dir <- output_dir / "tiles"
  output_mosaic_complete_dir <- output_dir / "cube"

  # mosaic by tile
  ntfy::ntfy_send("cube2tiles > generating mosaic by tiles")

  mosaic <- purrr::map_dfr(seq_len(nrow(cube)), function(tile_idx) {
    # select tile
    tile <- cube[tile_idx, ]

    # extract tile crs
    tile_crs <- unique(cube[["crs"]])

    # define output directory
    tile_dir <- output_mosaic_tile_dir / tile[["tile"]]

    # create dir
    fs::dir_create(tile_dir, recurse = TRUE)

    # mosaic
    sits_mosaic(
      cube       = tile,
      multicores = multicores,
      output_dir = tile_dir,
      crs        = tile_crs
    )
  })

  # create output dir to the whole area
  fs::dir_create(output_mosaic_complete_dir, recurse = TRUE)

  # get mosaic timeline
  mosaic_timeline <- sits_timeline(mosaic)

  # merge mosaic file infos
  mosaic_files <- dplyr::bind_rows(mosaic[["file_info"]])

  # mosaic by date
  ntfy::ntfy_send("cube2tiles > generating complete mosaic by dates")

  mosaic_files <- purrr::map_vec(mosaic_timeline, function(timeline_date) {
    # define output file
    mosaic_file <- output_mosaic_complete_dir / paste0(timeline_date, ".tif")
    mosaic_mbtiles <- output_mosaic_complete_dir / paste0(timeline_date, ".mbtiles")

    # if file exists, return it
    if (fs::file_exists(mosaic_mbtiles)) {
      return(mosaic_mbtiles)
    }

    # filter files by date
    tiles_in_date <- mosaic_files  |>
      dplyr::filter(date == timeline_date) |>
      dplyr::mutate(band = factor(band, levels = bands)) |>
      dplyr::arrange(band)

    # process files by `fid` (assuming 3 bands per fid)
    vrt_files <- dplyr::group_by(tiles_in_date, .data[["fid"]]) |>
      dplyr::group_map(function(group_fid, key) {
        # define vrt file path
        vrt_file <- fs::path(paste0(fs::file_temp(), ".vrt"))

        # create vrt
        sf::gdal_utils(
          util = "buildvrt",
          source = group_fid[["path"]],
          destination = vrt_file,
          options = c("-separate")
        )

        # return!
        vrt_file
      }) |>
      unlist()

    # define vrt list file
    vrt_files_lst <- fs::file_temp(ext = "txt")

    # write vrt files to list file
    readr::write_lines(vrt_files, file = vrt_files_lst)

    # build vrt (using system as sf was raising errors)
    vrt_merged <- fs::file_temp(ext = "vrt")

    system(paste(
      "gdalbuildvrt -input_file_list",
      vrt_files_lst,
      vrt_merged,
      sep = " "
    ))

    # translate
    rgb_file <- output_mosaic_complete_dir / "mosaic-rgb.tif"

    system(
      paste(
        "gdal_translate -ot Byte -a_nodata 0 -scale 0 10000 0 255 -b 1 -b 2 -b 3 ",
        vrt_merged,
        rgb_file,
        sep = " "
      )
    )

    # warp
    system(paste(
      "gdalwarp -dstalpha -cutline", roi_file, "-crop_to_cutline", rgb_file, mosaic_file, sep = " "
    ))

    # create mbtiles
    system(paste(
      "gdal_translate -of MBTILES",
      mosaic_file,
      mosaic_mbtiles,
      sep = " "
    ))

    # add mbtiles zoom
    system(paste("gdaladdo -r average ", mosaic_mbtiles, "2 4 8 16 32", sep = " "))

    # delete temp files
    fs::file_delete(rgb_file)

    # return
    mosaic_mbtiles
  })

  # notify
  ntfy::ntfy_send("cube2tiles > done!")

  # return!
  return(mosaic_files)
}


upload2dropbox <- function(files, dropbox_dir) {
  ntfy::ntfy_send("upload2dropbox > initialized")

  purrr::map(files, function(file) {
    print(paste0("Uploading: ", file))
    system(paste("rclone copy", file, paste0("dropbox:", dropbox_dir), sep = " "))
  })

  ntfy::ntfy_send("upload2dropbox > done!")
}


#
# General definitions
#
mosaic_dir <- fs::path("data/derived/mosaic-region-3/2022")

eco_regions <- "data/raw/region/amazon-regions-bdc-md.gpkg"

dropbox_dir <- "projects/01_restore-plus/_transfer/mosaic-mbtiles/2022"

bands <- c("SWIR16", "NIR08", "BLUE")


#
# 1. Create output dir
#
fs::dir_create(mosaic_dir, recurse = TRUE)


#
# 2. Load cube
#
cube <- sits_cube(source     = "BDC",
                  collection = "LANDSAT-OLI-16D",
                  data_dir   = "data/derived/cube-region-3/2022/")

#
# 3. Read regions file
#
eco_regions <- sf::st_read(eco_regions)

#
# 4. Transform / Filter region (region 3)
#
eco_regions <- sf::st_transform(eco_regions, crs = unique(cube[["crs"]]))
eco_regions <- dplyr::filter(eco_regions, layer == "eco_3") |>
  dplyr::select(-gid, -id, -grs_schema) |>
  sf::st_union() |>
  sf::st_convex_hull()

#
# 5. Save roi
#
roi_file <- fs::file_temp(ext = "gpkg")

sf::st_write(eco_regions, roi_file)

#
# 6. Define agriculture cube
#
cube_agriculture <- sits_select(cube, bands = bands)

#
# 7. Mosaic cube
#
tryCatch({
  tiles <- cube2tiles(
    cube       = cube_agriculture,
    output_dir = mosaic_dir,
    roi_file   = roi_file,
    bands      = bands,
    multicores = 44
  )
}, error = function(e) {
  ntfy::ntfy_send("generate-mosaic > error to generate tiles!")
})

#
# 8. Send to dropbox
#

tryCatch({
   tiles <- upload2dropbox(
     files       = tiles,
     dropbox_dir = dropbox_dir
   )
 }, error = function(e) {
   ntfy::ntfy_send("generate-mosaic > error to upload files to dropbox!")
})
