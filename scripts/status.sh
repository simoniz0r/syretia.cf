#!/bin/bash

rm -rf /home/webhookd/logs/*

[[ -n "$url" ]] && u="$url"
curl --max-time 7 --show-error -sIX HEAD "$u" 2>&1 | head -n 1 || true
