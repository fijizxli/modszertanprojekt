#! /usr/bin/env bash
#TODO shellcheck this

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJ_ROOT=$(dirname $(dirname -- "$SCRIPT_DIR"))

##lib
# global
kill_testee() {
  [[ "$testee_pid" ]] && kill -SIGTERM "$testee_pid"
  wait "$testee_pid"
  }

check_lingering() {
  #TODO
  :
  }

on_exit() {
  kill_testee
  check_lingering
  }

fail() {
  local message="$1"
  echo "$message" >&2
  exit 1
  }

scoped_load_envfile() {
  local scope="$1"
  local file="$2"
  mapfile -t arrg < <(sed "s/^/${scope}_/" < "$PROJ_ROOT/$file")
  export "${arrg[@]}"
  }

wait_cleanup_handles() {
  local procs=()
  for i in "$PROJ_ROOT/run"/*; do
    tail -f /dev/null --pid=$(cat $i) & procs+=($!)
  done
  wait "${procs[@]}"
  }

check_port() {
  local annotation="$1"
  local host="$2"
  local port="$3"
  nc -z "$host" "$port"
  return $?
  }

wait_for_port() {
  local count="$1"
  local wait="$2"
  local annotation="$3"
  local attempts=0
  shift; shift

  while ! { sleep "$wait"; check_port "$@"; }; do
    echo "Waiting for port ($@)..."
    if [[ "$((++attempts))" -gt "$count" ]]; then
      fail "$annotation: Port did not appear to be open after $attempts attempt waiting $((wait*attempts)) seconds."
    fi
  done
  }

assert_port() {
  check_port "$@" || fail "$annotation: Port $host $port does not appear to be open."
  }

# sets global res to the response code string
http_get_response_code() {
  local url="$1"
  res=$(curl -o /dev/null -s -w "%{http_code}\n" "$url")
  }

check_postgres_ready() {
  local host="$1"
  local port="$2"
  local user="$3"
  local password="$4"
  local database="$5"
  PGPASSWORD="$password" psql -h "$host" -p "$port" -U "$user" "$database" -c ""
  return $? # Returns 0 if successful
  }

assert_django() {
  local proto="$1"
  local host="$2"
  local port="$3"
  local endpoints=(
    "/admin/" "302"
    "/api/falatok/" "403"
    "/api/auth/" "404"
    )

  #TODO make this fit the scheme of the other commands
  #TODO not sure what causes this
  # Wait for django to come up
  # We deliberately use a url that wouldnt be proxied to the react dev server by the url routing
  local url="$proto://$host:$port/admin/"
  local attempts=0
  local wait=3
  while true; do
    http_get_response_code "$url"
    local code="$res"
    if [[ "$((++attempts))" -gt 7 ]]; then
      fail "Django server did not come up in time with nonzero HTTP code. (timeout)"
    elif [[ "$code" -eq "000" ]]; then
      sleep "$wait";
    else
      break
    fi
  done

  for i in $(seq 0 $(("${#endpoints[@]}"/2-1))); do
    local url="$proto://$host:$port${endpoints[$((i*2))]}"
    http_get_response_code "$url"
    local code="$res"
    [[ "${endpoints[$((i*2+1))]}" -eq "$code" ]] || fail "Unexpected HTTP GET response code $code for ${url} while looking for the django backend."
  done
  }

#TODO make this fit the scheme of the other commands
assert_react() {
  local proto="$1"
  local host="$2"
  local port="$3"
  local url="$proto://$host:$port/static/js/bundle.js"
  local attempts=0
  local wait="3"
  # Need to wait for the react dev server to come up
  while true; do
    http_get_response_code "$url"
    local code="$res"
    if [[ "$((++attempts))" -gt 7 ]]; then
      fail "React dev server did not come up in time with nonzero HTTP code. (timeout)"
    elif [[ "$code" -eq "000" ]]; then
      sleep "$wait";
    elif [[ "$code" -eq "200" ]]; then
      break
      ##TODO assert content makes sense since there was a bug with this
      #[[ "$res" -eq "200" ]] || fail "Unexpected HTTP GET response code $code for $url while looking for the react frontend"
    fi
  done
  }

##/lib

#TODO the podman/docker split here is a bit funky and depends on system level configuration and overrides so this isnt exactly hermetic...
#The "solution" would be to test in nested podman?
#TODO wont work till integui branch is merged
test_compose() {
  cid_file=$(mktemp)
  delete_volumes=1 cid_fle="$cid_file" "$PROJ_ROOT/scripts"/run.compose.bash & testee_pid=$!
  wait_for_port "12" "3" "wait for django" "localhost" "8000"
  assert_django "http" "localhost" "8000"
  #TODO#assert_react "http" "localhost" "8000"
  kill_testee # success
  #TODO check process cleaned up?
  }

test_split() {
  cid_file=$(mktemp)
  cid_file="$cid_file" "$PROJ_ROOT/scripts"/run.split.bash & testee_pid=$!
  wait_for_port "12" "3" "wait for django" "localhost" "8000"
  assert_django "http" "localhost" "8000"
  assert_react "http" "localhost" "3000" #TODO
  kill_testee
  #TODO check process cleaned up?
  }

test_compose_docker(){
  test_compose
  }

test_split_docker(){
  test_split
  }

test_compose_podman(){
  cid_file=$(mktemp)
  testee_pid_file=$(mktemp)
  (
    export container_manager=podman DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
    delete_volumes=1 cid_fle="$cid_file" "$PROJ_ROOT/scripts"/run.compose.bash & testee_pid=$!
    printf "$testee_pid" >> "$testee_pid_file" #TODO meh this is overly complicated
    )
  testee_pid=$(cat "$testee_pid_file")
  wait_for_port "12" "3" "wait for django" "localhost" "8000"
  assert_django "http" "localhost" "8000"
  #TODO#assert_react "http" "localhost" "8000"
  kill_testee # success
  #TODO check process cleaned up?
  }

test_split_podman(){
  cid_file=$(mktemp)
  testee_pid_file=$(mktemp)
  (
    export container_manager=podman DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
    cid_file="$cid_file" "$PROJ_ROOT/scripts"/run.split.bash & testee_pid=$!
    printf "$testee_pid" >> "$testee_pid_file" #TODO meh this is overly complicated
    )
  testee_pid=$(cat "$testee_pid_file")
  wait_for_port "12" "3" "wait for django" "localhost" "8000"
  assert_django "http" "localhost" "8000"
  assert_react "http" "localhost" "3000" #TODO
  kill_testee
  #TODO check process cleaned up?
  }

main() {
  set -x

  scoped_load_envfile "split" "env.split"

  trap on_exit EXIT

  export test_mode=1 # run.split.bash disables reading myenv so we can run tests
  # Podman is tested first because it has better tooling for waitign for containers to finish
  test_split_podman
  sleep 3 # maybe port will go away?
  #wait_cleanup_handles
  #test_compose_podman
  #wait_cleanup_handles
  #TODO I dont see a quick way to make this work with compose and this might not be necessary anyway
  mapfile -t cids < "$cid_file"
  #[[ "$cids" ]] && timeout 15 podman wait "${cids[@]}" --condition=stopped || fail "Timed out (or something) waiting for docker postgres to shut down."
  test_split_docker
  sleep 3 # maybe port will go away?
  #wait_cleanup_handles
  test_compose_docker
  sleep 3 # maybe port will go away?
  #wait_cleanup_handles
  }

main

