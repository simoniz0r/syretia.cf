#!/usr/bin/env nu

# plugin add ./nu_plugin_query
plugin use query

try { http get -m 10 $env.u | query webpage-info | to json -r } catch { |e| $e.msg }
