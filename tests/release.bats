#!/usr/bin/env bats
# Tests for config/release.zsh — shelly CLI and release logic

setup() { load test_helper/setup; }

# ── shelly dispatcher ──

@test "shelly help: outputs help text" {
    run_zsh_fn config/release.zsh "shelly help"
    assert_success
    assert_output --partial "shelly release"
    assert_output --partial "shelly version"
}

@test "shelly: no args outputs help" {
    run_zsh_fn config/release.zsh "shelly"
    assert_success
    assert_output --partial "shelly release"
}

@test "shelly version: outside repo prints error" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        export HOME='${TEST_TMPDIR}'
        cd '${TEST_TMPDIR}'
        source '${PROJECT_ROOT}/config/release.zsh'
        shelly version
    "
    assert_output --partial "not in shelly repo"
}

@test "shelly version: in repo prints version" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        cd '${PROJECT_ROOT}'
        source '${PROJECT_ROOT}/config/release.zsh'
        shelly version
    "
    assert_success
    # Should match semver pattern
    assert_output --regexp '^[0-9]+\.[0-9]+\.[0-9]+$'
}

# ── _shelly_release validation ──

@test "release: rejects invalid bump type" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        cd '${PROJECT_ROOT}'
        source '${PROJECT_ROOT}/config/release.zsh'
        _shelly_release foo
    "
    assert_failure
    assert_output --partial "Usage: shelly release"
}

@test "release: rejects empty bump type" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        cd '${PROJECT_ROOT}'
        source '${PROJECT_ROOT}/config/release.zsh'
        _shelly_release ''
    "
    assert_failure
    assert_output --partial "Usage: shelly release"
}

@test "release: fails outside git repo" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        cd '${TEST_TMPDIR}'
        source '${PROJECT_ROOT}/config/release.zsh'
        _shelly_release patch
    "
    assert_failure
    assert_output --partial "must be run from the shelly repo"
}

# ── Semver parsing (tested via zsh directly) ──

@test "semver: parses 1.2.3 correctly" {
    run zsh -c "
        current='1.2.3'
        major=\"\${current%%.*}\"
        rest=\"\${current#*.}\"
        minor=\"\${rest%%.*}\"
        patch=\"\${rest#*.}\"
        echo \"\$major \$minor \$patch\"
    "
    assert_success
    assert_output "1 2 3"
}

@test "semver: parses 0.0.1 correctly" {
    run zsh -c "
        current='0.0.1'
        major=\"\${current%%.*}\"
        rest=\"\${current#*.}\"
        minor=\"\${rest%%.*}\"
        patch=\"\${rest#*.}\"
        echo \"\$major \$minor \$patch\"
    "
    assert_success
    assert_output "0 0 1"
}

@test "semver: parses 10.20.30 correctly" {
    run zsh -c "
        current='10.20.30'
        major=\"\${current%%.*}\"
        rest=\"\${current#*.}\"
        minor=\"\${rest%%.*}\"
        patch=\"\${rest#*.}\"
        echo \"\$major \$minor \$patch\"
    "
    assert_success
    assert_output "10 20 30"
}

@test "semver bump: patch 1.2.3 -> 1.2.4" {
    run zsh -c "
        current='1.2.3'
        major=\"\${current%%.*}\"; rest=\"\${current#*.}\"; minor=\"\${rest%%.*}\"; patch=\"\${rest#*.}\"
        patch=\$(( patch + 1 ))
        echo \"\$major.\$minor.\$patch\"
    "
    assert_success
    assert_output "1.2.4"
}

@test "semver bump: minor 1.2.3 -> 1.3.0" {
    run zsh -c "
        current='1.2.3'
        major=\"\${current%%.*}\"; rest=\"\${current#*.}\"; minor=\"\${rest%%.*}\"; patch=\"\${rest#*.}\"
        minor=\$(( minor + 1 )); patch=0
        echo \"\$major.\$minor.\$patch\"
    "
    assert_success
    assert_output "1.3.0"
}

@test "semver bump: major 1.2.3 -> 2.0.0" {
    run zsh -c "
        current='1.2.3'
        major=\"\${current%%.*}\"; rest=\"\${current#*.}\"; minor=\"\${rest%%.*}\"; patch=\"\${rest#*.}\"
        major=\$(( major + 1 )); minor=0; patch=0
        echo \"\$major.\$minor.\$patch\"
    "
    assert_success
    assert_output "2.0.0"
}

@test "semver bump: patch from 0.0.0 -> 0.0.1" {
    run zsh -c "
        current='0.0.0'
        major=\"\${current%%.*}\"; rest=\"\${current#*.}\"; minor=\"\${rest%%.*}\"; patch=\"\${rest#*.}\"
        patch=\$(( patch + 1 ))
        echo \"\$major.\$minor.\$patch\"
    "
    assert_success
    assert_output "0.0.1"
}

# ── Release in a mock repo ──

@test "release: detects dirty working tree" {
    # Set up a minimal git repo with VERSION and CHANGELOG
    local repo="${TEST_TMPDIR}/mock-repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    echo "1.0.0" > "$repo/VERSION"
    cat > "$repo/CHANGELOG.md" << 'EOF'
# Changelog
## [Unreleased]
### Added
- something
EOF
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "init"
    # Dirty the tree
    echo "dirty" > "$repo/dirty.txt"

    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        cd '$repo'
        source '${PROJECT_ROOT}/config/release.zsh'
        _shelly_release patch
    "
    assert_failure
    assert_output --partial "dirty"
}

@test "release: detects empty unreleased section" {
    local repo="${TEST_TMPDIR}/mock-repo2"
    mkdir -p "$repo"
    git -C "$repo" init -q
    echo "1.0.0" > "$repo/VERSION"
    cat > "$repo/CHANGELOG.md" << 'EOF'
# Changelog
## [Unreleased]

## [1.0.0] - 2026-01-01
EOF
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "init"

    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        cd '$repo'
        source '${PROJECT_ROOT}/config/release.zsh'
        _shelly_release patch
    "
    assert_failure
    assert_output --partial "No changes under"
}
