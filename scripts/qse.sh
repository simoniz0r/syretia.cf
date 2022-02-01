#!/bin/bash

rm -rf /home/webhookd/logs/*

if [[ -n "$q" ]]; then
    q="$(echo "$q" | jq -Rr '@uri' | perl -pe 's/%20/+/g')"
    curl -sL "https://api.qwant.com/v3/search/web?count=10&q=${q}&t=web&locale=en_US&device=desktop&offset=0&safesearch=1" -A "$RANDOM$RANDOM" | \
	jq '[ .data.result.items.mainline[] | select(.type == "web") ]'
fi
