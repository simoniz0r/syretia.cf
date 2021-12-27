#!/bin/bash

if [[ -z "$domain" ]]; then
    jq -cn '.phish |= false | .source |= null'
    exit 0
fi

phisherman="$(curl -sLA 'blargbot https://blargbot.xyz' "https://api.phisherman.gg/v1/domains/$domain")"
if [[ "$phisherman" == "true" ]]; then
    jq -cn '.phish |= true | .source |= "phisherman.gg"'
    exit 0
fi

afdata="$(jq -n --arg d "$domain" '.message |= $d')"
antifish="$(curl -sLX POST -H 'Content-Type: application/json' -A 'blargbot (https://blargbot.xyz)' 'https://anti-fish.bitflow.dev/check' -d "$afdata")"
if [[ "$(echo "$antifish" | jq -r '.match')" == "true" ]]; then
    source="$(echo "$antifish" | jq -r '.matches[0].source')"
    jq -cn --arg s "$source" '.phish |= true | .source |= $s'
    exit 0
fi

gsb="$(curl -sL "https://urlscan.io/api/verdict/$domain" | jq -r '.gsb.verdict.phishing?' 2>/dev/null)"
if [[ "$gsb" == "true" ]]; then
    jq -cn '.phish |= true | .source |= "Google Safe Browsing"'
    exit 0
fi

jq -cn '.phish |= false | .source |= null'
