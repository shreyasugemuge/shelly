#!/bin/bash
# ── Homebrew Integration Tests for Shelly ──
# Verifies bin/shelly works from git clone, through Homebrew symlink chains,
# and that install.sh respects SHELLY_ROOT.
#
# Run from repo root:  ./tests/test-homebrew.sh

set -euo pipefail

# ── Must run from repo root ──
if [[ ! -f "VERSION" ]]; then
    echo "Error: must be run from the shelly repo root" >&2
    exit 1
fi

REPO_ROOT="$(pwd)"
EXPECTED_VERSION="$(cat VERSION)"

# ── Temp dir cleanup ──
CLEANUP_DIRS=()
cleanup() {
    for dir in "${CLEANUP_DIRS[@]}"; do
        rm -rf "$dir"
    done
}
trap cleanup EXIT

# ── Test harness ──
pass=0
fail=0

test_case() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo -e "  \033[0;32m✓\033[0m $name"
        pass=$((pass + 1))
    else
        echo -e "  \033[0;31m✗\033[0m $name"
        fail=$((fail + 1))
    fi
}

# Helper: check that a command's stdout contains an expected string
output_contains() {
    local expected="$1"; shift
    "$@" 2>/dev/null | grep -qF "$expected"
}

# ── Build fake Homebrew directory structure ──
CELLAR_BASE="$(mktemp -d)"
CLEANUP_DIRS+=("$CELLAR_BASE")
FAKE_CELLAR="$CELLAR_BASE/Cellar/shelly/test"
mkdir -p "$FAKE_CELLAR/bin"
mkdir -p "$FAKE_CELLAR/share/shelly"

cp "$REPO_ROOT/bin/shelly" "$FAKE_CELLAR/bin/"
cp "$REPO_ROOT/.zshrc" "$FAKE_CELLAR/share/shelly/"
cp -r "$REPO_ROOT/config" "$FAKE_CELLAR/share/shelly/"
cp "$REPO_ROOT/install.sh" "$FAKE_CELLAR/share/shelly/"
cp "$REPO_ROOT/VERSION" "$FAKE_CELLAR/share/shelly/"
cp "$REPO_ROOT/CHANGELOG.md" "$FAKE_CELLAR/share/shelly/"
cp "$REPO_ROOT/README.md" "$FAKE_CELLAR/share/shelly/"
cp "$REPO_ROOT/LICENSE" "$FAKE_CELLAR/share/shelly/"

PREFIX_BASE="$(mktemp -d)"
CLEANUP_DIRS+=("$PREFIX_BASE")
FAKE_PREFIX="$PREFIX_BASE/homebrew"
mkdir -p "$FAKE_PREFIX/bin" "$FAKE_PREFIX/share"

ln -s "$FAKE_CELLAR/bin/shelly" "$FAKE_PREFIX/bin/shelly"
ln -s "$FAKE_CELLAR/share/shelly" "$FAKE_PREFIX/share/shelly"

# ═══════════════════════════════════════════════════════
echo ""
echo -e "\033[0;36m── bin/shelly from git clone (direct) ──\033[0m"
echo ""

test_case "version prints output" \
    "$REPO_ROOT/bin/shelly" version

test_case "help shows usage" \
    "$REPO_ROOT/bin/shelly" help

test_case "no args shows help" \
    "$REPO_ROOT/bin/shelly"

test_case "version output matches VERSION file" \
    output_contains "shelly v${EXPECTED_VERSION}" "$REPO_ROOT/bin/shelly" version

# ═══════════════════════════════════════════════════════
echo ""
echo -e "\033[0;36m── bin/shelly through symlink chain (Homebrew simulation) ──\033[0m"
echo ""

test_case "symlinked: version prints output" \
    "$FAKE_PREFIX/bin/shelly" version

test_case "symlinked: help shows usage" \
    "$FAKE_PREFIX/bin/shelly" help

test_case "symlinked: install --dry-run works (uses SHELLY_ROOT)" \
    "$FAKE_PREFIX/bin/shelly" install --dry-run

# ═══════════════════════════════════════════════════════
echo ""
echo -e "\033[0;36m── install.sh SHELLY_ROOT override ──\033[0m"
echo ""

test_case "install.sh with SHELLY_ROOT override --dry-run" \
    env SHELLY_ROOT="$FAKE_CELLAR/share/shelly" bash "$REPO_ROOT/install.sh" --dry-run

test_case "install.sh without SHELLY_ROOT --dry-run (backward compat)" \
    bash "$REPO_ROOT/install.sh" --dry-run

test_case "install.sh --version works" \
    bash "$REPO_ROOT/install.sh" --version

test_case "install.sh --help works" \
    bash "$REPO_ROOT/install.sh" --help

# ═══════════════════════════════════════════════════════
echo ""
echo -e "\033[0;36m── Shellcheck ──\033[0m"
echo ""

if command -v shellcheck &>/dev/null; then
    test_case "shellcheck bin/shelly" \
        shellcheck "$REPO_ROOT/bin/shelly"

    test_case "shellcheck install.sh" \
        shellcheck "$REPO_ROOT/install.sh"
else
    echo -e "  \033[1;33m⚠\033[0m shellcheck not found — skipping lint tests"
fi

# ═══════════════════════════════════════════════════════
echo ""
echo "─────────────────────────────────"
echo -e "  \033[0;32m$pass passed\033[0m, \033[0;31m$fail failed\033[0m"
echo "─────────────────────────────────"
echo ""

if (( fail > 0 )); then
    exit 1
fi
