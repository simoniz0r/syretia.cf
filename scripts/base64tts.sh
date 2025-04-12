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
        http post -m 15 -H [content-type text/plain] $url $body | encode base64
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    # wrap result for json otuput
    return ($base64 | prepend "data:audio/ogg;base64," | str join "" | wrap audioUrl)
}

# get TTS audio from tts.monster
def monster [voice token text] {
    # setup body json
    let body = $text | wrap message | merge ($voice | wrap voice_id) | merge ('true' | wrap return_usage) | to json -r
    # make http post request
    let audio_json = try {
        http post -m 55 -H [Authorization $token content-type application/json] "https://api.console.tts.monster/generate" $body
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    let audio_url = try { $audio_json | get url } catch { |e| return ($e.json | from json | wrap error) }
    # fetch and base64 encode result
    let base64 = try { http get -m 5 ($audio_url) | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
    # wrap result for json otuput
    return ($base64 | prepend "data:audio/wav;base64," | str join "" | wrap audioUrl | merge $audio_json)
}

# get TTS audio from fakeyou
def fakeyou [voice text] {
    # setup body json
    let json = $text | wrap inference_text | merge ($voice | wrap tts_model_token) | merge (random uuid | wrap uuid_idempotency_token) | to json -r
    # set job start time
    let start = date now | format date '%s' | into int
    # make http post request to start job
    let job = try {
        http post -m 10 -H [accept application/json content-type application/json] "https://api.fakeyou.com/tts/inference" $json | get inference_job_token
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    # loop until job finished (up to 30 seconds)
    loop {
        # make http request to get job status
        let resp = try { http get -m 5 -e $"https://api.fakeyou.com/tts/job/($job)" } catch { |e| return ($e.json | from json | wrap error) }
        # set current time
        let now = date now | format date '%s' | into int
        # break if success is not true
        if $resp.success != true {
            # get seconds elapsed
            let time = $now - $start | append "seconds" | str join " "
            # return response
            return ($resp | merge ($time | wrap time) | wrap error)
            break
        }
        # break if time now minus time started is greater than 29 seconds
        if ($now - $start) > 29 {
            # get seconds elapsed
            let time = $now - $start | append "seconds" | str join " "
            # return response
            return ($resp | update success "false" | merge ($time | wrap time) | wrap error)
            break
        # sleep if status is pending
        } else if $resp.state.status == "pending" {
            sleep 1sec
        # sleep if status is started
        } else if $resp.state.status == "started" {
            sleep 0.5sec
        # break and return error if failed
        } else if $resp.state.status == "attempt_failed" {
            # get seconds elapsed
            let time = $now - $start | append "seconds" | str join " "
            # return response
            return ($resp | update success "false" | merge ($time | wrap time) | wrap error)
            break
        # break when job completed
        } else {
            # get seconds elapsed
            let time = $now - $start | append "seconds" | str join " "
            # download and base64 encode job audio
            let base64 = try { http get -m 10 -r $"https://cdn-2.fakeyou.com($resp.state.maybe_public_bucket_wav_audio_path)" | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
            # return response with base64 encoded audio
            return ($resp | merge ($time | wrap time) | merge ($base64 | prepend "data:audio/wav;base64," | str join "" | wrap audioUrl))
            break
        }
    }
}

# get TTS audio from lazypy
def lazypy [voice service text] {
    # create body using url build-query
    let body = $text | wrap text | merge ($service | wrap service) | merge ($voice | wrap voice) | url build-query
    # post body to lazypy and get audio_url
    let audio_json = try { http post -m 15 -H [content-type application/x-www-form-urlencoded] "https://lazypy.ro/tts/request_tts.php" $body } catch { |e| return ($e.json | from json | wrap error) }
    # return response if success is not true
    if ($audio_json | get success) != true {
        return ($audio_json | wrap error)
    }
    let audio_url = try { $audio_json | get audio_url } catch { |e| return ($e.json | from json | wrap error) }
    # fetch and base64 encode result
    let base64 = try { http get -m 5 $audio_url | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
    return ($base64 | prepend "data:audio/mp3;base64," | str join "" | wrap audioUrl | merge $audio_json)
}

# clean input by replacing emojis with text
def clean_input [text] {
    # if text does not contain emoji, return text
    if ($text | str replace -ar '[^[:print:]]' '') == $text {
        return $text
    # else replace each emoji with text
    } else {
        # get JSON list of emojis
        let emojis = try { open /home/syretia/git/syretia.cf/scripts/.data-by-emoji.json } catch { return $text }
        # if emoji found in list, replace emoji in input with name from emojis list
        let cleaned = try {
            $text | split row "" | each { |r| try { $emojis | get $r | get name } catch { $r } } | str join ""
        } catch {
            return $text
        }
        return $cleaned
    }
}

# gets TTS URL for given service and returns base64 encoded audio
def tts [voice:string service:string text:string] {
    # route based on service
    let detext = clean_input $text
    let result = match ($service | split row '_' | get 0) {
        audiourl => { audiourl $voice ($detext | str substring 0..499) },
        Cerevoice => { cerevoice $voice ($detext | str substring 0..499) },
        FakeYou => { fakeyou $voice ($detext | str substring 0..499) },
        TikTok => { weilbyte $voice ($detext | str substring 0..299) },
        ttsm => { monster $voice $service ($detext | str substring 0..499) },
        uberduck => { uberduck $voice ($detext | str substring 0..349) },
        _ => { lazypy $voice $service ($detext | str substring 0..499) }
    }
    # return result in json format
    return ($result | to json -r)
}

# get input and run main tts function
let env_voice = try { $env.voice } catch { exit 0 }
let env_service = try { $env.service } catch { exit 0 }
let env_text = try { $env.text } catch { exit 0 }

tts $env_voice $env_service $env_text
