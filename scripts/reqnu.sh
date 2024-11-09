#!/usr/bin/env nu

source /home/syretia/git/syretia.cf/scripts/.env.nu

def main [...body] {
    # get credentials
    # let hash = try { $env.x_authorization_hash } catch { |e| return $e.msg }
    let token = try { $env.x_authorization } catch { |e| return $e.msg }
    # check hash against token
    let hash_check = try { /usr/local/bin/bcrypt-tool match $"($token)" $"($hash)" | complete | get stdout | str replace -ra "\n" "" } catch { |e| return $e.msg }
    #check if match
    if $hash_check != "yes" {
        return "Hash does not match"
    }
    # get http request info
    let method = try { $env.hook_method } catch { |e| return $e.msg }
    let url = try { $env.url } catch { |e| return $e.msg }
    let headers = $env.x_headers? | default '["user-agent", "nushell"]'
    match $method {
        GET => { try { http get -fem 50 -H ($headers | from json) $url | to json -r } catch { |e| return $e.msg } }
        POST => { try { http post -fem 50 -H ($headers | from json) $url ($body | get 0) | to json -r } catch { |e| return $e.msg } }
        PATCH => { try { http patch -fem 50 -H ($headers | from json) $url ($body | get 0) | to json -r } catch { |e| return $e.msg } }
        PUT => { try { http put -fem 50 -H ($headers | from json) $url ($body | get 0) | to json -r } catch { |e| return $e.msg } }
        DELETE => { try { http delete -fem 50 -H ($headers | from json) $url | to json -r } catch { |e| return $e.msg } }
        HEAD => { try { http head -m 50 -H ($headers | from json) $url | to json -r } catch { |e| return $e.msg } }
    } | str replace -ra '7[0-9].[0-9][0-9]?[0-9]?.[0-9][0-9]?[0-9]?.[0-9][0-9]?[0-9]?' 'syretia.xyz'
}
