## code to prepare `sf_world` dataset goes here

## PREPARE DATA --------------------------------------------------------------

sf_world <- rnaturalearth::ne_countries(scale = 50, returnclass = "sf")

usethis::use_data(sf_world, overwrite = TRUE)
