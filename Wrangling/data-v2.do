local internal 	"C:\Users\luizaandrade\Box\i-h2o-takeup\Data"
local shared 	"G:\Shared drives\DIL Shared Drive\DIL\Projects\Water\GW EA take-up\Deliverables\v2"


*## Water point census ---------------------------------------------------------

use "`internal'\WaterPointCensus\DataSets\Final\wp-census.dta", clear 

iecodebook apply using "`internal'\WaterPointCensus\Documentation\wp-census-v2.xlsx", drop

order disp_dsw_datephoto, after(disp_dsw_date)

iesave 	"`shared'\wp-census.dta", id(wp_id) version(15) userinfo report(csv replace)  replace
copy  	"`internal'\WaterPointCensus\DataSets\Final\wp-census.rds" "`shared'\wp-census.rds", replace

/*## Promoter survey ------------------------------------------------------------

use "`internal'\PromoterSurvey\DataSets\Final\pm-survey.dta" , clear

iecodebook template using "`internal'\PromoterSurvey\Documentation\pm-survey-v2.xlsx"

iesave 		"`shared'\pm-survey.dta", idvars(wp_id promoter) version(15) userinfo report(csv replace)  replace
copy  	"`internal'\PromoterSurvey\DataSets\Final\pm-survey.rds" "`shared'\pm-survey.rds"

*/
*## Household census -----------------------------------------------------------

use "`internal'\HouseholdCensus\DataSets\Final\hh-census.dta" , clear

iecodebook apply using "`internal'\HouseholdCensus\Documentation\hh-census-v2.xlsx", drop

iesave 		"`shared'\hh-census.dta", idvars(household_id) version(15) userinfo report(csv replace) replace
copy  	"`internal'\HouseholdCensus\DataSets\Final\hh-census.rds" "`shared'\hh-census.rds", replace

*## Household survey -----------------------------------------------------------

use "`internal'\HouseholdSurvey\DataSets\Final\hh-survey.dta" , clear

iecodebook template using "C:\Users\luizaandrade\Box\i-h2o-takeup\Data\HouseholdSurvey\Documentation\hh-survey-v2.xlsx", replace

iesave 		"`shared'\hh-survey.dta", idvars(household_id survey) version(15) userinfo report(csv)  replace
copy  	"`internal'\HouseholdSurvey\DataSets\Final\hh-survey.rds" "`shared'\hh-survey.rds", replace
