* ------------------------------------------------------------------------------
* Date				January 23, 2024 (opened) - APR. 21, 2024 (last modified)
* Author			Ila Gupta
* Advisor			Chris R. Udry
*
* Task				Senior Thesis
* Title				Early Childhood Shocks in Ghana
*
* Datasets			w1: s1d, 7a-7c rural community, 6-6a urban community, 
*					s6a-e physical health, s1ei-iii employment/unemp, s1fi-iii
*					education/literacy
*
*					w2: 01b2 roster
*
*					w3: 01b2_roster
*
* ------------------------------------------------------------------------------

********************************************************************************
* --------------------------------- SET-UP -------------------------------------
********************************************************************************
	clear all
	set more off
	
	log using ghana_shocks_on_children, replace
	
	ssc install estout									
	ssc install outreg2
	ssc install valtovar

	global main 			"/Users/ilagupta/Documents/GPRL/Ghana_Panel_Survey"
	global raw 				"$main/raw_data"
	global community		"$raw/community"
	global clean 			"$main/clean_data"
	global output 			"$main/output"
	global tex				"$output/tex"
	global final			"$output/final"
	cd "$main"
	
	global tempvarlist FPrimary hhmid wave gender dayofbirth monthofbirth ///
	yearofbirth relationship maritalstatus spouseid agemarried yearmarried ///
	dowrygiven dowryreceived religion nationality ethnicity fatherinhouse ///
	fatherid fathereduc fatherwork motherinhouse motherid mothereduc ///
	motherwork politicaloffice stillpoloffice traditionaloffice ///
	stilltradoffice awaylast12

* ----------------------------- DATA PREPARATION -------------------------------
// WAVE 1
	use "$raw/wave_1/s1d.dta", clear						

	rename s1d_1 gender
	rename sid_3i dayofbirth
	rename s1d_3ii monthofbirth
	rename s1d_3iii yearofbirth
	rename s1d_2 relationship
	rename s1d_6 maritalstatus
	rename s1d_8 spouseid
	rename s1d_9 agemarried
	rename s1d_11 yearmarried
	rename s1d_10ai dowrygiven
	rename s1d_10bi dowryreceived
	rename s1d_13 religion
	rename s1d_15 nationality
	rename s1d_16 ethnicity
	rename s1d_17i fatherinhouse
	rename s1d_17ii fatherid
	rename s1d_18 fathereduc
	rename s1d_19 fatherwork
	rename s1d_20i motherinhouse
	rename s1d_20ii motherid
	rename s1d_21 mothereduc
	rename s1d_22 motherwork
	rename s1d_23 politicaloffice
	rename s1d_24 stillpoloffice
	rename s1d_25 traditionaloffice
	rename s1d_26 stilltradoffice
	rename s1d_27 awaylast12

	tostring FPrimary, replace
	
	order $tempvarlist
	save "$clean/wave_1/background.dta", replace

	keep $tempvarlist

	tempfile temp_w1
	save "`temp_w1'"
	

// WAVE 2
	use "$raw/wave_2/01b2_roster.dta", clear

	replace yearofbirth = year(dateofbirth) if yearofbirth==.
	gen monthofbirth = month(dateofbirth)
	gen dayofbirth = day(dateofbirth)

	keep FPrimary hhmid wave gender dayofbirth monthofbirth yearofbirth relationship

	merge 1:1 FPrimary hhmid using "$raw/wave_2/01d_background.dta"

	split ethnicity, p(.) limit(2)
	destring ethnicity2, replace
	drop ethnicity
	rename ethnicity2 ethnicity

	keep $tempvarlist
	order $tempvarlist
	
	tempfile temp_w2
	save "`temp_w2'"

// WAVE 3
	use "$raw/wave_3/01b2_roster.dta", clear

	replace yearofbirth = year(dateofbirth) if yearofbirth==.
	gen monthofbirth = month(dateofbirth)
	gen dayofbirth = day(dateofbirth)

	keep FPrimary hhmid gender dayofbirth monthofbirth yearofbirth relationship maritalstatus

	merge 1:1 FPrimary hhmid using "$raw/wave_3/01d_background.dta"

	gen wave = 3

	rename spouseid_1 spouseid

	keep $tempvarlist
	order $tempvarlist

	tempfile temp_w3
	save "`temp_w3'"

