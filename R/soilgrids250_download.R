soilgrids250_download <- function(par, depth = '0-5', xmin, ymin, xmax, ymax, path){
  require(sf)
  require(terra)
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
      tryCatch(
        expr = {
          download.file(url, paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = '/'), '.tif'), overwrite=TRUE, quiet = T)
          message(paste("Successfully downloaded to ", paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = '/'), '.tif'), sep = ""))
        },
        error = function(e){
          message(paste("Can't download in ", paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = '/'), '.tif'), sep = ""))
        }
      )
      n <- n + 1
    }
  }
  del <- list.files(path, pattern =  paste('tmp',par,depth, sep = '_'), full.names = T)
  rlist <- lapply(del, terra::rast)
  rsrc <- sprc(rlist)
  out <- terra::mosaic(rsrc, fun="mean")
  terra::writeRaster(out, paste0(paste(path,paste(par,depth, sep = '_'), sep = '/'), '.tif'), overwrite=TRUE)
  file.remove(del)
  return(out)
}
# Example
# soilgrids250_download(par = "soc", depth = "5-15", xmin = 7, ymin = 12, xmax = 11, ymax = 15, path = tempdir())
