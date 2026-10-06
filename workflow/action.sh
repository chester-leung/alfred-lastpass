#!/bin/bash
# Runs the action chosen in Alfred. $action comes from the item's variables;
# $1 is the account id for vault items.
source ./lib.sh

clear_secs="${clear_clipboard_seconds:-30}"

# Copies stdin to the clipboard. Secrets are marked concealed so clipboard
# managers (including Alfred's history) skip them, and are cleared after
# $clear_secs unless something else has been copied since.
copy() {  # copy <conceal|plain> <label>
    local count
    count=$(osascript -l JavaScript clip.js "$1") || true
    if [ -z "$count" ]; then notify "No $2 for this item"; return; fi
    if [ "$1" = conceal ] && [ "$clear_secs" -gt 0 ]; then
        nohup osascript -l JavaScript clear.js "$count" "$clear_secs" >/dev/null 2>&1 &
        notify "Copied $2 (clears in ${clear_secs}s)"
    else
        notify "Copied $2"
    fi
}

# Installs (or refreshes) the launchd job that logs out after idle time.
install_autologout() {
    local dir="$HOME/Library/Application Support/alfred-lastpass"
    local plist="$HOME/Library/LaunchAgents/$LABEL.plist"
    local idle=$(( ${idle_minutes:-60} * 60 ))
    mkdir -p "$dir" "$HOME/Library/LaunchAgents"
    cp autologout.sh "$dir/autologout.sh"
    rm -f "$plist"
    /usr/libexec/PlistBuddy \
        -c "Add :Label string $LABEL" \
        -c "Add :ProgramArguments array" \
        -c "Add :ProgramArguments:0 string /bin/bash" \
        -c "Add :ProgramArguments:1 string $dir/autologout.sh" \
        -c "Add :ProgramArguments:2 string $LPASS" \
        -c "Add :ProgramArguments:3 string $LAST_USED" \
        -c "Add :ProgramArguments:4 integer $idle" \
        -c "Add :StartInterval integer 300" \
        -c "Add :RunAtLoad bool true" \
        "$plist" >/dev/null
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
    launchctl bootstrap "gui/$(id -u)" "$plist"
}

login() {
    local email="${lastpass_email:-$(cat "$DATA/email" 2>/dev/null)}"
    email=$(osascript - "$email" <<'EOF'
on run argv
    tell me to activate
    set r to display dialog "LastPass email" default answer (item 1 of argv) ¬
        with title "LastPass" buttons {"Cancel", "Log in"} default button "Log in" cancel button "Cancel"
    return text returned of r
end run
EOF
    ) || exit 0
    [ -n "$email" ] || exit 0
    echo "$email" >"$DATA/email"

    local out ok=0
    # --trust skips MFA on later logins from this Mac; without it some MFA
    # accounts log in but can't download the vault ("Unable to fetch blob").
    local trust=()
    [ "${trust_device:-1}" = 1 ] && trust=(--trust)
    out=$("$LPASS" login "${trust[@]}" --color=never "$email" </dev/null 2>&1) && ok=1
    rm -f "${TMPDIR:-/tmp}"/alfred-lastpass-askpass.*
    if (( ok )); then
        touch_used
        install_autologout
        notify "Logged in. Auto-logout after ${idle_minutes:-60} min idle."
    elif [[ "$out" == *askpass* ]]; then
        # askpass exits non-zero on Cancel or after 3 rejected attempts.
        notify "Login cancelled. If LastPass keeps rejecting it, run: lpass login $email"
    else
        notify "Login failed: $(echo "$out" | tail -1)"
    fi
}

case "$action" in
    login) login ;;
    unlock)
        if "$LPASS" ls --sync=no </dev/null >/dev/null 2>&1; then
            touch_used
            install_autologout
            notify "Unlocked"
        else
            login
        fi
        ;;
    logout)
        "$LPASS" logout --force </dev/null >/dev/null 2>&1
        notify "Logged out"
        ;;
    sync)
        if "$LPASS" sync </dev/null >/dev/null 2>&1; then notify "Vault synced"; else notify "Sync failed"; fi
        ;;
    password | notes)
        touch_used
        "$LPASS" show --sync=no --color=never "--$action" "$1" </dev/null 2>/dev/null | copy conceal "$action"
        ;;
    username)
        touch_used
        "$LPASS" show --sync=no --color=never --username "$1" </dev/null 2>/dev/null | copy plain username
        ;;
    url)
        touch_used
        url=$("$LPASS" show --sync=no --color=never --url "$1" </dev/null 2>/dev/null)
        [ -n "$url" ] && open "$url"
        ;;
esac
