#!/bin/bash
# Name: metadata
# Author: Syretia
# License: MIT
# Dependencies: curl, jq, pup
# Description: output metadata for a given url in JSON format


rm -rf /home/webhookd/logs/*

if [[ -n "$url" ]]; then
	u="$url"
fi

if [[ -n "$u" ]]; then
	curl --max-time 2.5 -A "$RANDOM$RANDOM" -sL "$u" | \
	pup 'meta json{}' 2>&1 | \
	perl -pe 's%^EOF$%\[\]%' | \
	perl -pe 's%("property":|"http-equiv":)%"name":%g' | \
	perl -pe 's%"value":%"content":%g' | \
	jq --sort-keys 'walk(if type == "object" then del(.tag) else . end) | sort_by(.name)'
fi
