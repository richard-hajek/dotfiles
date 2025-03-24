#!/usr/bin/env bash

set -eu

host=${1:-proxmox.lan}

if [[ $UID == 0 ]]; then
  mkdir -p /media/meowxiik/Cloud
  mkdir -p /media/meowxiik/Archive
  chown meowxiik:meowxiik /media/meowxiik/Cloud
  chown meowxiik:meowxiik /media/meowxiik/Archive
  chown meowxiik:meowxiik /media/meowxiik/
  exit
fi

sudo bash $0

if [[ "$host" == "proxmox.lan" ]]; then
    if ! nmcli c show --active | grep -q "MeownetV4"; then
        nmcli connection up MeownetV4
        sleep 1
    fi
fi

sshfs root@$host:/media/CloudPlus/ /media/meowxiik/Cloud
sshfs root@$host:/media/Archive/ /media/meowxiik/Archive
