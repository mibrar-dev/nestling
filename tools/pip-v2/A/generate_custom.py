#!/usr/bin/env python3
"""Emit s3 idle skin x accessory combos to tmp dir for BOARD_custom."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate import render_bird, SKINS

tmp = sys.argv[1]
os.makedirs(tmp, exist_ok=True)
for sk in SKINS:
    for ac in ("none", "bow", "cap", "scarf", "glasses"):
        open(os.path.join(tmp, f"s3_idle_{sk}_{ac}.svg"), "w").write(render_bird(3, "idle", 1, skin=sk, acc=ac))
print("combos done")
