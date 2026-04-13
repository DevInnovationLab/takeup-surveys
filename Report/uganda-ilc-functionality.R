################################################################################
# ILC Functionality Table — Both Countries (Uganda + Malawi)
# Extends 7-ilc-functionality.Rmd to include Uganda ILC alongside Malawi.
#
# Run from within Report/ RStudio project (report.Rproj) so .Rprofile loads
# path_box automatically.
################################################################################

library(tidyverse)
library(knitr)
library(kableExtra)

# Load water point census
wp_census <- readRDS(file.path(path_box, "Data", "WaterPointCensus", "wp-census.rds"))

################################################################################
# Helper: build functionality row for one country
################################################################################
func_row <- function(data, country_label) {

  # ILC water points (device locations)
  wpts <- data[data$ilc_wp == TRUE & !is.na(data$ilc_wp), ]

  # ILC water collection points
  wcps <- data[data$ilc_wcp == TRUE & !is.na(data$ilc_wcp), ]

  # Closest and furthest WCPs tested for chlorine
  closest <- wcps[wcps$ilc_closest == TRUE & !is.na(wcps$ilc_closest), ]
  furthest <- wcps[wcps$ilc_furthest == TRUE & !is.na(wcps$ilc_furthest), ]
  other    <- wcps[wcps$ilc_furthest == TRUE & !is.na(wcps$ilc_furthest), ]  # furthest = "other"

  list(
    country = country_label,

    # --- Water points (ILC device locations) ---
    wp_n              = nrow(wpts),
    wp_communal       = sum(wpts$wp_drink, na.rm = TRUE),
    wp_func_obs       = sum(!is.na(wpts$wp_func)),
    wp_func           = sum(wpts$wp_func, na.rm = TRUE),
    wp_func_pct       = mean(wpts$wp_func, na.rm = TRUE),
    wp_devfunc_obs    = sum(!is.na(wpts$ilc_devicefunc)),
    wp_devfunc        = sum(wpts$ilc_devicefunc, na.rm = TRUE),
    wp_devfunc_pct    = mean(wpts$ilc_devicefunc, na.rm = TRUE),

    # --- Water collection points ---
    wcp_n             = nrow(wcps),
    wcp_communal      = sum(wcps$wp_drink, na.rm = TRUE),
    wcp_func_obs      = sum(!is.na(wcps$wp_func)),
    wcp_func          = sum(wcps$wp_func, na.rm = TRUE),
    wcp_func_pct      = mean(wcps$wp_func, na.rm = TRUE),

    # --- Chlorine at closest WCPs ---
    cl_closest_n      = sum(!is.na(closest$disctcr_02)),
    cl_closest_tcr    = mean(closest$disctcr_02, na.rm = TRUE),
    cl_closest_fcr    = mean(closest$discfcr_02, na.rm = TRUE),

    # --- Chlorine at furthest/other WCPs ---
    cl_other_n        = sum(!is.na(other$disctcr_02)),
    cl_other_tcr      = mean(other$disctcr_02, na.rm = TRUE),
    cl_other_fcr      = mean(other$discfcr_02, na.rm = TRUE),

    # --- Chlorine across all WCPs ---
    cl_all_n          = sum(!is.na(wcps$disctcr_02)),
    cl_all_tcr        = mean(wcps$disctcr_02, na.rm = TRUE),
    cl_all_fcr        = mean(wcps$discfcr_02, na.rm = TRUE)
  )
}

# Build rows for each country
mw_data <- wp_census[wp_census$country == "Malawi" & wp_census$sample_group == "ILC", ]
ug_data <- wp_census[wp_census$country == "Uganda" & wp_census$sample_group == "ILC", ]

mw <- func_row(mw_data, "Malawi")
ug <- func_row(ug_data, "Uganda")

pct <- function(x) paste0("(", round(x * 100, 1), "%)")

################################################################################
# TABLE 1: Functionality indicators
################################################################################
cat("====================================================================\n")
cat("ILC Functionality Indicators — Both Countries\n")
cat("====================================================================\n\n")

func_table <- tibble(
  ` `                          = c("Malawi", "Uganda"),
  `N (WPs)`                   = c(mw$wp_n,   ug$wp_n),
  `Communal (WPs)`            = c(mw$wp_communal, ug$wp_communal),
  `Functional WPs`            = c(
    paste(mw$wp_func, pct(mw$wp_func_pct)),
    paste(ug$wp_func, pct(ug$wp_func_pct))
  ),
  `ILC device functional`     = c(
    paste(mw$wp_devfunc, pct(mw$wp_devfunc_pct)),
    paste(ug$wp_devfunc, pct(ug$wp_devfunc_pct))
  ),
  `N (WCPs)`                  = c(mw$wcp_n,  ug$wcp_n),
  `Communal (WCPs)`           = c(mw$wcp_communal, ug$wcp_communal),
  `Functional WCPs`           = c(
    paste(mw$wcp_func, pct(mw$wcp_func_pct)),
    paste(ug$wcp_func, pct(ug$wcp_func_pct))
  )
)

print(func_table)

################################################################################
# TABLE 2: Chlorine detection at WCPs
################################################################################
cat("\n====================================================================\n")
cat("Chlorine Detection at ILC Water Collection Points — Both Countries\n")
cat("====================================================================\n\n")

cl_table <- tibble(
  ` `                         = c("Malawi", "Uganda"),

  # All WCPs
  `N (all)`                   = c(mw$cl_all_n,  ug$cl_all_n),
  `TCR ≥0.2 (all)`            = c(pct(mw$cl_all_tcr),  pct(ug$cl_all_tcr)),
  `FCR ≥0.2 (all)`            = c(pct(mw$cl_all_fcr),  pct(ug$cl_all_fcr)),

  # Closest WCPs
  `N (closest)`               = c(mw$cl_closest_n,  ug$cl_closest_n),
  `TCR ≥0.2 (closest)`        = c(pct(mw$cl_closest_tcr),  pct(ug$cl_closest_tcr)),
  `FCR ≥0.2 (closest)`        = c(pct(mw$cl_closest_fcr),  pct(ug$cl_closest_fcr)),

  # Other/furthest WCPs
  `N (other)`                 = c(mw$cl_other_n,  ug$cl_other_n),
  `TCR ≥0.2 (other)`          = c(pct(mw$cl_other_tcr),  pct(ug$cl_other_tcr)),
  `FCR ≥0.2 (other)`          = c(pct(mw$cl_other_fcr),  pct(ug$cl_other_fcr))
)

print(cl_table)

cat("\nNotes:\n")
cat("- WPs  = ILC water points (where the ILC device is installed)\n")
cat("- WCPs = ILC water collection points (taps connected to the ILC system)\n")
cat("- 'Closest'/'Other' refers to proximity to the ILC device tank within a cluster\n")
cat("- Uganda ILC was excluded from the original report; these are new estimates\n")
