//cleaning, variable setup of caregiver dataset from nsoc

capture log close
clear all
set more off

logs E:\nhats\nhats_code\NHATS data setup\logs
//local logs /Users/rebeccagorges/Documents/data/nhats/logs/
log using `logs'2_nsoc_nhats_cleaning1.txt, text replace

//PC file paths
local r1raw E:\nhats\data\NHATS Public\round_1\
local r2raw E:\nhats\data\NHATS Public\round_2\
local r3raw E:\nhats\data\NHATS Public\round_3\
local work E:\nhats\data\NHATS working data\
local r1s E:\nhats\data\NHATS Sensitive\r1_sensitive\
local r2s E:\nhats\data\NHATS Sensitive\r2_sensitive\
//Rebecca Mac file paths
/*local r1raw /Users/rebeccagorges/Documents/data/nhats/round_1/
local r2raw /Users/rebeccagorges/Documents/data/nhats/round_2/
local r3raw /Users/rebeccagorges/Documents/data/nhats/round_3/
local work /Users/rebeccagorges/Documents/data/nhats/working
local r1s /Users/rebeccagorges/Documents/data/nhats/r1_sensitive/
local r2s /Users/rebeccagorges/Documents/data/nhats/r2_sensitive/ 
*/
cd `work'

use caregiver_ds_nsoc_v1.dta, replace
******************************************************************
tab op1dnsoc, missing

//per nsoc user guide, use this weight when analysis is at the caregiver level
sum w1cgfinwgt0, detail //caregiver nsoc analytic weight

tab c1dgender, missing //caregiver gender
gen cg_female=1 if c1dgender==2
replace cg_female=0 if c1dgender==1
label var cg_female "Caregiver = female"
tab cg_female, missing

tab c1relatnshp, missing //caregiver relationship to SP
gen cg_relationship_cat=3
replace cg_relationship_cat=1 if c1relatnshp==2
replace cg_relationship_cat =2 if inlist(c1relatnshp,3,4,5,6,7,8)
la def rel 1 "Spouse" 2 "Adult child" 3 "Other"
la val cg_relationship_cat rel
la var cg_relationship_cat "Caregiver relationship"
tab cg_relationship_cat, missing

//ask about this, if want age categories, then fill in from categorical
//variable directly from nhats, don't use actual age
gen cg_age=op1age
replace cg_age=. if inlist(op1age,-8,-7,-1)
sum cg_age, detail

tab op1catgryage if cg_age==., missing

******************************************************************
//caregiver resides in same household, use OP reside in household flag
******************************************************************
******* Not complete, this section needs work! *********
******************************************************************
tab op1prsninhh, missing //caregiver in household
gen cg_lives_with_sp=1 if op1prsninhh==1
replace cg_lives_with_sp=0 if op1prsninhh==2
tab cg_lives_with_sp, missing
tab cg_lives_with_sp cg_relationship_cat, missing

tab op1proxy if cg_lives_with_sp==.
tab livearrang if cg_lives_with_sp==. & cg_relationship_cat==1, missing

//check hh1livwthspo (SP lives with spouse), needs to come from sp interview though
tab hh1livwthspo cg_lives_with_sp  if cg_relationship_cat==1

******************************************************************
//caregiver level of education
tab op1leveledu, missing
tab hh1spouseduc if op1leveledu==. & cg_relationship_cat==1, missing
******************************************************************
//caregiver health
tab che1health, missing //caregiver self reported health
gen cg_srh=che1health
replace cg_srh=. if che1health==-8 | che1health==-7
la val cg_srh srh
gen cg_srh_fp=1 if inlist(cg_srh,4,5)
replace cg_srh_fp=0 if inlist(cg_srh,1,2,3)
la var cg_srh "Caregiver self reported health 1-5"
la var cg_srh_fp "Caregiver SHR fair/poor"
tab cg_srh cg_srh_fp, missing

************************
//identify those that helped in last year  but not in last month
//excluded from HHS Informal Caregiving for Older Americans: Analysis of the 2011 NSOC
//April 2014 report dataset (n=11)
tab cca1hlplstyr, missing

***************************************************************
//identify care activities helped with
//household chores (laundry, cleaning, meal prep)
tab cca1hwoftchs, missing //how often help w/ hh chores
tab cca1hwoftshp, missing //how often help with shopping
tab cca1hlpordmd //ever help order rx
tab cca1hlpbnkng //ever help banking

tab cca1hwoftpc //how often personal care
tab cca1hwofthom //how often help getting around home or leaving home

tab cca1hwoftdrv //how often drive places
tab cca1hwoftott //how often went with on other transportation

//help medical care in the last month, yes/no
gen help_healthcare=0
foreach v in med shot mdtk exrcs diet teeth feet skin{
replace help_healthcare=1 if cca1hlp`v'==1
}
tab help_healthcare, missing

//help coordinate medical care with providers, insurance, etc? in last year
gen help_coordhc=0
foreach v in mdapt spkdr insrn othin{
replace help_coordhc=1 if cca1hlp`v'==1
}
tab help_coordhc, missing


************************
//save the dataset
save caregiver_ds_nsoc_clean_v2.dta, replace
************************
log close
