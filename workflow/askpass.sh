#!/bin/bash
# LPASS_ASKPASS helper: lpass passes a prompt ("Master Password", "Code", ...)
# and reads the answer from stdout. The answer never touches disk or argv.
exec osascript - "$*" <<'EOF'
on run argv
    tell me to activate
    set r to display dialog (item 1 of argv) default answer "" with hidden answer ¬
        with title "LastPass" buttons {"Cancel", "OK"} default button "OK" cancel button "Cancel"
    return text returned of r
end run
EOF
