#!/bin/bash

POLYBAR_DIR=$(echo ~/.config/polybar)

${POLYBAR_DIR}/modules/traffic.sh wlp3s0 | grep "Current speed" | sed 's/Current speed: //g'
