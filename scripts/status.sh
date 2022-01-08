#!/bin/bash

rm -rf /home/webhookd/logs/*

if [[ -z "$url" ]]; then
  jq -n '.error |= "Missing required parameter url"'
  exit 0
fi

REQ="$(/home/syretia/curl -sLIX HEAD -w '\n%{json}\n' --max-time 7 -A "$RANDOM$RANDOM" "$url" | tac || true)"

json="$(echo "$REQ" | head -n 1)"
headers="$(echo "$REQ" | tail -n +2 | tac | jq -Rs 'split("\r\n") | .[0:-2]')"

echo "$json" | jq --sort-keys --argfile h <(echo -n "$headers") '.headers |= $h | .local_ip |= null'
