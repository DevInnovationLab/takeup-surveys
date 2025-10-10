* import_dil_household_survey.do
*
* 	Imports and aggregates "DIL Household Survey" (ID: dil_household_survey) data.
*
*	Inputs:  "DIL Household Survey_WIDE.csv"
*	Outputs: "DIL Household Survey.dta"
*
*	Output by SurveyCTO June 17, 2025 6:04 PM.

* initialize Stata
clear all
set more off
set mem 100m

* initialize workflow-specific parameters
*	Set overwrite_old_data to 1 if you use the review and correction
*	workflow and allow un-approving of submissions. If you do this,
*	incoming data will overwrite old data, so you won't want to make
*	changes to data in your local .dta file (such changes can be
*	overwritten with each new import).
local overwrite_old_data 0

* initialize form-specific parameters
local csvfile "DIL Household Survey_WIDE.csv"
local dtafile "DIL Household Survey.dta"
local corrfile "DIL Household Survey_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid devicephonenum device_info duration full_duration text_audit audio_audit caseid caseid_vil hh_idbck hh_randtxt hh_randnum hh_randnum_int hhid_time country_pl district_pl district_id_pl"
local text_fields2 "village_name_pl village_id_pl parish_name_pl subcounty_name_pl household_id_pl visit_landmarks_pl full_names_pl hhh_common_name_pl wp_name_pl sstrm_pct_conversation comments today enumerator"
local text_fields3 "enumerator_id enumerator_name vil_id notuse notuse_ot cons_st no_consent_ot cons_end cons_diff respondent_st firstname familyname common_name relation_o respondent_end respondent_diff dsw_ilw_st"
local text_fields4 "wp_other_grp_count source_disp_o_* dsw_ilw_end dsw_ilw_diff drinking_water_st notgivewater_ot other_cont other_plastic access_contain_ot cover_storage_ot prep_different prep_different_ot"
local text_fields5 "who_collected_ot size_ot make_watersafe make_watersafe_ot where_collect_ot collect drinking_water_end drinking_water_diff water_treatment_st everdo everdo_ot often_6month_ot occasion occasion_ot"
local text_fields6 "often_chlorinate_ot chlorinate_occa chlorinate_occa_ot reason_notchlorinate reason_notchlorinate_ot source_safe_ot water_treatment_end water_treatment_diff use_dsw_st recent_use_ot why_treat"
local text_fields7 "why_treat_ot benefits health_details_other benefits_ot use_dsw_end use_dswn_diff perception_st who_talk who_talk_ot information information_ot why_goodjob why_goodjob_ot notgood_job_ot water_clear_ot"
local text_fields8 "water_tea_milk_ot treat_20l_ot empty_dispenser empty_dispenser_ot perception_end perception_diff hh_xtics_st hh_females hh_under18 hh_xtics_end hh_xtics_diff diarrhea_st u5_repeat_count u5_index_*"
local text_fields9 "diarrhea_end diarrhea_diff mobile mobile_comf names_mobile comment instanceid"
local date_fields1 ""
local datetime_fields1 "submissiondate starttime endtime"

disp
disp "Starting import of: `csvfile'"
disp

* import data from primary .csv file
insheet using "`csvfile'", names clear

* drop extra table-list columns
cap drop reserved_name_for_field_*
cap drop generated_table_list_lab*

