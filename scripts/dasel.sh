#!/bin/bash

stdin="$(echo "$@" | dasel -np json '.stdin')"
args="$(echo "$@" | dasel -np json --plain '.args')"

source <(echo "echo '$stdin' | dasel $args -p json") || true
