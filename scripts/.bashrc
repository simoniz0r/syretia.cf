# set neofetch to output stdout mode and not use config
neofetch() {
	/usr/bin/neofetch --stdout --no_config
}

# get google search results
gse () {
    SEARCH_QUERY="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$*")"
    SEARCH_RESULT="$(curl -sL "https://www.google.com/search?q=$SEARCH_QUERY" -H 'User-Agent: Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Falkon/3.1.0 Chrome/69.0.3497.128 Safari/537.36' | pup 'a attr{href}' | tail -n +3 | grep -m1 '^http')"
    curl -sL "http://api.linkpreview.net/?key=86a22451d042b92ea493ae9a063448af&q=$SEARCH_RESULT" | jq '.'
    # metadata "$SEARCH_RESULT"
}
