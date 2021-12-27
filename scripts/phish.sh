#!/bin/bash

if [[ -z "$domain" ]]; then
    jq -n '.phish |= false | .source |= null'
    exit 0
fi

phisherman="$(curl -sLA 'blargbot https://blargbot.xyz' "https://api.phisherman.gg/v1/domains/$domain")"
if [[ "$phisherman" == "true" ]]; then
    jq -n '.phish |= true | .source |= "phisherman.gg"'
    exit 0
fi

afdata="$(jq -n --arg d "$domain" '.message |= $d')"
antifish="$(curl -sLX POST -A 'blargbot (https://blargbot.xyz)' 'https://anti-fish.bitflow.dev/check' -d "$afdata")"
if [[ "$(echo "$antifish" | jq -r '.match')" == "true" ]]; then
    source="$(echo "$antifish" | jq -r '.matches[0].source')"
    jq -n --arg s "$source" '.phish |= true | .source |= $s'
    exit 0
fi

gsb="$(curl -sL "https://urlscan.io/api/verdict/$domain" | jq -r '.gsb.verdict.phishing?' 2>/dev/null)"
if [[ "$gsb" == "true" ]]; then
    jq -n '.phish |= true | .source |= "Google Safe Browsing"'
    exit 0
fi

jq -n '.phish |= false | .source |= null'
