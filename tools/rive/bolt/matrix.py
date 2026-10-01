#!/usr/bin/env python3
"""matrix.py - render every stage x mood x frame, assemble strips, motion board,
measure per-mood motion %, encode mp4s. Owned by the Bolt animator."""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
RIVE = os.path.join(ROOT, "tools", "rive", "bin", "rive")
PROJ = HERE
OUT = os.path.join(ROOT, "design", "animations", "rive", "bolt")
FR = os.path.join(OUT, "frames")

MOODS = {"idle": 0, "happy": 1, "eating": 2, "sleepy": 3, "surprised": 4,
         "proud": 5, "evolve": -1}
DUR = {"idle": 180, "happy": 72, "eating": 108, "sleepy": 240,
       "surprised": 48, "proud": 72, "evolve": 90}
PCTS = [0, 15, 30, 45, 60, 75, 90]


def advances(mood):
    d = DUR[mood]
    return [max(1, round(d * p / 100)) for p in PCTS]


def render(stage, mood, adv, path, extra=()):
    cmd = [RIVE, PROJ, f"--artboard=Stage{stage}", f"--screenshot={path}",
           f"--advance={adv}"]
    if MOODS[mood] >= 0:
        cmd.append(f"--data=mood={MOODS[mood]}")
    else:
        cmd.append("--data=evolve=1")
    cmd += list(extra)
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(path):
        print("RENDER FAIL", stage, mood, adv, r.stderr[-500:])
        sys.exit(1)


def main():
    os.makedirs(FR, exist_ok=True)
    only = sys.argv[1:] or None
    for stage in (1, 2, 3, 4):
        for mood in MOODS:
            if only and mood not in only:
                continue
            for k, adv in enumerate(advances(mood)):
                path = os.path.join(FR, f"s{stage}_{mood}_{k}.png")
                if os.path.exists(path):
                    continue
                render(stage, mood, adv, path)
                print(f"  s{stage} {mood} f{adv}", flush=True)
    print("matrix done")


if __name__ == "__main__":
    main()
