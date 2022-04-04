SRTM_download <- function(xmin, ymin, xmax, ymax, path){
  require(sf)
  require(terra)
  n <- 1
  for (x in seq(xmin, xmax, by = 2)) {
    for (y in seq(ymin, ymax, by = 2)) {
      x2 = x + 2
      y2 = y + 2
      url <- paste('https://portal.opentopography.org/API/globaldem?demtype=SRTMGL1',
                   '&south=', y,
                   '&north=', y2,
                   '&west=', x,
                   '&east=', x2,
                   '&outputFormat=GTiff', sep = '')
      tryCatch(
        expr = {
          download.file(url, paste0(paste(path,paste('tmp','SRTMGL1',n, sep = '_'), sep = '/'), '.tif'), overwrite=TRUE, quiet = T)
          message(paste("Successfully downloaded to ", paste0(paste(path,paste('tmp','SRTMGL1',n, sep = '_'), sep = '/'), '.tif'), sep = ""))
        },
        error = function(e){
          message(paste("Can't download in ", paste0(paste(path,paste('tmp','SRTMGL1',n, sep = '_'), sep = '/'), '.tif'), sep = ""))
        }
      )
      n <- n + 1
    }
  }
  del <- list.files(path, pattern = paste('tmp','SRTMGL1', sep = '_'), full.names = T)
  rlist <- lapply(del, terra::rast)
  rsrc <- src(rlist)
  out <- terra::mosaic(rsrc, fun="mean")
  file.remove(del)
  terra::writeRaster(out, paste0(paste(path,paste('SRTM', sep = '_'), sep = '/'), '.tif'), overwrite=TRUE)
  return(out)
}
# Example
# SRTM_download(xmin = 7, ymin = 12, xmax = 11, ymax = 15, path = path/to/file)
