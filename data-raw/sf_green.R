## code to prepare `sf_green` dataset goes here

d6berlin::download_data_berlin()

## FILE PATHS ----------------------------------------------------------------
json_file <- here::here("data-raw", "geo-raw", "bezirksgrenzen.geojson")
shp_path  <- here::here("data-raw", "geo-raw", "berlin_shapes")

## PREPARE DATA --------------------------------------------------------------
## Berlin districts (WGS 84)
## Source: Technologiestiftung Berlin
sf_districts <- sf::read_sf(json_file)

sf_green <-
  ## Berlin Landuse Categories (WGS 84)
  sf::read_sf(dsn = glue::glue("{shp_path}/gis_osm_landuse_a_free_1.shp"),
              layer = "gis_osm_landuse_a_free_1") %>%
  ## Berlin Natural Areas (WGS 84)
  rbind(sf::read_sf(dsn = glue::glue("{shp_path}/gis_osm_natural_a_free_1.shp"),
                    layer = "gis_osm_natural_a_free_1")) %>%
  dplyr::filter(fclass %in% c("forest", "grass", "meadow", "nature_reserve",
                              "scrub", "heath", "beach", "cliff")) %>%
  sf::st_intersection(sf_districts)

usethis::use_data(sf_green, overwrite = TRUE)
