#! /usr/bin/env bash
set -x
#TODO currently this file is docker specific

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJ_ROOT=$(dirname $(dirname -- "$SCRIPT_DIR"))

#TODO may be destructive, are there cases where we shouldnt try this? / where we arent the ones that created everything?
on_exit() {
  #TODO need to special-case podman
  #TODO also what about volumes
  [[ "$pid" ]] && { kill -SIGTERM "$pid"; wait "$pid"; }
  #TODO need a way to allow creating isolated temporary volumes
  "$container_manager" compose down ${delete_volumes:+-v}
#  kill -SIGTERM "$handlepid"
#  rm "$PROJ_ROOT/run/tests_cleanup_handle_$$"
  }

#mk_cleanup_handle() {
#  mkdir -p "$PROJ_ROOT/run"
#  sleep inf & handlepid=$!
#  echo "$handlepid" >> "$PROJ_ROOT/run/tests_cleanup_handle_$$"
#  }

main() {
  # Provide a way to use podman instead
  container_manager=${container_manager:-docker}

  trap on_exit EXIT
  #mk_cleanup_handle

  #TODO need to special-case podman
  "$container_manager" compose up -d
  [[ "$cid_file" ]] && "$container_manager" compose ps -qa >> "$cid_file"
  sleep inf & pid=$!
  wait $pid
  }

main
