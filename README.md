# fp-gender

Gender-focused scenario runs for Ray Fair's US macroeconometric model, built and exported from [`fp-wraptr`](https://github.com/smkwray/fp-wraptr).

This repository contains:

- A static [GitHub Pages site](https://smkwray.github.io/fp-gender/) for browsing model run results interactively
- Public-source input data series and provenance reports
- The export specification that defines which runs are retained for the public bundle
- Documentation of the gender overlay, variable definitions, data sources, and interpretation caveats

`fp-gender` is the public distribution artifact. Scenario authoring, model runtime code, Fair model engine integration, and the full internal working tree live in [`fp-wraptr`](https://github.com/smkwray/fp-wraptr).

Full regeneration requires local access to `fp-wraptr`, the Fair model executable/assets, and the private artifact workspace used to compile/export runs. This repository is the public distribution bundle, not the full implementation tree.

**Live site**: [https://smkwray.github.io/fp-gender/](https://smkwray.github.io/fp-gender/)

---

## Table of Contents

- [What the site does](#what-the-site-does)
- [Repository structure](#repository-structure)
- [Run families](#run-families)
- [Fair model modifications](#fair-model-modifications)
- [Gender variables](#gender-variables)
- [Data sources](#data-sources)
- [Build and refresh](#build-and-refresh)
- [Browsing the site](#browsing-the-site)
- [Interpretation and limitations](#interpretation-and-limitations)
- [Implementation provenance](#implementation-provenance)
- [References](#references)
- [Attribution](#attribution)

Detailed supporting documentation:

- [`reference/methodology.md`](reference/methodology.md) — equation architecture, overlay mechanics, mothers/non-mothers prototype design
- [`reference/data-sources.md`](reference/data-sources.md) — data source details, API paths, series construction, proxy rationale

---

## What the Site Does

The site is a read-only run explorer. Visitors can:

- Compare forecast paths across 22 gender-focused policy scenarios spanning seven question families
- Select from curated variable presets (headline macro, policy inputs, mothers split, gender exposure)
- Inspect variable definitions and the equations that produce them
- View quarterly time series for all tracked variables across retained runs
- Load custom variable selections and toggle between runs

The underlying question is: what does the Fair model predict for women's labor force participation (and downstream macro aggregates) under alternative paths for childcare costs, childcare subsidies, paid family leave coverage, caregiver leave access, and secondary-earner tax incentives?

---

## Repository Structure

```
fp-gender/
├── README.md                 ← this file
├── reference/
│   ├── methodology.md        ← equation architecture and overlay design
│   └── data-sources.md       ← data source details and provenance
├── docs/                     ← static site export (GitHub Pages root)
│   ├── index.html
│   ├── app.js
│   ├── styles.css
│   ├── runs/                 ← per-run JSON payloads (22 scenarios)
│   ├── dictionary.json       ← variable and equation metadata
│   ├── presets.json
│   ├── manifest.json
│   └── .nojekyll
├── specs/
│   └── gender-runs.spec.yaml ← export specification
├── data/
│   ├── series/               ← quarterly CSV input series (6 files)
│   ├── reports/              ← provenance JSON reports (5 files)
│   └── README.md
└── scripts/
    └── refresh_from_fp_wraptr.sh
```

---

## Run Families

The site presents 22 scenarios organized into seven question families. Each family has a base run and one or more shock/relief variants that perturb a specific policy input relative to that base.

| Family | Scenarios | Base Type | Policy Variable | Question |
|--------|:---------:|-----------|-----------------|----------|
| Childcare Affordability | 3 | Observed/live | `GCCOST` | What if childcare costs were lower or higher than the observed path? |
| Childcare Subsidy | 3 | Stock-equivalent | `GCSUB` | What if childcare subsidy support were introduced or removed? |
| Childcare Package | 4 | Stock-equivalent | `GCCOST` + `GCSUB` | What if cost relief and subsidy support moved together? |
| Paid Leave | 3 | Observed/live | `GPFL` | What if paid family leave coverage expanded or contracted? |
| Caregiver Leave (proxy) | 3 | Observed/live | `GPFL` | What if caregiver leave access changed? Uses BLS unpaid family leave as proxy. |
| Tax Wedge (proxy) | 3 | Observed/live | `GTAXWD` | What if the secondary-earner tax wedge widened or narrowed? |
| Mothers Paid Leave (prototype) | 3 | Observed/live | `GPFL` | Same paid-leave question, explicitly tracking mothers vs non-mothers labor force. |

### Base type conventions

- **Observed/live base**: The base scenario loads the actual historical data path for the policy variable and carries it forward into the forecast window. Relief and shock variants shift the path relative to that observed trajectory.
- **Stock-equivalent base**: The policy variable is zero in the base. The base run approximates what the Fair model would produce without that policy channel active. Relief and shock variants show the marginal effect of introducing the policy.

> **Important**: Compare runs within a family against that family's own base. Cross-family base comparisons can be misleading because different families activate different policy channels from different starting conditions. See [Interpretation and limitations](#interpretation-and-limitations).

### Full scenario listing

<details>
<summary>All 22 scenarios (click to expand)</summary>

**Childcare Affordability** (observed/live base)
- `gender-childcare-observed-base` — Observed childcare cost path
- `gender-childcare-affordability-relief` — Lower childcare costs
- `gender-childcare-affordability-shock` — Higher childcare costs

**Childcare Subsidy** (stock-equivalent base)
- `gender-childcare-subsidy-base` — Zero-subsidy baseline
- `gender-childcare-subsidy-relief` — Positive subsidy introduced
- `gender-childcare-subsidy-shock` — Negative subsidy shock

**Childcare Package** (stock-equivalent base)
- `gender-childcare-package-base` — Zero-baseline for both channels
- `gender-childcare-package-cost-relief` — Cost relief only
- `gender-childcare-package-subsidy-relief` — Subsidy support only
- `gender-childcare-package-combined-relief` — Both together

**Paid Leave** (observed/live base)
- `gender-paid-leave-base` — Observed paid-leave coverage
- `gender-paid-leave-relief` — Higher coverage
- `gender-paid-leave-shock` — Lower coverage

**Caregiver Leave Proxy** (observed/live base)
- `gender-caregiver-base` — Observed caregiver proxy path
- `gender-caregiver-relief` — More caregiver leave access
- `gender-caregiver-shock` — Less caregiver leave access

**Tax Wedge Proxy** (observed/live base)
- `gender-tax-wedge-base` — Observed tax-wedge path
- `gender-tax-wedge-relief` — Narrower tax wedge
- `gender-tax-wedge-shock` — Wider tax wedge

**Mothers Paid Leave Prototype** (observed/live base)
- `gender-mothers-paid-leave-base` — Observed paid-leave with mothers/non-mothers split tracking
- `gender-mothers-paid-leave-relief` — Higher coverage, split tracked
- `gender-mothers-paid-leave-shock` — Lower coverage, split tracked

</details>

### Headline results at 2029 Q4

<details>
<summary>End-of-forecast values and variant-vs-base differences (click to expand)</summary>

All values are at 2029 Q4 (the last forecast period). Differences are variant minus the family's own base.

**Reading the tables.** `L2` is women 25-54 labor force (millions). `UR` is the unemployment rate. `GDPR` is real GDP (billions, 2017 dollars). `PIEF` is business fixed investment (billions). `L2M` and `L2N` are mothers' and non-mothers' labor force. `L2M share` is mothers' fraction of total `L2`. `GMWEDGE` is the log participation-rate wedge (log of mothers' LFPR / non-mothers' LFPR; more negative = larger gap).

The split variables (`L2M share`, `GMWEDGE`) now vary across scenarios — the wedge equation produces genuinely differential mothers/non-mothers responses. The `L2M %` and `L2N %` columns show each group's percentage change from the base, making it possible to compare how each group responds in rate terms.

#### Childcare Affordability (observed/live base)

| Run | L2 | UR | GDPR | PIEF |
|-----|---:|---:|-----:|-----:|
| Observed base | 47.15 | 3.72% | 6,552 | 1,243 |

| Variant | dL2 | dUR | dGDPR | L2M % | L2N % | dShare |
|---------|----:|----:|------:|------:|------:|-------:|
| Relief (lower costs) | +1.31 | +0.19 pp | +18 | +2.91% | +2.67% | +0.0006 |
| Shock (higher costs) | −1.28 | −0.17 pp | −18 | −2.84% | −2.61% | −0.0006 |

Childcare affordability is the strongest direct policy channel. When childcare costs fall, mothers re-enter the labor force faster than non-mothers (2.91% vs 2.67%), widening mothers' share. This differential comes from the `GCCOST` coefficient in the wedge equation (−0.010): lower costs directly narrow the mothers/non-mothers participation gap.

The aggregate effects are large: a 25% childcare cost reduction produces 1.31 million additional women in the labor force and $18 billion in additional real GDP by 2029.

The unemployment rate *rises* when `L2` rises — this is standard in macro models. More women entering the labor force increases the labor supply faster than firms hire. Employment expands ($GDPR$ up), but not one-for-one with the labor force expansion. The `PIEF` decline reflects interest-rate crowding out: higher output tightens the economy, pushing up rates and reducing some business investment.

#### Childcare Subsidy (stock-equivalent base)

| Run | L2 | UR | GDPR | PIEF |
|-----|---:|---:|-----:|-----:|
| Stock-equivalent base | 52.58 | 4.53% | 6,621 | 1,209 |

| Variant | dL2 | dUR | dGDPR | L2M % | L2N % | dShare |
|---------|----:|----:|------:|------:|------:|-------:|
| Relief (+0.10 subsidy) | +1.51 | +0.25 pp | +18 | +2.91% | +2.84% | +0.0002 |
| Shock (−0.10 subsidy) | −1.47 | −0.23 pp | −18 | −2.83% | −2.77% | −0.0002 |

The subsidy channel operates primarily through the aggregate (TBL2 weights), not the wedge equation — `GCSUB` is not a regressor in EQ 9. The small share differential (+0.0002 vs affordability's +0.0006) comes entirely from indirect general-equilibrium feedback: the `UR` term in the wedge equation transmits the aggregate labor market shift to the split.

Note the higher base `L2` (52.58 vs 47.15 for affordability). This reflects the stock-equivalent framing: the base has zero childcare cost burden, so women's participation is higher than under the observed cost path.

#### Childcare Package (stock-equivalent base)

| Run | L2 | UR | GDPR | PIEF |
|-----|---:|---:|-----:|-----:|
| Stock-equivalent base | 47.15 | 3.72% | 6,552 | 1,243 |

| Variant | dL2 | dUR | dGDPR | L2M % | L2N % | dShare |
|---------|----:|----:|------:|------:|------:|-------:|
| Cost relief only | +1.31 | +0.19 pp | +18 | +2.91% | +2.67% | +0.0006 |
| Subsidy relief only | +1.37 | +0.19 pp | +18 | +2.94% | +2.88% | +0.0001 |
| Combined | +2.71 | +0.39 pp | +36 | +5.93% | +5.61% | +0.0007 |

The combined run is approximately additive: the joint cost + subsidy relief produces 2.71 million additional workers, close to the sum of the individual effects (1.31 + 1.37 = 2.68). The share differential (+0.0007) likewise sums the individual channels. Cost relief drives most of the differential because `GCCOST` enters the wedge equation directly, while subsidy support enters only through the aggregate.

#### Paid Leave (observed/live base)

| Run | L2 | UR | GDPR | PIEF |
|-----|---:|---:|-----:|-----:|
| Observed base | 56.75 | 5.23% | 6,668 | 1,197 |

| Variant | dL2 | dUR | dGDPR | L2M % | L2N % | dShare |
|---------|----:|----:|------:|------:|------:|-------:|
| Relief (+5 pp coverage) | +0.80 | +0.14 pp | +9 | +1.37% | +1.45% | −0.0002 |
| Shock (−5 pp coverage) | −0.79 | −0.14 pp | −9 | −1.35% | −1.44% | +0.0002 |

Expanding paid leave coverage increases aggregate `L2` (+0.80M) and GDP (+$9B), but non-mothers respond slightly *more* than mothers in rate terms (1.45% vs 1.37%). The mothers' share of `L2` actually *declines* (−0.0002) under relief.

This counterintuitive differential merits careful interpretation. The estimated `GPFL` coefficient in the wedge equation is −0.012, meaning higher paid leave coverage is associated with a wider mothers/non-mothers gap (mothers falling further behind) in the 2010-2023 ACS data. This likely reflects omitted confounders rather than a true negative effect of leave on mothers: paid leave coverage expanded during the same period as rapid childcare cost growth and other compositional shifts. With only 14 years of annual ACS observations informing the `GPFL` wedge coefficient, the estimate is noisy and should not be read as causal. The aggregate response (+0.80M workers, consistent across mothers and non-mothers) is the more robust finding.

#### Caregiver Leave Proxy (observed/live base)

| Run | L2 | UR | GDPR |
|-----|---:|---:|-----:|
| Observed base | 67.61 | 7.23% | 6,780 |

| Variant | dL2 | dUR | dGDPR |
|---------|----:|----:|------:|
| Relief | +0.37 | +0.07 pp | +4 |
| Shock | −0.37 | −0.07 pp | −4 |

**Split results omitted.** The caregiver family loads BLS unpaid family leave rates (~0.90) into the same `GPFL` channel where the wedge equation was estimated on paid leave data (~0.11-0.27). This out-of-sample extrapolation causes the wedge to diverge to −9.5 (essentially zero mothers' share), making the `L2M`/`L2N` decomposition meaningless. Aggregate `L2` results remain directionally valid: more caregiver leave access → more women in the labor force.

#### Tax Wedge Proxy (observed/live base)

| Run | L2 | UR | GDPR | PIEF |
|-----|---:|---:|-----:|-----:|
| Observed base | 50.49 | 4.20% | 6,595 | 1,219 |

| Variant | dL2 | dUR | dGDPR | L2M % | L2N % | dShare |
|---------|----:|----:|------:|------:|------:|-------:|
| Relief (−2 pp wedge) | +0.29 | +0.04 pp | +4 | +0.79% | +0.39% | +0.0010 |
| Shock (+2 pp wedge) | −0.29 | −0.04 pp | −4 | −0.78% | −0.39% | −0.0010 |

The tax wedge proxy produces the **largest differential response** of any family: mothers respond at roughly **twice the rate** of non-mothers (0.79% vs 0.39%), producing a share shift of ±0.0010 — nearly double the childcare affordability differential. The `GTAXWD` coefficient in the wedge equation is −0.097 (the largest absolute coefficient), indicating that the secondary-earner tax wedge has a strong estimated association with the mothers/non-mothers participation differential.

This is economically coherent. The OECD tax wedge measures the marginal tax disincentive on the secondary earner in a two-earner household. Mothers, who are disproportionately secondary earners, face this disincentive more directly. A narrower wedge reduces the tax penalty on the second income, making labor force participation relatively more attractive for mothers than for non-mothers.

The aggregate `L2` effect is modest (+0.29M for a 2pp wedge reduction) because the tax-wedge weight in the aggregate `TBL2` channel is calibrated conservatively. The differential signal is the main finding.

#### Mothers Paid Leave Prototype (observed/live base)

| Run | L2 | UR | GDPR | PIEF |
|-----|---:|---:|-----:|-----:|
| Observed base | 56.75 | 5.23% | 6,668 | 1,197 |

| Variant | dL2 | dUR | dGDPR | L2M % | L2N % | dShare |
|---------|----:|----:|------:|------:|------:|-------:|
| Relief (+5 pp coverage) | +0.80 | +0.14 pp | +9 | +1.37% | +1.45% | −0.0002 |
| Shock (−5 pp coverage) | −0.79 | −0.14 pp | −9 | −1.35% | −1.44% | +0.0002 |

The mothers prototype uses the same paid-leave inputs and produces the same results as the paid leave family. The family exists to explicitly surface `L2M` and `L2N` tracking in the site UI. See the paid leave discussion above for interpretation.

#### Cross-cutting patterns

**Aggregate labor supply expansion raises the unemployment rate.** In every family, a policy improvement (lower costs, more subsidies, more leave, narrower tax wedge) increases `L2` and raises `UR`. This is a standard result in macroeconometric models: the labor force expands faster than employment can absorb new entrants. Employment does rise (reflected in higher `GDPR`), but not one-for-one with labor supply. The `UR` increase is not a sign of worse labor market outcomes — it reflects more people seeking work.

**Investment crowding out.** `PIEF` (business fixed investment) consistently declines when `L2` and `GDPR` rise. The mechanism: more output → tighter economy → higher prices and interest rates → less investment. This is a model feature, not an economic prediction — it reflects the Fair model's simultaneous interest-rate determination.

**Differential channel strength varies.** The mothers' share response (how much `L2M/L2` shifts) differs sharply by family:

| Family | dShare (relief) | Source of differential |
|--------|----------------:|----------------------|
| Tax Wedge | +0.0010 | Direct: `GTAXWD` in wedge equation (−0.097) |
| Childcare Affordability | +0.0006 | Direct: `GCCOST` in wedge equation (−0.010) |
| Paid Leave | −0.0002 | Direct: `GPFL` in wedge equation (−0.012), sign counterintuitive |
| Childcare Subsidy | +0.0002 | Indirect only: UR feedback through wedge |

Families with direct policy regressors in the wedge equation (GCCOST, GPFL, GTAXWD) produce larger differential responses. The subsidy family, which lacks a direct wedge regressor, produces only the indirect UR-feedback differential. The tax wedge has the largest differential-to-aggregate ratio: a small aggregate `L2` change (+0.29M) produces a disproportionately large split shift.

**Interpretive caution.** The wedge equation coefficients are estimated on 19 years of ACS PUMS data (2005-2024, excluding 2020). They capture associations, not causally identified effects. The `GPFL` sign (negative — more leave widens the gap) contradicts the typical prior that paid leave helps mothers. This likely reflects omitted trends during the 2010-2023 expansion of leave coverage, not a true adverse effect of leave on mothers' labor force attachment. All differential results should be read as "model-implied compositional shifts conditional on the ACS-era estimation," not as causal impact estimates.

</details>

---

## Fair Model Modifications

All gender runs use a modified version of the Fair US macroeconometric model. The modifications are applied as a text overlay to the stock `fminput.txt` input deck. The design has two layers: an **aggregate policy channel** through Equation 6's trend term, and a **wedge equation** (EQ 9) that governs the mothers/non-mothers participation rate differential.

For the full equation-level walkthrough, see [`reference/methodology.md`](reference/methodology.md).

### Stock Equation 6

In the unmodified Fair model, Equation 6 governs total women 25-54 labor force:

```
EQ 6 LL2Z  CNST2L2 C TBL2 T LL2Z(-1) LAAZ(-1) UR ;
LHS L2=EXP(LL2Z)*POP2;
```

`LL2Z` is the log participation rate, `TBL2 = T * CNST2L2` is a piecewise time trend, and `L2` is the women 25-54 labor force level.

### Gender overlay: aggregate + wedge

The overlay preserves stock EQ 6 for aggregate `L2` and adds a **wedge equation** (EQ 9) that forecasts `GMWEDGE`, the log ratio of mothers' to non-mothers' participation rates:

```
EQ 6 LL2Z  CNST2L2 C TBL2 T LL2Z(-1) LAAZ(-1) UR ;   (stock, unchanged)
LHS L2=EXP(LL2Z)*POP2;

EQ 9 GMWEDGE C GMWEDGE(-1) GCCOST GPFL GTAXWD UR ;    (wedge equation)
```

The stock EQ 9 (an unused placeholder `NONE9`) is repurposed for the wedge equation. The aggregate `U` and `UR` identities remain stock.

Policy affects the model through two channels:

1. **Aggregate channel**: Policy variables enter `TBL2` through calibrated weights (`GCCOSTWT*GCCOST + ...`), shifting aggregate `L2`.
2. **Differential channel**: The same policy variables appear as regressors in the wedge equation (EQ 9), with coefficients estimated from ACS PUMS data (2005-2024). This determines how the mothers/non-mothers split responds.

After the forecast solve, `L2M` and `L2N` are recovered from aggregate `L2` and the forecast wedge:

```
POP2M = GMOTHSHR * POP2
POP2N = (1-GMOTHSHR) * POP2
L2NZ  = L2Z / ((1-GMOTHSHR) + GMOTHSHR * EXP(GMWEDGE))
L2MZ  = EXP(GMWEDGE) * L2NZ
L2M   = L2MZ * POP2M
L2N   = L2NZ * POP2N
```

### What the overlay changes

| Component | Stock Fair | Gender Overlay |
|-----------|-----------|----------------|
| EQ 6 | Total women 25-54 (`LL2Z`) | Stock + policy-augmented `TBL2` |
| EQ 9 | Unused placeholder (`NONE9`) | Wedge equation (`GMWEDGE`), estimated on ACS 2005-2024 |
| `TBL2` | `T * CNST2L2` | `T*CNST2L2 + GCCOSTWT*GCCOST + GCSUBWT*GCSUB + GPFLWT*GPFL + GTAXWT*GTAXWD` |
| `U`, `UR` | Stock identities | Stock identities (unchanged) |
| `L2M`, `L2N` | Not present | Recovered post-solve from `L2` + `GMWEDGE` |
| Data includes | `FMEXOG.TXT` | `gdata.txt` + `FMEXOG.TXT` + `ginputs.txt` |

### Key design points

- **Aggregate dynamics come from the validated Fair equation.** Stock EQ 6 governs total `L2`. The policy-augmented `TBL2` shifts the aggregate forecast; the estimated coefficients on `TBL2` capture the aggregate response.
- **Subgroup-differential behavior comes from the wedge equation.** EQ 9 is estimated only on the ACS-observed window (2005-2024, excluding 2020) where independent mothers/non-mothers participation data exists. The wedge coefficients are estimated, not calibrated.
- **Policy enters both channels.** Childcare costs, paid leave, and tax wedge appear as regressors in the wedge equation (directly estimated effect on the split) and as weighted terms in `TBL2` (calibrated aggregate effect).
- **`L2M` and `L2N` are recovery identities, not equation outputs.** They are derived post-solve from aggregate `L2` and the forecast wedge. This is the correct architecture: the aggregate is trusted from the macro engine, and the split is learned from ACS data.

### Wedge equation estimation

EQ 9 is estimated by 2SLS on the ACS-observed window (2005.1-2024.4), with 2020 quarters excluded via MODEQ dummies (Census did not release standard ACS 1-year estimates for 2020). The estimated coefficients at the current calibration:

| Regressor | Coefficient | Interpretation |
|-----------|-------------|----------------|
| C | −0.024 | Intercept |
| GMWEDGE(−1) | 0.498 | Persistence (moderate) |
| GCCOST | −0.010 | Higher childcare cost narrows mothers' relative advantage |
| GPFL | −0.012 | More paid leave widens the gap (mothers respond proportionally less in the current estimation) |
| GTAXWD | −0.097 | Tax wedge effect on the differential |
| UR | +0.134 | Higher unemployment widens the gap (mothers' participation drops more in recessions) |

### Weight sign conventions

For the aggregate channel, policy weights in `TBL2` follow the stock `TBL2` coefficient (estimated as negative):

| Weight | Sign | Interpretation |
|--------|------|----------------|
| `GCCOSTWT` | Positive | Higher cost adds to `TBL2`, reducing aggregate participation |
| `GCSUBWT` | Negative | Higher subsidy subtracts from `TBL2`, increasing participation |
| `GPFLWT` | Negative | More leave subtracts from `TBL2`, increasing participation |
| `GTAXWT` | Positive | Higher wedge adds to `TBL2`, reducing participation |

---

## Gender Variables

### Policy input variables

| Variable | Meaning | Type | Source |
|----------|---------|------|--------|
| `GCCOST` | Childcare cost index (2008 base) | Data input | DOL National Database of Childcare Prices |
| `GCSUB` | Childcare subsidy/support level | Data input | User-specified scenario path |
| `GPFL` | Paid family leave / caregiver leave coverage rate | Data input | BLS National Compensation Survey. The paid leave and caregiver leave families both load data into `GPFL` — they share the same Fair helper channel with different source series. See [Proxy status](#proxy-status). |
| `GTAXWD` | Secondary-earner tax wedge (% of labor costs) | Data input | OECD Taxing Wages |

### Exposure and structural variables

| Variable | Meaning | Type | Derivation |
|----------|---------|------|------------|
| `GMOTHSHR` | Mother share of women 25-54 | Data input | Census ACS PUMS: share with own children under 18 |
| `GMWEDGE` | Log participation-rate wedge, mothers vs non-mothers | Endogenous | Census ACS PUMS historical; forecast from EQ 9 (wedge equation) |
| `POP2M` | Mother population, 25-54 | Derived | `GMOTHSHR * POP2` |
| `POP2N` | Non-mother population, 25-54 | Derived | `(1 - GMOTHSHR) * POP2` |
| `L2M` | Mothers labor force, 25-54 | Recovered | Post-solve from `L2` + `GMWEDGE`: `EXP(GMWEDGE) * L2NZ * POP2M` |
| `L2N` | Non-mothers labor force, 25-54 | Recovered | Post-solve from `L2` + `GMWEDGE`: `L2NZ * POP2N` |
| `L2MZ` | Mothers participation rate | Derived | `EXP(GMWEDGE) * L2NZ` |
| `L2NZ` | Non-mothers participation rate | Derived | `L2Z / ((1-GMOTHSHR) + GMOTHSHR*EXP(GMWEDGE))` |

### Equation helper variables

| Variable | Meaning | Definition |
|----------|---------|------------|
| `TBL2` | Aggregate trend + policy term | `T*CNST2L2 + GCCOSTWT*GCCOST + GCSUBWT*GCSUB + GPFLWT*GPFL + GTAXWT*GTAXWD` |

### Deck constants (per-scenario calibration)

| Variable | Meaning | Sign convention |
|----------|---------|-----------------|
| `GCCOSTWT` | Weight on childcare cost in `TBL2` | Positive: higher cost reduces aggregate participation |
| `GCSUBWT` | Weight on childcare subsidy in `TBL2` | Negative: higher subsidy increases participation |
| `GPFLWT` | Weight on paid leave coverage in `TBL2` | Negative: more leave increases participation |
| `GTAXWT` | Weight on tax wedge in `TBL2` | Positive: higher wedge reduces participation |

---

## Data Sources

| Series File | Source | Observed Range | Fair Variable |
|-------------|--------|----------------|---------------|
| `childcare_cost_national_qtr.csv` | DOL National Database of Childcare Prices (NDCP 2022) | 2008–2022 | `GCCOST` |
| `paid_leave_civilian_qtr.csv` | BLS National Compensation Survey (NB series) | 2010–2023 | `GPFL` |
| `caregiver_leave_civilian_qtr.csv` | BLS National Compensation Survey (NB series) | 2010–2025 | `GPFL` (caregiver family) |
| `tax_wedge_us_qtr.csv` | OECD Taxing Wages 2025, Table 6.6 | 2000–2024 | `GTAXWD` |
| `mother_share_f25_54_qtr.csv` | Census ACS 1-year PUMS | 2005–2024 | `GMOTHSHR` |
| `mother_lfpr_log_wedge_f25_54_qtr.csv` | Census ACS 1-year PUMS (derived) | 2005–2024 | `GMWEDGE` |

All series are step-filled from annual observations to quarterly frequency. Forecast periods carry forward the last observed value unless a relief or shock variant shifts the path. Provenance reports for each series (including observation counts, base years, and exact source identifiers) are in `data/reports/`.

For detailed source documentation including API endpoints, variable definitions, and proxy rationale, see [`reference/data-sources.md`](reference/data-sources.md).

### Proxy status and shared channels

Two families use proxy series rather than direct measures, and one pair shares a Fair model variable:

- **Caregiver leave shares `GPFL` with paid leave.** The caregiver leave family does not introduce a separate Fair variable. It loads a different source series (BLS *unpaid* family leave access) into the same `GPFL` channel that the paid leave family uses (BLS *paid* family leave access). This is a modeling simplification: both families operate through the identical `GPFLWT * GPFL` term in aggregate `TBL2`, just with different data. The caregiver family should be understood as asking "what if the BLS unpaid-family-leave-access rate were different?" routed through the paid-leave helper channel, not as a structurally distinct caregiver policy lever.
- **Caregiver leave is also a proxy measure.** BLS unpaid family leave covers care for a spouse, child, or parent. There is no separate BLS series for caregiver-specific leave. The series is broader than dedicated caregiver leave.
- **Tax wedge** uses the OECD secondary-earner tax wedge for a married couple at specific earnings levels, not a gender-specific individual tax rate. The proxy assumption is that secondary earners are disproportionately women.

---

## Build and Refresh

### How fp-gender is built from fp-wraptr

The public site and data are generated from `fp-wraptr` through a two-stage process:

1. **Model runs**: Scenarios are compiled and executed using `fp.exe` (the Fair model executable) within `fp-wraptr`. Retained outputs are stored as artifacts under `fp-wraptr/artifacts-gender/`. Each artifact directory contains the compiled input deck, model outputs (LOADFORMAT, PABEV, PACEV files), and a `scenario.yaml` manifest.

2. **Export**: The `fp export pages` command (backed by `fp_wraptr.pages_export.export_pages_bundle()`) reads the export specification, resolves the latest matching artifact for each `scenario_name`, extracts time series from model outputs, builds variable/equation metadata, and writes a fully static site bundle into `docs/`.

### Export specification

The file `specs/gender-runs.spec.yaml` (mirrored from `fp-wraptr/public/gender-runs.spec.yaml`) defines:

- Which scenarios to include, identified by `scenario_name` matching against artifact directory names
- Display labels, summaries, and detail notes for each run
- Variable presets for the site UI
- Default run and preset selections on page load

### Refresh script

```bash
# Set FP_WRAPTR_ROOT if fp-wraptr is not in the default adjacent location
# Set PYTHON_BIN if using a different Python environment
scripts/refresh_from_fp_wraptr.sh
```

The script performs three steps:

1. **Copies the export spec** from `fp-wraptr/public/gender-runs.spec.yaml` into `specs/`
2. **Copies public-source data** — six quarterly CSV series and five provenance JSON reports from `fp-wraptr/projects_local/gender/data/` into `data/series/` and `data/reports/`
3. **Runs the export pipeline** — invokes `export_pages_bundle()` from within the `fp-wraptr` directory, writing JSON payloads and the static site template into `docs/`

### What goes where

| From `fp-wraptr` | To `fp-gender` | Content |
|-------------------|----------------|---------|
| `public/gender-runs.spec.yaml` | `specs/gender-runs.spec.yaml` | Export specification |
| `projects_local/gender/data/series/*.csv` | `data/series/` | Six quarterly CSV input series |
| `projects_local/gender/data/reports/*.json` | `data/reports/` | Five provenance reports |
| `artifacts-gender/*/` (via export pipeline) | `docs/runs/*.json` | Per-run time series payloads |
| (export pipeline) | `docs/dictionary.json` | Variable and equation metadata |
| (export pipeline) | `docs/presets.json`, `docs/manifest.json` | Presets and site manifest |
| `src/fp_wraptr/model_runs_static/` | `docs/` (HTML, JS, CSS, assets) | Static site template |

### GitHub Pages

The site is served from the `docs/` directory. The `.nojekyll` file tells GitHub Pages to serve files directly without Jekyll processing.

---

## Browsing the Site

### Presets

The site ships with four variable presets:

| Preset | Variables | Use for |
|--------|-----------|---------|
| **Headline Macro** | `L2`, `UR`, `PCY`, `GDPR`, `PIEF` | Aggregate labor market and macro impact |
| **Policy Inputs** | `GCCOST`, `GCSUB`, `GPFL`, `GTAXWD` | Inspecting the data paths underlying each scenario |
| **Mothers Split** | `L2M`, `L2N`, `L2`, `UR`, `GDPR`, `PIEF` | Mothers vs non-mothers labor force response |
| **Gender Exposure** | `GMOTHSHR`, `GMWEDGE`, `L2M`, `L2N` | Exposure parameters and split initialization inputs |

### What to look at first

1. **Start with the default view.** The site opens on the Childcare Package runs with the Headline Macro preset. This shows how childcare cost relief, subsidy support, and the combined package affect aggregate women's labor force (`L2`) and the unemployment rate (`UR`).

2. **Compare across families.** Switch to the paid leave, caregiver leave, or tax wedge families to compare the relative model response across different policy channels. Look at `L2` and `UR` across families.

3. **Inspect the mothers split.** Select the Mothers Paid Leave runs and switch to the Mothers Split preset. This shows how paid-leave changes affect mothers (`L2M`) vs non-mothers (`L2N`) differently within the prototype.

4. **Verify data paths.** Use the Policy Inputs preset to confirm which scenarios actually load non-zero data for each policy variable.

### How to interpret run families

Each family defines a self-contained counterfactual question:

- The **base** run represents the reference forecast trajectory
- **Relief** scenarios improve the policy variable (lower costs, more leave, narrower wedge)
- **Shock** scenarios worsen the policy variable

What you see in the charts is: "given the estimated Fair model structure, what would the forecast look like if this policy input followed a different path?" The model propagates the policy change through general equilibrium feedbacks — labor supply affects employment, which affects output, income, wages, and prices, which feed back into labor supply.

---

## Interpretation and Limitations

### What is empirically grounded

The results rest on several layers of empirical content:

- **The Fair model's macro dynamics** (EQ 6 and the simultaneous system) are estimated by 2SLS on ~70 years of quarterly US macroeconomic data (1954-2025). The model's aggregate labor supply, output, price, and interest rate responses have been publicly documented and refined over decades. The general equilibrium feedbacks (UR rising with labor supply expansion, PIEF crowding out through interest rates) are standard macro model properties, not gender-specific engineering.

- **The policy input series** are drawn from official public sources with transparent provenance: DOL childcare costs (NDCP 2022), BLS paid/unpaid family leave coverage (NCS), OECD secondary-earner tax wedge (Taxing Wages 2025), Census ACS PUMS mother share and participation rates. These are observed data, not simulated.

- **The wedge equation coefficients** are estimated from ACS PUMS data (2005-2024) using the same 2SLS framework as the rest of the Fair model. The coefficients capture empirical associations between policy environments and the mothers/non-mothers participation differential. The estimated signs — childcare costs and tax wedges widening the gap, unemployment widening the gap — are consistent with the labor supply literature. The magnitudes are data-driven, not imposed.

- **The mothers/non-mothers split recovery** is algebraically exact: `L2M + L2N = L2` by construction at every period. No approximation or assumption is involved in decomposing the aggregate into components.

### Aggregate policy weights and implied elasticities

The aggregate policy channel uses calibrated weights (`GCCOSTWT`, `GPFLWT`, etc.) that are **not estimated from data** — they are set to ±100 as round-number deck constants. The aggregate response magnitudes scale linearly with these weights.

This is a standard feature of reduced-form overlay work: every policy simulation model, including those used by the CBO, Federal Reserve, and Fair's own published scenarios, involves calibrated effect sizes for policy channels that are not directly estimated from the model's historical data. The relevant question is not whether the weights are estimated, but whether the implied effect sizes are in a plausible range.

At the current calibration (weight = 100), the implied elasticities are:

| Policy | Shock | Aggregate L2 response | Implied elasticity | Literature range |
|--------|-------|----------------------|-------------------|------------------|
| Childcare cost | 25% cost reduction | +1.31M (+2.8%) | −0.11 | −0.05 to −1.1; most estimates ~−0.1 ([Morrissey 2017](#references)) |
| Paid leave | +5 pp coverage | +0.80M (+1.4%) | +0.28 per pp | Limited direct estimates |
| Tax wedge | −2 pp wedge | +0.29M (+0.6%) | −0.30 per pp | Consistent with large secondary-earner elasticities ([Keane 2011](#references)) |
| Childcare subsidy | +0.10 subsidy unit | +1.51M (+2.9%) | +0.29 per unit | No direct comparable (constructed variable) |

The childcare cost elasticity of −0.11 falls at the low end of the published range. Morrissey (2017) reviews the US literature and reports that most estimates cluster around −0.1, implying a 10% decrease in childcare cost increases maternal employment by about 1%. Blau and Currie (2006) survey a wider range (−0.05 to −1.1) depending on methodology and population. The current calibration is conservative rather than aggressive. The weights could be refined by calibrating each to the midpoint of the relevant empirical literature, but the current values produce responses within the range that peer-reviewed studies consider plausible.

**What the weights determine and don't determine.** The weights set the *aggregate* magnitude — how much total `L2` moves. They do not affect the *differential* (how `L2M` vs `L2N` respond relative to each other), which is governed by the estimated wedge equation coefficients. The ranking of differential effects across families — tax wedge producing the largest mothers-specific shift, childcare cost next, paid leave smallest — comes from estimation, not calibration.

### Wedge equation: strengths and limits

The wedge equation (EQ 9) is estimated on ACS PUMS data from 2005-2024. It is the empirical core of the differential split.

**Strengths:**

- The ACS PUMS is the gold-standard US household survey for labor force characteristics by demographic subgroup. The `PAOC`-based mother/non-mother classification is well-defined and covers the exact Fair model age band (25-54).
- The wedge captures the *relative* participation behavior of mothers vs non-mothers — the empirical object that ACS actually measures independently. This is a better-identified target than two separate level equations, because the aggregate level is already handled by the validated Fair EQ 6.
- The estimated signs are mostly economically coherent: higher childcare costs and wider tax wedges are associated with a wider mothers/non-mothers gap, and higher unemployment is associated with mothers dropping out more (consistent with the "added worker" and "discouraged worker" literatures finding differential cyclical sensitivity by demographic group).
- The estimation window (2005-2024) covers a period of substantial policy variation: childcare costs rose ~38%, paid leave coverage more than doubled (11% to 27%), and the tax wedge fell from 24.1% to 14.3%.

**Limits:**

- **Small effective sample.** Although 72 quarterly observations enter the estimation, the underlying information is 19 annual ACS snapshots (excluding 2020). The quarterly step-fill does not add independent variation. With 6 regressors, the effective degrees of freedom are approximately 13. Standard errors are wide, and individual coefficient estimates should be treated as suggestive rather than precise.
- **No causal identification.** The coefficients are reduced-form associations, not causally identified effects. Multiple policy variables changed simultaneously over 2005-2024 (childcare costs rose while leave expanded and the tax wedge narrowed), making it difficult to disentangle their independent effects. The GPFL coefficient (−0.012) has a sign that contradicts the standard prior that paid leave helps mothers' labor force attachment. This likely reflects omitted confounders rather than a true negative causal effect, and illustrates the identification limits of a 19-year time series.
- **Step-fill mechanics.** Annual ACS observations are assigned to Q4 and carried forward through the preceding quarters. This produces within-year correlation structure that the quarterly 2SLS estimator does not account for. The persistence parameter (0.498) is lower than typical for a true quarterly AR(1) process, likely reflecting the annual step structure rather than genuine high-frequency dynamics.
- **2020 exclusion.** Census did not release standard ACS 1-year estimates for 2020 due to pandemic data collection issues. The four 2020 quarters are absorbed by MODEQ dummies. This is the correct handling given Census's own guidance, but it removes the most dramatic labor market shock in the sample from the estimation.
- **Caregiver family incompatibility.** The caregiver leave family loads BLS unpaid family leave rates (~0.90) into the `GPFL` variable, but the wedge equation's `GPFL` coefficient was estimated on paid leave data (~0.11-0.27). This out-of-sample extrapolation causes the wedge to diverge. The caregiver family's `L2M`/`L2N` results should be disregarded; its aggregate `L2` results remain valid through the separate TBL2 channel.

**In defense of the approach.** The wedge equation asks a narrow, well-defined empirical question: "over the ACS-observed period, how did the mothers/non-mothers participation gap co-move with childcare costs, leave coverage, tax incentives, and the business cycle?" It answers that question using the best available data (ACS PUMS) on the exact target population (women 25-54 with/without own children under 18). The aggregate macro forecast comes from the stock Fair model — a separate, validated engine. The wedge adds differential content without overriding or destabilizing the aggregate. For a scenario exploration tool, this is a defensible division of labor between the macro engine (trusted, long sample) and the subgroup decomposition (shorter sample, narrower question).

### Proxy variables

- **Caregiver leave** uses BLS unpaid family leave access as a proxy. BLS defines family leave as care for a spouse, child, or parent, which is broader than dedicated caregiver leave. Additionally, as noted above, the caregiver series is incompatible with the wedge equation's estimated GPFL coefficient range.
- **Tax wedge** uses the OECD secondary-earner tax wedge for a married couple at specific earnings levels. This is a household-level composite, not a gender-specific individual tax rate. The proxy assumption — that secondary earners are disproportionately women, and particularly mothers — is well-supported empirically (Bick and Fuchs-Schündeln 2017 find that switching from joint to separate taxation would increase married women's hours by ~10.5% across 17 European countries and the US) but involves averaging over substantial household-level heterogeneity.

### Cross-family base comparisons

Bases differ across families in kind:

- Observed/live bases load actual historical data. The baseline forecast includes the observed trajectory carried forward.
- Stock-equivalent bases set the policy variable to zero. The baseline approximates the model without that policy channel active.

Comparing the childcare affordability base (observed cost path) with the childcare subsidy base (zero subsidy path) does not tell you the relative importance of costs vs subsidies. It tells you the model's trajectory under very different assumptions about the starting state. Within-family comparisons (relief vs base, shock vs base) are the meaningful comparisons.

### Data limitations

- Childcare cost data ends at 2022 and is carried forward at the last observed value. No independent cost forecast is embedded.
- Paid leave data ends at 2023. The forecast carries forward 0.27.
- Caregiver leave data extends to 2025 through the BLS series. The forecast carries forward 0.90.
- Tax wedge observations are annual and step-filled to quarterly.
- Mother share is annual ACS data step-filled to quarterly, backfilled to 1952 at the 2005 level. The 2020 observation is missing (no ACS 1-year PUMS in 2020) and is interpolated.
- `GMOTHSHR` measures women with own children under 18 currently in the household, not all women who have ever been mothers. This is a childcare/leave-exposure proxy, not a demographic motherhood rate.

### Defensibility summary

| Component | Basis | Defensibility |
|-----------|-------|---------------|
| Policy direction signs | Economic theory + estimated wedge coefficients | Strong |
| Aggregate magnitudes | Calibrated weights (±100); implied elasticities in literature range | Moderate — plausible but not externally validated |
| Differential ranking across families | Estimated wedge coefficients | Suggestive — correct qualitative pattern, imprecise magnitudes |
| GE feedbacks (UR, PIEF) | Stock Fair model (decades of use) | Strong for the macro engine |
| Mothers/non-mothers level decomposition | Algebraic identity from L2 + wedge | Exact by construction |
| GPFL wedge coefficient sign | Estimated (contradicts prior) | Weak — likely omitted variable bias |
| Cross-family aggregate comparisons | Different weight calibrations × different shock sizes | Not meaningful (both are design choices) |

### What these runs are

These are scenario counterfactuals within a calibrated macroeconometric framework. They answer: "given the Fair model's structure, publicly observed policy data, and a wedge equation estimated on ACS PUMS, what would the women's labor force and its mothers/non-mothers composition look like under alternative policy paths?"

The directions are empirically grounded. The aggregate magnitudes are calibrated within the range of published elasticity estimates. The differential magnitudes are estimated from data, with the caveats of a short sample and no causal identification. The qualitative patterns — childcare costs and tax wedges mattering most for the mothers/non-mothers split, unemployment widening the gap — are consistent with the broader labor supply literature.

### What these runs are not

- They are not causal impact estimates of specific policy proposals
- They do not model policy implementation details (eligibility rules, take-up rates, employer compliance)
- They do not separately identify supply-side and demand-side labor market channels
- They are not validated against natural experiments or quasi-experimental variation
- The aggregate magnitudes have not been benchmarked against other structural models' predictions for the same policy scenarios

They are a structured, transparent, and empirically informed way to ask "what if?" — and they should be read as such.

---

## Implementation Provenance

The source implementation lives in [`fp-wraptr`](https://github.com/smkwray/fp-wraptr). For anyone wanting to inspect the engine code:

### Core implementation

| File | Purpose |
|------|---------|
| `src/fp_wraptr/gender_family.py` | Core module: overlay generation from stock `fminput.txt`, data refresh for all five datasets, mothers/non-mothers estimation and coefficient analysis |
| `FM/fminput.txt` | Stock Fair model input deck — the baseline that gets overlaid (EQ 6 at line 165, `U`/`UR` identities at lines 300-301, `CNST2L2`/`TBL2` at lines 512/516) |
| `src/fp_wraptr/pages_export.py` | Static site export pipeline: artifact resolution, time series extraction, dictionary/preset generation, safety checks |

### Generated overlay files (under `projects_local/gender/`)

| File | Purpose |
|------|---------|
| `gcommon.txt` | The rewritten model input: stock EQ 6 for aggregate `L2`, repurposed EQ 9 for `GMWEDGE`, rewritten recovery identities, and policy helper terms for the aggregate channel |
| `gbase.txt` | Entry file that chains `gpbase.txt` → `gcommon.txt` |
| `gpbase.txt` | Zero-initializes all policy variables and weights |
| `ginputs.txt` | Regenerates helper terms and split state from loaded data |
| `gdata.txt` | LOADDATA commands for `GCCOST.DAT`, `GCSUB.DAT`, `GPFL.DAT`, `GTAXWD.DAT`, `GMOTHSHR.DAT`, `GMWEDGE.DAT` |

### Scenario and bundle definitions

| File | Purpose |
|------|---------|
| `bundles/gender_*.yaml` | Bundle definitions for each of the seven families |
| `examples/gender_*.yaml` | Individual scenario definitions |
| `projects_local/cards/gender/` | Series card and policy card definitions for the scenario authoring UI |
| `projects_local/packs/gender/pack.yaml` | Pack definition with recipes, status, and visualization definitions for all families |

### Design and research documentation

| File | Purpose |
|------|---------|
| `projects_local/gender/README.md` | Family README with data refresh commands and source-path documentation |
| `projects_local/gender/todo.md` | Implementation checklist with completed and blocked items |
| `projects_local/gender/mothers_split_rewrite.md` | Design note for the mothers/non-mothers rewrite: Fair anchors, minimum viable scope, equation targets, data requirements, estimation strategy, and parity status |
| `projects_local/gender/data/research/` | Estimation panels, OLS/2SLS/fp.exe coefficient comparisons, parity overrides |

### Artifact outputs

| File | Purpose |
|------|---------|
| `artifacts-gender/README.md` | Documents the retained artifact structure and base-type conventions |
| `artifacts-gender/*/scenario.yaml` | Per-artifact manifests with `fp_home`, forecast window, backend, and tracked variables |
| `public/gender-runs.spec.yaml` | Export specification defining the public run bundle |

---

## References

Literature cited in the interpretation and calibration discussion:

- Bick, Alexander, and Nicola Fuchs-Schündeln. 2017. "Quantifying the Disincentive Effects of Joint Taxation on Married Women's Labor Supply." *American Economic Review* 107 (5): 100-104. [doi:10.1257/aer.p20171063](https://www.aeaweb.org/articles?id=10.1257/aer.p20171063)

- Blau, David, and Janet Currie. 2006. "Pre-School, Day Care, and After-School Care: Who's Minding the Kids?" In *Handbook of the Economics of Education*, vol. 2, edited by Eric Hanushek and Finis Welch, 1163-1278. Amsterdam: Elsevier. [doi:10.1016/S1574-0692(06)02020-4](https://ideas.repec.org/h/eee/educhp/2-20.html)

- Keane, Michael P. 2011. "Labor Supply and Taxes: A Survey." *Journal of Economic Literature* 49 (4): 961-1075. [doi:10.1257/jel.49.4.961](https://www.aeaweb.org/articles?id=10.1257/jel.49.4.961)

- Morrissey, Taryn W. 2017. "Child Care and Parent Labor Force Participation: A Review of the Research Literature." *Review of Economics of the Household* 15 (1): 1-24. [doi:10.1007/s11150-016-9331-3](https://link.springer.com/article/10.1007/s11150-016-9331-3)

---

## Attribution

The Fair model is due to [Ray Fair](https://fairmodel.econ.yale.edu/) (Yale University). The `fp-wraptr` tooling, the gender overlay, and the documentation in this repository are original work by Shane Wray.

### Data sources

- U.S. Department of Labor, Women's Bureau — [National Database of Childcare Prices](https://www.dol.gov/agencies/wb/topics/childcare/national-database-of-childcare-prices) (2022 edition)
- U.S. Bureau of Labor Statistics — [National Compensation Survey, Employee Benefits](https://www.bls.gov/ncs/) (NB series for paid and unpaid family leave)
- OECD — [Taxing Wages 2025](https://www.oecd.org/en/publications/taxing-wages-2025_b3a95829-en.html), Table 6.6
- U.S. Census Bureau — [American Community Survey 1-Year Public Use Microdata Sample](https://www.census.gov/programs-surveys/acs/microdata.html) (PUMS)
