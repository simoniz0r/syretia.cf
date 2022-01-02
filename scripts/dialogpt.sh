#!/bin/bash

if [[ -z "$model" ]]; then
    model="facebook/blenderbot-400M-distill"
fi

curl -sL "https://api-inference.huggingface.co/models/$model" -H "Authorization: Bearer $token" -H 'content-type: application/json' --data-raw "$@"
