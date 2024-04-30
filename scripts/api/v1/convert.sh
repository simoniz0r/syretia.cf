#!/bin/bash
# Name: convert
# Author: Syretia
# License: MIT
# Dependencies: curl, dasel
# Description: converts a 'url' 'from' a given format 'to' another

# remove logs
rm -rf /home/webhookd/logs/*

# check if variables set
if [[ -z "$from" || -z "$to" || -z "$url" ]]; then
	echo '' | dasel put -r json -s '.error' -v 'Missing required input.'
	exit 0
fi	

# get document and pipe into 'dasel' to be converted
curl -sLA "$RANDOM$RANDOM" --max-time 30 "$url" 2>/dev/null | dasel -r "$from" -w "$to" || true
