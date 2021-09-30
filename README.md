
<!-- README.md is generated from README.Rmd. Please edit that file -->

# d6berlin

<!-- badges: start -->
<!-- badges: end -->

> The `d6berlin` package aims to provide template maps for Berlin with
> carefully chosen and aesthetically pleasing defaults. Template maps
> include green spaces, imperviousness levels, water boders, district
> borders, and roads plus the utility to add a globe with locator pin, a
> scalebar, and a caption to include the data sources. All objects are
> returned as `ggplot` objects.

<br>

# 

<br>

## Installation

You can install the `d6berlin` package from GitHub:

``` r
install.packages("devtools")
devtools::install_github("EcoDynIZW/d6berlin")
```

(Note: If you are asked if you want to update other packgaes either
press “No” (option 3) and continue or update the packages before running
the install command again.)

<br>

# 

<br>

## A Basic Template Map of Imperviousness

The basic template map shows levels of imperviousness and green areas in
Berlin. The imperviousness raster data was derived from [Geoportal
Berlin (FIS-Broker)]() with a resolution of 10m. The vector data on
green spaces was collected from data provided by the [OpenStreetMap
Contributors](https://www.openstreetmap.org/). The green spaces consist
of a mixture of landuse and natural categories (namely “forest”,
“grass”, “meadow”, “nature\_reserve”, “scrub”, “heath”, “beach”,
“cliff”).

The map is projected in **EPSG 4326 (WGS84)**.

``` r
library(d6berlin)

base_map_imp()
```

<img src="man/figures/README-example-basic-1.png" width="100%" />

You can also customize the arguments, e.g. change the color intensity,
add a globe with a locator pin, change the resolution of the raster, and
move the legend to a custom position:

``` r
base_map_imp(color_intensity = 1, globe = TRUE, resolution = 500,
             legend_x = .17, legend_y = .12)
```

<img src="man/figures/README-example-custom-1.png" width="100%" />

If you think the legend is absolute, there is also an option called
`"none"`. (The default is `"bottom"`. You can also use of the predefined
setting `"top"` as illustrated below or a custom position as shown in
the previous example.)

<br>

# 

<br>

## Adding Locations to the Map

Let’s assume you have recorded some animal locations or you want to plot
another information on to of this plot. For example, let’s visualize the
Berlin metro stations by adding `geom_sf(data = x)` to the template map:

``` r
library(ggplot2)
library(sf)

map <- base_map_imp(color_intensity = .3, resolution = 250, legend = "top")

map + geom_sf(data = sf_metro) ## sf_metro is contained in the d6berlin package
```

<img src="man/figures/README-example-add-points-1.png" width="100%" />

**Note:** Since the template map contains many filled areas, we
recommend to add geometries with variables mapped to `color|xolour|col`
to the template maps.

You can, of course, style the appearance of the points as usual:

``` r
map + geom_sf(data = sf_metro, shape = 8, color = "red", size = 2)
```

<img src="man/figures/README-example-points-custom-1.png" width="100%" />

It is also possible to filter the data inside the `geom_sf` function —
no need to use `subset`:

``` r
library(dplyr) ## for filtering
library(stringr) ## for filtering based on name

map + 
  geom_sf(data = filter(sf_metro, str_detect(name, "^U")), 
          shape = 21, fill = "dodgerblue", size = 2) +
  geom_sf(data = filter(sf_metro, str_detect(name, "^S")), 
          shape = 21, fill = "forestgreen", size = 2)
```

<img src="man/figures/README-example-points-filter-1.png" width="100%" />

You can also use the `mapping` functionality of ggplot2 to address
variables from your data set:

``` r
map + 
  geom_sf(data = sf_metro, aes(color = internet_access), size = 2) +
  scale_color_brewer(palette = "Dark2", 
                     name = "Internet Access?",
                     na.value = "grey60") +
  guides(color = guide_legend(direction = "horizontal",
                              title.position = "top", 
                              title.hjust = .5))
```

<img src="man/figures/README-example-points-filter-aes-1.png" width="100%" />

(It looks better if you style the legend in the same horizontal layout.)

<br>

# 

<br>

## Custom Styling

Since the output is a `ggplot` object, you can manipulate the result as
you like (but don’t apply a new theme, this will mess up the legend
design):

``` r
library(systemfonts) ## for title font

base_map_imp(color_intensity = 1, resolution = 250, globe = TRUE,
             legend_x = .17, legend_y = .12) + 
  geom_sf(data = sf_metro, shape = 21, fill = "white", 
          stroke = .4, size = 4) +
  ggtitle("Metro Stations in Berlin") + 
  theme(plot.title = element_text(size = 30, hjust = .5, family = "Bangers"),
        panel.grid.major = element_line(color = "white", size = .3),
        axis.text = element_text(color = "black", size = 8),
        plot.background = element_rect(fill = "#fff0de", color = NA),
        plot.margin = margin(rep(20, 4)))
```

<img src="man/figures/README-example-styling-1.png" width="100%" />

<br>

# 

<br>

## Save Map

Unfortunately, the size of the text elements is fixed. The best aspect
ratio to export the map is 12x9 and you can save it with `ggsave()` for
example:

``` r
ggsave("metro_map.pdf", width = 12, height = 9, device = cairo_pdf)
```

<br>

# 

<details>
<summary>
Session Info
</summary>

``` r
Sys.time()
#> [1] "2021-09-27 12:23:19 CEST"
git2r::repository()
#> Local:    main C:/Users/DataVizard/PopDynIZW Dropbox/GeoData/d6berlin
#> Remote:   main @ origin (https://github.com/EcoDynIZW/d6berlin.git)
#> Head:     [9020e1d] 2021-05-04: :memo: update readme
sessionInfo()
#> R version 4.1.0 (2021-05-18)
#> Platform: x86_64-w64-mingw32/x64 (64-bit)
#> Running under: Windows 10 x64 (build 19043)
#> 
#> Matrix products: default
#> 
#> locale:
#> [1] LC_COLLATE=German_Germany.1252  LC_CTYPE=German_Germany.1252   
#> [3] LC_MONETARY=German_Germany.1252 LC_NUMERIC=C                   
#> [5] LC_TIME=German_Germany.1252    
#> system code page: 65001
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] systemfonts_1.0.2   stringr_1.4.0       dplyr_1.0.7        
#> [4] sf_1.0-2            ggplot2_3.3.5       d6berlin_0.0.0.9000
#> 
#> loaded via a namespace (and not attached):
#>  [1] Rcpp_1.0.7          rnaturalearth_0.1.0 lattice_0.20-44    
#>  [4] png_0.1-7           class_7.3-19        assertthat_0.2.1   
#>  [7] digest_0.6.28       utf8_1.2.2          R6_2.5.1           
#> [10] stats4_4.1.0        evaluate_0.14       e1071_1.7-9        
#> [13] highr_0.9           pillar_1.6.3        rlang_0.4.11       
#> [16] raster_3.4-13       rmarkdown_2.11      textshaping_0.3.5  
#> [19] labeling_0.4.2      webshot_0.5.2       rgdal_1.5-27       
#> [22] htmlwidgets_1.5.4   munsell_0.5.0       proxy_0.4-26       
#> [25] compiler_4.1.0      xfun_0.26           pkgconfig_2.0.3    
#> [28] base64enc_0.1-3     rgeos_0.5-8         htmltools_0.5.2    
#> [31] tidyselect_1.1.1    tibble_3.1.4        codetools_0.2-18   
#> [34] mapview_2.10.0      fansi_0.5.0         withr_2.4.2        
#> [37] crayon_1.4.1        wk_0.5.0            grid_4.1.0         
#> [40] satellite_1.0.2     lwgeom_0.2-7        gtable_0.3.0       
#> [43] lifecycle_1.0.1     DBI_1.1.1           git2r_0.28.0       
#> [46] magrittr_2.0.1      units_0.7-2         scales_1.1.1       
#> [49] KernSmooth_2.23-20  stringi_1.7.4       farver_2.1.0       
#> [52] leaflet_2.0.4.1     sp_1.4-5            ellipsis_0.3.2     
#> [55] ragg_1.1.3          generics_0.1.0      vctrs_0.3.8        
#> [58] RColorBrewer_1.1-2  s2_1.0.6            tools_4.1.0        
#> [61] ggspatial_1.1.5     leafem_0.1.6        glue_1.4.2         
#> [64] purrr_0.3.4         crosstalk_1.1.1     abind_1.4-5        
#> [67] parallel_4.1.0      fastmap_1.1.0       yaml_2.2.1         
#> [70] colorspace_2.0-2    stars_0.5-3         classInt_0.4-3     
#> [73] knitr_1.34
```

</details>

------------------------------------------------------------------------

<br>

#### Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

<div style="width:300px; height:200px">

<img src=https://camo.githubusercontent.com/00f7814990f36f84c5ea74cba887385d8a2f36be/68747470733a2f2f646f63732e636c6f7564706f7373652e636f6d2f696d616765732f63632d62792d6e632d73612e706e67 alt="" height="42">

</div>
