#!/usr/bin/env bash

set -ex

# clean out tmp
cd $(dirname $0)/..
rm -rf tmp/*

# put migrations into place
mkdir tmp/migrations
cp db/migrations/*.sql tmp/migrations

# build our application
go build main.go

# move our application into place
mv main tmp/

# move our Procfile into place
cp Procfile tmp/
