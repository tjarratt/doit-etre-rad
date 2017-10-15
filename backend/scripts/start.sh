#!/usr/bin/env bash

set -e
cd $(dirname $0)/..

./scripts/build.sh

export PORT=8080
source secret_env_vars

./tmp/main

