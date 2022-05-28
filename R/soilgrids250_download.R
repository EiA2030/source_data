#' Title Downlaoding soilGRIDs soil data from 250 m resolution
#'
#' @param param is soil property and it can be one of c("bdod", "cec", "cfvo", "clay", "nitrogen", "ocd", "phh2o", "sand", "silt", "soc")
#' @param depth is soil sample depth and it can be c("0-5", "5-15", "15-30", "30-60")
#' @param xmin is the minimum x for the are of interest 
#' @param ymin is the minimum y for the are of interest 
#' @param xmax is the maximum x for the are of interest 
#' @param ymax is the maximum x for the are of interest 
#' @param path is the path in which the GorTiff files will be dpownloaded 
#' @param lonlat is a data frame with x and y columns for the longtiude and latitude coordinates, This will be used when a user wishes to get the soil property for points. 
#' @return if lonlat is NULL it downlaads the GeoTiff files and if lonlat is provided it returns a data frame with the soil properties for the coordinates provided
#'
#' @examples soilgrids250_download(par = "soc", depth = "5-15", xmin = 7, ymin = 12, xmax = 11, ymax = 15, path = tempdir(), lonlat=NULL)
#' @examples soilgrids250_download(par = "soc", depth = "5-15", xmin = 7, ymin = 12, xmax = 11, ymax = 15, path = tempdir(), lonlat=data.frame(x=c(3.6,8.6,4.7), y=c(7.5,6,7.8)))
soilgrids250_download <- function(par, depth = '0-5', xmin, ymin, xmax, ymax, path, lonlat = NULL){
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
  
   if(is.null(lonlat)){
     rsrc <- sprc(rlist)
  out <- terra::mosaic(rsrc, fun="mean")
  terra::writeRaster(out, paste0(paste(path,paste(par,depth, sep = '_'), sep = '/'), '.tif'), overwrite=TRUE)
  file.remove(del)
  return(out)
   }else{
    getvalues <- NULL
    for(i in 1:length(rlist)){
      E_data <- as.data.frame(raster::extract(rlist[[i]], lonlat))
      E_data <- cbind(E_data, p)
      E_data <- E_data[!is.na(E_data[,2]),]
      names(E_data)[2] <- param 
      E_data <- E_data[, c("x", "y", param)]
      getvalues <- rbind(getvalues, E_data)
    }
    names(getvalues)[3] <- paste(param, depth, sep="_")
    file.remove(del)
    return(getvalues)
  }  
}


