#!/bin/bash

SEARCH_QUERY="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$q")"
SEARCH_RESULTS="$(curl -sL "https://www.w3.org/services/html2txt?url=https%3A%2F%2Fgoogle.com%2Fsearch%3Fq%3D${SEARCH_QUERY}&noinlinerefs=on&nonums=on&endrefs=on" -A "$RANDOM" | \
grep -Po 'https:\/\/www\.google\.com\/url\?q=\K.*' | \
perl -pe 's%&sa=.&ved=.*%%g' | \
head -n -2 | \
perl -pe 'chomp if eof' | \
jq -c --raw-input --slurp 'split("\n")')"
TOP_RESULT="$(printf "%s\n" "$SEARCH_RESULTS" | jq -r '.[0]')"
SEARCH_META="$(curl -sL "$TOP_RESULT" | pup 'meta json{}')"
curl -sL "http://api.linkpreview.net/?key=86a22451d042b92ea493ae9a063448af&q=$TOP_RESULT" | jq ".meta |= $SEARCH_META" | jq ".results |= $SEARCH_RESULTS"
# META_LENGTH="$(printf "%s\n" "$SEARCH_META" | jq length)"
# META_LENGTH2="$((META_LENGTH+1))"
# printf "%s\n" "$SEARCH_META" | jq ".[$(echo $META_LENGTH)] |= {\"url\":\"$TOP_RESULT\"}" | jq ".[$(echo $META_LENGTH2)] |= {\"results\":$SEARCH_RESULTS}"
rm -rf /home/webhookd/logs/*
