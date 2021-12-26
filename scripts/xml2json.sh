#!/bin/bash

curl -sLA "$RANDOM$RANDOM" "$url" | oq -i xml -o json
