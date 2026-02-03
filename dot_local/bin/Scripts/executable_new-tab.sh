#!/usr/bin/env bash

# exec >> /tmp/kitty_script.log 2>&1

kpid=$(pgrep 'kitty')
if [[ ! -z "${kpid}" ]] ; then
    kitten @ --to unix:$(echo -n ${HOME}/.cache/mykitty.sock-${kpid} )  launch --type tab & disown
else
    kitty & disown
fi

