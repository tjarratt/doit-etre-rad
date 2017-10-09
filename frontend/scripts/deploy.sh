#!/usr/bin/env bash

set -ex

cd $(dirname $0)/..

scripts/build.sh

rm -rf tmp/*
mkdir tmp/app
cp -r Staticfile nginx tmp
cp index.html index.js elm-init.js tmp/app

cf push
