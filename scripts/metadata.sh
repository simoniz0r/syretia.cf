#!/bin/bash
# Name: metadata
# Author: Syretia
# License: MIT
# Dependencies: curl, jq, pup
# Description: output metadata for a given url in JSON format

#remove logs
# rm -rf /home/webhookd/logs/*

# set url to u variable if present
if [[ -n "$u" ]]; then
	url="$u"
fi

# fetch url, use pup to get metadata, then filter using perl and jq
if [[ -n "$url" ]]; then
	curl --max-time 50 -A "$RANDOM$RANDOM" -sL "$url" | \
	pup 'meta json{}' 2>&1 | \
	perl -pe 's%^EOF$%\[\]%' | \
	perl -pe 's%("property":|"http-equiv":)%"name":%g' | \
	perl -pe 's%"value":%"content":%g' | \
	jq --sort-keys 'walk(if type == "object" then del(.tag) else . end) | sort_by(.name)'
fi
