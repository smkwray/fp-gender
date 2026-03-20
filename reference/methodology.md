# Methodology: Gender Overlay for the Fair Model

[Back to README](../README.md)

This document describes the equation-level architecture of the gender overlay applied to Ray Fair's US macroeconometric model. It covers the stock model anchors, the aggregate + wedge design, the estimation approach, and the post-solve recovery of the mothers/non-mothers split.

---

## Table of Contents

- [Stock model anchors](#stock-model-anchors)
- [Overlay architecture: aggregate + wedge](#overlay-architecture-aggregate--wedge)
- [Wedge equation estimation](#wedge-equation-estimation)
- [Post-solve split recovery](#post-solve-split-recovery)
- [Aggregate policy channel](#aggregate-policy-channel)
- [Overlay file structure](#overlay-file-structure)
- [What is not modified](#what-is-not-modified)
- [Design rationale](#design-rationale)

---

## Stock Model Anchors

The overlay modifies two anchors in the stock Fair model input deck (`FM/fminput.txt`):

### Equation 6: Women 25-54 labor force

```
EQ 6 LL2Z  CNST2L2 C TBL2 T LL2Z(-1) LAAZ(-1) UR ;
LHS L2=EXP(LL2Z)*POP2;
```

- `LL2Z = LOG(L2 / POP2)` — log participation rate for women 25-54
- `CNST2L2` — piecewise trend constant (changes slope at breakpoints)
- `TBL2 = T * CNST2L2` — time-trend interaction term
- `L2 = EXP(LL2Z) * POP2` — level form, scaled by working-age female population

### Equation 9: Unused placeholder

```
EQ 9 NONE9 C;
```

The stock model's EQ 9 is not used for any substantive equation. The gender overlay repurposes it for the wedge equation.

### Unemployment identities

```
IDENT U  = L1 + L2 + L3 - E
IDENT UR = U / (L1 + L2 + L3 - AFT)
```

These are **unchanged** in the gender overlay. Aggregate `L2` from stock EQ 6 feeds into the identities directly.

---

## Overlay Architecture: Aggregate + Wedge

The overlay has two layers:

### Layer 1: Aggregate policy channel (EQ 6)

Stock EQ 6 is preserved. The only modification is that `TBL2` is augmented with calibrated policy terms:

```
TBL2 = T*CNST2L2 + GCCOSTWT*GCCOST + GCSUBWT*GCSUB + GPFLWT*GPFL + GTAXWT*GTAXWD
```

This shifts aggregate `L2` in response to policy input paths. The `TBL2` coefficient in EQ 6 is estimated by `fp.exe` using 2SLS over the full Fair estimation window (1954-2025). The policy weights (`GCCOSTWT`, etc.) are calibrated deck constants.

### Layer 2: Wedge equation (EQ 9)

The stock placeholder `EQ 9 NONE9 C;` is replaced with:

```
EQ 9 GMWEDGE C GMWEDGE(-1) GCCOST GPFL GTAXWD UR ;
```

This governs `GMWEDGE = log(L2MZ / L2NZ)`, the log ratio of mothers' to non-mothers' participation rates. The policy variables appear directly as regressors with estimated (not calibrated) coefficients. `UR` is included to capture cyclical effects on the differential.

EQ 9 is estimated on the ACS-observed window only (2005.1-2024.4), with 2020 quarters excluded via MODEQ dummies. This is much shorter than the full Fair estimation window, but it is the only period with independent mothers/non-mothers participation data from Census ACS PUMS.

### Post-solve recovery

After the forecast solve determines aggregate `L2` (from EQ 6) and the wedge `GMWEDGE` (from EQ 9), the mothers/non-mothers components are recovered via identities:

```
POP2M  = GMOTHSHR * POP2
POP2N  = (1-GMOTHSHR) * POP2
GMWEXP = EXP(GMWEDGE)
L2NZ   = L2Z / ((1-GMOTHSHR) + GMOTHSHR * GMWEXP)
L2MZ   = GMWEXP * L2NZ
L2M    = L2MZ * POP2M
L2N    = L2NZ * POP2N
```

This ensures `L2M + L2N = L2` exactly at every period. The recovery is executed in `ginputs.txt`, which runs after the solve completes and before the output is written.

### What the overlay changes

| Component | Stock Fair | Gender Overlay |
|-----------|-----------|----------------|
| EQ 6 | `LL2Z` with `TBL2 = T*CNST2L2` | `LL2Z` with policy-augmented `TBL2` |
| EQ 9 | Unused placeholder (`NONE9`) | Wedge equation (`GMWEDGE`) |
| `TBL2` | `T * CNST2L2` | `T*CNST2L2 + GCCOSTWT*GCCOST + ...` |
| `U`, `UR` | Stock identities | Unchanged |
| `L2M`, `L2N` | Not present | Recovered post-solve from `L2` + `GMWEDGE` |
| EST block | `EST 1-14` with single sample | `EST 1-8` full sample, `EST 9` ACS window, `EST 10-14` full sample |
| MODEQ | No EQ 9 entry | `MODEQ 9` with 2020 quarterly dummies |

---

## Wedge Equation Estimation

### Estimation window

EQ 9 is estimated by 2SLS on `SMPL 2005.1 2024.4`, with `MODEQ 9 D20201 D20202 D20203 D20204 ;` excluding the 2020 quarters. This gives approximately 72 effective quarterly observations (19 ACS years minus 2020, step-filled to quarterly).

### Why ACS-observed only

The aggregate Fair equation (EQ 6) is estimated on the full 1954-2025 window using aggregate `L2` data. The wedge equation cannot use the full window because independent mothers/non-mothers participation data does not exist before 2005. Before ACS PUMS (which starts with 2005 1-year data), the wedge would have to be derived from aggregate `L2` — which would give the estimator no independent variation and reproduce the proportional-split problem.

### Data sources for the wedge

The dependent variable `GMWEDGE` is loaded from `GMWEDGE.DAT`, which contains the ACS PUMS-derived log participation-rate wedge. The ACS data shows genuine time variation: the wedge ranges from about −0.099 (2005) to −0.075 (2024), reflecting the faster recovery of mothers' participation relative to non-mothers over the 2015-2024 period.

The policy regressors (`GCCOST`, `GPFL`, `GTAXWD`) are loaded from their respective `.DAT` files, which now contain full-sample historical data (not just forecast-period values). During the ACS estimation window:
- `GCCOST` has observed values from 2008-2022 (zero before 2008)
- `GPFL` has observed values from 2010-2023
- `GTAXWD` has observed values from 2000-2024

### First-stage regressors

```
EQ 9 FSR C GMWEDGE(-1) GCCOST(-1) GPFL(-1) GTAXWD(-1) UR(-1) LAAZ(-3)
;
```

### 2020 exclusion

Census did not release standard ACS 1-year estimates for 2020 due to pandemic-related data collection issues. The 2020 experimental estimates exist but carry a Census comparability warning. The MODEQ dummies absorb any 2020 data that enters the estimation window, effectively excluding it.

### Coefficient interpretation

The estimated coefficients capture associations between policy input paths and the mothers/non-mothers participation differential over the ACS-observed period. They are **not** causally identified from exogenous policy variation. They are best understood as: "in the 2005-2024 data, when childcare costs were higher, the wedge tended to be narrower" — with the caveat that this is a 19-year window with step-filled quarterly data and multiple confounding trends.

---

## Post-Solve Split Recovery

The recovery algebra is implemented in `ginputs.txt`, which runs after the solve and before output is written. It uses the same formula that initializes the historical split:

```
L2Z   = L2 / POP2                                         (aggregate rate)
GMWEXP = EXP(GMWEDGE)                                     (rate ratio)
L2NZ  = L2Z / ((1-GMOTHSHR) + GMOTHSHR * GMWEXP)         (non-mothers rate)
L2MZ  = GMWEXP * L2NZ                                     (mothers rate)
L2M   = L2MZ * POP2M                                      (mothers level)
L2N   = L2NZ * POP2N                                      (non-mothers level)
```

The key property: `L2M + L2N = L2` exactly, by construction. The aggregate is always preserved.

For the forecast period, `GMWEDGE` is endogenous (solved by EQ 9). Different policy input paths produce different `GMWEDGE` forecasts, which produce different `L2M`/`L2N` splits. The mothers' share of `L2` is no longer constant across scenarios.

---

## Aggregate Policy Channel

### How TBL2 augmentation works

The stock `TBL2 = T * CNST2L2` is augmented by `ginputs.txt` after FMEXOG.TXT loads:

```
GENR TBL2 = T*CNST2L2 + GCCOSTWT*GCCOST + GCSUBWT*GCSUB + GPFLWT*GPFL + GTAXWT*GTAXWD;
```

This runs after FMEXOG.TXT (which would otherwise reset TBL2 to the stock value for the forecast period) and before the SOLVE.

### Weight calibration

The weights (`GCCOSTWT`, `GCSUBWT`, `GPFLWT`, `GTAXWT`) are deck constants set per-scenario. They are NOT estimated — they are calibrated to produce directionally correct aggregate responses given the sign of the stock TBL2 coefficient (estimated as negative).

| Weight | Sign | Why |
|--------|------|-----|
| `GCCOSTWT` | + | Higher cost adds to TBL2, amplifying the negative effect → reduces participation |
| `GCSUBWT` | − | Higher subsidy subtracts from TBL2, offsetting the negative effect → increases participation |
| `GPFLWT` | − | More leave subtracts from TBL2 → increases participation |
| `GTAXWT` | + | Higher wedge adds to TBL2 → reduces participation |

### Include order

The include order is critical: `gdata.txt` → `FMEXOG.TXT` → `ginputs.txt`. This ensures `ginputs.txt` runs last and its `GENR TBL2` overwrites any FMEXOG.TXT-set values for TBL2 in the forecast period.

---

## Overlay File Structure

```
projects_local/gender/
├── gbase.txt        ← entry file: includes gpbase.txt, then gcommon.txt
├── gpbase.txt       ← policy file: zero-initializes all policy variables and weights
├── gcommon.txt      ← rewritten model input: stock EQ 6 + wedge EQ 9, augmented TBL2, split-state
├── gdata.txt        ← LOADDATA commands for all six .DAT files
├── ginputs.txt      ← post-FMEXOG: augments TBL2, recovers L2M/L2N from L2 + GMWEDGE
├── GCCOST.DAT       ← childcare cost (full sample: 2008-2029)
├── GCSUB.DAT        ← childcare subsidy (full sample, typically zero)
├── GPFL.DAT         ← paid/caregiver leave (full sample: 2010-2029)
├── GTAXWD.DAT       ← tax wedge (full sample: 2000-2029)
├── GMOTHSHR.DAT     ← mother share (full sample: 1952-2029)
└── GMWEDGE.DAT      ← participation-rate wedge (full sample: 1952-2029)
```

---

## What Is Not Modified

The gender overlay modifies only EQ 6's TBL2 regressor, EQ 9's equation definition, the data includes, and the EST/MODEQ blocks. Everything else in the Fair model is unchanged:

- Equations 1-5 (consumption, housing, men's labor force)
- Equations 7-8 (other labor force, moonlighting)
- Equations 10-30 (production, prices, wages, interest rates, fiscal, trade)
- All identities (GDP, U, UR, national accounts, financial stocks)
- The exogenous variable paths (fiscal, monetary, trade, population)

---

## Design Rationale

### Why aggregate + wedge, not two separate equations

An earlier version of the overlay replaced EQ 6 with two separate behavioral equations — one for mothers (`LL2MZ`) and one for non-mothers (`LL2NZ`). This produced a proportional split: `L2M / L2 = 0.4538` across all scenarios, because the historical data for both equations was derived from aggregate `L2` via a constant-offset formula. The 2SLS estimator reproduced the constant offset in the forecast regardless of the policy input paths.

The wedge design resolves this by separating the two empirical objects:
1. **Aggregate women's labor force** — observed quarterly since 1954, well-identified in the stock Fair equation
2. **Mothers vs non-mothers differential** — observed annually since 2005 via ACS PUMS, with genuine independent variation

Estimating each where the data actually exists (full sample for the aggregate, ACS window for the differential) is more honest than pretending to have 70 years of subgroup data.

### Why GMWEDGE, not separate LFPRs

The empirical object from ACS is the *relative* participation behavior of mothers vs non-mothers. A wedge equation captures this directly. Estimating two free level equations would require:
- Independent historical series for mothers' and non-mothers' LFPR going back to 1954
- Solving the backfill problem for the pre-2005 period
- Ensuring the two equations produce levels that sum to aggregate L2

The wedge approach avoids all three problems. The aggregate level is trusted from stock EQ 6, and the wedge is learned from ACS data where it's actually observed.