********************************************************************************
* ---------------------------- PANEL CONSTRUCTION ------------------------------
********************************************************************************
	use "`temp_w1'", clear
	append using "`temp_w2'", force
	append using "`temp_w3'", force
	foreach var in gender fatherinhouse motherinhouse stillpoloffice ///
				   stilltradoffice {
		replace `var' = 2 if `var'==5 & inlist(wave,2,3)
		}
		
	foreach var in fathereduc mothereduc {
		replace `var' = 1 if `var'==0 & inlist(wave,2,3)
		replace `var' = 13 if `var'==95 & inlist(wave,2)
		replace `var' = 13 if `var'==-666 & inlist(wave,3)
		replace `var' = -9 if `var' < -666 & inlist(wave,3)
		}
		
	sort FPrimary hhmid wave
	
	valtovar *
	
	label define fatherwork 0 "Has no occupation" 36 "Self employed farmer" ///
	37 "Forestry worker" 38 "Fisherman/fishmonger" 39 "Self employed trader" ///
	40 "Employed shop attendant" 95 "Other", modify

	label define motherwork 0 "Has no occupation" 36 "Self employed farmer" ///
	37 "Forestry worker" 38 "Fisherman/fishmonger" 39 "Self employed trader" ///
	40 "Employed shop attendant" 95 "Other", modify

	replace politicaloffice = 6 if politicaloffice==95 & inlist(wave,2)
	replace politicaloffice = 6 if politicaloffice==-666 & inlist(wave,3)
	replace politicaloffice = . if politicaloffice < -666 & inlist(wave,3)
	replace politicaloffice = politicaloffice + 1 if inlist(wave,2,3)

	replace traditionaloffice = 8 if traditionaloffice==95 & inlist(wave,2)
	replace traditionaloffice = 8 if traditionaloffice==-666 & inlist(wave,3)
	replace traditionaloffice = . if traditionaloffice < -666 & inlist(wave,3)
	replace traditionaloffice = traditionaloffice + 1 if inlist(wave,2,3)

	label var FPrimary "Household (HH) number"
	label var hhmid "HH Member ID"
	label var wave "Wave"
	label var gender "Gender"
	label var dayofbirth "Day of birth"
	label var monthofbirth "Month of birth"
	label var yearofbirth "Year of birth"
	label var relationship "Relationship to HH Head"
	label var maritalstatus "Marital status"
	label var spouseid "Spouse ID"
	label var agemarried "Age at marriage"
	label var yearmarried "Year in which persen got married"
	label var dowrygiven "Amount of dowry given (in cedis)"
	label var dowryreceived "Amount of dowry received (in cedis)"
	label var religion "Religious denomination of person"
	label var nationality "Nationality"
	label var ethnicity "Ethnic group"
	label var fatherinhouse "Does father live in this household?"
	label var fatherid "ID of father if he lives in the household"
	label var fathereduc "Father's highest level of education"
	label var fatherwork "Father's occupation for most of his life"
	label var motherinhouse "Does mother live in this household?"
	label var motherid "ID of mother if she lives in the household"
	label var mothereduc "Mother's highest level of education"
	label var motherwork "Mother's occupation for most of her life"
	label var politicaloffice "Has the person ever held a political office?"
	label var stillpoloffice "Does the person still hold political office?"
	label var traditionaloffice "Has the person ever held a traditional office?"
	label var stilltradoffice "Does the person still hold this traditional office?"
	label var awaylast12 "For how many months has the person been away from this HH in last 12 months?"

	save "$clean/household_background_PANEL.dta", replace
	
********************************************************************************
* -------------------------- CLEAN COMMUNITY DATA ------------------------------
********************************************************************************
* -------------------------------- W1 RURAL ------------------------------------
* 7A TOWN EVENTS
	use "$community/wave_1/Rural/SEC 7A.dta", clear
	
	gen wave = 1
	rename reg regioncode
	rename district districtcode
	rename ea_no eacode
	rename shock_type s6a_shock_type
	
	foreach var of varlist cases_* {
		gen _`var' = `var'
		replace _`var' = 0 if `var' == .
		rename `var' s7a_`var'
	}
	
	gen s7a_shock_count = _cases_2006 + _cases_2007 + _cases_2008 + _cases_2009		// sum town shock cases 2006-2009
	drop _cases*
	label var s7a_shock_count "Town event shock count"

	drop if s6a_shock_type == "2"
	
	encode s6a_shock_type, generate(shocktype)
	drop if shocktype==. 					
		* 18 obs dropped from ea 230 (Ashanti)
	tostring shocktype, replace
	drop s6a
	
	save "$clean/wave_1/community/w1_7a_community.dta", replace
	
* 7B AGRICULTURAL SHOCKS
	use "$community/wave_1/Rural/SEC 7B.dta", clear
	
	gen wave = 1
	rename reg regioncode
	rename district districtcode
	rename ea_no eacode
	
	foreach var of varlist s7b_* {
		gen _`var' = `var'
		replace _`var' = 0 if `var' == . | `var' == 4
		replace _`var' = 1 if `var' == 2 | `var' == 3
	}
	
	gen s7b_shock_count = _s7b_occur_2006 + _s7b_occur_2007 + _s7b_occur_2008 ///	
	+ _s7b_occur_2009																// sum agri shock cases 2006-2009
	drop _s7b_occur*
	
	save "$clean/wave_1/community/w1_7b_community.dta", replace
	
