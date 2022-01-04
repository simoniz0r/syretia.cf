#!/bin/bash
# Name: json_db
# Author: Syretia
# License: MIT
# Dependencies: jq
# Description: A simple JSON database mostly intended for use with webhookd (https://github.com/ncarlier/webhookd). Inspired by jsonlite (https://github.com/nodesocket/jsonlite).

set -eo pipefail; [[ $TRACE ]] && set -x

readonly VERSION="0.0.1"
export JSON_DB_DIR=${JSON_DB_DIR:="$PWD/json_db_data"}

json_db_version() {
    echo "json_db $VERSION"
}

json_db_help() {
    jq -n --arg ver "$VERSION" \
    --arg a1 "set" \
    --arg u1 "set <bin> <id> [path] <json>" \
    --arg d11 "Writes JSON 'JSON_DB_DIR/bin/id' and returns what was written." \
    --arg d12 "'path' is optional; used to update existing JSON files. Uses 'jq' syntax." \
    --arg a2 "get" \
    --arg u2 "get <bin> [id] [path]" \
    --arg d21 "Retrieves JSON from 'JSON_DB_DIR/bin/id'." \
    --arg d22 "'id' and 'path' are optional. 'path' uses 'jq' syntax." \
    --arg a3 "count" \
    --arg u3 "count <bin>" \
    --arg d3 "Count total number of JSON files in 'JSON_DB_DIR/bin'." \
    --arg a4 "list" \
    --arg u4 "list <bin>" \
    --arg d4 "List JSON files in 'JSON_DB_DIR/bin'" \
    --arg a5 "delete" \
    --arg u5 "delete <bin> <id>" \
    --arg d5 "Deletes JSON file 'JSON_DB_DIR/bin/id'." \
    --arg a6 "drop" \
    --arg u6 "drop <bin> [--force]" \
    --arg d6 "Drops 'JSON_DB_DIR/bin'." \
    --arg a7 "help" \
    --arg u7 "help [section]" \
    --arg d7 "Displays help. 'section' is optional and displays help for a specific section." \
    --arg vn1 "JSON_DB_DIR" \
    --arg vd1 "Set the directory to store JSON files in." \
    --arg vn2 "JSON_DB_TOKEN" \
    --arg vd2 "Set the token to be used for authenticating with read and/or write protected bins." \
    --arg vn3 "JSON_DB_PRETTY" \
    --arg vd3 "When set to true, JSON will be pretty printed." \
    --arg ad1 "To read and/or write protect bins, authentication files can be placed in 'JSON_DB_DIR'." \
    --arg ad2 "For all bins, create the file 'JSON_DB_DIR/.default_auth' as shown in the example below." \
    --arg ad3 "For individual bins (overrides default), use 'JSON_DB_DIR/.BinNameHere_auth'." \
    --arg ad4 "Export the 'JSON_DB_TOKEN' variable with the contents of your non-encrypted token." \
    '{"name":"json_db",
    "version":$ver,
    "usage":"json_db argument <argument-specific-options>",
    "descripton":"A simple JSON database.",
    "arguments":[
        {"name":$a1,"usage":$u1,"description":[$d11,$d12]},
        {"name":$a2,"usage":$u2,"description":[$d21,$d22]},
        {"name":$a3,"usage":$u3,"description":$d3},
        {"name":$a4,"usage":$u4,"description":$d4},
        {"name":$a5,"usage":$u5,"description":$d5},
        {"name":$a6,"usage":$u6,"description":$d6},
        {"name":$a7,"usage":$u7,"description":$d7}
    ],
    "variables":[
        {"name":$vn1,"description":$vd1},
        {"name":$vn2,"description":$vd2},
        {"name":$vn3,"description":$vd3}
    ],
    "authentication":{
        "description":[$ad1,$ad2,$ad3,$ad4],
        "keys":{
            "hash":"Token for this bin in sha256 encrypted format.",
            "write":"Set to true to enable write protection or false to disable.",
            "read":"Set to true to enable read protection or false to disable."
        },
        "example":{
            "hash":"befeafb844fd6f296ebc9f1e0cb519205c9359b1d69d5298b1e95add129e529b",
            "write":true,
            "read":true
        }
    }
    }' | jq ".$1 // {\"error\":\"Section '$1' not found\".}"
}

