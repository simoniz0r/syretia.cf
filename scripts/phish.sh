#!/bin/bash

phisherman() {
    curl -sLA 'blargbot https://blargbot.xyz' "https://api.phisherman.gg/v1/domains/$domain" > /home/webhookd/out/.phisherman."$timens"
}

gsb() {
    curl -sL "https://transparencyreport.google.com/transparencyreport/api/v3/safebrowsing/status?site=$domain" | tail -n 1 > /home/webhookd/out/.gsb."$timens"
}

rm -rf /home/webhookd/logs/*

if [[ -z "$url" ]]; then
    jq -cn '.url|= null | .domain |= null | .redirect |= false | .phish |= false | .source |= null | .info |= null | .error |= "Missing url input"'
    exit 0
fi

if [[ "$url" == "http"* ]]; then
    export domain="$(echo "$url" | cut -f3 -d '/' | perl -pe 's%^www\.%%')"
else
    export domain="$(echo "$url" | cut -f1 -d '/' | perl -pe 's%^www\.%%')"
fi

redirect="$(jq -r --arg d "$domain" 'any(.shorteners[] == $d; .)' /home/webhookd/jsonlite/discord/domains)"

if [[ "$redirect" == "true" ]]; then
    domain="$(curl -sIX HEAD "$url" | grep -im1 '^location:' | cut -f3 -d'/')"
    if [[ -z "$domain" ]]; then
        jq -cn --arg u "$url" '.url |= $u | .domain |= null | .redirect |= true | .phish |= false | .source |= null | .info |= null | .error |= "Failed to follow redirect"'
        exit 0
    fi
fi

export timens="$(date +%s%N)"

if [[ "$info" == "true" ]]; then
    info="$(curl -sL "https://urlscan.io/api/verdict/$domain" | jq -c '.')"
else
    info="null"
fi

yachts="$(jq -r --arg d "$domain" 'any(.blacklist[] == $d; .)' /home/webhookd/jsonlite/discord/domains)"

if [[ "$yachts" == "true" ]]; then
    jq -cn --arg d "$domain" --argjson i "$info" --argjson r "$redirect" --arg u "$url" \
    '.url |= $u | .domain |= $d | .redirect |= $r | .phish |= true | .source |= "phish.sinking.yachts" | .info |= $i | .error |= null'
    exit 0
fi

phisherman &
gsb &

wait

phisherman="$(cat /home/webhookd/out/.phisherman."$timens")"
gsb="$(cat /home/webhookd/out/.gsb."$timens")"

rm -rf /home/webhookd/out/.phisherman."$timens"
rm -rf /home/webhookd/out/.gsb."$timens"

if [[ "$phisherman" == "true" ]]; then
    jq -cn --arg d "$domain" --argjson i "$info" --argjson r "$redirect" --arg u "$url" \
    '.url |= $u | .domain |= $d | .redirect |= $r | .phish |= true | .source |= "phisherman.gg" | .raw |= true | .info |= $i | .error |= null'
    exit 0
fi

if [[ "$(echo "$gsb" | jq '.[0][4]')" == "1" ]]; then
    jq -cn --arg d "$domain" --argjson i "$info" --argjson r "$redirect" --arg u "$url" \
    '.url |= $u | .domain |= $d | .redirect |= $r | .phish |= true | .source |= "Google Safe Browsing" | .info |= $i | .error |= null'
    exit 0
fi

jq -cn --arg d "$domain" --argjson r "$redirect" --arg u "$url" \
'.url |= $u | .domain |= $d | .redirect |= $r | .phish |= false | .source |= null | .info |= null | .error |= null'
