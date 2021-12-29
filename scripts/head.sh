#!/bin/bash

rm -rf /home/webhookd/logs/*

# agent="$(curl -sL 'https://generate-name.net/user-agent' | pup 'td.name text{}' | head -n 1 | perl -pe 'chomp if eof')"
curl -sL --max-time 2.5 "$u" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36" --show-error | pup 'head'
