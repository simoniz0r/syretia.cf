#!/bin/bash
# Name: opensuse
# Author: Syretia
# License: MIT
# Dependencies: curl, oq
# Description: openSUSE package search

# remove logs
# rm -rf /home/webhookd/logs/*

# set query to q if present
if [[ -n "$q" ]]; then
    query="$q"
fi

# try searching for exact match first
res="$(curl --max-time 25 -sL "https://opi-proxy.opensuse.org/?obs_api_link=https%3A%2F%2Fapi.opensuse.org%2Fsearch%2Fpublished%2Fbinary%2Fid%3Fmatch%3D%2540name%253D%2527$query%2527%26limit%3D0&obs_instance=openSUSE" | \
oq -i xml -o json '[.collection.binary[] | select(."@baseproject" == "openSUSE:Factory") | select(."@arch" | test("(x86_64|noarch)"))]' 2>/dev/null)"

# try fuzzy search if no exact match
if [[ "$res" == "" ]]; then
    res="$(curl --max-time 25 -sL "https://opi-proxy.opensuse.org/?obs_api_link=https%3A%2F%2Fapi.opensuse.org%2Fsearch%2Fpublished%2Fbinary%2Fid%3Fmatch%3Dcontains-ic%2528%2540name%252C%2B%2527$query%2527%2529%2B%26limit%3D0&obs_instance=openSUSE" | \
    oq -i xml -o json '[.collection.binary[] | select(."@baseproject" == "openSUSE:Factory") | select(."@arch" | test("(x86_64|noarch)"))]' 2>/dev/null)"
fi

# set values to null and exit if no results
if [[ "$res" == "" ]]; then
    oq -n '."@name" |= null |
    ."@project" |= null |
    ."@package" |= null |
    ."@repository" |= null |
    ."@version" |= null |
    ."@release" |= null |
    ."@arch" |= null |
    ."@filename" |= null |
    ."@filepath" |= null |
    ."@baseproject" |= null |
    ."@type" |= null'
    exit 0
fi

# if results contain build for Factory, output that, otherwise output first result
if [[ "$(echo "$res" | oq '[.[] | select(."@project" == "openSUSE:Factory")] | .[0]')" != "null" ]]; then
    echo "$res" | oq '[.[] | select(."@project" == "openSUSE:Factory")] | .[0]'
else
    echo "$res" | oq '.[0]'
fi
