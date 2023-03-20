#' Download WFS data from fisbroker database https://fbinter.stadt-berlin.de/fb/index.jsp
#' select a layer and click on the WFS link. A pop-up window will open and you can copy the link and paste
#' it to this function.
#'
#' @param link the url of the data from fisbroker.
#'
#' @return A folder with the data as a geopackage.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' url <- "https://fbinter.stadt-berlin.de/fb/wfs/data/senstadt/s_wfs_alkis_bezirk"
#' d6berlin::download_fisbroker_wfs(link = url)
#' }

#### Function
download_fisbroker_wfs <- function(link) { # a data frame is required, with at least a column for the year of data creation and WFS-link

  base_fun <- function(single_row) { # function, to be applied on each row of input table

    single_link <- single_row # WFS-link; in case, please change column

    wfs_client <- ows4R::WFSClient$new(single_link, serviceVersion = "2.0.0")

    layer <- wfs_client$ # layer name (incl. prefix, e. g.: "fis:")
      getCapabilities()$
      getFeatureTypes() |>
      purrr::map_chr(function(x){ vx$getName() })

    if(length(layer) > 1) stop(paste0("This function is not suited for WFS-sets with multiple layers. First layer here: ", layer[1]))

    typename <- unlist(strsplit(layer, ":"))[2] # layer name without prefix

    title <- wfs_client$ # layer title in German
      getCapabilities()$
      findFeatureTypeByName(layer)$
      getTitle()

    crs <- wfs_client$ # CRS
      getCapabilities()$
      findFeatureTypeByName(layer)$
      getDefaultCRS()[1]$input

    link2       <- httr::parse_url(single_link)
    link2$query <- list(service   = "wfs",
                        version   = "2.0.0",
                        request   = "GetFeature",
                        typenames = typename,
                        srsName   = paste0("EPSG:", unlist(strsplit(crs, ":"))[2])) # applies CRS to shapefile for download
    request     <- httr::build_url(link2)
    request2    <- sf::st_read(request)

    return(request2)

  }

  safely_function <- purrr::safely(base_fun) # skip and save errors, when using this function
  execution       <- safely_function(link) # applies function on every row of input table
  return(execution$result)
}
