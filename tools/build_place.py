#!/usr/bin/env python3
"""Build RecipeForDisaster.rbxlx from the Rojo-style src/ tree.

Layout rules (same as Rojo):
  Folder            -> Folder (or ModuleScript if it holds init.luau)
  Name.server.luau  -> Script
  Name.client.luau  -> LocalScript
  Name.luau         -> ModuleScript
"""
import os
import sys
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")

SERVICES = {
    "ReplicatedStorage": {},
    "ServerScriptService": {},
    "ServerStorage": {},
    "StarterPlayer": {},
    "StarterGui": {},
    "Workspace": {"StreamingEnabled": ("bool", "true")},
    "Players": {"CharacterAutoLoads": ("bool", "false")},
    "SoundService": {},
}

_ref = [0]


def ref():
    _ref[0] += 1
    return "RBX%08X" % _ref[0]


def prop(kind, name, value):
    if kind == "ProtectedString":
        value = value.replace("]]>", "]]]]><![CDATA[>")
        return '<ProtectedString name="%s"><![CDATA[%s]]></ProtectedString>' % (name, value)
    return '<%s name="%s">%s</%s>' % (kind, name, escape(value), kind)


def item(cls, name, props=None, children=None):
    out = ['<Item class="%s" referent="%s"><Properties>' % (cls, ref())]
    out.append(prop("string", "Name", name))
    for k, (kind, v) in (props or {}).items():
        out.append(prop(kind, k, v))
    out.append("</Properties>")
    for c in children or []:
        out.append(c)
    out.append("</Item>")
    return "".join(out)


def read(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


SPECIAL_CLASSES = {"StarterPlayerScripts": "StarterPlayerScripts", "StarterCharacterScripts": "StarterCharacterScripts"}


def build_entry(full):
    entry = os.path.basename(full)
    if entry.startswith("."):
        return None
    if os.path.isdir(full):
        init = None
        for cand in ("init.luau", "init.server.luau", "init.client.luau"):
            if os.path.exists(os.path.join(full, cand)):
                init = cand
        if init:
            cls = {"init.luau": "ModuleScript", "init.server.luau": "Script", "init.client.luau": "LocalScript"}[init]
            kids = [build_entry(os.path.join(full, e)) for e in sorted(os.listdir(full)) if e != init]
            return item(cls, entry, {"Source": ("ProtectedString", read(os.path.join(full, init)))}, [k for k in kids if k])
        return item(SPECIAL_CLASSES.get(entry, "Folder"), entry, None, build_dir(full))
    if entry.endswith(".server.luau"):
        return item("Script", entry[: -len(".server.luau")], {"Source": ("ProtectedString", read(full))})
    if entry.endswith(".client.luau"):
        return item("LocalScript", entry[: -len(".client.luau")], {"Source": ("ProtectedString", read(full))})
    if entry.endswith(".luau"):
        return item("ModuleScript", entry[: -len(".luau")], {"Source": ("ProtectedString", read(full))})
    return None


def build_dir(path):
    """Return list of xml Items for the contents of a directory."""
    items = [build_entry(os.path.join(path, e)) for e in sorted(os.listdir(path))]
    return [i for i in items if i]


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "RecipeForDisaster.rbxlx")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    parts = [
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
        "<External>null</External><External>nil</External>",
    ]
    for svc, props in SERVICES.items():
        svc_dir = os.path.join(SRC, svc)
        children = build_dir(svc_dir) if os.path.isdir(svc_dir) else []
        parts.append(item(svc, svc, props, children))
    parts.append("</roblox>")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("".join(parts))
    print("wrote", out_path, os.path.getsize(out_path), "bytes")


if __name__ == "__main__":
    main()
