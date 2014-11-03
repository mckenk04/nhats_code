capture log close
clear all
set more off

//local logs C:\data\nhats\logs
local logs /Users/rebeccagorges/Documents/data/nhats/logs
log using `logs'\1_nhats_setup1.txt, text replace

//local r1raw C:\data\nhats\round_1
//local r2raw C:\data\nhats\round_2
//local work C:\data\nhats\working

local r1raw /Users/rebeccagorges/Documents/data/nhats/round_1
local r2raw /Users/rebeccagorges/Documents/data/nhats/round_2
local work /Users/rebeccagorges/Documents/data/nhats/working

cd `work'
*********************************************

//round 1
//use `r1raw'\NHATS_Round_1_SP_File.dta
use `r1raw'/NHATS_Round_1_SP_File.dta
//check to make sure sample ids are unique
sort spid 
quietly by spid: gen dup = cond(_N==1,0,_n)
tab dup
gen wave=1
la var wave "Survey wave"
save round_1_1.dta, replace
clear

//round 2
//use `r2raw'\NHATS_Round_2_SP_File_v2.dta
use `r2raw'/NHATS_Round_2_SP_File_v2.dta
//check to make sure sample ids are unique
sort spid 
quietly by spid: gen dup = cond(_N==1,0,_n)
tab dup
gen wave=2
la var wave "Survey wave"
save round_2_1.dta, replace
clear 

//drop variables not needed
local keepallwaves spid wave r`w'dresid w`w'varunit w`w'anfinwgt0 w`w'varstrat  ///
	mo`w'out* r`w'd2intvrage hh`w'martlstat ///
	ia`w'toincim1-ia`w'toincim5 ip`w'cmedicaid rl`w'spkothlan re`w'resistrct ///
	hh`w'dlvngarrg hh`w'dhshldnum hc`w'health hc`w'disescn1-hc`w'disescn10 ///
	hc`w'depresan* is`w'resptype cp`w'chgthink* cg`w'speaktosp cg`w'todaydat* ///
	cg`w'presidna* cg`w'vpname* cg`w'dclkdraw cg`w'dwrdimmrc cg`w'dwrddlyrc ///
	hc`w'brokebon1 hc`w'fllsinmth sc`w'deathelp sc`w'dbathhelp sc`w'dtoilhelp ///
	sc`w'ddreshelp mc`w'havregdoc mc`w'regdoclyr mc`w'hwgtregd8 hc`w'hosptstay ///
	hc`w'hosovrnht
	
//round 1
foreach w in 1 2{
use round_`w'_1.dta

local keepallwaves spid wave r`w'dresid w`w'varunit w`w'anfinwgt0 w`w'varstrat  ///
	mo`w'out* r`w'd2intvrage hh`w'martlstat ///
	ip`w'cmedicaid  ///
	hh`w'dlvngarrg hh`w'dhshldnum hc`w'health hc`w'disescn1-hc`w'disescn10 ///
	hc`w'depresan* is`w'resptype cp`w'chgthink* cg`w'speaktosp cg`w'todaydat* ///
	cg`w'presidna* cg`w'vpname* cg`w'dclkdraw cg`w'dwrdimmrc cg`w'dwrddlyrc ///
	hc`w'brokebon1 hc`w'fllsinmth sc`w'deathelp sc`w'dbathhelp sc`w'dtoilhelp ///
	sc`w'ddreshelp mc`w'havregdoc mc`w'regdoclyr mc`w'hwgtregd8 hc`w'hosptstay ///
	hc`w'hosovrnht

if `w'==1 {	
keep `keepallwaves' r`w'dgender rl`w'dracehisp rl`w'spkothlan el`w'higstschl ///
ia`w'toincim1-ia`w'toincim5 re`w'resistrct
}

if `w'==2 {	
keep `keepallwaves' re2intplace re2newstrct
}

save round_`w'_ltd.dta, replace
}

/*variables I'll need to pull once I get the sensitive dataset
r`w'dintvwrage
*/

//combine 2 waves into single dataset
use round_1_ltd.dta
append using round_2_ltd.dta
save round_1_2.dta, replace

*********************************************
log close
