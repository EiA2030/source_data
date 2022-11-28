chirps <- function(startDate, endDate, df = NULL){
  dates <- seq.Date(as.Date(startDate, format = "%Y-%m-%d"), as.Date(endDate, format = "%Y-%m-%d"), by = "day")
  year <- unique(format(dates, "%Y"))
  chirps <- terra::rast()
  for (file in list.files('/home/jovyan/AgWise/rawData/2_weather/rain_chirps/raw', pattern = paste0(year, collapse = '|'), full.names = TRUE)) {
    terra::add(chirps) <- terra::rast(file)
  }
  names(chirps) <- as.character(format(as.Date(terra::time(chirps)), "%Y%m%d"))
  chirps <- chirps[[as.character(format(dates, format = "%Y%m%d"))]]
  w <- data.frame()
  for (pnt in seq(1:nrow(df))){
    lon <- df[pnt, 1]
    lat <- df[pnt, 2]
    z <- terra::extract(chirps,data.frame(lon,lat))
    out <- data.frame("dates" = dates)
    out$X <- lon
    out$Y <- lat
    out$RAIN <- as.vector(t(z[2:length(z)]))
    out <- data.frame("X" = out$X, "Y" = out$Y, "dates" = out$dates,
                    "year" = format(as.Date(out$dates), format = "%Y"),
                    "month" = format(as.Date(out$dates), format = "%m"),
                    "day" = format(as.Date(out$dates), format = "%d"),
                    "RAIN" = out$RAIN)
    w <- rbind(w, out)
  }
  return(w)
}
