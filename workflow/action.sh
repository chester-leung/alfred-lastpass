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

# Writes a launchd job from PlistBuddy commands and (re)starts it.
load_job() {  # load_job <label> <PlistBuddy -c commands...>
    local label=$1 plist="$HOME/Library/LaunchAgents/$1.plist" args=() c
    shift
    for c in "Add :Label string $label" "$@"; do args+=(-c "$c"); done
    mkdir -p "$HOME/Library/LaunchAgents"
    rm -f "$plist"
    /usr/libexec/PlistBuddy "${args[@]}" "$plist" >/dev/null
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null
    launchctl bootstrap "gui/$(id -u)" "$plist"
}

# Installs (or refreshes) the launchd jobs that lock after idle time and when
# the screen locks or the Mac sleeps.
install_autologout() {
    local dir="$HOME/Library/Application Support/alfred-lastpass"
    local idle=$(( ${idle_minutes:-60} * 60 ))
    mkdir -p "$dir"
    cp autologout.sh lockwatch.js "$dir/"
    load_job "$LABEL" \
        "Add :ProgramArguments array" \
        "Add :ProgramArguments:0 string /bin/bash" \
        "Add :ProgramArguments:1 string $dir/autologout.sh" \
        "Add :ProgramArguments:2 string $LPASS" \
        "Add :ProgramArguments:3 string $LAST_USED" \
        "Add :ProgramArguments:4 string $idle" \
        "Add :StartInterval integer 300" \
        "Add :RunAtLoad bool true"
    load_job "$LOCK_LABEL" \
        "Add :ProgramArguments array" \
        "Add :ProgramArguments:0 string /usr/bin/osascript" \
        "Add :ProgramArguments:1 string -l" \
        "Add :ProgramArguments:2 string JavaScript" \
        "Add :ProgramArguments:3 string $dir/lockwatch.js" \
        "Add :KeepAlive bool true" \
        "Add :RunAtLoad bool true"
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
        notify "Logged in. Locks after ${idle_minutes:-60} min idle."
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
