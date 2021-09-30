#' Plot Berlin template map showing imperviousness and green areas
#'
#' @param color_intensity A numeric.  A number to control the desaturation of
#'                        the color intensity, ranging from 0 (fully
#'                        desaturated) to 1 (fully saturated).
#' @param resolution A numeric. Resolution of the imperviousness raster in
#'                   meters, starting from 10m.
#' @param globe A Boolean. If TRUE a inset globe is added to the map.
#' @param legend A string. Either "bottom", "top", or "none". Otherwise specify
#'               positions via legend_x and legend_y
#' @param legend_x A numeric. Horizontal position of the legend (0–1)
#' @param legend_y A numeric. Vertical position of the legend (0–1)
#' @param print A Boolean. If TRUE prints the map in the viewer pane.
#'
#' @return A ggplot object containing a template map of Berlin.
#'
#' @importFrom magrittr %>%
#'
#' @examples
#' \dontrun{
#' base_map_imp()
#' base_map_imp(resolution = 500, color_intensity = 1, globe = TRUE,
#'              legend_x = .17, legend_y = .12)
#' base_map_imp(resolution = 500, color_intensity = 1, legend = "top")
#' }
#'
#' @export
base_map_imp <- function(color_intensity = .5,
                         resolution = 100,
                         globe = FALSE,
                         legend = "bottom",
                         legend_x = NULL,
                         legend_y = NULL,
                         print = FALSE) {

  if(!dplyr::between(color_intensity, 0, 1)) stop("color_intensity must be a value between 0 and 1.")
  if(!is.numeric(resolution) | resolution < 10) stop("resolution must be a numeric value of 10 or greater.")
  if(!is.logical(globe)) stop("globe must be a boolean value (TRUE or FALSE).")
  if(!is.logical(print)) stop("print must be a boolean value (TRUE or FALSE).")
  if(!legend %in% c("none", "bottom", "top") | !exists("legend_x") | !exists("legend_y")) stop('Please provide as legend position: either "bottom", "top", or "none" or specify a custom legend position via legend_x and legend_y.')
  if(isTRUE(globe) & legend == "top") stop("When using a globe, the legend should be placed at the bottom. Or specify a custom legend position via legend_x and legend_y.")
  if(!is.null(legend_x)) { if (!is.numeric(legend_x) | legend_x > 1 | legend_y < 0) stop("legend_x must be a numeric value between 0 and 1.") }
  if(!is.null(legend_y)) { if (!is.numeric(legend_y) | legend_x > 1 | legend_y < 0) stop("legend_y must be a numeric value between 0 and 1.") }

  if (is.null(legend_x) & legend == "bottom") { legend_x <- .5; legend_y <- .075 }
  if (is.null(legend_x) & legend == "top") { legend_x <- .82; legend_y <- .85 }
  if (legend %in% c("none", "None")) leg <- "none" else leg <- "colourbar"

  message("Aggregating raster data.")

  ## load data
  # ras_imp <- data(ras_imp_orig)
  # sf_berlin <- data(sf_berlin)
  # sf_green <- data(sf_green)
  # sf_water <- data(sf_water)
  ras_imp_orig <- raster::raster(system.file("extdata", "imperviousness_berlin_copernicus_raster_10m_2018_3035.tif", package = "d6berlin"))


  ## Read 10m raster data (aggregated based on `resolution`)
  fact <- resolution / 10
  ras_imp <- raster::aggregate(ras_imp_orig, fact = fact)
  ## turn into stars object and reproject
  sf_imp <-
    suppressMessages(
      stars::st_as_stars(ras_imp) %>%
        sf::st_transform(crs = sf::st_crs(d6berlin::sf_berlin))
    )

  ## COLOR PALETTE -------------------------------------------------------------
  pal <- scales::alpha(
    grDevices::colorRampPalette(c("grey95", "grey5"))(100), color_intensity
  )
  col_type <-
    colorspace::desaturate(
      colorspace::lighten("#a5bf8b", (1 - color_intensity) / 1.3),
      (1 - color_intensity) / 1.3
    )
  col_water <-
    colorspace::desaturate(
      colorspace::lighten("#a9c3df", (1 - color_intensity) / 1.5),
      (1 - color_intensity) / 1.5
    )

  ## CAPTION TEXT --------------------------------------------------------------
  caption <- "Data Berlin Map: OpenStreetMap & Geoportal Berlin"
  if (globe == TRUE) {
    caption <- paste0(caption, "\nData World Map: Natural Earth")
  }

  ## BERLIN MAP ----------------------------------------------------------------
  message("Plotting basic map.")
  g <- ggplot2::ggplot() +
    ## background filling ......................................................
    ggplot2::geom_sf(data = d6berlin::sf_berlin,
                     fill = "white",
                     color = NA) +
    ## imperviousness ..........................................................
    stars::geom_stars(data = sf_imp) +
    ggplot2::labs(fill = "Imperviousness Level") +
    ggplot2::scale_fill_gradientn(colors = pal,
                                  labels = function(x) paste0(x, "%"),
                                  limits = c(0, 100),
                                  guide = leg) +
    ## green areas .............................................................
    ggplot2::geom_sf(data = d6berlin::sf_green,
                     fill = col_type,
                     color = col_type,
                     lwd = 0.05) +
    ## waterways ...............................................................
    ggplot2::geom_sf(data = d6berlin::sf_water,
                     fill = col_water,
                     color = col_water)

  ## ADD INSET GLOBE -----------------------------------------------------------
  if (globe == TRUE) {
    message("Adding inset globe.")

    g <- g +
      ## inset globe ...........................................................
      ggplot2::annotation_custom(grob = ggplot2::ggplotGrob(
                                          d6berlin::globe(col_earth = "#B7D19D",
                                                          col_water = "#A9C9EB",
                                                          bg = TRUE)
                                        ),
                                 xmin = 13.6, xmax = 13.75,
                                 ymin = 52.55, ymax = 52.7) +
      ggplot2::theme_void()
  }

  ## OTHER MAP FEATURES: SCALEBAR, CREDIT, THEMING -----------------------------
  message("Styling map.")
  g <- g +
    ggplot2::coord_sf(clip = "off") +
    ## scalebar ................................................................
    ggspatial::annotation_scale(
      location = "bl", height = ggplot2::unit(.3, "cm"),
      line_width = 1.3, width_hint = .36,
      text_col = "black", text_cex = .83, #text_family = font_family,
      pad_x = ggplot2::unit(1.5, "cm"), pad_y = ggplot2::unit(1.5, "cm")
    ) +
    ## caption .................................................................
    ggplot2::annotate("text", x = 13.09, y = 52.34, label = caption,
                      hjust = 0, vjust = 1, color = "black",
                      #family = font_family,
                      size = 3.4, lineheight = .95) +
    ggplot2::theme_void() +
    ggplot2::theme(plot.margin = ggplot2::margin(0, 10, 0, 10),
                   #text = ggplot2::element_text(family = font_family),
                   legend.position = c(legend_x, legend_y))

  if (legend != "none") {
    g <- g +
      ggplot2::guides(fill = ggplot2::guide_colorbar(direction = "horizontal",
                                                     title.position = "top",
                                                     title.hjust = .5,
                                                     barwidth = ggplot2::unit(13, "lines"),
                                                     barheight = ggplot2::unit(.5, "lines")))
  }

  if (print == TRUE) { suppressMessages(print(g)) }

  return(g)
}