* 7C CROP SALES
	use "$community/wave_1/Rural/SEC 7C.dta", clear
	
	gen wave = 1
	rename reg regioncode
	rename district districtcode
	rename ea_no eacode
	
	foreach var of varlist inab_* {
		replace `var' = "1" if `var' == "A"
		destring `var', replace
		replace `var' = 1 if `var' !=.
		replace `var' = 0 if `var' ==.
	}
	
	egen inab_sell_count = rowtotal(inab_*)										 // sum sale shock cases 2006-2009
	
	save "$clean/wave_1/community/w1_7c_community.dta", replace
	
* CLEAN & MERGE RURAL SHOCKS 
* town events
	use "$clean/wave_1/community/w1_7a_community.dta", clear
	
		sort region district ea shocktype
	
		keep regioncode districtcode eacode wave s7a_shock_count shocktype
		
		duplicates drop 
			* 326 obs dropped
	
		bys region district ea shocktype: replace s7a=s7a[_n-1] if _n>1
		duplicates drop
			* 14 obs dropped
		
		reshape wide s7a_shock, i(region district ea) j(shocktype) 
		
		egen shock_town_count = rowtotal(s7a_*)
		
		rename s7a_shock_count1 attacksminority
		rename s7a_shock_count2 beatingwitches
		rename s7a_shock_count3 disease
		rename s7a_shock_count4 ethnic
		rename s7a_shock_count5 fireflood
		rename s7a_shock_count6 water
		rename s7a_shock_count7 landdispute
		rename s7a_shock_count8 firmbankruptcy
		rename s7a_shock_count9 theft
		rename s7a_shock_count10 mob
		rename s7a_shock_count11 murder
		rename s7a_shock_count12 other
		rename s7a_shock_count13 peacefuldem
		rename s7a_shock_count14 policebrut
		rename s7a_shock_count15 rape
		rename s7a_shock_count16 religious
		rename s7a_shock_count17 violentdem
		
		label var attacks "attacks on a minority group"
		label var beating "beating or killing of suspected witches"
		label var disease "disease epidemic affecting people"
		label var ethnic "ethnic/tribal conflict"
		label var fireflood "fire, flood or wind that destroyed property"
		label var water "interruption in water supply"
		label var land "land dispute - use of forest resources"
		label var firm "large firm bankruptcy"
		label var theft "major theft, armed robery and burglary"
		label var mob "mob justice"
		label var murder "murder"
		label var other "other significant event"
		label var peaceful "peaceful demonstration/strikes"
		label var police "police/military brutality against civilian(s)"
		label var rape "rape"
		label var religious "religious conflict"
		label var violent "violent demonstrations/strikes"
		
		save "$clean/wave_1/community/w1_7a_community_collapsed", replace

* agricultural
	use "$clean/wave_1/community/w1_7b_community.dta", clear
		keep regioncode districtcode eacode wave s6b_shock_type s7b_shock_count
		
		duplicates drop
			* 166 obs
		drop if s6b == "4"
			* 1 obs
		
		encode s6b, gen(shocktype_agri)
		drop if shocktype ==.
			* 2 obs
		drop s6b
		
		bys region district ea shocktype: replace s7b=s7b[_n-1] if _n>1
		duplicates drop
		* 41 obs 
			
		reshape wide s7b, i(region district ea) j(shock)
		
		egen shock_agri_count = rowtotal(s7b_*)
		
		rename s7b_shock_count1 birds 
		rename s7b_shock_count2 locust 
		rename s7b_shock_count3 epidemic 
		rename s7b_shock_count4 other
		rename s7b_shock_count5	animals 
		rename s7b_shock_count6 insects 
		rename s7b_shock_count7 disease
		rename s7b_shock_count8 rodents
		rename s7b_shock_count9 littlerain 
		rename s7b_shock_count10 muchrain 
		
		label var birds "birds destroying crops"
		label var locust "locust/grasshoppers destroying crops"
		label var epidemic "major disease epidemic affecting crops"
		label var other "other"
		label var animals "other large animals destroying crops"
		label var insects "other insects destroying crops"
		label var disease "plant/animal disease"
		label var rodents "rodents destroying crops"
		label var littlerain "too little rain affecting crops and animals"
		label var muchrain "too much rain affecting crops and animals"
		
		save "$clean/wave_1/community/w1_7b_community_collapsed", replace

