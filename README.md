# Code Sample

Stata replication code for a prefecture-level difference-in-differences analysis of how an exogenous policy shock affected sectoral composition in Chinese cities.

**Haotian Yu** | Cornell University | hy657@cornell.edu

## Methods

- Prefecture-level panel from China City Statistical Yearbook (2010–2023) and CSMAR
- Treatment: top 30% of pre-policy exposure intensity
- Kernel propensity score matching → two-way fixed effects DID
- Event study with parallel trends tests

## Files

| File | Description |
|------|-------------|
| `00_master.do` | Set paths and run pipeline |
| `01_clean_merge.do` | Merge yearbook editions into panel, harmonize variable names |
| `02_create_analysis.do` | Variable construction, treatment assignment, interpolation |
| `03_main_analysis.do` | PSM-DID and event study (Tables 1–2, Figure 1) |
| `04_robustness.do` | City trends, dose-response, placebo, short window, log-level tests (Tables 3–4) |
| `05_mechanisms.do` | Mechanisms, FDI extensive margin, regional heterogeneity (Tables 5–7) |
| `06_extensions.do` | Wild cluster bootstrap, permutation test, IPTW, balance diagnostics |

## Requirements

Stata 16+ with: `reghdfe`, `ftools`, `psmatch2`, `estout`, `coefplot`, `boottest`

## Note

Data are not included in this repository. See `README.docx` for full documentation. Claude (Anthropic) was used as a coding assistant for portions of this package.
