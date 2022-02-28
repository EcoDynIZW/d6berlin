
<!-- README.md is generated from README.Rmd. Please edit that file -->

# d6berlin <img src='man/figures/hexlogo.png' align="right" height="151.5" /></a>

<!-- badges: start -->
<!-- badges: end -->

> The `d6berlin` package aims to provide spatial data and template maps
> for Berlin. The data sets include green spaces, water bodies, district
> borders, raleways and more. A template map of imperviousness across
> Berlin with carefully chosen and aesthetically pleasing default is
> included to serve as a base map to visualize spatial data.

<br>

# 

<br>

## Installation

You can install the `d6berlin` package from GitHub:

``` r
install.packages("devtools")
devtools::install_github("EcoDynIZW/d6berlin")
```

(Note: If you are asked if you want to update other packages either
press “No” (option 3) and continue or update the packages before running
the install command again.)

Afterwards, load the functionality and data of the package in each
session:

``` r
library(d6berlin)
```

<br>

# 

<br>

## Spatial Data Sets

The following data sets are stored as *simple feature objects* and
directly accessible:

``` text
sf_berlin      -- Berlin border
sf_districts   -- district borders
sf_green       -- green spaces
sf_metro       -- U- and S-train stations
sf_railways    -- railroad lines
sf_roads       -- motorways and streets
sf_water       -- water ways and bodies
```

More information about each data set is available in the help:

``` r
?sf_green
```

> An sf object containing the shape of all green spaces (defined as
> natural areas and landuse categories “forest”, “grass”, “meadow”,
> “nature_reserve”, “scrub”, “heath”, “beach”, and “cliff”) in Berlin.

Furthermore, you can work with the spatial data as you usually do:

