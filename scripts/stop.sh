#!/usr/bin/env bash

lsof -i :5000 -i :8080 -i :8000 \
  | tail -n +2 \
  | grep -i listen \
  | tr -s ' ' \
  | cut -d ' ' -f 2 \
  | xargs kill -9
