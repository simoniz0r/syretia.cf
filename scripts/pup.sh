#!/bin/bash
# Name: pup
# Author: Syretia
# License: MIT
# Dependencies: curl, jq, pup
# Description: Get data from HTML websites without an API using CSS selectors

# remove logs
rm -rf /home/webhookd/logs/*

# if query uses url or path vars, set to u or p
if [[ -n "$url" ]]; then
	u="$url"
fi
if [[ -n "$path" ]]; then
	p="$path"
fi

# if variables set, make request
if [[ -n "$u" && -n "$p" ]]; then
	data="$(curl --max-time 50 -A "$RANDOM$RANDOM" -sL "$u" 2>/dev/null || true)"
	# error if no data returned
	if [[ -z "$data" ]]; then
		jq -n '.error += "Curl response contained no data"'
		exit 0
	fi
	# parse data with pup
    echo "$data" | pup "$p" 2>&1 | perl -pe 's%^EOF$%\[\]%' || true
else
	# error if variables not set
	jq -n '.error += "Missing required input"'
fi
