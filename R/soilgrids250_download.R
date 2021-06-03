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
  ref <- rast(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, res = c(0.002259887, 0.002389486), crs = '+proj=longlat +datum=WGS84 +no_defs')
  tif <- gdal_translate(paste0(sg_url, par, '/', par, '_', depth, 'cm_mean.vrt'),
                        paste0(paste('tmp',par,depth, sep = '_'), '.tif'),
                        tr = c(250,250),
                        projwin=bb,
                        projwin_srs=crs,
                        verbose=FALSE)
  tif <- project(rast(paste0(paste('tmp',par,depth, sep = '_'), '.tif')), ref)
  return(tif)
}
