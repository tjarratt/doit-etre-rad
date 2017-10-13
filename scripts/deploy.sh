#!/usr/bin/env bash

set -ex

pushd backend
./scripts/deploy.sh
popd

pushd frontend
./scripts/deploy.sh
popd
