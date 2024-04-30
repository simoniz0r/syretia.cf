#!/bin/bash
# Name: imgix
# Author: Syretia
# License: MIT
# Dependencies: curl, jq
# Description: saves an image in the directory that is visible to imgix

rm -rf /home/webhookd/logs/*

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
       	jq -nc '.error |= "Invalid authorization."'
       	exit
       	;;
esac

url="$(echo "$@" | jq -r '.url?' 2>/dev/null)"
name="$(echo "$@" | jq -r '.name?' 2>/dev/null)"
rand="$(echo "$@" | jq -r '.rand?' 2>/dev/null)"
temp="$(echo "$@" | jq -r '.temp?' 2>/dev/null)"

if [[ "$rand" != "false" ]]; then
	if [[ "$name" == "."* || "$name" == "" ]]; then
		name="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w6 | head -n1)$name"
	else
		name="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w6 | head -n1)_$name"
	fi
fi

if [[ -n "$url" ]]; then
	curl -sL --max-time 3 --show-error "$url" -o /home/webhookd/imgix/"$name" 2>&1 || exit 0
fi

if [[ "$temp" != "false" ]]; then
	curl -sL "https://sy.imgix.net/$name" &>/dev/null
	rm /home/webhookd/imgix/"$name"
fi

echo -n "https://sy.imgix.net/$name"

ls /home/webhookd/imgix | grep -v 'index.html' | perl -pe 's%(^.*$)%<a href="https://sy.imgix.net/$1">$1</a><br>%g' > /home/webhookd/imgix/index.html
