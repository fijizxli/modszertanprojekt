#!/usr/bin/env bash

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJ_ROOT=$(dirname $(dirname $(dirname -- "$SCRIPT_DIR")))

echo "Running shellcheck..."
shopt -s globstar
shellcheck -o all "$PROJ_ROOT"/**/*.bash
shopt -u globstar
echo "End of shellcheck output"
