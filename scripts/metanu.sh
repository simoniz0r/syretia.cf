#!/usr/bin/env nu
# Name: metanu
# Author: Syretia
# License: MIT
# Dependencies: nushell, nushell query plugin
# Description: output metadata for a given url in JSON format

# use query plugin for webpage-info
plugin use query

# http get url, query webpage-info for metadata, output as json
try { http get -m 10 $env.u | query webpage-info | to json -r } catch { |e| $e.msg }
