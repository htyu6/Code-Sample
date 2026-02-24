*06_extensions.do
*Bootstrap, permutation, IPTW, balance

clear all
set more off
cap log close
log using "${code}\06_extensions.log", replace text


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


*Wild cluster bootstrap
reghdfe service_share DID $controls [pw = kernel_weight], ///
    absorb(cityid year) vce(cluster cityid)
local b_main = _b[DID]

cap which boottest
if _rc == 0 {
    boottest DID, reps(9999) seed(12345) cluster(cityid) nograph
}


*Permutation test (1000 draws)
qui count if treat == 1 & year == 2015
local n_t = r(N)

local nperms = 1000
tempfile perm_results
postfile handle perm_b using `perm_results'

set seed 54321

forvalues p = 1/`nperms' {
    preserve
        bys cityid (year): gen tag = (_n == 1)
        gen rand = runiform() if tag == 1
        bys cityid: egen city_rand = max(rand)
        egen city_rank = rank(city_rand) if tag == 1
        bys cityid: egen rank_all = max(city_rank)
        gen perm_treat = (rank_all <= `n_t')
        gen perm_DID = perm_treat * Post

        qui cap reghdfe service_share perm_DID $controls ///
            [pw = kernel_weight], absorb(cityid year) vce(cluster cityid)

        if _rc == 0 {
            post handle (_b[perm_DID])
        }
    restore
}

postclose handle

*p-values and histogram
preserve
    use `perm_results', clear
    gen below   = (perm_b <= `b_main')
    gen extreme = (abs(perm_b) >= abs(`b_main'))
    qui su below
    local p_one = r(mean)
    qui su extreme
    local p_two = r(mean)

    hist perm_b, width(0.1) color(gs12) ///
        xline(`b_main', lcolor(red) lwidth(thick)) ///
        xtitle("Permuted coefficient") ytitle("Frequency") ///
        note("Red line = actual. One-sided p = `p_one'. Two-sided p = `p_two'.") ///
        graphregion(color(white)) bgcolor(white)

    graph export "${code}\figures\Figure_Permutation.png", replace width(1200)
restore


*IPTW as alternative to kernel PSM
use "${output}\analysis_data.dta", clear
xtset cityid year
keep if year >= 2010 & year <= 2023
drop if year == 2017

gen Post = (year >= 2016)
gen DID  = treat * Post

preserve
    keep if year == 2015
    logit treat $controls
    predict ps_iptw, p
    keep cityid ps_iptw
    tempfile iptw_ps
    save `iptw_ps'
restore

merge m:1 cityid using `iptw_ps', keep(3) nogen

gen iptw = treat / ps_iptw + (1 - treat) / (1 - ps_iptw)

*Trim extreme weights
su iptw, d
replace iptw = r(p99) if iptw > r(p99)

reghdfe service_share DID $controls [pw = iptw], ///
    absorb(cityid year) vce(cluster cityid)
est store iptw_main

reghdfe service_share DID $controls [pw = iptw], ///
    absorb(cityid year cityid#c.year) vce(cluster cityid)
est store iptw_trend

esttab iptw_main iptw_trend ///
    using "${code}\tables\AppTable_IPTW.rtf", replace ///
    keep(DID) b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("N Observations" "r2_a Adj R-sq") ///
    title("Appendix: IPTW") ///
    mtitles("Full controls" "+ City trends")


*Balance table
use "${output}\analysis_data.dta", clear
keep if year == 2015

logit treat $controls
predict pscore, p
psmatch2 treat, pscore(pscore) kernel outcome(service_share) common

pstest $controls, both


log close
