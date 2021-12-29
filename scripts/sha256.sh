#!/bin/bash

rm -rf /home/webhookd/logs/*

echo -n "$q" | sha256sum | cut -f1 -d' ' | perl -pe 'chomp if eof'