``` r
unique(sf_green$fclass)
#> [1] "scrub"          "grass"          "forest"         "meadow"        
#> [5] "nature_reserve" "beach"          "heath"          "cliff"

sf_forests <- subset(sf_green, fclass == "forest")
head(sf_forests)
#>      osm_id code fclass                                      name district_name
#> 3   5643109 7201 forest                                      <NA> Reinickendorf
#> 9   3085634 7201 forest                                      <NA> Reinickendorf
#> 11 23353374 7201 forest                                Lindwerder Reinickendorf
#> 18 24482177 7201 forest                                      <NA> Reinickendorf
#> 19  3085413 7201 forest NABU-Schutzgebiet "Kiesgrube am Dachsbau" Reinickendorf
#> 24 27835164 7201 forest                                      <NA> Reinickendorf
#>    district_id district_key
#> 3          012     11000012
#> 9          012     11000012
#> 11         012     11000012
#> 18         012     11000012
#> 19         012     11000012
#> 24         012     11000012
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      geometry
#> 3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  13.30093, 13.30307, 13.30134, 13.30135, 13.30119, 13.30141, 13.30175, 13.30200, 13.29922, 13.29798, 13.29799, 13.29805, 13.29884, 13.29909, 13.29912, 13.29940, 13.29941, 13.29844, 13.29789, 13.29774, 13.29672, 13.29651, 13.29634, 13.29621, 13.29612, 13.29606, 13.29605, 13.29607, 13.29614, 13.29629, 13.29639, 13.29640, 13.29686, 13.30015, 13.30049, 13.30071, 13.30075, 13.30080, 13.30093, 13.30093, 52.54882, 52.55141, 52.55182, 52.55185, 52.55195, 52.55221, 52.55212, 52.55248, 52.55318, 52.55118, 52.55107, 52.55108, 52.55118, 52.55030, 52.55019, 52.55020, 52.54961, 52.54954, 52.54948, 52.55007, 52.54997, 52.54993, 52.54987, 52.54980, 52.54971, 52.54961, 52.54950, 52.54938, 52.54926, 52.54901, 52.54889, 52.54889, 52.54888, 52.54883, 52.54883, 52.54882, 52.54882, 52.54882, 52.54882, 52.54882, 13.29668, 13.29685, 13.29709, 13.29732, 13.29752, 13.29772, 13.29795, 13.29817, 13.29839, 13.29858, 13.29883, 13.29908, 13.29929, 13.29951, 13.29975, 13.29996, 13.30020, 13.30022, 13.29995, 13.29975, 13.29950, 13.29929, 13.29907, 13.29882, 13.29857, 13.29837, 13.29815, 13.29794, 13.29771, 13.29751, 13.29731, 13.29708, 13.29686, 13.29666, 13.29668, 52.54915, 52.54915, 52.54915, 52.54915, 52.54914, 52.54914, 52.54914, 52.54914, 52.54913, 52.54913, 52.54913, 52.54912, 52.54912, 52.54912, 52.54912, 52.54911, 52.54911, 52.54887, 52.54887, 52.54887, 52.54888, 52.54888, 52.54889, 52.54889, 52.54889, 52.54890, 52.54890, 52.54890, 52.54891, 52.54891, 52.54892, 52.54892, 52.54892, 52.54893, 52.54915, 13.29944, 13.29998, 13.29998, 13.29944, 13.29944, 52.55188, 52.55188, 52.55155, 52.55155, 52.55188, 13.29999, 13.30122, 13.30125, 13.30126, 13.30095, 13.29969, 13.29999, 52.55279, 52.55251, 52.55248, 52.55243, 52.55208, 52.55232, 52.55279
#> 9  13.35432, 13.35450, 13.35454, 13.35613, 13.35719, 13.35764, 13.35661, 13.35676, 13.35866, 13.35875, 13.35939, 13.35938, 13.35978, 13.35981, 13.35989, 13.36005, 13.36008, 13.36009, 13.36009, 13.36010, 13.36012, 13.36014, 13.36031, 13.36034, 13.36035, 13.36036, 13.36036, 13.36038, 13.36040, 13.36058, 13.36060, 13.36063, 13.36063, 13.36063, 13.36065, 13.36068, 13.36083, 13.36109, 13.36131, 13.36142, 13.36157, 13.36171, 13.36185, 13.36189, 13.36188, 13.36212, 13.36234, 13.36246, 13.36257, 13.36258, 13.36271, 13.36280, 13.36288, 13.36294, 13.36293, 13.36286, 13.36286, 13.36316, 13.36352, 13.36385, 13.36373, 13.36356, 13.36360, 13.36344, 13.36330, 13.36321, 13.36315, 13.36312, 13.36298, 13.36286, 13.36262, 13.36248, 13.36249, 13.36238, 13.36245, 13.36258, 13.36269, 13.36284, 13.36276, 13.36155, 13.36154, 13.36119, 13.36120, 13.36117, 13.36076, 13.36071, 13.36066, 13.36050, 13.36017, 13.36032, 13.35907, 13.35855, 13.35849, 13.35843, 13.35829, 13.35821, 13.35835, 13.35842, 13.35842, 13.35843, 13.35842, 13.35840, 13.35835, 13.35831, 13.35827, 13.35823, 13.35820, 13.35817, 13.35737, 13.35653, 13.35439, 13.35434, 13.35431, 13.35432, 52.56476, 52.56471, 52.56467, 52.56487, 52.56501, 52.56398, 52.56381, 52.56352, 52.56340, 52.56347, 52.56331, 52.56336, 52.56334, 52.56321, 52.56319, 52.56317, 52.56317, 52.56316, 52.56316, 52.56316, 52.56317, 52.56316, 52.56314, 52.56315, 52.56314, 52.56314, 52.56314, 52.56314, 52.56314, 52.56313, 52.56313, 52.56312, 52.56312, 52.56312, 52.56313, 52.56312, 52.56313, 52.56314, 52.56315, 52.56317, 52.56319, 52.56321, 52.56324, 52.56325, 52.56328, 52.56334, 52.56341, 52.56347, 52.56353, 52.56353, 52.56362, 52.56371, 52.56380, 52.56387, 52.56397, 52.56405, 52.56415, 52.56415, 52.56415, 52.56421, 52.56444, 52.56440, 52.56434, 52.56431, 52.56433, 52.56452, 52.56450, 52.56457, 52.56455, 52.56468, 52.56498, 52.56508, 52.56509, 52.56517, 52.56522, 52.56524, 52.56527, 52.56532, 52.56535, 52.56559, 52.56557, 52.56564, 52.56568, 52.56568, 52.56569, 52.56578, 52.56577, 52.56614, 52.56609, 52.56571, 52.56547, 52.56540, 52.56544, 52.56556, 52.56576, 52.56575, 52.56553, 52.56542, 52.56540, 52.56538, 52.56535, 52.56533, 52.56533, 52.56532, 52.56531, 52.56530, 52.56528, 52.56526, 52.56515, 52.56504, 52.56477, 52.56477, 52.56478, 52.56476, 13.35908, 13.35910, 13.35915, 13.35919, 13.35921, 13.35924, 13.35925, 13.35924, 13.35923, 13.35920, 13.35918, 13.35916, 13.35911, 13.35908, 13.35924, 13.35941, 13.35951, 13.35968, 13.35986, 13.36007, 13.36018, 13.36030, 13.36080, 13.36103, 13.36109, 13.36131, 13.36147, 13.36161, 13.36169, 13.36182, 13.36192, 13.36199, 13.36234, 13.36250, 13.36262, 13.36262, 13.36258, 13.36254, 13.36252, 13.36251, 13.36242, 13.36229, 13.36214, 13.36205, 13.36194, 13.36176, 13.36162, 13.36146, 13.36134, 13.36120, 13.36092, 13.36066, 13.36050, 13.36034, 13.36020, 13.35999, 13.35985, 13.35979, 13.35980, 13.35968, 13.35964, 13.35957, 13.35950, 13.35946, 13.35943, 13.35937, 13.35939, 13.35928, 13.35921, 13.35917, 13.35910, 13.35908, 13.35908, 52.56463, 52.56467, 52.56470, 52.56470, 52.56471, 52.56473, 52.56475, 52.56476, 52.56479, 52.56480, 52.56480, 52.56480, 52.56483, 52.56491, 52.56509, 52.56519, 52.56523, 52.56528, 52.56533, 52.56537, 52.56539, 52.56540, 52.56540, 52.56538, 52.56536, 52.56534, 52.56531, 52.56530, 52.56528, 52.56525, 52.56522, 52.56519, 52.56494, 52.56481, 52.56456, 52.56445, 52.56436, 52.56423, 52.56399, 52.56395, 52.56385, 52.56374, 52.56364, 52.56358, 52.56353, 52.56345, 52.56342, 52.56339, 52.56339, 52.56340, 52.56340, 52.56344, 52.56347, 52.56352, 52.56356, 52.56366, 52.56373, 52.56373, 52.56375, 52.56379, 52.56382, 52.56388, 52.56395, 52.56400, 52.56404, 52.56408, 52.56409, 52.56423, 52.56427, 52.56440, 52.56449, 52.56456, 52.56463
#> 11                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 13.25183, 13.25185, 13.25188, 13.25192, 13.25196, 13.25198, 13.25201, 13.25202, 13.25204, 13.25208, 13.25214, 13.25215, 13.25216, 13.25225, 13.25235, 13.25241, 13.25242, 13.25244, 13.25247, 13.25251, 13.25259, 13.25267, 13.25275, 13.25279, 13.25281, 13.25289, 13.25293, 13.25296, 13.25302, 13.25304, 13.25306, 13.25309, 13.25312, 13.25316, 13.25325, 13.25329, 13.25340, 13.25344, 13.25347, 13.25352, 13.25356, 13.25357, 13.25358, 13.25360, 13.25359, 13.25358, 13.25356, 13.25353, 13.25351, 13.25349, 13.25347, 13.25342, 13.25330, 13.25327, 13.25316, 13.25303, 13.25295, 13.25291, 13.25280, 13.25262, 13.25258, 13.25234, 13.25213, 13.25209, 13.25201, 13.25198, 13.25187, 13.25183, 13.25183, 13.25183, 13.25183, 52.57736, 52.57734, 52.57732, 52.57728, 52.57723, 52.57721, 52.57719, 52.57717, 52.57715, 52.57711, 52.57707, 52.57706, 52.57705, 52.57701, 52.57698, 52.57697, 52.57696, 52.57694, 52.57692, 52.57692, 52.57690, 52.57689, 52.57688, 52.57687, 52.57685, 52.57682, 52.57682, 52.57681, 52.57677, 52.57675, 52.57673, 52.57671, 52.57670, 52.57669, 52.57669, 52.57670, 52.57673, 52.57675, 52.57676, 52.57683, 52.57688, 52.57693, 52.57695, 52.57697, 52.57700, 52.57703, 52.57708, 52.57713, 52.57720, 52.57725, 52.57727, 52.57731, 52.57737, 52.57738, 52.57742, 52.57743, 52.57744, 52.57745, 52.57747, 52.57752, 52.57753, 52.57753, 52.57752, 52.57751, 52.57751, 52.57750, 52.57747, 52.57744, 52.57741, 52.57739, 52.57736
#> 18                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         13.36983, 13.37001, 13.37026, 13.37032, 13.37041, 13.37049, 13.37066, 13.37067, 13.37064, 13.37060, 13.37045, 13.37040, 13.37044, 13.37055, 13.37094, 13.37098, 13.37093, 13.37096, 13.37100, 13.37105, 13.37107, 13.37100, 13.37087, 13.37075, 13.37062, 13.37040, 13.37058, 13.37049, 13.37033, 13.37022, 13.37003, 13.37030, 13.37032, 13.37024, 13.36997, 13.36978, 13.36983, 52.61140, 52.61132, 52.61139, 52.61148, 52.61156, 52.61153, 52.61118, 52.61106, 52.61099, 52.61095, 52.61097, 52.61088, 52.61082, 52.61080, 52.61084, 52.61090, 52.61106, 52.61113, 52.61129, 52.61143, 52.61163, 52.61181, 52.61195, 52.61206, 52.61219, 52.61210, 52.61196, 52.61191, 52.61200, 52.61197, 52.61177, 52.61167, 52.61161, 52.61157, 52.61162, 52.61150, 52.61140
#> 19                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             13.23093, 13.23106, 13.23121, 13.23131, 13.23155, 13.23148, 13.22921, 13.22897, 13.22869, 13.23093, 52.61050, 52.61044, 52.61095, 52.61131, 52.61252, 52.61259, 52.61291, 52.61194, 52.61084, 52.61050, 13.22970, 13.22975, 13.22980, 13.22985, 13.22987, 13.22988, 13.22990, 13.22996, 13.23000, 13.23005, 13.23011, 13.23017, 13.23043, 13.23045, 13.23049, 13.23052, 13.23056, 13.23060, 13.23070, 13.23072, 13.23073, 13.23071, 13.23071, 13.23071, 13.23071, 13.23061, 13.23050, 13.23040, 13.23032, 13.23029, 13.23025, 13.23004, 13.22994, 13.22988, 13.22982, 13.22973, 13.22970, 13.22970, 52.61201, 52.61205, 52.61213, 52.61229, 52.61240, 52.61241, 52.61241, 52.61241, 52.61239, 52.61239, 52.61239, 52.61238, 52.61236, 52.61236, 52.61235, 52.61234, 52.61233, 52.61231, 52.61227, 52.61224, 52.61222, 52.61217, 52.61212, 52.61208, 52.61206, 52.61193, 52.61178, 52.61173, 52.61168, 52.61167, 52.61166, 52.61166, 52.61170, 52.61173, 52.61181, 52.61193, 52.61197, 52.61201
#> 24                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     13.34818, 13.34820, 13.34824, 13.34830, 13.34836, 13.34840, 13.34842, 13.34841, 13.34838, 13.34832, 13.34826, 13.34821, 13.34818, 13.34818, 52.60167, 52.60164, 52.60161, 52.60161, 52.60162, 52.60164, 52.60168, 52.60170, 52.60173, 52.60175, 52.60175, 52.60172, 52.60169, 52.60167
```