* crop sales
	use "$clean/wave_1/community/w1_7c_community.dta", clear
		keep regioncode districtcode eacode wave itemname inab_*
		
		gen shock_sales_count = inab_sell_count
		drop inab_*
		
		encode itemname, gen(item)
		drop if item ==.
			* 104 obs
		drop itemname
		
		bys region district ea item: replace shock=shock[_n-1] if _n>1
		duplicates drop
			* 102 obs
		
		reshape wide shock_sales, i(region district ea) j(item) 
		
		egen shock_crop_count = rowtotal(shock_sales*)
		
		rename shock_sales_count1 cassava
		rename shock_sales_count2 cocoyam
		rename shock_sales_count3 maize
		rename shock_sales_count4 millet
		rename shock_sales_count5 plantain
		rename shock_sales_count6 yam
		
		save "$clean/wave_1/community/w1_7c_community_collapsed", replace
	
* MERGE 
	use "$clean/wave_1/community/w1_7a_community_collapsed.dta", clear
	merge 1:1 region district ea using "$clean/wave_1/community/w1_7b_community_collapsed.dta"
	drop _merge
	
	merge 1:1 region district ea using "$clean/wave_1/community/w1_7c_community_collapsed.dta"
	drop _merge
	
	save "$clean/wave_1/community/W1_RURALSHOCKS.dta", replace
	
* -------------------------------- W1 URBAN ------------------------------------
* CROP SALES
	use "$community/wave_1/Urban/SEC 5_SHKS TO CROP SALES.dta", clear
	
	rename reg regioncode
	rename district districtcode
	rename ea_no eacode
	
	foreach var of varlist inab_* {
		replace `var' = "1" if `var' == "A"
		destring `var', replace
		replace `var' = 1 if `var' !=.
		replace `var' = 0 if `var' ==.
	}
	
	egen inab_sell_count = rowtotal(inab_*)
	
	save "$clean/wave_1/community/w1_urban_cropshocks.dta", replace
	
* TOWN EVENTS
	use "$community/wave_1/Urban/SEC 5.dta", clear
	
	gen wave = 1
	rename reg regioncode
	rename district districtcode
	rename ea_no eacode
	rename shock_type shocktype_str
	
	foreach var of varlist cases_* {
		gen _`var' = `var'
		replace _`var' = 0 if `var' == .
	}
	
	gen totalcases = _cases_2006 + _cases_2007 + _cases_2008 + _cases_2009
	drop _cases*
	label var totalcases "Town event shock count"

	encode shocktype_str, generate(shocktype)
	drop if shocktype==. 														
		* 1 obs
	drop shocktype_str
	
	save "$clean/wave_1/community/w1_urban_townshocks.dta", replace

* CLEAN & MERGE URBAN SHOCKS
* crop sales
	use "$clean/wave_1/community/w1_urban_cropshocks.dta", clear
		sort region district ea itemname
		keep region district ea item inab_sell_count
		
		bys region district ea item: replace inab=inab[_n-1] if _n>1
		duplicates drop
		* 1 obs
		
		encode itemname, gen(item)
		drop if item ==.
		drop itemname
		
		/*
		tab item inab_sell if item == 4 , m 
		tab item inab_sell if item == 5 , m 
		*/
		
		replace item = 1 if item == 3
		drop if item == 4
		
		reshape wide inab_sell_count, i(region district ea) j(item) 
		
		egen shock_crop_count = rowtotal(inab_*)
		
		rename inab_sell_count1 cassava
		rename inab_sell_count2 cocoyam
		rename inab_sell_count5 maize
		rename inab_sell_count6 millet
		rename inab_sell_count7 plantain
		rename inab_sell_count8 yam
		
		gen wave = 1
		
		save "$clean/wave_1/community/w1_urban_cropshocks_collapsed", replace
		
* town events		
	use "$clean/wave_1/community/w1_urban_townshocks.dta", clear
		keep region district ea wave totalcases shocktype
	
		bys region district ea shocktype: replace totalcases=totalcases[_n-1] if _n>1
		duplicates drop
	
		reshape wide totalcases, i(region district ea) j(shocktype) 
		
		egen shock_town_count = rowtotal(totalcases*)
		
		rename totalcases1 attacksminority
		rename totalcases2 beatingwitches
		rename totalcases3 disease
		rename totalcases4 ethnic
		rename totalcases5 fireflood
		rename totalcases6 water
		rename totalcases7 landdispute
		rename totalcases8 firmbankruptcy
		rename totalcases9 theft
		rename totalcases10 mob
		rename totalcases11 murder
		rename totalcases12 other
		rename totalcases13 peacefuldem
		rename totalcases14 policebrut
		rename totalcases15 rape
		rename totalcases16 religious
		rename totalcases17 violentdem
		
		label var attacks "attacks on a minority group"
		label var beating "beating or killing of suspected witches"
		label var disease "disease epidemic affecting people"
		label var ethnic "ethnic/tribal conflict"
		label var fireflood "fire, flood or wind that destroyed property"
		label var water "interruption in water supply"
		label var land "land dispute - use of forest resources"
		label var firm "large firm bankruptcy"
		label var theft "major theft, armed robery and burglary"
		label var mob "mob justice"
		label var murder "murder"
		label var other "other significant event"
		label var peaceful "peaceful demonstration/strikes"
		label var police "police/military brutality against civilian(s)"
		label var rape "rape"
		label var religious "religious conflict"
		label var violent "violent demonstrations/strikes"
		
		save "$clean/wave_1/community/w1_urban_townshocks_collapsed", replace
	
