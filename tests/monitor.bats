#!/usr/bin/env bats
# Tests for config/monitor.zsh — sysmon

setup() { load test_helper/setup; }

# ── State file paths ──

@test "_sysmon_state_file: returns correct path" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_state_file
    "
    assert_success
    assert_output --partial "zsh/sysmon.session_id"
}

@test "_sysmon_old_state_file: returns correct path" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_old_state_file
    "
    assert_success
    assert_output --partial "zsh/sysmon-old.session_id"
}

# ── _sysmon_write_btop_conf ──

@test "_sysmon_write_btop_conf: creates config file" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        export HOME='${TEST_TMPDIR}'
        export XDG_CONFIG_HOME='${TEST_TMPDIR}/.config'
        mkdir -p '${TEST_TMPDIR}/.config'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_write_btop_conf
        cat '${TEST_TMPDIR}/.config/btop/btop.conf'
    "
    assert_success
    assert_output --partial 'shown_boxes = "cpu mem net"'
    assert_output --partial 'graph_symbol = "braille"'
    assert_output --partial 'update_ms = 1000'
    assert_output --partial 'show_battery = True'
}

@test "_sysmon_write_btop_conf: overwrites existing config" {
    mkdir -p "${TEST_TMPDIR}/.config/btop"
    echo "old config" > "${TEST_TMPDIR}/.config/btop/btop.conf"
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        export HOME='${TEST_TMPDIR}'
        export XDG_CONFIG_HOME='${TEST_TMPDIR}/.config'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_write_btop_conf
        cat '${TEST_TMPDIR}/.config/btop/btop.conf'
    "
    assert_success
    refute_output --partial "old config"
    assert_output --partial 'shown_boxes = "cpu mem net"'
}

# ── _sysmon_ensure_iterm2 ──

@test "_sysmon_ensure_iterm2: delegates to _iterm2_ensure with sysmon label" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_ensure_iterm2
    "
    assert_failure
    assert_output --partial "sysmon requires iTerm2"
}

# ── _sysmon_tab_exists / _sysmon_close_tab (wrappers) ──

@test "_sysmon_tab_exists: fails when no state file" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        export HOME='${TEST_TMPDIR}'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_tab_exists
    "
    assert_failure
}

@test "_sysmon_close_tab: no-op when no state file" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        export HOME='${TEST_TMPDIR}'
        mkdir -p '${TEST_TMPDIR}/.cache/zsh'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_close_tab
    "
    assert_success
    assert_output --partial "sysmon tab"
}

@test "_sysmon_old_close_tab: no-op when no state file" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        export HOME='${TEST_TMPDIR}'
        mkdir -p '${TEST_TMPDIR}/.cache/zsh'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_old_close_tab
    "
    assert_success
    assert_output --partial "No sysmon-old tab tracked"
}

# ── _sysmon_pkg_install ──

@test "_sysmon_pkg_install: uses brew when available" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        # Mock brew to echo its args
        brew() { echo \"brew \$*\"; }
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_pkg_install testpkg
    "
    assert_success
    assert_output "brew install testpkg"
}

# ── sysmon help ──

@test "sysmon help: shows all subcommands" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        sysmon help
    "
    assert_success
    assert_output --partial "sysmon"
    assert_output --partial "kill"
    assert_output --partial "status"
    assert_output --partial "btop"
    assert_output --partial "mactop"
}

# ── _sysmon_has_gpu ──

@test "_sysmon_has_gpu: uses system_profiler on macOS" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        system_profiler() { echo 'Chip: Apple M4 Max'; }
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_has_gpu
    "
    assert_success
}

@test "_sysmon_has_gpu: uses lspci on Linux" {
    run zsh -c "
        IS_MACOS=false; IS_LINUX=true
        lspci() { echo '0000:00:02.0 VGA compatible controller: Intel'; }
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_has_gpu
    "
    assert_success
}

@test "_sysmon_has_gpu: fails when no GPU" {
    run zsh -c "
        IS_MACOS=false; IS_LINUX=true
        lspci() { echo '0000:00:01.0 Audio device: Intel'; }
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_has_gpu
    "
    assert_failure
}

# ── _sysmon_has_nvidia ──

@test "_sysmon_has_nvidia: detects nvidia-smi" {
    run zsh -c "
        IS_MACOS=false; IS_LINUX=true
        nvidia-smi() { return 0; }
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        source '${PROJECT_ROOT}/config/monitor.zsh'
        _sysmon_has_nvidia
    "
    assert_success
}
