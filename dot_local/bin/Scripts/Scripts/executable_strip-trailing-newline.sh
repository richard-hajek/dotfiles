#!/usr/bin/env bash

if [[ $# != 1 ]]; then
	echo Usage: $0 \<path\>
	exit 1
fi

sed -i '$s/\n$//' $1
