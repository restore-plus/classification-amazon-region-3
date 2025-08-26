
#' @export
load_prodes_2023_from_2023 <- function(version = "v2", multicores = 32, memsize = 120) {
  # PRODES 2023, created with PRODES 2023
  prodes_dir <- restoreutils:::.prodes_dir(version = version, year = 2023)
  prodes_rds <- restoreutils:::.prodes_rds(prodes_dir)

  if (fs::file_exists(prodes_rds)) {
    prodes <- readRDS(prodes_rds)
  } else {
    # Recover the PRODES classified cube
    prodes <- sits_cube(
      source = "MPC",
      collection = "LANDSAT-C2-L2",
      data_dir = prodes_dir,
      multicores = multicores,
      memsize = memsize,
      parse_info = c("product", "sensor",
                     "tile", "start_date", "end_date",
                     "band", "version"),
      bands = "class",
      labels = c("0"  = "d2000",
                 "2"  = "d2002",
                 "4"  = "d2004",
                 "6"  = "d2006",
                 "7"  = "d2007",
                 "8"  = "d2008",
                 "9"  = "d2009",
                 "10" = "d2010",
                 "11" = "d2011",
                 "12" = "d2012",
                 "13" = "d2013",
                 "14" = "d2014",
                 "15" = "d2015",
                 "16" = "d2016",
                 "17" = "d2017",
                 "18" = "d2018",
                 "19" = "d2019",
                 "20" = "d2020",
                 "21" = "d2021",
                 "22" = "d2022",
                 "23" = "d2023",
                 "50" = "r2010",
                 "51" = "r2011",
                 "52" = "r2012",
                 "53" = "r2013",
                 "54" = "r2014",
                 "55" = "r2015",
                 "56" = "r2016",
                 "57" = "r2017",
                 "58" = "r2018",
                 "59" = "r2019",
                 "60" = "r2020",
                 "61" = "r2021",
                 "62" = "r2022",
                 "63" = "r2023",
                 "91" = "Hidrografia",
                 "99" = "Nuvem",
                 "100" = "Vegetação Nativa",
                 "101" = "Não Floresta")
    )

    saveRDS(prodes, prodes_rds)
  }
  prodes
}
