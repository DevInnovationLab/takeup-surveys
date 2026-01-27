source("renv/activate.R")
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
    legend.position = "none"
  )

# Inputs -----------------------------------------------------------------------

test_vars <-
  c(
    "discfcr_02", "disctcr_02", 
    "meterfcr_02", "metertcr_02",
    "meterfcr_01", "metertcr_01"
  )

# Functions --------------------------------------------------------------------

design <- function(data, ...) {
  svydesign(
    id = ~ village_id,
    data = data, 
    strata = ~ country + sample_group,
    nest = TRUE,
    ...
  )
}

mean_ci <- function(var, data, dummy = TRUE, ...) {
  
  design <- design(data, ...)
  
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

total_ci <-
  function(data, var, ...) {
    
    design <- design(data, ...)
    
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
      bind_cols(total, total_ci) %>%
      mutate(outcome = var) %>%
      select(outcome, everything())
    
    rownames(all) <- NULL
  
    return(all)
    
  }
  
kable_by_group <- function(x, ...) {
  kable(
    x,
    format = "html",
    format.args = list(big.mark = ",", decimal.mark = "."),
    ...
  ) %>%
    kable_paper("striped", full_width = TRUE) %>%
    pack_rows("Malawi", 1, 4) %>%
    pack_rows("Uganda", 5, 6)
  
}
  
kable_by_country <- function(x, ...) {
  kable(
    x,
    format = "html",
    format.args = list(big.mark = ",", decimal.mark = "."),
    ...
  ) %>%
    kable_paper("striped", full_width = TRUE) %>%
    pack_rows("Malawi", 1, 2) %>%
    pack_rows("Uganda", 3, 3)
  
}

latex_table <- function(table, numbered_footnote = NULL, single_footnote = NULL, ...) {
  table %>%
    kable(
      format = "latex",
      format.args = list(big.mark = ",", decimal.mark = "."),
      booktabs = T,
      ...
    ) %>%
    kable_styling(latex_options = c("scale_down", "HOLD_position")) %>%
    footnote(
      number = numbered_footnote,
      general = single_footnote,
      threeparttable = TRUE,
      footnote_as_chunk = FALSE
    )
}

html_table <- function(table, numbered_footnote = NULL, single_footnote = NULL, ...) {
  table %>%
    kable(
      format = "html",
      format.args = list(big.mark = ",", decimal.mark = "."),
      ...
    ) %>%
    footnote(
      number = numbered_footnote,
      general = single_footnote,
      threeparttable = TRUE,
      footnote_as_chunk = FALSE
    ) %>%
    kable_paper("striped", full_width = TRUE)
}

pack_intervention_se <- function(kable) {
  kable %>%
    pack_rows("Malawi", 1, 4) %>%
    pack_rows("Uganda", 5, 6)
}

pack_intervention <- function(kable) {
  kable %>%
    pack_rows("Malawi", 1, 2) %>%
    pack_rows("Uganda", 3, 3)
}

pack_sample_se <- function(kable) {
  kable %>%
    pack_rows("Malawi", 1, 8) %>%
    pack_rows("Uganda", 9, 12)
}

pack_sample <- function(kable) {
  kable %>%
    pack_rows("Malawi", 1, 3) %>%
    pack_rows("Uganda", 4, 5)
}
