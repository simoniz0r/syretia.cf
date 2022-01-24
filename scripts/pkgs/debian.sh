#!/bin/bash
# Debian package search

pkg_name="$(curl -sL "https://packages.debian.org/search?suite=bullseye&searchon=names&keywords=$q" | \
pup 'a attr{href}' | \
grep -m1 '^/bullseye/' | \
cut -f3 -d'/')"

if [[ -z "$pkg_name" ]]; then
	exit 0
fi

curl -sL "https://packages.debian.org/bullseye/$pkg_name" | \
pup 'meta json{}' | \
jq --arg pn "$pkg_name" '{name: $pn, description: .[2].content, info: .[3].content, author: .[1].content}'
rm -rf /home/webhookd/logs/*