* continue only if there's at least one row of data to import
if _N>0 {
	* drop note fields (since they don't contain any real data)
	forvalues i = 1/100 {
		if "`note_fields`i''" ~= "" {
			drop `note_fields`i''
		}
	}
	
	* format date and date/time fields
	forvalues i = 1/100 {
		if "`datetime_fields`i''" ~= "" {
			foreach dtvarlist in `datetime_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=clock(`tempdtvar',"MDYhms",2025)
						* automatically try without seconds, just in case
						cap replace `dtvar'=clock(`tempdtvar',"MDYhm",2025) if `dtvar'==. & `tempdtvar'~=""
						format %tc `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
		if "`date_fields`i''" ~= "" {
			foreach dtvarlist in `date_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=date(`tempdtvar',"MDY",2025)
						format %td `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
	}

	* ensure that text fields are always imported as strings (with "" for missing values)
	* (note that we treat "calculate" fields as text; you can destring later if you wish)
	tempvar ismissingvar
	quietly: gen `ismissingvar'=.
	forvalues i = 1/100 {
		if "`text_fields`i''" ~= "" {
			foreach svarlist in `text_fields`i'' {
				cap unab svarlist : `svarlist'
				if _rc==0 {
					foreach stringvar in `svarlist' {
						quietly: replace `ismissingvar'=.
						quietly: cap replace `ismissingvar'=1 if `stringvar'==.
						cap tostring `stringvar', format(%100.0g) replace
						cap replace `stringvar'="" if `ismissingvar'==1
					}
				}
			}
		}
	}
	quietly: drop `ismissingvar'


	* consolidate unique ID into "key" variable
	replace key=instanceid if key==""
	drop instanceid


	* label variables
	label variable key "Unique submission ID"
	cap label variable submissiondate "Date/time submitted"
	cap label variable formdef_version "Form version used on device"
	cap label variable review_status "Review status"
	cap label variable review_comments "Comments made during review"
	cap label variable review_corrections "Corrections made during review"


	label variable enumerator "Please select the unique name for enumerator field. (Edit this label to meet you"
	note enumerator: "Please select the unique name for enumerator field. (Edit this label to meet your needs...)"

	label variable vil_id "Enter household ID:"
	note vil_id: "Enter household ID:"

	label variable confirm_details_yn "Are the location details correct?"
	note confirm_details_yn: "Are the location details correct?"
	label define confirm_details_yn 1 "Yes" 0 "No"
	label values confirm_details_yn confirm_details_yn

	label variable respo_availability "Have you found an eligible respondent at the household?"
	note respo_availability: "Have you found an eligible respondent at the household?"
	label define respo_availability 1 "Yes" 0 "No"
	label values respo_availability respo_availability

	label variable gpslatitude "1.6 GPS Coordinates (latitude)"
	note gpslatitude: "1.6 GPS Coordinates (latitude)"

	label variable gpslongitude "1.6 GPS Coordinates (longitude)"
	note gpslongitude: "1.6 GPS Coordinates (longitude)"

	label variable gpsaltitude "1.6 GPS Coordinates (altitude)"
	note gpsaltitude: "1.6 GPS Coordinates (altitude)"

	label variable gpsaccuracy "1.6 GPS Coordinates (accuracy)"
	note gpsaccuracy: "1.6 GPS Coordinates (accuracy)"

	label variable use_waterpoint "1.9 Do you or your household ever use the water point \${wp_name_pl} or the chlo"
	note use_waterpoint: "1.9 Do you or your household ever use the water point \${wp_name_pl} or the chlorine dispenser in it?"
	label define use_waterpoint 1 "Yes" 0 "No" -999 "Don’t Know"
	label values use_waterpoint use_waterpoint

	label variable notuse "1.10 Why do you not use \${wp_name_pl} right now?"
	note notuse: "1.10 Why do you not use \${wp_name_pl} right now?"

	label variable notuse_ot "1.11 What is the other reason why you don't use \${wp_name_pl} right now?"
	note notuse_ot: "1.11 What is the other reason why you don't use \${wp_name_pl} right now?"

	label variable consent "2.1 Do you consent to volunteer about 30 minutes of your time to speak with me?"
	note consent: "2.1 Do you consent to volunteer about 30 minutes of your time to speak with me?"
	label define consent 1 "Yes" 0 "No"
	label values consent consent

	label variable no_consent "2.2 Why not?"
	note no_consent: "2.2 Why not?"
	label define no_consent 1 "No time available" 2 "Not interested" 3 "Feeling ill" 4 "Don’t trust surveyor" -666 "Other"
	label values no_consent no_consent

	label variable no_consent_ot "2.3 What is the other reason?"
	note no_consent_ot: "2.3 What is the other reason?"

	label variable consent_opt "2.4 Do you agree to ..."
	note consent_opt: "2.4 Do you agree to ..."
	label define consent_opt 1 "Yes" 0 "No"
	label values consent_opt consent_opt

	label variable consent_audio "Having some of your answers recorded by audio?"
	note consent_audio: "Having some of your answers recorded by audio?"
	label define consent_audio 1 "Yes" 0 "No"
	label values consent_audio consent_audio

	label variable consent_gps "Having the GPS location coordinates recorded?"
	note consent_gps: "Having the GPS location coordinates recorded?"
	label define consent_gps 1 "Yes" 0 "No"
	label values consent_gps consent_gps

	label variable consent_contact "The researchers retaining your contact information in order to contact you in th"
	note consent_contact: "The researchers retaining your contact information in order to contact you in the future to see whether you are interested in participating in other research studies?"
	label define consent_contact 1 "Yes" 0 "No"
	label values consent_contact consent_contact

	label variable firstname "3.1 Respondent's first name"
	note firstname: "3.1 Respondent's first name"

	label variable familyname "3.2 Respondent's family name"
	note familyname: "3.2 Respondent's family name"

	label variable common_name "3.3 Respondent's common name"
	note common_name: "3.3 Respondent's common name"

	label variable age_resp "3.4 How old are you?"
	note age_resp: "3.4 How old are you?"

	label variable sex "3.5 What is the respondent's sex"
	note sex: "3.5 What is the respondent's sex"
	label define sex 1 "Male" 2 "Female"
	label values sex sex

	label variable educ "3.6 What is the highest level of education you have completed?"
	note educ: "3.6 What is the highest level of education you have completed?"
	label define educ 0 "Never attended school / did not complete class" 111 "Pre-Primary" 1 "P1" 2 "P2" 3 "P3" 4 "P4" 5 "P5" 6 "P6" 7 "P7" 8 "PLE" 11 "S1" 12 "S2" 13 "S3" 14 "S4" 15 "O level" 16 "S5" 17 "S6" 18 "A level" 20 "Polytechnic" 21 "Informal Training" 22 "College (non-University)" 30 "University" -666 "Other" -999 "Don't know"
	label values educ educ

	label variable relation "3.7 How are you related to the household’s head?"
	note relation: "3.7 How are you related to the household’s head?"
	label define relation 1 "Me/respondent is the HoH" 2 "Spouse/ partner" 3 "Parent/ parent-in-law" 4 "Grandparent/ spouse's grandparent" 5 "Child/ adopted child/ step child" 6 "Son or daughter-in-law" 7 "Grandchild" 8 "Sibling/brother/sister" 9 "Other relative" 10 "Domestic worker" -666 "Other"
	label values relation relation

	label variable relation_o "3.7 What is the other type of relation?"
	note relation_o: "3.7 What is the other type of relation?"

	label variable hh_educ "3.8 What is the highest level of education the household head has completed?"
	note hh_educ: "3.8 What is the highest level of education the household head has completed?"
	label define hh_educ 0 "Never attended school / did not complete class" 111 "Pre-Primary" 1 "P1" 2 "P2" 3 "P3" 4 "P4" 5 "P5" 6 "P6" 7 "P7" 8 "PLE" 11 "S1" 12 "S2" 13 "S3" 14 "S4" 15 "O level" 16 "S5" 17 "S6" 18 "A level" 20 "Polytechnic" 21 "Informal Training" 22 "College (non-University)" 30 "University" -666 "Other" -999 "Don't know"
	label values hh_educ hh_educ

	label variable gender_hhh "3.9 What is the sex of the household head?"
	note gender_hhh: "3.9 What is the sex of the household head?"
	label define gender_hhh 1 "Male" 2 "Female"
	label values gender_hhh gender_hhh

	label variable hhh_age "3.10 How old is the head of the household?"
	note hhh_age: "3.10 How old is the head of the household?"

	label variable wp_dsw "4.1 Is there a chlorine dispenser like this one at \${wp_name_pl}?"
	note wp_dsw: "4.1 Is there a chlorine dispenser like this one at \${wp_name_pl}?"
	label define wp_dsw 1 "Yes" 0 "No" -999 "Don’t Know"
	label values wp_dsw wp_dsw

	label variable wp_ilc "4.2 Is \${wp_name_pl} connected to in-line chlorination?"
	note wp_ilc: "4.2 Is \${wp_name_pl} connected to in-line chlorination?"
	label define wp_ilc 1 "Yes" 0 "No" -999 "Don’t Know"
	label values wp_ilc wp_ilc

	label variable wp_more "4.3 In a normal week, do you use other water sources apart from \${wp_name_pl} t"
	note wp_more: "4.3 In a normal week, do you use other water sources apart from \${wp_name_pl} to collect water for drinking?"
	label define wp_more 1 "Yes" 0 "No" -999 "Don’t Know"
	label values wp_more wp_more

	label variable wp_count "4.4 In a normal week, how many water sources other than \${wp_name_pl} do you us"
	note wp_count: "4.4 In a normal week, how many water sources other than \${wp_name_pl} do you use to collect water for drinking?"

	label variable prepare_water "5.1 Do you prepare drinking water for a child under 5 years of age any different"
	note prepare_water: "5.1 Do you prepare drinking water for a child under 5 years of age any differently than you prepare for yourself?"
	label define prepare_water 1 "Yes" 0 "No" -999 "Don’t Know"
	label values prepare_water prepare_water

	label variable glass_water "5.2 Could you give me a glass of drinking water the way that you would prepare i"
	note glass_water: "5.2 Could you give me a glass of drinking water the way that you would prepare it for a child?"
	label define glass_water 1 "Yes" 0 "No"
	label values glass_water glass_water

	label variable give_water "5.3 Could you give me a glass of drinking water?"
	note give_water: "5.3 Could you give me a glass of drinking water?"
	label define give_water 1 "Yes" 0 "No"
	label values give_water give_water

	label variable notgivewater "5.4 Why not?"
	note notgivewater: "5.4 Why not?"
	label define notgivewater 1 "Drinking water is finished and the respondent is yet to fetch." 2 "Household is locked and respondent does not have the keys" 3 "Refused to give water" 4 "Surveyed outside of home" -666 "Other"
	label values notgivewater notgivewater

	label variable notgivewater_ot "5.5 What is the other reason?"
	note notgivewater_ot: "5.5 What is the other reason?"

	label variable storage "5.6 What type of water storage container is used to store the drinking water?"
	note storage: "5.6 What type of water storage container is used to store the drinking water?"
	label define storage 1 "Clay pot" 2 "Jerrycan" 3 "Plastic bucket" -333 "Other plastic container" 5 "Metal bucket" -666 "Other"
	label values storage storage

	label variable other_cont "5.7 What is the other container?"
	note other_cont: "5.7 What is the other container?"

	label variable other_plastic "5.8 What is the other plastic container?"
	note other_plastic: "5.8 What is the other plastic container?"

	label variable access_contain "5.9 How does the family access the water from the storage container?"
	note access_contain: "5.9 How does the family access the water from the storage container?"
	label define access_contain 1 "Dipping" 2 "Pouring or tap" -666 "Other"
	label values access_contain access_contain

	label variable access_contain_ot "5.10 What is the other container?"
	note access_contain_ot: "5.10 What is the other container?"

	label variable cover_storage "5.11 What is the cover of the storage container with drinking water?"
	note cover_storage: "5.11 What is the cover of the storage container with drinking water?"
	label define cover_storage 1 "Lid/enclosed with a cap" 2 "Open" -666 "Other"
	label values cover_storage cover_storage

	label variable cover_storage_ot "5.12 What is the other cover?"
	note cover_storage_ot: "5.12 What is the other cover?"

	label variable prep_different "5.13 What did you do differently to prepare this water for a child?"
	note prep_different: "5.13 What did you do differently to prepare this water for a child?"

	label variable prep_different_ot "5.14 What is the other reason?"
	note prep_different_ot: "5.14 What is the other reason?"

	label variable howlong_waterprep "5.15 How long ago was the water in this glass collected?"
	note howlong_waterprep: "5.15 How long ago was the water in this glass collected?"
	label define howlong_waterprep 1 "Less than 12 hrs ago [today]" 2 "12-24 hrs ago [Yesterday afternoon]" 3 "25-36 hrs ago [1-1.5 days ago]" 4 "37-48 hrs ago [1.5-2 days ago]" 5 "49-72 hrs ago [3 days ago]" 6 "Over 3 days ago" -999 "Don't know"
	label values howlong_waterprep howlong_waterprep

	label variable who_collected "5.16 Who collected the water in this glass?"
	note who_collected: "5.16 Who collected the water in this glass?"
	label define who_collected 1 "The respondent" 2 "A child under the age of 18 years" 3 "Spouse of the respondent" 4 "Another relative 18 years old or older" -666 "Other"
	label values who_collected who_collected

	label variable who_collected_ot "Can you please specify who collected the water in this glass?"
	note who_collected_ot: "Can you please specify who collected the water in this glass?"

	label variable age_child "5.17 What is the age of the child in years?"
	note age_child: "5.17 What is the age of the child in years?"

	label variable size "5.18 What size of container did you use to collect the drinking water in this gl"
	note size: "5.18 What size of container did you use to collect the drinking water in this glass? If you do not know the exact amount, please approximate."
	label define size 1 "5L" 2 "10L" 3 "20L" -666 "Other (specify)" -999 "Don't know"
	label values size size

	label variable size_ot "Please describe the approximate size of the container you used to collect the dr"
	note size_ot: "Please describe the approximate size of the container you used to collect the drinking water."

	label variable do_anything "5.19 Did you or someone else in this housheold do anything to the water in this "
	note do_anything: "5.19 Did you or someone else in this housheold do anything to the water in this glass to make it safer to drink?"
	label define do_anything 1 "Yes" 0 "No" -999 "Don’t Know"
	label values do_anything do_anything

	label variable make_watersafe "5.20 What did you or someone else do to make this water safer to drink? Anything"
	note make_watersafe: "5.20 What did you or someone else do to make this water safer to drink? Anything else?"

	label variable make_watersafe_ot "What else did you do to make the water safer to drink?"
	note make_watersafe_ot: "What else did you do to make the water safer to drink?"

	label variable mix "5.21 Did you mix the water in this drinking water container with old or untreate"
	note mix: "5.21 Did you mix the water in this drinking water container with old or untreated water?"
	label define mix 1 "Yes" 0 "No" -999 "Don’t Know"
	label values mix mix

	label variable where_collect "5.22 Where did you collect the water in this glass?"
	note where_collect: "5.22 Where did you collect the water in this glass?"
	label define where_collect 1 "From the water point with the chlorine dispenser" 2 "From another water point inside the village" 3 "From another water point outside the village" 4 "Rainwater" 5 "Piped water into the household" -666 "Others"
	label values where_collect where_collect

	label variable where_collect_ot "Please describe the location where you collected the water."
	note where_collect_ot: "Please describe the location where you collected the water."

	label variable collect "5.23 What is the other water source?"
	note collect: "5.23 What is the other water source?"

	label variable everdo "7.1 In the past 6 months, what methods or techniques have you used to make your "
	note everdo: "7.1 In the past 6 months, what methods or techniques have you used to make your drinking water safer?"

	label variable everdo_ot "7.2 What is the other treatment?"
	note everdo_ot: "7.2 What is the other treatment?"

	label variable often_6month "7.3 How often have you done any of these in the past 6 months?"
	note often_6month: "7.3 How often have you done any of these in the past 6 months?"
	label define often_6month 1 "Always" 2 "Sometimes" 3 "Rarely" 4 "Never" -999 "Don't know"
	label values often_6month often_6month

	label variable often_6month_ot "7.4 What is the other frequency?"
	note often_6month_ot: "7.4 What is the other frequency?"

	label variable occasion "7.5 On what occasion do you do this to the water?"
	note occasion: "7.5 On what occasion do you do this to the water?"

	label variable occasion_ot "7.6 What is the other ocasion?"
	note occasion_ot: "7.6 What is the other ocasion?"

	label variable often_chlorinate "7.7 How often have you chlorinated in the past 6 months?"
	note often_chlorinate: "7.7 How often have you chlorinated in the past 6 months?"
	label define often_chlorinate 1 "Always" 2 "Sometimes" 3 "Rarely" 4 "Never" -999 "Don't know"
	label values often_chlorinate often_chlorinate

	label variable often_chlorinate_ot "7.8 What is the other frequency?"
	note often_chlorinate_ot: "7.8 What is the other frequency?"

	label variable chlorinate_occa "7.9 On what occasion do you chlorinate the water?"
	note chlorinate_occa: "7.9 On what occasion do you chlorinate the water?"

	label variable chlorinate_occa_ot "7.10 What is the other ocasion?"
	note chlorinate_occa_ot: "7.10 What is the other ocasion?"

	label variable reason_notchlorinate "7.11 Why do you not always chlorinate the water?"
	note reason_notchlorinate: "7.11 Why do you not always chlorinate the water?"

	label variable reason_notchlorinate_ot "7.12 What is the other reason?"
	note reason_notchlorinate_ot: "7.12 What is the other reason?"

	label variable source_safe "7.13 Do you think it is safe to drink the water from \${wp_name_pl} without addi"
	note source_safe: "7.13 Do you think it is safe to drink the water from \${wp_name_pl} without additional treatment?"
	label define source_safe 1 "Yes, always safe to drink" 2 "No, sometimes it needs water treatment" 3 "No, it always needs water treatment" -666 "Other"
	label values source_safe source_safe

	label variable source_safe_ot "7.14 What is the other answer?"
	note source_safe_ot: "7.14 What is the other answer?"

	label variable people_sick "7.15 Assume that 100 people in your village drink water from \${wp_name_pl} as t"
	note people_sick: "7.15 Assume that 100 people in your village drink water from \${wp_name_pl} as their primary source. If they do not treat the water, how many do you think will get sick or develop diarrhea within one week?"

	label variable often_use_disp "8.1 In the past month, how often do you or any other household member use the ch"
	note often_use_disp: "8.1 In the past month, how often do you or any other household member use the chlorine dispenser (shown in the picture) by the water point to chlorinate your drinking water?"
	label define often_use_disp 0 "Never used in the past month" 1 "Less than half of the time" 2 "Half or more than half of the time" 3 "Every time water is collected" -999 "Don’t know"
	label values often_use_disp often_use_disp

	label variable recent_use "8.2 When was the most recent time that you or any household member last used the"
	note recent_use: "8.2 When was the most recent time that you or any household member last used the chlorine dispenser?"
	label define recent_use 1 "Today" 2 "Yesterday" 3 "In the past 3 days" 4 "4-7 days ago" 5 "8-14 days ago" 6 "15-30 days ago" -666 "Others (specify)" -999 "Don’t know"
	label values recent_use recent_use

	label variable recent_use_ot "Others Specify"
	note recent_use_ot: "Others Specify"

	label variable why_treat "8.3 Why do you treat your water with chlorine from the dispenser?"
	note why_treat: "8.3 Why do you treat your water with chlorine from the dispenser?"

	label variable why_treat_ot "Others Specify"
	note why_treat_ot: "Others Specify"

	label variable knw_benefit "8.4 Do you know of any benefits for you, your family, or your community that are"
	note knw_benefit: "8.4 Do you know of any benefits for you, your family, or your community that are associated with using chlorine?"
	label define knw_benefit 1 "Yes" 0 "No" -999 "Don’t Know"
	label values knw_benefit knw_benefit

	label variable benefits "8.5 What are the benefits that are associated with using chlorine for you, your "
	note benefits: "8.5 What are the benefits that are associated with using chlorine for you, your family, or your community?"

	label variable health_details_other "8.6 Please describe how using chlorine has helped improve health for you, your f"
	note health_details_other: "8.6 Please describe how using chlorine has helped improve health for you, your family, or your community."

	label variable benefits_ot "8.7 Please describe the benefit in your own words."
	note benefits_ot: "8.7 Please describe the benefit in your own words."

	label variable talk "9.1 Has anyone talked with you about the dispenser from outside or within your c"
	note talk: "9.1 Has anyone talked with you about the dispenser from outside or within your community in the past 30 days?"
	label define talk 1 "Yes" 0 "No" -999 "Don’t Know"
	label values talk talk

	label variable who_talk "9.2 Who has talked with you about the dispenser from outside or within your comm"
	note who_talk: "9.2 Who has talked with you about the dispenser from outside or within your community in the past 30 days?"

	label variable who_talk_ot "Other Specify"
	note who_talk_ot: "Other Specify"

	label variable promoter "9.3 Do you know the Promoter of this water source?"
	note promoter: "9.3 Do you know the Promoter of this water source?"
	label define promoter 1 "Yes" 0 "No" -999 "Don’t Know"
	label values promoter promoter

	label variable often_seen_prom "9.4 How often in the past 30 days have you seen the promoter?"
	note often_seen_prom: "9.4 How often in the past 30 days have you seen the promoter?"
	label define often_seen_prom 1 "Not in the past 30 days" 2 "1-2 times per month" 3 "1-3 times per week (3-15 days)" 4 "Daily or almost daily (more than 15 days)" 5 "Never - (I've never seen or talked with this person)" -999 "Don't know"
	label values often_seen_prom often_seen_prom

	label variable talk_dispenser "9.5 How often in the past 30 days has the Promoter talked to you about the dispe"
	note talk_dispenser: "9.5 How often in the past 30 days has the Promoter talked to you about the dispenser?"
	label define talk_dispenser 1 "He/she hasn't told me about the dispenser in the past month" 2 "1-2 times per month" 3 "1-3 times/week (3-15 days per month)" 4 "Daily or almost daily (more than 15 days per month)" 5 "He/she has never told me about the dispense" -999 "Don't know"
	label values talk_dispenser talk_dispenser

	label variable information "9.6 What Information has the Promoter talked to you about regarding the chlorine"
	note information: "9.6 What Information has the Promoter talked to you about regarding the chlorine dispenser within the past 30 days?"

	label variable information_ot "Other Specify"
	note information_ot: "Other Specify"

	label variable rate_job "9.7 How would you rate the job that the Promoters are doing at refilling the dis"
	note rate_job: "9.7 How would you rate the job that the Promoters are doing at refilling the dispenser and promoting its use in the community?"
	label define rate_job 1 "Good" 2 "Average, just okay, or not bad" 3 "Poor" -999 "Don't know"
	label values rate_job rate_job

	label variable why_goodjob "9.8 Why do you think the Promoters are doing a good job?"
	note why_goodjob: "9.8 Why do you think the Promoters are doing a good job?"

	label variable why_goodjob_ot "Other Specify"
	note why_goodjob_ot: "Other Specify"

	label variable notgood_job "9.9 Why don't you think the Promoters are doing a good job?"
	note notgood_job: "9.9 Why don't you think the Promoters are doing a good job?"
	label define notgood_job 1 "He/she never teaches me how to use the dispenser" 2 "He/she is never available" 3 "He/she is not knowledgeable about chlorine" 4 "He/she does not communicate very well" 5 "I found the dispenser empty many times" 6 "The water source and the dispenser are dirty" -666 "Other specify" -999 "Don't know"
	label values notgood_job notgood_job

	label variable notgood_job_ot "Other Specify"
	note notgood_job_ot: "Other Specify"

	label variable water_clear "9.10 If the water is 'clear' when you fetch it, how many turns of a valve must y"
	note water_clear: "9.10 If the water is 'clear' when you fetch it, how many turns of a valve must you make to make 20 litres of water safe for drinking?"
	label define water_clear 1 "1 turn" 2 "2 turns" -666 "Other" -999 "Don't know"
	label values water_clear water_clear

	label variable water_clear_ot "Please specify how many turns."
	note water_clear_ot: "Please specify how many turns."

	label variable water_tea_milk "9.11 If the water is looking like 'tea with no milk' when you fetch it, how many"
	note water_tea_milk: "9.11 If the water is looking like 'tea with no milk' when you fetch it, how many turns of a valve must you make to make 20 litres of water safe for drinking?"
	label define water_tea_milk 1 "1 turn" 2 "2 turns" -666 "Other" -999 "Don't know"
	label values water_tea_milk water_tea_milk

	label variable water_tea_milk_ot "Please specify how many turns."
	note water_tea_milk_ot: "Please specify how many turns."

	label variable waterpoint "9.12 What was the water at the water point looking like when you most recently w"
	note waterpoint: "9.12 What was the water at the water point looking like when you most recently went to collect water?"
	label define waterpoint 1 "1" 2 "2" 3 "3" 4 "4" -999 "Don't know"
	label values waterpoint waterpoint

	label variable treat_20l "9.13 How many turns of the valve did you make to treat 20L of water with chlorin"
	note treat_20l: "9.13 How many turns of the valve did you make to treat 20L of water with chlorine?"
	label define treat_20l 1 "1 turn" 2 "2 turns" -666 "Other" -999 "Don't know"
	label values treat_20l treat_20l

	label variable treat_20l_ot "Please specify how many turns."
	note treat_20l_ot: "Please specify how many turns."

	label variable wait_add "9.14 Do you need to wait after adding chlorine before your water is safe to drin"
	note wait_add: "9.14 Do you need to wait after adding chlorine before your water is safe to drink?"
	label define wait_add 1 "Yes" 0 "No" -999 "Don’t Know"
	label values wait_add wait_add

	label variable empty_dispenser "9.15 What should you do if you find the dispenser empty?"
	note empty_dispenser: "9.15 What should you do if you find the dispenser empty?"

	label variable empty_dispenser_ot "Other Specify"
	note empty_dispenser_ot: "Other Specify"

	label variable hh_hhsincompound "10.1 How many households live in this COMPOUND?"
	note hh_hhsincompound: "10.1 How many households live in this COMPOUND?"

	label variable hh_members "10.2 How many people of all ages currently live in this HOUSEHOLD and have lived"
	note hh_members: "10.2 How many people of all ages currently live in this HOUSEHOLD and have lived here for at least 3 months?"

	label variable hh_adults "10.3 How many people currently living in this HOUSEHOLD and have lived here for "
	note hh_adults: "10.3 How many people currently living in this HOUSEHOLD and have lived here for at least 3 months are 18 years old and above?"

	label variable hh_males "10.4 How many males of all ages currently live in this HOUSEHOLD and have lived "
	note hh_males: "10.4 How many males of all ages currently live in this HOUSEHOLD and have lived here for at least 3 months?"

	label variable hh_pregnant "10.5 How many pregnant women currently live in this HOUSEHOLD?"
	note hh_pregnant: "10.5 How many pregnant women currently live in this HOUSEHOLD?"

	label variable hh_under5 "10.6 How many children under 5 currently live in this HOUSEHOLD?"
	note hh_under5: "10.6 How many children under 5 currently live in this HOUSEHOLD?"

	label variable hh_under2 "10.7 How many children under 2 currently live in this HOUSEHOLD?"
	note hh_under2: "10.7 How many children under 2 currently live in this HOUSEHOLD?"

	label variable mobile "Mobile"
	note mobile: "Mobile"

	label variable mobile_comf "Confirm Mobile"
	note mobile_comf: "Confirm Mobile"

	label variable names_mobile "Names in which the number is registered in"
	note names_mobile: "Names in which the number is registered in"

	label variable comment "Enumerator comment if any"
	note comment: "Enumerator comment if any"

	label variable outcome "What was the outcome of this visit?"
	note outcome: "What was the outcome of this visit?"
	label define outcome 1 "Respondent Surveyed" 2 "Respondent Declined" 3 "Respondent not available, attempts to continue" 4 "Visit attempts reached without reaching respondent"
	label values outcome outcome



	capture {
		foreach rgvar of varlist source_disp_o_* {
			label variable `rgvar' "4.5 What is the other water source?"
			note `rgvar': "4.5 What is the other water source?"
		}
	}

	capture {
		foreach rgvar of varlist gender_* {
			label variable `rgvar' "11.1 Gender"
			note `rgvar': "11.1 Gender"
			label define `rgvar' 1 "Male" 2 "Female"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist age_child_diarr_* {
			label variable `rgvar' "11.2 Age of child in years"
			note `rgvar': "11.2 Age of child in years"
		}
	}

	capture {
		foreach rgvar of varlist age_month_diarr_* {
			label variable `rgvar' "11.3 Age of child in months"
			note `rgvar': "11.3 Age of child in months"
		}
	}

	capture {
		foreach rgvar of varlist age_weeks_diarr_* {
			label variable `rgvar' "11.4 Age of child in weeks"
			note `rgvar': "11.4 Age of child in weeks"
		}
	}

	capture {
		foreach rgvar of varlist diarrh_label_* {
			label variable `rgvar' "11.6 With that definition, has this child had diarrhoea..."
			note `rgvar': "11.6 With that definition, has this child had diarrhoea..."
			label define `rgvar' 1 "Yes" 0 "No" -999 "Don’t Know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist diarrh_2weeks_* {
			label variable `rgvar' "... in the past 2 weeks (past 14 days) including and up to today?"
			note `rgvar': "... in the past 2 weeks (past 14 days) including and up to today?"
			label define `rgvar' 1 "Yes" 0 "No" -999 "Don’t Know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist diarrh_week_* {
			label variable `rgvar' "... in the past week (past 7 days) including and up to today?"
			note `rgvar': "... in the past week (past 7 days) including and up to today?"
			label define `rgvar' 1 "Yes" 0 "No" -999 "Don’t Know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist diarrh_today_* {
			label variable `rgvar' "... today?"
			note `rgvar': "... today?"
			label define `rgvar' 1 "Yes" 0 "No" -999 "Don’t Know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist diarrh_yest_* {
			label variable `rgvar' "... yesterday?"
			note `rgvar': "... yesterday?"
			label define `rgvar' 1 "Yes" 0 "No" -999 "Don’t Know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist diarrh_before_yest_* {
			label variable `rgvar' "... the day before yesterday?"
			note `rgvar': "... the day before yesterday?"
			label define `rgvar' 1 "Yes" 0 "No" -999 "Don’t Know"
			label values `rgvar' `rgvar'
		}
	}




	* append old, previously-imported data (if any)
	cap confirm file "`dtafile'"
	if _rc == 0 {
		* mark all new data before merging with old data
		gen new_data_row=1
		
		* pull in old data
		append using "`dtafile'"
		
		* drop duplicates in favor of old, previously-imported data if overwrite_old_data is 0
		* (alternatively drop in favor of new data if overwrite_old_data is 1)
		sort key
		by key: gen num_for_key = _N
		drop if num_for_key > 1 & ((`overwrite_old_data' == 0 & new_data_row == 1) | (`overwrite_old_data' == 1 & new_data_row ~= 1))
		drop num_for_key

		* drop new-data flag
		drop new_data_row
	}
	
	* save data to Stata format
	save "`dtafile'", replace

	* show codebook and notes
	codebook
	notes list
}

disp
disp "Finished import of: `csvfile'"
disp

* OPTIONAL: LOCALLY-APPLIED STATA CORRECTIONS
*
* Rather than using SurveyCTO's review and correction workflow, the code below can apply a list of corrections
* listed in a local .csv file. Feel free to use, ignore, or delete this code.
*
*   Corrections file path and filename:  DIL Household Survey_corrections.csv
*
*   Corrections file columns (in order): key, fieldname, value, notes

capture confirm file "`corrfile'"
if _rc==0 {
	disp
	disp "Starting application of corrections in: `corrfile'"
	disp

	* save primary data in memory
	preserve

	* load corrections
	insheet using "`corrfile'", names clear
	
	if _N>0 {
		* number all rows (with +1 offset so that it matches row numbers in Excel)
		gen rownum=_n+1
		
		* drop notes field (for information only)
		drop notes
		
		* make sure that all values are in string format to start
		gen origvalue=value
		tostring value, format(%100.0g) replace
		cap replace value="" if origvalue==.
		drop origvalue
		replace value=trim(value)
		
		* correct field names to match Stata field names (lowercase, drop -'s and .'s)
		replace fieldname=lower(subinstr(subinstr(fieldname,"-","",.),".","",.))
		
		* format date and date/time fields (taking account of possible wildcards for repeat groups)
		forvalues i = 1/100 {
			if "`datetime_fields`i''" ~= "" {
				foreach dtvar in `datetime_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						gen origvalue=value
						replace value=string(clock(value,"MDYhms",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
						* allow for cases where seconds haven't been specified
						replace value=string(clock(origvalue,"MDYhm",2025),"%25.0g") if strmatch(fieldname,"`dtvar'") & value=="." & origvalue~="."
						drop origvalue
					}
				}
			}
			if "`date_fields`i''" ~= "" {
				foreach dtvar in `date_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						replace value=string(clock(value,"MDY",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
					}
				}
			}
		}

		* write out a temp file with the commands necessary to apply each correction
		tempfile tempdo
		file open dofile using "`tempdo'", write replace
		local N = _N
		forvalues i = 1/`N' {
			local fieldnameval=fieldname[`i']
			local valueval=value[`i']
			local keyval=key[`i']
			local rownumval=rownum[`i']
			file write dofile `"cap replace `fieldnameval'="`valueval'" if key=="`keyval'""' _n
			file write dofile `"if _rc ~= 0 {"' _n
			if "`valueval'" == "" {
				file write dofile _tab `"cap replace `fieldnameval'=. if key=="`keyval'""' _n
			}
			else {
				file write dofile _tab `"cap replace `fieldnameval'=`valueval' if key=="`keyval'""' _n
			}
			file write dofile _tab `"if _rc ~= 0 {"' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab _tab `"disp "CAN'T APPLY CORRECTION IN ROW #`rownumval'""' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab `"}"' _n
			file write dofile `"}"' _n
		}
		file close dofile
	
		* restore primary data
		restore
		
		* execute the .do file to actually apply all corrections
		do "`tempdo'"

		* re-save data
		save "`dtafile'", replace
	}
	else {
		* restore primary data		
		restore
	}

	disp
	disp "Finished applying corrections in: `corrfile'"
	disp
}
