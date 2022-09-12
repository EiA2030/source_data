#' Title Downlaoding NASA DEM data at 30 m resolution
#'
#' @param par is a terrain property and it can be one of c("elevation", "hillshade", "slope	")
#' @param xmin is the minimum x for the are of interest 
#' @param ymin is the minimum y for the are of interest 
#' @param xmax is the maximum x for the are of interest 
#' @param ymax is the maximum x for the are of interest
#' @param lonlat is a data frame with x and y columns for the longtiude and latitude coordinates, This will be used when a user wishes to get the soil property for points. 
#' @return if lonlat is NULL it downlaads the GeoTiff files and if lonlat is provided it returns a data frame with the soil properties for the coordinates provided
#'
#' @examples nasadem_download(par = "elevation", xmin = 7, ymin = 12, xmax = 11, ymax = 15, lonlat=NULL)
#' @examples nasadem_download(par = "slope", xmin = 7, ymin = 12, xmax = 11, ymax = 15, lonlat=data.frame(x=c(3.6,8.6,4.7), y=c(7.5,6,7.8)))

ndf <- function(par, xmin, ymin, xmax, ymax){
  aoi <- terra::vect(sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(c(xmin = xmin, xmax = xmax, ymax = ymax, ymin = ymin), crs = sf::st_crs(4326)))))
  tif.cog <- paste0("/vsicurl/https://s3.eu-central-1.wasabisys.com/africa-soil/layers30m/",
                    paste0("dtm_",par,"_aw3d30.nasadem_m_30m_s0..0cm_2017_africa_proj.laea_v0.1.tif"))
  terra::crs(aoi) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
  out <- terra::rast(tif.cog)
  aoi.laea <- terra::project(aoi, out)
  out.laea <- terra::crop(out, aoi.laea)
  out <- terra::project(out.laea, aoi)
}

nasadem_download <- function(par, xmin, ymin, xmax, ymax, lonlat = NULL){
  if (is.null(lonlat)){
    out <- ndf(par, xmin, ymin, xmax, ymax)
    return(out)
  } else {
    getvalues <- NULL
    xmin <- min(lonlat[[1]])-0.00027
    xmax <- max(lonlat[[1]])+0.00027
    ymin <- min(lonlat[[2]])-0.00027
    ymax <- max(lonlat[[2]])+0.00027
    out <- ndf(par, xmin, ymin, xmax, ymax)
    for (pnt in seq_len(nrow(lonlat))) {
      pnt <- lonlat[pnt,]
      d <- terra::extract(out, data.frame(x = pnt[1], y = pnt[2]))[,2]
      E_data <- data.frame(pnt[2], pnt[1], d)
      getvalues <- rbind(getvalues, E_data)
    }
    return(getvalues)
  }
}
