# ── Release & Versioning ──
# Author: Shreyas Ugemuge
#
# `shelly release <major|minor|patch>` — automated semver bump, changelog
# sectioning, commit, tag, and push. See CLAUDE.md for prerequisites.

function shelly() {
    case "$1" in
        release) shift; _shelly_release "$@" ;;
        version) cat "$(git rev-parse --show-toplevel 2>/dev/null)/VERSION" 2>/dev/null || echo "not in shelly repo" ;;
        help|*)
            echo "" >&2
            echo -e "  \033[1mshelly\033[0m — project management for shelly" >&2
            echo "" >&2
            echo "  shelly release <major|minor|patch>  Bump version, update changelog, commit, tag, push" >&2
            echo "  shelly version                      Show current version" >&2
            echo "  shelly help                         Show this help" >&2
            echo "" >&2
            ;;
    esac
}

function _shelly_release() {
    local bump_type="$1"
    local repo_root=""
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"

    if [[ -z "$repo_root" || ! -f "$repo_root/VERSION" ]]; then
        echo "shelly release: must be run from the shelly repo" >&2
        return 1
    fi

    if [[ "$bump_type" != "major" && "$bump_type" != "minor" && "$bump_type" != "patch" ]]; then
        echo "Usage: shelly release <major|minor|patch>" >&2
        return 1
    fi

    # Check for clean working tree
    if [[ -n "$(git -C "$repo_root" status --porcelain)" ]]; then
        echo -e "\033[0;31m✗\033[0m  Working tree is dirty — commit or stash changes first" >&2
        return 1
    fi

    # Read current version
    local current=""
    current="$(<"$repo_root/VERSION")"
    current="${current%%$'\n'}"

    # Parse semver
    local major="" minor="" patch=""
    major="${current%%.*}"
    local rest="${current#*.}"
    minor="${rest%%.*}"
    patch="${rest#*.}"

    # Bump
    case "$bump_type" in
        major) major=$(( major + 1 )); minor=0; patch=0 ;;
        minor) minor=$(( minor + 1 )); patch=0 ;;
        patch) patch=$(( patch + 1 )) ;;
    esac

    local new_version="$major.$minor.$patch"
    local today=""
    today="$(date +%Y-%m-%d)"

    # Check for unreleased changes in CHANGELOG
    local changelog="$repo_root/CHANGELOG.md"
    local unreleased_content=""
    unreleased_content="$(awk '/^## \[Unreleased\]/{found=1; next} /^## \[/{if(found) exit} found{print}' "$changelog")"

    if [[ -z "${unreleased_content//[$'\n\r\t ']/}" ]]; then
        echo -e "\033[0;33m⚠\033[0m  No changes under [Unreleased] in CHANGELOG.md" >&2
        echo "  Add changelog entries before releasing." >&2
        return 1
    fi

    # Derive repo URL from git remote (strip .git suffix, normalize SSH to HTTPS)
    local repo_url=""
    repo_url="$(git -C "$repo_root" remote get-url origin 2>/dev/null)"
    repo_url="${repo_url%.git}"
    repo_url="${repo_url/git@github.com:/https:\/\/github.com\/}"

    # Confirm
    echo "" >&2
    echo -e "  \033[1mshelly release\033[0m" >&2
    echo -e "  v$current → \033[0;32mv$new_version\033[0m ($today)" >&2
    echo "" >&2
    echo "  This will:" >&2
    echo "    1. Update VERSION to $new_version" >&2
    echo "    2. Move [Unreleased] → [$new_version] in CHANGELOG.md" >&2
    echo "    3. Commit: chore: release v$new_version" >&2
    echo "    4. Tag: v$new_version" >&2
    echo "    5. Push commit and tag to origin" >&2
    echo "" >&2

    local confirm=""
    read -r "confirm?  Proceed? (y/N): "
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted." >&2
        return 1
    fi

    echo "" >&2

    # 1. Update VERSION
    echo "$new_version" > "$repo_root/VERSION"
    echo -e "  \033[0;32m✓\033[0m VERSION → $new_version" >&2

    # 2. Update CHANGELOG.md — insert new version header below [Unreleased]
    awk -v ver="$new_version" -v date="$today" '
    /^## \[Unreleased\]/ {
        print
        print ""
        print "## [" ver "] - " date
        next
    }
    {print}
    ' "$changelog" > "$changelog.tmp" && mv "$changelog.tmp" "$changelog"

    # Update [Unreleased] compare link to point to new version tag
    sed -i '' "s|\[Unreleased\]:.*compare/v.*\.\.\.HEAD|[Unreleased]: $repo_url/compare/v${new_version}...HEAD|" "$changelog"

    # Add new version compare link after [Unreleased] link line
    local escaped_url="${repo_url//\//\\/}"
    sed -i '' "/^\[Unreleased\]:.*HEAD$/a\\
[$new_version]: $escaped_url/compare/v${current}...v${new_version}" "$changelog"

    echo -e "  \033[0;32m✓\033[0m CHANGELOG.md updated" >&2

    # 3. Commit
    git -C "$repo_root" add VERSION CHANGELOG.md
    git -C "$repo_root" commit -q -m "chore: release v$new_version"
    echo -e "  \033[0;32m✓\033[0m Committed: chore: release v$new_version" >&2

    # 4. Tag
    git -C "$repo_root" tag "v$new_version"
    echo -e "  \033[0;32m✓\033[0m Tagged: v$new_version" >&2

    # 5. Push
    git -C "$repo_root" push -q origin master 2>&1
    git -C "$repo_root" push -q origin "v$new_version" 2>&1
    echo -e "  \033[0;32m✓\033[0m Pushed to origin" >&2

    echo "" >&2
    echo -e "  \033[0;32m✓ v$new_version released\033[0m" >&2
    echo "" >&2
}
