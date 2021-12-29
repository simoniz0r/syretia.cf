#!/bin/bash

rm -rf /home/webhookd/logs/*

emoj="$(echo "$@" | jq -r '.text' | emojify)"
echo "$@" | jq --arg emj "$emoj" '.emojified |= $emj' 
