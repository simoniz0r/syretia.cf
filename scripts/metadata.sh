#!/bin/bash

if [[ -n "$u" ]]; then
	curl --max-time 2.5 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36" -sL "$u" | pup 'meta json{}' 2>&1 | perl -pe 's%^EOF$%\[\]%' | perl -pe 's%("property":|"http-equiv":)%"name":%g' | perl -pe 's%"value":%"content":%g' | jq --sort-keys 'walk(if type == "object" then del(.tag) else . end) | sort_by(.name)'
fi
