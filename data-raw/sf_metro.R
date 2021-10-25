## code to prepare `sf_metro` dataset goes here

d6berlin::download_data_berlin()

## FILE PATHS ----------------------------------------------------------------
shp_path  <- here::here("data-raw", "geo-raw", "berlin_shapes")

## PREPARE DATA --------------------------------------------------------------

## Berlin metro stations (WGS 84)
sf_metro <-
  suppressMessages(
    sf::read_sf(dsn = glue::glue("{shp_path}/gis_osm_transport_free_1.shp"),
                layer = "gis_osm_transport_free_1") %>%
      dplyr::filter(
        fclass %in% c("railway_station"),
        stringr::str_detect(name, "^U |^S |^S+U |^U+S")
      ) %>%
      dplyr::mutate(
        osm_id = as.factor(osm_id),
        name = stringr::str_replace_all(name, "ß", "ss"),
        name = stringr::str_replace_all(name, "ä", "ae"),
        name = stringr::str_replace_all(name, "ö", "oe"),
        name = stringr::str_replace_all(name, "ü", "ue"),
        type = dplyr::case_when(
          stringr::str_detect(name, "^U") ~ "U-Bahn",
          stringr::str_detect(name, "^S") ~ "S-Bahn",
          TRUE ~ "unknown"
        )
      ) %>%
      sf::st_intersection(d6berlin::sf_districts)
  )

usethis::use_data(sf_metro, overwrite = TRUE)
