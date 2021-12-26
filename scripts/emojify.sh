#!/bin/bash

emoj="$(echo "$@" | jq -r '.text' | emojify)"
echo "$@" | jq --arg emj "$emoj" '.emojified |= $emj' 
