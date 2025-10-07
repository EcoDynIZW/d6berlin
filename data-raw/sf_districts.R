## code to prepare `sf_roads` dataset goes here

d6berlin::download_data_berlin()

## FILE PATHS ----------------------------------------------------------------
json_file <- "./data-raw/geo-raw/bezirksgrenzen.geojson"

## PREPARE DATA --------------------------------------------------------------
## Berlin districts (WGS 84)
## Source: Technologiestiftung Berlin
sf_districts <-
  suppressMessages(
    sf::read_sf(json_file)
  ) |>
  dplyr::rename(
    district_name = Gemeinde_name,
    district_id = Gemeinde_schluessel,
    district_key = Schluessel_gesamt
  ) |>
  dplyr::mutate(district_key = as.numeric(district_key)) |>
  dplyr::select(dplyr::starts_with("district_"))

usethis::use_data(sf_districts, overwrite = TRUE)
