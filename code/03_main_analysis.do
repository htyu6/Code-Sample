*03_main_analysis.do
*PSM-DID and event study

clear all
set more off
cap log close
log using "${code}\03_main_analysis.log", replace text


*Load data
use "${output}\analysis_data.dta", clear
xtset cityid year

*Drop census revision year
keep if year >= 2010 & year <= 2023
drop if year == 2017

global controls "ln_gdppc ln_pop fin_depth ln_fiscal ln_wage"


*Kernel PSM weights (2015 cross-section)
preserve
    keep if year == 2015

    logit treat $controls
    predict pscore, p

    psmatch2 treat, pscore(pscore) kernel outcome(service_share) common

    keep cityid _weight
    rename _weight kernel_weight
    tempfile psm_weights
    save `psm_weights', replace
restore

merge m:1 cityid using `psm_weights'
keep if _merge == 3
drop _merge
keep if kernel_weight != . & kernel_weight > 0

gen Post = (year >= 2016)
gen DID  = treat * Post


*Main DID (Table 1)

*(1)FE only
reghdfe service_share DID [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store main1

*(2)Basic controls
reghdfe service_share DID ln_gdppc ln_pop [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store main2

*(3)Full controls
reghdfe service_share DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store main3

esttab main1 main2 main3 ///
    using "${code}\tables\Table1_Main.rtf", replace ///
    keep(DID ln_gdppc ln_pop fin_depth ln_fiscal ln_wage) ///
    b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("N Observations" "r2_a Adj R-squared") ///
    title("Table 1: Main Results") ///
    mtitles("(1)" "(2)" "(3)") ///
    addnotes("City and year FE. SE clustered at city level.")


*Event study(Figure 1)

cap drop pre_* post_*
gen event_time = year - 2016

forvalues k = 6(-1)3 {
    gen pre_`k' = treat * (event_time == -`k')
}
forvalues k = 0/7 {
    gen post_`k' = treat * (event_time == `k')
}

*Base period: k = -2 omitted
reghdfe service_share pre_6 pre_5 pre_4 pre_3 ///
    post_0 post_1 post_2 post_3 post_4 post_5 post_6 post_7 ///
    $controls [pw = kernel_weight], absorb(cityid year) vce(cluster cityid)
est store event_main

*Parallel trends
test pre_6 pre_5 pre_4 pre_3
test pre_4 pre_3

coefplot event_main, ///
    keep(pre_6 pre_5 pre_4 pre_3 ///
         post_0 post_1 post_2 post_3 post_4 post_5 post_6 post_7) ///
    vertical recast(connected) ciopts(recast(rcap)) ///
    yline(0, lcolor(red) lpattern(dash)) ///
    xline(4.5, lcolor(gray) lpattern(dash)) ///
    xtitle("Year (relative to policy)") ///
    ytitle("Effect on Service Sector Share (pp)") ///
    note("Base period: k = -2. Kernel PSM-DID. 95% CI.") ///
    msymbol(circle_hollow) graphregion(color(white)) bgcolor(white)

graph export "${code}\figures\Figure1_EventStudy.png", replace width(1200)

esttab event_main using "${code}\tables\Table2_EventStudy.rtf", replace ///
    keep(pre_6 pre_5 pre_4 pre_3 ///
         post_0 post_1 post_2 post_3 post_4 post_5 post_6 post_7) ///
    b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    title("Table 2: Event Study") mtitles("Service Share")


log close
