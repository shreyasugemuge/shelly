#!/usr/bin/env bash
# Common test setup for all bats test files
#
# Usage: add to the top of each .bats file:
#   setup() { load test_helper/setup; }

# Load bats libraries
load "${BATS_TEST_DIRNAME}/.bats/bats-support/load"
load "${BATS_TEST_DIRNAME}/.bats/bats-assert/load"

# Project root (one level up from tests/)
export PROJECT_ROOT="${BATS_TEST_DIRNAME}/.."

# Temp directory for test artifacts (cleaned up automatically by bats)
export TEST_TMPDIR="${BATS_TEST_TMPDIR}"

# ── Helper: Run a zsh function in an isolated environment ──
# Sets up minimal environment (IS_MACOS, IS_LINUX, etc.) then sources
# the given config file and runs the command.
#
# Usage: run_zsh_fn <config_file> <command> [args...]
# Example: run_zsh_fn config/functions.zsh portfind 80
run_zsh_fn() {
    local config_file="$1"
    shift
    local cmd="$*"
    run zsh -c "
        # Minimal environment matching .zshrc
        [[ \"\$OSTYPE\" == darwin* ]] && IS_MACOS=true || IS_MACOS=false
        [[ \"\$OSTYPE\" == linux*  ]] && IS_LINUX=true  || IS_LINUX=false
        export HOME=\"${TEST_TMPDIR}\"
        mkdir -p \"\${HOME}/.cache/zsh\" \"\${HOME}/.config/zsh\" \"\${HOME}/.config/btop\"
        source \"${PROJECT_ROOT}/${config_file}\"
        ${cmd}
    "
}

# ── Helper: Run zsh with multiple config files sourced ──
# Usage: run_zsh_multi "config/iterm2.zsh config/devterm.zsh" "some_function arg"
run_zsh_multi() {
    local config_files="$1"
    shift
    local cmd="$*"
    local sources=""
    for f in $config_files; do
        sources+="source \"${PROJECT_ROOT}/${f}\"; "
    done
    run zsh -c "
        [[ \"\$OSTYPE\" == darwin* ]] && IS_MACOS=true || IS_MACOS=false
        [[ \"\$OSTYPE\" == linux*  ]] && IS_LINUX=true  || IS_LINUX=false
        export HOME=\"${TEST_TMPDIR}\"
        mkdir -p \"\${HOME}/.cache/zsh\" \"\${HOME}/.config/zsh\"
        ${sources}
        ${cmd}
    "
}

# ── Helper: Run zsh with forced platform ──
# Usage: run_zsh_platform macos config/functions.zsh "pan"
run_zsh_platform() {
    local platform="$1"
    local config_file="$2"
    shift 2
    local cmd="$*"
    local is_macos="false" is_linux="false"
    case "$platform" in
        macos) is_macos="true" ;;
        linux) is_linux="true" ;;
    esac
    run zsh -c "
        IS_MACOS=${is_macos}
        IS_LINUX=${is_linux}
        export HOME=\"${TEST_TMPDIR}\"
        mkdir -p \"\${HOME}/.cache/zsh\" \"\${HOME}/.config/zsh\"
        source \"${PROJECT_ROOT}/${config_file}\"
        ${cmd}
    "
}
