#!/usr/bin/env bash
# Print next semver (no leading v) for a Fleet component repo.
# Env:
#   INITIAL_VERSION  — used when no v*.*.* tags exist (default 0.1.0)
#   MANIFEST         — optional yaml with a top-level version: field (overrides INITIAL_VERSION)
set -euo pipefail

INITIAL_VERSION="${INITIAL_VERSION:-0.1.0}"
if [[ -n "${MANIFEST:-}" && -f "${MANIFEST}" ]]; then
  from_manifest="$(python3 - <<PY
import re
from pathlib import Path
text = Path("${MANIFEST}").read_text()
m = re.search(r"(?m)^version:\s*[\"']?([^\"'\s#]+)", text)
print(m.group(1).strip() if m else "")
PY
)"
  if [[ -n "${from_manifest}" ]]; then
    INITIAL_VERSION="${from_manifest}"
  fi
fi

git fetch --tags --quiet 2>/dev/null || true
latest="$(git tag -l 'v*.*.*' --sort=-v:refname | head -n1 || true)"
if [[ -z "${latest}" ]]; then
  echo "${INITIAL_VERSION#v}"
  exit 0
fi

ver="${latest#v}"
IFS=. read -r major minor patch <<<"${ver}"
major="${major:-0}"
minor="${minor:-0}"
patch="${patch:-0}"
echo "${major}.${minor}.$((patch + 1))"
