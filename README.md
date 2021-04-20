# Sourcing Available Data

Gather available data and make decisions on the need for new data. This involves standardising data collection methods from different sources. The data collection approaches will be used to satisfy data needs for for all use cases as well as the next phase of EiA. This stage also involves evaluation of available  data for suitability for use. Where data is insufficient in terms of quantity and quality, recommendations will be made for collection of additional data.

|   | **Climatic/Meteorology**          | Source             | Platform               | Tools                 |
|---|-----------------------------------|--------------------|------------------------|-----------------------|
|   |                                   |                    |                        |                       |
| 1 | Precipitation                     | GEE                | GEE                    | daily_data_gee.R      |
| 2 | Solar Net Radiation               | GEE/NASA POWER     | GEE/NASA POWER         | nasapower_download.R  |
| 3 | Temperature                       | GEE/NASA POWER     | GEE/NASA POWER         | nasapower_download.R  |
| 4 | ...                               | ...                | ...                    | ...                   |

|   | **Soil**                          | Source             | Platform               | Tools                 |
|---|-----------------------------------|--------------------|------------------------|-----------------------|
|   |                                   |                    |                        |                       |
| 1 | N                                 | iSDA/SoilGrids     | GEE/R                  | daily_data_gee.R      |
| 2 | Bulk Density                      | iSDA/SoilGrids     | GEE/R                  | nasapower_download.R  |
| 3 | P                                 | iSDA/SoilGrids     | GEE/R                  | nasapower_download.R  |
| 4 | ...                               | ...                | ...                    | ...                   |

|   | **Crop Yield**                    | Source             | Platform               | Tools                 |
|---|-----------------------------------|--------------------|------------------------|-----------------------|
|   |                                   |                    |                        |                       |
| 1 |  ?                                | GARDIAN            | CG Labs                |                       |
| 2 |  ?                                | GARDIAN            | CG Labs                |                       |
| 3 |  ?                                | GARDIAN            | CG Labs                |                       |
| 4 | ...                               | ...                | ...                    | ...                   |

...