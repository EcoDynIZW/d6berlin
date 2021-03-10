#' Plot Berlin template map showing imperviousness and green areas
#'
#' @param color_intensity A numeric.  A number to control the desaturation of the color intensity, ranging from 0 (fully desaturated) to 1 (fully saturated).
#' @param resolution A numeric. Resolution of the imperviousness raster in meters, starting from 10m.
#' @param globe A Boolean. If TRUE a inset globe is added to the map.
#' @param print A Boolean. If TRUE prints the map in the viewer pane.
#'
#' @return A ggplot object containing a template map of Berlin.
#'
#' @examples base_map_imp()
#' @examples base_map_imp(color_intensity = 1, globe = TRUE)
#'
#' @import ggplot2
#' @import dplyr
#' @import sf
#' @import stars
#' @import ggspatial
#' @import systemfonts
#' @importFrom magrittr %>%
#' @importFrom  raster aggregate
#'
#' @export
base_map_imp <- function(color_intensity = .5,
                         resolution = 100,
                         globe = FALSE,
                         print = FALSE) {
  message("Aggregating raster data.")

  ## Read 10m raster data (aggregated based on `resolution`)
  fact <- resolution / 10
  ras_imp <- raster::aggregate(d6berlin::ras_imp_orig, fact = fact)
  ## turn into stars object and reproject
  sf_imp <-
    suppressMessages(
      stars::st_as_stars(ras_imp) %>%
        sf::st_transform(crs = sf::st_crs(sf_berlin))
    )

  ## COLOR PALETTE -------------------------------------------------------------
  pal <- scales::alpha(colorRampPalette(c("grey95", "grey5"))(100), color_intensity)
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
                                  limits = c(0, 100)) +
    ## green areas .............................................................
    ggplot2::geom_sf(data = d6berlin::sf_type,
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
      ggplot2::annotation_custom(grob = ggplot2::ggplotGrob(d6berlin::globe()),
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
      text_col = "black",  text_family = "Segoe UI", text_cex = .83,
      pad_x = ggplot2::unit(1.5, "cm"), pad_y = ggplot2::unit(2.4, "cm")
    ) +
    ## caption .................................................................
    ggplot2::annotate("text", x = 13.092, y = 52.35,
                      hjust = 0, vjust = 1, color = "black",
                      label = "Data Berlin Map: OpenStreetMap Contributors\nData World Map: Natural Earth",
                      family = "Segoe UI",
                      size = 3.6,
                      lineheight = .95) +
    ggplot2::theme_void() +
    ggplot2::theme(plot.margin = ggplot2::margin(20, 30, 20, 30),
                   legend.position = c(.5, .075),
                   text = ggplot2::element_text(family = "Segoe UI")) +
    ggplot2::guides(fill = ggplot2::guide_colorbar(direction = "horizontal",
                                                   title.position = "top",
                                                   title.hjust = .5,
                                                   barwidth = ggplot2::unit(15, "lines"),
                                                   barheight = ggplot2::unit(.5, "lines")))

  if (print == TRUE) { suppressMessages(print(g)) }

  return(g)
}

