#!/bin/bash
# ── Shelly Deploy ──
# Author: Shreyas Ugemuge
#
# Pushes current branch, tags the release, and creates a GitHub release.
#
# Usage:
#   ./deploy.sh              Auto-reads version from VERSION file
#   ./deploy.sh --dry-run    Show what would happen without doing it

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo "")"
TAG="v${VERSION}"
BRANCH="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)"
DRY_RUN=false

# ── Colors ──
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}→${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${CYAN}·${NC} $1"; }

# ── Parse args ──
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "Usage: ./deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would happen without doing it"
            echo "  --help, -h   Show this help message"
            exit 0
            ;;
    esac
done

# ── Preflight ──
echo ""
echo -e "${CYAN}── Deploy v${VERSION} ──${NC}"
echo ""

if [[ -z "$VERSION" ]]; then
    err "VERSION file is empty or missing"
    exit 1
fi

# Check for uncommitted changes
if ! git -C "$REPO_DIR" diff --quiet || ! git -C "$REPO_DIR" diff --cached --quiet; then
    err "Uncommitted changes — commit first before deploying"
    git -C "$REPO_DIR" status --short
    exit 1
fi

# Check for untracked files in config/
_untracked="$(git -C "$REPO_DIR" ls-files --others --exclude-standard)"
if [[ -n "$_untracked" ]]; then
    err "Untracked files found — commit or .gitignore them first:"
    echo "$_untracked" | sed 's/^/    /'
    exit 1
fi

# Check gh CLI
if ! command -v gh &>/dev/null; then
    warn "gh CLI not found — will push but skip GitHub release"
    warn "Install with: brew install gh (macOS) / apt install gh / dnf install gh"
    _has_gh=false
else
    _has_gh=true
fi

info "Version:  ${VERSION}"
info "Tag:      ${TAG}"
info "Branch:   ${BRANCH}"
echo ""

if $DRY_RUN; then
    echo -e "${CYAN}Dry run — no changes will be made${NC}"
    echo ""
    info "Would push ${BRANCH} to origin"
    if git -C "$REPO_DIR" tag -l "$TAG" | grep -q "$TAG"; then
        info "Tag ${TAG} already exists locally"
    else
        info "Would create tag ${TAG}"
    fi
    info "Would push tag ${TAG} to origin"
    if $_has_gh; then
        info "Would create GitHub release for ${TAG}"
    fi
    echo ""
    ok "Dry run complete"
    exit 0
fi

# ── Push branch ──
echo -e "${CYAN}Pushing ${BRANCH}…${NC}"
git -C "$REPO_DIR" push origin "$BRANCH"
ok "Pushed ${BRANCH}"

# ── Tag ──
if git -C "$REPO_DIR" tag -l "$TAG" | grep -q "$TAG"; then
    info "Tag ${TAG} already exists locally"
else
    git -C "$REPO_DIR" tag -a "$TAG" -m "${TAG}"
    ok "Created tag ${TAG}"
fi
git -C "$REPO_DIR" push origin "$TAG" 2>/dev/null || git -C "$REPO_DIR" push origin "$TAG" --force
ok "Pushed tag ${TAG}"

# ── GitHub Release ──
if $_has_gh; then
    # Extract release notes from CHANGELOG for this version
    _notes="$(awk "/^## \\[${VERSION}\\]/{found=1; next} /^## \\[/{if(found) exit} found{print}" "$REPO_DIR/CHANGELOG.md")"

    if [[ -z "$_notes" ]]; then
        warn "No changelog entry found for ${VERSION} — using --generate-notes"
        gh release create "$TAG" --title "${TAG}" --generate-notes --repo "$(git -C "$REPO_DIR" remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')"
    else
        gh release create "$TAG" --title "${TAG}" --notes "$_notes" --repo "$(git -C "$REPO_DIR" remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')"
    fi
    ok "GitHub release created for ${TAG}"
fi

echo ""
ok "Deploy complete! 🚀"
echo ""
