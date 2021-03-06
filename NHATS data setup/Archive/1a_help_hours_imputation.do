/*this section uses the SP and OP R1,2&3 data files and imputes
hours of help provided to SP per methods in NHATS Technical Paper #7

Variables from this dataset are then brought in to the SP R 1,2,3 dataset
and also the NSOC caregiver dataset*/

capture log close
clear all
set more off

local logs E:\nhats\nhats_code\NHATS data setup\logs
//local logs /Users/rebeccagorges/Documents/data/nhats/logs/
log using "`logs'1a-help_hours_imputation-LOG.txt", text replace

//PC file paths
local r1raw "E:\nhats\data\NHATS Public\round_1\"
local r2raw "E:\nhats\data\NHATS Public\round_2\"
local r3raw "E:\nhats\data\NHATS Public\round_3\"
local r4raw "E:\nhats\data\NHATS PUBLIC\round_4\"
local work "E:\nhats\data\NHATS working data\"
local r1s "E:\nhats\data\NHATS Sensitive\r1_sensitive\"
local r2s "E:\nhats\data\NHATS Sensitive\r2_sensitive\"
local r3s "E:\nhats\data\NHATS Sensitive\r3_sensitive\"
local r4s "E:\nhats\data\NHATS Sensitive\r4_sensitive\"

/* //Rebecca mac file paths
local r1raw /Users/rebeccagorges/Documents/data/nhats/round_1/
local r2raw /Users/rebeccagorges/Documents/data/nhats/round_2/
local r3raw /Users/rebeccagorges/Documents/data/nhats/round_3/
local work /Users/rebeccagorges/Documents/data/nhats/working
local r1s /Users/rebeccagorges/Documents/data/nhats/r1_sensitive/
local r2s /Users/rebeccagorges/Documents/data/nhats/r2_sensitive/ 
 */
 
cd "`work'"

**User note: This section can be commented out after run one time to set up datasets
********************************************************************
//combine op and sp data files
//round 1
use "`r1raw'NHATS_Round_1_OP_File_v2.dta", clear
sort spid opid 

merge m:1 spid using round_1_1.dta //bring in sorted sp ivw dataset
keep if _merge==3 //drop obs with no OP entries
save R1_OPSPlinked.dta, replace

//round 2
use "`r2raw'NHATS_Round_2_OP_File_v2.dta", clear
sort spid opid

merge m:1 spid using round_2_1.dta //bring in sorted sp ivw dataset
keep if _merge==3 //drop obs with no OP entries
save R2_OPSPlinked.dta, replace

//round 3
use "`r3raw'NHATS_Round_3_OP_File.dta", clear
sort spid opid

merge m:1 spid using round_3_1.dta //bring in sorted sp ivw dataset
keep if _merge==3 //drop obs with no OP entries
save R3_OPSPlinked.dta, replace

//round 4
use "`r4raw'NHATS_Round_4_OP_File.dta", clear
sort spid opid

merge m:1 spid using round_4_1.dta //bring in sorted sp ivw dataset
keep if _merge==3 //drop obs with no OP entries
save R4_OPSPlinked.dta, replace


foreach w in 1 2 3 4{
	use R`w'_OPSPlinked.dta
	
//now create limited datasets for each wave with only needed variables
local keeplist spid op* wave  w`w'anfinwgt0 w`w'varstrat w`w'varunit r`w'dresid ///
 mo`w'douthelp mo`w'dinsdhelp mo`w'dbedhelp sc`w'deathelp sc`w'dbathhelp ///
 sc`w'dtoilhelp sc`w'ddreshelp ha`w'dlaunreas ha`w'dshopreas ha`w'dmealreas ///
 ha`w'dbankreas mc`w'dmedsreas
 
	keep `keeplist'
	save R`w'_OPSPltd.dta, replace
}

********************************************************************
//merge into single file for initial setup
use R1_OPSPltd.dta, clear
append using R2_OPSPltd.dta
append using R3_OPSPltd.dta
append using R4_OPSPltd.dta

