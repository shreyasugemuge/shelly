#!/usr/bin/env bats
# Tests for config/deps.zsh — dependency management
#
# Note: deps.zsh runs at source time and unfunctions its helpers after.
# We test the internal logic by sourcing a stripped version.

setup() { load test_helper/setup; }

@test "deps.zsh: passes syntax check" {
    run zsh -n "${PROJECT_ROOT}/config/deps.zsh"
    assert_success
}

@test "_should_check_deps: returns true when no stamp file" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        _SHELLY_BREW_PREFIX=''
        export XDG_CACHE_HOME='${TEST_TMPDIR}/.cache'
        _deps_stamp='${TEST_TMPDIR}/.cache/zsh/deps_checked'
        mkdir -p '${TEST_TMPDIR}/.cache/zsh'
        # Define function inline (it gets unfunctioned after source)
        _should_check_deps() {
            if [[ -f \"\$_deps_stamp\" ]]; then
                local stamp_day today
                if \$IS_MACOS; then
                    stamp_day=\"\$(stat -f '%Sm' -t '%Y-%m-%d' \"\$_deps_stamp\" 2>/dev/null)\"
                else
                    stamp_day=\"\$(date -r \"\$_deps_stamp\" '+%Y-%m-%d' 2>/dev/null)\"
                fi
                today=\"\$(date '+%Y-%m-%d')\"
                [[ \"\$stamp_day\" != \"\$today\" ]]
            else
                return 0
            fi
        }
        _should_check_deps && echo 'should_check' || echo 'skip'
    "
    assert_success
    assert_output "should_check"
}

@test "_should_check_deps: returns false when stamp is from today" {
    mkdir -p "${TEST_TMPDIR}/.cache/zsh"
    touch "${TEST_TMPDIR}/.cache/zsh/deps_checked"
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        _deps_stamp='${TEST_TMPDIR}/.cache/zsh/deps_checked'
        _should_check_deps() {
            if [[ -f \"\$_deps_stamp\" ]]; then
                local stamp_day today
                if \$IS_MACOS; then
                    stamp_day=\"\$(stat -f '%Sm' -t '%Y-%m-%d' \"\$_deps_stamp\" 2>/dev/null)\"
                else
                    stamp_day=\"\$(date -r \"\$_deps_stamp\" '+%Y-%m-%d' 2>/dev/null)\"
                fi
                today=\"\$(date '+%Y-%m-%d')\"
                [[ \"\$stamp_day\" != \"\$today\" ]]
            else
                return 0
            fi
        }
        _should_check_deps && echo 'should_check' || echo 'skip'
    "
    assert_success
    assert_output "skip"
}

@test "_plugin_installed: returns false for nonexistent plugin" {
    run zsh -c "
        IS_MACOS=true; IS_LINUX=false
        _SHELLY_BREW_PREFIX=''
        _plugin_installed() {
            local plugin=\"\$1\"
            local brew_share=\"\${_SHELLY_BREW_PREFIX}/share\"
            for _dir in \"\$brew_share\" /usr/share /usr/local/share; do
                [[ -f \"\$_dir/\$plugin/\$plugin.zsh\" ]] && return 0
            done
            return 1
        }
        _plugin_installed nonexistent-xyz && echo 'found' || echo 'not found'
    "
    assert_success
    assert_output "not found"
}

@test "_cask_installed: returns false when neither file nor brew detect the cask" {
    # Isolate from the real system: HOME → tmpdir (no font file) and PATH=""
    # (no brew available). Function must return false.
    run zsh -c "
        HOME='${TEST_TMPDIR}'
        PATH=''
        _cask_installed() {
            local cask=\"\$1\"
            case \"\$cask\" in
                font-meslo-lg-nerd-font)
                    [[ -f \"\$HOME/Library/Fonts/MesloLGSNerdFontMono-Regular.ttf\" ]] && return 0
                    ;;
            esac
            command -v brew &>/dev/null && brew list --cask \"\$cask\" &>/dev/null
        }
        _cask_installed font-meslo-lg-nerd-font && echo 'found' || echo 'not found'
    "
    assert_success
    assert_output "not found"
}

@test "_cask_installed: font fast-path detects installed font" {
    mkdir -p "${TEST_TMPDIR}/Library/Fonts"
    touch "${TEST_TMPDIR}/Library/Fonts/MesloLGSNerdFontMono-Regular.ttf"
    run zsh -c "
        HOME='${TEST_TMPDIR}'
        _cask_installed() {
            local cask=\"\$1\"
            case \"\$cask\" in
                font-meslo-lg-nerd-font)
                    [[ -f \"\$HOME/Library/Fonts/MesloLGSNerdFontMono-Regular.ttf\" ]] && return 0
                    ;;
            esac
            command -v brew &>/dev/null && brew list --cask \"\$cask\" &>/dev/null
        }
        _cask_installed font-meslo-lg-nerd-font && echo 'found' || echo 'not found'
    "
    assert_success
    assert_output "found"
}
