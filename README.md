# Sourcing Available Data

Gather available data and make decisions on the need for new data. This involves standardising data collection methods from different sources. The data collection approaches will be used to satisfy data needs for for all use cases as well as the next phase of EiA. This stage also involves evaluation of available  data for suitability for use. Where data is insufficient in terms of quantity and quality, recommendations will be made for collection of additional data.

## Sources available

|   | **Climatic/Meteorology**          | Source             | Platform               | Tools                 |
|---|-----------------------------------|--------------------|------------------------|-----------------------|
| 1 | Precipitation                     | GEE                | GEE                    | daily_data_gee.R      |
| 2 | Solar Net Radiation               | GEE/NASA POWER     | GEE/NASA POWER         | nasapower_download.R  |
| 3 | Temperature                       | GEE/NASA POWER     | GEE/NASA POWER         | nasapower_download.R  |
| 4 | ...                               | ...                | ...                    | ...                   |
| 5 | ...                               | ...                | ...                    | ...                   |
| 6 | ...                               | ...                | ...                    | ...                   |

|    | **Soil**                          | Source         | ID                     | Platform/Tools        |
|----|-----------------------------------|----------------|------------------------|-----------------------|
| 1  | N total                           | iSDA           | log.n_tot_ncs_m_30m    | isda_download.R       |
| 2  | Bulk density                      | iSDA           | db_od_m_30m            | isda_download.R       |
| 3  | Phosphorous extractable           | iSDA           | log.p_mehlich3_m_30m   | isda_download.R       |
| 4  | Bedrock depth                     | iSDA           | bdr_m_30m              | isda_download.R       |
| 5  | Calcium extractable               | iSDA           | log.ca_mehlich3_m_30m  | isda_download.R       |
| 6  | Carbon organic                    | iSDA           | log.oc_m_30m           | isda_download.R       |
| 7  | Carbon total                      | iSDA           | log.c_tot_m_30m        | isda_download.R       |
| 8  | CEC                               | iSDA           | log.ecec.f_m_30m       | isda_download.R       |
| 9  | Clay content                      | iSDA           | sol_clay_tot_psa_m_30m | isda_download.R       |
|    |                                   |                |                        |                         |
| 10 | N total                           | SoilGrids      | nitrogen               | soilgrids250_download.R |
| 11 | Bulk density                      | SoilGrids      | bdod                   | soilgrids250_download.R |
| 12 | CEC                               | SoilGrids      | cec                    | soilgrids250_download.R |
| 13 | Soil pH                           | SoilGrids      | phh2o                  | soilgrids250_download.R |
| 14 | Clay content                      | SoilGrids      | clay                   | soilgrids250_download.R |
| 15 | Sand                              | SoilGrids      | sand                   | soilgrids250_download.R |
| 16 | Silt                              | SoilGrids      | silt                   | soilgrids250_download.R |
| 17 | Soil organic carbon content       | SoilGrids      | soc                    | soilgrids250_download.R |
| 18 | ...                               | SoilGrids      | ...                    | ...                   |

|   | **Crop Yield**                    | Source             | Platform               | Tools                 |
|---|-----------------------------------|--------------------|------------------------|-----------------------|
| 1 |  ?                                | GARDIAN            | CG Labs                |                       |
| 2 |  ?                                | GARDIAN            | CG Labs                |                       |
| 3 |  ?                                | GARDIAN            | CG Labs                |                       |
| 4 | ...                               | ...                | ...                    | ...                   |

## Examples
#### NASA POWER:
NASA POWER Provides solar and meteorological data sets from NASA research for support of renewable energy, building energy efficiency and supporting agricultural data needs. Data services are provided through a series of restful Application Programming Interfaces (API) distributing Analysis Ready Data to end users. Making use of the [``nasapower`` R package](https://github.com/ropensci/nasapower) we can access a variety of data in several ways:
1. Using CG Labs data gathering tools and Fformat your selected NASA POWER data to the desired format (table; vector points; raster stack) using ``nasapower_json2output.R``. Fr example:
    f_tblR.JSON("POWER_Regional_Daily_20210101_20210110_d2b00515.json", "t2m")
2. Using the [``nasaP``](https://github.com/EiA2030/source_data/blob/main/R/nasapower_download.R) function facilitating the use of [``nasapower`` R package](https://cran.r-project.org/web/packages/nasapower/), and alo obtaining data in the desired format (table; vector points; raster stack). For example:
    nasaP(tr = 0.08333, xmin = 36, ymin = -2, xmax = 39, ymax = 1, sdate = "2021-01-01", edate = "2021-01-10", "T2M", "T10M", "PS", "RH2M")

#### iSDA Africa Soil:
Most of agronomic decisions depend on available data on soil health or soil characteristics. We have found 2 main data providers: iSDA and SoilGrids
1. Provide soil characteristics and properties at two standard soil depths using [``isda_data``](https://github.com/EiA2030/source_data/blob/main/R/isda_download.R) function, which fetches data from the Cloud Optimized Geotiff (COG) of [OpenLand.org](https://openlandmap.org/) sources. Use the ID of the parameter selected from the [sources available](#Sources-available). Example of total nitrogen at 0 - 20 cm for a region in Kenya.
    isda_data(par = "log.n_tot_ncs_m_30m", depth = "0..20cm", xmin = 37.0, ymin = -0.9, xmax = 37.2, ymax = -0.7)
2. Access SoilGrids (?)
    
#### Google Earth Engine Catalog
Google Earth Engine's public data catalog includes a variety of standard Earth science datasets. You can import these datasets into your script environment and start analyzing data using Google's computing resources. Results can then be exported and used on premises. Using the [``rgee`` R package](https://r-spatial.github.io/rgee/index.html) we can interact with Google Earth Engine APIs and get access to a large variety of spatio-temporal datasets including: CHIRPS, Landsat, and many others.
Using [``daily_data_gee.R``](https://github.com/EiA2030/source_data/blob/main/R/daily_data_gee.R) and [``extract_daily_data_gee.R``](https://github.com/EiA2030/source_data/blob/main/R/extract_daily_data_gee.R) we can export results as a ``FeatureCollection`` in GeoJSON format. For example:
1. Access CHIRPS data for precipitation information between 2018 and 2019 in Malawi:
    ``daily.IC(imcol = "UCSB-CHG/CHIRPS/DAILY", band = "precipitation", sdate = "2018-01-01", edate = "2019-12-31", xmin = 34.8145177, ymin = -15.3265231, xmax = 35.3005743, ymax = -14.77034)``
2. Extract that precipitation into an operable table with dates, geometries (coordinates) and the variable of interest (in his example, precipitation).
    ``zonalStats(prec, params, xmin = 34.8145177, ymin = -15.3265231, xmax = 35.3005743, ymax = -14.77034)``
3. Export results:
    ``ee_table_to_gcs(x, description = "export weather data", bucket = 'your_GCS_bucket', fileNamePrefix = "points_x_", fileFormat = "GeoJSON")$start()``
    ``ee_monitoring(eeTaskList = T)``
...