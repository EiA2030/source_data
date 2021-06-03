# Function to download SoilGrids (250m).
# Data is obtained from: https://soilgrids.org
#############################################################################################
# arguments:
    # par: See README.md --> https://github.com/EiA2030/source_data/blob/main/README.md
    # depth: Depth of the layer to request. Default is 0-5 cm interval
    # xmin,ymin,xmax,ymax: Bounding Box parameters to defne the spatial extent of the request 
soilgrids250_data <- function(par, depth = '0-5', xmin, ymin, xmax, ymax){
  require(rgdal)
  require(gdalUtils)
  require(terra)
  bb <- c(xmin, ymax, xmax, ymin)
  crs <- 'EPSG:4326'
  sg_url <- "/vsicurl?max_retry=3&retry_delay=1&list_dir=no&url=https://files.isric.org/soilgrids/latest/data/"
  tmp <- tempdir()
  gdal_translate(paste0(sg_url, par, '/', par, '_', depth, 'cm_mean.vrt'),
                 paste0(tmp, '/', paste('tmp1',par,depth, sep = '_'), '.vrt'),
                 of='VRT', tr = c(250,250),
                 projwin=bb,
                 projwin_srs=crs,
                 verbose=FALSE)
  gdalwarp(paste0(tmp, '/', paste('tmp1',par,depth, sep = '_'), '.vrt'),
           paste0(tmp, '/', paste(par,depth, sep = '_'), '.tif'),
           t_srs=crs,
           of='GTiff',
           overwrite=TRUE)
  tif <- rast(paste0(tmp, '/', paste(par,depth, sep = '_'), '.tif'))
  unlink(tmp)
  return(tif)
}
