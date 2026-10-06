# LastPass for Alfred

Search your LastPass vault from Alfred using the official
[`lpass`](https://github.com/lastpass/lastpass-cli) CLI, with automatic logout
after a period of inactivity.

| Key | Action |
| --- | --- |
| `lp <query>` | Search by name, username, site or folder |
| ↩ | Copy password (secure notes: copy the note) |
| ⌘↩ | Copy username |
| ⌥↩ | Open the site |

`lp sync` refreshes the vault; `lp logout` logs out immediately.

## Security

- **Login prompts** (email, master password, MFA code) are native macOS dialogs
  wired in via `LPASS_ASKPASS`. The password is passed straight to `lpass` on
  stdin; it is never written to disk or put on a command line.
- **Copied passwords** are marked `org.nspasteboard.ConcealedType`, so Alfred's
  clipboard history and other well-behaved clipboard managers don't record
  them, and are cleared after 30s unless you've copied something else since.
- **Idle logout:** after logging in, the workflow installs a launchd job
  (`com.chesterleung.alfred-lastpass.autologout`) that runs every 5 minutes.
  Once the workflow hasn't been used for `idle_minutes` (default 60) it runs
  `lpass logout --force`, which removes the local session, encrypted vault
  cache and agent. Using the workflow resets the timer.
- **Backstop:** the `lpass` agent is started with `LPASS_AGENT_TIMEOUT` of 8h,
  so the key is dropped from memory after 8h even if the launchd job isn't
  running. You'd then be asked to unlock with your master password.
- `--trust` and `--plaintext-key` are never used, so each login needs MFA.

Note: the idle timer only counts use of this workflow. If you use `lpass` from
a terminal too, the background job will still log it out once the workflow has
been idle for `idle_minutes`.

## Install

1. Install `lpass` (`nix profile install nixpkgs#lastpass-cli`, or
   `brew install lastpass-cli`).
2. `./build.sh install` copies the workflow into Alfred's preferences, or
   `./build.sh` builds `dist/LastPass.alfredworkflow` to double-click.
3. Type `lp` and choose **Log in to LastPass**.

## Settings

Workflow variables (Alfred Preferences → the workflow → **[𝑥]**):

| Variable | Default | |
| --- | --- | --- |
| `lastpass_keyword` | `lp` | Alfred keyword |
| `idle_minutes` | `60` | Log out after this long without use (applied at next login) |
| `clear_clipboard_seconds` | `30` | `0` disables clearing |
| `lastpass_email` | | Pre-fills the login dialog |
| `lpass_path` | | Only needed if `lpass` isn't in Nix/Homebrew default locations |

## Uninstall the idle-logout job

    launchctl bootout gui/$(id -u)/com.chesterleung.alfred-lastpass.autologout
    rm ~/Library/LaunchAgents/com.chesterleung.alfred-lastpass.autologout.plist
