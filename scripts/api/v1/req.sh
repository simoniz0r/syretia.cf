#!/usr/bin/env nu
# Name: req
# Author: Syretia
# License: MIT
# Dependencies: nushell
# Description: gets headers and body that were set by blargbot's request and reroutes them to the given url

source /home/syretia/git/syretia.cf/.env.nu

def main [...body] {
    # get ip hash
    let ip_hash = try { $env.cf_connecting_ip | hash sha256 } catch { |e| return $e.msg }
    # check hash against stored hashes
    if $ip_hash == $blargbot {
        sleep 0sec
    } else if $ip_hash == $bakone {
        sleep 0sec
    } else if $ip_hash == $baktwo {
        sleep 0sec
    } else {
        return "Unauthorized use"
    }
    # get http request info
    let method = try { $env.hook_method } catch { |e| return $e.msg }
    let url = try { $env.url } catch { |e| return $e.msg }
    let headers = $env.x_headers? | default '["user-agent", "nushell"]'
    # run http command based on method and output result as json
    match $method {
        GET => { try { http get -fem 50 -H ($headers | from json) $url | to json -r } catch { |e| return $e.msg } }
        POST => { try { http post -fem 50 -H ($headers | from json) $url ($body | get 0) | to json -r } catch { |e| return $e.msg } }
        PATCH => { try { http patch -fem 50 -H ($headers | from json) $url ($body | get 0) | to json -r } catch { |e| return $e.msg } }
        PUT => { try { http put -fem 50 -H ($headers | from json) $url ($body | get 0) | to json -r } catch { |e| return $e.msg } }
        DELETE => { try { http delete -fem 50 -H ($headers | from json) $url | to json -r } catch { |e| return $e.msg } }
        HEAD => { try { http head -m 50 -H ($headers | from json) $url | to json -r } catch { |e| return $e.msg } }
    } | str replace -ra '7[0-9].[0-9][0-9][0-9].[0-9].[0-9][0-9]' 'syretia.xyz'
    # replace ip in all outputs
}
