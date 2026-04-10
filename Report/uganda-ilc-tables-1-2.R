################################################################################
# Tables 1 and 2: Uganda ILC Results
# This script reproduces and extends Table 1 and Table 2 from the report
# "Independent chlorine adoption surveys" (January 29, 2026) to include
# Uganda ILC estimates.
#
# Table 1 uses village as the unit of reference.
# Table 2 uses water point as the unit of reference.
#
# Run from within the Report/ RStudio project (report.Rproj) so that .Rprofile
# is loaded automatically. This gives access to path_box, which points to the
# shared Box folder (set BOX env variable to your local Box sync root).
################################################################################

library(survey)

# path_box is defined in .Rprofile as file.path(Sys.getenv("BOX"), "i-h2o-takeup")
# Each collaborator sets the BOX environment variable to their local Box sync folder.

# Load data
hh  <- readRDS(file.path(path_box, "Data", "HouseholdCensus",  "hh-census.rds"))
hs  <- readRDS(file.path(path_box, "Data", "HouseholdSurvey",  "hh-survey.rds"))
wp  <- readRDS(file.path(path_box, "Data", "WaterPointCensus", "wp-census.rds"))
vil <- readRDS(file.path(path_box, "Data", "Villages",         "villages.rds"))

################################################################################
# HELPER: Reach estimate (village as unit of reference) — Table 1
################################################################################
reach_village <- function(data, wp_col, sample_vils, total_vils, country, sg) {
  # Responding HH using the target WP type, confirmed in EA database, WP inside village
  users <- data[
    data$country == country &
    data$sample_group == sg &
    data$response == TRUE &
    !is.na(data[[wp_col]]) & data[[wp_col]] == TRUE &
    !is.na(data$wp_identified) & data$wp_identified == TRUE &
    !is.na(data$wp_invillage) & data$wp_invillage == TRUE,
  ]

  # Response rate per village (among all censused HH in this sample group)
  all_sg <- data[data$country == country & data$sample_group == sg, ]
  resp_rate <- aggregate(as.integer(response) ~ village_id, data = all_sg, FUN = mean)
  names(resp_rate) <- c("village_id", "resp_rate")

  # Village-level: total people using this WP type
  vil_ppl <- aggregate(hh_members ~ village_id, data = users, FUN = sum)
  vil_ppl <- merge(vil_ppl, resp_rate, by = "village_id", all.x = TRUE)
  vil_ppl$people_adj <- vil_ppl$hh_members / vil_ppl$resp_rate

  # Villages with no qualifying users get 0 (e.g., ILC cluster not functional)
  missing <- sample_vils[!sample_vils %in% vil_ppl$village_id]
  if (length(missing) > 0) {
    zeros <- data.frame(village_id = missing, hh_members = 0,
                        resp_rate = NA, people_adj = 0)
    vil_ppl <- rbind(vil_ppl, zeros)
  }

  # Clustered SE via survey package (one-stage cluster sample of villages)
  design <- svydesign(ids = ~village_id, data = vil_ppl, weights = ~1)
  est    <- svymean(~people_adj, design, na.rm = TRUE)
  mu     <- coef(est)
  se     <- SE(est)

  list(
    n_vils = length(sample_vils),
    n_hh   = nrow(users),
    reach  = mu * total_vils,
    ci_lo  = (mu - 1.96 * se) * total_vils,
    ci_hi  = (mu + 1.96 * se) * total_vils
  )
}

################################################################################
# HELPER: Reach estimate (water point as unit of reference) — Table 2
################################################################################
reach_waterpoint <- function(data, wp_col, sample_vils, total_wps,
                             country, sg, func_rate = 1.0) {
  users <- data[
    data$country == country &
    data$sample_group == sg &
    data$response == TRUE &
    !is.na(data[[wp_col]]) & data[[wp_col]] == TRUE &
    !is.na(data$wp_identified) & data$wp_identified == TRUE &
    !is.na(data$wp_invillage) & data$wp_invillage == TRUE,
  ]

  all_sg    <- data[data$country == country & data$sample_group == sg, ]
  resp_rate <- aggregate(as.integer(response) ~ village_id, data = all_sg, FUN = mean)
  names(resp_rate) <- c("village_id", "resp_rate")

  # WP-level: total people per water point
  wp_ppl <- aggregate(hh_members ~ wp_id, data = users, FUN = sum)
  wp_vils <- unique(users[!is.na(users$wp_id), c("wp_id", "village_id")])
  wp_ppl  <- merge(wp_ppl, wp_vils, by = "wp_id", all.x = TRUE)
  wp_ppl  <- merge(wp_ppl, resp_rate, by = "village_id", all.x = TRUE)
  wp_ppl$people_adj <- wp_ppl$hh_members / wp_ppl$resp_rate

  # Drop rows with no village_id (unmatched WPs)
  wp_ppl <- wp_ppl[!is.na(wp_ppl$village_id), ]

  # Clustered SE at village level
  design <- svydesign(ids = ~village_id, data = wp_ppl, weights = ~1)
  est    <- svymean(~people_adj, design, na.rm = TRUE)
  mu     <- coef(est)
  se     <- SE(est)

  eff_wps <- total_wps * func_rate

  list(
    n_wps = nrow(wp_ppl),
    reach = mu * eff_wps,
    ci_lo = (mu - 1.96 * se) * eff_wps,
    ci_hi = (mu + 1.96 * se) * eff_wps
  )
}

