#!/bin/bash
# Name: debian
# Author: Syretia
# License: MIT
# Dependencies: curl, jq, pup
# Description: Debian package search

pkg_name="$(curl -sL "https://packages.debian.org/search?suite=bookworm&searchon=names&keywords=$q" | \
pup 'a attr{href}' | \
grep -m1 '^/bookworm/' | \
cut -f3 -d'/')"

if [[ -z "$pkg_name" ]]; then
	exit 0
fi

curl -sL "https://packages.debian.org/bookworm/$pkg_name" | \
pup 'meta json{}' | \
jq --arg pn "$pkg_name" '{name: $pn, description: .[2].content, info: .[3].content, author: .[1].content}'
rm -rf /home/webhookd/logs/*
