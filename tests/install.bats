#!/usr/bin/env bats
# Tests for install.sh — installation script

setup() { load test_helper/setup; }

@test "install.sh: passes syntax check" {
    run bash -n "${PROJECT_ROOT}/install.sh"
    assert_success
}

@test "install.sh --help: shows usage" {
    run bash "${PROJECT_ROOT}/install.sh" --help
    assert_success
    assert_output --partial "Usage"
    assert_output --partial "install"
}

@test "install.sh --dry-run: shows what would be done without changes" {
    run bash "${PROJECT_ROOT}/install.sh" --dry-run
    assert_success
    assert_output --partial "Dry run"
}

@test "install.sh: VERSION file exists" {
    [ -f "${PROJECT_ROOT}/VERSION" ]
}

@test "install.sh: VERSION matches semver format" {
    run cat "${PROJECT_ROOT}/VERSION"
    assert_success
    assert_output --regexp '^[0-9]+\.[0-9]+\.[0-9]+$'
}
