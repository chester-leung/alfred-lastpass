# LastPass for Alfred

Search your LastPass vault from Alfred using the official
[`lpass`](https://github.com/lastpass/lastpass-cli) CLI, with automatic logout
after a period of inactivity.

**[DOWNLOAD](https://github.com/chester-leung/alfred-lastpass/releases/latest)**

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
- Logins use `--trust` by default, marking this Mac as a trusted device so
  later logins need only the master password (like "trust this device" in the
  browser). Some MFA-enabled accounts otherwise log in but fail to download the
  vault with "Unable to fetch blob" (lastpass-cli
  [#510](https://github.com/lastpass/lastpass-cli/issues/510)). Set
  `trust_device` to `0` to require MFA on every login.
- `--plaintext-key` is never used: the decryption key only lives in the agent's memory.

Note: the idle timer only counts use of this workflow. If you use `lpass` from
a terminal too, the background job will still log it out once the workflow has
been idle for `idle_minutes`.

## Install

1. Install `lpass` (`nix profile install nixpkgs#lastpass-cli`, or
   `brew install lastpass-cli`).
2. [Download `LastPass.alfredworkflow`](https://github.com/chester-leung/alfred-lastpass/releases/latest)
   and double-click it. From a clone, `./build.sh install` copies the workflow
   into Alfred's preferences instead.
3. Type `lp` and choose **Log in to LastPass**.

If login keeps getting rejected, run `LPASS_DISABLE_PINENTRY=1 lpass login --trust <email>`
in a terminal: it shows LastPass's actual error, which `lpass` doesn't pass to
the dialog. A session started there works with the workflow too, but the
idle-logout job is only installed by logging in (or unlocking) through Alfred.

## Settings

Workflow variables (Alfred Preferences → the workflow → **[𝑥]**):

| Variable | Default | |
| --- | --- | --- |
| `lastpass_keyword` | `lp` | Alfred keyword |
| `idle_minutes` | `60` | Log out after this long without use (applied at next login) |
| `clear_clipboard_seconds` | `30` | `0` disables clearing |
| `lastpass_email` | | Pre-fills the login dialog |
| `trust_device` | `1` | `0` = don't use `--trust`, so every login needs MFA |
| `lpass_path` | | Only needed if `lpass` isn't in Nix/Homebrew default locations |

## Uninstall the idle-logout job

    launchctl bootout gui/$(id -u)/com.chesterleung.alfred-lastpass.autologout
    rm ~/Library/LaunchAgents/com.chesterleung.alfred-lastpass.autologout.plist
