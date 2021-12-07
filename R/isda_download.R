# Function to download iSDA Soil data (Africa only).
# Data is obtained from: https://gitlab.com/openlandmap/africa-soil-and-agronomy-data-cube
#############################################################################################
# arguments:
    # par: See README.md --> https://github.com/EiA2030/source_data/blob/main/README.md
    # depth: Depth of the layer to request. Can be 0-20cm OR 20-50cm
    # xmin,ymin,xmax,ymax: Bounding Box parameters to defne the spatial extent of the request 
isda_download <- function(par, depth, xmin, ymin, xmax, ymax){
  aoi <- terra::vect(sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(c(xmin = xmin, xmax = xmax, ymax = ymax, ymin = ymin), crs = sf::st_crs(4326)))))
  tif.cog <- paste0("/vsicurl/https://s3.eu-central-1.wasabisys.com/africa-soil/layers30m/",
                    paste("sol",par,depth,"2001..2017_africa_epsg4326_v0.1.tif",sep = "_"))
  out <- crop(terra::rast(tif.cog), aoi)
  return(out)
}