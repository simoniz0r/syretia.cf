#!/bin/bash

rm -rf /home/webhookd/logs/*

if [[ -n "$key" ]]; then
	curl -sL "https://spreadsheets.google.com/tq?&tq=&key=${key}&gid=2" | perl -pe 's%(.*google.visualization.Query.setResponse\(|\);)%%gm' | tail -n -1 | jq -r '.'
fi