* MERGE
	use "$clean/wave_1/community/w1_urban_cropshocks_collapsed.dta", clear
	merge 1:1 region district ea using "$clean/wave_1/community/w1_urban_townshocks_collapsed.dta"
	drop _merge

	save "$clean/wave_1/community/W1_URBANSHOCKS.dta", replace

* W1 APPEND RURAL / URBAN 
	use "$clean/wave_1/community/W1_RURALSHOCKS", replace
	append using "$clean/wave_1/community/W1_URBANSHOCKS"
	save "$clean/wave_1/community/W1_ALLSHOCKS", replace

********************************************************************************
* ------------------------------ CLEAN BACKGROUND  -----------------------------
********************************************************************************
	use "$clean/wave_1/background.dta", clear
	
	global idvarlist FPrimary hhid hhmid wave regioncode districtcode eacode
	
	rename s1d_4i age_yrs
	rename s1d_4ii age_mos
	rename s1d_5 child
	rename s1d_7 spouseinhh
	rename s1d_14 placeofbirth
	
	drop s1d_*
	
	replace nationality = 11 if nationality == 12
	replace nationality = 9 if nationality == 3 | nationality == 4 | ///
	nationality == 5 | nationality == 6 | nationality == 7
	
	gen ghanaian = nationality
	replace ghanaian = 0 if ghanaian == 2 | ghanaian == 9 | ghanaian == 11
	
	replace religion = 7 if religion == 2 
	replace religion = 11 if religion == 12 | religion == 13 | religion == 6
	
	replace ethnicity = 1 if ethnicity >= 2 & ethnicity <= 19
	replace ethnicity = 20 if ethnicity >= 21 & ethnicity <= 27
	replace ethnicity = 40 if ethnicity >= 41 & ethnicity <= 49
	replace ethnicity = 50 if ethnicity >= 51 & ethnicity <= 57
	replace ethnicity = 60 if ethnicity >= 61 & ethnicity <= 69
	replace ethnicity = 70 if ethnicity >= 71 & ethnicity <= 75
	replace ethnicity = 80 if ethnicity >= 81 & ethnicity <= 88
	replace ethnicity = 93 if ethnicity >= 90
	
	keep $idvarlist gender monthofbirth yearofbirth relationship ///
	maritalstatus spouseid agemarried yearmarried religion nationality ///
	ethnicity fatherinhouse fatherid fathereduc fatherwork motherinhouse ///
	motherid mothereduc motherwork awaylast12 age_yrs age_mos child ///
	spouseinhh placeofbirth ghanaian
	
	* relabel 93 "other"
	
	qui bys region district eacode FPrimary hhid: gen hhsize = _N
	
	foreach var of varlist fathereduc mothereduc {
		replace `var' = 10 if `var' == 4 | `var' == 5 | `var' == 6 | `var' == 7 | `var' == 8 | `var' == 9 | `var' == 11
		replace `var' =. if `var' == 12 | `var' == 13 
	}
	
	save "$clean/wave_1/background_final.dta", replace
	
********************************************************************************
* -------------------------------- EMPLOYMENT ----------------------------------
********************************************************************************
	global empvarlist hhwork numhhworkers jobcount maintasks isco_work ///
	tradetype isic_trade duration_yrs duration_mos paid earnedcedis ///
	earnedpessewas formal paidvaca paidsick workplace
	
	global unempvarlist employed eligible available_lastweek effort_lastweek ///
	whynot jobsearch_type jobsearch_duration lastjob_type lastjob_isco ///
	conditionsforavail lowestwtw_cedis lowestwtw_pessewas
	
	global educvarlist someschool highestgrade highestqualif school_lastyr ///
	studentnow schooltype currentgrade traveltime_hr traveltime_min ///
	classtime_hr classtime_min absent_hr absent_min hw_hr hw_min fees_cedis ///
	fees_pesewas pta_cedis pta_pesewas uniforms_cedis uniforms_pesewas ///
	books_cedis books_pesewas trans_cedis trans_pesewas
	
	global litvarlist readlang writelang readeng writeeng speakfluent ///
	writtencalc litcourse whylitcourse coursedur_mos
	
