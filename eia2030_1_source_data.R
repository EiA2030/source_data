## Access NASA POWER API
nasaP <- function(xmin, ymin, xmax, ymax, sdate, edate, par1, par2, par3, par4, tr){ # For the moment 4 parameters. This can be extended later, or make it more flexible to allow the user to select parameters.
  require(nasapower)
  require(sf)
  require(raster)
# Fetch NASA POWER data  
  tbl <- get_power(
    community = "AG",
    lonlat = c(xmin, ymin, xmax, ymax), # BBOX for the ROI. There is a limit on the size of the BBOX.
# This collects the info from the indicated parameters
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
# Create object as a raw table from the POWER API
  assign("table", tbl, envir = .GlobalEnv)
# Format table removing unnecessary columns (i.e.: DOY, YEAR, MONTH, etc)
    tbl <- if(missing(par4) & missing(par3) & missing(par2)) {
    dplyr::select(tbl,LON,LAT,YYYYMMDD,par1)
  } else if (missing(par4) & missing(par3)) {
    dplyr::select(tbl,LON,LAT,YYYYMMDD,par1,par2)
  } else if(missing(par4)) {
    dplyr::select(tbl,LON,LAT,YYYYMMDD,par1,par2,par3)
  } else {
    dplyr::select(tbl,LON,LAT,YYYYMMDD,par1,par2,par3,par4)
  }
# Create a sf object with POINT_GEOMETRY
  pnt <- st_as_sf(tbl, coords = c("LON", "LAT"), crs = 4326)
  assign("points", pnt, envir = .GlobalEnv)
# Create new objects for each parameter selected  
  lapply(names(pnt)[!grepl(paste(c("YYYYMMDD","geometry"), collapse="|"), names(pnt))], function(x) assign(x, pnt[c("YYYYMMDD",x)], envir = .GlobalEnv))
  n <- 0
# Rasterize the sf of each parameter at a selected resolution (tr)
  for(i in names(pnt)[!grepl(paste(c("YYYYMMDD", "geometry"), collapse="|"), names(pnt))]){
    r <- raster(ext = extent(st_bbox(pnt)) + 0.5, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0", resolution = 0.5)
    st <- stack()
    j <- get(i, envir = .GlobalEnv)
    j <-tidyr::spread(j, "YYYYMMDD", i)
    ## Re-format column labels
    colnames(j) <- gsub('-', '_', colnames(j), fixed=TRUE)
    for(k in names(j)[!grepl("['geometry]", names(j))]){
      vals <- dplyr::pull(j, k) # Read vector with`` the values of the date (k)
      r <- raster(ext = extent(st_bbox(j)) + 0.5, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0",
                  resolution = tr) # Create Raster object with the desired Target Resolution
      ras <- rasterize(x = j,
                       y = raster(ext = extent(st_bbox(j)) + 0.5, resolution = 0.5),
                       field = vals)
      crs(ras) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
      ras <- resample(ras, r, method = "bilinear")
      st <- stack(st,ras)
      # names(st[[n]]) <- as.character(k) # https://stackoverflow.com/questions/36844460/why-does-r-add-an-x-when-renaming-raster-stack-layers
# Create RasterStack of each object       
      assign(paste0(i), st , envir = .GlobalEnv)
      remove(vals,ras)
      n <- n + 1
    }
  }
}
