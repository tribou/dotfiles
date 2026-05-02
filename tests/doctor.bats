#!/usr/bin/env bats

setup() {
    # Project root is the current working directory when bats is run
    source scripts/doctor.sh
}

@test "main guard prevents automatic execution when sourced" {
    run bash -c 'source scripts/doctor.sh'
    [ "$status" -eq 0 ]
    # When sourced, main should not run, so no output
    [ "$output" = "" ]
}