save R1234_OPSPltd.dta, replace
********************************************************************
use R1234_OPSPltd.dta, clear

tab wave, missing

********************************************************************
//recode helper time variables to -1 (na) if not helper per flag variable
**Note, these OP variables are backfilled from wave to wave
gen opishelper_allw=.
foreach w in 1 2 3 4{
tab op`w'ishelper wave, missing //helper flag variable
replace opishelper_allw=op`w'ishelper if wave==`w'
}
tab opishelper_allw wave, missing

foreach w in 1 2 3 4{
	foreach v in op`w'helpsched op`w'numdayswk op`w'numdaysmn op`w'numhrsday {
		tab `v' if op`w'ishelper==-1 & wave==`w', missing
		replace `v'=-1 if op`w'ishelper==-1 & wave==`w'
	}
}
//generate indicator of help with any task that has monthly reference period
gen month=.
foreach w in 1 2 3 4{
replace month=0 if wave==`w'
replace month=1 if (op`w'outhlp==1 | op`w'insdhlp==1 | op`w'bedhlp==1 | ///
 op`w'tkplhlp1==1 | op`w'tkplhlp2==1 | op`w'launhlp==1 | op`w'shophlp==1 | ///
 op`w'mealhlp==1 | op`w'bankhlp==1 | op`w'eathlp==1 | op`w'bathhlp==1 | ///
 op`w'toilhlp==1 | op`w'dreshlp==1 | op`w'medshlp==1) & wave==`w'
} 
tab month wave, missing

 //generate indicator of help with any task that has yearly reference period
gen year=.
foreach w in 1 2 3 4{
replace year=0 if wave==`w'
replace year=1 if (op`w'moneyhlp==1 | op`w'dochlp==1 | op`w'insurhlp==1) & wave==`w'
tab year month if wave==`w', missing
}

//generate indicator of help in last year but not last month
gen yearnotmonth=0
replace yearnotmonth=1 if year==1 & month==0
tab yearnotmonth wave, missing

********************************************************************
//generate SP received help with self care or mobility activity or 
//household activity for health and functioning reasons
gen disab=.
foreach w in 1 2 3 4{
replace disab=0 if wave==`w'
//self care or mobility, assumed to be for health reasons
replace disab=1 if (mo`w'douthelp==2 | mo`w'dinsdhelp==2 | mo`w'dbedhelp==2 | ///
 sc`w'deathelp==2 | sc`w'dbathhelp==2 | sc`w'dtoilhelp==2 | sc`w'ddreshelp==2) & wave==`w'
//household activity for health or functioning reasons or in residential care
**note this is different from tech paper #7 because codes disab=1 if 1,3 or 4
**not just if 3 or 4
foreach v in ha`w'dlaunreas ha`w'dshopreas ha`w'dmealreas ha`w'dbankreas mc`w'dmedsreas{
replace disab=1 if inlist(`v',1,3,4) & wave==`w'
}
}
tab disab wave, missing

********************************************************************
//flag variable for hours/month reported, valid
tab op1dhrsmth wave, missing //derived hours/month from HL section
gen op_ind_hrsmth=.
foreach w in 1 2 3 4{
replace op_ind_hrsmth=op`w'dhrsmth if wave==`w'
}
recode op_ind_hrsmth (1/750=1)

la def hrsmth -13"-13:Deceased" -12"Zero days/wk" -11"-11:hours missing" ///
 -10"-10:days missing" -9 "-9:days+hours mssing" -1"-1:NA" 1"1:Valid" 9999"9999:<1hr/day",replace
la val op_ind_hrsmth hrsmth 
tab op_ind_hrsmth wave, missing

//generate variable indicating one day per month or one day per week
gen justone=.
foreach w in 1 2 3 4{
replace justone=0 if wave==`w'
replace justone=1 if (op`w'numdayswk==1 | op`w'numdaysmn==1) & wave==`w'
}
tab justone op_ind_hrsmth, missing

//recode help flags to 0=(no or inapplicable) or 1=yes
foreach w in 1 2 3 4{
foreach v in op`w'outhlp op`w'insdhlp op`w'bedhlp op`w'tkplhlp1 op`w'tkplhlp2 op`w'launhlp ///
 op`w'shophlp op`w'mealhlp op`w'bankhlp op`w'eathlp op`w'bathhlp op`w'toilhlp op`w'dreshlp ///
 op`w'medshlp op`w'moneyhlp op`w'dochlp op`w'insurhlp{
tab `v' if wave==`w', missing
replace `v'=0 if `v'==-1 & wave==`w'
}
}

