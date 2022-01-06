#!/bin/bash

curl -sL 'https://en.wikipedia.org/wiki/Wikipedia:Today%27s_featured_article' 2>/dev/null | pup 'a:contains(Full) attr{href}' | grep -v '/wiki/2008_Orange_Bowl' | head -n 1
