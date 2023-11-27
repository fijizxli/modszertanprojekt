#! /usr/bin/env bash
set -x

on_exit() {
  [[ "$pid" ]] && { kill -SIGTERM "$pid"; wait "$pid"; }
  }

trap on_exit EXIT



python manage.py migrate && { python manage.py runserver "${DJANGO_HOST:-127.0.0.1}":"${DJANGO_PORT:-8000}" & pid=$!; wait "$pid"; }
