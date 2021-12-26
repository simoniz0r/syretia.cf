#!/bin/bash

if [[ -z "$@" ]]; then
	curl -sL "https://jsonbase.com/$p"
else
	curl -sLX PUT "https://jsonbase.com/$p" -d "$@" -H 'content-type: application/json'
fi
