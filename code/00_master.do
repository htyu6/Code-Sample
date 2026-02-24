* Environmental Regulation and Industrial Composition
* Master File
*
* Required reghdfe, psmatch2, coefplot, estout, ftools, boottest
* Install ssc install [package]

clear all
set more off

*Paths (adjust to your)
global root     "D:\Pre-Doc\Code Sample"
global raw      "${root}\data\raw"
global output   "${root}\data\output"
global code     "${root}\code"

cap mkdir "${output}"
cap mkdir "${code}\tables"
cap mkdir "${code}\figures"

do "${code}\01_clean_merge.do"
do "${code}\02_create_analysis.do"
do "${code}\03_main_analysis.do"
do "${code}\04_robustness.do"
do "${code}\05_mechanisms.do"
do "${code}\06_extensions.do"
