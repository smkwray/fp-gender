#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_FP_WRAPTR_ROOT="$(cd "${REPO_ROOT}/../../fp-wraptr" 2>/dev/null && pwd || true)"
FP_WRAPTR_ROOT="${FP_WRAPTR_ROOT:-${DEFAULT_FP_WRAPTR_ROOT}}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ -z "${FP_WRAPTR_ROOT}" || ! -d "${FP_WRAPTR_ROOT}" ]]; then
  echo "FP_WRAPTR_ROOT is not set to a valid fp-wraptr checkout." >&2
  exit 1
fi

mkdir -p "${REPO_ROOT}/specs" "${REPO_ROOT}/data/series" "${REPO_ROOT}/data/reports"

cp "${FP_WRAPTR_ROOT}/public/gender-runs.spec.yaml" "${REPO_ROOT}/specs/gender-runs.spec.yaml"

for rel_path in \
  "projects_local/gender/data/series/caregiver_leave_civilian_qtr.csv" \
  "projects_local/gender/data/series/childcare_cost_national_qtr.csv" \
  "projects_local/gender/data/series/mother_lfpr_log_wedge_f25_54_qtr.csv" \
  "projects_local/gender/data/series/mother_share_f25_54_qtr.csv" \
  "projects_local/gender/data/series/paid_leave_civilian_qtr.csv" \
  "projects_local/gender/data/series/tax_wedge_us_qtr.csv" \
  "projects_local/gender/data/reports/caregiver_leave_civilian_qtr.json" \
  "projects_local/gender/data/reports/childcare_cost_national_qtr.json" \
  "projects_local/gender/data/reports/mother_share_f25_54_qtr.json" \
  "projects_local/gender/data/reports/paid_leave_civilian_qtr.json" \
  "projects_local/gender/data/reports/tax_wedge_us_qtr.json"; do
  src="${FP_WRAPTR_ROOT}/${rel_path}"
  if [[ ! -f "${src}" ]]; then
    echo "Missing expected source file: ${src}" >&2
    exit 1
  fi
  if [[ "${rel_path}" == *"/series/"* ]]; then
    cp "${src}" "${REPO_ROOT}/data/series/"
  else
    cp "${src}" "${REPO_ROOT}/data/reports/"
  fi
done

(
  cd "${FP_WRAPTR_ROOT}"
  export FP_GENDER_ROOT="${REPO_ROOT}"
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONPYCACHEPREFIX=/private/tmp/fp-wraptr-pycache \
  "${PYTHON_BIN}" - <<'PY'
import os
from pathlib import Path
from fp_wraptr.pages_export import export_pages_bundle

fp_root = Path.cwd().resolve()
target_root = Path(os.environ["FP_GENDER_ROOT"]).resolve()
result = export_pages_bundle(
    spec_path=fp_root / "public" / "gender-runs.spec.yaml",
    artifacts_dir=fp_root / "artifacts-gender",
    out_dir=target_root / "docs",
)
print(result.out_dir)
print(result.run_count, result.variable_count, result.generated_at)
PY
)

echo "Refreshed fp-gender from ${FP_WRAPTR_ROOT}"
