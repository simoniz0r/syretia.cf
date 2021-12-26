#!/bin/bash

if [[ -z "$key" || -z "$hash" || -z "$action" ]]; then
    jq -n '.error |= "Missing required info"'
    exit 0
fi

case "$action" in
    info) curl -sL 'https://nerdvm.racknerd.com/api/client/command.php' -d "key=$key" -d "hash=$hash" -d "action=$action" -d 'bw=true' -d "hdd=true" | pup 'body json{}';;
    *) curl -sL 'https://nerdvm.racknerd.com/api/client/command.php' -d "key=$key" -d "hash=$hash" -d "action=$action" | pup 'body json{}';;
esac
