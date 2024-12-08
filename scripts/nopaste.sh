#!/usr/bin/env nu
# Name: nopaste
# Author: Syretia
# License: MIT
# Dependencies: nushell, base64, lzma
# Description: outputs links to nopaste or converts back to original content

def main [...body] {
    # check if url contains encoded paste
    let in_paste = $env.p? | default ""
    if $in_paste != "" {
        # try to base64 decode input
        let decoded = try {
            $in_paste | base64 -dw0 | complete
        } catch {
            |e| return ("Failed to decode paste" | wrap error | to json -r)
        }
        # return if exit not 0
        if ($decoded | get exit_code) != 0 { return ($decoded | wrap error | to json -r) }
        # try to decompress decoded input
        let decompressed = try {
            $decoded | get stdout | lzma -d | complete
        } catch {
            |e| return ("Failed to decompress paste" | wrap error | to json -r)
        }
        # return if exit not 0
        if ($decompressed | get exit_code) != 0 { return ($decompressed | wrap error | to json -r) }
        # get stdout from complete output
        return ($decompressed | get stdout)
    } else {
        # url does not include paste
        # try to get paste from body
        let body_paste = try {
            $body | get 0 | from json | get paste
        } catch {
            return ("Failed to parse body" | wrap error | to json -r)
        }
        # try to compress and base64 encode paste
        let lzma_base64 = try {
            $body_paste | lzma | base64 -w0 | complete
        } catch {
            |e| return ("Failed to compress and encode paste" | wrap error | to json -r)
        }
        # return if exit not 0
        if ($lzma_base64 | get exit_code) != 0 { return ($lzma_base64 | wrap error | to json -r) }
        # check if url includes language
        let lang = $env.l? | default ""
        # create json with main link, base64, and double url encoded base64
        let json = try {(
            $"https://bokub.github.io/nopaste/?l=($lang)#($lzma_base64 | get stdout)" | wrap url |
            merge ($lzma_base64 | get stdout | wrap base64) |
            merge ($lzma_base64 | get stdout | url encode | url encode | wrap base64_url_enc) | 
            to json -r
        )} catch {
            |e| return ("Failed to create response JSON" | wrap error | to json -r)
        }
        # output json
        return $json
    }
}
