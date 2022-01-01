#!/bin/bash

antifish() {
    curl -sLX POST -H 'Content-Type: application/json' -A 'blargbot (https://blargbot.xyz)' 'https://anti-fish.bitflow.dev/check' -d "$afdata" > /home/webhookd/out/.antifish."$timens"
}

phisherman() {
    curl -sLA 'blargbot https://blargbot.xyz' "https://api.phisherman.gg/v1/domains/$domain" > /home/webhookd/out/.phisherman."$timens"
}

gsb() {
    curl -sL "https://transparencyreport.google.com/transparencyreport/api/v3/safebrowsing/status?site=$domain" | tail -n 1 > /home/webhookd/out/.gsb."$timens"
}

rm -rf /home/webhookd/logs/*

if [[ -z "$domain" ]]; then
    jq -cn '.domain |= null | .phish |= false | .source |= null'
    exit 0
fi

export timens="$(date +%s%N)"
export afdata="$(jq -n --arg d "$domain" '.message |= $d')"

antifish &
phisherman &
gsb &

wait

antifish="$(cat /home/webhookd/out/.antifish."$timens")"
phisherman="$(cat /home/webhookd/out/.phisherman."$timens")"
gsb="$(cat /home/webhookd/out/.gsb."$timens")"

rm -rf /home/webhookd/out/.antifish."$timens"
rm -rf /home/webhookd/out/.phisherman."$timens"
rm -rf /home/webhookd/out/.gsb."$timens"

if [[ "$(echo "$antifish" | jq -r '.match')" == "true" ]]; then
    source="anti-fish.bitflow.dev ($(echo "$antifish" | jq -r '.matches[0].source'))"
    jq -cn --arg d "$domain" --arg s "$source" --argjson r "$antifish" '.domain |= $d | .phish |= true | .source |= $s | .raw |= $r'
    exit 0
fi

if [[ "$phisherman" == "true" ]]; then
    jq -cn --arg d "$domain" '.domain |= $d | .phish |= true | .source |= "phisherman.gg" | .raw |= true'
    exit 0
fi

if [[ "$(echo "$gsb" | jq '.[0][4]')" == "1" ]]; then
    jq -cn --arg d "$domain" --argjson r "$gsb" '.domain |= $d | .phish |= true | .source |= "Google Safe Browsing" | .raw |= $r'
    exit 0
fi

jq -cn --arg d "$domain" '.domain |= $d | .phish |= false | .source |= null'
