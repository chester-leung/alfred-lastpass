#!/bin/sh
# Builds dist/LastPass.alfredworkflow.
#   ./build.sh           build and package
#   ./build.sh install   also copy straight into Alfred's preferences
set -e
cd "$(dirname "$0")"
mkdir -p dist
chmod +x workflow/*.sh
python3 make_workflow.py

# Icon comes from a locally installed LastPass Firefox extension (not
# redistributed in the repo or the package).
for xpi in "$HOME"/Library/Application\ Support/Firefox/Profiles/*/extensions/support@lastpass.com.xpi; do
  [ -f "$xpi" ] || continue
  unzip -p "$xpi" images/icon-512.png > workflow/icon.png.tmp &&
    sips -Z 256 workflow/icon.png.tmp --out workflow/icon.png >/dev/null
  rm -f workflow/icon.png.tmp
  break
done
rm -f dist/LastPass.alfredworkflow
(cd workflow && zip -q ../dist/LastPass.alfredworkflow info.plist *.sh *.js)
echo "built dist/LastPass.alfredworkflow"

if [ "$1" = install ]; then
  PREFS=$(defaults read com.runningwithcrayons.Alfred-Preferences syncfolder 2>/dev/null | sed "s|^~|$HOME|")
  DEST="${PREFS:-$HOME/Library/Application Support/Alfred}/Alfred.alfredpreferences/workflows/user.workflow.lastpass"
  mkdir -p "$DEST"
  cp workflow/info.plist workflow/*.sh workflow/*.js "$DEST/"
  [ -f workflow/icon.png ] && cp workflow/icon.png "$DEST/"
  echo "installed to $DEST"
fi
