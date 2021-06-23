#!/usr/bin/env bash

set -xeo pipefail

REPO="docker.pkg.github.com/clash-lang/clash-compiler"
NAME="clash-ci-"
DIR=$(dirname "$0")
now=$(date +%F)

GHC_VERSIONS=(  "9.0.1"   "8.10.2"  "8.8.4"   "8.6.5")
CABAL_VERSIONS=("3.4.0.0" "3.2.0.0" "3.2.0.0" "3.0.0.0")

# We want to use docker buildkit so that our layers are built in parallel. This
# is ignored completely on versions of docker which don't support buildkit.
export DOCKER_BUILDKIT=1

for i in "${!GHC_VERSIONS[@]}"
do
  GHC_VERSION="${GHC_VERSIONS[i]}"
  CABAL_VERSION="${CABAL_VERSIONS[i]}"

  docker build \
    --build-arg cabal_version=${CABAL_VERSION} \
    --build-arg ghc_version=${GHC_VERSION} \
    -t "${REPO}/${NAME}${GHC_VERSION}:$now" \
    -t "${REPO}/${NAME}${GHC_VERSION}:latest" \
    "$DIR"
done

read -p "Push to GitHub? (y/N) " push

if [[ $push =~ ^[Yy]$ ]]; then
  for i in "${!GHC_VERSIONS[@]}"
  do
    GHC_VERSION="${GHC_VERSIONS[i]}"
    docker push "${REPO}/${NAME}${GHC_VERSION}:$now"
    docker push "${REPO}/${NAME}${GHC_VERSION}:latest"
  done
else
  echo "Skipping push to container registry"
fi
