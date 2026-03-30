#!/usr/bin/env bats
# Tests for config/environment.zsh — exports, options, NVM

setup() { load test_helper/setup; }

@test "environment.zsh: sources without error" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/environment.zsh'
        true
    "
    assert_success
}

@test "EDITOR is set" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/environment.zsh'
        echo \"\$EDITOR\"
    "
    assert_success
    assert_output "emacs"
}

@test "LANG is set to UTF-8" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/environment.zsh'
        echo \"\$LANG\"
    "
    assert_success
    assert_output "en_US.UTF-8"
}

@test "NVM lazy-load stubs are created when NVM exists" {
    # Only test if nvm.sh exists on this machine
    local nvm_found=false
    for path in /opt/homebrew/opt/nvm/nvm.sh /usr/local/opt/nvm/nvm.sh "$HOME/.nvm/nvm.sh"; do
        [[ -f "$path" ]] && nvm_found=true && break
    done
    if ! $nvm_found; then
        skip "NVM not installed"
    fi

    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/environment.zsh'
        type nvm
    "
    assert_success
    assert_output --partial "function"
}

@test "setopt options are applied" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/environment.zsh'
        setopt | grep autocd
    "
    assert_success
    assert_output --partial "autocd"
}

@test "PATH deduplication via typeset -U" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        source '${PROJECT_ROOT}/config/environment.zsh'
        # Check path is unique
        local dupes=0
        local -A seen
        for p in \$path; do
            if (( \${+seen[\$p]} )); then
                (( dupes++ ))
            fi
            seen[\$p]=1
        done
        echo \"\$dupes\"
    "
    assert_success
    assert_output "0"
}
