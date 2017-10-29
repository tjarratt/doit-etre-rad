#!/usr/bin/env bash

set -ex

elm-format src tests --yes
elm-css src/Stylesheets.elm --output=assets
elm-make src/App.elm --yes --output=assets/index.js
