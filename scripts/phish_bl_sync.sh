#!/bin/bash

# only allow blargbot
if [[ "$cf_connecting_ip" != "167.114.1.162" ]]; then
  exit 250
fi
# get list of phishing domains from phish.sinking.yachts and output to /home/webhookd/out/.yachts
curl -sL 'https://phish.sinking.yachts/v2/all' -H 'X-Identity: Syretia (https://syretia.cf/docs)' -o /home/webhookd/out/.yachts
# check if file exists and is valid JSON
if [[ -f "/home/webhookd/out/.yachts" ]] && jq '.' /home/webhookd/out/.yachts &>/dev/null; then
        # combine /home/webhookd/out/.yachts and /home/webhookd/jsonlite/domains/blacklist
        # then sort, filter out duplicates, and filter out entries that start with 'www.'
        cat /home/webhookd/out/.yachts | jq -c --argfile bl /home/webhookd/jsonlite/domains/blacklist \
        '[. + $bl | sort | unique | .[] | select(. | test("^www\\.") | not)]' > /home/webhookd/jsonlite/domains/blacklist
        # output status
        jq -cn --arg l "$(jq -r 'length' /home/webhookd/jsonlite/domains/blacklist)" '.status |= "Phishing domain blacklist updated." | .length |= $l'
else
        # output error
        jq -cn '.error |= "Error fetching https://phish.sinking.yachts/v2/all"'
fi
# remove /home/webhookd/out/.yachts
rm -rf /home/webhookd/out/.yachts

