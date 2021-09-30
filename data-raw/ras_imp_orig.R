## code to prepare `ras_imp_orig` dataset goes here

## FILE PATH -----------------------------------------------------------------
path <-
  here::here(
    "inst",
    "imperviousness_berlin_copernicus_raster_10m_2018_3035.tif")

## PREPARE DATA --------------------------------------------------------------
## Berlin imperviousness levels (WGS 84)
## Source: Copernicus
ras_imp_orig <-
  raster::raster("inst/imperviousness_berlin_copernicus_raster_10m_2018_3035.tif")
ras_imp_orig <- ras_imp_orig * 1

usethis::use_data(ras_imp_orig, overwrite = TRUE)
