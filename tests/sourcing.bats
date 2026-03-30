#!/usr/bin/env bats
# Smoke tests: every config file sources without error

setup() { load test_helper/setup; }

@test "zsh -n: .zshrc passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/.zshrc"
    assert_success
}

@test "zsh -n: iterm2.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/iterm2.zsh"
    assert_success
}

@test "zsh -n: functions.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/functions.zsh"
    assert_success
}

@test "zsh -n: release.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/release.zsh"
    assert_success
}

@test "zsh -n: devterm.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/devterm.zsh"
    assert_success
}

@test "zsh -n: monitor.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/monitor.zsh"
    assert_success
}

@test "zsh -n: sysinfo.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/sysinfo.zsh"
    assert_success
}

@test "zsh -n: deps.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/deps.zsh"
    assert_success
}

@test "zsh -n: environment.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/environment.zsh"
    assert_success
}

@test "zsh -n: prompt.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/prompt.zsh"
    assert_success
}

@test "zsh -n: aliases.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/aliases.zsh"
    assert_success
}

@test "zsh -n: plugins.zsh passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/plugins.zsh"
    assert_success
}

@test "functions.zsh sources without error" {
    run_zsh_fn config/functions.zsh "true"
    assert_success
}

@test "release.zsh sources without error" {
    run_zsh_fn config/release.zsh "true"
    assert_success
}

@test "iterm2.zsh sources without error" {
    run_zsh_fn config/iterm2.zsh "true"
    assert_success
}

@test "devterm.zsh sources with iterm2.zsh without error" {
    run_zsh_multi "config/iterm2.zsh config/devterm.zsh" "true"
    assert_success
}

@test "monitor.zsh sources with iterm2.zsh without error" {
    run_zsh_multi "config/iterm2.zsh config/monitor.zsh" "true"
    assert_success
}

@test "all config files source in order without error" {
    run zsh -c "
        [[ \"\$OSTYPE\" == darwin* ]] && IS_MACOS=true || IS_MACOS=false
        [[ \"\$OSTYPE\" == linux*  ]] && IS_LINUX=true  || IS_LINUX=false
        for f in \
            '${PROJECT_ROOT}/config/environment.zsh' \
            '${PROJECT_ROOT}/config/prompt.zsh' \
            '${PROJECT_ROOT}/config/aliases.zsh' \
            '${PROJECT_ROOT}/config/iterm2.zsh' \
            '${PROJECT_ROOT}/config/functions.zsh' \
            '${PROJECT_ROOT}/config/release.zsh' \
            '${PROJECT_ROOT}/config/devterm.zsh' \
            '${PROJECT_ROOT}/config/plugins.zsh' \
            '${PROJECT_ROOT}/config/monitor.zsh'; do
            source \"\$f\"
        done
    "
    assert_success
}
