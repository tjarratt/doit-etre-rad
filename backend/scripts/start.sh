#!/usr/bin/env bash

set -e
cd $(dirname $0)/..

export PORT=8080
source secret_env_vars

go run main.go

