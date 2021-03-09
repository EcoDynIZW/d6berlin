## P


#' Plot Globe with Locator Pin for Berlin (while preserving polygons in orthographic view)
#'
#' @return A ggplot object containing a locator globe with pin.
#'
#' @examples globe()
#'
#' @import ggplot2
#' @import dplyr
#' @import sf
#' @importFrom magrittr %>%
#' @importFrom  rnaturalearth ne_countries
#' @importFrom  mapview npts
#'
#' @export
globe <- function() {
  ## code to preserve orthpgraühic view from this gist:
  ## https://gist.github.com/fzenoni/ef23faf6d1ada5e4a91c9ef23b0ba2c1
  ## via this issue: https://github.com/r-spatial/sf/issues/1050

  ## Load country data
  mini_world <- rnaturalearth::ne_countries(scale = 110, returnclass = "sf")

  ## Define the orthographic projection ........................................
  lat <- 32
  lon <- 13
  ortho <- paste0('+proj=ortho +lat_0=', lat, ' +lon_0=', lon, ' +x_0=0 +y_0=0 +a=6371000 +b=6371000 +units=m +no_defs')

  ## Define the polygon to split what lies within and without your projection ..
  circle <-
    suppressMessages(
      sf::st_point(x = c(0, 0)) %>%
        sf::st_buffer(dist = 6371000) %>%
        sf::st_sfc(crs = ortho)
    )
  ## Project this polygon in lat-lon ...........................................
  circle_longlat <-
    circle %>%
    sf::st_transform(crs = 4326)

  ## You must decompose it into a string with ordered longitudes
  ## Then complete the polygon definition to cover the hemisphere ..............
  if(lat != 0) {
    circle_longlat <- sf::st_boundary(circle_longlat)

    circle_coords <- sf::st_coordinates(circle_longlat)[, c(1,2)]
    circle_coords <- circle_coords[order(circle_coords[, 1]),]
    circle_coords <- circle_coords[!duplicated(circle_coords),]

    ## Rebuild line ............................................................
    circle_longlat <-
      sf::st_linestring(circle_coords) %>%
      sf::st_sfc(crs = 4326)

    if(lat > 0) {
      rectangle <- list(rbind(circle_coords,
                              c(X = 180, circle_coords[nrow(circle_coords), 'Y']),
                              c(X = 180, Y = 90),
                              c(X = -180, Y = 90),
                              c(X = -180, circle_coords[1, 'Y']),
                              circle_coords[1, c('X','Y')])) %>%
        sf::st_polygon() %>%
        sf::st_sfc(crs = 4326)
    } else {
      rectangle <- list(rbind(circle_coords,
                              c(X = 180, circle_coords[nrow(circle_coords), 'Y']),
                              c(X = 180, Y = -90),
                              c(X = -180, Y = -90),
                              c(X = -180, circle_coords[1, 'Y']),
                              circle_coords[1, c('X','Y')])) %>%
        sf::st_polygon() %>%
        sf::st_sfc(crs = 4326)
    }

    circle_longlat <- suppressMessages(sf::st_union(
      sf::st_make_valid(circle_longlat),
      sf::st_make_valid(rectangle))
    )
  }

  ## A small negative buffer is necessary to avoid polygons still disappearing
  ## in a few pathological cases ...............................................
  visible <- suppressMessages(suppressWarnings(
    sf::st_intersection(sf::st_make_valid(mini_world),
                        sf::st_buffer(circle_longlat, -.09)) %>%
    sf::st_transform(crs = ortho)
  ))

  ## Get reason why polygons are broken ........................................
  broken_reason <- sf::st_is_valid(visible, reason = TRUE)

  ## First fix NA's by decomposing them ........................................
  na_visible <- visible[is.na(broken_reason),]
  visible <- visible[!is.na(broken_reason),]

  ## Open and close polygons ...................................................
  na_visible <- sf::st_cast(na_visible, 'MULTILINESTRING') %>%
    sf::st_cast('LINESTRING', do_split=TRUE)
  na_visible <- na_visible %>%
    dplyr::mutate(npts = mapview::npts(geometry, by_feature = TRUE))

  ## Exclude polygons with less than 4 points ..................................
  na_visible <- na_visible %>%
    dplyr::filter(npts >= 4) %>%
    dplyr::select(-npts) %>%
    sf::st_cast('POLYGON')

  ## Fix other broken polygons .................................................
  broken <- which(!sf::st_is_valid(visible))
  for(land in broken) {
    result = suppressWarnings(tryCatch({
      visible[land,] <-
        sf::st_make_valid(visible[land,]) %>%
        sf::st_collection_extract()
    }, error = function(e) {
      visible[land,] <<- sf::st_buffer(visible[land,], 0)
    }))
  }

  ## Bind together the two tables ..............................................
  visible <- suppressMessages(rbind(visible, na_visible))

  ## Berlin location ...........................................................
  sf_berlin_loc <- suppressMessages(
    sf::st_sfc(sf::st_point(c(13.4050, 52.5200)),
               crs = sf::st_crs(d6maps::sf_berlin))
  )

  ## Create globe as ggplot ....................................................
  globe <-
    ggplot2::ggplot() +
    ggplot2::geom_sf(data = circle, fill = "#96b6d8", alpha = .5) +
    ggplot2::geom_sf(data = sf::st_collection_extract(visible),
                     fill = "#a5bf8b", color = NA) +
    ggplot2::geom_sf(data = sf_berlin_loc, color = "black", size = 1.2,
                     shape = 1, stroke = 1.2) +
    ggplot2::geom_sf(data = circle, color = "grey60", fill = NA, size = .5) +
    ggplot2::coord_sf(crs = ortho) +
    ggplot2::theme_void() +
    ggplot2::theme(panel.grid = ggplot2::element_line("grey60", size = .3))

  return(globe)
}
