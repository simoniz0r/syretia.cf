#!/bin/bash

rm -rf /home/webhookd/logs/*

curl -sLA "$RANDOM$RANDOM" "$url" | oq -i xml -o json
