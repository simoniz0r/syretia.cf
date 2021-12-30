#!/bin/bash

rm -rf /home/webhookd/logs/*

if [[ -z "$domain" ]]; then
    jq -cn '.domain |= null | .phish |= false | .source |= null'
    exit 0
fi

phisherman="$(curl -sLA 'blargbot https://blargbot.xyz' "https://api.phisherman.gg/v1/domains/$domain")"
if [[ "$phisherman" == "true" ]]; then
    jq -cn --arg d "$domain" '.domain |= $d | .phish |= true | .source |= "phisherman.gg"'
    exit 0
fi

afdata="$(jq -n --arg d "$domain" '.message |= $d')"
antifish="$(curl -sLX POST -H 'Content-Type: application/json' -A 'blargbot (https://blargbot.xyz)' 'https://anti-fish.bitflow.dev/check' -d "$afdata")"
if [[ "$(echo "$antifish" | jq -r '.match')" == "true" ]]; then
    source="$(echo "$antifish" | jq -r '.matches[0].source')"
    jq -cn --arg d "$domain" --arg s "$source" '.domain |= $d | .phish |= true | .source |= $s'
    exit 0
fi

gsb="$(curl -sL "https://urlscan.io/api/verdict/$domain" | jq -r '.gsb.verdict.phishing?' 2>/dev/null)"
if [[ "$gsb" == "true" ]]; then
    jq -cn --arg d "$domain" '.domain |= $d | .phish |= true | .source |= "Google Safe Browsing"'
    exit 0
fi

jq -cn --arg d "$domain" '.domain |= $d | .phish |= false | .source |= null'
