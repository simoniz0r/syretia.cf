#!/bin/bash

rm -rf /home/webhookd/logs/*

key="$(echo "$@" | jq -r '.key'):"
url="$(echo "$@" | jq -r '.url')"
name="$(echo "$@" | jq -r '.name')"

curl -sLX POST -u "$key" 'https://upload.imagekit.io/api/v1/files/upload' -F "file=$url" -F "fileName=$name" || true
