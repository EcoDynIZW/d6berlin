#' Download ATOM data from fisbroker database https://fbinter.stadt-berlin.de/fb/index.jsp
#' select a layer and click on the ATOM link. A pop-up window will open and you can copy the zip link and paste
#' it to this function.
#'
#' @param zip_link the atom url of the data from fisbroker.
#' @param name name of the folder where the data should be stored (will be created if it does not exists)
#' @param path path where the file is stored
#'
#' @return A folder with the data as a geopackage.
#'
#' @export
#' @examples
#' \dontrun{
#' url <- "https://fbinter.stadt-berlin.de/fb/atom/Vegetationshoehen/veghoehe_2020.zip"
#' download_fisbroker_atom(zip_link = url, path = tempdir(), name = "vheights")
#' }

#### Function
download_fisbroker_atom <- function(zip_link, path, name) {

  ## correct path if no trailing slash is provided
  path <- if (!grepl("/$", path)) paste0(path, "/")

  curl::curl_download(zip_link, destfile = paste0(path, name, ".zip"))
  utils::unzip(zipfile = paste0(path, name, ".zip"), exdir = paste0(path, name))
  suppressMessages(file.remove(paste0(path, name, ".zip")))
  curl::curl_download(zip_link, destfile = paste0(path, name, "/", name, ".tif"))

  # you have to set the crs because it is missing sometimes. The default epsg on fisbroker is 25833
  ras <- terra::rast(list.files(paste0(path, name), pattern = ".tif$", full.names = TRUE)[1])
  return(ras)
}
