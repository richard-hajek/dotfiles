#!/usr/bin/env bash

if ! nmcli c show --active | grep -q "MeownetV4"; then
    nmcli connection up MeownetV4
fi

sleep 10

mkdir -p ~/Cloud/Models/x_TEXTURES
sshfs ~/Cloud/Models/x_TEXTURES data.lan:/mnt/Cloud/CloudRemote/Models/x_TEXTURES
