*02_create_analysis.do
*Construct final analysis dataset

clear all
set more off
cap log close
log using "${code}\02_create_analysis.log", replace text


*Load cleaned panel
use "${output}\yearbook_panel_clean.dta", clear


*Log transforms
gen ln_gdppc  = ln(gdppc)
gen ln_pop    = ln(population)
gen ln_fiscal = ln(fiscal)
gen ln_wage   = ln(wage)

*Financial depth
gen fin_depth = loans / deposits
replace fin_depth = . if deposits == 0 | deposits == .

*Log sector VA
gen ln_tertiary_va  = ln(tertiary_va)
gen ln_secondary_va = ln(secondary_va)


*Merge treatment (exposure intensity from external source)
*Top 30% of 2015 exposure = treated
merge m:1 cityid using "${raw}\exposure_2015.dta", keep(1 3) nogen

su exposure if year == 2015, d
local p70 = r(p70)
gen treat = (exposure >= `p70') if exposure != .
replace treat = 0 if treat == . & exposure != .

tab treat if year == 2015


*Assign regions
gen region = ""

replace region = "East" if inlist(province, "Beijing", "Tianjin", ///
    "Shanghai", "Jiangsu", "Zhejiang", "Fujian", "Shandong", ///
    "Guangdong", "Hainan", "Hebei")

replace region = "Central" if inlist(province, "Shanxi", "Anhui", ///
    "Jiangxi", "Henan", "Hubei", "Hunan")

replace region = "West" if inlist(province, "Chongqing", "Sichuan", ///
    "Guizhou", "Yunnan", "Shaanxi", "Gansu", "Qinghai") | ///
    inlist(province, "Guangxi", "Inner Mongolia", "Ningxia", ///
    "Xinjiang", "Tibet")

replace region = "Northeast" if inlist(province, "Liaoning", ///
    "Jilin", "Heilongjiang")


*Interpolate missing controls (~10% of obs)
xtset cityid year

foreach var of varlist service_share industry_share ///
                       ln_gdppc ln_pop fin_depth ln_fiscal ln_wage {
    cap drop `var'_imp
    by cityid: ipolate `var' year, gen(`var'_imp) epolate
    replace `var' = `var'_imp if `var' == .
    drop `var'_imp
}

label data "Analysis Panel"
save "${output}\analysis_data.dta", replace

log close
