#!/bin/bash

rm -rf /home/webhookd/logs/*

checkkey() {
	# convert key input to sha256sum
	key_hash="$(printf "%s\n" "$key" | sha256sum | cut -f1 -d' ')"
	# unset key input so cannot be seen by running script
	unset key
	unset WHD_DISCORD_TOKEN
	# compare input key hash to stored key hash
	case "$key_hash" in
    	"$WHD_AUTH_HASH")
        	# successful authorization
        	sleep 0
        	;;
    	*)
        	# failed authorization
        	echo '{"error":"Invalid authorization."}' | jq '.'
        	exit
        	;;
	esac
}

export JSONLITE_DATA_DIR="/home/webhookd/jsonlite"

if [[ -n "$id" ]]; then
	export document_id="$id"
fi

if [[ -n "$@" ]]; then
	jdata="$(echo "$@" | jq -cr '.data?')"
fi

case "$op" in
	set|delete) checkkey; jsonlite "$op" "$bin" "$id" "$jdata";;
	get|count|list) jsonlite "$op" "$bin" "$id";;
	*) jsonlite help;;
esac
