# Shared setup for the LastPass workflow scripts. Sourced from the workflow dir.
set -o pipefail

DATA="${alfred_workflow_data:-$HOME/Library/Application Support/alfred-lastpass}"
mkdir -p "$DATA"
LAST_USED="$DATA/last_used"
LABEL="com.chesterleung.alfred-lastpass.autologout"

# Alfred runs scripts with a minimal PATH, so look in the usual install spots.
find_lpass() {
    local p
    for p in "$lpass_path" "$(command -v lpass)" \
        "$HOME/.nix-profile/bin/lpass" "/etc/profiles/per-user/$(id -un)/bin/lpass" \
        /run/current-system/sw/bin/lpass /opt/homebrew/bin/lpass /usr/local/bin/lpass; do
        [ -n "$p" ] && [ -x "$p" ] && { echo "$p"; return; }
    done
}
LPASS=$(find_lpass)

# Master password and MFA prompts go through a native dialog.
export LPASS_ASKPASS="$PWD/askpass.sh"
export LPASS_DISABLE_PINENTRY=1
# Hard cap on how long the agent holds the decryption key, regardless of use.
# Idle logout (autologout.sh) normally kicks in long before this.
export LPASS_AGENT_TIMEOUT=$((8 * 3600))

touch_used() { touch "$LAST_USED"; }

# True if lpass has a saved session on disk, even if the agent has quit.
has_session() {
    local home="${LPASS_HOME:-$HOME/.lpass}"
    [ -e "$home/verify" ] || [ -e "$home/blob" ] || ls "$home"/session_* >/dev/null 2>&1
}

# True if the agent is running and holding the key. Never prompts.
unlocked() { env -u LPASS_ASKPASS "$LPASS" status -q </dev/null >/dev/null 2>&1; }

notify() {
    osascript - "$1" <<'EOF' >/dev/null 2>&1
on run argv
    display notification (item 1 of argv) with title "LastPass"
end run
EOF
}
