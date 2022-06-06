#' Title Downlaoding iSDA soil data at 30 m resolution
#'
#' @param par is soil property and it can be one of c("log.n_tot_ncs_m_30m", "db_od_m_30m", "log.p_mehlich3_m_30m	", "bdr_m_30m", "log.ca_mehlich3_m_30m", "log.oc_m_30m", "log.c_tot_m_30m", "log.ecec.f_m_30m", "sol_clay_tot_psa_m_30m")
#' @param depth is soil sample depth and it can be c("0..20cm", "20..40cm", "40..80cm", "80..100cm")
#' @param xmin is the minimum x for the are of interest 
#' @param ymin is the minimum y for the are of interest 
#' @param xmax is the maximum x for the are of interest 
#' @param ymax is the maximum x for the are of interest
#' @param lonlat is a data frame with x and y columns for the longtiude and latitude coordinates, This will be used when a user wishes to get the soil property for points. 
#' @return if lonlat is NULL it downlaads the GeoTiff files and if lonlat is provided it returns a data frame with the soil properties for the coordinates provided
#'
#' @examples isda_download(par = "log.n_tot_ncs_m_30m", depth = "0..20cm", xmin = 7, ymin = 12, xmax = 11, ymax = 15, lonlat=NULL)
#' @examples isda_download(par = "log.c_tot_m_30m", depth = "20..40cm", xmin = 7, ymin = 12, xmax = 11, ymax = 15, lonlat=data.frame(x=c(3.6,8.6,4.7), y=c(7.5,6,7.8)))

isda_download <- function(par, depth, xmin, ymin, xmax, ymax, lonlat = NULL){
  if (is.null(lonlat)){
    aoi <- terra::vect(sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(c(xmin = xmin, xmax = xmax, ymax = ymax, ymin = ymin), crs = sf::st_crs(4326)))))
    tif.cog <- paste0("/vsicurl/https://s3.eu-central-1.wasabisys.com/africa-soil/layers30m/",
                      paste("sol",par,depth,"2001..2017_africa_epsg4326_v0.1.tif",sep = "_"))
    out <- terra::crop(terra::rast(tif.cog), aoi)
    return(out)
  } else {
    getvalues <- NULL
    xmin <- min(lonlat$lon)-1
    xmax <- max(lonlat$lon)+1
    ymin <- min(lonlat$lat)-1
    ymax <- max(lonlat$lat)+1
    aoi <- terra::vect(sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(c(xmin = xmin, xmax = xmax, ymax = ymax, ymin = ymin), crs = sf::st_crs(4326)))))
    tif.cog <- paste0("/vsicurl/https://s3.eu-central-1.wasabisys.com/africa-soil/layers30m/",
                      paste("sol",par,depth,"2001..2017_africa_epsg4326_v0.1.tif",sep = "_"))
    out <- terra::crop(terra::rast(tif.cog), aoi)
    for (pnt in seq_len(nrow(lonlat))) {
      pnt <- lonlat[pnt,]
      d <- terra::extract(out, data.frame(x = pnt[1], y = pnt[2]))[,2]
      E_data <- data.frame(pnt[2], pnt[1], d)
      getvalues <- rbind(getvalues, E_data)
    }
    return(getvalues)
  }
}