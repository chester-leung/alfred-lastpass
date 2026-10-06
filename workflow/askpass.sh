#!/bin/bash
# LPASS_ASKPASS helper: lpass passes a prompt ("Master Password", "Code", ...)
# and reads the answer from stdout. The answer never touches disk or argv.
#
# When LastPass rejects a login, lpass re-prompts forever without saying why,
# so count attempts per lpass process ($PPID) and give up after 3.
counter="${TMPDIR:-/tmp}/alfred-lastpass-askpass.$PPID.${1// /_}"
n=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 ))
echo "$n" >"$counter"
if (( n > 3 )); then
    rm -f "$counter"
    exit 1
fi
prompt="$*"
(( n > 1 )) && prompt="LastPass rejected that attempt. $prompt (try $n of 3)"

exec osascript - "$prompt" <<'EOF'
on run argv
    tell me to activate
    set r to display dialog (item 1 of argv) default answer "" with hidden answer ¬
        with title "LastPass" buttons {"Cancel", "OK"} default button "OK" cancel button "Cancel"
    return text returned of r
end run
EOF
