#!/bin/bash
# switch-to-windows.sh - Run on macOS to reboot into Windows
# Requires: brew install cliclick

set -e

MACOS_PASSWORD="${MACOS_PASSWORD:-YOUR_PASSWORD_HERE}"

if ! command -v cliclick &> /dev/null; then
    echo "ERROR: cliclick not found. Install with: brew install cliclick"
    exit 1
fi

echo "Opening Startup Disk preferences..."
open "x-apple.systempreferences:com.apple.preference.startupdisk"
sleep 3

osascript -e '
tell application "System Settings"
    activate
    set bounds of window 1 to {0, 25, 800, 600}
end tell
'
sleep 1

echo "Selecting BOOTCAMP..."
cliclick c:400,300
sleep 1
cliclick c:400,350
sleep 2

echo "Clicking Restart..."
cliclick c:400,500
sleep 1

echo "Entering password..."
cliclick t:"$MACOS_PASSWORD"
cliclick kp:return
sleep 2

echo "Rebooting..."
osascript -e "do shell script \"reboot\" with administrator privileges password \"$MACOS_PASSWORD\""
