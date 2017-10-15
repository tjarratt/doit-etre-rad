#!/usr/bin/env bash

set -ex

cd $(dirname $0)/..

scripts/build.sh

rm -rf tmp/*
mkdir tmp/app
cp -r Staticfile nginx tmp
cp index.html tmp/app

timestamp=$(date +"%s")
cp index.js tmp/app/index-${timestamp}.js
cp elm-init.js tmp/app/elm-init-${timestamp}.js
sed -i '' "s/index.js/index-${timestamp}.js/" tmp/app/index.html
sed -i '' "s/elm-init.js/elm-init-${timestamp}.js/" tmp/app/index.html

cf push
