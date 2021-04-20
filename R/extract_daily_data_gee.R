library(rgee)

ee_Initialize(display = TRUE)

# Function to generate centroids of pixels in collection
pix2pnt <- function(collection, xmin, ymin, xmax, ymax){
  collection$first()$sample(region = ee$Geometry$BBox(xmin,ymin,xmax,ymax), geometries = TRUE)
}

# Function to extract data from ImageCollections to points
zonalStats <- function(collection, params, xmin, ymin, xmax, ymax){
  # Create sampling points
  pnts <- pix2pnt(collection = collection, xmin = xmin, ymin = ymin , xmax = xmax, ymax = ymax)
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
        fcSub <- pnts$filterBounds(img$geometry())
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

###########################               EXAMPLES                 ##########################

# Define parameters for ALL ImageCollection-s
params <- list(reducer = ee$Reducer$mean(),
               scale = NULL,
               crs = 'EPSG:4326',
               bands = NULL,
               bandsRename = NULL,
               imgProps = NULL,
               imgsPropsRename = NULL,
               datetimeName = 'system:index',
               datetimeFormat = 'YYYYMMdd')

# Copy pixel values of ImageCollection to points
srad.pnts <- zonalStats(srad, pnts, params)
tmin.pnts <- zonalStats(tmin, pnts, params)
tmax.pnts <- zonalStats(tmax, pnts, params)
h2op.pnts <- zonalStats(vapr, pnts, params)
windU.pnts <- zonalStats(wind.U, pnts, params)
windV.pnts <- zonalStats(wind.V, pnts, params)

# Export to Google Cloud Storage
# N.B.: Exported elemets to GCS are not public by default.
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
