#!/bin/bash
# Name: req
# Author: Syretia
# License: MIT
# Dependencies: curl,  dasel, jq
# Description: gets headers and body that were set by blargbot's request and reroutes them to the given url

# rm -rf /home/webhookd/logs/*

# only work with blargbot's IP
ip_hash="$(echo -n "$cf_connecting_ip" | sha256sum | cut -f1 -d' ')"
if [[ "$ip_hash" != "48bf3717248c376717c77b41e279aba6a32edcc3e9c8ca1a6ac36bc8dbb8fd66" && "$ip_hash" != "83bdcd6058addb51543a5fcd5008f342bc7b09921a3be27af5569eeac936db10" && "$ip_hash" != "8829af3e4b753df9402a72a2ae1d88fc11fd7b96129c6ee58de9b984d57ba6f9" ]]; then
	echo '' | jq -n '.error += "Not authorized"'
	exit 0
fi
# get request headers from environment variables and tranform them into a format that curl can handle
HEADERS="$(env | grep -E '^[a-z][a-z]+|^[a-z]_' | perl -pe 's%^(cdn_|cf_|x_forwarded_|hook_|connection=|content_length=|url=|accept_encoding=gzip).*%%g' | \
sed '/^$/d' | perl -pe 'chomp if eof' | \
sed -e ':b; s/^\([^=]*\)*_/\1-/; tb;' | perl -pe "s%=%: %")"
# if raw is true, do not output in json format (useful if body is more than 50k chars)
if [[ "$raw" == "true" ]]; then
  if [[ -n "$@" ]]; then
    curl -sL"$f"X "$x" "$url"  --max-time 50 --data-binary "$@" -H @<(echo "$HEADERS") 2>/dev/null || true
  else
    curl -sL"$f"X "$x" "$url"  --max-time 50 -H @<(echo "$HEADERS") 2>/dev/null || true
  fi
  exit 0
fi
# make request with body from request if present and reverse using tac for easier parsing
if [[ -n "$@" ]]; then
  REQ="$(curl -w '\n# CURL JSON\n%{json}\n' -sLi"$f"X "$x" "$url"  --max-time 50 --data-binary "$@" -H @<(echo "$HEADERS") 2>/dev/null | tac || true)"
else
  REQ="$(curl -w '\n# CURL JSON\n%{json}\n' -sLi"$f"X "$x" "$url"  --max-time 50 -H @<(echo "$HEADERS") 2>/dev/null | tac || true)"
fi
# get json from first line of curl's output and use jq to delete irrelevent keys
json="$(echo "$REQ" | head -n 1 | \
jq 'del(.certs, .curl_version, .filename_effective, .ftp_entry_path, .http_connect, .http_version, .local_ip, .local_port, .num_connects, .proxy_ssl_verify_result, .response_code, .ssl_verify_result, .time_appconnect, .time_connect, .time_namelookup, .time_pretransfer, .time_redirect, .time_starttransfer, .urlnum)')"
# get status and add it to json
json="$(echo "$json" | jq '.status += .http_code | del(.http_code)')"
# get headers by removing body and json from REQ
headers="$(echo "$REQ" | awk '/^\r$/,/^$/' | tac | jq -Rs 'split("\r\n") | .[0:-2]')"
# get body by removing headers and json from REQ
body="$(echo "$REQ" | awk '/^# CURL JSON/,/^\r$/' | tac | head -n -1 | tail -n +2)"
# truncate body and set errormsg if 50k chars or more
# if [[ "$(echo "$body" | wc -c)" -ge "50000" ]]; then
#	json="$(echo "$json" | jq '.errormsg += "Body exceeded max length. Dumped to file. See body for URL."')"
#	timehash="$(date +%s | md5sum | cut -f1 -d' ')"
#	echo "$body" > /home/webhookd/out/"$timehash"
#	body="https://out.syretia.xyz/$timehash"
	# systemd-run --user --on-active=600 "rm /home/webhookd/out/$timehash"
# fi
# add headers to json
json="$(echo "$json" | dasel put -r json -s '.headers' -t json -v "$headers")"
# json="$(echo "$json" | jq --arg h "$headers" '.headers += $h')"
# output results using dasel to put the body into curl's json
echo "$json" | jq -S --arg b "$body" '.body += $b'
