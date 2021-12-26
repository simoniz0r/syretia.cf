#!/bin/bash

printf "%s\n" "[$(curl -sL -u \
"zyp_user:zyp_password_1" \
"https://api.opensuse.org/search/published/binary/id?match=%40name%3D%27$q%27" | \
xmlstarlet sel -t \
-m "/collection/binary" \
-v "concat('{\"name\":\"',@name,'\",\"version\":\"',@version,'\",\"project\":\"',@project,'\",\"repository\":\"',@repository,'\",\"arch\":\"',@arch,'\",\"package\":\"',@package,'\",\"filename\":\"',@filename,'\",\"filepath\":\"',@filepath,'\",\"baseproject\":\"',@baseproject,'\",\"type\":\"',@type,'\"}')" -n | \
perl -pe 'chomp if eof' | \
tr '\n' ',')]" | \
jq -r '.'