//generate variable indicating help with only one activity
gen numact=.
foreach w in 1 2 3 4{
replace numact=op`w'outhlp + op`w'insdhlp + op`w'bedhlp + op`w'tkplhlp1 + op`w'tkplhlp2 + ///
 op`w'launhlp + op`w'shophlp + op`w'mealhlp + op`w'bankhlp + op`w'eathlp + op`w'bathhlp + ///
 op`w'toilhlp + op`w'dreshlp + op`w'medshlp + op`w'moneyhlp + op`w'dochlp + op`w'insurhlp if wave==`w'
}

tab numact wave, missing
gen oneact=0 //note this =0 if help with no activities
replace oneact=1 if numact==1
tab oneact opishelper_allw, missing

********************************************************************
//generate variables indicating relationship is spouse, other rel, other nonrel
gen spouse=.
gen otherrel=.
gen nonrel=.

foreach w in 1 2 3 4{
replace spouse=0 if wave==`w'
replace spouse=1 if op`w'relat==2 & wave==`w'
replace otherrel=0 if wave==`w'
replace otherrel=1 if ((op`w'relat>2 & op`w'relat<=29) | op`w'relat==91) & wave==`w'
replace nonrel=0 if wave==`w'
replace nonrel=1 if (op`w'relat>=30 & op`w'relat~=91) & wave==`w'

tab op`w'relat spouse
tab op`w'relat otherrel
tab op`w'relat nonrel

}

tab spouse wave, missing
tab otherrel wave, missing
tab nonrel wave, missing

********************************************************************
//generate variables indicating help on a regular schedule
gen regular=.
foreach w in 1 2 3 4{
replace regular=0 if wave==`w'
replace regular=1 if op`w'helpsched==1 & wave==`w'
}
tab regular wave, missing

la def hrsmth -13"-13:Deceased" -12"-12:Zero days/wk" -11"-11:hours missing" ///
 -10"-10:days missing" -9 "-9:days+hours mssing" -1"-1:NA" 1"1:Valid" 9999"9999:<1hr/day",replace
la val op_ind_hrsmth hrsmth 

tab op_ind_hrsmth wave

tab op_ind_hrsmth yearnotmonth if wave==1 & opishelper_allw==1
tab op_ind_hrsmth yearnotmonth if wave==2 & opishelper_allw==1

tab opishelper_allw

//generate indicator of imputation category
//1=impute, 2=recode to zero, 3=recode to small number hrs/day, 4=no imputation needed
gen impute_cat=-1

//wave=1
	//1=impute
	replace impute_cat=1 if inlist(op_ind_hrsmth,-11,-10) | ///
	(op_ind_hrsmth==-9 & yearnotmonth==0) & op1ishelper==1 & wave==1
	replace impute_cat=1 if op_ind_hrsmth==9999 & (op1numdayswk==1 | op1numdaysmn==1) ///
	 & yearnotmonth==0 & op1ishelper==1 & wave==1
	//2=recode to zero
	replace impute_cat=2 if op_ind_hrsmth==-9 & yearnotmonth==1 & op1ishelper==1 & wave==1
	replace impute_cat=2 if op_ind_hrsmth==9999 & (op1numdayswk==1 | op1numdaysmn==1) ///
	& yearnotmonth==1 & op1ishelper==1 & wave==1
	//3=set to small number
	replace impute_cat=3 if op_ind_hrsmth==9999 & ///
	(op1numdayswk~=1 & op1numdaysmn~=1) & op1ishelper==1 & wave==1
	//4=imputation not necessary, complete info
	replace impute_cat=4 if op_ind_hrsmth==1 & op1ishelper==1 & wave==1

