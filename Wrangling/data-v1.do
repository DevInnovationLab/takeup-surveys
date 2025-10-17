use "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\WaterPointCensus\DataSets\Final\wp-census.dta" , clear
iecodebook apply using "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\WaterPointCensus\DataSets\Final\wp-census.xlsx", drop

order country district district_id sample_group village village_id sample_group sample wp_id ilc_cluster_id ea_* dsw ilc_wp ilc_wcp ilc intervention  spotcheck_enum cw_enum meter_enum cw_nocl_enum meter_nocl_enum wp_multicompound wp_drink wp_func wp_func wp_func_last wp_eligible wp_turbidity wp_pay wp_cost wp_cost_period sourcetype disp_tank_present disp_casing_present disp_pvc_pole_present jc_valve jc_chlorine jc_mllost jc_mldispensed meter* disc* promoter_surveyed date

iesave "G:\Shared drives\DIL Shared Drive\DIL\Projects\Water\GW EA take-up\Deliverables\v2\wp-census.dta", id(wp_id) version(15) userinfo report(csv replace)  replace


use "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\PromoterSurvey\DataSets\Final\pm-survey.dta" , clear

iecodebook apply using "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\PromoterSurvey\DataSets\Final\pm-survey.xlsx", drop

iesave "G:\Shared drives\DIL Shared Drive\DIL\Projects\Water\GW EA take-up\Deliverables\v1\pm-survey.dta", idvars(wp_id promoter) version(15) userinfo report(csv replace)  replace


use "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\HouseholdCensus\DataSets\Final\hh-census.dta" , clear

iecodebook apply using "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\HouseholdCensus\DataSets\Final\hh-census.xlsx", drop

order country district district_id village village_id ea_program_vil sample_group sample household_id inclusion response wp_id wp_intervention_type ilc_cluster_id hhh_gender hhh_age hhh_educ hh_hhsincompound hh_members hh_adults hh_males hh_females hh_pregnant hh_under5n hh_under5yn hh_under2n hh_under2yn wp_freq wp_secweek wp_secweekno wp_count_pastmonth wp_identified wp_invillage hh_dsw hh_ilc wp_func wp_sourcetype wp_turbidity wp_pay wp_dsw_valve wp_dsw_chlorine wp_dsw_dose wp_meterfcr wp_metertcr wp_discfcr wp_disctcr wp_meterfcr_01 wp_metertcr_01 wp_meterfcr_un_01 wp_metertcr_un_01 wp_meterfcr_02 wp_metertcr_02 wp_discfcr_02 wp_disctcr_02 wp_meterfcr_un_02 wp_metertcr_un_02 wp_discfcr_un_02 wp_disctcr_un_02

iesave "G:\Shared drives\DIL Shared Drive\DIL\Projects\Water\GW EA take-up\Deliverables\v1\hh-census.dta", idvars(household_id) version(15) userinfo report(csv replace) replace


use "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\HouseholdSurvey\DataSets\Final\hh-survey.dta" , clear

iecodebook apply using "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\HouseholdSurvey\DataSets\Final\hh-survey.xlsx", drop

iesave "G:\Shared drives\DIL Shared Drive\DIL\Projects\Water\GW EA take-up\Deliverables\v1\hh-survey.dta", idvars(household_id survey) version(15) userinfo report(csv replace)  replace
