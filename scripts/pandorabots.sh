#!/bin/bash

botid="$(jq -r '.botid' <<<"$@")"
botcust="$(jq -r '.botcust?' <<<"$@")"
if [[ "$botcust" == "null" ]]; then
    botcust=""
fi
message_raw="$(jq -r '.message' <<<"$@")"
message="$(jq -r '.message | @uri | gsub("%20";"+")' <<<"$@")"

if [[ -z "$botid" || -z "$message" ]]; then
    jq -cn '.error |= "Missing required data botid or message"'
    exit 0
fi

curl_resp="$(curl -sL "https://pandorabots.com/pandora/talk?botid=$botid" -d "message=$message&botcust2=$botcust" 2>/dev/null || true)"
botcust="$(pup 'input[name="botcust2"] attr{value}' <<<"$curl_resp")"
response="$(pup 'text{}' <<<"$curl_resp" | grep -i '^ [a-z0-9]' | jq -Rsr 'split("\n") | .[1]' | cut -f2- -d' ')"

jq -cn --arg msg "$message_raw" --arg cust "$botcust" --arg resp "$response" '.botcust |= $cust | .message |= $msg | .response |= $resp'
