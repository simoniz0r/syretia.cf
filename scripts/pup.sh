#!/bin/bash

rm -rf /home/webhookd/logs/*

if [[ -n "$u" && -n "$p" ]]; then
	# p="$p json{}"
	curl --max-time 2.5 -A "$RANDOM$RANDOM" -sL "$u" | pup "$p" 2>&1 | perl -pe 's%^EOF$%\[\]%'
fi
