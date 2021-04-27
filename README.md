# Sourcing Available Data

Gather available data and make decisions on the need for new data. This involves standardising data collection methods from different sources. The data collection approaches will be used to satisfy data needs for for all use cases as well as the next phase of EiA. This stage also involves evaluation of available  data for suitability for use. Where data is insufficient in terms of quantity and quality, recommendations will be made for collection of additional data.

|   | **Climatic/Meteorology**          | Source             | Platform               | Tools                 |
|---|-----------------------------------|--------------------|------------------------|-----------------------|
| 1 | Precipitation                     | GEE                | GEE                    | daily_data_gee.R      |
| 2 | Solar Net Radiation               | GEE/NASA POWER     | GEE/NASA POWER         | nasapower_download.R  |
| 3 | Temperature                       | GEE/NASA POWER     | GEE/NASA POWER         | nasapower_download.R  |
| 4 | ...                               | ...                | ...                    | ...                   |
| 5 | ...                               | ...                | ...                    | ...                   |
| 6 | ...                               | ...                | ...                    | ...                   |

|    | **Soil**                          | Source             | ID                     | Platform/Tools        |
|----|-----------------------------------|--------------------|------------------------|-----------------------|
| 1  | N total                           | iSDA/SoilGrids     | log.n_tot_ncs_m_30m    | isda_download.R       |
| 2  | Bulk density                      | iSDA/SoilGrids     | db_od_m_30m            | isda_download.R       |
| 3  | Phosphorous extractable           | iSDA/SoilGrids     | log.p_mehlich3_m_30m   | isda_download.R       |
| 4  | Bedrock depth                     | iSDA/SoilGrids     | bdr_m_30m              | isda_download.R       |
| 5  | Calcium extractable               | iSDA/SoilGrids     | log.ca_mehlich3_m_30m  | isda_download.R       |
| 6  | Carbon organic                    | iSDA/SoilGrids     | log.oc_m_30m           | isda_download.R       |
| 7  | Carbon total                      | iSDA/SoilGrids     | log.c_tot_m_30m        | isda_download.R       |
| 8  | CEC                               | iSDA/SoilGrids     | log.ecec.f_m_30m       | isda_download.R       |
| 9  | Clay content                      | iSDA/SoilGrids     | sol_clay_tot_psa_m_30m | isda_download.R       |
| 10 | ...                               | ...                | ...                    | ...                   |

|   | **Crop Yield**                    | Source             | Platform               | Tools                 |
|---|-----------------------------------|--------------------|------------------------|-----------------------|
| 1 |  ?                                | GARDIAN            | CG Labs                |                       |
| 2 |  ?                                | GARDIAN            | CG Labs                |                       |
| 3 |  ?                                | GARDIAN            | CG Labs                |                       |
| 4 | ...                               | ...                | ...                    | ...                   |

...