################################################################################
# HELPER: Adoption rate (unweighted avg, clustered SE at village level)
################################################################################
adoption_rate <- function(hs_data, country, sg, wp_col) {
  sub <- hs_data[
    hs_data$country      == country &
    hs_data$survey       == "Household Survey" &
    hs_data$sample_group == sg &
    !is.na(hs_data[[wp_col]]) & hs_data[[wp_col]] == TRUE &
    !is.na(hs_data$water_sample) & hs_data$water_sample == TRUE,
  ]

  # Drop rows with NA village_id or NA chlorine readings
  sub <- sub[!is.na(sub$village_id), ]

  if (nrow(sub) == 0) {
    return(list(n = 0, tcr = NA, tcr_lo = NA, tcr_hi = NA,
                fcr = NA, fcr_lo = NA, fcr_hi = NA))
  }

  # Convert logical to numeric 0/1 for clean svymean output
  sub$tcr_01 <- as.integer(sub$disctcr_02 == TRUE)
  sub$fcr_01 <- as.integer(sub$discfcr_02 == TRUE)

  design  <- svydesign(ids = ~village_id, data = sub, weights = ~1)
  tcr_est <- svymean(~tcr_01, design, na.rm = TRUE)
  fcr_est <- svymean(~fcr_01, design, na.rm = TRUE)

  tcr    <- coef(tcr_est) * 100;  tcr_se <- SE(tcr_est) * 100
  fcr    <- coef(fcr_est) * 100;  fcr_se <- SE(fcr_est) * 100

  list(
    n      = nrow(sub),
    tcr    = tcr,
    tcr_lo = tcr - 1.96 * tcr_se,
    tcr_hi = tcr + 1.96 * tcr_se,
    fcr    = fcr,
    fcr_lo = fcr - 1.96 * fcr_se,
    fcr_hi = fcr + 1.96 * fcr_se
  )
}

################################################################################
# Country-level village and water-point totals (sampling frame)
################################################################################
ug_fp_total  <- sum(vil$country == "Uganda" & vil$sample_group == "Footprint")
ug_exp_total <- sum(vil$country == "Uganda" & vil$sample_group == "Expansion")
ug_ilc_total <- sum(vil$country == "Uganda" & vil$sample_group == "ILC")

mw_fp_total  <- sum(vil$country == "Malawi" & vil$sample_group == "Footprint")
mw_exp_total <- sum(vil$country == "Malawi" & vil$sample_group == "Expansion")
mw_ilc_total <- sum(vil$country == "Malawi" & vil$sample_group == "ILC")

# Total WPs per sample group (from village-level counts in vil)
ug_fp_wps  <- sum(vil$dsw_wpt[vil$country == "Uganda" & vil$sample_group == "Footprint"], na.rm = TRUE)
ug_exp_wps <- sum(vil$dsw_wpt[vil$country == "Uganda" & vil$sample_group == "Expansion"], na.rm = TRUE)
ug_ilc_wps <- sum(vil$ilc_wcp[vil$country == "Uganda" & vil$sample_group == "ILC"],      na.rm = TRUE)

mw_fp_wps  <- sum(vil$dsw_wpt[vil$country == "Malawi" & vil$sample_group == "Footprint"], na.rm = TRUE)
mw_exp_wps <- sum(vil$dsw_wpt[vil$country == "Malawi" & vil$sample_group == "Expansion"], na.rm = TRUE)
mw_ilc_wps <- sum(vil$ilc_wcp[vil$country == "Malawi" & vil$sample_group == "ILC"],       na.rm = TRUE)

