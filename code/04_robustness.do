*04_robustness.do
*Robustness and log-level tests

clear all
set more off
cap log close
log using "${code}\04_robustness.log", replace text


*Load and prepare (same as 03)
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

tempfile base_sample
save `base_sample'


*1.City-specific linear trends (no PSM weights; trends absorb
*unobserved heterogeneity that PSM addresses)
reghdfe service_share DID $controls, ///
    absorb(cityid year cityid#c.year) vce(cluster cityid)
est store rob_trend


*2.OLS without PSM
use "${output}\analysis_data.dta", clear
keep if year >= 2010 & year <= 2023
drop if year == 2017

gen Post = (year >= 2016)
gen DID_OLS = treat * Post

reghdfe service_share DID_OLS $controls, ///
    absorb(cityid year) vce(cluster cityid)
est store rob_ols

use `base_sample', clear


*3.Alternative treatment thresholds (dose-response)
*Store all percentiles before running regressions
su exposure if year == 2015, d
local p60 = r(p60)
local p75 = r(p75)
local p80 = r(p80)

gen treat_40 = (exposure >= `p60') if exposure != .
gen did_40 = treat_40 * Post

reghdfe service_share did_40 $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store rob_40

gen treat_25 = (exposure >= `p75') if exposure != .
gen did_25 = treat_25 * Post

reghdfe service_share did_25 $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store rob_25

gen treat_20 = (exposure >= `p80') if exposure != .
gen did_20 = treat_20 * Post

reghdfe service_share did_20 $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store rob_20


*4.Continuous DID
gen DID_Cont = exposure * Post

reghdfe service_share DID_Cont $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store rob_cont


*5.Placebo (fake treatment 3 years early)
preserve
    keep if year < 2016

    gen FakePost = (year >= 2013)
    gen DID_Fake = treat * FakePost

    reghdfe service_share DID_Fake $controls [pw = kernel_weight], ///
        absorb(cityid year) vce(cluster cityid)
    est store rob_placebo
restore


*6.Exclude municipalities
preserve
    drop if municipality == 1

    reghdfe service_share DID $controls [pw = kernel_weight], ///
        absorb(cityid year) vce(cluster cityid)
    est store rob_nomunic
restore


*7.Short window
preserve
    keep if year >= 2013 & year <= 2019

    reghdfe service_share DID $controls [pw = kernel_weight], ///
        absorb(cityid year) vce(cluster cityid)
    est store rob_short
restore


*8.Without interpolated values
use "${output}\analysis_data_nointerp.dta", clear
keep if year >= 2010 & year <= 2023
drop if year == 2017

merge m:1 cityid using `psm_w', keep(3) nogen
keep if kernel_weight != . & kernel_weight > 0

gen Post = (year >= 2016)
gen DID_NI = treat * Post

reghdfe service_share DID_NI $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store rob_nointerp


*9.Log-level regressions (share illusion test)
use `base_sample', clear

reghdfe ln_tertiary_va DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store si_tert

reghdfe ln_secondary_va DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store si_sec

reghdfe ln_gdppc DID ln_pop fin_depth ln_fiscal ln_wage ///
    [pw = kernel_weight], absorb(cityid year) vce(cluster cityid)
est store si_gdp

gen ln_ts_ratio = ln_tertiary_va - ln_secondary_va
reghdfe ln_ts_ratio DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
est store si_ratio


*Output
esttab rob_trend rob_ols rob_40 rob_25 rob_20 rob_cont ///
       rob_placebo rob_nomunic rob_short rob_nointerp ///
    using "${code}\tables\Table3_Robustness.rtf", replace ///
    keep(DID DID_OLS did_40 did_25 did_20 DID_Cont DID_Fake ///
         DID_NI) ///
    b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("N Observations") ///
    title("Table 3: Robustness") ///
    mtitles("City trend" "OLS" "Top40" "Top25" "Top20" ///
            "Continuous" "Placebo" "No Munic" "Short" "No Interp")

esttab si_tert si_sec si_gdp si_ratio ///
    using "${code}\tables\Table4_LogLevel.rtf", replace ///
    keep(DID) b(4) se(4) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("N Observations" "r2_a Adj R-sq") ///
    title("Table 4: Log-Level Regressions") ///
    mtitles("ln(Tert VA)" "ln(Sec VA)" "ln(GDP pc)" "ln(Tert/Sec)")


log close
