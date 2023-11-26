#! /usr/bin/env bash
set -x
# Interface:
#  Tf the $keep_postgres env var is set to "1", the postgres container we started (i.e. if it wasn't running already) isnt stopped.
#  The $container_manager env var can be set to change the container manager to e.g. "podman"
#  These can also be set in the scriptdir/myenv environment override file
#  If the $cid_file env var is set to a file, the id of the container that is run is written to it
#  If $test_mode is nonempty, the myenv override file isnt read, so that testing this file can be done consistently

#TODO requires ss
#TODO podman version issues on my system result in having to fiddle with default.nix
#TODO shellcheck this

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJ_ROOT=$(dirname $(dirname -- "$SCRIPT_DIR"))

# Inputs: file name as first argument
# Outputs: sets global variables and exports them
load_envfile() {
  local file="$1"
  mapfile -t arrg < "$PROJ_ROOT/$file"
  export "${arrg[@]}"
  }

# Starts a postgresql container.
#  Inputs: uses global environment from environment file as well as global $container_manager
#  Outputs: sets $running_postgres
start_postgres() {
  # Start postgres container if nothing is running on the desired postgres port
  if [[ "$(ss -lntpHo sport $SQL_PORT | wc -l)" -gt 0 ]]; then
    echo "Something is already running on port $SQL_PORT, not starting postgres."
  else
    running_postgres=1
    echo "Nothing is running on the desired postgres port; starting a postgres container..."
    cont_id=$("$container_manager" run -d -it --rm -p "$SQL_PORT":5432 -e POSTGRES_USER="$SQL_USER" -e POSTGRES_PASSWORD="$SQL_PASSWORD" -e POSTGRES_DB="$SQL_DATABASE" postgres)
    [[ -f "$cid_file" ]] && printf "$cont_id" >> "$cid_file"

    # Wait for database to be accessible and finish starting up
    while ! PGPASSWORD="$SQL_PASSWORD" psql -h "$SQL_HOST" -p "$SQL_PORT" -U "$SQL_USER" "$SQL_DATABASE" -c ""; do echo "waiting for postgres port..."; sleep 3; done
  fi
  }

# A hook to stop the postgresql container that we startef on exit (if we started it, and the user doesnt explcitly tell us to keep it)
#  Inputs: $cont_id global variable, $running_postgres global variable, $keep_postgres environment variable, $container_manager global variable, $runner_pids global variable
#  Outputs: none
on_exit() {
  if [[ "$running_postgres" -eq "1" ]] && [[ ! "$keep_postgres" -eq "1" ]]; then
    echo "running exit hook to stop the postgres container we started"
    "$container_manager" stop "$cont_id"
  else
    echo "we didnt start the possible postgres container ourselves, or we were told to keep it, not doing any cleanup"
  fi
  [[ "$runner_pids" ]] && { kill -SIGTERM "${runner_pids[@]}"; wait "${runner_pids[@]}"; }
  }

# Inputs: $container_manager environment variable
# Outputs: sets and exports DOTENV
main(){
  set -x

  # Provide a way to use podman instead
  container_manager=${container_manager:-docker}

  running_postgres=0

  trap on_exit EXIT

  # Load global environment variables / overrides from env file
  export DOTENV=env.split
  load_envfile "fincsi_backend/$DOTENV"
  # Load user's override file
  if [[ -f "$PROJ_ROOT/fincsi_backend/myenv" && -z "${test_mode}" ]]; then
    load_envfile "fincsi_backend/myenv"
  fi

  start_postgres

  #{ python manage.py migrate && python manage.py runserver "$DJANGO_HOST":"$DJANGO_PORT"; } & wait $!
  "$PROJ_ROOT/fincsi_backend/scripts/run.bash" & runner_pids+=($!)
  "$PROJ_ROOT/fincsi_backend/scripts/react_devserver.bash" & runner_pids+=($!)

  wait "${runner_pids[@]}"
  unset $runner_pids #TODO remove individual pids after they exit
  }

main
