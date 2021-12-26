#!/bin/bash

if [[ -n "$alg" && -n "$str" ]]; then
    echo -n "$str" | ${alg}sum | cut -f1 -d' '
else
	alg="$(echo "$@" | jq -r '.alg')"
	str="$(echo "$@" | jq -r '.str')"
	jq -n --arg al "$alg" --arg hash "$(echo -n "$str" | ${alg}sum | cut -f1 -d' ')" '.alg |= $al | .hash |= $hash'
fi
