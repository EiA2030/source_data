colGEE <- function(imagecollection, tr, xmin, ymin, xmax, ymax, sdate, edate){
  require(rgee)
  require(sf)
  
  # Initialize GEE
  ee_Initialize(drive = TRUE)
  
  # Load an image collection
  chirps <- ee$ImageCollection(imagecollection)$
    filterDate(sdate, edate)
    # filterDate("2020-01-01", "2020-01-03")

  # Create a Bounding Box for the Area of Interest (AOI)  
  # aoi <- list(st_bbox(c(xmin = xmin, xmax = xmax, ymax = ymax, ymin = ymin), crs = st_crs(4326)))[[1]]
  aoi <- list(st_bbox(c(xmin = 36, xmax = 37, ymax = -2, ymin = -1), crs = st_crs(4326)))[[1]]
  aoi <- ee$Geometry$BBox(aoi[[1]],aoi[[2]],aoi[[3]],aoi[[4]])
  
  # Clip images to defined AOI
  clipAOI <- function(image) {
    return(image$clip(aoi))
  }
  chirps <- chirps$map(clipAOI)
  
  # Save images into directory
  ee_imagecollection_to_local(ic = chirps, region = aoi, dsn = "CHIRPS_", maxPixels = 1e13, scale = tr)
  
  # Build Multi-Band Raster with the stored images (then delete them)
  st <- stack()
  n <- 1
  #Create RasterStack
  for(i in list.files(pattern = ".tif")) {
    r <- raster(i)
    st <- stack(st,r)
    names(st[[n]]) <- as.character(tools::file_path_sans_ext(i))
    file.remove(i)
    n <- n + 1
  }
  
  #Save Multi-Band Raster
  writeRaster(st,"CHIRPS.tif", format="GTiff", options="INTERLEAVE=BAND",)
}

colGEE("UCSB-CHG/CHIRPS/DAILY", 0.05, 36, -2, 37, 1, "2020-01-01", "2020-01-10")