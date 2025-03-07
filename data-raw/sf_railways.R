## code to prepare `sf_roads` dataset goes here

d6berlin::download_data_berlin()

## FILE PATHS ----------------------------------------------------------------
shp_path  <- "./data-raw/geo-raw/berlin_shapes"

## PREPARE DATA --------------------------------------------------------------

## Berlin roads (WGS 84)
sf_railways <-
  suppressMessages(
    sf::read_sf(dsn = paste0(shp_path, "/gis_osm_railways_free_1.shp"),
                layer = "gis_osm_railways_free_1") |>
      dplyr::mutate(
        osm_id = as.factor(osm_id),
        bridge = as.logical(bridge),
        tunnel = as.logical(tunnel),
        name = stringr::str_replace_all(name, "ß", "ss"),
        name = stringr::str_replace_all(name, "ä", "ae"),
        name = stringr::str_replace_all(name, "ö", "oe"),
        name = stringr::str_replace_all(name, "ü", "ue")
      ) |>
      dplyr::select(osm_id, code, fclass, name, layer, bridge, tunnel) |>
      sf::st_intersection(d6berlin::sf_districts)
  )

usethis::use_data(sf_railways, overwrite = TRUE)
