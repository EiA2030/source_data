download.noaa <- function() {
  url <- paste0("https://www.ncei.noaa.gov/data/climate-forecast-system/access/operational-9-month-forecast/6-hourly-flux")
  add.months <- function(date,n) seq(date, by = paste (n, "months"), length = 2)[2]
  system("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/*")
  dir.create("/media/TRANSFORM-EGB/other/NOAA_data/process/", showWarnings = FALSE)
  dir.create("/media/TRANSFORM-EGB/other/NOAA_data/raw/", showWarnings = FALSE)
  for (i in as.list(seq(Sys.Date()-4, add.months(Sys.Date()-4, 6), by = "day"))) {
    year <- format(as.Date(Sys.Date()-4, format="%d/%m/%Y"),"%Y")
    month <- format(as.Date(Sys.Date()-4, format="%d/%m/%Y"),"%m")
    day <- format(as.Date(Sys.Date()-4, format="%d/%m/%Y"),"%d")
    year.f <- format(as.Date(i, format="%d/%m/%Y"),"%Y")
    month.f <- format(as.Date(i, format="%d/%m/%Y"),"%m")
    day.f <- format(as.Date(i, format="%d/%m/%Y"),"%d")
    for (t in c("00")) {
      # for (t in c("00", "06", "12", "18")) {
      for (t.f in c("00", "06", "12", "18")) {
        files <- paste0(url, "/",
                        year, "/",
                        year, month, "/",
                        year, month, day, "/",
                        year, month, day, t, "/",
                        "flxf", year.f, month.f, day.f, t.f, ".01.", year, month, day, t,".grb2")
        tryCatch(
          expr = download.file(url = files,
                               destfile = paste0("/media/TRANSFORM-EGB/other/NOAA_data/raw/","flxf", year.f, month.f, day.f, t.f, ".01.", year, month, day, t,".grb2"),
                               quiet = TRUE),
          error = function(e){
            message(paste("Does not exist: ", files, sep = ""))
          }
        )
        bands <- c(11,16,31,36,37,38,41,42)
        for (b in bands) {
          bname <- ifelse(b == 11, "radl", # radl
                          ifelse(b == 16, "rads", # rads
                                 ifelse(b == 31, "prec", # prec
                                        ifelse(b == 36, "winu", # winu
                                               ifelse(b == 37, "winv", # winv
                                                      ifelse(b == 38, "temp", # temp
                                                             ifelse(b == 41, "tmax", "tmin"))))))) # tmax tmin
          bunits <- ifelse(b == 11, "W/(m^2)",
                           ifelse(b == 16, "W/(m^2)",
                                  ifelse(b == 31, "kg/(m^2 s)",
                                         ifelse(b == 36, "m/s",
                                                ifelse(b == 37, "m/s","C")))))
          dir.create(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", bname), showWarnings = FALSE)
          system(paste0("gdal_translate -b ",b," -co COMPRESS=LZW -co BIGTIFF=YES ",
                        "/media/TRANSFORM-EGB/other/NOAA_data/raw/","flxf", year.f, month.f, day.f, t.f, ".01.", year, month, day, t,".grb2 ",
                        "/media/TRANSFORM-EGB/other/NOAA_data/process/", bname,"/flxf_", bname, "_", year.f, month.f, day.f, t.f, ".01.", year, month, day, t,".tif"))
          system(paste0("gdalwarp -t_srs '+proj=longlat +datum=WGS84 +ellps=WGS84 +units=m +no_defs' -tr 0.0833 0.0833 -r bilinear -co COMPRESS=LZW -co BIGTIFF=YES --config CENTER_LONG 0 -overwrite ",
                        "/media/TRANSFORM-EGB/other/NOAA_data/process/", bname,"/flxf_", bname, "_", year.f, month.f, day.f, t.f, ".01.", year, month, day, t,".tif ",
                        "/media/TRANSFORM-EGB/other/NOAA_data/process/", bname,"/flxf_4326_", bname, "_", year.f, month.f, day.f, t.f, ".01.", year, month, day, t,".tif"))
          system(paste0("rm -r -f ",
                        "/media/TRANSFORM-EGB/other/NOAA_data/process/", bname,"/flxf_", bname, "_", year.f, month.f, day.f, t.f, ".01.", year, month, day, t,".tif"))
          # system(paste0("gdal_edit.py -unsetmd -mo BAND_NAME=", bname, " -mo BAND_UNITS=", bunits, " ",
          #               "/media/TRANSFORM-EGB/other/NOAA_data/process/", bname,"/flxf_4326_", bname, "_", year.f, month.f, day.f, t.f, ".01.", year, month, day, t,".tif"))
        }
      }
    }
    for (band in c("radl", "prec", "winu", "temp", "tmax", "tmin")) {
      if (band == "radl") {
        dir.create(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/srad"), showWarnings = FALSE)
        short <- "rads"
        l.files <- list.files(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band),
                              pattern = paste0("flxf_4326_", band, "_", year.f, month.f, day.f),
                              full.names = TRUE)
        l.avg <- tapp(rast(raster::stack(l.files)), fun = mean, index = 1)
        s.files <- list.files(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", short),
                              pattern = paste0("flxf_4326_", short, "_", year.f, month.f, day.f),
                              full.names = TRUE)
        s.avg <- tapp(rast(raster::stack(s.files)), fun = mean, index = 1)
        avg <- l.avg + s.avg
        terra::writeRaster(avg, paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", "srad", "/", "noaa_", "srad", "_4326_", year.f, month.f, day.f, "_", year, month, day, ".tif"),
                           datatype = "FLT4S", filetype = "GTiff", gdal = c("BIGTIFF=YES"), names = paste0("Solar Net Radiation [W/(m^2)] ", year.f, month.f, day.f))
        system(paste0("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/process/", band))
        system(paste0("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/process/", short))
      } else if (band == "winu") {
        dir.create(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/wind"), showWarnings = FALSE)
        v <- "winv"
        u.files <- list.files(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band),
                              pattern = paste0("flxf_4326_", band, "_", year.f, month.f, day.f),
                              full.names = TRUE)
        u.avg <- tapp(rast(raster::stack(u.files)), fun = mean, index = 1)
        v.files <- list.files(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", v),
                              pattern = paste0("flxf_4326_", v, "_", year.f, month.f, day.f),
                              full.names = TRUE)
        v.avg <- tapp(rast(raster::stack(v.files)), fun = mean, index = 1)
        avg <- sqrt(u.avg^2 + v.avg^2)
        terra::writeRaster(avg, paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", "wind", "/", "noaa_", "wind", "_4326_", year.f, month.f, day.f, "_", year, month, day, ".tif"),
                           datatype = "FLT4S", filetype = "GTiff", gdal = c("BIGTIFF=YES"), names = paste0("Wind Speed [m/s] ", year.f, month.f, day.f))
        system(paste0("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/process/", band))
        system(paste0("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/process/", v))
      } else if (band == "prec") {
        p.files <- list.files(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band, ""),
                              pattern = paste0("flxf_4326_", band, "_", year.f, month.f, day.f),
                              full.names = TRUE)
        avg <- tapp(rast(raster::stack(p.files)), fun = sum, index = 1)*86400
        terra::writeRaster(avg, paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band, "/", "noaa_", band, "_4326_", year.f, month.f, day.f, "_", year, month, day, ".tif"),
                           datatype = "FLT4S", filetype = "GTiff", gdal = c("BIGTIFF=YES"), names = paste0("Precipitation [mm] ", year.f, month.f, day.f))
        system(paste0("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/process/", band, "/flxf_4326_*"))
      } else if (band == "temp") {
        dir.create(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/vapr"), showWarnings = FALSE)
        t.files <- list.files(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band),
                              pattern = paste0("flxf_4326_", band, "_", year.f, month.f, day.f),
                              full.names = TRUE)
        avg <- tapp(rast(raster::stack(t.files)), fun = mean, index = 1)
        vapr <- 0.6121*exp((18.678-(avg/234.5))*(avg/(257.14+avg)))
        terra::writeRaster(avg, paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band, "/", "noaa_", band, "_4326_", year.f, month.f, day.f, "_", year, month, day, ".tif"),
                           datatype = "FLT4S", filetype = "GTiff", gdal = c("BIGTIFF=YES"), names = paste0("Temperature [C] ", year.f, month.f, day.f))
        terra::writeRaster(vapr, paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/vapr/noaa_vapr_4326_", year.f, month.f, day.f, "_", year, month, day, ".tif"),
                           datatype = "FLT4S", filetype = "GTiff", gdal = c("BIGTIFF=YES"), names = paste0("Water vapor pressure [kPa] ", year.f, month.f, day.f))
        system(paste0("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/process/", band, "/flxf_4326_*"))
      } else if (band == "tmax") {
        tmax.files <- list.files(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band),
                                 pattern = paste0("flxf_4326_", band, "_", year.f, month.f, day.f),
                                 full.names = TRUE)
        avg <- tapp(rast(raster::stack(tmax.files)), fun = max, index = 1)
        terra::writeRaster(avg, paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band, "/", "noaa_", band, "_4326_", year.f, month.f, day.f, "_", year, month, day, ".tif"),
                           datatype = "FLT4S", filetype = "GTiff", gdal = c("BIGTIFF=YES"), names = paste0("Temperature Maximum [C] ", year.f, month.f, day.f))
        system(paste0("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/process/", band, "/flxf_4326_*"))
      } else {
        tmin.files <- list.files(paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band),
                                 pattern = paste0("flxf_4326_", band, "_", year.f, month.f, day.f),
                                 full.names = TRUE)
        avg <- tapp(rast(raster::stack(tmin.files)), fun = min, index = 1)
        terra::writeRaster(avg, paste0("/media/TRANSFORM-EGB/other/NOAA_data/process/", band, "/", "noaa_", band, "_4326_", year.f, month.f, day.f, "_", year, month, day, ".tif"),
                           datatype = "FLT4S", filetype = "GTiff", gdal = c("BIGTIFF=YES"), names = paste0("Temperature Minimum [C] ", year.f, month.f, day.f))
        system(paste0("rm -r -f /media/TRANSFORM-EGB/other/NOAA_data/process/", band, "/flxf_4326_*"))
      }
    }
  }
}
download.noaa()
