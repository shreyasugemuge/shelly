#!/usr/bin/env bats
# Tests for config/prompt.zsh — prompt face and git integration

setup() { load test_helper/setup; }

@test "prompt.zsh: sources without error" {
    run zsh -c "
        autoload -Uz vcs_info
        source '${PROJECT_ROOT}/config/prompt.zsh'
        true
    "
    assert_success
}

@test "_set_face: yellow face on success (exit 0)" {
    run zsh -c "
        autoload -Uz vcs_info
        source '${PROJECT_ROOT}/config/prompt.zsh'
        # Simulate success
        (exit 0)
        _set_face
        echo \"\$_prompt_face\"
    "
    assert_success
    assert_output --partial "yellow"
    assert_output --partial "-_-"
}

@test "_set_face: red face on failure (exit 1)" {
    run zsh -c "
        autoload -Uz vcs_info
        source '${PROJECT_ROOT}/config/prompt.zsh'
        # Simulate failure
        (exit 1)
        _set_face
        echo \"\$_prompt_face\"
    "
    assert_success
    assert_output --partial "red"
    assert_output --partial "O_O"
}

@test "_set_face: red face on exit code 127" {
    run zsh -c "
        autoload -Uz vcs_info
        source '${PROJECT_ROOT}/config/prompt.zsh'
        (exit 127)
        _set_face
        echo \"\$_prompt_face\"
    "
    assert_success
    assert_output --partial "red"
    assert_output --partial "O_O"
}

@test "prompt: PROMPT variable is set" {
    run zsh -c "
        autoload -Uz vcs_info
        source '${PROJECT_ROOT}/config/prompt.zsh'
        [[ -n \"\$PROMPT\" ]]
    "
    assert_success
}

@test "prompt: precmd_functions includes _set_face" {
    run zsh -c "
        autoload -Uz vcs_info
        source '${PROJECT_ROOT}/config/prompt.zsh'
        echo \"\${precmd_functions[@]}\"
    "
    assert_success
    assert_output --partial "_set_face"
}

@test "prompt: precmd_functions includes _set_vcs_info" {
    run zsh -c "
        autoload -Uz vcs_info
        source '${PROJECT_ROOT}/config/prompt.zsh'
        echo \"\${precmd_functions[@]}\"
    "
    assert_success
    assert_output --partial "_set_vcs_info"
}
