#!/usr/bin/env bash

youtube=`activitywatch_monitor.sh 'https://www.youtube.com'`
netflix=`activitywatch_monitor.sh 'https://www.netflix.com'`
disneyplus=`activitywatch_monitor.sh 'https://www.disneyplus.com'`
reddit=`activitywatch_monitor.sh 'https://www.reddit.com'`

total=`echo "$youtube + $netflix + $disneyplus + $reddit" | bc`

echo "yt: $youtube, netf: $netflix, dp: $disneyplus, reddit: $reddit, total: $total" >&2

echo MEDIA `date -d@$total -u +%d%H:%M:%S`
