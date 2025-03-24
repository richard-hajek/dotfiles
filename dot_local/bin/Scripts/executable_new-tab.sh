#!/bin/bash

exec >> /tmp/kitty_script.log 2>&1

if pgrep -x "kitty" > /dev/null; then
    kitten @ --to unix:$(echo -n /tmp/mykitty.sock* )  launch --type tab & disown
else
    /usr/bin/kitty & disown
fi

