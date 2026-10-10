"""Writes workflow/info.plist for the LastPass Alfred workflow."""
import os
import plistlib

SF, RUN = "B2E0C1AB-0001-4000-8000-000000000001", "B2E0C1AB-0002-4000-8000-000000000002"
CMD, ALT = 1048576, 524288

info = {
    "bundleid": "com.chesterleung.lastpass",
    "name": "LastPass",
    "description": "Search your LastPass vault with lpass, with idle auto-logout",
    "createdby": "Chester Leung",
    "category": "Productivity",
    "readme": "`lp` searches your vault. ↩ copies the password (concealed, cleared after 30s), "
              "⌘↩ copies the username, ⌥↩ opens the URL. Logs out of lpass automatically "
              "after `idle_minutes` without use.",
    "webaddress": "https://github.com/chester-leung/alfred-lastpass",
    "disabled": False,
    "version": os.environ.get("VERSION", "1.0"),  # CI passes it from the tag
    "objects": [
        {"uid": SF, "type": "alfred.workflow.input.scriptfilter", "version": 3, "config": {
            "keyword": "{var:lastpass_keyword}", "withspace": True, "argumenttype": 1,
            "argumenttrimmode": 0, "argumenttreatemptyqueryasnil": True,
            "title": "Search LastPass", "subtext": "", "runningsubtext": "Reading vault…",
            "type": 0, "script": "./list.sh", "scriptfile": "", "scriptargtype": 1, "escaping": 102,
            "alfredfiltersresults": True, "alfredfiltersresultsmatchmode": 0,
            "queuemode": 1, "queuedelaymode": 0, "queuedelaycustom": 3, "queuedelayimmediatelyinitially": True,
        }},
        {"uid": RUN, "type": "alfred.workflow.action.script", "version": 2, "config": {
            "type": 0, "scriptargtype": 1, "escaping": 102, "concurrently": False, "scriptfile": "",
            "script": './action.sh "$1"',
        }},
    ],
    "connections": {
        SF: [
            {"destinationuid": RUN, "modifiers": 0, "modifiersubtext": "", "vitoclose": False},
            {"destinationuid": RUN, "modifiers": CMD, "modifiersubtext": "", "vitoclose": False},
            {"destinationuid": RUN, "modifiers": ALT, "modifiersubtext": "", "vitoclose": False},
        ],
    },
    "uidata": {SF: {"xpos": 50, "ypos": 50}, RUN: {"xpos": 300, "ypos": 50}},
    "variables": {
        "lastpass_keyword": "lp",
        "idle_minutes": "60",
        "clear_clipboard_seconds": "30",
        "lastpass_email": "",
        "trust_device": "1",
        "lpass_path": "",
    },
    "variablesdontexport": ["lastpass_email", "lpass_path"],
}
with open("workflow/info.plist", "wb") as f:
    plistlib.dump(info, f)
