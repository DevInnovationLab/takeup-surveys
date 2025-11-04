pacman::p_load(
  sf,
  tidyverse,
  viridis,
  fixest,
  janitor,
  broom,
  car,
  modelsummary,
  survey
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
  dplyr::filter(
    survey == "Household Survey"
  )


hh_survey %>%
  dplyr::filter(
    country == "Malawi", 
    sample_group == "ILC",
    wp_intervention == "ILC"
  ) %>%
  group_by(ilc_wp) %>%
  summarise(
    av = mean(disctcr_02, na.rm = TRUE),
    sd = sd(disctcr_02, na.rm = TRUE),
    n = sum(!is.na(disctcr_02)),
    lb = av - 1.96 * (sd/sqrt(n)),
    ub = av + 1.96 * (sd/sqrt(n))
  ) %>%
  ggplot(
    aes(
      x = av,
      xmin = lb,
      xmax = ub,
      y = ilc_wp,
      color = ilc_wp
    )
  ) +
  geom_point(size = 2) +
  geom_errorbar(size = 1, width = .1) +
  scale_color_viridis_d() +
  theme

# Restricing to water points where the ILC is working

hh_survey %>%
  dplyr::filter(
    wp_func, 
    country == "Malawi", 
    sample_group == "ILC",
    wp_intervention == "ILC"
  ) %>%
  group_by(ilc_wp) %>%
  summarise(
    av = mean(disctcr_02, na.rm = TRUE),
    sd = sd(disctcr_02, na.rm = TRUE),
    n = sum(!is.na(disctcr_02)),
    lb = av - 1.96 * (sd/sqrt(n)),
    ub = av + 1.96 * (sd/sqrt(n))
  ) %>%
  ggplot(
    aes(
      x = av,
      xmin = lb,
      xmax = ub,
      y = ilc_wp,
      color = ilc_wp
    )
  ) +
  geom_point(size = 2) +
  geom_errorbar(size = 1, width = .1) +
  scale_color_viridis_d() +
  theme
