#!/bin/bash

# convert key input to sha256sum
# key_hash="$(printf "%s\n" "$key" | sha256sum | cut -f1 -d' ')"
# unset key input so cannot be seen by running script
# unset key
# compare input key hash to stored key hash
# case "$key_hash" in
# 	"$WHD_AUTH_HASH")
# 		# successful authorization
# 	    sleep 0
# 	    ;;
# 	    *)
# 	    # failed authorization
# 	    echo '{"error":"Invalid authorization."}' | jq '.'
# 	    exit
# 	    ;;
# esac

pkg_name="$(curl -sL "https://packages.debian.org/search?suite=buster&searchon=names&keywords=$q" | pup 'a attr{href}' | grep -m1 '^/buster/' | cut -f3 -d'/')"
if [[ -z "$pkg_name" ]]; then
	exit 0
fi
curl -sL "https://packages.debian.org/buster/$pkg_name" | pup 'meta json{}' | jq --arg pn "$pkg_name" '{name: $pn, description: .[2].content, info: .[3].content, author: .[1].content}'
rm -rf /home/webhookd/logs/*
