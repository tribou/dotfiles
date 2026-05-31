#!/bin/bash

# Platform detection helpers
# Usage: if is_macos; then ... fi
# Usage: if is_linux; then ... fi

function is_macos () {
  [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname -s)" == "Darwin" ]]
}

function is_linux () {
  [[ "$OSTYPE" == "linux"* ]] || [[ "$(uname -s)" == "Linux" ]]
}
