#! /usr/bin/env bash
set -x

#TODO I dont know why we need to fight with the process tree of npm start
# https://stackoverflow.com/questions/52508896/pgrep-p-but-for-grandchildren-not-just-children/52544126#52544126
get_children() {
  unprocessed_pids=( $$ )
  while (( ${#unprocessed_pids[@]} > 0 )) ; do
    pid=${unprocessed_pids[0]}                      # Get first elem.
    echo "$pid"
    unprocessed_pids=( "${unprocessed_pids[@]:1}" ) # Remove first elem.
    unprocessed_pids+=( $(pgrep -P $pid) )          # Add child pids
  done
  }

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJ_ROOT=$(dirname $(dirname -- "$SCRIPT_DIR"))

on_exit() {
  [[ "$pid" ]] && { kill -SIGINT "$pid" "${procs[@]}"; wait "$pid" "${procs[@]}"; }
  }

trap on_exit EXIT

cd "$PROJ_ROOT/fincsi_frontend"

[[ ! -d node_modules ]] && npm install

#{ npm start | cat -; } & pid=$!
#TODO I dont know why we need to fight with the process tree of npm start
#TODO IDK how long we need to sleep
npm start 1>/dev/null 2>/dev/null & pid=$!
sleep 4; procs=($(get_children))
wait "$pid"
