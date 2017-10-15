#!/usr/bin/env bash

set -ex
cd $(dirname $0)/..

./scripts/build.sh
elm reactor

# TODO : watch files and re-build automatically

