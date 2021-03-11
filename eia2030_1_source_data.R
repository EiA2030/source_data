library(tidyverse)
library(nasapower)
library(sf)
library(raster)
library(stars)

nasaP <- function(xmin, ymin, xmax, ymax, sdate, edate, par1, par2, par3, par4){
  tbl <- get_power(
    community = "AG",
    lonlat = c(xmin, ymin, xmax, ymax),
    pars = if(missing(par4) & missing(par3) & missing(par2)) {
      c(par1)
    } else if (missing(par4) & missing(par3)) {
      c(par1,par2)
    } else if(missing(par4)) {
      c(par1, par2, par3)
    } else {
      c(par1,par2,par3,par4)
    },
    dates = c(sdate, edate),
    temporal_average = "DAILY"
    )
  tbl <- if(missing(par4) & missing(par3) & missing(par2)) {
    dplyr::select(tbl,LON,LAT,YYYYMMDD,par1)
  } else if (missing(par4) & missing(par3)) {
    dplyr::select(tbl,LON,LAT,YYYYMMDD,par1,par2)
  } else if(missing(par4)) {
    dplyr::select(tbl,LON,LAT,YYYYMMDD,par1,par2,par3)
  } else {
    dplyr::select(tbl,LON,LAT,YYYYMMDD,par1,par2,par3,par4)
  }
  pnt <- st_as_sf(tbl, coords = c("LON", "LAT"), crs = 4326)
  # strs <- st_as_stars(pnt)
  # 
  # st <- stack()
  # n <- 1
  # for(i in names(pnt)[!grepl("['geometry]", names(pnt))]){
  #   vals <- pull(pnt, i) # Read vector with`` the values of the date (i)
  #   print(vals)
  #   # r <- raster(ext = extent(st_bbox(pnt)) + 0.5, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0",
  #   #             resolution = tr) # Create Raster object with the desired Target Resolution
  #   # ras <- rasterize(x = pnt,
  #   #                  y = raster(ext = extent(st_bbox(pnt)) + 0.5, resolution = 0.5),
  #   #                  field = vals)
  #   # crs(ras) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
  #   # ras <- resample(ras, r, method = "bilinear")
  #   # st <- stack(st,ras)
  #   # names(st[[n]]) <- as.character(i) # https://stackoverflow.com/questions/36844460/why-does-r-add-an-x-when-renaming-raster-stack-layers
  #   # remove(vals,ras)
  #   # n <- n + 1
  # }
  # # br <- terra::rast(brick(st))
  
  return(pnt)
}

d <- nasaP(36.5, -1.5 , 37.5, -1.0, "2020-01-01", "2020-01-30", "T10M", "T2M", "RH2M")
strs <- st_as_stars(d)