//if wave==2 | wave==3 | wave == 4
	//1=impute, wave 2,3 criteria
	replace impute_cat=1 if inlist(op_ind_hrsmth,-11,-9) & opishelper_allw==1 & inlist(wave,2,3,4)
	replace impute_cat=1 if op_ind_hrsmth==-12 & yearnotmonth==0 & opishelper_allw==1 & inlist(wave,2,3,4)
	//2=recode to zero, wave 2, 3
	replace impute_cat=2 if op_ind_hrsmth==-12 & yearnotmonth==1 & opishelper_allw==1 & inlist(wave,2,3,4)
	//3=recode to small number
	replace impute_cat=3 if op_ind_hrsmth==9999 & opishelper_allw==1 & inlist(wave,2,3,4)
	//4=imputation not necessary
	replace impute_cat=4 if op_ind_hrsmth==1 & opishelper_allw==1 & inlist(wave,2,3,4)

la def impute_cat -1"N/A, not helper" 1"Impute" 2"Recode to zero" ///
3"Recode to small number" 4"No imputation needed"
la val impute_cat impute_cat
tab impute_cat wave, missing

tab impute_cat op_ind_hrsmth if wave==1, missing
tab impute_cat op_ind_hrsmth if wave==2, missing
tab impute_cat op_ind_hrsmth if wave==3, missing
tab impute_cat op_ind_hrsmth if wave==4, missing

********************************************************************
//save separate datasets for r 1 2 & 3 so can run imputation with weighting
foreach w in 1 2 3 4{
preserve
keep op* wave numact yearnotmonth disab w`w'anfinwgt0 w`w'varstrat w`w'varunit ///
 r`w'dresid spid justone spouse otherrel nonrel regular oneact impute_cat
keep if wave==`w'
save R`w'_for_hrs_impute.dta,replace
restore
}
*/
********************************************************************
//implement matching, do separately for each wave
foreach w in 1 2 3 4{
use R`w'_for_hrs_impute.dta, clear

svyset w`w'varunit [pweight=w`w'anfinwgt0], strata(w`w'varstrat)

