#!/bin/bash
# Run by launchd every 5 minutes (installed on login by action.sh):
#   autologout.sh <lpass> <last_used file> <idle seconds>
# Locks lpass (stops the agent holding the decryption key) once the workflow
# hasn't been used for <idle seconds>. The session stays on disk, so the next
# use only asks for the master password.
LPASS=$1 LAST_USED=$2 IDLE=$3
[ -x "$LPASS" ] || exit 0

last=$(stat -f %m "$LAST_USED" 2>/dev/null || echo 0)
(( $(date +%s) - last < IDLE )) && exit 0

pkill -TERM -U "$(id -u)" -f '^lpass \[agent\]' || exit 0
osascript -e 'display notification "Locked after inactivity" with title "LastPass"' >/dev/null 2>&1
