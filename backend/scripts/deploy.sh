#!/usr/bin/env bash

set -ex

cd $(dirname $0)/..

GOOS=linux GOARCH=amd64 ./scripts/build.sh

cf push
