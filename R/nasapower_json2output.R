f_tblR.JSON <- function(file_name,p){
  require(rjson)
  require(tidyverse)
  require(sf)
  json <- enframe(unlist(fromJSON(file = file_name)))
  json <- json %>% 
    separate(name, into = c(paste0("name", 1:5)), fill = "right") %>%
    filter(name1 == "features" &
             name2 == "geometry" &
             name3 %in% c("coordinates1", "coordinates2") |
             (name1 == "features" &
                name2 == "properties" &
                name3 == "parameter")) %>%
    dplyr::select(name5, value)

  json <- json %>%
    mutate(lat = if_else(is.na(name5), as.numeric(value), as.numeric(NA))) %>%
    mutate(lon = if_else(is.na(name5), as.numeric(lag(value, n = 1L)), as.numeric(NA))) %>%
    mutate(date = if_else(is.na(name5), as.Date(NA), as.Date(name5, "%Y%m%d"))) %>% 
    mutate(parameter = if_else(is.na(name5), as.numeric(NA), as.numeric(value))) %>%
    dplyr::select(lat, lon, date, parameter) %>%
    filter(!is.na(lat) & !is.na(lon) |
             (!is.na(date) & !is.na(p)))
  colnames(json) <- c("lat", "lon", "date",p)

  while(length(ind <- which(is.na(json$lat))) > 0){
    json$lat[ind] <- json$lat[ind -1]
  }
  while(length(ind <- which(is.na(json$lon))) > 0){
    json$lon[ind] <- json$lon[ind -1]
  }

  json <- json %>%
    filter(!is.na(date) & !is.na(p))
  json <- json %>%
    arrange(date, lat, lon)
  return(json)
}
        
f_point.data <- function(file_name, p){
  require(sf)
  data <- f_tblR.JSON(file_name, p)
  data <- st_as_sf(data, coords = c("lon", "lat"), crs = 4326)
  colnames(data) <- c('YYYYMMDD', p, "geometry")
  return(data)
}


f_data.Cube <- function(file_name, p, tr){
  tbl <- f_tblR.JSON(file_name, p)
  pnt <- f_point.data(file_name, p)
  require(raster)
# Create new objects for each parameter selected  
  lapply(names(pnt)[!grepl(paste(c("YYYYMMDD","geometry"), collapse="|"), names(pnt))], function(x) assign(x, pnt[c("YYYYMMDD",x)], envir = .GlobalEnv))
# Rasterize the sf of each parameter at a selected resolution (tr)
  for(i in names(pnt)[!grepl(paste(c("YYYYMMDD", "geometry"), collapse="|"), names(pnt))]){
    r <- raster(ext = extent(st_bbox(pnt)) + 0.5, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0", resolution = 0.5)
    st <- stack()
    j <- get(i, envir = .GlobalEnv)
    j <-tidyr::spread(j, "YYYYMMDD", i)
    ## Re-format column labels
    colnames(j) <- gsub('-', '_', colnames(j), fixed=TRUE)
    n <- 1
    for(k in names(j)[!grepl("['geometry]", names(j))]){
      vals <- dplyr::pull(j, k) # Read vector with`` the values of the date (k)
      r <- raster(ext = extent(st_bbox(j)) + 0.5, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0",
                  resolution = tr) # Create Raster object with the desired Target Resolution
      # # Add this part to work inside of CG Labs
      # # It works with library(raster) object SpatialPointsDataFrame
      lonlat <- cbind(tbl$lon, tbl$lat)
      df <- data.frame(ID=1:nrow(lonlat), i = vals)
      colnames(df) <- c("ID", i)
      v <- SpatialPointsDataFrame(lonlat, data=df, proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
      ras <- rasterize(x = v,
                       y = raster(ext = extent(st_bbox(j)) + 0.5, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0", resolution = 0.5),
                       field = i)
      # # # This part is removed (not working inside CG Labs)
      # ras <- rasterize(x = j,
      #                  y = raster(ext = extent(st_bbox(j)) + 0.5, resolution = 0.5),
      #                  field = vals)
      crs(ras) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
      ras <- resample(ras, r, method = "bilinear")
      st <- stack(st,ras)
      names(st[[n]]) <- as.character(paste0('date_', gsub("_", "-", k))) # https://stackoverflow.com/questions/36844460/why-does-r-add-an-x-when-renaming-raster-stack-layers
      # Create RasterStack of each object
      assign(paste0(i), st , envir = .GlobalEnv)
      remove(vals,ras)
      n <- n + 1
    }
  }
}