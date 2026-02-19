*05_mechanisms.do
*Mechanism analysis and regional heterogeneity

clear all
set more off
cap log close
log using "${code}\05_mechanisms.log", replace text


use "${output}\analysis_data.dta", clear
xtset cityid year

keep if year >= 2010 & year <= 2023
drop if year == 2017

global controls "ln_gdppc ln_pop fin_depth ln_fiscal ln_wage"

*PSM weights
preserve
    keep if year == 2015
    logit treat $controls
    predict pscore, p
    psmatch2 treat, pscore(pscore) kernel outcome(service_share) common
    keep cityid _weight
    rename _weight kernel_weight
    tempfile psm_w
    save `psm_w', replace
restore

merge m:1 cityid using `psm_w'
keep if _merge == 3
drop _merge
keep if kernel_weight != . & kernel_weight > 0

gen Post = (year >= 2016)
gen DID  = treat * Post

tempfile working
save `working'


*Mechanism regressions (Table 5)

*Industry share (seesaw)
reghdfe industry_share DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store mech_ind

*FDI
reghdfe ln_fdi DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store mech_fdi

*Industrial profits
reghdfe ln_profit DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store mech_profit

*Real estate investment
reghdfe ln_re_inv DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store mech_re

*Retail consumption
reghdfe ln_retail DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store mech_retail

esttab mech_ind mech_fdi mech_profit mech_re mech_retail ///
    using "${code}\tables\Table5_Mechanisms.rtf", replace ///
    keep(DID) b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("N Observations") ///
    title("Table 5: Mechanisms") ///
    mtitles("Ind share" "ln(FDI)" "ln(Profit)" "ln(RE)" "ln(Retail)")


*FDI extensive margin (Table 6)
*Enterprise counts from separate prefecture database

use "${raw}\enterprise_data.dta", clear
keep cityid year n_foreign n_hkt fdi_actual

gen n_foreign_total = n_foreign + n_hkt
gen ln_n_foreign       = ln(n_foreign + 1)
gen ln_n_hkt           = ln(n_hkt + 1)
gen ln_n_foreign_total = ln(n_foreign_total + 1)
gen ln_fdi_actual      = ln(fdi_actual + 1)

duplicates drop cityid year, force

tempfile ent_data
save `ent_data'

use `working', clear
merge 1:1 cityid year using `ent_data', keep(1 3) nogen

reghdfe ln_n_foreign DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store fdi_foreign

reghdfe ln_n_hkt DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store fdi_hkt

reghdfe ln_n_foreign_total DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store fdi_total

reghdfe ln_fdi_actual DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store fdi_actual

esttab fdi_foreign fdi_hkt fdi_total fdi_actual ///
    using "${code}\tables\Table6_FDI.rtf", replace ///
    keep(DID) b(4) se(4) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("N Observations" "r2_a Adj R-sq") ///
    title("Table 6: FDI Extensive Margin") ///
    mtitles("ln(Foreign)" "ln(HKT)" "ln(Total)" "ln(FDI Actual)")


*Regional heterogeneity (Table 7)

use `working', clear

reghdfe service_share DID $controls [pw = kernel_weight] ///
    if region == "East", absorb(cityid year) vce(cluster cityid)
est store het_east

reghdfe service_share DID $controls [pw = kernel_weight] ///
    if region == "Central", absorb(cityid year) vce(cluster cityid)
est store het_central

reghdfe service_share DID $controls [pw = kernel_weight] ///
    if region == "West", absorb(cityid year) vce(cluster cityid)
est store het_west

reghdfe service_share DID $controls [pw = kernel_weight] ///
    if region == "Northeast", absorb(cityid year) vce(cluster cityid)
est store het_ne

*Northeast + city trends
reghdfe service_share DID $controls [pw = kernel_weight] ///
    if region == "Northeast", ///
    absorb(cityid year cityid#c.year) vce(cluster cityid)
est store het_ne_trend

esttab het_east het_central het_west het_ne ///
    using "${code}\tables\Table7_Heterogeneity.rtf", replace ///
    keep(DID) b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("N Observations") ///
    title("Table 7: Regional Heterogeneity") ///
    mtitles("East" "Central" "West" "Northeast")


log close