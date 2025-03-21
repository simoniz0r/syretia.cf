#!/usr/bin/env nu
# Name: base64tts
# Author: Syretia
# License: MIT
# Dependencies: nushell
# Description: fetches TTS audio from a couple of free services and returns the result encoded in base64 format

# fetch and base64 encode audio urls
def audiourl [voice text] {
    # url encode text and prepend url
    let enc_url = $text | url encode | prepend $voice | str join ""
    # fetch and base64 encode audio url
    let base64 = try { http get -m 5 $enc_url | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
    # wrap result for json output
    return ($base64 | prepend "data:audio/mp3;base64," | str join "" | wrap audioUrl | merge ($enc_url | wrap originalUrl))
}

# get TikTok TTS audio from weilbyte
def weilbyte [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request and bas64 encode result, fallback to weilnet if fails
    let base64 = try { http post -m 6 -H [content-type application/json] "https://tiktok-tts.weilbyte.dev/api/generate" $body | encode base64 } catch { return (weilnet $voice $text) }
    # wrap result for json otuput
    return ($base64 | prepend "data:audio/mp3;base64," | str join "" | wrap audioUrl)
}

# get TikTok TTS audio from weilnet
def weilnet [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request, fallback to cursecode if fails
    let req_json = try { http post -m 6 -H [content-type application/json] "https://tiktok-tts.weilnet.workers.dev/api/generation" $body } catch { return (cursecode $voice $text) }
    # prepend audio info and rename column
    let json = try { $req_json | upsert data { |row| $row.data | prepend "data:audio/mp3;base64," | str join "" } | rename -c {data: audioUrl} } catch { return (cursecode $voice $text) }
    # output json result
    return $json
}

# get TikTok TTS audio from cursecode
def cursecode [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request, fallback to gesserit if fails
    let req_json = try { http post -m 6 -H [content-type application/json] "https://tts.cursecode.me/api/tts" $body } catch { return (gesserit $voice $text) }
    let json = try { $req_json | rename -c { audio: audioUrl } } catch { return (gesserit $voice $text) }
    # output json result
    return $json
}

# get TikTok TTS audio from gesserit
def gesserit [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request, fallback to lazypy if fails
    let json = try { http post -m 6 "https://gesserit.co/api/tiktok-tts" $body } catch { return (lazypy $voice "TikTok" $text) }
    # output json result
    return $json
}

# get TTS audio from uberduck
def uberduck [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request
    let audio_json = try { http post -m 10 -H [content-type application/json] "https://www.uberduck.ai/splash-tts" $body } catch { |e| return ($e.json | from json | wrap error) }
    let audio_url = try { $audio_json | get response.path } catch { |e| return ($e.json | from json | wrap error) }
    # fetch and base64 encode result
    let base64 = try { http get -m 5 ($audio_url) | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
    # wrap result for json otuput
    return ($base64 | prepend "data:audio/wav;base64," | str join "" | wrap audioUrl | merge $audio_json)
}

# get TTS audio from Cerevoice
def cerevoice [voice text] {
    # setup body
    let body = $text | prepend "<text>" | append "</text>" | str join ""
    # setup url with voice as query
    let url = "https://api.cerevoice.com/v2/demo?audio_format=ogg&voice=" | append $voice | append "-CereWave" | str join ""
    # make http post request and bas64 encode result
    let base64 = try {
        http post -m 10 -H [content-type text/plain] $url $body | encode base64
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    # wrap result for json otuput
    return ($base64 | prepend "data:audio/ogg;base64," | str join "" | wrap audioUrl)
}

# get TTS audio from lazypy
def lazypy [voice service text] {
    # create body using url build-query
    let body = $text | wrap text | merge ($service | wrap service) | merge ($voice | wrap voice) | url build-query
    # post body to lazypy and get audio_url
    let audio_json = try { http post -m 10 -H [content-type application/x-www-form-urlencoded] "https://lazypy.ro/tts/request_tts.php" $body } catch { |e| return ($e.json | from json | wrap error) }
    # return response if success is not true
    if ($audio_json | get success) != true {
        return ($audio_json | wrap error)
    }
    let audio_url = try { $audio_json | get audio_url } catch { |e| return ($e.json | from json | wrap error) }
    # fetch and base64 encode result
    let base64 = try { http get -m 5 $audio_url | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
    return ($base64 | prepend "data:audio/mp3;base64," | str join "" | wrap audioUrl | merge $audio_json)
}

# gets TTS URL for given service and returns base64 encoded audio
def tts [voice:string service:string text:string] {
    # route based on service
    let result = match $service {
        audiourl => { audiourl $voice $text },
        Cerevoice => { cerevoice $voice $text },
        TikTok => { weilbyte $voice $text },
        uberduck => { uberduck $voice $text },
        _ => { lazypy $voice $service $text }
    }
    # return result in json format
    return ($result | to json -r)
}

# get input and run main tts function
let env_voice = try { $env.voice } catch { exit 0 }
let env_service = try { $env.service } catch { exit 0 }
let env_text = try { $env.text } catch { exit 0 }

tts $env_voice $env_service $env_text
