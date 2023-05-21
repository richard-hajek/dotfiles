#!/usr/bin/env bash

picom &

if hash obsidian &> /dev/null; then
  obsidian &
fi

wallpaper-select
setxkbmap cz -variant coder

if hash numlockx &> /dev/null; then
  numlockx on
fi

if hash wal &> /dev/null; then
	wal -e --theme sexy-gjm --vte > /dev/null
fi

bash ~/.config/polybar/launch_polybar.sh
bash ~/.xprofile
