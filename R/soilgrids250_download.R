soilgrids250_data <- function(par, depth = '0-5', xmin, ymin, xmax, ymax, path){
  require(sf)
  require(terra)
  out <- rast(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, res = c(0.002259887, 0.002389486))
  n <- 1
  for (x in seq(xmin, xmax, by = 2)) {
    for (y in seq(ymin, ymax, by = 2)) {
      x2 = x + 2
      y2 = y + 2
      # aoi <- terra::vect(st_as_sf(st_as_sfc(st_bbox(c(xmin = x, xmax = x2, ymin = y, ymax = y2), crs = st_crs(4326)))))
      url <- paste0("https://maps.isric.org/mapserv?map=/map/",par,".map&SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID=",
                    par,"_",depth,"cm_mean&FORMAT=image/tiff&SUBSET=",
                    "long(",x,",",x2,")&SUBSET=",
                    "lat(",y,",",y2,")",
                    "&SUBSETTINGCRS=http://www.opengis.net/def/crs/EPSG/0/4326&OUTPUTCRS=http://www.opengis.net/def/crs/EPSG/0/4326")
      download.file(url, paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = ''), '.tif'), overwrite=TRUE)
      # tif <- terra::crop(terra::rast(paste0(paste(path,paste('tmp',par,depth,x,y, sep = '_'), sep = '/'), '.tif')), terra::ext(aoi), filename = paste0(paste(path,paste(par,depth,x,y, sep = '_'), sep = '/'), '.tif'), overwrite = T)
      # tif <- terra::rast(paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = ''), '.tif'))
      out <- terra::mosaic(out,rast(paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = ''), '.tif')),fun="mean")
      n <- n + 1
    }
  }
  # del <- list.files(getwd(), full.names = T, pattern = "tmp_*")
  # out <- terra::mosaic(out,rast(paste0(paste(path,paste('tmp',par,depth,n, sep = '_'), sep = ''), '.tif')),fun="mean")
  del <- list.files(par, full.names = T)
  file.remove(del)
  terra::writeRaster(out, paste0(paste(path,paste(par,depth, sep = '_'), sep = ''), '.tif'), overwrite=TRUE)
  return(out)
}
# SOC.gna <- soilgrids250_data('nitrogen', depth = '0-5', xmin = -3, ymin = 4, xmax = 1, ymax = 12, path = '/media/data/work/iita/EiA2030/validation/data/soil/nitro/')
# plot(SOC.gna)
