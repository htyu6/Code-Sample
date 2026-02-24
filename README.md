# Replication Code

Environmental Regulation and Industrial Composition

Haotian Yu | hy657@cornell.edu

## Overview

Stata code for a difference-in-differences analysis of how an exogenous policy shock affected sectoral composition at the Chinese prefecture level. The empirical strategy combines kernel propensity score matching with two-way fixed effects estimation.

## Requirements

Stata 16 or later, with: reghdfe, ftools, psmatch2, estout/esttab, coefplot, boottest. All installable via `ssc install`.

## How to run

Open `code/00_master.do`, set the path on line 11, and run. It calls all do-files in order.

## Files

`01_clean_merge.do` merges 14 yearbook editions into a panel. Variable names change across editions (`gdp_` vs `grp_` prefixes), so a standardization program handles that before appending. Controls are winsorized at 1/99.

`02_create_analysis.do` creates log transforms and financial depth, merges treatment from the exposure file, assigns four-region classification, and interpolates missing controls (~10% of obs).

`03_main_analysis.do` runs kernel PSM on five baseline covariates, then estimates DID with city and year FE under three control specifications. Event study with parallel trends F-tests.

`04_robustness.do` has ten checks: city-specific trends, OLS without PSM, three alternative cutoffs (top 40/25/20%), continuous DID, placebo, municipality exclusion, shorter window, no-interpolation sample. Also log-level regressions to distinguish composition effects from real contraction.

`05_mechanisms.do` replaces the DV with industry share, FDI, industrial profits, real estate investment, and retail. Enterprise data merged for FDI extensive margin. Regional heterogeneity by East/Central/West/Northeast.

`06_extensions.do` runs wild cluster bootstrap, permutation test (1000 draws), IPTW, and PSM balance diagnostics.

## Identification

Treatment is top 30% of pre-policy exposure intensity. Kernel PSM on GDP per capita, population, financial depth, fiscal revenue, and average wage. Main spec is TWFE DID with PSM weights and city-clustered SEs. One census revision year dropped due to inconsistent sectoral accounting.

## Sample data

The `data/raw/` folder has synthetic .dta files so the code can run without the original data. 60 fictional cities, 2010 to 2023. Not real data, just meant to match the variable names and structure.

`data/output/` starts empty. Running `00_master.do` populates it: 01 cleans and merges the yearbook files into a panel, 02 constructs analysis variables and saves both `analysis_data.dta` and `analysis_data_nointerp.dta`, then 03 through 06 read from there.

## Data sources

The actual analysis uses the China City Statistical Yearbook (2011 to 2024 editions), CSMAR city-level database, and a prefecture enterprise database. Available through institutional subscriptions.

---

Claude (Anthropic) was used as a coding assistant for portions of this replication package.
