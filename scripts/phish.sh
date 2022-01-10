#!/usr/bin/tclsh
;# Name: phish
;# Author: Syretia
;# License: MIT
;# Dependencies: rl_json, TclCurl
;# Description: Uses data fetched from phish.sinking.yachts and Google Safe Browsing to check if a 'url' is flagged for phishing

;# yes, this is a Tcl script even though it has a '.sh' extension
;# webhookd doesn't work with '.tcl' file extensions :(

;# use rl_json and TclCurl
package require rl_json
package require TclCurl
;# use namespace to import rl_json::json so it can be used as 'json'
namespace import rl_json::json
;# remove logs
exec rm -rf /home/webhookd/logs/*
;# set default values for variables
set phish false
set redirect false
;# output JSON containing error and exit if 'url' environment variable doesn't exist
if { [ info exists env(url) ] == 0 } {
    set error [ list string "No 'url' provided" ]
    puts [ json object \
    domain null \
    error $error\
    phish { boolean false } \
    redirect { boolean false } \
    source null \
    url null ]
    exit 0
}
;# set input variable to 'url' environment variable
set input $env(url)
;# get domain from input
if { [ string match "http*" $input ] } {
    set domain [ regsub "^www\." [ lindex [ split $input "/" ] 2 ] "" ]
} else {
    set domain [ regsub "^www\." $input "" ]
}
;# open URL shorteners file
set sFileID [ open {/home/webhookd/jsonlite/domains/shorteners} ]
;# read contents of file
set sjs [ read $sFileID ]
;# transform JSON array into list
set shorteners [ json get $sjs ]
;# check if domain is a URL shortener
foreach s $shorteners {
    if { $s == $domain } {
        set redirect true
        break
    }
}
;# get redirect URL if domain is a shortener
if { $redirect == true } {
    curl::transfer -nobody 1 -url $input -headervar reheaders
    ;# get URL from location header
    set reurl [ lindex [ array get reheaders location ] 1 ]
    ;# get domain from URL
    set domain [ regsub "^www\." [ lindex [ split $reurl "/" ] 2 ] "" ]
    ;# output JSON containing error and exit if domain is empty
    if { $domain == "" } {
        set error [ list string "Failed to fetch redirect for '$input'" ]
        set lredirect [ list boolean $redirect ]
        set url [ list string $input ]
        puts [ json object \
        domain null \
        error $error \
        phish [ list boolean false ] \
        redirect $lredirect \
        source null \
        url $url ]
        exit 0
    }
}
;# open domain blacklist file
set bFileID [ open {/home/webhookd/jsonlite/domains/blacklist} ]
;# read contents of file
set bjs [ read $bFileID ]
;# transform JSON array into list
set blacklist [ json get $bjs ]
;# check if blacklist contains domain
foreach d $blacklist {
    ;# match found, set phish variable to true and output JSON
    if { $d == $domain } {
        set phish true
        set ldomain [ list string $domain ]
        set lredirect [ list boolean $redirect ]
        set url [ list string $input ]
        puts [ json object \
        domain $ldomain \
        error null \
        phish { boolean true } \
        redirect $lredirect \
        source { string "phish.sinking.yachts" } \
        url $url ]
        break
    }
}
;# if no match found above, check Google Safe Browsing
if { $phish == false } {
    ;# set body of GSB results to gsbraw variable
    curl::transfer -followlocation 1 -url https://transparencyreport.google.com/transparencyreport/api/v3/safebrowsing/status?site=$domain -bodyvar gsbraw
    ;# get 5th value from nested array from results by getting 3rd line of gsbraw variable
    ;# the 5th value in the nested array is '1' if the site is flagged for phishing
    set gsb [ json get [ lindex [ split $gsbraw "\n" ] 2 ] 0  4 ]
    ;# set phish variable to true and output JSON if gsb variable is '1'
    if { $gsb == 1 } {
        set phish true
        set ldomain [ list string $domain ]
        set lredirect [ list boolean $redirect ]
        set url [ list string $input ]
        puts [ json object \
        domain $ldomain \
        error null \
        phish { boolean true } \
        redirect $lredirect \
        source { string "Google Safe Browsing" } \
        url $url ]
    }
}
;# no matches found, output JSON and exit
if { $phish == false } {
    set ldomain [ list string $domain ]
    set lredirect [ list boolean $redirect ]
    set url [ list string $input ]
    puts [ json object \
    domain $ldomain \
    error null \
    phish { boolean false } \
    redirect $lredirect \
    source null \
    url $url ]
}

exit 0
