#!/usr/bin/env bash

set -ex

pushd frontend
elm test
popd

pushd backend
ginkgo -r . 
popd
