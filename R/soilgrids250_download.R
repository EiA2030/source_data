soilgrids250_data <- function(par, depth = '0-5', xmin, ymin, xmax, ymax, path){
  require(sf)
  require(terra)
  out <- rast(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, res = c(0.002259887, 0.002389486))
  n <- 1
  for (x in seq(xmin, xmax, by = 2)) {
    for (y in seq(ymin, ymax, by = 2)) {
      x2 = x + 2
      y2 = y + 2
      url <- paste0("https://maps.isric.org/mapserv?map=/map/",par,".map&SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID=",
                    par,"_",depth,"cm_mean&FORMAT=image/tiff&SUBSET=",
                    "long(",x,",",x2,")&SUBSET=",
                    "lat(",y,",",y2,")",
                    "&SUBSETTINGCRS=http://www.opengis.net/def/crs/EPSG/0/4326&OUTPUTCRS=http://www.opengis.net/def/crs/EPSG/0/4326")
      download.file(url, paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = ''), '.tif'), overwrite=TRUE)
      out <- terra::mosaic(out,rast(paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = ''), '.tif')),fun="mean")
      n <- n + 1
    }
  }
  del <- list.files(par, full.names = T)
  file.remove(del)
  terra::writeRaster(out, paste0(paste(path,paste(par,depth, sep = '_'), sep = ''), '.tif'), overwrite=TRUE)
  return(out)
}