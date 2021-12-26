#!/usr/bin/tclsh

package require TclCurl

curl::transfer -header 1 -nobody 1 -url $env(u) -timeout 7 -useragent [expr {int(rand()*99999999999)}]
