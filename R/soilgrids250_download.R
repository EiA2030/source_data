# Function to download SoilGrids (250m).
# Data is obtained from: https://soilgrids.org
#############################################################################################
# arguments:
    # par: See README.md --> https://github.com/EiA2030/source_data/blob/main/README.md
    # depth: Depth of the layer to request. Default is 0-5 cm interval
    # xmin,ymin,xmax,ymax: Bounding Box parameters to defne the spatial extent of the request 
soilgrids250_data <- function(par, depth = '0-5', xmin, ymin, xmax, ymax){
  require(sf)
  require(terra)
  out <- rast(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, res = c(0.002259887, 0.002389486))
  for (x in seq(xmin, xmax, by = 2)) {
    for (y in seq(ymin, ymax, by = 2)) {
      x2 = x + 2
      y2 = y + 2
      aoi <- vect(st_as_sf(st_as_sfc(st_bbox(c(xmin = x, xmax = x2, ymin = y, ymax = y2), crs = st_crs(4326)))))
      url <- paste0("https://maps.isric.org/mapserv?map=/map/ocd.map&SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID=",
                    par,"_",depth,"cm_mean&FORMAT=image/tiff&SUBSET=",
                    "long(",x,",",x2,")&SUBSET=",
                    "lat(",y,",",y2,")",
                    "&SUBSETTINGCRS=http://www.opengis.net/def/crs/EPSG/0/4326&OUTPUTCRS=http://www.opengis.net/def/crs/EPSG/0/4326")
      download.file(url, paste0(paste('tmp',par,depth,x,y, sep = '_'), '.tif'), overwrite=TRUE)
      tif <- crop(rast(paste0(paste('tmp',par,depth,x,y, sep = '_'), '.tif')), aoi, filename = paste0(paste(par,depth,x,y, sep = '_'), '.tif'), overwrite = T)
      out <- terra::mosaic(out,tif,fun="mean")
    }
  }
  writeRaster(out, paste(paste(par,depth,sep = "_"), ".tif", sep = ""), overwrite=TRUE)
  return(out)
}
