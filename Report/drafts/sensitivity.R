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


# Are chlorination rates different across countries and groups?

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

# Chlorination rates in Uganda are not different between Expansion and Footprint households

village <-
  hh_survey %>%
  group_by(
    wp_intervention, sample_group, village_id, country
  ) %>%
  summarise(
    disctcr_02 = mean(disctcr_02, na.rm = TRUE)
  )

feols(
  disctcr_02 ~ sample_group * country,
  data = village
)

feols(
  disctcr_02 ~ sample_group,
  data = village
)

feols(
  disctcr_02 ~ country,
  data = village
)

feols(
  disctcr_02 ~ wp_intervention,
  data = village
)



feols(
  disctcr_02 ~ wp_intervention | village_id,
  data = hh_survey %>% dplyr::filter(country == "Uganda"),
  cluster = ~ village_id
)

feols(
  disctcr_02 ~ sample_group,
  data = hh_survey %>% dplyr::filter(country == "Uganda"),
  cluster = ~ village_id
)

# Chlorination rates in Malawi are different between DSW and ILC

feols(
  disctcr_02 ~ wp_intervention | village_id,
  data = hh_survey %>% dplyr::filter(country == "Malawi"),
  cluster = ~ village_id
)

# Chlorination rates in Malawi are not different between Expansion and Footprint households

feols(
  disctcr_02 ~ sample_group,
  data = hh_survey %>% dplyr::filter(country == "Malawi", wp_intervention == "DSW"),
  cluster = ~ village_id
)


# Chlorination rates in Malawi are not different between Expansion and Footprint villages

feols(
  disctcr_02 ~ sample_group,
  data = hh_survey %>% dplyr::filter(wp_intervention == "DSW"),
  cluster = ~ village_id
)



# Calculate chlorination rates in different samples

self_report <-
  hh_survey %>%
  dplyr::filter(
    hh_dsw,
    sample_group != "ILC"
  ) 

raw <-
  hh_survey %>%
  dplyr::filter(
    wp_dsw,
    sample_group != "ILC"
  ) 

constructed <-
  hh_survey %>%
  dplyr::filter(
    wp_intervention == "DSW",
    sample_group != "ILC"
  ) 

dil <-
  hh_survey %>%
  dplyr::filter(
    wp_intervention == "DSW",
    sample_group != "ILC"
  ) %>%
  group_by(village_id) %>%
  dplyr::filter(n() > 1) %>%
  ungroup

list(
  self_report,
  raw,
  constructed,
  dil
) %>%
  map(
    . %>% 
      group_by(village_id) %>%
      summarise(
        average = mean(disctcr_02, na.rm = TRUE)
      ) %>%
      summarise(
        n = sum(!is.na(average)),
        average = mean(average, na.rm = TRUE)
      )
  ) %>%
  bind_rows



list(
  hh_survey %>%
    dplyr::filter(hh_dsw, country == "Uganda"),
  hh_survey %>%
    dplyr::filter(wp_dsw, country == "Uganda"),
  hh_survey %>%
    dplyr::filter(wp_intervention == "DSW", country == "Uganda")
) %>%
  map(
    ~ village_mean_ci(
      data = .x %>%
        group_by(village_id) %>%
        dplyr::filter(n() > 1) %>% 
        ungroup,
      outcomes = c("disctcr_02"),
      dummy = TRUE
    )
  ) %>%
  bind_rows %>%
  mutate(
    sample = c(
      "Self-report",
      "Raw enumerator report",
      "Enumerator report + map check against EvAc data"
    ),
    country = "Uganda",
    across(
      c(mean, lb, ub),
      ~ . * 100
    )
  ) %>%
  bind_rows(
    list(
      hh_survey %>%
        dplyr::filter(hh_dsw, country == "Malawi"),
      hh_survey %>%
        dplyr::filter(wp_dsw, country == "Malawi"),
      hh_survey %>%
        dplyr::filter(wp_intervention == "DSW", country == "Malawi")
    ) %>%
      map(
        ~ village_mean_ci(
          data = .x %>%
            group_by(village_id) %>%
            dplyr::filter(n() > 1) %>% 
            ungroup,
          outcomes = c("disctcr_02"),
          dummy = TRUE
        )
      ) %>%
      bind_rows %>%
      mutate(
        sample = c(
          "Self-report",
          "Raw enumerator report",
          "Enumerator report + map check against EvAc data"
        ),
        country = "Malawi",
        across(
          c(mean, lb, ub),
          ~ . * 100
        )
      )
  ) %>%
  ggplot(
    aes(
      y = sample,
      x = mean,
      xmin = lb,
      xmax = ub,
      color = sample
    )
  ) +
  facet_wrap(~ country, ncol = 1) +
  geom_point(size = 3) +
  geom_errorbar(width = .1, size = 1)+
  labs(
    x = "Percent of households that have at least 0.2 ppm TCR in drinking water",
    y = "Definition of presence of DSW in primary source of drinking water"
  ) +
  theme +
  theme(legend.position = "none") +
  scale_color_viridis_d() + 
  xlim(c(0, 35))
