#!/usr/bin/env bats
# Tests for config/iterm2.zsh — shared iTerm2 utilities

setup() { load test_helper/setup; }

# ── _SHELLY_IT2API default ──

@test "SHELLY_IT2API: defaults to /Applications/iTerm.app/.../it2api" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        echo \"\$_SHELLY_IT2API\"
    "
    assert_success
    assert_output "/Applications/iTerm.app/Contents/Resources/it2api"
}

@test "SHELLY_IT2API: can be overridden before sourcing" {
    run zsh -c "
        SHELLY_IT2API='/custom/path/it2api'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        echo \"\$_SHELLY_IT2API\"
    "
    assert_success
    assert_output "/custom/path/it2api"
}

# ── _iterm2_ensure ──

@test "_iterm2_ensure: fails outside iTerm2" {
    run zsh -c "
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_ensure 'testcaller'
    "
    assert_failure
    assert_output --partial "non-iTerm mode"
    assert_output --partial "testcaller requires iTerm2"
}

@test "_iterm2_ensure: includes caller name in error" {
    run zsh -c "
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_ensure 'sysmon'
    "
    assert_failure
    assert_output --partial "sysmon requires iTerm2"
}

@test "_iterm2_ensure: default caller name is 'feature'" {
    run zsh -c "
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_ensure
    "
    assert_failure
    assert_output --partial "feature requires iTerm2"
}

@test "_iterm2_ensure: reports current terminal" {
    run zsh -c "
        TERM_PROGRAM='Apple_Terminal'
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_ensure 'test'
    "
    assert_failure
    assert_output --partial "Apple_Terminal"
}

# ── _iterm2_tab_exists ──

@test "_iterm2_tab_exists: fails when state file missing" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_tab_exists '/nonexistent/file'
    "
    assert_failure
}

@test "_iterm2_tab_exists: fails when state file empty" {
    local state_file="${TEST_TMPDIR}/empty.sid"
    touch "$state_file"
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_tab_exists '${state_file}'
    "
    assert_failure
}

# ── _iterm2_focus_tab ──

@test "_iterm2_focus_tab: fails when state file missing" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_focus_tab '/nonexistent/file'
    "
    assert_failure
}

# ── _iterm2_close_tab ──

@test "_iterm2_close_tab: no-op when state file missing" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_close_tab '/nonexistent/file' 'test'
    "
    assert_success
    assert_output --partial "No test tab tracked"
}

@test "_iterm2_close_tab: uses label in messages" {
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _iterm2_close_tab '/nonexistent/file' 'devterm split'
    "
    assert_success
    assert_output --partial "No devterm split tab tracked"
}

@test "_iterm2_close_tab: cleans up state file when session not in hierarchy" {
    local state_file="${TEST_TMPDIR}/test.sid"
    echo "fake-session-id" > "$state_file"
    run zsh -c "
        # Mock it2api to return empty hierarchy
        _SHELLY_IT2API() { echo ''; }
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        # Override _SHELLY_IT2API to a nonexistent command so show-hierarchy returns nothing
        _SHELLY_IT2API='/bin/true'
        _iterm2_close_tab '${state_file}' 'test'
    "
    assert_success
    assert_output --partial "test tab already closed"
    [ ! -f "$state_file" ]
}

@test "_iterm2_close_tab: restores dimming when dim_state_file has value 1" {
    local state_file="${TEST_TMPDIR}/test.sid"
    local dim_file="${TEST_TMPDIR}/test.dim"
    echo "fake-session-id" > "$state_file"
    echo "1" > "$dim_file"
    run zsh -c "
        # Mock defaults command
        defaults() { echo 'mock defaults called'; }
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _SHELLY_IT2API='/bin/true'
        _iterm2_close_tab '${state_file}' 'test' '${dim_file}'
    "
    assert_success
    [ ! -f "$dim_file" ]
}

@test "_iterm2_close_tab: skips dimming when no dim_state_file" {
    local state_file="${TEST_TMPDIR}/test.sid"
    echo "fake-session-id" > "$state_file"
    run zsh -c "
        source '${PROJECT_ROOT}/config/iterm2.zsh'
        _SHELLY_IT2API='/bin/true'
        _iterm2_close_tab '${state_file}' 'test'
    "
    assert_success
    assert_output --partial "test tab already closed"
}

# ── Hierarchy parsing (regex logic) ──

@test "hierarchy parsing: extracts window and tab IDs" {
    run zsh -c "
        hierarchy='Window id=w123 (main)
  Tab id=t456
    Session id=s789 (ssh)
  Tab id=t999
    Session id=s111 (bash)'
        local sid='s789' cur_win='' cur_tab='' win_id='' tab_id=''
        while IFS= read -r line; do
            if [[ \"\$line\" =~ 'Window id=([^ ]+)' ]]; then
                cur_win=\"\${match[1]}\"
            elif [[ \"\$line\" =~ 'Tab id=([^ ]+)' ]]; then
                cur_tab=\"\${match[1]}\"
            elif [[ \"\$line\" == *\"id=\$sid\"* ]]; then
                win_id=\"\$cur_win\"
                tab_id=\"\$cur_tab\"
                break
            fi
        done <<< \"\$hierarchy\"
        echo \"win=\$win_id tab=\$tab_id\"
    "
    assert_success
    assert_output "win=w123 tab=t456"
}

@test "hierarchy parsing: handles session in second tab" {
    run zsh -c "
        hierarchy='Window id=w1
  Tab id=t1
    Session id=s1
  Tab id=t2
    Session id=s2'
        local sid='s2' cur_win='' cur_tab='' win_id='' tab_id=''
        while IFS= read -r line; do
            if [[ \"\$line\" =~ 'Window id=([^ ]+)' ]]; then
                cur_win=\"\${match[1]}\"
            elif [[ \"\$line\" =~ 'Tab id=([^ ]+)' ]]; then
                cur_tab=\"\${match[1]}\"
            elif [[ \"\$line\" == *\"id=\$sid\"* ]]; then
                win_id=\"\$cur_win\"
                tab_id=\"\$cur_tab\"
                break
            fi
        done <<< \"\$hierarchy\"
        echo \"win=\$win_id tab=\$tab_id\"
    "
    assert_success
    assert_output "win=w1 tab=t2"
}
