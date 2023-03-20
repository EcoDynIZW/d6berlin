## code to prepare `sf_water` dataset goes here

d6berlin::download_data_berlin()

## FILE PATHS ----------------------------------------------------------------
shp_path  <- "./data-raw/geo-raw/berlin_shapes"

## PREPARE DATA --------------------------------------------------------------

## Berlin Waterways (WGS 84)
sf_water <-
  suppressMessages(
    sf::read_sf(dsn = paste0({shp_path}, "/gis_osm_water_a_free_1.shp"),
                layer = "gis_osm_water_a_free_1") |>
    dplyr::mutate(osm_id = as.factor(osm_id)) |>
    sf::st_intersection(d6berlin::sf_districts)
  )

usethis::use_data(sf_water, overwrite = TRUE)
