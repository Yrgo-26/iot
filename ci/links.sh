#!/usr/bin/env bash
#
# Check that every relative link in the course material resolves to a file that exists.
#
# Links into a git submodule that is not checked out (a clone made without --recurse-submodules)
# cannot be resolved and are skipped, so the check needs nothing but this repository; once the
# submodule is checked out, as in CI, they are checked like any other. Every other relative link
# must resolve.
#
# Usage:
#   ci/links.sh
set -euo pipefail

# Root directory.
ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."

################################################################################
# Tell whether a path lies inside a git submodule that is not checked out.
# Globals:
#   None
# Arguments:
#   $1 - Path relative to the repository root.
# Returns:
#   0 if the path is inside a submodule whose working tree is absent, 1 otherwise.
################################################################################
in_absent_submodule() {
    local path="$1"
    local submodule

    # The submodule paths come from .gitmodules; a checked-out submodule has a .git file (or
    # directory) at its root, and one that is not checked out is an empty directory.
    while IFS= read -r submodule
    do
        if [[ "$path" == "$submodule"/* && ! -e "$submodule/.git" ]]
        then
            return 0
        fi
    done < <(git config --file .gitmodules --get-regexp '\.path$' 2>/dev/null | awk '{ print $2 }')
    return 1
}

################################################################################
# Report every relative markdown link whose target does not exist.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   One line per broken link on stdout.
# Returns:
#   0 if every link resolves, 1 otherwise.
################################################################################
check_links() {
    local broken=0
    local checked=0
    local unchecked=0
    local file dir target resolved

    # Prune the libs/ submodule: it carries its own CI and is not this repository's to check.
    while IFS= read -r -d '' file
    do
        dir="$(dirname "$file")"

        # Extract the target of every inline markdown link, i.e. the "..." in "[text](...)".
        while IFS= read -r target
        do
            # Skip external links and pure anchors; only relative paths are checkable here.
            case "$target" in
                http://*|https://*|mailto:*|\#*) continue ;;
            esac

            # Drop any "#anchor" suffix, leaving the path itself.
            target="${target%%#*}"
            [[ -z "$target" ]] && continue

            resolved="$dir/$target"
            if [[ -e "$resolved" ]]
            then
                (( ++checked ))
            elif in_absent_submodule "$(realpath -m --relative-to=. "$resolved")"
            then
                # Nothing to link to until the submodule is checked out; CI checks it out.
                (( ++unchecked ))
            else
                (( ++checked ))
                echo "error: $file: link target does not exist: $target" >&2
                (( ++broken ))
            fi
        done < <(grep -o '](\([^)]*\))' "$file" | sed 's/^](//; s/)$//')
    done < <(find . -path ./libs -prune -o -name "*.md" -print0)

    echo "Checked $checked relative link(s)."
    if (( unchecked > 0 ))
    then
        echo "Skipped $unchecked link(s) into submodules that are not checked out" \
             "(git submodule update --init checks them too)."
    fi
    if (( broken > 0 ))
    then
        echo "error: $broken broken link(s)." >&2
        return 1
    fi
    return 0
}

# Navigate to the root directory.
cd "$ROOT_DIR"

# Check the links.
check_links
