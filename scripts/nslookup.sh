#!/bin/bash

if [[ -n "$domain" ]]; then
    nslookup "$domain" "$server"
fi
