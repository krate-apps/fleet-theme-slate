#!/usr/bin/env bash
# Set top-level version: in a Fleet YAML manifest to VERSION (no leading v).
# Usage: sync-manifest-version.sh <manifest> <version>
set -euo pipefail

MANIFEST="${1:?manifest path}"
VERSION="${2:?version}"
VERSION="${VERSION#v}"

python3 - <<PY
from pathlib import Path
import re
path = Path("${MANIFEST}")
text = path.read_text()
new, n = re.subn(
    r"(?m)^version:\s*.*$",
    f"version: ${VERSION}",
    text,
    count=1,
)
if n != 1:
    raise SystemExit(f"{path}: could not update version field")
path.write_text(new)
print(f"synced {path} version=${VERSION}")
PY
