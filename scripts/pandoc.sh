#!/bin/bash

rm -rf /home/webhookd/logs/*

printf "%s\n" "$@" | pandoc -f "$f" -t "$t" --wrap=none
