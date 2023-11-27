#!/usr/bin/env bash
set -x
export SHELLOPTS

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJ_ROOT=$(dirname $(dirname -- "$SCRIPT_DIR"))

{ trap - INT; "$PROJ_ROOT/scripts"/run.split.bash; } & testee_pid=$!
kill -sINT $testee_pid;
