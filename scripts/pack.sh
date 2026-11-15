#!/usr/bin/env bash
# Build a linux/amd64 theme release archive + SHA256SUMS from this repo root.
# Usage: bash scripts/pack.sh [out-dir]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

OUT_DIR="${1:-dist}"
mkdir -p "${OUT_DIR}"

if [[ ! -f fleet.theme.yaml ]]; then
  echo "missing fleet.theme.yaml in ${ROOT}" >&2
  exit 2
fi

THEME_ID="$(python3 - <<'PY'
import re
from pathlib import Path
text = Path("fleet.theme.yaml").read_text()
m = re.search(r"(?m)^id:\s*[\"']?([^\"'\s#]+)", text)
if not m:
    raise SystemExit("fleet.theme.yaml: missing id")
print(m.group(1).strip())
PY
)"
if [[ -z "${THEME_ID}" ]]; then
  echo "could not read id from fleet.theme.yaml" >&2
  exit 2
fi

# Archive top-level folder = last id segment (e.g. org.example.theme.template → template)
SLUG="${THEME_ID##*.}"
ASSET="${THEME_ID}-linux-amd64.tar.gz"

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
DEST="${STAGE}/${SLUG}"
mkdir -p "${DEST}"

cp -a fleet.theme.yaml "${DEST}/"
if [[ -f theme.css ]]; then
  cp -a theme.css "${DEST}/"
fi
# Optional extra assets referenced by fleet.theme.yaml
CSS_PATH="$(python3 - <<'PY'
import re
from pathlib import Path
text = Path("fleet.theme.yaml").read_text()
m = re.search(r"(?m)^css:\s*[\"']?([^\"'\s#]+)", text)
print((m.group(1).strip() if m else "theme.css"))
PY
)"
if [[ -n "${CSS_PATH}" && "${CSS_PATH}" != "theme.css" && -f "${CSS_PATH}" ]]; then
  mkdir -p "${DEST}/$(dirname "${CSS_PATH}")"
  cp -a "${CSS_PATH}" "${DEST}/${CSS_PATH}"
fi
if [[ -f LICENSE ]]; then
  cp -a LICENSE "${DEST}/LICENSE"
fi

tar -C "${STAGE}" -czf "${OUT_DIR}/${ASSET}" "${SLUG}"
(
  cd "${OUT_DIR}"
  sha256sum "${ASSET}" | tee SHA256SUMS
)
echo "Wrote ${OUT_DIR}/${ASSET}"
