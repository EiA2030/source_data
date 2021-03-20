library(rgee)
library(osmdata)
library(sf)
library(geojsonsf)
# ee_reattach() # reattach ee as a reserved word

ee_Initialize(drive = TRUE)

## Get Kiambu data
kmb <- opq(bbox = 'Kiambu KE', timeout = 25*10) %>%
  add_osm_feature(key = 'name', value = "Kiambu", value_exact = T) %>%
  add_osm_feature(key = 'admin_level', value = "4", value_exact = T) %>%
  osmdata_sf()
## Get Nairobi Data
nrb <- opq(bbox = 'Nairobi KE', timeout = 25*10) %>%
  add_osm_feature(key = 'name', value = "Nairobi", value_exact = T) %>%
  add_osm_feature(key = 'admin_level', value = "4", value_exact = T) %>%
  osmdata_sf()
## UNION both and create a new AOI
aoi <- list(st_bbox(st_union(kmb$osm_multipolygons, nrb$osm_multipolygons, crs = 4326)))[[1]]
aoi <- ee$Geometry$BBox(aoi[[1]],aoi[[2]],aoi[[3]],aoi[[4]])

# Load an image collection
chirps <- ee$ImageCollection("UCSB-CHG/CHIRPS/DAILY")$
  filterDate('2020-01-01', '2020-01-3')

# clip images to AOI
clipAOI <- function(image) {
  return(image$clip(aoi))
}
chirps <- chirps$map(clipAOI)

# Center the map and display the image.
Map$setCenter(list(aoi$centroid(1)$coordinates()$getInfo())[[1]][1],
              list(aoi$centroid(1)$coordinates()$getInfo())[[1]][2],
              10)
# Visualize one image...
viz <- list(
  max = 1,
  min = 0,
  palette = c("#ffffff","#3d29ff")
)
Map$addLayer(
  eeObject = ee$Image(chirps$toList(1,1)$get(0)),
  visParams =  viz,
  name = as.character(paste0("CHIRPS ", as.character(strptime(ee$Image(chirps$toList(1,1)$get(0))$get('system:index')$getInfo(), "%Y%m%d")))),
  opacity = 0.7,
  legend = TRUE
)

ee_imagecollection_to_local(
  ic = chirps,
  region = aoi,
  dsn = "CHIRPS_"
)

