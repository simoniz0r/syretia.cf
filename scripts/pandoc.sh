#!/bin/bash

printf "%s\n" "$@" | pandoc -f "$f" -t "$t" --wrap=none
