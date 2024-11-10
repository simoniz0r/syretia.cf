#!/bin/bash
# Name: imgix
# Author: Syretia
# License: MIT
# Dependencies: curl, jq
# Description: saves an image in the directory that is visible to imgix

# remove logs
# rm -rf /home/webhookd/logs/*

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

# get variables from JSON body
data="$(echo "$@" | jq -r '.data?' 2>/dev/null)"
url="$(echo "$@" | jq -r '.url?' 2>/dev/null)"
name="$(echo "$@" | jq -r '.name?' 2>/dev/null)"
rand="$(echo "$@" | jq -r '.rand?' 2>/dev/null)"
temp="$(echo "$@" | jq -r '.temp?' 2>/dev/null)"

# exit if no data or url
if [[ "$data" == "null" && "$url" == "null" ]]; then
	jq -nc '.error |= "Missing 'url' or 'data' value."'
	exit 0
fi

# get file type
if [[ "$data" != "null" ]]; then
	filetype="$(echo -n "$data" | base64 -d - | file --mime-type - | cut -f2 -d' ')"
elif [[ "$url" != "null" ]]; then
	filetype="$(curl -sL --max-time 25 "$url" | file --mime-type - | cut -f2 -d' ')"
fi

# exit if file type is not image
type="$(echo "$filetype" | cut -f1 -d'/')"
if [[ "$type" != "image" ]]; then
	jq -nc '.error |= "Invalid file type."'
	exit 0
fi

# set name to file type if not present
if [[ "$name" == "null" ]]; then
	rand="true"
	name="$(echo "$filetype" | tr '/' '.')"
fi

# if rand is not false, randomize name
if [[ "$rand" != "false" ]]; then
	name="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w6 | head -n1)_$name"
fi

# write image to imgix dir
if [[ "$data" != "null" ]]; then
	echo -n "$data" | base64 -d - > /home/webhookd/imgix/"$name" || \
	{ jq -nc '.error |= "Failed to write file."'; exit 0; }
elif [[ "$url" != "null" ]]; then
	curl -sL --max-time 25 "$url" -o /home/webhookd/imgix/"$name" 2>/dev/null || \
	{ jq -nc '.error |= "Failed to write file."'; exit 0; }
fi

# if temp is not false, cache image with HTTP request and then delete it
if [[ "$temp" != "false" ]]; then
	curl -sL "https://sy.imgix.net/$name" &>/dev/null
	rm /home/webhookd/imgix/"$name"
fi

# output url to image
echo -n "https://sy.imgix.net/$name"

# create index of stored images
ls /home/webhookd/imgix | grep -v 'index.html' | perl -pe 's%(^.*$)%<a href="https://sy.imgix.net/$1">$1</a><br>%g' > /home/webhookd/imgix/index.html
