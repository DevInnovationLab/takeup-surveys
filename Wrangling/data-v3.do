local internal 	"C:\Users\luizaandrade\Box\i-h2o-takeup\Data"
local shared 	"G:\Shared drives\DIL Shared Drive\DIL\Projects\Water\GW EA take-up\Deliverables\v4"


*## Household survey -----------------------------------------------------------

copy  	"`internal'\HouseholdSurvey\DataSets\Raw\hh-survey-deid.rds" "`shared'\data\raw\hh-survey-deid.rds", replace
copy  	"`internal'\HouseholdSurvey\DataSets\Raw\hh-survey-deid.dta" "`shared'\data\raw\hh-survey-deid.dta", replace

use "`internal'\HouseholdSurvey\DataSets\Final\hh-survey.dta" , clear

iecodebook apply using "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\HouseholdSurvey\Documentation\hh-survey-v4.xlsx", drop

iesave 	"`shared'\data\analysis\hh-survey.dta", idvars(household_id survey) version(15) userinfo report(csv)  replace
copy  	"`internal'\HouseholdSurvey\DataSets\Final\hh-survey.rds" "`shared'\data\analysis\hh-survey.rds", replace

*## Water point census ---------------------------------------------------------

copy  	"`internal'\WaterPointCensus\DataSets\Raw\wp-census-deid.rds" "`shared'\data\raw\wp-census-deid.rds", replace
copy  	"`internal'\WaterPointCensus\DataSets\Raw\wp-census-deid.dta" "`shared'\data\raw\wp-census-deid.dta", replace


use 	"`internal'\WaterPointCensus\DataSets\Final\wp-census.dta", clear 

iecodebook apply using "`internal'\WaterPointCensus\Documentation\wp-census-v4.xlsx", drop

order disp_dsw_datephoto, after(disp_dsw_date)

iesave 	"`shared'\data\analysis\wp-census.dta", id(wp_id) version(15) userinfo report(csv replace)  replace
copy  	"`internal'\WaterPointCensus\DataSets\Final\wp-census.rds" "`shared'\data\analysis\wp-census.rds", replace

*## Household census -----------------------------------------------------------

copy  	"`internal'\HouseholdCensus\DataSets\Raw\hh-census-deid.rds" "`shared'\data\raw\hh-census-deid.rds", replace
copy  	"`internal'\HouseholdCensus\DataSets\Raw\hh-census-deid.dta" "`shared'\data\raw\hh-census-deid.dta", replace

use "`internal'\HouseholdCensus\DataSets\Final\hh-census.dta" , clear

iecodebook apply using "`internal'\HouseholdCensus\Documentation\hh-census-v4.xlsx"

iesave 	"`shared'\data\analysis\hh-census.dta", idvars(household_id) version(15) userinfo report(csv replace) replace
copy  	"`internal'\HouseholdCensus\DataSets\Final\hh-census.rds" "`shared'\data\analysis\hh-census.rds", replace





/*## Promoter survey ------------------------------------------------------------

use "`internal'\PromoterSurvey\DataSets\Final\pm-survey.dta" , clear

iecodebook template using "`internal'\PromoterSurvey\Documentation\pm-survey-v2.xlsx"

iesave 		"`shared'\pm-survey.dta", idvars(wp_id promoter) version(15) userinfo report(csv replace)  replace
copy  	"`internal'\PromoterSurvey\DataSets\Final\pm-survey.rds" "`shared'\pm-survey.rds"

*/
