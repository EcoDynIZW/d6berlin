## code to prepare `sf_berlin` dataset goes here

d6berlin::download_data_berlin()

## FILE PATH -----------------------------------------------------------------
json_file <- here::here("data-raw", "geo-raw", "bezirksgrenzen.geojson")

## PREPARE DATA --------------------------------------------------------------
## Berlin districts (WGS 84)
## Source: Technologiestiftung Berlin
sf_districts <- sf::read_sf(json_file)

## Derive Berlin Outline
sf_berlin <- suppressMessages(sf::st_union(sf_districts))

usethis::use_data(sf_berlin, overwrite = TRUE)
