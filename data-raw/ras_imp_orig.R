## code to prepare `ras_imp_orig` dataset goes here

## FILE PATH -----------------------------------------------------------------
path <-
  here::here("data-raw", "imperviousness_berlin_copernicus_raster_10m_2018_3035.tif")

## PREPARE DATA --------------------------------------------------------------
## Berlin imperviousness levels (WGS 84)
## Source: Copernicus
#ras_imp_orig <- raster::raster(path)
ras_imp_orig <- lazyraster::lazyraster(path)

usethis::use_data(ras_imp_orig, overwrite = TRUE)
