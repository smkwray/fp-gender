# Data Sources

[Back to README](../README.md)

This document describes each public data source used in the gender run bundle, the processing pipeline that transforms it into a quarterly series, and how it maps to a Fair model input variable.

---

## Table of Contents

- [Overview](#overview)
- [Childcare cost (GCCOST)](#childcare-cost-gccost)
- [Paid family leave (GPFL)](#paid-family-leave-gpfl)
- [Caregiver leave proxy (GPFL in caregiver family)](#caregiver-leave-proxy-gpfl-in-caregiver-family)
- [Secondary-earner tax wedge (GTAXWD)](#secondary-earner-tax-wedge-gtaxwd)
- [Mother share (GMOTHSHR)](#mother-share-gmothshr)
- [Mother LFPR log wedge (GMWEDGE)](#mother-lfpr-log-wedge-gmwedge)
- [Series construction conventions](#series-construction-conventions)
- [Provenance reports](#provenance-reports)

---

## Overview

Six quarterly series are published in `data/series/`. Five have corresponding provenance reports in `data/reports/`. All are derived from public U.S. government or OECD data sources.

| Series | Fair Variable | Source Organization | Refresh Command |
|--------|--------------|---------------------|-----------------|
| `childcare_cost_national_qtr.csv` | `GCCOST` | DOL Women's Bureau | `fp gender refresh-data --dataset childcare` |
| `paid_leave_civilian_qtr.csv` | `GPFL` | BLS | `fp gender refresh-data --dataset paid-leave` |
| `caregiver_leave_civilian_qtr.csv` | `GPFL` | BLS | `fp gender refresh-data --dataset caregiver-leave` |
| `tax_wedge_us_qtr.csv` | `GTAXWD` | OECD | `fp gender refresh-data --dataset tax-wedge` |
| `mother_share_f25_54_qtr.csv` | `GMOTHSHR` | Census Bureau | `fp gender refresh-data --dataset mother-share` |
| `mother_lfpr_log_wedge_f25_54_qtr.csv` | `GMWEDGE` | Census Bureau (derived) | `fp gender refresh-data --dataset mother-share` |

---

## Childcare Cost (GCCOST)

### Source

**U.S. Department of Labor, Women's Bureau — National Database of Childcare Prices (NDCP)**

- Source URL: `https://www.dol.gov/sites/dolgov/files/WB/NDCP2022.xlsx`
- Edition: 2022
- Coverage: County-level childcare prices by care type and age group, 2008-2022

### Processing pipeline

1. The NDCP workbook (`.xlsx`) is downloaded and parsed
2. National median center-based infant care prices (`mcinfant` column) are extracted
3. Prices are indexed to a 2008 base year (2008 = 0, expressed as proportional change from the base)
4. Annual observations are step-filled to quarterly frequency
5. Quarters beyond the last observed year (2022) carry forward the last observed value through 2029

### Output characteristics

- **Observed range**: 2008 Q1 – 2022 Q4 (15 annual observations → 60 quarterly)
- **Total range**: 2008 Q1 – 2029 Q4 (88 quarterly observations with carryforward)
- **Value range**: 0.0 (2008 base) to ~0.382 (2022)
- **Interpretation**: A value of 0.382 means center-based infant care costs rose ~38.2% above the 2008 level

### Notes

- The NDCP workbook is a single-edition release (2022). Future updates would require a new workbook download.
- Only the national median infant center-based price is used. State/county variation and other care types are not incorporated.
- No independent cost forecast is embedded. The forecast window uses the last observed value.

---

## Paid Family Leave (GPFL)

### Source

**U.S. Bureau of Labor Statistics — National Compensation Survey, Employee Benefits (NB series)**

- Primary source: BLS Public Data API v2
- Series IDs:
  - Civilian: `NBU18700000000000033349`
  - Private industry: `NBU28700000000000033349`
  - State/local government: `NBU38700000000000033349`
- Fallback: Cached NB flat files under `projects_local/gender/data/raw/bls-nb/`
- Final fallback: Embedded fact-sheet snapshot (hardcoded annual values in `gender_family.py`)

### Processing pipeline

1. The civilian series is fetched from the BLS API (or fallback sources)
2. Annual observations (share of civilian workers with access to paid family leave) are taken directly
3. Annual values are step-filled to quarterly frequency
4. Quarters beyond the last observed year carry forward the last observed value
5. Relief and shock variants shift the forecast path by ±0.05 from the carryforward level

### Output characteristics

- **Observed range**: 2010 – 2023 (14 annual observations → 56 quarterly)
- **Total range**: 2010 Q1 – 2029 Q4 (80 quarterly observations)
- **Value range**: 0.11 (2010) to 0.27 (2023)
- **Interpretation**: A value of 0.27 means 27% of civilian workers had access to paid family leave

### Embedded snapshot values

If both the API and flat files are unavailable, the pipeline uses these hardcoded values (from BLS published fact sheets):

| Year | Civilian | Private | State/Local |
|------|----------|---------|-------------|
| 2014 | 0.13 | 0.12 | 0.16 |
| 2015 | 0.13 | 0.12 | 0.16 |
| 2016 | 0.14 | 0.13 | 0.16 |
| 2017 | 0.15 | 0.13 | 0.25 |
| 2018 | 0.17 | 0.16 | 0.25 |
| 2019 | 0.19 | 0.18 | 0.25 |
| 2020 | 0.21 | 0.20 | 0.26 |
| 2021 | 0.23 | 0.23 | 0.26 |
| 2022 | 0.25 | 0.24 | 0.27 |
| 2023 | 0.27 | 0.27 | 0.28 |

---

## Caregiver Leave Proxy (GPFL in Caregiver Family)

### Source

**U.S. Bureau of Labor Statistics — National Compensation Survey, Employee Benefits (NB series)**

- Series IDs:
  - Civilian: `NBU18800000000000033350`
  - Private industry: `NBU28800000000000033350`
  - State/local government: `NBU38800000000000033350`

### Processing pipeline

Same as paid leave, but using the *unpaid* family leave access series instead of the *paid* family leave series.

### Output characteristics

- **Observed range**: 2010 – 2025 (16 annual observations → 64 quarterly)
- **Total range**: 2010 Q1 – 2029 Q4 (80 quarterly observations)
- **Value range**: 0.86 (2010) to 0.90 (2023-2025)
- **Interpretation**: A value of 0.90 means 90% of civilian workers had access to unpaid family leave

### Why this is a proxy

BLS does not publish a separate "caregiver leave" series. The unpaid family leave series measures access to leave for care of a spouse, child, or parent — which is the closest available BLS series to a caregiver-specific measure.

This is broader than dedicated caregiver leave in two ways:
1. It includes childcare leave, not only elder/spousal care
2. It measures access (whether the benefit exists), not utilization

The proxy status is an inherent limitation of available federal survey data. Users should interpret caregiver-family results as reflecting family leave access broadly, not a caregiver-specific policy lever.

### Shared Fair variable with paid leave

The caregiver leave family does not introduce a separate Fair model variable. It loads a different source series into the same `GPFL` variable that the paid leave family uses. Both families operate through the identical `GPFLWT * GPFL` term in aggregate `TBL2` — the only difference is which BLS series populates `GPFL` in the compiled scenario input. This is a modeling simplification, not a structurally distinct caregiver policy channel.

### Forecast variants

- **Relief**: +0.02 from the carryforward level (e.g., 0.90 → 0.92)
- **Shock**: −0.02 from the carryforward level (e.g., 0.90 → 0.88)

---

## Secondary-Earner Tax Wedge (GTAXWD)

### Source

**OECD — Taxing Wages 2025, Table 6.6**

- Description: "Tax wedge as % of labour costs for a two-earner married couple with two children at 100% and 67% of average wage"
- Country: United States
- Source URL: `https://www.oecd.org/en/publications/taxing-wages-2025_b3a95829-en/full-report/component-17.html`

### Processing pipeline

1. The OECD Table 6.6 values for the U.S. are materialized from hardcoded observations in `gender_family.py` (the OECD data is accessed from the publication, not via a live API)
2. Annual observations are step-filled to quarterly frequency
3. Quarters beyond the last observed year carry forward
4. Relief and shock variants shift the forecast path by ±0.02

### Output characteristics

- **Observed range**: 2000 – 2024 (10 annual observations with step-fill → 100 quarterly)
- **Total range**: 2000 Q1 – 2029 Q4 (120 quarterly observations)
- **Value range**: 0.273 (2000) to 0.143 (2024)
- **Interpretation**: A value of 0.143 means the total tax wedge for the secondary earner in a two-earner couple was 14.3% of labor costs

### Hardcoded source values

| Year | Tax Wedge |
|------|-----------|
| 2000 | 0.273 |
| 2010 | 0.246 |
| 2015 | 0.241 |
| 2018 | 0.220 |
| 2019 | 0.215 |
| 2020 | 0.200 |
| 2021 | 0.175 |
| 2022 | 0.167 |
| 2023 | 0.166 |
| 2024 | 0.143 |

### Why this is a proxy

The OECD tax wedge is a household-level measure for a specific family type (married, two children, earnings at 100%/67% of average wage). It is not a gender-specific individual tax rate.

The proxy assumption is that secondary earners are disproportionately women, so changes in the secondary-earner tax wedge approximate changes in the effective tax disincentive to women's labor supply. This is a standard approximation in the labor supply literature but involves significant abstraction from individual-level heterogeneity.

### Forecast variants

- **Relief**: −0.02 from the carryforward level (e.g., 0.143 → 0.123) — a narrower wedge
- **Shock**: +0.02 from the carryforward level (e.g., 0.143 → 0.163) — a wider wedge

---

## Mother Share (GMOTHSHR)

### Source

**U.S. Census Bureau — American Community Survey 1-Year Public Use Microdata Sample (ACS 1-Year PUMS)**

- API endpoint: `https://api.census.gov/data/{year}/acs/acs1/pums`
- Query: `tabulate=weight(PWGTP)&row+PAOC&col+ESR&SEX=2&AGEP=25:54`
- Population: Females ages 25-54

### Key Census variables

| Variable | Code | Meaning |
|----------|------|---------|
| `PAOC` | 1 | Own children under 6 years only |
| `PAOC` | 2 | Own children 6 to 17 years only |
| `PAOC` | 3 | Own children under 6 years and 6 to 17 years |
| `PAOC` | 4 | No own children |
| `PAOC` | 0 | Not applicable (group quarters) — excluded from denominator |
| `ESR` | 1-5 | In the civilian labor force |
| `ESR` | 6 | Not in the labor force |

### Processing pipeline

1. Weighted `PAOC` × `ESR` tabulations are fetched from the Census API for each available year (2005-2024, excluding 2020)
2. Mother share is computed as: `PAOC ∈ {1,2,3} / (PAOC ∈ {1,2,3,4})` — the share of women 25-54 with own children under 18 in the household
3. Annual observations are step-filled to quarterly frequency
4. The series is backfilled to 1952 at the 2005 level (the earliest ACS 1-year PUMS year)
5. The 2020 observation is missing (no ACS 1-year in 2020) and is interpolated between 2019 and 2021

### Output characteristics

- **Observed range**: 2005 – 2024 (19 annual observations, excluding 2020)
- **Total range**: 1952 Q1 – 2029 Q4 (312 quarterly observations with backfill and carryforward)
- **Value range**: ~0.473 to ~0.512

### Interpretation caveats

- This is a **resident own-children-under-18** share, not an all-mothers or ever-gave-birth share
- Women whose children have all aged out of 18 are counted as non-mothers
- Women in group quarters (`PAOC=0`) are excluded from the denominator
- This makes `GMOTHSHR` a strong exposure proxy for childcare and leave questions (which affect women currently raising children) but not a complete demographic motherhood rate
- The backfill to 1952 assumes the 2005 level is a reasonable approximation for the pre-ACS period, which is a limitation for long-horizon historical analysis

---

## Mother LFPR Log Wedge (GMWEDGE)

### Source

Derived from the same Census ACS 1-year PUMS data as `GMOTHSHR`.

### Processing pipeline

1. For each year, the labor force participation rate is computed separately for mothers (`PAOC ∈ {1,2,3}`) and non-mothers (`PAOC = 4`) among women 25-54
2. The log wedge is: `GMWEDGE = LOG(mothers LFPR / non-mothers LFPR)`
3. Since mothers participate at lower rates than non-mothers, `GMWEDGE` is consistently negative
4. Annual observations are step-filled to quarterly frequency
5. Backfilled to 1952 at the 2005 level; 2020 is interpolated

### Output characteristics

- **Observed range**: 2005 – 2024
- **Total range**: 1952 Q1 – 2029 Q4
- **Value range**: ~−0.099 to ~−0.074
- **Interpretation**: A value of −0.075 means mothers' participation rate is approximately `EXP(−0.075) ≈ 0.928`, or about 7.2% lower than non-mothers' rate

### Role in the model

`GMWEDGE` is used only for historical initialization of the mothers/non-mothers split. It ensures the initial `L2M`/`L2N` decomposition reflects empirical rate differences rather than assuming mothers and non-mothers participate at identical rates.

---

## Series Construction Conventions

All series follow these conventions:

- **Format**: Two-column CSV with `period` (e.g., `2010.1` for Q1 2010) and `value`
- **Quarterly step-fill**: Annual observations are assigned to Q4 of the observation year. Intermediate quarters carry forward the previous year's value.
- **Forecast carryforward**: Beyond the last observed year, the series carries forward the last observed value at a flat level.
- **Relief/shock variants**: Where applicable (paid leave, caregiver leave, tax wedge), variant series shift the forecast path from the carryforward level by a fixed increment (typically ±0.02 to ±0.05). The historical path is identical across base, relief, and shock.

---

## Provenance Reports

Each series has a corresponding JSON provenance report in `data/reports/` that records:

- Number of annual observations
- Base year
- Number of observed and total quarterly observations
- Latest observed period and value
- Source identifiers (BLS series IDs, OECD table references, Census API parameters)
- Refresh metadata

The `mother_share_f25_54_qtr.json` report also contains:
- Estimation panel metadata (columns, rows, recommended estimation window)
- OLS research summaries for mothers and non-mothers labor force equations
- R-squared values and coefficient previews from the research fitting pipeline

These reports are generated by `fp gender refresh-data` and are intended for audit and reproducibility, not for direct model input.
