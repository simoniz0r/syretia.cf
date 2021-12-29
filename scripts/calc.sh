#!/bin/bash

rm -rf /home/webhookd/logs/*

ex="$(echo "$@" | jq -r '.expr')"
echo "$@" | jq --arg res "$(awk "BEGIN {print $ex}" 2>&1)" '.result |= $res'
