#!/usr/bin/env bash

# exec >> /tmp/kitty_script.log 2>&1

if pgrep "kitty" > /dev/null; then
    kitten @ --to unix:$(echo -n ${HOME}/.cache/mykitty.sock* )  launch --type tab & disown
else
    kitty & disown
fi

