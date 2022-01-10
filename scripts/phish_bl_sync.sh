#!/bin/bash

if [[ "$cf_connecting_ip" != "167.114.1.162" ]]; then
  exit 250
fi

/home/syretia/curl -sLw '%{json}' 'https://discord-fde27-default-rtdb.firebaseio.com/discord/domains/blacklist.json' -o /home/webhookd/jsonlite/domains/blacklist | jq '.local_ip |= null'
