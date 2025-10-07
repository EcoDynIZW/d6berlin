#' Download data to draw Berlin template maps
#'
#' @param osmdata A Boolean. Should data from OpenStreetMap be downloaded?
#'
#' @return Geodata of Berlin.
#'
#' @examples
#' \dontrun{
#' download_data_berlin()
#' }
#'
#' @export
download_data_berlin <- function(osmdata = TRUE) {
  ## SETUP ---------------------------------------------------------------------
  ## output dir for raw geo files
  dir <- "./data-raw/geo-raw"
  if (!dir.exists(dir)) dir.create(dir, showWarnings = TRUE, recursive = TRUE)

  ## DISTRICTS -----------------------------------------------------------------
  ## Berlin districts (WGS 84)
  ## Source: Technologiestiftung Berlin
  json_file <- "./data-raw/geo-raw/bezirksgrenzen.geojson"
  if (!file.exists(json_file)) {
    ## Download and unzip Berlin districts (WGS 84)
    ##   - German:  https://daten.odis-berlin.de/de/dataset/bezirksgrenzen
    ##   - English: https://daten.odis-berlin.de/en/dataset/bezirksgrenzen
    link <- "https://tsb-opendata.s3.eu-central-1.amazonaws.com/bezirksgrenzen/bezirksgrenzen.geojson"
    message(paste0("Loading Berlin district data from ", link, "."))
    curl::curl_download(link, destfile = json_file)
    message(paste0("Downloaded to ", json_file, "."))
  } else {
    message(paste0("Berlin district data already exists: ", json_file, "."))
  }

  ## OSM DATA ------------------------------------------------------------------
  ## Berlin OSM data (WGS 84)
  ## Source: OpenStreetMaps via Geofabrik
  if (osmdata == TRUE) {
    zip_file <- "./data-raw/geo-raw/berlin_shapes.zip"
    shp_path <- "./data-raw/geo-raw/berlin_shapes"
    if (!file.exists(paste0(shp_path, "/gis_osm_water_a_free_1.shp"))) {
      ## Download and unzip Berlin shapefiles (WGS 84)
      ## https://download.geofabrik.de/europe/germany/berlin.html
      link <- "https://download.geofabrik.de/europe/germany/berlin-latest-free.shp.zip"
      message(paste0("Loading Berlin OSM data from ", link, "."))
      curl::curl_download(link, destfile = zip_file)
      message(paste0("Unzip Berlin OSM data from ", zip_file, "."))
      utils::unzip(zipfile = zip_file, exdir = shp_path)
      suppressMessages(file.remove(zip_file))
      curl::curl_download(link, destfile = json_file)
      message(paste0("Downloaded to ", shp_path, "/."))
    } else {
      message(paste0("Berlin OSM data already exists: ", shp_path, "/."))
    }
  }
}
