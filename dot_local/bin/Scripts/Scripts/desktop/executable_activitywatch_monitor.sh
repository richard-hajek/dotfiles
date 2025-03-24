#!/usr/bin/env bash

filter_url="$1"
datetime_from=`date --date 'month ago' --iso-8601=seconds`
datetime_to=`date --date 'now' --iso-8601=seconds`

API_URL='http://localhost:5600/api/0/buckets/aw-watcher-web-firefox/events'

cache_file=/tmp/activity_watch_result_`date +'%Y-%m-%d-%H-%M'`.json

if [[ ! -f $cache_file ]]; then
  curl -s -X GET --data-urlencode "end=${datetime_to}" --data-urlencode "start=${datetime_from}" $API_URL -H "accept: application/json" > $cache_file
fi

jq '.[] | select(.data.url | startswith("'$filter_url'")) | .duration' $cache_file | paste -sd+ | bc