json_db_set() {
    json_bin="$1"
    json_id="$2"
    if [[ -z "$4" ]]; then
        json_path=""
        value="$3"
    else
        json_path="$3"
        value="$4"
    fi

    if [[ -z "$value" && ! -t 0 ]]; then
        while read -r piped; do
        value+=$piped
        done;
    fi

    if [[ -z "$json_bin" ]]; then
        jq -cn '.error |= "Missing required argument bin."'
        exit 0
    fi

    unset auth_file
    if [[ -f "$JSON_DB_DIR/.${json_bin}_auth" ]]; then
        auth_file=".${json_bin}_auth"
    elif [[ -f "$JSON_DB_DIR/.default_auth" ]]; then
        auth_file=".default_auth"
    fi

    if [[ -n "$auth_file" ]]; then
        json_write="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.write?' 2>/dev/null || true)"
        if [[ "$json_write" == "true" ]]; then
            if [[ -z "$JSON_DB_TOKEN" ]]; then
                jq -cn '.error |= "This bin is write protected. Missing required variable JSON_DB_TOKEN."'
                exit 0
            fi
            json_hash="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.hash?' 2>/dev/null || true)"
            token_hash="$(echo -n "$JSON_DB_TOKEN" | sha256sum | cut -f1 -d' ')"
            if [[ "$json_hash" != "$token_hash" ]]; then
                jq -cn '.error |= "Invalid authorization. Variable JSON_DB_TOKEN does not match stored hash for this bin."'
                exit 0
            fi
        fi
    fi

    if [[ -z "$json_id" ]]; then
        jq -cn '.error |= "Missing required argument id."'
        exit 0
    fi

    if [[ -z "$value" ]]; then
        jq -cn '.error |= "Missing required argument json file."'
        exit 0
    fi

    if [[ -z "$json_path" ]]; then
        # check if json is valid
        if echo "$value" | jq '.' &> /dev/null; then
        json_document="$(echo "$value" | jq -c '.')"
        else
            jq -cn --arg er "$(echo "$value" | jq '.' 2>&1 | cut -f4- -d':' | cut -f2- -d' ')" '.error |= $er'
            exit 0
        fi
    else
        if [[ "$(jq -crn --argjson j "$value" '$j' 2>/dev/null)" != "" && "$value" == [0-9]* ]]; then
            json_document="$(jq -c --arg v "$value" "$json_path |= \$v" "$JSON_DB_DIR/$json_bin/$json_id" 2>&1 || true)"
        elif [[ "$(jq -crn --argjson j "$value" '$j' 2>/dev/null)" != "" ]]; then
            json_document="$(jq -c --argjson v "$value" "$json_path |= \$v" "$JSON_DB_DIR/$json_bin/$json_id" 2>&1 || true)"
        else
            json_document="$(jq -c --arg v "$value" "$json_path |= \$v" "$JSON_DB_DIR/$json_bin/$json_id" 2>&1 || true)"
        fi
    fi

    # check if json is valid
    if ! echo "$json_document" | jq '.' &> /dev/null; then
        jq -cn --arg er "$(echo "$json_document" | cut -f4- -d':' | cut -f2- -d' ')" '.error |= $er'
        exit 0
    fi

    mkdir -p "$JSON_DB_DIR/$json_bin"

    echo "$json_document" > "$JSON_DB_DIR/$json_bin/$json_id"
    if [[ -z "$json_path" ]]; then
        cat "$JSON_DB_DIR/$json_bin/$json_id"
    else
        if [[ "$JSON_DB_PRETTY" == "true" ]]; then
            jq -r "$json_path" "$JSON_DB_DIR/$json_bin/$json_id"
        else
            jq -cr "$json_path" "$JSON_DB_DIR/$json_bin/$json_id"
        fi
    fi
}

