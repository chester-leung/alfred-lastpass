#!/bin/bash
# Run by launchd every 5 minutes (installed on login by action.sh):
#   autologout.sh <lpass> <last_used file> <idle seconds>
# Logs out of lpass (removing the local session, cache and agent) once the
# workflow hasn't been used for <idle seconds>.
LPASS=$1 LAST_USED=$2 IDLE=$3
[ -x "$LPASS" ] || exit 0

last=$(stat -f %m "$LAST_USED" 2>/dev/null || echo 0)
(( $(date +%s) - last < IDLE )) && exit 0

home="${LPASS_HOME:-$HOME/.lpass}"
[ -e "$home/verify" ] || [ -e "$home/blob" ] || ls "$home"/session_* >/dev/null 2>&1 || exit 0

"$LPASS" logout --force </dev/null >/dev/null 2>&1
osascript -e 'display notification "Logged out after inactivity" with title "LastPass"' >/dev/null 2>&1
