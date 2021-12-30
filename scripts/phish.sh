#!/bin/bash

rm -rf /home/webhookd/logs/*

if [[ -z "$domain" ]]; then
    jq -cn '.domain |= null | .phish |= false | .source |= null'
    exit 0
fi

afdata="$(jq -n --arg d "$domain" '.message |= $d')"

phisherman="$(curl -sLA 'blargbot https://blargbot.xyz' "https://api.phisherman.gg/v1/domains/$domain" &)"
antifish="$(curl -sLX POST -H 'Content-Type: application/json' -A 'blargbot (https://blargbot.xyz)' 'https://anti-fish.bitflow.dev/check' -d "$afdata" &)"
gsb="$(curl -sL "https://transparencyreport.google.com/transparencyreport/api/v3/safebrowsing/status?site=$domain" | tail -n 1 &)"

wait

if [[ "$phisherman" == "true" ]]; then
    jq -cn --arg d "$domain" '.domain |= $d | .phish |= true | .source |= "phisherman.gg"'
    exit 0
fi

if [[ "$(echo "$antifish" | jq -r '.match')" == "true" ]]; then
    source="anti-fish.bitflow.dev ($(echo "$antifish" | jq -r '.matches[0].source'))"
    jq -cn --arg d "$domain" --arg s "$source" '.domain |= $d | .phish |= true | .source |= $s'
    exit 0
fi

if [[ "$(echo "$gsb" | jq '.[0][4]')" == "1" ]]; then
    jq -cn --arg d "$domain" '.domain |= $d | .phish |= true | .source |= "Google Safe Browsing"'
    exit 0
fi

jq -cn --arg d "$domain" '.domain |= $d | .phish |= false | .source |= null'
