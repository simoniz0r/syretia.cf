#!/bin/bash

# only allow blargbot
ip_hash="$(echo -n "$cf_connecting_ip" | sha256sum | cut -f1 -d' ')"

if [[ "$ip_hash" != "48bf3717248c376717c77b41e279aba6a32edcc3e9c8ca1a6ac36bc8dbb8fd66" ]]; then
  exit 250
fi

# if no POST data, sync local database to https://phish.sinking.yachts/v2/all
if [[ -z "$@" ]]; then
  if [[ -z "$dt" ]]; then
    dt="3600"
  fi
  # get list of phishing domains added in the last $dt seconds from phish.sinking.yachts and output to /home/webhookd/out/.yachts
  curl -sL "https://phish.sinking.yachts/v2/recent/$dt" -H 'X-Identity: Syretia (https://syretia.cf/docs)' | \
  jq -c '[.[].domains[]]' 2>/dev/null > /home/webhookd/out/.yachts
  # check if file exists and is valid JSON
  if [[ -f "/home/webhookd/out/.yachts" && "$(jq 'length' /home/webhookd/out/.yachts 2>/dev/null || echo -n '0')" != "0" ]]; then
    # combine /home/webhookd/out/.yachts and /home/webhookd/jsonlite/domains/blacklist
    # then sort, filter out duplicates, and filter out entries that start with 'www.'
    cat /home/webhookd/out/.yachts | jq --argfile bl /home/webhookd/jsonlite/domains/blacklist \
    '[. + $bl | sort | unique | .[] | select(. | test("^www\\.") | not)]' > /home/webhookd/jsonlite/domains/.blacklist
    mv /home/webhookd/jsonlite/domains/.blacklist /home/webhookd/jsonlite/domains/blacklist
    # output status
    jq -cn --arg l "$(jq -r 'length' /home/webhookd/jsonlite/domains/blacklist)" '.status |= "Phishing domain blacklist updated." | .length |= $l'
  elif [[ ! -f "/home/webhookd/out/.yachts" ]]; then
    # output error
    jq -cn '.error |= "Failed to fetch https://phish.sinking.yachts/v2/all"'
  else
    jq -cn --arg l "$(jq 'length' /home/webhookd/out/.yachts 2>/dev/null)" '.status |= "No new phishing domains found." | .length |= $l'
  fi
  # remove /home/webhookd/out/.yachts
  rm -rf /home/webhookd/out/.yachts
# else add POST data to blacklist array
else
  # check authorization
  # convert key input to sha256sum
  key_hash="$(printf "%s\n" "$key" | sha256sum | cut -f1 -d' ')"
  # unset key input so cannot be seen by running script
  unset key
  # compare input key hash to stored key hash
  case "$key_hash" in
      "$WHD_AUTH_HASH")
          # successful authorization
          sleep 0
          ;;
      *)
          # failed authorization
          jq -nc '.error |= "Invalid authorization."'
          exit 0
          ;;
  esac
  # check if POST data is valid JSON array
  if [[ "$(echo "$@" | jq '.[0]' 2>/dev/null)" == "" ]]; then
    jq -cn '.error |= "Input is not a valid JSON array"'
    exit 0
  fi
  # add POST data to blacklist array
  cat /home/webhookd/jsonlite/domains/blacklist | jq --argjson ar "$@" '. += $ar | sort | unique' > /home/webhookd/jsonlite/domains/.blacklist
  mv /home/webhookd/jsonlite/domains/.blacklist /home/webhookd/jsonlite/domains/blacklist
fi
