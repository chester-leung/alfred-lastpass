#!/bin/bash
# Script Filter: emits Alfred JSON for the vault, or a login/unlock item.
source ./lib.sh

if [ -z "$LPASS" ]; then
    exec osascript -l JavaScript list.js missing
fi
if ! unlocked; then
    if has_session; then exec osascript -l JavaScript list.js unlock; fi
    exec osascript -l JavaScript list.js login
fi

touch_used

# Listing uses the local cache for speed; refresh it in the background
# at most every 15 minutes.
stamp="$DATA/last_sync"
if [ -z "$(find "$stamp" -mmin -15 2>/dev/null)" ]; then
    touch "$stamp"
    "$LPASS" sync --background </dev/null >/dev/null 2>&1
fi

US=$'\x1f'
"$LPASS" ls --sync=no --color=never --format="%ai$US%an$US%au$US%al$US%/as%/ag" </dev/null 2>/dev/null |
    osascript -l JavaScript list.js list
