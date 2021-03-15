
<!-- README.md is generated from README.Rmd. Please edit that file -->

# d6berlin

<!-- badges: start -->
<!-- badges: end -->

> The `d6berlin` package aims to provide template maps for Berlin with
> carefully chosen and aesthetically pleasing defaults. Template maps
> include green spaces, imperviousness levels, water bodeis, district
> borders, and roads plus the utility to add a globe with locator pin, a
> scalebar, and a caption to include the data sources. All objects are
> returned as `ggplot` objects.

<br>

------------------------------------------------------------------------

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

------------------------------------------------------------------------

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
add a globe with a locator pin and change the resolution of the raster:

``` r
base_map_imp(color_intensity = 1, globe = TRUE, resolution = 500)
```

<img src="man/figures/README-example-custom-1.png" width="100%" />

<br>

------------------------------------------------------------------------

<br>

## Adding Locations to the Map

Let’s assume you have recorded some animal locations or you want to plot
another information on to of this plot. For example, let’s visualize the
Berlin metro stations by adding `geom_sf(data = )` to the template map:

``` r
library(ggplot2)
library(sf)

map <- base_map_imp(color_intensity = .3, resolution = 250)

map + geom_sf(data = sf_metro)
```

<img src="man/figures/README-example-add-points-1.png" width="100%" />

**Note:** Since the template map contains many filled areas, we
recommend to add only point or line geometries (or maybe polygon
geometries without a filling) to the template maps

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

------------------------------------------------------------------------

<br>

## Custom Styling

Since the output is a `ggplot` object, you can manipulate the result as
you like (but don’t apply a new theme, this will mess up the legend
design):

``` r
library(systemfonts) ## for title font

map + 
  geom_sf(data = sf_metro, shape = 21, fill = "white", 
          stroke = .4, size = 2.5) +
  ggtitle("Metro Stations in Berlin") + 
  theme(plot.title = element_text(size = 30, hjust = .5, family = "Bangers"),
        panel.grid.major = element_line(color = "white", size = .3),
        axis.text = element_text(color = "black", size = 8),
        plot.background = element_rect(fill = "bisque", color = NA))
```

<img src="man/figures/README-example-styling-1.png" width="100%" />

<br>

------------------------------------------------------------------------

<br>

## Save Map

Unfortunately, the size of the text elements is fixed. The best aspect
ratio to export the map is 12x9.5 and you can save it with `ggsave()`
for example:

``` r
ggsave("metro_map.pdf", width = 12, height = 9.5, device = cairo_pdf)
```

<br>

------------------------------------------------------------------------

<br>

#### Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

<div style="width:300px; height:200px">

<img src=https://camo.githubusercontent.com/00f7814990f36f84c5ea74cba887385d8a2f36be/68747470733a2f2f646f63732e636c6f7564706f7373652e636f6d2f696d616765732f63632d62792d6e632d73612e706e67 alt="" height="42">

</div>

<details>
<summary>
Session Info
</summary>

``` r
Sys.time()
#> [1] "2021-03-15 11:37:30 CET"
git2r::repository()
#> Local:    main C:/Users/DataVizard/PopDynIZW Dropbox/GeoData/d6berlin
#> Remote:   main @ origin (https://github.com/EcoDynIZW/d6berlin.git)
#> Head:     [e30d700] 2021-03-15: :bug: fix warning font family + caption
sessionInfo()
#> R version 4.0.2 (2020-06-22)
#> Platform: x86_64-w64-mingw32/x64 (64-bit)
#> Running under: Windows 10 x64 (build 19041)
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
#> [1] systemfonts_1.0.1   stringr_1.4.0       dplyr_1.0.4        
#> [4] sf_0.9-7            ggplot2_3.3.3       d6berlin_0.0.0.9000
#> 
#> loaded via a namespace (and not attached):
#>  [1] Rcpp_1.0.6          rnaturalearth_0.1.0 lattice_0.20-41    
#>  [4] png_0.1-7           class_7.3-17        assertthat_0.2.1   
#>  [7] digest_0.6.27       R6_2.5.0            stats4_4.0.2       
#> [10] evaluate_0.14       e1071_1.7-4         highr_0.8          
#> [13] pillar_1.4.7        rlang_0.4.10        raster_3.4-5       
#> [16] rmarkdown_2.6       textshaping_0.3.0   labeling_0.4.2     
#> [19] webshot_0.5.2       htmlwidgets_1.5.3   munsell_0.5.0      
#> [22] compiler_4.0.2      xfun_0.20           pkgconfig_2.0.3    
#> [25] base64enc_0.1-3     rgeos_0.5-5         htmltools_0.5.1.1  
#> [28] tidyselect_1.1.0    tibble_3.0.6        codetools_0.2-16   
#> [31] mapview_2.9.0       withr_2.4.1         crayon_1.4.0       
#> [34] grid_4.0.2          lwgeom_0.2-5        satellite_1.0.2    
#> [37] gtable_0.3.0        lifecycle_0.2.0     DBI_1.1.1          
#> [40] git2r_0.28.0        magrittr_2.0.1      units_0.6-7        
#> [43] scales_1.1.1        KernSmooth_2.23-17  stringi_1.5.3      
#> [46] farver_2.0.3        leaflet_2.0.4.1     sp_1.4-5           
#> [49] ellipsis_0.3.1      ragg_1.1.0          generics_0.1.0     
#> [52] vctrs_0.3.6         RColorBrewer_1.1-2  tools_4.0.2        
#> [55] ggspatial_1.1.5     leafem_0.1.3        glue_1.4.2         
#> [58] purrr_0.3.4         crosstalk_1.1.1     abind_1.4-5        
#> [61] parallel_4.0.2      yaml_2.2.1          colorspace_2.0-0   
#> [64] stars_0.5-1         classInt_0.4-3      knitr_1.31
```

</details>
