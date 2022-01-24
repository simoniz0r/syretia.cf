#!/bin/bash

# path="$(echo "$@" | oq -r '.path | @uri')"

if [[ "$path" == "" ]]; then
	oq -n '.error |= "Missing required parameter path"'
	exit 0
fi

path="$(echo "$path" | oq -Rr '@uri')"

curl -sL "https://opi-proxy.opensuse.org/?obs_api_link=https%3A%2F%2Fapi.opensuse.org%2F$path&obs_instance=openSUSE" 2>/dev/null | \
oq -i xml -o json 2>/dev/null || \
oq -n '.error |= "Failed to convert XML to JSON"'
