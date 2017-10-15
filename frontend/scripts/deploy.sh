#!/usr/bin/env bash

set -ex

cd $(dirname $0)/..

scripts/build.sh

rm -rf tmp/*
mkdir -p tmp/app/assets
cp -r Staticfile nginx tmp
cp index.html tmp/app

timestamp=$(date +"%s")
cp assets/index.js tmp/app/assets/index-${timestamp}.js
cp assets/elm-init.js tmp/app/assets/elm-init-${timestamp}.js
cp assets/application.appcache tmp/app/assets/application.appcache
sed -i '' "s/index.js/index-${timestamp}.js/" tmp/app/index.html
sed -i '' "s/elm-init.js/elm-init-${timestamp}.js/" tmp/app/index.html
sed -i '' "s/VERSION/${timestamp}/" tmp/app/assets/application.appcache

#cf push
