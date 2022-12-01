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

repo=helm-infra$(date +%s)

flux check --pre
flux bootstrap github \
    --owner="$GITHUB_USER" \
    --repository="$repo" \
    --branch=main \
    --path=app-cluster \
    --personal

git clone "git@github.com:TaylorMonacelli/$repo"

cd "$repo"
mkdir -p app-cluster/

# podinfo
flux create source helm podinfo \
    --url=https://stefanprodan.github.io/podinfo \
    --interval=20m \
    --namespace flux-system \
    --export >app-cluster/podinfo-helm-repo.yaml

flux create helmrelease podinfo \
    --source=HelmRepository/podinfo \
    --release-name=podinfo \
    --create-target-namespace \
    --target-namespace=test \
    --chart=podinfo \
    --export >app-cluster/podinfo-helm-chart.yaml

# redis
flux create source helm bitnami \
    --url=https://charts.bitnami.com/bitnami \
    --interval=20m \
    --namespace flux-system \
    --export >app-cluster/bitnami-helm-repo.yaml

flux create helmrelease redis \
    --source=HelmRepository/bitnami \
    --chart=redis \
    --release-name=redis \
    --create-target-namespace \
    --chart-version="17.3.13" \
    --target-namespace=test \
    --export >app-cluster/helmrelease-redis.yaml

git add -A
git commit -am test
git push
