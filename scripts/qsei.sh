#!/bin/bash

rm -rf /home/webhookd/logs/*

if [[ -n "$q" ]]; then
    q="$(echo "$q" | jq -Rr '@uri' | perl -pe 's/%20/+/g')"
    curl -sL "https://api.qwant.com/v3/search/images?count=10&q=${q}&t=images&safesearch=1&locale=en_US&uiv=4" -A "$RANDOM$RANDOM"
fi