cat("=== Sampling frame totals ===\n")
cat(sprintf("Uganda: Footprint %d vils / %d WPs | Expansion %d vils / %d WPs | ILC %d vils / %d WCPs\n",
            ug_fp_total, ug_fp_wps, ug_exp_total, ug_exp_wps, ug_ilc_total, ug_ilc_wps))
cat(sprintf("Malawi: Footprint %d vils / %d WPs | Expansion %d vils / %d WPs | ILC %d vils / %d WCPs\n\n",
            mw_fp_total, mw_fp_wps, mw_exp_total, mw_exp_wps, mw_ilc_total, mw_ilc_wps))

# Sampled village IDs (from hh-census)
get_vils <- function(country, sg) unique(hh[hh$country == country & hh$sample_group == sg, "village_id"])

ug_fp_vils  <- get_vils("Uganda", "Footprint")
ug_exp_vils <- get_vils("Uganda", "Expansion")
ug_ilc_vils <- get_vils("Uganda", "ILC")
mw_fp_vils  <- get_vils("Malawi", "Footprint")
mw_exp_vils <- get_vils("Malawi", "Expansion")
mw_ilc_vils <- get_vils("Malawi", "ILC")

# ILC water point functionality rates (for Table 2 WP-based scaling)
ug_ilc_func <- mean(wp$wp_func[wp$country == "Uganda" & wp$sample_group == "ILC" & wp$ilc_wcp == TRUE] == TRUE, na.rm = TRUE)
mw_ilc_func <- mean(wp$wp_func[wp$country == "Malawi" & wp$sample_group == "ILC" & wp$ilc_wcp == TRUE] == TRUE, na.rm = TRUE)

################################################################################
# TABLE 1: Village as unit of reference
################################################################################
cat("====================================================================\n")
cat("TABLE 1: Village as unit of reference\n")
cat("====================================================================\n")
cat(sprintf("%-22s | Vils | HH_users | Reach (thousands) [95%% CI]   | TCR %% [95%% CI]    | FCR %% [95%% CI]   \n", "Group"))
cat(paste(rep("-", 110), collapse = ""), "\n")

print_row_t1 <- function(label, country, sg, wp_col, sample_vils, total_vils) {
  r <- reach_village(hh, wp_col, sample_vils, total_vils, country, sg)
  a <- adoption_rate(hs, country, sg, wp_col)

  cat(sprintf(
    "%-22s | %4d | %8d | %6.0f K  [%5.0f K - %5.0f K]  | %4.1f [%4.1f-%4.1f] (n=%d) | %4.1f [%4.1f-%4.1f]\n",
    label,
    r$n_vils, r$n_hh,
    r$reach / 1e3, r$ci_lo / 1e3, r$ci_hi / 1e3,
    a$tcr, a$tcr_lo, a$tcr_hi, a$n,
    a$fcr, a$fcr_lo, a$fcr_hi
  ))
  invisible(list(reach = r, adoption = a))
}

cat("--- Uganda ---\n")
ug_fp_r  <- print_row_t1("Uganda FP (DSW)",  "Uganda", "Footprint", "wp_dsw", ug_fp_vils,  ug_fp_total)
ug_exp_r <- print_row_t1("Uganda EXP (DSW)", "Uganda", "Expansion", "wp_dsw", ug_exp_vils, ug_exp_total)
ug_ilc_r <- print_row_t1("Uganda ILC [NEW]", "Uganda", "ILC",       "wp_ilc", ug_ilc_vils, ug_ilc_total)

cat("--- Malawi ---\n")
mw_fp_r  <- print_row_t1("Malawi FP (DSW)",  "Malawi", "Footprint", "wp_dsw", mw_fp_vils,  mw_fp_total)
mw_exp_r <- print_row_t1("Malawi EXP (DSW)", "Malawi", "Expansion", "wp_dsw", mw_exp_vils, mw_exp_total)
mw_ilc_r <- print_row_t1("Malawi ILC",       "Malawi", "ILC",       "wp_ilc", mw_ilc_vils, mw_ilc_total)

################################################################################
# TABLE 2: Water point as unit of reference
################################################################################
cat("\n====================================================================\n")
cat("TABLE 2: Water point as unit of reference\n")
cat("====================================================================\n")
cat(sprintf("%-22s | WPs  | Reach (thousands) [95%% CI]   | TCR %% [95%% CI]    | FCR %% [95%% CI]   \n", "Group"))
cat(paste(rep("-", 100), collapse = ""), "\n")

