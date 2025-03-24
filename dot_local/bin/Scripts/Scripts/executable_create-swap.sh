#!/usr/bin/env bash


sudo dd if=/dev/zero of=/swapfile bs=1M count=8k status=progress
sudo chmod 0600 /swapfile
sudo mkswap -U clear /swapfile
sudo swapon /overlayfs/overlay/upperdirs/os/swapfile
