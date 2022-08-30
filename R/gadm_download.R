#' Download country administrative layers from GADM (https://gadm.org/)
#'
#' @param iso ISO3 code of the country of interest
#' @param path directory to download the data (default is a temporary directory)
#' @return NULL
#' @examples
#' gadm41.download(iso = "MOZ")

gadm36.download <- function(iso = NULL, path = tempdir()){
  dir.create(paste(path, "raw", sep = "/"), showWarnings = TRUE)
  url <- paste0("https://geodata.ucdavis.edu/gadm/gadm3.6/gpkg/gadm36_", iso, "_gpkg.zip")
  download.file(url, destfile = paste0(path,"/raw/gadm36_", iso, "_gpkg.zip"))
  unzip(paste0(path,"/raw/gadm36_", iso, "_gpkg.zip"), exdir = path)
  for (l in sf::st_layers(paste0(path,"/raw/gadm36_", iso, ".gpkg")[1])) {
    for (k in l) {
      pol <- sf::st_read(fname, layer = k, quiet = T)
      if(isFALSE(sf::st_is_valid(pol))){sf::sf_write(obj = sf::st_make_valid(pol), dsn = l, layer = k, append = FALSE)}
    }
  }
  return(NULL)
}

gadm41.download <- function(iso = NULL, path = tempdir()){
  dir.create(paste(path, "raw", sep = "/"), showWarnings = TRUE)
  url <- paste0("https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/gadm41_", iso, "_gpkg.zip")
  download.file(url, destfile = paste0(path,"/raw/gadm41_", iso, "_gpkg.zip"))
  unzip(paste0(path,"/raw/gadm41_", iso, "_gpkg.zip"), exdir = path)
  for (l in sf::st_layers(paste0(path,"/raw/gadm41_", iso, ".gpkg")[1])) {
    for (k in l) {
      pol <- sf::st_read(fname, layer = k, quiet = T)
      if(isFALSE(sf::st_is_valid(pol))){sf::sf_write(obj = sf::st_make_valid(pol), dsn = l, layer = k, append = FALSE)}
    }
  }
  return(NULL)
}
