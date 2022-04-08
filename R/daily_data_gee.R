library(rgee)

ee_Initialize(display = TRUE)

# Function for ImageCollections with daily data 
daily.IC <- function(imcol,band,sdate,edate,xmin,ymin,xmax,ymax){
  return(ee$ImageCollection(imcol)$
           select(band)$
           filterDate(sdate, edate)$
           filterBounds(ee$Geometry$BBox(xmin,ymin,xmax,ymax)))
}
# Function to aggregate Image Collections with sub-daily data
aggDaily.IC <- function(imcol,band,sdate,edate,xmin,ymin,xmax,ymax){
  len <- length(as.character(seq(as.Date(sdate), as.Date(edate), "days")))
  return(ee$ImageCollection(
    ee$List$sequence(0,len)$map(
      ee_utils_pyfunc(
        function(n) {
          s <- ee$Date(sdate)$advance(n, 'day')
          e <- s$advance(1, 'day')
          return(ee$ImageCollection(imcol)$
                   filterDate(s, e)$
                   select(band)$
                   filterBounds(ee$Geometry$BBox(xmin,ymin,xmax,ymax))$
                   mean()$
                   set('system:time_start', s$millis())$
                   set('system:index', s$format("YYYYMMdd"))
          )
        }
      )
    )
  )
  )
}

# # Example: Daily precipitation (mm) data from CHIRPS
# prec <- daily.IC(imcol = "UCSB-CHG/CHIRPS/DAILY", band = "precipitation", sdate = "2010-01-01", edate = "2015-12-31", xmin = 34.8145177, ymin = -15.3265231, xmax = 35.3005743, ymax = -14.77034)
# # Example: Daily average solar net radiation () from ECMWF
# srad <- aggDaily.IC(imcol = "ECMWF/ERA5_LAND/HOURLY", band = "surface_net_solar_radiation", sdate = "2010-01-01", edate = "2015-12-31", xmin = 34.8145177, ymin = -15.3265231, xmax = 35.3005743, ymax = -14.77034)

