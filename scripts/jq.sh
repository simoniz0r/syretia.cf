#!/bin/bash

stdin="$(echo "$@" | jq '.stdin')"
args="$(echo "$@" | jq -r '.args')"

if [[ -z "$stdin" ]]; then
        source <(echo "jq -n '$args'") || true
else
        source <(echo "echo '$stdin' | jq -r '$args'") || true
fi
