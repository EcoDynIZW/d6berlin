## code to prepare `sf_water` dataset goes here

d6berlin::download_data_berlin()

## FILE PATHS ----------------------------------------------------------------
json_file <- here::here("data-raw", "geo-raw", "bezirksgrenzen.geojson")
shp_path  <- here::here("data-raw", "geo-raw", "berlin_shapes")

## PREPARE DATA --------------------------------------------------------------
## Berlin districts (WGS 84)
## Source: Technologiestiftung Berlin
sf_districts <- sf::read_sf(json_file)

## Berlin Waterways (WGS 84)
sf_water <-
  suppressMessages(sf::read_sf(dsn = glue::glue("{shp_path}/gis_osm_water_a_free_1.shp"),
                               layer = "gis_osm_water_a_free_1") %>%
                     sf::st_intersection(sf_districts))

usethis::use_data(sf_water, overwrite = TRUE)
