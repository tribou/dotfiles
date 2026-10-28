#!/usr/bin/env bash
set -euo pipefail

# Run only the tests affected by the current changes (see docs/TESTING.md).
#
# Usage: test_changed.sh [--list] [FILE...]   run (or with --list, print) the test plan
#        test_changed.sh --check-headers      verify every unit test has a covers header
#
# Changed files default to everything since the merge-base with origin's
# default branch (override with DOTFILES_TEST_BASE), plus uncommitted and
# untracked files. Each tests/*.bats declares what it exercises with a
# "# covers: <glob>..." line; in these globs `*` also matches `/`.

# Changes here can break any test, so they always run the full unit suite.
CORE_PATTERNS=(lib/_shared.sh lib/index.sh lib/platform.sh 'tests/test_helper/*')
# Files no unit test exercises, unless a covers header claims them.
NO_UNIT_PATTERNS=('*.md' 'docs/*' LICENSE goss.yaml 'tests/integration/*' '.github/*')
# Files the Docker suite (`just test`) always exercises: integration tests,
# their helpers, and the lib files bash_profile runs to set up the environment.
DOCKER_PATTERNS=('tests/integration/*' 'tests/test_helper/*' lib/index.sh lib/path.sh lib/platform.sh)
# Files the Docker suite never touches; any change not listed here or above runs it.
DOCKER_SKIP_PATTERNS=('*.md' 'docs/*' LICENSE 'lib/*' scripts/doctor.sh scripts/perf_report.sh scripts/test_changed.sh 'skills/*' 'agent/*' 'tests/fixtures/*' '.github/*')

note() { printf 'test-changed: %s\n' "$1" >&2; }

matches_any() {
    local file="$1" pattern
    shift
    for pattern in "$@"; do
        # shellcheck disable=SC2053 # unquoted on purpose: glob match
        [[ "$file" == $pattern ]] && return 0
    done
    return 1
}

# Parallel arrays of (test file, covered pattern), read once from the headers.
COVER_TESTS=()
COVER_PATTERNS=()
load_covers() {
    local line test patterns pattern
    local -a words
    while IFS= read -r line; do
        test="${line%%:*}"
        patterns="${line#*:# covers:}"
        read -r -a words <<< "$patterns"
        for pattern in ${words[@]+"${words[@]}"}; do
            COVER_TESTS+=("$test")
            COVER_PATTERNS+=("$pattern")
        done
    done < <(grep -H '^# covers:' tests/*.bats 2>/dev/null || true)
}

is_unit_test_file() { [[ "$1" == tests/*.bats && "$1" != tests/*/* ]]; }

# Print the commit to diff against, or fail when it can't be determined.
resolve_base() {
    local ref
    if [[ -n "${DOTFILES_TEST_BASE:-}" ]]; then
        if ! git rev-parse --verify -q "${DOTFILES_TEST_BASE}^{commit}" >/dev/null; then
            note "DOTFILES_TEST_BASE '$DOTFILES_TEST_BASE' is not a commit"
            return 1
        fi
        echo "$DOTFILES_TEST_BASE"
        return
    fi
    for ref in origin/HEAD origin/main; do
        if git rev-parse --verify -q "$ref" >/dev/null; then
            if ! git merge-base HEAD "$ref"; then
                note "no merge-base between HEAD and $ref; set DOTFILES_TEST_BASE"
                return 1
            fi
            return
        fi
    done
    note "no origin/HEAD or origin/main; checking only uncommitted changes (set DOTFILES_TEST_BASE to include commits)"
    echo HEAD
}

changed_files() {
    local base
    base="$(resolve_base)" || return 1
    if ! git diff --name-only --no-renames "$base"; then
        note "git diff against $base failed"
        return 1
    fi
    git ls-files --others --exclude-standard
}

check_headers() {
    local status=0 test pattern i found file
    local -a files=()
    while IFS= read -r file; do files+=("$file"); done < <(git ls-files --cached --others --exclude-standard)
    for test in tests/*.bats; do
        if ! grep -q '^# covers:' "$test"; then
            echo "$test: missing '# covers:' header"
            status=1
        fi
    done
    for ((i = 0; i < ${#COVER_TESTS[@]}; i++)); do
        pattern="${COVER_PATTERNS[$i]}"
        found=0
        for file in "${files[@]}"; do
            # shellcheck disable=SC2053 # unquoted on purpose: glob match
            if [[ -e "$file" && "$file" == $pattern ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            echo "${COVER_TESTS[$i]}: '$pattern' matches no file"
            status=1
        fi
    done
    return $status
}

main() {
    local list=0 file i matched full=0 docker=0
    local -a changed=() selected=()

    cd "$(git rev-parse --show-toplevel)"
    load_covers

    case "${1:-}" in
        --check-headers) check_headers; return ;;
        --list) list=1; shift ;;
    esac

    if [[ $# -gt 0 ]]; then
        changed=("$@")
    else
        local files
        files="$(changed_files)" || return 1
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then changed+=("$file"); fi
        done < <(sort -u <<< "$files")
    fi
    if [[ ${#changed[@]} -eq 0 ]]; then
        note "no changes found; nothing to test"
        return 0
    fi

    for file in "${changed[@]}"; do
        if matches_any "$file" "${DOCKER_PATTERNS[@]}" ||
            ! { is_unit_test_file "$file" || matches_any "$file" "${DOCKER_SKIP_PATTERNS[@]}"; }; then
            [[ $docker -eq 0 ]] && note "$file -> Docker suite"
            docker=1
        fi

        if matches_any "$file" "${CORE_PATTERNS[@]}"; then
            note "$file is shared by all tests -> full unit suite"
            full=1
            continue
        fi
        matched=0
        if is_unit_test_file "$file" && [[ -f "$file" ]]; then
            selected+=("$file")
            matched=1
        fi
        for ((i = 0; i < ${#COVER_TESTS[@]}; i++)); do
            if matches_any "$file" "${COVER_PATTERNS[$i]}"; then
                selected+=("${COVER_TESTS[$i]}")
                matched=1
            fi
        done
        if [[ $matched -eq 0 ]] && ! matches_any "$file" "${NO_UNIT_PATTERNS[@]}"; then
            note "$file has no covering test -> full unit suite"
            full=1
        fi
    done

    if [[ ${#selected[@]} -gt 0 ]]; then
        local -a unique=()
        while IFS= read -r file; do unique+=("$file"); done < <(printf '%s\n' "${selected[@]}" | sort -u)
        selected=("${unique[@]}")
    fi

    if [[ $list -eq 1 ]]; then
        if [[ $full -eq 1 ]]; then
            echo "unit all"
        elif [[ ${#selected[@]} -eq 0 ]]; then
            echo "unit none"
        else
            printf 'unit %s\n' "${selected[@]}"
        fi
        if [[ $docker -eq 1 ]]; then echo "docker yes"; else echo "docker no"; fi
        return 0
    fi

    if [[ $full -eq 1 ]]; then
        just test-unit
    elif [[ ${#selected[@]} -gt 0 ]]; then
        just test-unit "${selected[@]}"
    else
        note "no unit tests affected"
    fi
    if [[ $docker -eq 1 ]]; then
        just test
    fi
}

main "$@"
