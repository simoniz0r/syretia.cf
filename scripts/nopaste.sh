#!/bin/bash
# Name: nopaste
# Author: Syretia
# License: MIT
# Dependencies: base64, lzma
# Description: outputs links to nopaste

base64="$(printf "$@" | lzma | base64 -w0)"

printf "https://bokub.github.io/nopaste/?l=$l#$base64"
