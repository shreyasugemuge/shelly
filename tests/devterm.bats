#!/usr/bin/env bats
# Tests for config/devterm.zsh — dev workspace

setup() { load test_helper/setup; }

# ── Configurable defaults ──

@test "SHELLY_DEVTERM_RATIO: defaults to 0.8" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        echo \"\$SHELLY_DEVTERM_RATIO\"
    "
    assert_success
    assert_output "0.8"
}

@test "SHELLY_DEVTERM_RATIO: can be overridden" {
    run zsh -c "
        SHELLY_DEVTERM_RATIO=0.7
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        echo \"\$SHELLY_DEVTERM_RATIO\"
    "
    assert_success
    assert_output "0.7"
}

@test "SHELLY_CODE_DIRS: defaults to expected list" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        echo \"\${SHELLY_CODE_DIRS[*]}\"
    "
    assert_success
    assert_output --partial "code"
    assert_output --partial "projects"
    assert_output --partial "dev"
}

@test "SHELLY_CODE_DIRS: can be overridden" {
    run zsh -c "
        SHELLY_CODE_DIRS=(mycode myprojects)
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        echo \"\${SHELLY_CODE_DIRS[*]}\"
    "
    assert_success
    assert_output "mycode myprojects"
}

# ── _dev_state_file ──

@test "_dev_state_file: returns correct path" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_state_file
    "
    assert_success
    assert_output --partial "zsh/devterm.session_id"
}

@test "_dev_state_file: respects XDG_CACHE_HOME" {
    run zsh -c "
        export XDG_CACHE_HOME='/tmp/custom-cache'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_state_file
    "
    assert_success
    assert_output "/tmp/custom-cache/zsh/devterm.session_id"
}

# ── _dev_split_state_file ──

@test "_dev_split_state_file: returns correct path" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_state_file
    "
    assert_success
    assert_output --partial "zsh/devterm-split.session_id"
}

# ── _dev_split_grid ──

@test "grid: 1 pane -> 1" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_grid 1
    "
    assert_success
    assert_output "1"
}

@test "grid: 2 panes -> 2" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_grid 2
    "
    assert_success
    assert_output "2"
}

@test "grid: 3 panes -> 3" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_grid 3
    "
    assert_success
    assert_output "3"
}

@test "grid: 4 panes -> 2 2 (2x2)" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_grid 4
    "
    assert_success
    assert_output "2 2"
}

@test "grid: 5 panes -> 2 2 1" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_grid 5
    "
    assert_success
    assert_output "2 2 1"
}

@test "grid: 6 panes -> 3 3" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_grid 6
    "
    assert_success
    assert_output "3 3"
}

@test "grid: 7 panes -> 3 3 1" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_grid 7
    "
    assert_success
    assert_output "3 3 1"
}

@test "grid: 8 panes -> 4 4" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_grid 8
    "
    assert_success
    assert_output "4 4"
}

# ── _dev_ensure_iterm2 ──

@test "_dev_ensure_iterm2: delegates to _iterm2_ensure with devterm label" {
    run zsh -c "
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_ensure_iterm2
    "
    assert_failure
    assert_output --partial "devterm requires iTerm2"
}

# ── _dev_tab_exists / _dev_focus_tab / _dev_close_tab (wrappers) ──

@test "_dev_tab_exists: fails when no state file" {
    run zsh -c "
        export HOME='${TEST_TMPDIR}'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_tab_exists
    "
    assert_failure
}

@test "_dev_close_tab: no-op when no state file" {
    run zsh -c "
        export HOME='${TEST_TMPDIR}'
        mkdir -p '${TEST_TMPDIR}/.cache/zsh'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_close_tab
    "
    assert_success
    assert_output --partial "devterm tab"
}

@test "_dev_split_close_tab: no-op when no state file" {
    run zsh -c "
        export HOME='${TEST_TMPDIR}'
        mkdir -p '${TEST_TMPDIR}/.cache/zsh'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_split_close_tab
    "
    assert_success
    assert_output --partial "devterm split tab"
}

# ── devterm help ──

@test "devterm help: shows all subcommands" {
    run zsh -c "
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        devterm help
    "
    assert_success
    assert_output --partial "devterm"
    assert_output --partial "kill"
    assert_output --partial "status"
    assert_output --partial "config"
    assert_output --partial "split mode"
}

@test "devterm -s help: shows split mode help" {
    run zsh -c "
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        devterm -s help
    "
    assert_success
    assert_output --partial "split mode"
    assert_output --partial "Grid layouts"
}

# ── _dev_persist_dir / _dev_unpersist_dir ──

@test "_dev_persist_dir: saves to .zshrc.local" {
    run zsh -c "
        export HOME='${TEST_TMPDIR}'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_persist_dir '/custom/code'
    "
    assert_success
    run grep 'DEVTMUX_DIR' "${TEST_TMPDIR}/.zshrc.local"
    assert_success
    assert_output --partial "/custom/code"
}

@test "_dev_persist_dir: updates existing entry" {
    echo 'export DEVTMUX_DIR="/old/path"' > "${TEST_TMPDIR}/.zshrc.local"
    run zsh -c "
        export HOME='${TEST_TMPDIR}'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_persist_dir '/new/path'
    "
    assert_success
    run grep 'DEVTMUX_DIR' "${TEST_TMPDIR}/.zshrc.local"
    assert_output --partial "/new/path"
    # Should not have duplicate entries
    run grep -c 'DEVTMUX_DIR' "${TEST_TMPDIR}/.zshrc.local"
    assert_output "1"
}

@test "_dev_unpersist_dir: removes from .zshrc.local" {
    echo 'export DEVTMUX_DIR="/some/path"' > "${TEST_TMPDIR}/.zshrc.local"
    run zsh -c "
        export HOME='${TEST_TMPDIR}'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_unpersist_dir
    "
    assert_success
    run grep 'DEVTMUX_DIR' "${TEST_TMPDIR}/.zshrc.local"
    assert_failure
}

# ── _dev_get_code_dir ──

@test "_dev_get_code_dir: uses DEVTMUX_DIR if set" {
    mkdir -p "${TEST_TMPDIR}/mycode"
    run zsh -c "
        export DEVTMUX_DIR='${TEST_TMPDIR}/mycode'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_get_code_dir
    "
    assert_success
    assert_output "${TEST_TMPDIR}/mycode"
}

@test "_dev_get_code_dir: falls back to ~/code if it exists" {
    mkdir -p "${TEST_TMPDIR}/code"
    run zsh -c "
        export HOME='${TEST_TMPDIR}'
        unset DEVTMUX_DIR
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/devterm.zsh'
        _dev_get_code_dir
    "
    assert_success
    assert_output "${TEST_TMPDIR}/code"
}
