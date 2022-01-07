#!/bin/bash

rm -rf /home/webhookd/logs/*

printf "%s\n" "$@" | base64 -d - | pandoc -f "$f" -t "$t" --wrap=none
