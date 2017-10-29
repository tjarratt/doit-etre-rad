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
cp assets/index.css tmp/app/assets/index-${timestamp}.css
cp assets/elm-init.js tmp/app/assets/elm-init-${timestamp}.js
cp assets/application.appcache tmp/app/assets/application.appcache
sed -i '' "s/index.js/index-${timestamp}.js/" tmp/app/index.html
sed -i '' "s/index.css/index-${timestamp}.css/" tmp/app/index.html
sed -i '' "s/elm-init.js/elm-init-${timestamp}.js/" tmp/app/index.html
sed -i '' "s/VERSION/${timestamp}/" tmp/app/assets/application.appcache

cp assets/drapeau_francais_retina.png tmp/app/assets
cp assets/drapeau_francais_favicon.ico tmp/app/favicon.ico

cf push
