#!/usr/bin/env bash

set -ex

# setup.sh
# This script can be run to ensure new machines can build and run
# this project without much additional setup.
# Make sure you already have npm installed, otherwise you'll be sad.
# (purposefully exclused this step since installation of npm can be done
# differently depending on host OS - whether it's OS X, unix or Windows)

cd $(dirname $0)/..

pushd frontend

# ensure npm is up-to-date
npm -i g npm

# install elm itself
npm install -g elm
npm install -g elm-css
npm install -g elm-test
npm install -g elm-format
npm install -g elm-oracle
npm install -g elm-github-install

# install elm github-only-dependencies (e.g.: Elmer)
pushd tests
elm install
popd

# install various packages
elm package install

popd # done with frontend 

# installing backend items
brew install go

pushd backend
go get -u ./... 
popd
