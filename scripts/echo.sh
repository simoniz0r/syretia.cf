#!/bin/bash

rm -rf /home/webhookd/logs/*

echo "$@" > ~/out/echo
cat ~/out/echo
