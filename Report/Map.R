pacman::p_load(
    dplyr,
    ggplot2,
    gridExtra,
    htmlwidgets,
    webshot2,
    mapview,
    magick,
    pagedown,
    readr,
    htmltools,
    leaflet,
    sf,
    randomcoloR,
    janitor,
    scales,
    sjmisc,
    htmlwidgets
  )

# Load data -------------------------------------------------------------------

wp_census <-
  read_rds(
    file.path(
      path_box,
      "Data/WaterPointCensus/DataSets/Spatial",
      "wp-gps-constructed.rds"
    )
  ) %>%
  mutate(
    icon_type = case_when(
      intervention_type == "DSW" ~ "dsw",
      intervention_type == "ILC water point" ~ "ilc",
      intervention_type == "ILC water collection point" ~ "ilc",
    ),
    label = paste(
      "Name:", wp_name, "<br>",
      "WP ID:", wp_id_c, wp_id, "<br>",
      "EA ID:", ea_id, "<br>",
      "Source type:", sourcetype, "<br>",
      "Functioning:", wp_func, "<br>",
      "Village:", village_id, "<br>",
      "District:", district_id
    ),
    label = lapply(label, htmltools::HTML)
  )

hh_census <-
  read_rds(
    file.path(
      path_box,
      "Data/HouseholdCensus/DataSets/Spatial",
      "hh-census-constructed.rds"
    )
  ) %>%
  mutate(
    label = paste(
      "HH ID:", household_id, "<br>",
      "Village:", village_id, "<br>",
      "District:", district_id
    ),
    label = lapply(label, htmltools::HTML)
  )

villages <-
  read_rds(
    file.path(
      path_box,
      "Data/VillageBoundary",
      "village-boundaries.rds"
    )
  ) 

ea_wpt <-
  bind_rows(
    read_rds(
      file.path(
        path_box,
        "Data/EvidenceAction/Spatial",
        "ea-uganda-wp-sf.rds"
      )
    ),
    read_rds(
      file.path(
        path_box,
        "Data/EvidenceAction/Spatial",
        "ea-malawi-wp-sf.rds"
      )
    )
  ) %>%
  mutate(
    label = paste(
      "EA ID:", wpt_id, "<br>",
      "Source type:", sourcetype, "<br>",
      "Intervention:", program, "<br>",
      "Village:", villageid, "<br>",
      "District:", districtid
    ) ,
    label = lapply(label, htmltools::HTML)
  )
  
ea_wcp <-
  bind_rows(
    read_rds(
      file.path(
        path_box,
        "Data/EvidenceAction/Spatial",
        "ea-uganda-wcp-sf.rds"
      ) 
    ),
    read_rds(
      file.path(
        path_box,
        "Data/EvidenceAction/Spatial",
        "ea-malawi-wcp-sf.rds"
      )
    ) %>%
    mutate(
      across(
        c(wpt_villageid, wcp_villageid),
        ~ as.character(.)
      )
    )
  ) %>%
  mutate(
    label = paste(
      "EA ID:", wcp_id, "<br>",
      "Intervention: ILC water collection point<br>",
      "Village:", wcp_villageid, "<br>",
      "District:", districtid
    ) ,
    label = lapply(label, htmltools::HTML)
  )

# Settings --------------------------------------------------------------------

## Icons for type of EvAc intervention ----------------------------------------
icon_list <- iconList(
  wcp = makeIcon(
    iconUrl    = 
      here(
        path_box,
        "Map",
        "icons",
        "icon_pipe.svg"
      ),
    iconWidth  = 8,
    iconHeight = 8,
    iconAnchorX = 4,
    iconAnchorY = 4
  ),
  ilc = makeIcon(
    iconUrl = 
      here(
        path_box,
        "Map",
        "icons",
        "icon_tank.svg"
      ),
    iconWidth  = 16,
    iconHeight = 16,
    iconAnchorX = 8,
    iconAnchorY = 8
  ),
  dsw = makeIcon(
    iconUrl    =
      here(
        path_box,
        "Map",
        "icons",
        "icon_waterdrop.svg"
      ),
    iconWidth  = 8,
    iconHeight = 8,
    iconAnchorX = 4,
    iconAnchorY = 4
  )
)

## Actual map ------------------------------------------------------------------

map <-
  leaflet() %>%
  addTiles(options = tileOptions(opacity = 0.95)) %>%
  addPolygons(
    data =  villages,
    opacity = .5,
    color = "orange"
  ) %>%
  # If there are no DSW water points in the village, the map will throw an error.
  # Comment these lines out to run ita
  addCircleMarkers(
    data = ea_wpt %>% dplyr::filter(program == "DSW"),
    radius = 11,
    stroke = FALSE,
    color = "darkblue",
    fillOpacity = 1,
    label = ~label
  ) %>%
  addCircleMarkers(
    data = ea_wcp,
    radius = 11,
    stroke = FALSE,
    color = "blue",
    fillOpacity = 1,
    label = ~label
  ) %>%
  addCircleMarkers(
    data = ea_wpt %>% dplyr::filter(program == "ILC"),
    radius = 11,
    color = "blue",
    fillOpacity = 1,
    label = ~label
  ) %>%
  addCircleMarkers(
    data = wp_census,
    radius = 8, 
    color = "lightblue",
    fillOpacity = 1,
    label = ~label
  ) %>%
  addMarkers(
    data = wp_census %>% dplyr::filter(intervention_type == "DSW"),
    icon = icon_list$dsw
  ) %>%
  addMarkers(
    data = wp_census %>% dplyr::filter(intervention_type == "ILC water point"),
    icon = icon_list$ilc
  ) %>%
  addMarkers(
    data = wp_census %>% dplyr::filter(intervention_type == "ILC water collection point"),
    icon = icon_list$wcp
  ) %>%
  addCircleMarkers(
    data = hh_census,
    radius = 4, 
    color = "gray",
    fillOpacity = .8,
    stroke = FALSE,
    label = ~label
  ) %>%
  addLegend(
    position = "bottomright",
    colors = c("orange", "darkblue", "blue", "blue", "lightblue", "gray"),
    labels = c(
      "Village boundaries", 
      "DSW (from EvAc)",
      "ILC tank (from EvAc)",
      "ILC tap (from EvAc)",
      "Water point (from IPA)",
      "Household"
    ), 
    opacity = c(1, 1, 1, 0, 1, 1)
  )

saveWidget(map, file = "G:/Shared drives/DIL Shared Drive/DIL/Projects/Water/GW EA take-up/Deliverables/v2/Data/Map.html")
