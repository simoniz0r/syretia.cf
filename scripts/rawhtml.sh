#!/bin/bash

if [[ -n "$u" ]]; then
	curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36" --max-time 2.5 --show-error "$u" 2>&1 || true
fi
