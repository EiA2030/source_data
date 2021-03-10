library(nasapower)
nasaP <- function(xmin, ymin, xmax, ymax, par1, par2, par3, par4 .... ){
  daily_region_ag <- get_power(
    community = "AG",
    lonlat = c(150.5, -28.5 , 153.5, -25.5),
    pars = c("RH2M", "T2M"),
    dates = c("1985-01-01", "1985-01-02"),
    temporal_average = "DAILY"
  )