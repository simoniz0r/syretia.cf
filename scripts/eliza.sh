#!/bin/bash

chat="$(eliza "$@")"
message="$(echo "$chat" | head -n 1 | cut -f2- -d' ')"
response="$(echo "$chat" | tail -n 1 | cut -f2- -d' ')"
jq -cn --arg msg "$message" --arg resp "$response" '.message |= $msg | .response |= $resp' 
