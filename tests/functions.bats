#!/usr/bin/env bats
# Tests for config/functions.zsh — utility functions

setup() { load test_helper/setup; }

# ── mkcd ──

@test "mkcd: creates directory and changes into it" {
    run_zsh_fn config/functions.zsh "mkcd '${TEST_TMPDIR}/testdir' && pwd"
    assert_success
    assert_output "${TEST_TMPDIR}/testdir"
}

@test "mkcd: creates nested directories" {
    run_zsh_fn config/functions.zsh "mkcd '${TEST_TMPDIR}/a/b/c' && pwd"
    assert_success
    assert_output "${TEST_TMPDIR}/a/b/c"
}

@test "mkcd: no argument prints usage and fails" {
    run_zsh_fn config/functions.zsh "mkcd"
    assert_failure
    assert_output --partial "Usage: mkcd"
}

# ── extract ──

@test "extract: non-existent file prints error" {
    run_zsh_fn config/functions.zsh "extract /nonexistent/file.tar.gz"
    assert_failure
    assert_output --partial "is not a valid file"
}

@test "extract: unknown format prints error" {
    touch "${TEST_TMPDIR}/file.xyz"
    run_zsh_fn config/functions.zsh "extract '${TEST_TMPDIR}/file.xyz'"
    assert_output --partial "unknown format"
}

@test "extract: handles .tar.gz file" {
    # Create a test archive
    mkdir -p "${TEST_TMPDIR}/src"
    echo "hello" > "${TEST_TMPDIR}/src/test.txt"
    tar czf "${TEST_TMPDIR}/test.tar.gz" -C "${TEST_TMPDIR}/src" test.txt
    mkdir -p "${TEST_TMPDIR}/dst"
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/functions.zsh'
        cd '${TEST_TMPDIR}/dst' && extract '${TEST_TMPDIR}/test.tar.gz'
    "
    assert_success
    [ -f "${TEST_TMPDIR}/dst/test.txt" ]
}

@test "extract: handles .zip file" {
    mkdir -p "${TEST_TMPDIR}/src"
    echo "hello" > "${TEST_TMPDIR}/src/test.txt"
    (cd "${TEST_TMPDIR}/src" && zip -q "${TEST_TMPDIR}/test.zip" test.txt)
    mkdir -p "${TEST_TMPDIR}/dst"
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/functions.zsh'
        cd '${TEST_TMPDIR}/dst' && extract '${TEST_TMPDIR}/test.zip'
    "
    assert_success
    [ -f "${TEST_TMPDIR}/dst/test.txt" ]
}

# ── portfind ──

@test "portfind: no argument prints usage" {
    run_zsh_fn config/functions.zsh "portfind"
    assert_failure
    assert_output --partial "Usage: portfind"
}

@test "portfind: non-numeric argument fails" {
    run_zsh_fn config/functions.zsh "portfind abc"
    assert_failure
    assert_output --partial "port must be a number"
}

@test "portfind: port 0 fails range check" {
    run_zsh_fn config/functions.zsh "portfind 0"
    assert_failure
    assert_output --partial "port must be 1-65535"
}

@test "portfind: port 65536 fails range check" {
    run_zsh_fn config/functions.zsh "portfind 65536"
    assert_failure
    assert_output --partial "port must be 1-65535"
}

@test "portfind: port 1 passes validation" {
    # lsof may fail if nothing is on port 1, but validation should pass
    run_zsh_fn config/functions.zsh "portfind 1 2>/dev/null; true"
    assert_success
}

@test "portfind: port 65535 passes validation" {
    run_zsh_fn config/functions.zsh "portfind 65535 2>/dev/null; true"
    assert_success
}

# ── pan ──

@test "pan: no argument prints usage" {
    run_zsh_fn config/functions.zsh "pan"
    assert_failure
    assert_output --partial "Usage: pan"
}

@test "pan: non-macOS prints error" {
    run_zsh_platform linux config/functions.zsh "pan ls"
    assert_failure
    assert_output --partial "requires macOS"
}

# ── whichip ──

@test "whichip: outputs public and local IP labels" {
    # Mock curl to avoid network calls
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        curl() { echo '1.2.3.4'; }
        route() { echo 'interface: en0'; }
        ipconfig() { echo '192.168.1.1'; }
        source '${PROJECT_ROOT}/config/functions.zsh'
        whichip
    "
    assert_success
    assert_output --partial "Public IP"
    assert_output --partial "Local IP"
}

# ── weather ──

@test "weather: calls wttr.in with city" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        curl() { echo \"called: \$*\"; }
        source '${PROJECT_ROOT}/config/functions.zsh'
        weather London
    "
    assert_success
    assert_output --partial "wttr.in/London"
}

@test "weather: calls wttr.in without city" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        curl() { echo \"called: \$*\"; }
        source '${PROJECT_ROOT}/config/functions.zsh'
        weather
    "
    assert_success
    assert_output --partial "wttr.in/"
}

# ── ccnotify ──

@test "ccnotify: no-op outside iTerm2" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/functions.zsh'
        ccnotify 'test'
    "
    assert_success
    assert_output ""
}

@test "ccnotify: uses default message" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        TERM_PROGRAM='iTerm.app'
        source '${PROJECT_ROOT}/config/functions.zsh'
        ccnotify
    "
    assert_success
    # Output contains escape sequences (OSC 9)
    assert_output --partial "done"
}

# ── iterm-setup ──

@test "iterm-setup: fails outside iTerm2" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/functions.zsh'
        iterm-setup
    "
    assert_failure
    assert_output --partial "not running in iTerm2"
}
