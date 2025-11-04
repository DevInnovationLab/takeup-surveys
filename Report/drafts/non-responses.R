hhc <-
  read_rds(
    file.path(
      path_box,
      "Data",
      "HouseholdCensus",
      "DataSets",
      "Constructed",
      "hh-census-constructed.rds"
    )
  )

hhc %>% 
  dplyr::filter(country == "Uganda") %>%
  tabyl(district_id, response) %>%
  adorn_percentages()
  tabyl(visit_outcome)

lm(
  response ~ team,
  data = hhc %>%
    dplyr::filter(country == "Uganda")
) %>% summary

feols(
  response ~ 1 | team,
  data = hhc %>%
    dplyr::filter(country == "Uganda")
) %>% summary

feols(
  response ~ 1 | village_id,
  data = hhc %>%
    dplyr::filter(country == "Uganda")
) %>% summary

feols(
  response ~ 1 | enumerator_id,
  data = hhc %>%
    dplyr::filter(country == "Uganda")
) %>% summary

feols(
  response ~ 1 | district_id,
  data = hhc %>%
    dplyr::filter(country == "Uganda")
) %>% summary

feols(
  response ~ 1 | village_id + enumerator_id,
  data = hhc %>%
    dplyr::filter(country == "Uganda")
) %>% summary

feols(
  response ~ district_id,
  data = hhc %>%
    dplyr::filter(country == "Uganda")
) %>% summary

lm(
  response ~ enumerator_id,
  data = hhc %>%
    dplyr::filter(country == "Uganda")
) %>% summary

hhc %>% 
  dplyr::filter(country == "Malawi") %>%
  tabyl(district_id, response) %>%
  adorn_percentages()
  tabyl(visit_outcome)
