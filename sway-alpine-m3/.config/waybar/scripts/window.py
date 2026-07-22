#!/usr/bin/env python3
import json
import sys


def get_focused_name(tree):
    """Walk sway tree BFS to find the focused window's name."""
    q = [tree]
    while q:
        n = q.pop(0)
        if n.get("focused"):
            return n.get("name")
        q.extend(n.get("nodes", []))
        q.extend(n.get("floating_nodes", []))
    return None


try:
    tree = json.load(sys.stdin)
    name = get_focused_name(tree)
    print(("󰋼  " + name) if name else "󰋼  Desktop")
except (json.JSONDecodeError, OSError):
    print("󰋼  Desktop", file=sys.stderr)
    print("󰋼  Desktop")