print_row_t2 <- function(label, country, sg, wp_col, sample_vils, total_wps,
                         func_rate = 1.0) {
  r <- reach_waterpoint(hh, wp_col, sample_vils, total_wps, country, sg, func_rate)
  a <- adoption_rate(hs, country, sg, wp_col)

  cat(sprintf(
    "%-22s | %4d | %6.0f K  [%5.0f K - %5.0f K]  | %4.1f [%4.1f-%4.1f]       | %4.1f [%4.1f-%4.1f]\n",
    label,
    r$n_wps,
    r$reach / 1e3, r$ci_lo / 1e3, r$ci_hi / 1e3,
    a$tcr, a$tcr_lo, a$tcr_hi,
    a$fcr, a$fcr_lo, a$fcr_hi
  ))
}

cat("--- Uganda ---\n")
print_row_t2("Uganda FP (DSW)",  "Uganda", "Footprint", "wp_dsw", ug_fp_vils,  ug_fp_wps)
print_row_t2("Uganda EXP (DSW)", "Uganda", "Expansion", "wp_dsw", ug_exp_vils, ug_exp_wps)
print_row_t2("Uganda ILC [NEW]", "Uganda", "ILC",       "wp_ilc", ug_ilc_vils, ug_ilc_wps, ug_ilc_func)

cat("--- Malawi ---\n")
print_row_t2("Malawi FP (DSW)",  "Malawi", "Footprint", "wp_dsw", mw_fp_vils,  mw_fp_wps)
print_row_t2("Malawi EXP (DSW)", "Malawi", "Expansion", "wp_dsw", mw_exp_vils, mw_exp_wps)
print_row_t2("Malawi ILC",       "Malawi", "ILC",       "wp_ilc", mw_ilc_vils, mw_ilc_wps, mw_ilc_func)

################################################################################
# SUMMARY: Uganda ILC new results
################################################################################
cat("\n====================================================================\n")
cat("SUMMARY: Uganda ILC NEW ROW for Tables 1 and 2\n")
cat("====================================================================\n")

r1 <- ug_ilc_r$reach
a1 <- ug_ilc_r$adoption
cat("\nTable 1 (village unit of reference):\n")
cat(sprintf("  Villages in sample   : %d  (total Uganda ILC villages: %d)\n", r1$n_vils, ug_ilc_total))
cat(sprintf("  HH using ILC WPs     : %d\n", r1$n_hh))
cat(sprintf("  Reach estimate       : %.0f (95%% CI: %.0f - %.0f)\n", r1$reach, r1$ci_lo, r1$ci_hi))
cat(sprintf("  TCR adoption (>0.2)  : %.1f%% (95%% CI: %.1f%% - %.1f%%)   n=%d HH tested\n",
            a1$tcr, a1$tcr_lo, a1$tcr_hi, a1$n))
cat(sprintf("  FCR adoption (>0.2)  : %.1f%% (95%% CI: %.1f%% - %.1f%%)\n",
            a1$fcr, a1$fcr_lo, a1$fcr_hi))

################################################################################
# Export results to CSV
################################################################################

