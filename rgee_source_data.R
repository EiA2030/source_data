library(rgee)
library(RCurl)
library(sf)
library(data.table)

ee_Initialize(display = TRUE)

####################################################################################################################################
#######                                         SOURCE DATA from Google Earth Engine                                        ########
####################################################################################################################################

# Create a Bounding Box for the Area of Interest (AOI)  
aoi <- ee$Geometry$BBox(34.8145177, -15.3265231, 35.3005743, -14.77034)

# Daily precipitation (mm) data from CHIRPS
prec <- ee$ImageCollection("UCSB-CHG/CHIRPS/DAILY")$
  select("precipitation")$
  filterDate("2010-01-01", "2015-12-31")$
  filterBounds(aoi)

# Daily temperature (C) from ECMWF
tmin <- ee$ImageCollection("ECMWF/ERA5/DAILY")$
  select("minimum_2m_air_temperature")$
  filterDate("2010-01-01", "2015-12-31")$
  filterBounds(aoi)

# Daily temperature (C) from ECMWF
tmax <- ee$ImageCollection("ECMWF/ERA5/DAILY")$
  select("maximum_2m_air_temperature")$
  filterDate("2010-01-01", "2015-12-31")$
  filterBounds(aoi)

# Daily wind U (m/s) from ECMWF
wind.U <- ee$ImageCollection("ECMWF/ERA5/DAILY")$
  select("u_component_of_wind_10m")$
  filterDate("2010-01-01", "2015-12-31")$
  filterBounds(aoi)

# Daily wind V (m/s) from ECMWF
wind.V <- ee$ImageCollection("ECMWF/ERA5/DAILY")$
  select("v_component_of_wind_10m")$
  filterDate("2010-01-01", "2015-12-31")$
  filterBounds(aoi)

# Daily average water vapor pressure from (NCEP)
h2op <- ee$ImageCollection(
  ee$List$sequence(0,6*365)$map(
    ee_utils_pyfunc(
      function(n) {
        s <- ee$Date('2010-01-01')$advance(n, 'day')
        e <- s$advance(1, 'day')
        return(ee$ImageCollection("NCEP_RE/surface_wv")$
                 filterDate(s, e)$
                 select("pr_wtr")$
                 filterBounds(aoi)$
                 mean()$
                 set('system:time_start', s$millis())$
                 set('system:index', s$format("YYYYMMdd"))
        )
      }
    )
  )
)

# Daily average solar net radiation () from ECMWF
srad <- ee$ImageCollection(
  ee$List$sequence(0,6*365)$map(
    ee_utils_pyfunc(
      function(n) {
        s <- ee$Date('2010-01-01')$advance(n, 'day')
        e <- s$advance(1, 'day')
        return(ee$ImageCollection("ECMWF/ERA5_LAND/HOURLY")$
                 filterDate(s, e)$
                 select("surface_net_solar_radiation")$
                 filterBounds(aoi)$
                 mean()$
                 set('system:time_start', s$millis())$
                 set('system:index', s$format("YYYYMMdd"))
        )
      }
    )
  )
)

####################################################################################################################################
####################################################################################################################################

####################################################################################################################################
#######                                               EXTRACT DATA from sourced data                                        ########
####################################################################################################################################

# Function to generate centroids of pixels in collection
pix2pnt <- function(collection, AOI){
  collection$first()$sample(region = AOI, geometries = TRUE)
}
# Generate points
pnts <- pix2pnt(collection = prec, AOI = aoi)

# Function to extract data from ImageCollections to points
zonalStats <- function(collection, features, params){
  # Initialize internal params dictionary.
  pars <- list('reducer' = ee$Reducer$mean(),
               'scale' = NULL,
               'crs' = NULL,
               'bands' = NULL,
               'bandsRename' = NULL,
               'imgProps' = NULL,
               'imgsPropsRename' = NULL,
               'datetimeName' = 'datetime',
               'datetimeFormat' = 'YYYY-MM-dd')
  # Replace initialized params with provided params.
  if(!missing(params)){
    for(param in names(params)){
      pars[param] <- params[param]
    }
  }
  # Set default parameters based on an image representative.
  imgRep <- collection$first()
  nonSystemImgProps <- ee$Feature(NULL)$copyProperties(imgRep)$propertyNames()
  if(is.null(pars$bands)){
    pars$bands <- imgRep$bandNames()
  }
  if(is.null(pars$bandsRename)){
    pars$bandsRename <- pars$bands
  }
  if(is.null(pars$imgProps)){
    pars$imgProps <- nonSystemImgProps
  }
  if(is.null(pars$imgsPropsRename)){
    pars$imgsPropsRename <- pars$imgProps
  }
  # Map the reduceRegions function over the image collection.
  results <- collection$map(
    ee_utils_pyfunc(
      function(image){
        # Select bands (optionally rename), set a datetime & timestamp property.
        # img <- ee$Image(image)
        
        img <- ee$Image(image$select(pars$bands, pars$bandsRename))$
          set(pars$datetimeName, image$date()$format(pars$datetimeFormat))$
          set('timestamp', image$get('system:time_start'))
        
        # Subset points that intersect the given image.
        fcSub <- features$filterBounds(img$geometry())
        # Reduce the image by regions.
        return(img$reduceRegions(
          collection = fcSub,
          reducer = pars$reducer,
          scale = img$projection()$nominalScale(),
          crs = img$projection()
        ))
      }
    )
  )$flatten()
  return(results)
}

# Define parameters for ALL ImageCollection-s
params <- list(crs = 'EPSG:4326',
               datetimeName = 'system:index',
               datetimeFormat = 'YYYYMMdd')