json_db_get() {
    json_bin="$1"
    json_id="$2"
    if [[ -n "$3" ]]; then
        json_path="$3"
    else
        json_path="."
    fi
    if [[ -z "$json_bin" ]]; then
        jq -cn '.error |= "Missing required argument bin."'
        exit 0
    fi

    if [[ ! -d "$JSON_DB_DIR/$json_bin" ]]; then
        jq -cn '.error |= "Invalid argument bin."'
        exit 0
    fi

    unset auth_file
    if [[ -f "$JSON_DB_DIR/.${json_bin}_auth" ]]; then
        auth_file=".${json_bin}_auth"
    elif [[ -f "$JSON_DB_DIR/.default_auth" ]]; then
        auth_file=".default_auth"
    fi

    if [[ -n "$auth_file" ]]; then
        json_read="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.read?' 2>/dev/null || true)"
        if [[ "$json_read" == "true" ]]; then
            if [[ -z "$JSON_DB_TOKEN" ]]; then
                jq -cn '.error |= "This bin is read protected. Missing required variable JSON_DB_TOKEN."'
                exit 0
            fi
            json_hash="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.hash?' 2>/dev/null || true)"
            token_hash="$(echo -n "$JSON_DB_TOKEN" | sha256sum | cut -f1 -d' ')"
            if [[ "$json_hash" != "$token_hash" ]]; then
                jq -cn '.error |= "Invalid authorization. Variable JSON_DB_TOKEN does not match stored hash for this bin."'
                exit 0
            fi
        fi
    fi

    if [[ -z "$json_id" ]]; then
        for file in "$JSON_DB_DIR/$json_bin"/*; do
            file_name="$(basename "$file")"
            if [[ -z "$json" ]]; then
                json="$(jq -cn --arg f "$file_name" --argfile j "$file" '.[$f] |= $j')"
            else
                json="$(echo "$json" | jq -c --arg f "$file_name" --argfile j "$file" '.[$f] |= $j')"
            fi
        done
        if [[ "$print" == "pretty" ]]; then
            echo "$json" | jq '.'
        else
            echo "$json"
        fi
        # jq -cn '.error |= "Missing required argument id."'
        exit 0
    fi

    if [[ ! -f "$JSON_DB_DIR/$json_bin/$json_id" ]]; then
        jq -cn '.error |= "Invalid argument id."'
        exit 0
    fi  

    json_out="$(jq -cr "$json_path" "$JSON_DB_DIR/$json_bin/$json_id" 2>&1 || true)"

    if [[ "$json_out" == "jq"* ]]; then
        jq -cn --arg er "$(echo "$json_out" | cut -f5- -d' ')" '.error |= $er'
    else
        if [[ "$JSON_DB_PRETTY" == "true" ]] && [[ "$json_out" == '['* || "$json_out" == '{'* ]]; then
            jq '.' <<<"$json_out"
        else
            echo "$json_out"
        fi
    fi
}

json_db_count() {
    json_bin="$1"
    if [[ -z "$json_bin" ]]; then
        jq -cn '.error |= "Missing required argument bin."'
        exit 0
    fi
    
    if [[ ! -d "$JSON_DB_DIR/$json_bin" ]]; then
        jq -cn '.error |= "Invalid argument bin."'
        exit 0
    fi

    unset auth_file
    if [[ -f "$JSON_DB_DIR/.${json_bin}_auth" ]]; then
        auth_file=".${json_bin}_auth"
    elif [[ -f "$JSON_DB_DIR/.default_auth" ]]; then
        auth_file=".default_auth"
    fi

    if [[ -n "$auth_file" ]]; then
        json_read="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.read?' 2>/dev/null || true)"
        if [[ "$json_read" == "true" ]]; then
            if [[ -z "$JSON_DB_TOKEN" ]]; then
                jq -cn '.error |= "This bin is read protected. Missing required variable JSON_DB_TOKEN."'
                exit 0
            fi
            json_hash="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.hash?' 2>/dev/null || true)"
            token_hash="$(echo -n "$JSON_DB_TOKEN" | sha256sum | cut -f1 -d' ')"
            if [[ "$json_hash" != "$token_hash" ]]; then
                jq -cn '.error |= "Invalid authorization. Variable JSON_DB_TOKEN does not match stored hash for this bin."'
                exit 0
            fi
        fi
    fi

    ls -Cw1 "$JSON_DB_DIR/$json_bin" | wc -l | jq -cR --arg bn "$json_bin" '{"count":.|fromjson,"bin":$bn}'
}

json_db_list() {
    json_bin="$1"
    if [[ -z "$json_bin" ]]; then
        jq -cn '.error |= "Missing required argument bin."'
        exit 0
    fi
    
    if [[ ! -d "$JSON_DB_DIR/$json_bin" ]]; then
        jq -cn '.error |= "Invalid argument bin."'
        exit 0
    fi

    unset auth_file
    if [[ -f "$JSON_DB_DIR/.${json_bin}_auth" ]]; then
        auth_file=".${json_bin}_auth"
    elif [[ -f "$JSON_DB_DIR/.default_auth" ]]; then
        auth_file=".default_auth"
    fi

    if [[ -n "$auth_file" ]]; then
        json_read="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.read?' 2>/dev/null || true)"
        if [[ "$json_read" == "true" ]]; then
            if [[ -z "$JSON_DB_TOKEN" ]]; then
                jq -cn '.error |= "This bin is read protected. Missing required variable JSON_DB_TOKEN."'
                exit 0
            fi
            json_hash="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.hash?' 2>/dev/null || true)"
            token_hash="$(echo -n "$JSON_DB_TOKEN" | sha256sum | cut -f1 -d' ')"
            if [[ "$json_hash" != "$token_hash" ]]; then
                jq -cn '.error |= "Invalid authorization. Variable JSON_DB_TOKEN does not match stored hash for this bin."'
                exit 0
            fi
        fi
    fi

    ls -Cw1 "$JSON_DB_DIR/$json_bin" | perl -pe 'chomp if eof' | jq -cRs --arg bn "$json_bin" '{"list":split("\n"),"bin":$bn}'
}

json_db_delete() {
    json_bin="$1"
    json_id="$2"
    if [[ -z "$json_bin" ]]; then
        jq -cn '.error |= "Missing required argument bin."'
        exit 0
    fi
    
    if [[ -z "$json_id" ]]; then
        jq -cn '.error |= "Missing required argument id."'
        exit 0
    fi

    if [[ ! -d "$JSON_DB_DIR/$json_bin" ]]; then
        jq -cn '.error |= "Invalid argument bin."'
        exit 0
    fi

    if ! json_db_is_valid "." "$json_bin/$json_id"; then
        jq -cn '.error |= "Invalid argument id."'
        exit 0
    fi

    unset auth_file
    if [[ -f "$JSON_DB_DIR/.${json_bin}_auth" ]]; then
        auth_file=".${json_bin}_auth"
    elif [[ -f "$JSON_DB_DIR/.default_auth" ]]; then
        auth_file=".default_auth"
    fi

    if [[ -n "$auth_file" ]]; then
        json_write="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.write?' 2>/dev/null || true)"
        if [[ "$json_write" == "true" ]]; then
            if [[ -z "$JSON_DB_TOKEN" ]]; then
                jq -cn '.error |= "This bin is write protected. Missing required variable JSON_DB_TOKEN."'
                exit 0
            fi
            json_hash="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.hash?' 2>/dev/null || true)"
            token_hash="$(echo -n "$JSON_DB_TOKEN" | sha256sum | cut -f1 -d' ')"
            if [[ "$json_hash" != "$token_hash" ]]; then
                jq -cn '.error |= "Invalid authorization. Variable JSON_DB_TOKEN does not match stored hash for this bin."'
                exit 0
            fi
        fi
    fi

    if [[ -f "$JSON_DB_DIR/$json_bin/$json_id" ]]; then
        rm -f "$JSON_DB_DIR/$json_bin/$json_id"
        jq -cn --arg doc "$json_id" --arg bn "$json_bin" '{"deleted":$doc,"bin":$bn}'
    fi
}

json_db_drop() {
    json_bin="$1"
    if [[ -z "$json_bin" ]]; then
        jq -cn '.error |= "Missing required argument bin."'
        exit 0
    fi
    
    if [[ ! -d "$JSON_DB_DIR/$json_bin" ]]; then
        jq -cn '.error |= "Invalid argument bin."'
        exit 0
    fi

    unset auth_file
    if [[ -f "$JSON_DB_DIR/.${json_bin}_auth" ]]; then
        auth_file=".${json_bin}_auth"
    elif [[ -f "$JSON_DB_DIR/.default_auth" ]]; then
        auth_file=".default_auth"
    fi

    if [[ -n "$auth_file" ]]; then
        json_write="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.write?' 2>/dev/null || true)"
        if [[ "$json_write" == "true" ]]; then
            if [[ -z "$JSON_DB_TOKEN" ]]; then
                jq -cn '.error |= "This bin is write protected. Missing required variable JSON_DB_TOKEN."'
                exit 0
            fi
            json_hash="$(cat "$JSON_DB_DIR/$auth_file" | jq -r '.hash?' 2>/dev/null || true)"
            token_hash="$(echo -n "$JSON_DB_TOKEN" | sha256sum | cut -f1 -d' ')"
            if [[ "$json_hash" != "$token_hash" ]]; then
                jq -cn '.error |= "Invalid authorization. Variable JSON_DB_TOKEN does not match stored hash for this bin."'
                exit 0
            fi
        fi
    fi

    if [[ "$2" == "--force" ]]; then
        rm -rf "$JSON_DB_DIR/$json_bin"
        exit 0
    fi

    read -rp "Drop database '$JSON_DB_DIR/$json_bin'? [Y/n] " confirm
    case "$confirm" in
        Y|y|YES|yes ) rm -rf "$JSON_DB_DIR/$json_bin";;
        * ) exit;;
    esac
}

json_db_main() {
    cmd="$1"

    if [[ -z $cmd ]]; then
        json_db_help
        exit 0
    fi

    shift 1
    case "$cmd" in
        "set") json_db_set "$@";;
        "get") json_db_get "$@";;
        "count") json_db_count "$@";;
        "list") json_db_list "$@";;
        "delete") json_db_delete "$@";;
        "drop") json_db_drop "$@";;
        "version") json_db_version;;
        "help") json_db_help "$@";;
        *) json_db_help "$cmd";;
    esac
}

if [[ -n "$hook_id" ]]; then
    if [[ "$pretty" == "true" ]]; then
        export JSON_DB_PRETTY="true"
    fi
    export JSON_DB_DIR="/home/webhookd/jsonlite"
    export JSON_DB_TOKEN="$token"
    json_in="$(echo "$@" | jq -r '.json?' || true)"
    json_db_main "$op" "$bin" "$id" "$path" "$json_in"
else
    json_db_main "$@"
fi
