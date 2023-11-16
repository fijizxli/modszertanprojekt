#! /usr/bin/env bash
set -x

#Hack so that we dont have to deploy a wsgi server and static file server or whatever for now
if [[ "$DEBUG" == "False" ]]; then INSECURE=--insecure; fi

cd fincsi_backend
python manage.py migrate && python manage.py runserver 0.0.0.0:8000 $INSECURE
