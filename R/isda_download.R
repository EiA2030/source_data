# # Function to download iSDA Soil data (Africa only).
# # Data is obtained from: https://gitlab.com/openlandmap/africa-soil-and-agronomy-data-cube
# #############################################################################################
# # arguments:
#     # par: See README.md --> https://github.com/EiA2030/source_data/blob/main/README.md
#     # depth: Depth of the layer to request. Can be 0-20cm OR 20-50cm
#     # xmin,ymin,xmax,ymax: Bounding Box parameters to defne the spatial extent of the request 
# isda_download <- function(par, depth, xmin, ymin, xmax, ymax){
#   aoi <- terra::vect(sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(c(xmin = xmin, xmax = xmax, ymax = ymax, ymin = ymin), crs = sf::st_crs(4326)))))
#   tif.cog <- paste0("/vsicurl/https://s3.eu-central-1.wasabisys.com/africa-soil/layers30m/",
#                     paste("sol",par,depth,"2001..2017_africa_epsg4326_v0.1.tif",sep = "_"))
#   out <- terra::crop(terra::rast(tif.cog), aoi)
#   return(out)
# }
# # Example
# # isda_download(par = "log.n_tot_ncs_m_30m", depth = "0..20cm", xmin = 7, xmax = 10, ymin = 10, ymax = 13)


# Function to download iSDA Soil data (Africa only).
# Data is obtained from: https://gitlab.com/openlandmap/africa-soil-and-agronomy-data-cube
#############################################################################################
# arguments:
# par: See README.md --> https://github.com/EiA2030/source_data/blob/main/README.md
# depth: Depth of the layer to request. Can be 0-20cm OR 20-50cm
# xmin,ymin,xmax,ymax: Bounding Box parameters to defne the spatial extent of the request
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

out <- isda_download(par = "log.n_tot_ncs_m_30m", depth = "0..20cm", xmin = 7, xmax = 10, ymin = 10, ymax = 13)

# Example 1:
out <- isda_download(par = "log.n_tot_ncs_m_30m", depth = "0..20cm", xmin = 7, xmax = 10, ymin = 10, ymax = 13)

# Example 2:
out <- isda_download(par = "log.n_tot_ncs_m_30m", depth = "0..20cm", xmin = 22.43, xmax = 22.59, ymin = -21.38, ymax = -18.78, lonlat = data.frame(x=c(22.43, 22.59, 23.50), y=c(-18.78, -21.38, -20.41)))
