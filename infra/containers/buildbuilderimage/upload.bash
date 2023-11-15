#! /usr/bin/env bash
set -x
podman build --tag=buildimage . || exit 1
podman push --tls-verify=false --creds=actionautomation:actionautomation localhost/buildimage p.p2.kolmogorov.space:64743/modszproj/buildimage:22.04