// WAVE 1
* EMPLOYMENT
	use "$raw/wave_1/s1ei.dta", clear
	merge m:1 FPrimary eacode hhid using "$raw/wave_1/s1ei0.dta"
	
	rename s1ei_1 jobcount
	rename s1ei_2 maintasks
	rename s1ei_3 isco_work
	rename s1ei_4 tradetype
	rename s1ei_5 isic_trade
	rename s1ei_6i duration_yrs
	rename s1ei_6ii duration_mos
	rename s1ei_9 paid
	rename s1ei_10i earnedcedis
	rename s1ei_10ii earnedpessewas
	rename s1ei_15 formal
	rename s1ei_17 paidvaca
	rename s1ei_18 paidsick
	rename s1ei_22 workplace
	rename s1ei_0 hhwork
	rename s1ei_01 numhhworkers
	
	replace hhmid=999 if hhmid==. 												// NOTE - 3827 obs , no work outside hh in last 7 days
	
	keep $idvarlist $empvarlist
	order $idvarlist $empvarlist
	
	tempfile temp_w1_emp
	save "`temp_w1_emp'"														// NOTE - for now, not including secondary employment survey
	
* UNEMPLOYMENT
	use "$raw/wave_1/s1eiii.dta", clear
	merge m:1 FPrimary eacode hhid using "$raw/wave_1/s1eiii0.dta"
	
	rename s1eiii_62i employed
	rename s1eiii_62ii eligible
	rename s1eiii_63 available_lastweek
	rename s1eiii_64 effort_lastweek
	rename s1eiii_65 whynot
	rename s1eiii_67 jobsearch_type
	rename s1eiii_68 jobsearch_duration
	rename s1eiii_69 lastjob_type
	rename s1eiii_70 lastjob_isco
	rename s1eiii_71 conditionsforavail
	rename s1eiii_72i lowestwtw_cedis
	rename s1eiii_72ii lowestwtw_pessewas
	
	keep $idvarlist $unempvarlist
	order $idvarlist $unempvarlist 
	
	tempfile temp_w1_unemp
	save "`temp_w1_unemp'"
	
* MERGE EMP / UNEMP
	use "`temp_w1_emp'", clear
	append using "`temp_w1_unemp'"
	
	* browse if FPrimary ==. | hhid==. | hhmid==.
	* 495 obs
	drop if hhmid==.
	
	* browse if hhmid==999
	* 3,845 observations
	drop if hhmid == 999
	
	* isid FPrimary hhid hhmid region district eacode
	
	bys region district eacode FPrimary hhid hhmid: drop if _n != _N
	
	tostring FPrimary, replace
	save "$clean/wave_1/emp_unemp.dta", replace
	
********************************************************************************
* --------------------------------- EDUCATION ----------------------------------
********************************************************************************
* EDUCATION
	use "$raw/wave_1/s1fi.dta", clear
	
	rename s1fi_hhmid hhmid 
	rename s1fi_2 someschool
	rename s1fi_3 highestgrade
	rename s1fi_4 highestqualif
	rename s1fi_5 school_lastyr
	rename s1fi_6 studentnow
	rename s1fi_7 schooltype
	rename s1fi_8 currentgrade
	rename s1fi_9i traveltime_hr
	rename s1fi_9ii traveltime_min
	rename s1fi_10i classtime_hr
	rename s1fi_10ii classtime_min
	rename s1fi_11i absent_hr
	rename s1fi_11ii absent_min
	rename s1fi_12i hw_hr
	rename s1fi_12ii hw_min
	rename s1fi_13i fees_cedis
	rename s1fi_13ii fees_pesewas
	rename s1fi_14i pta_cedis
	rename s1fi_14ii pta_pesewas
	rename s1fi_15i uniforms_cedis
	rename s1fi_15ii uniforms_pesewas
	rename s1fi_16i books_cedis
	rename s1fi_16ii books_pesewas
	rename s1fi_17i trans_cedis
	rename s1fi_17ii trans_pesewas
	
	keep $idvarlist $educvarlist
	order $idvarlist $educvarlist
	
	drop if hhmid ==.
	/* 
	list FP eacode someschool if hhmid ==.
	NOTE: 4 obs of 5 are ea 294
	*/
	
	tostring FP, replace
	
	save "$clean/wave_1/s1fi.dta", replace

	** ADD IN EXAM SCORES!
	
* LITERACY
	use "$raw/wave_1/s1fiii.dta", clear
	
	rename s1fi_hhmid hhmid
	rename s1fiii_53 readlang
	rename s1fiii_54 writelang
	rename s1fiii_55 readeng
	rename s1fiii_56 writeeng
	rename s1fiii_57 speakfluent
	rename s1fiii_58 writtencalc
	rename s1fiii_59 litcourse
	rename s1fiii_60 whylitcourse
	rename s1fiii_61 coursedur_mos
	
	keep $idvarlist $litvarlist
	order $idvarlist $litvarlist
	
	drop if hhmid ==.
	** 1 obs deleted
	
	tostring FP, replace
		
	save "$clean/wave_1/s1fiii.dta", replace
	