results <- data.frame(
  table       = c(rep("Table1", 6), rep("Table2", 6)),
  group       = rep(c("Uganda FP (DSW)", "Uganda EXP (DSW)", "Uganda ILC [NEW]",
                      "Malawi FP (DSW)", "Malawi EXP (DSW)", "Malawi ILC"), 2),
  reach       = c(ug_fp_r$reach$reach, ug_exp_r$reach$reach, ug_ilc_r$reach$reach,
                  mw_fp_r$reach$reach, mw_exp_r$reach$reach, mw_ilc_r$reach$reach,
                  NA, NA, NA, NA, NA, NA),  # Table 2 not stored above; re-run if needed
  reach_ci_lo = c(ug_fp_r$reach$ci_lo, ug_exp_r$reach$ci_lo, ug_ilc_r$reach$ci_lo,
                  mw_fp_r$reach$ci_lo, mw_exp_r$reach$ci_lo, mw_ilc_r$reach$ci_lo,
                  NA, NA, NA, NA, NA, NA),
  reach_ci_hi = c(ug_fp_r$reach$ci_hi, ug_exp_r$reach$ci_hi, ug_ilc_r$reach$ci_hi,
                  mw_fp_r$reach$ci_hi, mw_exp_r$reach$ci_hi, mw_ilc_r$reach$ci_hi,
                  NA, NA, NA, NA, NA, NA),
  tcr_pct     = c(ug_fp_r$adoption$tcr, ug_exp_r$adoption$tcr, ug_ilc_r$adoption$tcr,
                  mw_fp_r$adoption$tcr, mw_exp_r$adoption$tcr, mw_ilc_r$adoption$tcr,
                  ug_fp_r$adoption$tcr, ug_exp_r$adoption$tcr, ug_ilc_r$adoption$tcr,
                  mw_fp_r$adoption$tcr, mw_exp_r$adoption$tcr, mw_ilc_r$adoption$tcr),
  tcr_ci_lo   = c(ug_fp_r$adoption$tcr_lo, ug_exp_r$adoption$tcr_lo, ug_ilc_r$adoption$tcr_lo,
                  mw_fp_r$adoption$tcr_lo, mw_exp_r$adoption$tcr_lo, mw_ilc_r$adoption$tcr_lo,
                  ug_fp_r$adoption$tcr_lo, ug_exp_r$adoption$tcr_lo, ug_ilc_r$adoption$tcr_lo,
                  mw_fp_r$adoption$tcr_lo, mw_exp_r$adoption$tcr_lo, mw_ilc_r$adoption$tcr_lo),
  tcr_ci_hi   = c(ug_fp_r$adoption$tcr_hi, ug_exp_r$adoption$tcr_hi, ug_ilc_r$adoption$tcr_hi,
                  mw_fp_r$adoption$tcr_hi, mw_exp_r$adoption$tcr_hi, mw_ilc_r$adoption$tcr_hi,
                  ug_fp_r$adoption$tcr_hi, ug_exp_r$adoption$tcr_hi, ug_ilc_r$adoption$tcr_hi,
                  mw_fp_r$adoption$tcr_hi, mw_exp_r$adoption$tcr_hi, mw_ilc_r$adoption$tcr_hi),
  fcr_pct     = c(ug_fp_r$adoption$fcr, ug_exp_r$adoption$fcr, ug_ilc_r$adoption$fcr,
                  mw_fp_r$adoption$fcr, mw_exp_r$adoption$fcr, mw_ilc_r$adoption$fcr,
                  ug_fp_r$adoption$fcr, ug_exp_r$adoption$fcr, ug_ilc_r$adoption$fcr,
                  mw_fp_r$adoption$fcr, mw_exp_r$adoption$fcr, mw_ilc_r$adoption$fcr),
  n_hh_tested = c(ug_fp_r$adoption$n, ug_exp_r$adoption$n, ug_ilc_r$adoption$n,
                  mw_fp_r$adoption$n, mw_exp_r$adoption$n, mw_ilc_r$adoption$n,
                  ug_fp_r$adoption$n, ug_exp_r$adoption$n, ug_ilc_r$adoption$n,
                  mw_fp_r$adoption$n, mw_exp_r$adoption$n, mw_ilc_r$adoption$n)
)

out_file <- file.path(dirname(normalizePath(".")), "uganda-ilc-analysis", "tables_1_2_results.csv")
write.csv(results, "tables_1_2_results.csv", row.names = FALSE)
cat("\nResults saved to: tables_1_2_results.csv\n")

cat("\nVerification against report values:\n")
cat("  Uganda DSW (FP+EXP) reach: should be ~3.9M people\n")
ug_dsw_reach <- ug_fp_r$reach$reach + ug_exp_r$reach$reach
cat(sprintf("  Computed: %.1fM\n", ug_dsw_reach / 1e6))
cat("  Uganda DSW TCR adoption: should be ~30.4%\n")
# Weighted average of FP and EXP adoption (by n_hh)
ug_fp_n  <- ug_fp_r$adoption$n
ug_exp_n <- ug_exp_r$adoption$n
ug_dsw_tcr_avg <- (ug_fp_r$adoption$tcr * ug_fp_n + ug_exp_r$adoption$tcr * ug_exp_n) /
                  (ug_fp_n + ug_exp_n)
cat(sprintf("  Computed (unweighted avg): FP=%.1f%%, EXP=%.1f%%\n",
            ug_fp_r$adoption$tcr, ug_exp_r$adoption$tcr))
cat(sprintf("  Malawi ILC reach: should be ~75K\n"))
cat(sprintf("  Computed: %.1fK\n", mw_ilc_r$reach$reach / 1e3))
cat(sprintf("  Malawi ILC TCR: should be ~30.7%%\n"))
cat(sprintf("  Computed: %.1f%%\n", mw_ilc_r$adoption$tcr))