//wave 1 imputation... need to check what is different if anything for wave 2
gen op_hrsmth_i=0
replace op_hrsmth_i=op`w'dhrsmth if impute_cat==4  //use actual value
replace op_hrsmth_i=0 if impute_cat==2 //set to zero
replace op_hrsmth_i=(.5*op`w'numdayswk*4.3) if impute_cat==3 & op`w'helpsched==1 //assign small hours
replace op_hrsmth_i=(.5*op`w'numdaysmn) if impute_cat==3 & inlist(op`w'helpsched,2,-7,-8)  //assign small hours

//impute where op_ind_hrsmth=-10, missing days per month
gen op_numdays_i=0
replace op_numdays_i=op`w'numdayswk*4.3 if inlist(impute_cat,3,4) & op`w'helpsched==1
replace op_numdays_i=op`w'numdaysmn if inlist(impute_cat,3,4) & inlist(op`w'helpsched,2,-7,-8)

gen ln_opnumdays_i=ln(op_numdays_i) if inlist(impute_cat,3,4)

local adjvars spouse otherrel regular yearnotmonth oneact disab ///
 op`w'outhlp op`w'insdhlp op`w'bedhlp op`w'tkplhlp1 op`w'tkplhlp2 op`w'launhlp ///
 op`w'shophlp op`w'mealhlp op`w'bankhlp op`w'eathlp op`w'bathhlp op`w'toilhlp ///
 op`w'dreshlp op`w'medshlp op`w'moneyhlp op`w'dochlp op`w'insurhlp

svy: reg ln_opnumdays_i `adjvars' if inlist(impute_cat,3,4)
predict ln_opnumdays_i2 if impute_cat==1 & op_ind_hrsmth==-10
gen op_numdays_i2=exp(ln_opnumdays_i2) if impute_cat==1 & op_ind_hrsmth==-10
replace op_hrsmth_i= op_numdays_i2*op`w'numhrsday if impute_cat==1 & ///
 op_ind_hrsmth==-10 & op`w'numhrsday>=1
replace op_hrsmth_i= op_numdays_i2*.5 if impute_cat==1 & ///
 op_ind_hrsmth==-10 & op`w'numhrsday==0

//impute where op_ind_hrsmth=-11, missing hours per day
gen op_numhrsday_i=0
replace op_numhrsday_i=.5 if impute_cat==3
replace op_numhrsday_i=op`w'numhrsday if impute_cat==4
gen ln_opnumhrsday_i=ln(op_numhrsday_i) if inlist(impute_cat,3,4)
svy: reg ln_opnumhrsday_i `adjvars' if inlist(impute_cat,3,4)
predict ln_opnumhrsday_i2 if impute_cat==1 & op_ind_hrsmth==-11
gen op_numhrsday_i2=exp(ln_opnumhrsday_i2) if impute_cat==1 & op_ind_hrsmth==-11
replace op_hrsmth_i=op`w'numdayswk*4.3*op_numhrsday_i2 if impute_cat==1 & ///
 op_ind_hrsmth==-11 & op`w'helpsched==1
replace op_hrsmth_i=op`w'numdaysmn*op_numhrsday_i2 if impute_cat==1 & ///
 op_ind_hrsmth==-11 & inlist(op`w'helpsched,2,-7,-8) & op`w'numdaysmn>=1
replace op_hrsmth_i=op`w'numdayswk*4.3*op_numhrsday_i2 if impute_cat==1 & ///
 op_ind_hrsmth==-11 & inlist(op`w'helpsched,2,-7,-8) & ///
 op`w'numdaysmn<1 & op`w'numdayswk>=1 

//impute where op_ind_hrsmth=-9, -12 or 9999, missing hours and days or <1hr/day
gen ln_opdhrsmth_i=ln(op_hrsmth_i) if inlist(impute_cat,3,4)
svy: reg ln_opdhrsmth_i `adjvars' if inlist(impute_cat,3,4)
predict ln_opdhrsmth_i2 if impute_cat==1 & inlist(op_ind_hrsmth,-9,-12,9999)
gen op_hrsmth_i2=exp(ln_opdhrsmth_i2) if impute_cat==1 & inlist(op_ind_hrsmth,-9,-12,9999)
replace op_hrsmth_i=op_hrsmth_i2 if impute_cat==1 & inlist(op_ind_hrsmth,-9,-12,9999)
replace op_hrsmth_i=-1 if op`w'ishelper~=1 

//look at imputed hours per month by imputation category
di "where op_ind_hrsmth==-12"
capture noisily: mean op_hrsmth_i if impute_cat==1 & op_ind_hrsmth==-12 [pweight=w`w'anfinwgt0]
di "where op_ind_hrsmth==-11"
mean op_hrsmth_i if impute_cat==1 & op_ind_hrsmth==-11 [pweight=w`w'anfinwgt0]
di "where op_ind_hrsmth==-10"
capture noisily: mean op_hrsmth_i if impute_cat==1 & op_ind_hrsmth==-10 [pweight=w`w'anfinwgt0]
di "where op_ind_hrsmth==-9"
mean op_hrsmth_i if impute_cat==1 & op_ind_hrsmth==-9 [pweight=w`w'anfinwgt0] 
di "where op_ind_hrsmth==9999"
capture noisily: mean op_hrsmth_i if impute_cat==1 & op_ind_hrsmth==9999 [pweight=w`w'anfinwgt0] 

di "impute_cat==2"
mean op_hrsmth_i if op_hrsmth_i~=-1 & impute_cat==2 [pweight=w`w'anfinwgt0]
di "impute_cat==3"
mean op_hrsmth_i if op_hrsmth_i~=-1 & impute_cat==3 [pweight=w`w'anfinwgt0]
di "impute_cat==4"
mean op_hrsmth_i if op_hrsmth_i~=-1 & impute_cat==4 [pweight=w`w'anfinwgt0]

save R`w'_hrs_imputed_added.dta,replace

}

********************************************************************
log close
