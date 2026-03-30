#!/usr/bin/env bats
# Tests for config/plugins.zsh — plugin loading
#
# Note: plugins.zsh unfunctions _find_plugin after sourcing.
# We test the logic by defining it inline.

setup() { load test_helper/setup; }

@test "plugins.zsh: passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/plugins.zsh"
    assert_success
}

@test "plugins.zsh: sources without error" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        _SHELLY_BREW_PREFIX=''
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/plugins.zsh'
        true
    "
    assert_success
}

@test "_find_plugin logic: returns failure for nonexistent plugin" {
    run zsh -c "
        _plugin_dirs=(/nonexistent/path)
        _find_plugin() {
            local plugin=\"\$1\"
            for _dir in \"\${_plugin_dirs[@]}\"; do
                [[ -f \"\$_dir/\$plugin/\$plugin.zsh\" ]] && { echo \"\$_dir/\$plugin/\$plugin.zsh\"; return 0; }
            done
            return 1
        }
        _find_plugin nonexistent-xyz
    "
    assert_failure
}

@test "_find_plugin logic: finds plugin in search path" {
    # Create a fake plugin
    mkdir -p "${TEST_TMPDIR}/share/myplugin"
    echo "# fake plugin" > "${TEST_TMPDIR}/share/myplugin/myplugin.zsh"
    run zsh -c "
        _plugin_dirs=('${TEST_TMPDIR}/share')
        _find_plugin() {
            local plugin=\"\$1\"
            for _dir in \"\${_plugin_dirs[@]}\"; do
                [[ -f \"\$_dir/\$plugin/\$plugin.zsh\" ]] && { echo \"\$_dir/\$plugin/\$plugin.zsh\"; return 0; }
            done
            return 1
        }
        _find_plugin myplugin
    "
    assert_success
    assert_output "${TEST_TMPDIR}/share/myplugin/myplugin.zsh"
}

@test "plugins: iTerm2 integration skipped outside iTerm" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        _SHELLY_BREW_PREFIX=''
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/plugins.zsh'
        echo 'sourced ok'
    "
    assert_success
    assert_output "sourced ok"
}

@test "plugins: autosuggestions config vars set when plugin available" {
    # Only run if autosuggestions is installed
    local brew_prefix
    brew_prefix="$(brew --prefix 2>/dev/null)" || true
    if [[ ! -f "${brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        skip "zsh-autosuggestions not installed via brew"
    fi

    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        _SHELLY_BREW_PREFIX='${brew_prefix}'
        TERM_PROGRAM=xterm
        source '${PROJECT_ROOT}/config/plugins.zsh'
        echo \"\$ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE\"
    "
    assert_success
    assert_output "20"
}
