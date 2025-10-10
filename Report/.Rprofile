# File paths -------------------------------------------------------------------

path_box <- file.path(Sys.getenv("BOX"),"i-h2o-takeup")
path_git <- file.path(Sys.getenv("GITHUB"),"i-h2o-takeup")

# Load functions ---------------------------------------------------------------

library(tidyverse)

map(
  list.files(
    file.path(path_git, "code/funs"),
    full.names = T
  ), 
  source
)

# Table formatting -------------------------------------------------------------

library(kableExtra)

kable_format <-
  list(decimal.mark = ".", big.mark = ",")

table_largenumber <- function(x) {
  format(x, big.mark = ",", nsmall = 0)
}

table_se <- function(x) {
  if_else(
    !is.na(x),
    paste0("(", x, ")"),
    x
  )
}

table_ci <- function(lb, ub) {
  paste0("(", lb,", ", ub, ")")
}

# Graph formatting -------------------------------------------------------------

theme <-
  theme_minimal() +
  theme(
    strip.background = element_rect(
      fill = "gray90",
      color = "gray90"
    ),
    plot.title = element_text(hjust = 0.5),
    text = element_text(size = 11, family = "Times"),
    plot.caption = element_text(
      hjust = 0,
      size = 10,
      color = "gray40"
    ),
    legend.position = "bottom"
  )

# Inputs -----------------------------------------------------------------------

weights <-
  tribble(
    ~ country, ~ sample_group, ~ pop,
    "Uganda", "ILC", 651, 
    "Uganda", "Footprint", 3171,
    "Uganda", "Expansion", 4012,
    "Malawi", "Footprint", 1161,
    "Malawi", "Expansion", 4812, 
    "Malawi", "ILC", 633
  )

test_vars <-
  c(
    "discfcr_02", "disctcr_02", 
    "meterfcr_02", "metertcr_02",
    "meterfcr_01", "metertcr_01"
  )


# Functions --------------------------------------------------------------------

mean_ci <- function(data, var, dummy) {
  design <- 
    svydesign(
      id = ~ household_id,      # PSU (here: villages)
      strata = ~ village_id,    # stratification
      data = data,
      nest = TRUE
    )
  
  formula <- paste("~", var) %>% as.formula()
  
  mean <- 
    svymean(formula, na.rm = TRUE, design) %>%
    as.data.frame() %>% 
    set_names(c("mean", "se"))
  
  mean_ci <-
    confint(
      svymean(formula, na.rm = TRUE, design)
    ) %>% 
    as.data.frame() %>%
    set_names("lb", "ub")
  
  result <-
    bind_cols(mean, mean_ci) %>%
    mutate(outcome = var) %>%
    select(outcome, everything())
  
  if (dummy) {
    result <-
      result %>%
      dplyr::filter(str_detect(rownames(.), "TRUE"))
  }
  
  rownames(result) <- NULL
  
  result
}

village_mean_ci <-
  function(data, dummy = TRUE, outcomes) {
    map(
      outcomes,
      ~ mean_ci(data, var = ., dummy)
    ) %>%
      bind_rows
  }


total_cis <-
  function(data, var) {
    
    design <- 
      svydesign(
        id = ~ village_id,       # PSU (here: villages)
        strata = ~ sample_group, # stratification
        weights = ~ weight,
        data = data,
        nest = TRUE
      )
    
    formula <- paste("~", var) %>% as.formula()
    
    total <- 
      svytotal(formula, na.rm = TRUE, design) %>%
      as.data.frame() %>% 
      set_names(c("total", "se"))
    
    total_ci <-
      confint(
        svytotal(formula, na.rm = TRUE, design)
      ) %>% 
      as.data.frame() %>%
      set_names("lb", "ub")
    
    all <- 
      bind_cols(total, total_ci)
    
    rownames(all) <- NULL
  
    return(all)
    
  }
  
