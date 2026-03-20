# data/

Public-source derived inputs and provenance reports for the gender run bundle.

## series/

Quarterly CSV series used as Fair model inputs. Each file has two columns: `period` (e.g., `2010.1`) and `value`.

| File | Fair Variable | Source | Observed Range |
|------|--------------|--------|----------------|
| `childcare_cost_national_qtr.csv` | `GCCOST` | DOL NDCP 2022 | 2008–2022 |
| `paid_leave_civilian_qtr.csv` | `GPFL` | BLS NCS | 2010–2023 |
| `caregiver_leave_civilian_qtr.csv` | `GPFL` | BLS NCS (unpaid family leave proxy) | 2010–2025 |
| `tax_wedge_us_qtr.csv` | `GTAXWD` | OECD Taxing Wages 2025 | 2000–2024 |
| `mother_share_f25_54_qtr.csv` | `GMOTHSHR` | Census ACS PUMS | 2005–2024 |
| `mother_lfpr_log_wedge_f25_54_qtr.csv` | `GMWEDGE` | Census ACS PUMS (derived) | 2005–2024 |

## reports/

JSON provenance reports recording observation counts, base years, source identifiers, and refresh metadata for each series.

## Source

These files are copied from `fp-wraptr/projects_local/gender/data/` by [`scripts/refresh_from_fp_wraptr.sh`](../scripts/refresh_from_fp_wraptr.sh). For detailed source documentation, see [`reference/data-sources.md`](../reference/data-sources.md).