* MERGE EDUC & LITERACY
	merge 1:1 FPrimary hhid hhmid using "$clean/wave_1/s1fi.dta"
	drop _merge

	save "$clean/wave_1/educ_lit.dta", replace

********************************************************************************
* ----------------------------- PHYSICAL HEALTH --------------------------------
********************************************************************************
	global idvarlist FPrimary hhid hhmid wave regioncode districtcode eacode
	
	use "$raw/wave_1/s6a.dta", clear
		keep $idvarlist s6a_a1 s6a_a2_1 s6a_a3_1
		rename s6a_a1 healthinsurance
		rename s6a_a2_1 insurancetype
		rename s6a_a3_1 whynotinsurance
		
		tostring FPrimary, replace
		
		save "$clean/wave_1/health6a.dta", replace
	
	
	use "$raw/wave_1/s6b.dta", clear
		keep $idvarlist s6b_1 s6b_2 s6b_4 s6b_5
		rename s6b_1 measured
		rename s6b_2 whynotmeasured
		rename s6b_4 height
		rename s6b_5 weight
	
		tostring FPrimary, replace
	
		gen weightforheight = weight/height
		
		sort region district ea hhid hhmid
		replace hhmid = 1 if _n == 8549
		replace hhmid = 2 if _n == 8550
	
		save "$clean/wave_1/health6b.dta", replace
		
	use "$raw/wave_1/s6c.dta", clear
		keep $idvarlist s6c_1 s6c_2 s6c_9 s6c_12
		rename s6c_1 immunized
		rename s6c_2 bcgvax
		rename s6c_9 vaxfees
		rename s6c_12 whynotimmunized
		
		tostring FPrimary, replace
		
		save "$clean/wave_1/health6c.dta", replace
		
	use "$raw/wave_1/s6d.dta", clear
		keep $idvarlist s6d_1 s6d_4
		rename s6d_1 carryheavyload
		rename s6d_4 bathewithouthelp
		
		tostring FPrimary, replace
		
		save "$clean/wave_1/health6d.dta", replace
		
	use "$raw/wave_1/s6e.dta", clear
		keep $idvarlist s6e_1 s6e_2 s6e_3 s6e_4
		rename s6e_1 selfhealthrating
		rename s6e_2 footirritation
		rename s6e_3 tingling
		rename s6e_4 tobacco
		
		foreach var of varlist selfhealth foot tingling tobacco {
			replace `var' = 0 if `var' == 2
			replace `var' = 0 if `var' == .
		}
		
		gen physicalhealthscore = selfhealth + foot + tingling + tobacco
		
		tostring FPrimary, replace
		
		save "$clean/wave_1/health6e.dta", replace
	
	use "$clean/wave_1/health6a.dta", clear
		merge 1:1 FPrimary hhid hhmid using "$clean/wave_1/health6b.dta"
		drop _merge
		
		merge 1:1 FPrimary hhid hhmid using "$clean/wave_1/health6c.dta"
		drop _merge
		
		merge 1:1 FPrimary hhid hhmid using "$clean/wave_1/health6d.dta"
		drop _merge
		
		merge 1:1 FPrimary hhid hhmid using "$clean/wave_1/health6e.dta"
		drop _merge
	
		save "$clean/wave_1/W1_ALLPHYSICAL.dta", replace
	
********************************************************************************
* ---------------------------- MERGE WITH EDUCATION ----------------------------
********************************************************************************	
	* merge background & educ/lit
	use "$clean/wave_1/background_final.dta", clear
	
	merge 1:1 FPrimary hhid hhmid using "$clean/wave_1/educ_lit.dta"
	drop _merge
	
	save "$clean/wave_1/background_educ_lit.dta", replace
	
	* merge with shocks
	merge m:1 region district eacode using "$clean/wave_1/community/W1_ALLSHOCKS.dta"	// not matched: 7380 from master, 132 from using
	drop _merge
	
	save "$clean/wave_1/background_shocks_educlit.dta", replace 

* ----------------------------  RESTRICITNG BY AGE -----------------------------
/*	tab age_yrs if relationship == 3 													/* child ... only 85% >= 18 yrs */
	
	tab age_yrs if relationship == 5													// son/daughter-in-law ... 2 obs <= 14
	tab age_yrs if relationship == 6													// other relative ... all >= 14
	tab age_yrs if relationship == 8													// househelp ... 60% <= 14 , 83% <= 18
	tab age_yrs if relationship == 9													// non-relative ... 50% <= 14, 86% <= 18
	
	tab yearofbirth if age_yrs == 15 */
	
	drop if age_yrs > 15 | yearofbirth < 1994
	
	save "$final/wave_1/educlit.dta", replace
	
