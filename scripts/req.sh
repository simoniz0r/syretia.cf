#!/bin/bash
# intended to work with the 'req' tag with blargbot
# gets headers and body that were set by blargbot's request and reroutes them to the given url
# requires curl (version 7.80.0 or greater) and dasel

# only work with blargbot's IP
ip_hash="$(echo -n "$cf_connecting_ip" | sha256sum | cut -f1 -d' ')"
if [[ "$ip_hash" != "48bf3717248c376717c77b41e279aba6a32edcc3e9c8ca1a6ac36bc8dbb8fd66" && "$ip_hash" != "83bdcd6058addb51543a5fcd5008f342bc7b09921a3be27af5569eeac936db10" ]]; then
	echo '' | dasel put string -p json '.error' 'Not authorized'
	exit 0
fi
# get request headers from environment variables and tranform them into a format that curl can handle
HEADERS="$(env | grep -E '^[a-z][a-z]+|^[a-z]_' | perl -pe 's%^(cdn_|cf_|x_forwarded_|hook_|connection=|content_length=|url=|accept_encoding=gzip).*%%g' | \
sed '/^$/d' | perl -pe 'chomp if eof' | \
sed -e ':b; s/^\([^=]*\)*_/\1-/; tb;' | perl -pe "s%=%: %g")"
# if raw is true, do not output in json format (useful if body is more than 50k chars)
if [[ "$raw" == "true" ]]; then
  if [[ -n "$@" ]]; then
    curl -sL"$f"X "$x" "$url"  --max-time 5 --data-binary "$@" -H @<(echo "$HEADERS") 2>/dev/null || true
  else
    curl -sL"$f"X "$x" "$url"  --max-time 5 -H @<(echo "$HEADERS") 2>/dev/null || true
  fi
  exit 0
fi
# make request with body from request if present and reverse using tac for easier parsing
if [[ -n "$@" ]]; then
  REQ="$(/home/syretia/curl -w '\n# CURL JSON\n%{json}\n' -sLi"$f"X "$x" "$url"  --max-time 5 --data-binary "$@" -H @<(echo "$HEADERS") 2>/dev/null | tac || true)"
else
  REQ="$(/home/syretia/curl -w '\n# CURL JSON\n%{json}\n' -sLi"$f"X "$x" "$url"  --max-time 5 -H @<(echo "$HEADERS") 2>/dev/null | tac || true)"
fi
# get json from first line of curl's output and use dasel to delete irrelevent keys
json="$(echo "$REQ" | head -n 1 | \
dasel delete -p json '.curl_version' | \
dasel delete -p json '.filename_effective' | \
dasel delete -p json '.ftp_entry_path' | \
dasel delete -p json '.http_connect' | \
dasel delete -p json '.http_version' | \
dasel delete -p json '.local_ip' | \
dasel delete -p json '.local_port' | \
dasel delete -p json '.num_connects' | \
dasel delete -p json '.proxy_ssl_verify_result' | \
dasel delete -p json '.response_code' | \
dasel delete -p json '.ssl_verify_result' | \
dasel delete -p json '.time_appconnect' | \
dasel delete -p json '.time_connect' | \
dasel delete -p json '.time_namelookup' | \
dasel delete -p json '.time_pretransfer' | \
dasel delete -p json '.time_redirect' | \
dasel delete -p json '.time_starttransfer' | \
dasel delete -p json '.urlnum')"
# get status and add it to json
status="$(echo "$json" | dasel select -p json '.http_code')"
json="$(echo "$json" | dasel put int -p json '.status' "$status" | dasel delete -p json '.http_code')"
# get headers by removing body and json from REQ
headers="$(echo "$REQ" | awk '/^\r$/,/^$/' | tac | jq -Rs 'split("\r\n") | .[0:-2]')"
# get body by removing headers and json from REQ
body="$(echo "$REQ" | awk '/^# CURL JSON/,/^\r$/' | tac | head -n -1 | tail -n +2)"
# truncate body and set errormsg if 50k chars or more
if [[ "$(echo "$body" | wc -c)" -ge "50000" ]]; then
	json="$(echo "$json" | dasel put string -p json '.errormsg' 'body exceeded max length. truncated to first 50,000 characters.')"
	body="$(echo "$body" | head -c50000)"
fi
# add headers to json
json="$(echo "$json" | dasel put document -p json '.headers' "$headers")"
# output results using dasel to put the body into curl's json
echo "$json" | dasel put document -p json -s '.body' -v "$body" 2>/dev/null || \
echo "$json" | dasel put string -p json -s '.body' -v "$body"
