#!/bin/bash
# Name: status
# Author: Syretia
# License: MIT
# Dependencies: curl, jq
# Description: gets connection info for a 'url'

# remove logs on every execution
rm -rf /home/webhookd/logs/*
# check if 'url' exists
if [[ -z "$url" ]]; then
  jq -n '.error |= "Missing required parameter url"'
  exit 0
fi
# use latest curl version with write out option '%json' to output connection info
# pipe into tac to make JSON first line
REQ="$(/home/syretia/curl -sLIX HEAD -w '\n%{json}\n' --max-time 7 -A "$RANDOM$RANDOM" "$url" | tac || true)"
# get JSON from first line
json="$(echo "$REQ" | head -n 1)"
# get headers from rest of lines
headers="$(echo "$REQ" | tail -n +2 | tac | jq -Rs 'split("\r\n") | .[0:-2]')"
# output response
echo "$json" | jq --sort-keys --argfile h <(echo -n "$headers") '.headers |= $h | .local_ip |= null'
