% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{sf_roads}
\alias{sf_roads}
\title{Berlin roads (WGS 84)}
\format{
An object of class \code{sf} (inherits from \code{tbl_df}, \code{tbl}, \code{data.frame}) with 106136 rows and 12 columns.
}
\source{
Data downloaded from
\url{https://download.geofabrik.de/europe/germany/berlin.html}.
Please give credit by stating (c) OpenStreetMap contributors when using the data.
}
\usage{
sf_roads
}
\description{
An sf object containing all roads in Berlin. Contains only those classes that
are used by cars (i.e. excludes roads of class footway, steps, bridleway,
path, pedestrian, and cycleway as well as roads that are unclassified or of
unknown class; includes tracks of all grades; run \code{unique(sf_roads$fclass)}
to seeinspect all classes contained).
}
\details{
\itemize{
\item osm_id. OpenStreetMap id for this feature as factor.
\item code. 4 digit code (between 1000 and 9999) defining the class of this feature.
\item fclass. Class name of this feature (here class of road, e.g. "primary",
"living_street", or "residential")
\item name. Name of this feature (here name of the road).
\item oneway. Logical, TRUE in case this feature has a access restriction for cars.
\item maxspeed. Maximum speed on this feature.
\item bridge. Logical. TRUE in case this feature is a bridge.
\item tunnel Logical. TRUE in case this feature is a tunnel.
\item district_name. Name of the Berlin district this feature is located in.
\item district_id. 3 digit code (as character) of the district this feature is located in.
\item district_key. Combined key for the district this feature is located in.
\item geometry. Simple feature geometry.
}
}
\keyword{datasets}
