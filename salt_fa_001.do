** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name			        salt_fa_001.do
    //  project:				        Health of the Nation (HotN)
    //  analysts:				       	Ian HAMBLETON
    // 	date last modified	            09-MAY-2019
    //  algorithm task			        Reading the SALT dataset. Initial preparation. Initial Factor Analysis.

    ** General algorithm set-up
    version 15
    clear all
    macro drop _all
    set more 1
    set linesize 80

    ** Set working directories: this is for DATASET and LOGFILE import and export
    ** DATASETS to encrypted SharePoint folder
    local datapath "X:/The University of the West Indies/DataGroup - repo_data/data_p128"
    ** LOGFILES to unencrypted OneDrive folder (.gitignore set to IGNORE log files on PUSH to GitHub)
    local logpath X:/OneDrive - The University of the West Indies/repo_datagroup/repo_p128

    ** Close any open log file and open a new log file
    capture log close
    log using "`logpath'\salt_fa_001", replace
** HEADER -----------------------------------------------------



** ------------------------------------------------------------
** FILE 1 - DATA PREPARATION
** ------------------------------------------------------------
use "`datapath'/version01/2-working/salt_foodgroups.dta" ,clear
tab foodcat ,m

** Keep selected variables
keep pid id subject ed region sex agey educ occg whotn_ad grams calories energykj  foodgroup foodcat cat_fact foodname_original 
order pid id subject ed region sex agey educ occg whotn_ad grams calories energykj  foodgroup foodcat cat_fact foodname_original 
label var pid "Unique participant identifier"
label var id "ID from original NutriBase file"
label var ed "Survey enumeration district"
label var region "Survey region"
label var sex "participanr sex. 1=F. 2=M"
label var agey "Age in years at survey administration"
label var educ "Level of education"
label var occg "Major occupational groups (9 groups)"
label var whotn_ad "Survey weight"
label var grams "Grams of food item recalled"
label var calories "Calories of food item recalled"
label var energykj "Energy of food item recalled"
label var subject "Day of 24-hour recall"
label var foodgroup "56 Food Groups"
label var foodcat "33 Food Categories"
label var cat_fact "31 Food categories"
label var foodname_original "Original name of food from NutriBase"


** Preparation
** We want a WIDE dataset with grams/day for EACH of the THIRTY (?) food categories
drop if cat_fact==.
** Mean grams for each 24-hour recall day, by participant and food category 
collapse(sum) grams , by(subject pid cat_fact)
**  Mean grams across both 24-hour recall days, by participant and food category
collapse(mean) grams , by(pid cat_fact) 

** Descriptive
forval x = 1(1)30 { 
    ameans grams if cat_fact==`x'
}




** Reshape to WIDE, ready for Factor Analytics
rename cat_fact fcat 
label var fcat "30 Food categories"
tab fcat 
reshape wide grams, i(pid) j(fcat) 
label var grams1 "poultry"
label var grams2 "fried chicken"
label var grams3 "dairy hi-fat"
label var grams4 "dairy lo-fat"
label var grams5 "refined grains"
label var grams6 "whole grains"
label var grams7 "french fries"
label var grams8 "ground provisions"
label var grams9 "macaroni pie"
label var grams10 "rice and peas"
label var grams11 "vegetables"
label var grams12 "fruit"
label var grams13 "fried fish"
label var grams14 "unfried fish"
label var grams15 "red meat"
label var grams16 "processed meat"
label var grams17 "eggs"
label var grams18 "cake/sweetbread"
label var grams19 "snacks"
label var grams20 "nuts"
label var grams21 "legumes"
label var grams22 "butter/oils"
label var grams23 "condiments"
label var grams24 "soy"
label var grams25 "candy/chocolate"
label var grams26 "sugar"
label var grams27 "non-SSB"
label var grams28 "SSB"
label var grams29 "alcohol"
label var grams30 "hydrogenated fats"

** Replace missing categories with 0 grams - not eaten 
foreach var in grams1 grams2 grams3 grams4 grams5 grams6 grams7 grams8 grams9 grams10 ///
               grams11 grams12 grams13 grams14 grams15 grams16 grams17 grams18 grams19 grams20 ///
               grams21 grams22 grams23 grams24 grams25 grams26 grams27 grams28 grams29 grams30 {
    replace `var'=0 if `var'==.
} 

** Proportion of empty categories
forval x = 1(1)30 {
    gen empty`x' = 0
    replace empty`x'=1 if grams`x'==0
    tab empty`x'
}

** Initial Factor Analysis
drop if grams29>6000 
factor grams1-grams30,factors(6) blanks(0.25)
rotate,  blanks(0.25) normalize
** estat factors
** loadingplot 
** scoreplot, mlabel(pid) aspect(1)

