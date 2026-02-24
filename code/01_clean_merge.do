*01_clean_merge.do
*Merge annual yearbook

clear all
set more off
cap log close
log using "${code}\01_clean_merge.log", replace text


*Variable names shift between gdp_ and grp_ prefixes across editions.
*This will standardizes them before appending.

capture program drop standardize_vars
program define standardize_vars

    *Tertiary share
    cap confirm variable gdp_share_tertiary
    if _rc == 0 {
        rename gdp_share_tertiary service_share
    }
    else {
        cap confirm variable grp_share_tertiary
        if _rc == 0 {
            rename grp_share_tertiary service_share
        }
        else {
            gen service_share = .
        }
    }

    *Secondary share
    cap confirm variable gdp_share_secondary
    if _rc == 0 {
        rename gdp_share_secondary industry_share
    }
    else {
        cap confirm variable grp_share_secondary
        if _rc == 0 {
            rename grp_share_secondary industry_share
        }
        else {
            gen industry_share = .
        }
    }

    *GDP per capita
    cap confirm variable gdp_pc
    if _rc == 0 rename gdp_pc gdppc
    cap confirm variable grp_pc
    if _rc == 0 rename grp_pc gdppc

    *Population
    cap confirm variable pop_total
    if _rc == 0 rename pop_total population
    cap confirm variable total_pop
    if _rc == 0 rename total_pop population

    *Fiscal revenue
    cap confirm variable fiscal_rev
    if _rc == 0 rename fiscal_rev fiscal
    cap confirm variable fiscal_revenue
    if _rc == 0 rename fiscal_revenue fiscal

    *Average wage
    cap confirm variable avg_wage
    if _rc == 0 rename avg_wage wage
    cap confirm variable average_wage
    if _rc == 0 rename average_wage wage

    *Loans and deposits
    cap confirm variable loan_balance
    if _rc == 0 rename loan_balance loans
    cap confirm variable deposit_balance
    if _rc == 0 rename deposit_balance deposits

end


*Loop over editions and append
tempfile master
local first = 1

forvalues y = 2010/2023 {

    cap use "${raw}\yearbook_`y'.dta", clear
    if _rc != 0 continue

    standardize_vars

    gen year = `y'

    cap keep city cityid province municipality year ///
            service_share industry_share ///
            gdppc population fiscal wage loans deposits ///
            fdi_actual tertiary_va secondary_va ///
            ind_profit re_investment retail_sales

    if `first' == 1 {
        save `master', replace
        local first = 0
    }
    else {
        append using `master'
        save `master', replace
    }
}

use `master', clear
sort cityid year
duplicates drop cityid year, force


*Basic cleaning
drop if cityid == .

*Drop cities with admin boundary changes

*Winsorize at 1/99
foreach var of varlist gdppc population fiscal wage {
    qui su `var', d
    replace `var' = r(p1) if `var' < r(p1) & `var' != .
    replace `var' = r(p99) if `var' > r(p99) & `var' != .
}

save "${output}\yearbook_panel_clean.dta", replace

log close
