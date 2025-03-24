#!/bin/bash

# Function to check network connectivity
check_connectivity() {
    ping -c 1 google.com > /dev/null 2>&1
    return $?
}

# Main loop
while true; do
    if check_connectivity; then
        echo "$(date): Connectivity is fine."
    else
        echo "$(date): Connectivity lost. Cycling wifi..."
        nmcli networking off
        sleep 2
        nmcli networking on
        echo "$(date): wifi cycled"
        sleep 5
    fi
    sleep 30
done