# Copy pixel values of ImageCollection to points
srad.pnts <- zonalStats(srad, pnts, params)
tmin.pnts <- zonalStats(tmin, pnts, params)
tmax.pnts <- zonalStats(tmax, pnts, params)
h2op.pnts <- zonalStats(h2op, pnts, params)
windU.pnts <- zonalStats(wind.U, pnts, params)
windV.pnts <- zonalStats(wind.V, pnts, params)

# Export to GCS
task_srad <- ee_table_to_gcs(srad.pnts, description = "export weather data", bucket = 'your_GCS_bucket', fileNamePrefix = "points_srad_", fileFormat = "GeoJSON")
task_srad$start()
task_tmin <- ee_table_to_gcs(tmin.pnts, description = "export weather data", bucket = 'your_GCS_bucket', fileNamePrefix = "points_tmin_", fileFormat = "GeoJSON")
task_tmin$start()
task_tmax <- ee_table_to_gcs(tmax.pnts, description = "export weather data", bucket = 'your_GCS_bucket', fileNamePrefix = "points_tmax_", fileFormat = "GeoJSON")
task_tmax$start()
task_vapr <- ee_table_to_gcs(h2op.pnts, description = "export weather data", bucket = 'your_GCS_bucket', fileNamePrefix = "points_vapr_", fileFormat = "GeoJSON")
task_vapr$start()
task_windU <- ee_table_to_gcs(windU.pnts, description = "export weather data", bucket = 'your_GCS_bucket', fileNamePrefix = "points_windU_", fileFormat = "GeoJSON")
task_windU$start()
task_windV <- ee_table_to_gcs(windV.pnts, description = "export weather data", bucket = 'your_GCS_bucket', fileNamePrefix = "points_windV_", fileFormat = "GeoJSON")
task_windV$start()
ee_monitoring(eeTaskList = T)

####################################################################################################################################
####################################################################################################################################

####################################################################################################################################
#######                                               FORMAT DATA from extracted data                                        ########
####################################################################################################################################

srad.col <- data.table::data.table(read_sf("https://storage.googleapis.com/iita_transform_bucket/points_srad__2021_04_13_15_36_58.geojson"))
colnames(srad.col) <- c("date", "srad_J/m2", "deleteme","geo")
srad.col$date <- as.Date(substr(srad.col$date, 1,8), "%Y%m%d")
srad.col <- cbind(srad.col, st_coordinates(srad.col$geo))
srad.col <- srad.col[, c(1,2,5,6)]
data.table::setkey(srad.col,date,X,Y)
tmin.col <- data.table::data.table(read_sf("https://storage.googleapis.com/iita_transform_bucket/points_tmin__2021_04_13_15_37_00.geojson"))
colnames(tmin.col) <- c("date", "tmin_K", "deleteme", "geo")
tmin.col$date <- as.Date(substr(tmin.col$date, 1,8), "%Y%m%d")
tmin.col <- cbind(tmin.col,date,st_coordinates(tmin.col$geo))
tmin.col <- tmin.col[, c(1,2,6,7)]
data.table::setkey(tmin.col,date,X,Y)
tmax.col <- data.table::data.table(read_sf("https://storage.googleapis.com/iita_transform_bucket/points_tmax__2021_04_13_15_37_01.geojson"))
colnames(tmax.col) <- c("date", "tmax_K", "deleteme", "geo")
tmax.col$date <- as.Date(substr(tmax.col$date, 1,8), "%Y%m%d")
tmax.col <- cbind(tmax.col,date,st_coordinates(tmax.col$geo))
tmax.col <- tmax.col[, c(1,2,6,7)]
data.table::setkey(tmax.col,date,X,Y)
vapr.col <- data.table::data.table(read_sf("https://storage.googleapis.com/iita_transform_bucket/points_vapr__2021_04_13_15_37_02.geojson"))
colnames(vapr.col) <- c("date", "vapr_kg/m2", "deleteme", "geo")
vapr.col$date <- as.Date(substr(vapr.col$date, 1,8), "%Y%m%d")
vapr.col <- cbind(vapr.col,date,st_coordinates(vapr.col$geo))
vapr.col <- vapr.col[, c(1,2,6,7)]
data.table::setkey(vapr.col,date,X,Y)
windU.col <- data.table::data.table(read_sf("https://storage.googleapis.com/iita_transform_bucket/points_windU__2021_04_13_15_37_04.geojson"))
colnames(windU.col) <- c("date", "windU_m/s", "deleteme", "geo")
windU.col$date <- as.Date(substr(windU.col$date, 1,8), "%Y%m%d")
windU.col <- cbind(windU.col,date,st_coordinates(windU.col$geo))
windU.col <- windU.col[, c(1,2,6,7)]
data.table::setkey(windU.col,date,X,Y)
windV.col <- data.table::data.table(read_sf("https://storage.googleapis.com/iita_transform_bucket/points_windV__2021_04_13_15_37_05.geojson"))
colnames(windV.col) <- c("date", "windV_m/s", "prec_mm", "geo")
windV.col$date <- as.Date(substr(windV.col$date, 1,8), "%Y%m%d")
windV.col <- cbind(windV.col,date,st_coordinates(windV.col$geo))
windV.col <- windV.col[, c(1,2,3,6,7)]
data.table::setkey(windV.col,date,X,Y)

dmerge = function(x,y) merge(x,y,all=TRUE, no.dups = TRUE)
weather <- Reduce(dmerge,list(srad.col,tmin.col,tmax.col,vapr.col,windU.col,windV.col))