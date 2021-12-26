#!/bin/bash

if [[ -n "$u" && -n "$p" ]]; then
	p="$p json{}"
	curl --max-time 2.5 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36" -sL "$u" | pup "$p" 2>&1 | perl -pe 's%^EOF$%\[\]%'
fi
