#!/usr/bin/tclsh

# load rl_json package and import it so it can be used as 'json'
package require rl_json
namespace import rl_json::json

# check if environment variable x_api_key exists
if {[info exists env(x_api_key)] == 0} {
	# set hash to null if doesn't exist
	set hash null
} else {
	# set hash to sha256sum of x_api_key
	set hash [lindex [split [exec echo $env(x_api_key) | sha256sum] { }] 0]
}

# check if hash matches WHD_AUTH_HASH environment variable
if {$hash != $env(WHD_AUTH_HASH)} {
	# exit if not matching
	set er [list string "Not authorized: $hash"]
	puts [json object error $er]
	exit 0
}

# get json from input
set json [lindex $argv 0]
# get program and stdin from json and base64 decode them
if {[catch {set program [binary decode base64 [json get $json program]]}] != 0} {
	# output error and exit if missing program
	set er [list string "Missing required values"]
	puts [json object error $er]
	exit 0
}
if {[catch {set stdin [binary decode base64 [json get $json stdin]]}] != 0} {
	# set stdin to empty value if not present in $json
	set stdin {}
}

# check if $stdin is set and setup $command
# $command loads .bashrc file, runs $program,  and removes any files written wile running
if {$stdin != {}} {
	# if $stdin is set, redirect it to $program
	set command "cd ~/runner/bash; \
	source /home/syretia/git/syretia.cf/scripts/.bashrc; \
	$program <<<$stdin; \
	exit_status=\"$?\"; \
	rm -rf ~/runner/bash/*; \
	exit \$exit_status"
} else {
	# else just run $program
	set command "cd ~/runner/bash; \
	source /home/syretia/git/syretia.cf/scripts/.bashrc; \
	$program; \
	exit_status=\"$?\"; \
	rm -rf ~/runner/bash/*; \
	exit \$exit_status"
}

# set start time in milliseconds
set start_time [clock milliseconds]

# run $command using bash
# set default values
set exit_status 0
set standard_error {}
set standard_output {}
# run command and catch any non-zero exit
if {[catch {exec bash -c -- "$command"} output] != 0} {
	global errorCode
	# get $exit_status from end of $errorCode
	set exit_status [lindex $errorCode end]
	# $standard_error is last line of output
	set standard_error [lindex [split $output "\n"] end]
	# $standard_output is all lines except last of output
	set standard_output [join [lrange [split $output "\n"] 0 end-1] "\n"]
} else {
	# $standard_output is output
	set standard_output $output
}

# get time in seconds that bash ran
set end_time [format "%.3f" [expr [expr [clock milliseconds] - $start_time] / 1000.0]]

# setup variables for JSON response output
set pgm [list string $program]
set sti [list string $stdin]
set stdout [list string $standard_output]
set stderr [list string $standard_error]
set ex [list string $exit_status]
set time [list string $end_time]

# output JSON response
puts [json object \
program $pgm \
stdin $sti \
stdout $stdout \
stderr $stderr \
exit $ex \
time $time]

exit 0
