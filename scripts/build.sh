#!/usr/bin/env bash

set -ex

elm-format src tests --yes
elm-make src/App.elm --yes
