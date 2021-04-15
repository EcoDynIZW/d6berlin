## code to prepare `sf_metro` dataset goes here

d6berlin::download_data_berlin()

## FILE PATHS ----------------------------------------------------------------
json_file <- here::here("data-raw", "geo-raw", "bezirksgrenzen.geojson")
shp_path  <- here::here("data-raw", "geo-raw", "berlin_shapes")

## PREPARE DATA --------------------------------------------------------------
## Berlin districts (WGS 84)
## Source: Technologiestiftung Berlin
sf_districts <- sf::read_sf(json_file)

## Berlin metro stations (WGS 84)
sf_metro <-
  suppressMessages(sf::read_sf(dsn = glue::glue("{shp_path}/gis_osm_transport_free_1.shp"),
                               layer = "gis_osm_transport_free_1") %>%
                     dplyr::filter(
                       fclass %in% c("railway_station"),
                       stringr::str_detect(name, "^U |^S ")
                      ) %>%
                     sf::st_intersection(sf_districts))

usethis::use_data(sf_metro, overwrite = TRUE)
