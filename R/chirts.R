chirts <- function(startDate, endDate, raster = FALSE, coordPoints = NULL){
  dates <- seq.Date(as.Date(startDate, format = "%Y-%m-%d"), as.Date(endDate, format = "%Y-%m-%d"), by = "day")
  year <- unique(format(dates, "%Y"))
  chirts <- terra::rast()
  for (file in list.files("/home/jovyan/common_data/chirts/netcdf/tmax/africa", pattern = paste0(year, collapse = '|'), full.names = TRUE)) {
    terra::add(chirts) <- terra::rast(file)
  }
  names(chirts) <- as.character(format(as.Date(terra::time(chirts)), "%Y%m%d"))
  chirts <- chirts[[as.character(format(dates, format = "%Y%m%d"))]]
  if (raster){
    aoi <- suppressWarnings(terra::vect(sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(c(xmin = min(coordPoints[,1]), xmax = max(coordPoints[,1]), ymax = max(coordPoints[,2]), ymin = min(coordPoints[,2])), crs = sf::st_crs(4326))))))
    chirts <- terra::crop(chirts,aoi)
    return(chirts)
  }
  else {
    w <- data.frame()
    for (pnt in seq(1:nrow(coordPoints))){
      lon <- coordPoints[pnt, 1]
      lat <- coordPoints[pnt, 2]
      z <- terra::extract(chirts,data.frame(lon,lat))
      out <- data.frame("dates" = dates)
      out$X <- lon
      out$Y <- lat
      out$TMAX <- as.vector(t(z[2:length(z)]))
      out <- data.frame("X" = out$X, "Y" = out$Y, "dates" = out$dates,
                      "year" = format(as.Date(out$dates), format = "%Y"),
                      "month" = format(as.Date(out$dates), format = "%m"),
                      "day" = format(as.Date(out$dates), format = "%d"),
                      "tmax" = out$TMAX)
      w <- rbind(w, out)
    }
    return(w)
  }
}
