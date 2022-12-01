#!/bin/bash

# create token here https://github.com/settings/tokens
# export GITHUB_TOKEN=mysecrettoken
# export GITHUB_USER=mygithubusername

set -u
set -e

[ -z "$GITHUB_TOKEN" ] && echo GITHUB_TOKEN not set && exit 1

kind delete cluster --name jointlarge
kind create cluster --name jointlarge

kubectl get events --watch -A &

repo=helm-infra1669925171

flux check --pre
flux bootstrap github \
    --owner="$GITHUB_USER" \
    --repository="$repo" \
    --branch=main \
    --path=app-cluster \
    --personal
