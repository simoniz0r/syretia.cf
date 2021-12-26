#!/bin/bash
# script used by 'webhookd' to execute bash script under restricted 'webhookd' user
# 'webhookd' user can only write to '/home/webhookd/runner', and this dir is cleared after each run

# function to run script that contains user input
bash_api() {
    # set process limit to 30 and cpu time to 15
    ulimit -u 30 -t 15
    # create dummy 'ulimit' function to disable setting ulimit in script
    ulimit(){ echo "nope"; }
    # create script containing input
    printf "%s\n" "$program" > /home/webhookd/runner/bash/"$dir_name"/bashrun
    # printf "%s\n" "export exitcode=$?" >> /home/webhookd/runner/bash/"$dir_name"/bashrun
	# load in custom variables and functions
	source /home/syretia/webhookd/scripts/.bashrc
    # cd to only dir 'webhookd' user can write to
    cd /home/webhookd/runner/bash/"$dir_name/run"
    # set start time
    start_time="$(date +%s%N)"
    # run script
	if [[ -n "$stdin" ]]; then
		printf "%s\n" "$stdin" | source ../bashrun
	else
    	source ../bashrun
    fi
    # set exit code for json output
    exitcode=$?
    # set end time
    end_time="$(date +%s%N)"
    # calculate total run time based on start and end time for json output
    time="$(awk "BEGIN {printf \"%.3f\n\", ($end_time - $start_time) / 1000000000}")s"
}

# function to get the results from running the script and output them as json
bash_results() {
    # get stdout from file and remove colors
    stdout="$(cat /home/webhookd/runner/bash/"$dir_name"/bashstdout | sed -r 's/\x1B(\[[0-9;]*[JKmsu]|\(B)//g')"
    # get stderr from file and remove colors
    stderr="$(cat /home/webhookd/runner/bash/"$dir_name"/bashstderr | sed -r 's/\x1B(\[[0-9;]*[JKmsu]|\(B)//g')"
    # get log number
    log_num="$(ls /home/webhookd/logs/bash_*.txt | cut -f2 -d'_' | sort -nr | head -n 1)"
    # use jq to output json containing input, stdout, stderr, exit code, and run time
    jq -n --arg pg "$program" --arg si "$stdin" --arg so "$stdout" --arg se "$stderr" --arg ex "$exitcode" --arg tm "$time" --arg ln "$log_num" '{"program":$pg,"stdin":$si,"stdout":$so,"stderr":$se,"exit":$ex,"time":$tm,"logNum":$ln}'
    # remove any files that were created during run
    rm -rf /home/webhookd/runner/bash/"$dir_name"
}

# convert key input to sha256sum
key_hash="$(printf "%s\n" "$key" | sha256sum | cut -f1 -d' ')"
# unset key input so cannot be seen by running script
unset key
unset WHD_DISCORD_TOKEN
# compare input key hash to stored key hash
case "$key_hash" in
    "$WHD_AUTH_HASH")
        # successful authorization
        sleep 0
        ;;
    *)
        # failed authorization
        echo '{"error":"Invalid authorization."}' | jq '.'
        exit
        ;;
esac
            
# check if user input is from URL or sent as data
if [[ -z "$program" ]]; then
	if [[ "$(printf "%s\n" "$@" | jq -r '.program' 2> /dev/null)" != "" ]]; then
		program="$(printf "%s\n" "$@" | jq -r .program)"
		if [[ "$(printf "%s\n" "$@" | jq -r '.stdin')" != "null" ]]; then
			stdin="$(printf "%s\n" "$@" | jq -r '.stdin')"
		fi
	else
    	program="$@"
    fi
fi
# create directory for current instance
dir_name="$(date +%s)_$RANDOM"
mkdir -p /home/webhookd/runner/bash/"$dir_name"/run
# remove any files created in /tmp
mapfile -t tmp_files < <(ls -al /tmp | grep 'webhookd' | awk '{print $9}')
for tmp_file in "${tmp_files[@]}"; do
	if [[ -z "$tmp_file" ]]; then
		break
	fi
	rm -rf /tmp/"$tmp_file"
done
# remove any files left behind in case process was killed by webhookd
for dir in $(ls -a /home/webhookd/runner/bash | tail -n +3); do
    # break if nothing
    [[ -z "$dir" ]] && break
    # get date dir was created by removing random string at end
    dir_date="$(echo "$dir" | cut -f1 -d'_' | grep '[0-9]')"
    # check if is directory and dir_date variable is 10 chars long
    if [[ -d "/home/webhookd/runner/bash/$dir" && "${#dir_date}" -eq "10" ]]; then
        # delete if is dir and older than 10 seconds
        if [[ "$(($(date +%s)-$dir_date))" -gt "10" ]]; then
            rm -rf /home/webhookd/runner/bash/"$dir"
        fi
    # else remove any other junk left behind
    else
        rm -rf /home/webhookd/runner/bash/"$dir"
    fi
done
# run script based on user input and send stdout and stderr to files
bash_api 1> /home/webhookd/runner/bash/"$dir_name"/bashstdout 2> /home/webhookd/runner/bash/"$dir_name"/bashstderr
# get results and output json
bash_results 2> /dev/null
rm -rf /home/webhookd/logs/*
