#!/bin/bash

# create token here https://github.com/settings/tokens
# export GITHUB_TOKEN=mysecrettoken 
# export GITHUB_USER=mygithubusername

set -u
set -e

repo=helm-infra$(date +%s)
kind delete cluster --name jointlarge
kind create cluster --name jointlarge
flux check --pre
flux bootstrap github \
     --owner=$GITHUB_USER \
     --repository=$repo \
     --branch=main \
     --path=app-cluster \
     --personal

git clone git@github.com:TaylorMonacelli/$repo
cd $repo
mkdir -p app-cluster/
flux create source helm podinfo \
     --url=https://stefanprodan.github.io/podinfo \
     --interval=20m \
     --namespace flux-system \
     --export >app-cluster/podinfo-helm-repo.yaml

flux create helmrelease podinfo \
     --source=HelmRepository/podinfo \
     --release-name=podinfo \
     --target-namespace=default \
     --chart=podinfo \
     --target-namespace=default \
     --chart-version=">5.0.0" \
     --export >app-cluster/podinfo-helm-chart.yaml

git add -A
git commit -am t
git push

sleep 60
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=podinfo
