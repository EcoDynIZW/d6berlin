## code to prepare `sf_roads` dataset goes here

d6berlin::download_data_berlin()

## FILE PATHS ----------------------------------------------------------------
shp_path  <- here::here("data-raw", "geo-raw", "berlin_shapes")

## PREPARE DATA --------------------------------------------------------------

## Berlin roads (WGS 84)
sf_roads <-
  suppressMessages(
    sf::read_sf(dsn = glue::glue("{shp_path}/gis_osm_roads_free_1.shp"),
                layer = "gis_osm_roads_free_1") %>%
      ## remove paths not used by cars
      filter(
        !fclass %in% c("footway", "steps", "bridleway",
                       "path", "pedestrian", "cycleway",
                       "unknown", "unclassified")
      ) %>%
      dplyr::mutate(
        osm_id = as.factor(osm_id),
        bridge = as.logical(bridge),
        tunnel = as.logical(tunnel),
        oneway = ifelse(oneway == "F", FALSE, TRUE),
        name = stringr::str_replace_all(name, "ß", "ss"),
        name = stringr::str_replace_all(name, "ä", "ae"),
        name = stringr::str_replace_all(name, "ö", "oe"),
        name = stringr::str_replace_all(name, "ü", "ue")
      ) %>%
      dplyr::select(osm_id, code, fclass, name, oneway, maxspeed, bridge, tunnel) %>%
      sf::st_intersection(d6berlin::sf_districts)
  )

usethis::use_data(sf_roads, overwrite = TRUE)
