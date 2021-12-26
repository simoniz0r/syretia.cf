#!/usr/bin/tclsh

package require TclCurl

curl::transfer -followlocation 1 -url $env(u) -timeout 3 -useragent [expr {int(rand()*99999999999)}]
