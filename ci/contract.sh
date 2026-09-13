#!/usr/bin/env bash
#
# Check that the copies of the hardware class's contract documents, in
# projects/P03/contract/, still match the originals.
#
# The originals live in the hardware course's repository and are the source of truth; this
# repository carries verbatim copies so that the contract is available to students without that
# repository. register_map.md states the update order: the original first, the copy in the same
# go, the code last. This check is what makes a forgotten second step visible.
#
# The originals live in the hardware course's repository:
#
#   https://github.com/Yrgo-26/programmable-logic
#
# Clone it wherever you like and point CONTRACT_SRC at its project/ directory. The check skips
# cleanly when CONTRACT_SRC is unset or missing, which is the normal case in CI and on a
# student's laptop.
#
# Usage:
#   CONTRACT_SRC=<path>/programmable-logic/project ci/contract.sh
set -euo pipefail

# Root directory.
ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."

# Navigate to the root directory.
cd "$ROOT_DIR"

# Where the originals live. No default: the hardware repository may be cloned anywhere, so the
# path is given explicitly rather than assumed.
CONTRACT_SRC="${CONTRACT_SRC:-}"

# Where the copies live.
CONTRACT_DST="projects/P03/contract"

# The documents under contract.
DOCS=(register_map.md spi_register_protocol.md)

# Skip cleanly when the hardware repository is not checked out next to this one, which is the
# normal case in CI and on a student's laptop.
if [[ -z "$CONTRACT_SRC" ]]
then
    echo "CONTRACT_SRC is not set; skipping the contract copy check."
    echo "Set it to the project/ directory of https://github.com/Yrgo-26/programmable-logic"
    echo "to check the copies against the originals."
    exit 0
fi

if [[ ! -d "$CONTRACT_SRC" ]]
then
    echo "error: contract originals not found at $CONTRACT_SRC." >&2
    exit 1
fi

if ! command -v python3 &> /dev/null
then
    echo "error: python3 not found; needed to compare the contract copies." >&2
    exit 1
fi

CONTRACT_SRC="$CONTRACT_SRC" CONTRACT_DST="$CONTRACT_DST" DOCS="${DOCS[*]}" python3 - <<'PY'
import os
import pathlib
import re
import sys

src = pathlib.Path(os.environ["CONTRACT_SRC"])
dst = pathlib.Path(os.environ["CONTRACT_DST"])
docs = os.environ["DOCS"].split()

# Links in the originals that point outside project/, into the hardware repository. The copies
# keep the link text but drop the target, since those files are not in this repository.
OUTWARD = (
    "../bridge/README.md",
    "../lectures/L18/README.md",
    "../lectures/L19/README.md",
    "./README.md",
)

# The copies carry a provenance note between the title and this separator.
SEPARATOR = "\n---\n\n"

drift = 0

for name in docs:
    original = src / name
    copy = dst / name

    if not original.is_file():
        print(f"error: {original} does not exist.", file=sys.stderr)
        drift += 1
        continue
    if not copy.is_file():
        print(f"error: {copy} does not exist.", file=sys.stderr)
        drift += 1
        continue

    def unlink(match):
        return match.group(1) if match.group(2) in OUTWARD else match.group(0)

    expected = re.sub(r"\[([^\]]*)\]\(([^)]*)\)", unlink, original.read_text())
    expected_body = expected.split("\n", 1)[1].lstrip("\n")

    text = copy.read_text()
    if SEPARATOR not in text:
        print(f"error: {copy} has no provenance note; cannot locate its body.", file=sys.stderr)
        drift += 1
        continue
    body = text.split(SEPARATOR, 1)[1]

    if body == expected_body:
        print(f"{name}: matches the original.")
    else:
        print(f"error: {copy} has drifted from {original}.", file=sys.stderr)
        print("       Update the copy from the original; never the other way round.",
              file=sys.stderr)
        drift += 1

if drift > 0:
    print(f"error: {drift} contract document(s) out of date.", file=sys.stderr)
    sys.exit(1)
PY
