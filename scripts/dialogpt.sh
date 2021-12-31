#!/bin/bash

curl -sL 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-large' -H "Authorization: Bearer $token" -H 'content-type: application/json' --data-raw "$@"
