hh_survey <-
  read_rds(
    file.path(
      path_box,
      "Data",
      "HouseholdSurvey",
      "DataSets",
      "Final",
      "hh-survey.rds"
    )
  ) %>%
  dplyr::filter(
    survey == "Household Survey"
  ) %>%
  mutate(wp_intervention = case_when(
    str_detect(wp_intervention_type, "ILC") ~ "ILC",
    wp_intervention_type == "DSW" ~ "DSW"
  )) %>%
  dplyr::filter(
    !is.na(wp_intervention),
    !(sample_group != "ILC" & wp_intervention == "ILC")
  ) 

hh_survey %>%
  group_by(country, sample_group, wp_intervention) %>%
  summarise(
    across(
      all_of(
        c("make_watersafe_2",
             "disctcr_02", "metertcr_02", "metertcr_01",
             "discfcr_02", "meterfcr_02", "meterfcr_01")),
      ~ mean(., na.rm = TRUE)
    )
  )

hh_survey <-
  read_rds(
    file.path(
      path_box,
      "Data",
      "HouseholdSurvey",
      "DataSets",
      "Final",
      "hh-survey.rds"
    )
  ) %>%
  mutate(wp_intervention = case_when(
    str_detect(wp_intervention_type, "ILC") ~ "ILC",
    wp_intervention_type == "DSW" ~ "DSW"
  )) %>%
  dplyr::filter(
    !is.na(wp_intervention),
    !(sample_group != "ILC" & wp_intervention == "ILC")
  ) 

hh_survey %>%
  group_by(country, sample_group, wp_intervention) %>%
  summarise(
    across(
      all_of(
        c("make_watersafe_2",
          "disctcr_02", "metertcr_02", "metertcr_01",
          "discfcr_02", "meterfcr_02", "meterfcr_01")),
      ~ mean(., na.rm = TRUE)
    )
  )
