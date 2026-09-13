#!/usr/bin/env bash
#
# Build every code example in the repository that ships a Makefile, and run its tests if it
# defines a 'test' target.
#
# Directories under an 'appendix/' path are skipped: those are the exercise skeletons handed out
# with the lecture notes, and they are deliberately incomplete - the exercise is to complete them.
# Building them would fail by design. Everything else (lecture notes, test suites) is complete and
# must build.
#
# The lecture demo directories are the ones live-coded during a lecture and handed out
# afterwards; a directory that is not present yet is simply not found, so the build stays green
# throughout the course rather than failing until every lecture has happened.
#
# Usage:
#   ci/build.sh
set -euo pipefail

# Root directory.
ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."

# Directories searched for code examples.
SEARCH_DIRS=(lectures exam lab)

# Navigate to the root directory.
cd "$ROOT_DIR"

# Build every example that has a Makefile, in a stable order.
found=0
for dir in "${SEARCH_DIRS[@]}"
do
    [[ -d "$dir" ]] || continue

    while IFS= read -r -d '' makefile
    do
        # Skip the exercise skeletons; see the note at the top of this file.
        if [[ "$makefile" == *"/appendix/"* ]]
        then
            continue
        fi

        found=1
        example_dir="$(dirname "$makefile")"
        echo "Building $example_dir"
        make -C "$example_dir" build

        # Detect a 'test' target by reading the Makefile rather than probing with 'make -n test'.
        # Make runs recipe lines containing $(MAKE) even under -n, so a probe would recurse into
        # libs/test and fail whenever the submodule is not checked out.
        if grep -qE '^test:' "$makefile"
        then
            echo "Testing $example_dir"
            make -C "$example_dir" test
        fi
    done < <(find "$dir" -iname Makefile -print0 | sort -z)
done

# Make a vacuous build explicit, so an empty result reads as "no code examples in this tree"
# rather than silently masking a mis-scoped search.
if (( found == 0 ))
then
    echo "No Makefiles found under ${SEARCH_DIRS[*]}; nothing to build."
fi
