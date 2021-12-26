#!/bin/bash

ex="$(echo "$@" | jq -r '.expr')"
echo "$@" | jq --arg res "$(awk "BEGIN {print $ex}" 2>&1)" '.result |= $res'
