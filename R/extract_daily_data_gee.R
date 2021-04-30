# # Function to generate centroids of pixels in collection
pix2pnt <- function(collection, xmin, ymin, xmax, ymax){
  require(rgee)
  ee_Initialize(display = TRUE)
  aoi = ee$Geometry$BBox(xmin,ymin,xmax,ymax)
  proj <- collection$first()$projection()
  latlon <- collection$first()$pixelLonLat()$reproject(proj)
  coords <- latlon$select('longitude', 'latitude')$
    reduceRegion(
      reducer = ee$Reducer$toList(),
      geometry = aoi,
      scale = proj$nominalScale()$toInt(),
      maxPixels = 10e10
    )
  xy <- ee$List(coords$get('longitude'))$zip(ee$List(coords$get('latitude')))
  l <- ee$List(list(0))
  feats <- ee$FeatureCollection(
    xy$map(
      ee_utils_pyfunc(
        function(point) {
          ind <- xy$indexOf(point)
          feat <- ee$Feature(ee$Geometry$Point(xy$get(ind)))
          return(l$add(feat))
        }
      )
    )$flatten()$removeAll(list(0))
  )
  return(feats)
}

# Function to extract data from ImageCollections to points
zonalStats <- function(collection, params, xmin, ymin, xmax, ymax){
  require(rgee)
  ee_Initialize(display = TRUE)
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
