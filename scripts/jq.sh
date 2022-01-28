#!/bin/bash

stdin="$(echo "$@" | jq '.stdin')"
args="$(echo "$@" | jq -r '.args')"

if [[ -z "$stdin" ]]; then
        source <(echo "jq -n '$args'")
else
        source <(echo "echo '$stdin' | jq -r '$args'")
fi
