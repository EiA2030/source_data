colGEE <- function(imagecollection, tr, xmin, ymin, xmax, ymax, sdate, edate){
  require(rgee)
  require(sf)
  require(raster)
  
  # Initialize GEE
  ee_Initialize(drive = TRUE)
  
  # Load an image collection
  chirps <- ee$ImageCollection(imagecollection)$
    filterDate(sdate, edate)

  # Create a Bounding Box for the Area of Interest (AOI)  
  aoi <- ee$Geometry$BBox(xmin, ymin, xmax, ymax)

  # Clip images to defined AOI
  clipAOI <- function(image) {
    return(image$clip(aoi))
  }
  chirps <- chirps$map(clipAOI)
  
  # Save images into directory
  ee_imagecollection_to_local(ic = chirps, region = aoi, dsn = "CHIRPS_", maxPixels = 1e13)

  # Build Multi-Band Raster with the stored images (then delete them)
  r <- raster(ext = extent(st_bbox(c(xmin = xmin, xmax = xmax, ymax = ymax, ymin = ymin), crs = st_crs(4326))) + 0.5,
              crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0",
              resolution = tr)
  st <- stack()
  n <- 1
  #Create RasterStack
  for(i in list.files(pattern = ".tif")) {
    ras <- raster(i)
    r <- resample(ras, r, method = "bilinear")
    st <- stack(st,r)
    names(st[[n]]) <- as.character(tools::file_path_sans_ext(i))
    file.remove(i)
    n <- n + 1
  }
  
  #Save Multi-Band Raster
  writeRaster(brick(st),
              "gee_download.tif",
              format = "GTiff",
              options = c("COMPRESS=LZW", "INTERLEAVE=BAND"),
              bandorder = 'BIL',
              progress = "text")
}

# Example: 
colGEE("UCSB-CHG/CHIRPS/DAILY", 0.025, 36, -2, 37, -1, "2020-01-01", "2020-01-10")
