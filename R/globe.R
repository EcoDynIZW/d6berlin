#' Plot Globe with Locator Pin for Berlin (while preserving polygons in orthographic view)
#'
#' @param center A vector with longitude and latitude (WGS 84) used to center
#'               the globe and for the locator circle.
#' @param col_water A hex code. Color used for oceans.
#' @param col_earth A hex code. Color used for continents.
#' @param col_pin A hex code. Color used for te locator circle.
#' @param size_pin A positive number indicating the symbol size and stroke of
#'                 the locator circle.
#' @param bg A Boolean. Should a background be added to the globe?
#'
#' @return A ggplot object containing a locator globe with pin.
#'
#' @examples
#' \dontrun{
#' globe()
#' }
#'
#' @export
globe <- function(center = c(13.4050, 52.5200), col_earth = "#a5bf8b", col_water = "#96b6d8",
                  col_pin = "black", size_pin = 1.2, bg = TRUE) {

  ## code to preserve orthpgraphic view from this gist:
  ## https://gist.github.com/fzenoni/ef23faf6d1ada5e4a91c9ef23b0ba2c1
  ## via this issue: https://github.com/r-spatial/sf/issues/1050

  ## Define the orthographic projection ........................................
  lon <- center[1]
  lat <- center[2]

  ## for Berlin adjust latitude, otherwise use center[2] as provided to keep it generic
  if(identical(center, c(13.4050, 52.5200))) { lat <- 32 }

  ortho <- paste0('+proj=ortho +lat_0=', lat, ' +lon_0=', lon,
                  ' +x_0=0 +y_0=0 +a=6371000 +b=6371000 +units=m +no_defs')

  ## Define the polygon to split what lies within and without your projection ..
  circle <-
    suppressMessages(
      sf::st_point(x = c(0, 0)) |>
        sf::st_buffer(dist = 6371000) |>
        sf::st_sfc(crs = ortho)
    )

  ## Project this polygon in lat-lon ...........................................
  circle_longlat <-
    circle |>
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
      sf::st_linestring(circle_coords) |>
      sf::st_sfc(crs = 4326)

    if(lat > 0) {
      rectangle <- list(rbind(circle_coords,
                              c(X = 180, circle_coords[nrow(circle_coords), 'Y']),
                              c(X = 180, Y = 90),
                              c(X = -180, Y = 90),
                              c(X = -180, circle_coords[1, 'Y']),
                              circle_coords[1, c('X','Y')])) |>
        sf::st_polygon() |>
        sf::st_sfc(crs = 4326)
    } else {
      rectangle <- list(rbind(circle_coords,
                              c(X = 180, circle_coords[nrow(circle_coords), 'Y']),
                              c(X = 180, Y = -90),
                              c(X = -180, Y = -90),
                              c(X = -180, circle_coords[1, 'Y']),
                              circle_coords[1, c('X','Y')])) |>
        sf::st_polygon() |>
        sf::st_sfc(crs = 4326)
    }

    circle_longlat <- suppressMessages(sf::st_union(
      sf::st_make_valid(circle_longlat),
      sf::st_make_valid(rectangle))
    )
  }

  ## A small negative buffer is necessary to avoid polygons still disappearing
  ## in a few pathological cases ...............................................
  ## Comment Cédric: Doesn't work with -.09 anymore, returns empty object.
  ##                 But works also without the buffer, so using 0 here to
  ##                 return the same type of object.
  visible <- suppressMessages(suppressWarnings(
    sf::st_intersection(sf::st_make_valid(d6berlin::sf_world),
                        sf::st_buffer(circle_longlat, 0)) |>
    sf::st_transform(crs = ortho)
  ))

  ## Get reason why polygons are broken ........................................
  broken_reason <- sf::st_is_valid(visible, reason = TRUE)

  ## First fix NA's by decomposing them ........................................
  na_visible <- visible[is.na(broken_reason),]
  visible <- visible[!is.na(broken_reason),]

  ## Open and close polygons ...................................................
  na_visible <- sf::st_cast(na_visible, 'MULTILINESTRING') |>
    sf::st_cast('LINESTRING', do_split = TRUE)
  na_visible <- na_visible |>
    #dplyr::mutate(npts = mapview::npts(geometry, by_feature = TRUE))
    dplyr::mutate(id = dplyr::row_number()) |>
    dplyr::add_count(id, name = "npts")

  ## Exclude polygons with less than 4 points ..................................
  na_visible <- na_visible |>
    dplyr::filter(npts >= 4) |>
    dplyr::select(-npts) |>
    sf::st_cast('POLYGON')

  ## Fix other broken polygons .................................................
  broken <- which(!sf::st_is_valid(visible))
  for(land in broken) {
    result = suppressWarnings(tryCatch({
      visible[land,] <-
        sf::st_make_valid(visible[land,]) |>
        sf::st_collection_extract()
    }, error = function(e) {
      visible[land,] <<- sf::st_buffer(visible[land,], 0)
    }))
  }

  ## Bind together the two tables ..............................................
  visible <- suppressMessages(rbind(visible, na_visible))

  ## Berlin location ...........................................................
  sf_berlin_loc <- suppressMessages(
    sf::st_sfc(sf::st_point(center),
               crs = sf::st_crs(d6berlin::sf_berlin))
  )

  ## Create globe as ggplot ....................................................
  globe <-
    ggplot2::ggplot()

  if (isTRUE(bg)) {
    globe <- globe +
      ggplot2::geom_sf(data = circle, fill = "white", color = "transparent")
  }


  int <- sf::st_intersection(sf::st_collection_extract(visible), sf::st_collection_extract(visible))
  sf_inner <- int[int$sov_a3 != int$sov_a3.1 ,]

  globe <- globe +
    ggplot2::geom_sf(data = circle, fill = col_water, alpha = .5) +
    ggplot2::geom_sf(data = sf::st_collection_extract(visible),
                     fill = col_earth, color = "transparent") +
    ggplot2::geom_sf(data = sf_inner, color = col_earth, lwd = .3) +
    ggplot2::geom_sf(data = sf_berlin_loc, color = col_pin, size = size_pin,
                     shape = 1, stroke = size_pin) +
    ggplot2::geom_sf(data = circle, color = "grey60", fill = NA, size = .5) +
    ggplot2::coord_sf(crs = ortho) +
    ggplot2::theme_void()

  return(globe)
}
