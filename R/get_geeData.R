download.vars <- function(aoi, gee.user, gcs.bucket, dest.path){
  pol <- terra::vect(aoi)
  pol <- terra::project(pol,'EPSG:4326')
  xmin <- terra::ext(pol)[1]
  ymin <- terra::ext(pol)[3]
  xmax <- terra::ext(pol)[2]
  ymax <- terra::ext(pol)[4]
  tmp <- dest.path
  require(rgee)
  require(googleCloudStorageR)
  ee_Initialize(user = gee.user, gcs = T)
  bb <- ee$Geometry$BBox(xmin,ymin,xmax,ymax)
  # Download WorldClim variables
  clim <- function(b, bb){
    img <- ee$Image("WORLDCLIM/V1/BIO")$
      select(b)$
      clip(bb)
    if(b %in% c("bio12","bio15","bio16")){
      img <- img$expression('BAND*0.1', list(BAND = img$select(b)))
    }
    task_img <- ee_image_to_gcs(img, bucket = gcs.bucket, scale = 1000, fileFormat = 'GEO_TIFF', region = bb, fileNamePrefix = paste0("WorldClim_",b))
    task_img$start()
    ee_monitoring(task_img)
    Sys.sleep(100)
    # ras <- ee_gcs_to_local(task = task_img, dsn = paste(tmp, b, sep = '/'), public = TRUE, overwrite = TRUE)
    robj <- gcs_list_objects(prefix = b, bucket = gcs.bucket)
    gcs_get_object(robj$name, saveToDisk = paste(tmp, paste0(b,".tif"), sep = '/'), bucket = gcs.bucket, overwrite = TRUE)
    gcs_delete_object(robj$name, bucket = gcs.bucket)
  }
  wc.1 <- clim(b = "bio01", bb = bb)
  wc.12 <- clim(b = "bio12", bb = bb)
  wc.15 <- clim(b = "bio15", bb = bb)
  wc.16 <- clim(b = "bio16", bb = bb)
  # Download SoilGrids variables
  devtools::source_url("https://raw.githubusercontent.com/EiA2030/source_data/main/R/soilgrids250_download.R")
  BDO <- soilgrids250_download(par = "bdod", depth = "5-15", xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax, path = tmp)
  SOC <- soilgrids250_download(par = "soc", depth = "5-15", xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax, path = tmp)
  N <- soilgrids250_download(par = "nitrogen", depth = "5-15", xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax, path = tmp)
  PH <- soilgrids250_download(par = "phh2o", depth = "5-15", xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax, path = tmp)
  CEC <- soilgrids250_download(par = "cec", depth = "5-15", xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax, path = tmp)
  clay <- soilgrids250_download(par = "clay", depth = "5-15", xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax, path = tmp)
  sand <- soilgrids250_download(par = "sand", depth = "5-15", xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax, path = tmp)
  # Download Vegetation variables (MODIS)
  means <- function(col, b, sdate = '2020-01-01', edate = '2021-01-01', bb){
    img <- ee$ImageCollection(col)$
      filterDate(sdate, edate)$
      filterBounds(bb)$
      select(b)$
      mean()$
      clip(bb)
    img <- img$expression('BAND*0.0001', list(BAND = img$select(b)))
    task_img <- ee_image_to_gcs(img, bucket = gcs.bucket, scale = 1000, fileFormat = 'GEO_TIFF', region = bb, fileNamePrefix = b)
    task_img$start()
    ee_monitoring(task_img)
    Sys.sleep(100)
    # ras <- ee_gcs_to_local(task = task_img, dsn = paste(tmp, b, sep = '/'), public = TRUE, overwrite = TRUE)
    robj <- gcs_list_objects(prefix = b, bucket = gcs.bucket)
    gcs_get_object(robj$name, saveToDisk = paste(tmp, paste0(b,".tif"), sep = '/'), bucket = gcs.bucket, overwrite = TRUE)
    gcs_delete_object(robj$name, bucket = gcs.bucket)
  }
  evi <- means(col = "MODIS/006/MOD13A2", b = "EVI", bb = bb)
  gpp <- means(col = "MODIS/006/MOD17A2H", b = "Gpp", bb = bb)
  # Mask: PAs, Urban, water
  bb <- ee$Geometry$BBox(xmin,ymin,xmax,ymax)
  valU <- ee$List(list(2))
  valW <- ee$List(list(1))
  urban <- ee$Image("JRC/GHSL/P2016/BUILT_LDSMT_GLOBE_V1")$select('built')$rename(list('mask'))$clip(bb)
  water <- ee$Image("JRC/GSW1_3/GlobalSurfaceWater")$select('occurrence')$rename(list('mask'))$clip(bb)
  pas <- ee$FeatureCollection('WCMC/WDPA/current/polygons')
  urban <- urban$updateMask(urban$neq(ee$Image$constant(valU))$reduce(ee$Reducer$anyNonZero()))
  water <- water$updateMask(water$gt(ee$Image$constant(valW))$reduce(ee$Reducer$anyNonZero()))
  pas <- pas$filter(ee$Filter$notNull(list("WDPAID")))$reduceToImage(properties = list("WDPAID"), reducer = ee$Reducer$first())$rename(list('mask'))$clip(bb)
  urban <- urban$divide(urban)$ceil()$reproject(crs = "EPSG:4326", scale = 1000)
  water <- water$divide(water)$ceil()$reproject(crs = "EPSG:4326", scale = 1000)
  pas <- pas$divide(pas)$ceil()$reproject(crs = "EPSG:4326", scale = 1000)
  mask <- ee$ImageCollection$fromImages(list(urban, water, pas))$mosaic()
  task_img <- ee_image_to_gcs(mask, bucket = gcs.bucket, scale = 1000, fileFormat = 'GEO_TIFF', region = bb, fileNamePrefix = 'MASK')
  task_img$start()
  ee_monitoring(task_img)
  Sys.sleep(100)
  # mask.gee <- ee_gcs_to_local(task = task_img, dsn = paste(tmp, 'MASK.tif', sep = '/'), public = TRUE, overwrite = TRUE)
  robj <- gcs_list_objects(prefix = b, bucket = gcs.bucket)
  gcs_get_object(robj$name, saveToDisk = paste(tmp, paste0(b,".tif"), sep = '/'), bucket = gcs.bucket, overwrite = TRUE)
  gcs_delete_object(robj$name, bucket = gcs.bucket)
  mask <- terra::rast(paste(tmp, paste0("MASK",".tif"), sep = '/'))
}

# # Example
# download.vars(aoi = "aoi.shp", user = "validated_gee_user@gmail.com", gcs.bucket = "GCS_bucket", dest.path = "path/to/dir")
