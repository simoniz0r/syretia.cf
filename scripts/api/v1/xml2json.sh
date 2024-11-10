#!/bin/bash
# Name: xml2json
# Author: Syretia
# License: MIT
# Dependencies: curl, oq
# Description: converts a 'url' containing an XML document to JSON

# remove logs
# rm -rf /home/webhookd/logs/*
# get XML document and pipe into 'oq' to convert to JSON
curl -sLA "$RANDOM$RANDOM" --max-time 50 "$url" | oq -i xml -o json
