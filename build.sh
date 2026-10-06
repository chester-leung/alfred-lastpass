#!/bin/sh
# Builds dist/LastPass.alfredworkflow.
#   ./build.sh           build and package
#   ./build.sh install   also copy straight into Alfred's preferences
set -e
cd "$(dirname "$0")"
mkdir -p dist
chmod +x workflow/*.sh
python3 make_workflow.py
rm -f dist/LastPass.alfredworkflow
(cd workflow && zip -q ../dist/LastPass.alfredworkflow info.plist *.sh *.js)
echo "built dist/LastPass.alfredworkflow"

if [ "$1" = install ]; then
  PREFS=$(defaults read com.runningwithcrayons.Alfred-Preferences syncfolder 2>/dev/null | sed "s|^~|$HOME|")
  DEST="${PREFS:-$HOME/Library/Application Support/Alfred}/Alfred.alfredpreferences/workflows/user.workflow.lastpass"
  mkdir -p "$DEST"
  cp workflow/info.plist workflow/*.sh workflow/*.js "$DEST/"
  echo "installed to $DEST"
fi