********************************************************************************
* ---------------------------- MERGE WITH EMPLOYMENT ---------------------------
********************************************************************************	
	* merge background & emp / unemp
	use "$clean/wave_1/background_final.dta", clear

	merge 1:1 FPrimary hhid hhmid using "$clean/wave_1/emp_unemp.dta"
	drop _merge
	
	* merge with shocks
	merge m:1 region district eacode using "$clean/wave_1/community/W1_ALLSHOCKS.dta"
	drop _merge
	
	save "$clean/wave_1/background_shocks_empunemp.dta", replace 
	
	* restrict ages
	drop if age_yrs > 15 | yearofbirth < 1994
	save "$final/wave_1/empeunemp.dta", replace

********************************************************************************
* ------------------------- MERGE WITH PHYSICAL HEALTH -------------------------
********************************************************************************
	* merge background & physical health
	use "$clean/wave_1/background_final.dta", clear

	merge 1:1 FPrimary hhid hhmid using "$clean/wave_1/W1_ALLPHYSICAL.dta"
	drop _merge
	
	* merge with shocks
	merge m:1 region district eacode using "$clean/wave_1/community/W1_ALLSHOCKS.dta"
	drop _merge
	
	save "$clean/wave_1/background_shocks_PH.dta", replace 
	
	* restrict ages
	drop if age_yrs > 15 | yearofbirth < 1994
	save "$final/wave_1/PH.dta", replace

********************************************************************************
* -------------------------- DESCRIPTIVE STATISTICS ----------------------------
********************************************************************************
	use "$final/wave_1/educlit.dta", clear
	
	global demographics gender maritalstatus agemarried ghanaian fathereduc ///
	mothereduc 
	
	gen shock = 0
	replace shock = 1 if shock_agri >= 1 | shock_town >= 1 | shock_crop >= 1
	
	dtable $demographics, by(shock)
	
	egen shockcttotal = rowtotal(shock_*)
	
	gen fewshocks = 0
	replace fewshocks = 1 if shockct <= 4
	
	gen someshocks = 0
	replace someshocks = 1 if shockct > 4 & shockct <= 16
	
	gen manyshocks = 0
	replace manyshocks = 1 if shockct > 16 & shockct <= 32
	
	gen lotsoshocks = 0
	replace lotsoshocks = 1 if shockct >= 33
	
	save "$final/wave_1/educlit.dta", replace

********************************************************************************
* ---------------------------- PRELIMINARY CHECKS ------------------------------
********************************************************************************
	use "$final/wave_1/educlit.dta", clear
	
	global shockct fewshocks someshocks manyshocks lotsoshocks
	global shock_types shock_agri shock_town shock_crop
	
	global hh_controls ghanaian nationality ethnicity religion fathereduc ///
	fatherwork mothereduc motherwork hhsize
	
	global indiv_controls gender yearofbirth relationship age_mos age_yrs
	
	global educ_controls readlang writelang readeng writeeng traveltime_hr
	
	global emp_controls employed formal self_employed 
	
	foreach hhcontrols of global hh_controls {
		foreach var of global shockct {
		ttest `hhcontrols', by(`var')
		}
	}
	
	foreach indiv of global indiv_controls {
		foreach var of global shockct {
		ttest `indiv', by(`var')
		}
	}
	
	foreach educ of global indiv_controls {
		foreach var of global shockct {
		ttest `educ', by(`var')
		}
	}
	
	foreach emp of global indiv_controls {
		foreach var of global shockct {
		ttest `emp', by(`var')
		}
	}

********************************************************************************
* ---------------------------- EXPLORATORY ANALYSIS  ---------------------------
********************************************************************************
	foreach var of varlist shock_agri_count shock_town_count shock_crop_count {
		reg `var' $hh_controls $indiv_controls $educ_controls $emp_controls ///
		i.region i.district i.eacode 
	}
	
* -------------------------------- EMPLOYMENT ----------------------------------
	foreach var of varlist formal paid earnedcedis earnedpessewas paidsick {
		reg `var' $shockct $hh_controls $indiv_controls $educ_controls $emp_controls ///
		i.region i.district i.eacode 
	}

* -------------------------------- EDUCATION -----------------------------------
	foreach var of varlist highestgrade classtime_hr absent_hr fees_cedis bookscedis  {
		reg `var' $shockct $hh_controls $indiv_controls $educ_controls $emp_controls ///
		i.region i.district i.eacode 
	}

* ------------------------------ PHYSICAL HEALTH -------------------------------
	foreach var of varlist weightforheight carryheavyload bathewithouthelp physicalhealthscore  {
		reg `var' $shockct $hh_controls $indiv_controls $educ_controls $emp_controls ///
		i.region i.district i.eacode 
	}
	
	
* ------------------------------------------------------------------------------	
log close
