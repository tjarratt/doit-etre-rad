#!/usr/bin/env bash

set -ex

cd $(dirname $0)/..

scripts/build.sh

rm -rf tmp/*
mkdir -p tmp/app/assets
cp -r Staticfile nginx tmp
cp index.html tmp/app

# move all of our assets into the deploy directory
cp assets/* assets/*.css tmp/app/assets/

# version our application cache
# if we version the assets (javascript, css, etc...) then the browser will
# freakout when they go away, so its a much better practice to just have a
# version string in the appcache manifest itself
timestamp=$(date +"%s")
sed -i '' "s/VERSION/${timestamp}/" tmp/app/assets/application.appcache

cf push
