/*this file will execute all of the do files for the nhats data processing
to create the SP round 1, 2, 3 dataset

resulting dataset is organized with one row for each SP for each 
interview (so can have up to 3 rows per SP)*/

local dofilepath E:\data\nhats\Code\

/*merges individual datasets into single file with r1,2,3 interviews*/
do `dofilepath'1_combine_waves.do

/*performs helper hours imputations*/
do `dofilepath'1a_help_hours_imputation.do

/*starts r1,2,3 common variable creating/cleaning*/
do `dofilepath'2_r12_cleaning_1.do

/*continues r1,2,3 cleaning*/
do `dofilepath'3_r12_cleaning_2.do

/*Continues r1,2,3 cleaning*/
do `dofilepath'4_r12_cleaning_3.do

/*Merges in the helper details at the SP level*/
do `dofilepath'5_r12_add_helper.do
