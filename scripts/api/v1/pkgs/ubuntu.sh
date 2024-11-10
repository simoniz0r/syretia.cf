#!/bin/bash
# Name: ubuntu
# Author: Syretia
# License: MIT
# Dependencies: curl, jq, pup
# Description: Ubuntu package search

# support old query variable
if [[ -n "$q" ]]; then
	query="$q"
fi
# set release to bookworm if not set
if [[ -z "$release" ]]; then
	release="noble"
fi
# scrape package name from search results
pkg_name="$(curl --max-time 25 -sL "https://packages.ubuntu.com/search?suite=$release&searchon=names&keywords=$query" | \
pup 'a attr{href}' | \
grep -m1 "^/$release/" | \
cut -f3 -d'/')"
# exit if not found
if [[ -z "$pkg_name" ]]; then
	jq -n '.error |= "No results found"'
	exit 0
fi
# get metadata from package page which has version, description, etc
curl --max-time 25 -sL "https://packages.ubuntu.com/$release/$pkg_name" | \
pup 'meta json{}' | \
jq --arg pn "$pkg_name" '{name: $pn, description: .[2].content, info: .[3].content, author: .[1].content}'
# rm -rf /home/webhookd/logs/*
