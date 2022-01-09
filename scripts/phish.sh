#!/usr/bin/tclsh

package require rl_json
package require TclCurl

namespace import rl_json::json

set phish false

set redirect false

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

set input $env(url)

if { [ string match "http*" $input ] } {
	set domain [ regsub "^www\." [ lindex [ split $input "/" ] 2 ] "" ]
} else {
	set domain [ regsub "^www\." $input "" ]
}

set sFileID [ open {/home/webhookd/jsonlite/domains/shorteners} ]

set sjs [ read $sFileID ]

set shorteners [ json get $sjs ]

foreach s $shorteners {
	if { $s == $domain } {
		set redirect true
		break
	}
}

if { $redirect == true } {
	curl::transfer -nobody 1 -url $input -headervar reheaders
	set reurl [ lindex [ array get reheaders location ] 1 ]
	set domain [ regsub "^www\." [ lindex [ split $reurl "/" ] 2 ] "" ]
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

set bFileID [ open {/home/webhookd/jsonlite/domains/blacklist} ]

set bjs [ read $bFileID ]

set blacklist [ json get $bjs ]

foreach d $blacklist {
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

if { $phish == false } {
	curl::transfer -followlocation 1 -url https://transparencyreport.google.com/transparencyreport/api/v3/safebrowsing/status?site=$domain -bodyvar gsbraw
	set gsb [ json get [ lindex [ split $gsbraw "\n" ] 2 ] 0  4 ]
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
