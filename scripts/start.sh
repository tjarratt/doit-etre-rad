#!/usr/bin/env bash

set -ex
cd $(dirname $0)/..

# ensure everything is stopped
./scripts/stop.sh

mkdir -p logs

# start backend
$(./backend/scripts/start.sh > logs/frontend.log &)

# start frontend
$(./frontend/scripts/start.sh > logs/backend.log &)

# start nginx
nginx -c $(pwd)/nginx_proxy.conf
