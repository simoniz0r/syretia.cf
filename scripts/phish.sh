#!/bin/bash

phisherman() {
    curl -sLA 'blargbot https://blargbot.xyz' "https://api.phisherman.gg/v1/domains/$domain" > /home/webhookd/out/.phisherman."$timens"
}

gsb() {
    curl -sL "https://transparencyreport.google.com/transparencyreport/api/v3/safebrowsing/status?site=$domain" | tail -n 1 > /home/webhookd/out/.gsb."$timens"
}

rm -rf /home/webhookd/logs/*

if [[ -z "$url" ]]; then
    jq -cn '.domain |= null | .error |= "Missing url input" | .info |= null | .phish |= false | .redirect |= false | .source |= null | .url |= null'
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
        jq -cn --arg u "$url" \
        '.domain |= null | .error |= "Failed to follow redirect" | .info |= null | .phish |= false | .redirect |= true | .source |= null | .url |= $u'
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
    '.domain |= $d | .error |= null | .info |= $i | .phish |= true | .redirect |= $r | .source |= "phish.sinking.yachts" | .url |= $u'
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
    '.domain |= $d | .error |= null | .info |= $i | .phish |= true | .redirect |= $r | .source |= "phisherman.gg" | .url |= $u'
    exit 0
fi

if [[ "$(echo "$gsb" | jq '.[0][4]')" == "1" ]]; then
    jq -cn --arg d "$domain" --argjson i "$info" --argjson r "$redirect" --arg u "$url" \
    '.domain |= $d | .error |= null | .info |= $i | .phish |= true | .redirect |= $r | .source |= "Google Safe Browsing" | .url |= $u'
    exit 0
fi

jq -cn --arg d "$domain" --argjson r "$redirect" --arg u "$url" \
'.domain |= $d | .error |= null | .info |= null | .phish |= false | .redirect |= $r | .source |= null | .url |= $u'