# 

<br>

## A Basic Template Map of Imperviousness

The basic template map shows levels of imperviousness and green areas in
Berlin. The imperviousness raster data was derived from [Geoportal
Berlin
(FIS-Broker)](https://www.stadtentwicklung.berlin.de/geoinformation/fis-broker/)
with a resolution of 10m. The vector data on green spaces was collected
from data provided by the [OpenStreetMap
Contributors](https://www.openstreetmap.org/). The green spaces consist
of a mixture of land use and natural categories (namely “forest”,
“grass”, “meadow”, “nature_reserve”, “scrub”, “heath”, “beach”,
“cliff”).

The map is projected in **EPSG 4326 (WGS84)**.

``` r
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

## Berlin Data Sets

The package contains several data sets for Berlin. All of them start
with `sf_`, e.g. `d6berlin::sf_roads`. Here is a full overview of the
data sets that are available:

<img src="man/figures/README-datasets-1.png" width="33%" /><img src="man/figures/README-datasets-2.png" width="33%" /><img src="man/figures/README-datasets-3.png" width="33%" /><img src="man/figures/README-datasets-4.png" width="33%" /><img src="man/figures/README-datasets-5.png" width="33%" /><img src="man/figures/README-datasets-6.png" width="33%" /><img src="man/figures/README-datasets-7.png" width="33%" />

<br>

## Adding Locations to the Map

Let’s assume you have recorded some animal locations or you want to plot
another information on top of our base map. For example, let’s visualize
the Berlin metro stations by adding `geom_sf(data = x)` to the `map`
object:

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
  geom_sf(data = sf_metro, aes(color = type), size = 2) +
  scale_color_discrete(type = c("dodgerblue", "forestgreen"), 
                       name = NULL) +
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
#> [1] "2022-02-28 15:09:32 CET"
git2r::repository()
#> Local:    main C:/Users/DataVizard/PopDynIZW Dropbox/GeoData/d6berlin
#> Remote:   main @ origin (https://github.com/EcoDynIZW/d6berlin.git)
#> Head:     [dc1a153] 2022-02-07: update documentation
sessionInfo()
#> R version 4.1.2 (2021-11-01)
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
#> [1] systemfonts_1.0.3   stringr_1.4.0       dplyr_1.0.7        
#> [4] sf_1.0-5            ggplot2_3.3.5       d6berlin_0.0.0.9000
#> 
#> loaded via a namespace (and not attached):
#>  [1] Rcpp_1.0.7          rnaturalearth_0.1.0 lattice_0.20-45    
#>  [4] png_0.1-7           class_7.3-19        assertthat_0.2.1   
#>  [7] digest_0.6.29       utf8_1.2.2          R6_2.5.1           
#> [10] stats4_4.1.2        evaluate_0.14       e1071_1.7-9        
#> [13] highr_0.9           pillar_1.6.4        rlang_0.4.12       
#> [16] raster_3.5-11       rmarkdown_2.11      textshaping_0.3.6  
#> [19] labeling_0.4.2      webshot_0.5.2       rgdal_1.5-28       
#> [22] htmlwidgets_1.5.4   munsell_0.5.0       proxy_0.4-26       
#> [25] compiler_4.1.2      xfun_0.27           base64enc_0.1-3    
#> [28] pkgconfig_2.0.3     htmltools_0.5.2     tidyselect_1.1.1   
#> [31] tibble_3.1.6        codetools_0.2-18    mapview_2.10.0     
#> [34] fansi_0.5.0         withr_2.4.3         crayon_1.4.2       
#> [37] wk_0.6.0            grid_4.1.2          satellite_1.0.4    
#> [40] lwgeom_0.2-8        gtable_0.3.0        lifecycle_1.0.1    
#> [43] DBI_1.1.2           git2r_0.29.0        magrittr_2.0.1     
#> [46] units_0.7-2         scales_1.1.1        KernSmooth_2.23-20 
#> [49] stringi_1.7.5       farver_2.1.0        leaflet_2.0.4.1    
#> [52] sp_1.4-6            ellipsis_0.3.2      ragg_1.1.3         
#> [55] generics_0.1.1      vctrs_0.3.8         s2_1.0.7           
#> [58] tools_4.1.2         ggspatial_1.1.5     leafem_0.1.6       
#> [61] glue_1.4.2          purrr_0.3.4         crosstalk_1.2.0    
#> [64] abind_1.4-5         parallel_4.1.2      fastmap_1.1.0      
#> [67] yaml_2.2.1          colorspace_2.0-2    terra_1.4-22       
#> [70] stars_0.5-5         classInt_0.4-3      knitr_1.36
```

</details>

------------------------------------------------------------------------

<br>

#### Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

<div style="width:300px; height:200px">

<img src=https://camo.githubusercontent.com/00f7814990f36f84c5ea74cba887385d8a2f36be/68747470733a2f2f646f63732e636c6f7564706f7373652e636f6d2f696d616765732f63632d62792d6e632d73612e706e67 alt="" height="42">

</div>
