#!/bin/bash

rm -rf /home/webhookd/logs/*

json='{"source_code":"","input":"","language":"bash","api_key":"guest","network":true,"longpoll":true,"longpoll_timeout":30}'

if [[ -z "$@" ]]; then
	jq -n '.error |= "Missing JSON data."'
	exit
fi

url="$(echo "$@" | jq -r '.url' 2>/dev/null)"

if [[ -z "$url" || "$url" == "null" ]]; then
	jq -n '.error |= "Missing url in JSON data."'
	exit
fi

name="$(echo "$@" | jq -r '.name' 2>/dev/null)"

if [[ -z "$url" || "$url" == "null" ]]; then
	jq -n '.error |= "Missing name in JSON data."'
	exit
fi

if [[ -n "$(echo "$@" | jq '.arguments?|length')" ]]; then
	arguments="$(echo "$@" | jq '.arguments[]' | perl -pe 'chomp if eof' | tr '\n' ' ')"
fi

source_code="$(curl -sL "$url" 2>/dev/null || true)"

if [[ -z "$source_code" ]]; then
	jq -n '.error |= "Failed to fetch data from url."'
	exit
fi

source_code="$source_code;$name $arguments"

json="$(echo "$json" | jq --arg src "$source_code" '.source_code |= $src')"

if [[ "$(echo "$@" | jq -r '.input' 2>/dev/null)" != "null" ]]; then
	json="$(echo "$json" | jq --arg in "$(echo "$@" | jq -r '.input' 2>/dev/null)" '.input |= $in')"
fi

if [[ "$(echo "$@" | jq -r '.language' 2>/dev/null)" != "" && "$(echo "$@" | jq -r '.language' 2>/dev/null)" != "null" ]]; then
	json="$(echo "$json" | jq --arg lang "$(echo "$@" | jq -r '.language' 2>/dev/null)" '.language |= $lang')"
fi

runner="$(curl -sLX POST 'http://api.paiza.io/runners/create' -H 'Content-Type: application/json' -d "$json" 2>/dev/null)"

if [[ -z "$runner" ]]; then
	jq -n '.error |= "Failed to execute runner."'
	exit
fi

id="$(echo "$runner" | jq -r '.id' 2>/dev/null)"

if [[ "$id" == "" || "$id" == "null" ]]; then
	echo "$runner" | jq '.'
	exit
fi

curl -sL "http://api.paiza.io/runners/get_details?id=${id}&api_key=guest" 2>/dev/null || jq -n '.error |= "Failed to fetch runner details."'
