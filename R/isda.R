isda <- function(df = NULL){
  dep <- c("top"="0..20cm","bottom"="20..50cm")
  tex <- c("clay_content"="clay_tot_psa","sand_content"="sand_tot_psa","silt_content"="silt_tot_psa", "texture_class"="texture.class")
  phy <- c("bedrock_depth_cm"="bdr","bulk_density"="db_od","ph"="ph_h2o", "stone_content"="log.wpg2","nitrogen_total"="log.n_tot_ncs")
  che <- c("carbon_total"="log.c_tot","carbon_organic"="log.oc",
           "phosphorous_extractable"="log.p_mehlich3","potassium_extractable"="log.k_mehlich3",
           "zinc_extractable"="log.zn_mehlich3","magnesium_extractable"="log.mg_mehlich3","calcium_extractable"="log.ca_mehlich3",
           "aluminium_extractable"="log.al_mehlich3","iron_extractable"="log.fe_mehlich3","sulphur_extractable"="log.s_mehlich3",
           "cation_exchange_capacity"="log.ecec.f")
  url <- "~/common_data/isda/raw/"
  aoi <- suppressWarnings(terra::vect(sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(c(xmin = min(df[,1]), xmax = max(df[,1]), ymax = max(df[,2]), ymin = min(df[,2])), crs = sf::st_crs(4326))))))
  out <- df
  out$location <- paste(out[[2]], out[[1]], sep = "_")
  out <- out[,c(3,2,1)]
  for (par in c(tex, phy, che)) {
      var <- names(c(tex, phy, che)[c(tex, phy, che) == par])
    for (d in dep) {
        lab <- names(dep[dep == d])
      if (par == "bdr"){d == "0..200cm"}
      else {
        lyr <- paste("sol",par,"m_30m",d,"2001..2017_v0.13_wgs84.tif",sep = "_")
        tif.cog <- paste0(url,lyr)
        data <- suppressWarnings(terra::crop(terra::rast(tif.cog), aoi))
        vals <- NULL
        for (pnt in seq_len(nrow(df))) {
            pnt <- df[pnt,]
            val <- terra::extract(data, data.frame(x = pnt[1], y = pnt[2]))[,2]
            if (par %in% c(che, "log.wpg2")){val <- expm1(val / 10)}
            else if (par == "db_od"){val <- val / 100}
            else if (par == "log.n_tot_ncs"){val <- expm1(val / 100)}
            else if (par == "ph_h2o"){val <- val / 10}
            else val <- val
            vals <- c(vals, val)
        }
        out <- cbind(out, vals)
        colnames(out)[ncol(out)] <- c(paste(var, lab, sep = "_"))
      }
    }
    `%not_in%` <- purrr::negate(`%in%`)
    if (var %not_in% c("bedrock_depth_cm", "texture_class")) {
      fava <- (data.frame(out[,ncol(out) - 1] + out[,ncol(out)]))/2
      colnames(fava) <- var
      out <- cbind(out, fava)
    }    
  }
  return(out)
}