#' Berlin shape (WGS 84)
#'
#' An sf object containing the multipolygon of Berlin.
#'
#' @source
#' Data downloaded from
#' \url{https://daten.odis-berlin.de/en/dataset/bezirksgrenzen}.
"sf_berlin"

#' Berlin districts (WGS 84)
#'
#' An sf object containing the12 districts of Berlin as multipolygons.
#'
#' \itemize{
#'   \item district_name. Name of the Berlin district this feature is located in.
#'   \item district_id. 3 digit code (as character) of the district this feature is located in.
#'   \item district_key. Combined key for the district this feature is located in.
#'   \item geometry. Simple feature geometry.
#' }
#'
#' @source
#' Data downloaded from
#' \url{https://daten.odis-berlin.de/en/dataset/bezirksgrenzen}.
"sf_districts"

#' Berlin green spaces (WGS 84)
#'
#' An sf object containing the shape of all green spaces (defined as natural
#' areas and landuse categories "forest", "grass", "meadow", "nature_reserve",
#' "scrub", "heath", "beach", and "cliff") in Berlin.
#'
#' \itemize{
#'   \item osm_id. OpenStreetMap id for this feature as factor.
#'   \item code. 4 digit code (between 1000 and 9999) defining the class of this feature.
#'   \item fclass. Class name of this feature (here class of green space, i.e.
#'                 "forest", "grass", "meadow", "nature_reserve", "scrub",
#'                 "heath", "beach", or "cliff").
#'   \item name. Name of this feature (here name of the green area).
#'   \item district_name. Name of the Berlin district this feature is located in.
#'   \item district_id. 3 digit code (as character) of the district this feature is located in.
#'   \item district_key. Combined key for the district this feature is located in.
#'   \item geometry. Simple feature geometry.
#' }
#'
#' @source
#' Data downloaded from
#' \url{https://download.geofabrik.de/europe/germany/berlin.html}.
#' Please give credit by stating (c) OpenStreetMap contributors when using the data.
"sf_green"

#' Berlin water bodies (WGS 84)
#'
#' An sf object containing the shape of all water bodies and ways found in Berlin.
#'
#' \itemize{
#'   \item osm_id. OpenStreetMap id for this feature as factor.
#'   \item code. 4 digit code (between 1000 and 9999) defining the class of this feature.
#'   \item fclass. Class name of this feature (here class of water bodies, i.e. "water",
#'                 "wetland", "riverbank" or "reservoir").
#'   \item name. Name of this feature (here name of the water body).
#'   \item district_name. Name of the Berlin district this feature is located in.
#'   \item district_id. 3 digit code (as character) of the district this feature is located in.
#'   \item district_key. Combined key for the district this feature is located in.
#'   \item geometry. Simple feature geometry.
#' }
#'
#' @source
#' Data downloaded from
#' \url{https://download.geofabrik.de/europe/germany/berlin.html}.
#' Please give credit by stating (c) OpenStreetMap contributors when using the data.
"sf_water"

#' Berlin roads (WGS 84)
#'
#' An sf object containing all roads in Berlin. Contains only those classes that
#' are used by cars (i.e. excludes roads of class footway, steps, bridleway,
#' path, pedestrian, and cycleway as well as roads that are unclassified or of
#' unknown class; includes tracks of all grades; run `unique(sf_roads$fclass)`
#' to seeinspect all classes contained).
#'
#' \itemize{
#'   \item osm_id. OpenStreetMap id for this feature as factor.
#'   \item code. 4 digit code (between 1000 and 9999) defining the class of this feature.
#'   \item fclass. Class name of this feature (here class of road, e.g. "primary",
#'                 "living_street", or "residential")
#'   \item name. Name of this feature (here name of the road).
#'   \item oneway. Logical, TRUE in case this feature has a access restriction for cars.
#'   \item maxspeed. Maximum speed on this feature.
#'   \item bridge. Logical. TRUE in case this feature is a bridge.
#'   \item tunnel Logical. TRUE in case this feature is a tunnel.
#'   \item district_name. Name of the Berlin district this feature is located in.
#'   \item district_id. 3 digit code (as character) of the district this feature is located in.
#'   \item district_key. Combined key for the district this feature is located in.
#'   \item geometry. Simple feature geometry.
#' }
#'
#' @source
#' Data downloaded from
#' \url{https://download.geofabrik.de/europe/germany/berlin.html}.
#' Please give credit by stating (c) OpenStreetMap contributors when using the data.
"sf_roads"

#' Berlin railways (WGS 84)
#'
#' An sf object containing all railways in Berlin.
#'
#' \itemize{
#'   \item osm_id. OpenStreetMap id for this feature as factor.
#'   \item code. 4 digit code (between 1000 and 9999) defining the class of this feature.
#'   \item fclass. Class name of this feature (here class of railway, i.e. "rail",
#'                 "light_rail", "subway", "tram", "miniature_railway" or "narrow_gauge".
#'   \item name. Name of this feature (here name of the water body).
#'   \item layer. Describes the vertical relationship between crossing or overlapping features.
#'   \item bridge. Logical. TRUE in case this feature is a bridge.
#'   \item tunnel Logical. TRUE in case this feature is a tunnel.
#'   \item district_name. Name of the Berlin district this feature is located in.
#'   \item district_id. 3 digit code (as character) of the district this feature is located in.
#'   \item district_key. Combined key for the district this feature is located in.
#'   \item geometry. Simple feature geometry.
#' }
#'
#' @source
#' Data downloaded from
#' \url{https://download.geofabrik.de/europe/germany/berlin.html}.
#' Please give credit by stating (c) OpenStreetMap contributors when using the data.
"sf_railways"

#' Berlin metro station (WGS 84)
#'
#' An sf object containing the locations of metro stations in Berlin.
#'
#' \itemize{
#'   \item osm_id. OpenStreetMap id for this feature.
#'   \item code. 4 digit code (between 1000 and 9999) defining the class of this feature.
#'   \item fclass. Class name of this feature (always of class "railway_station").
#'   \item name. Name of this feature (here name of the water body).
#'   \item type. Type of train station, either S-Bahn or U-Bahn.
#'   \item district_name. Name of the Berlin district this feature is located in.
#'   \item district_id. 3 digit code (as character) of the district this feature is located in.
#'   \item district_key. Combined key for the district this feature is located in.
#'   \item geometry. Simple feature geometry.
#' }
#'
#' @source
#' Data downloaded from
#' \url{https://download.geofabrik.de/europe/germany/berlin.html}.
#' Please give credit by stating (c) OpenStreetMap contributors when using the data.
"sf_metro"
