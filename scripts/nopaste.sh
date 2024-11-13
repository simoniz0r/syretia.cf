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
        # url includes paste, decode, decompress and output
        let decoded = try { $in_paste | base64 -dw0 } catch { |e| return $e.msg }
        let decompressed = try { $decoded | lzma -d } catch { |e| return $e.msg }
        return $decompressed
    } else {
        # url does not include paste, compress body with lzma then base64 encode
        let lzma_base64 = try { $body | get 0 | from json | get paste | lzma | base64 -w0 } catch { |e| return $e.msg }
        # check if url includes language
        let lang = $env.l? | default ""
        # create json with links to nopaste and output
        let json = try { 
            $"https://bokub.github.io/nopaste/?l=($lang)#($lzma_base64)\nhttps://syretia.xyz/nopaste?p=($lzma_base64 | url encode | url encode)" | split column "\n" url alt | get 0 | to json -r
        } catch { |e| return $e.msg }
        return $json
    }
}
