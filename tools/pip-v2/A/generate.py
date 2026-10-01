#!/usr/bin/env python3
"""Mochi (style A) pose library generator — 100% original art.
Writes design/pip-v2/A/{poses,skins,accessories,evolve}/ with exact contract group ids.
Canvas 0 0 240 240, baseline y=214, ink #1E1B3A, stroke 6, one soft highlight only.
"""
import os

ROOT = "/Users/ibrar/Desktop/infinora.noworkspace/nestling-pip-v2"
A = os.path.join(ROOT, "design/pip-v2/A")
INK = "#1E1B3A"
SW = 6
PEACH = "#FF8A5B"
PURPLE = "#7C6CF2"
WHITE = "#FFFFFF"

SKINS = {
    "sunny": ("#FFD93D", "#FFF1B8", "#E8A800"),
    "berry": ("#FF9EBB", "#FFE1EA", "#E0608C"),
    "sky":   ("#8EC9FF", "#E2F1FF", "#4E9AE0"),
    "mint":  ("#8EE3B5", "#DDF8E8", "#3FA67E"),
}

def spark(x, y, s, fill=PURPLE, stroke=None):
    sw = f' stroke="{INK}" stroke-width="3" stroke-linejoin="round"' if stroke else ""
    return (f'<path d="M{x} {y-s} L{x+s*0.22} {y-s*0.22} L{x+s} {y} '
            f'L{x+s*0.22} {y+s*0.22} L{x} {y+s} L{x-s*0.22} {y+s*0.22} '
            f'L{x-s} {y} L{x-s*0.22} {y-s*0.22} Z" fill="{fill}"{sw}/>')

def zzz(x, y, s, op=1.0, col=PURPLE):
    w = s
    return (f'<path d="M{x} {y} L{x+w} {y} L{x} {y+w} L{x+w} {y+w}" fill="none" '
            f'stroke="{col}" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round" opacity="{op}"/>')

def excl(x, y, h=34):
    return (f'<rect x="{x-5}" y="{y}" width="10" height="{h}" rx="5" fill="{PURPLE}" '
            f'stroke="{INK}" stroke-width="4"/><circle cx="{x}" cy="{y+h+12}" r="6" fill="{PURPLE}" stroke="{INK}" stroke-width="4"/>')

def heart(x, y, s):
    return (f'<path d="M{x} {y+s*0.9} C{x-s*1.4} {y} {x-s*0.7} {y-s} {x} {y-s*0.25} '
            f'C{x+s*0.7} {y-s} {x+s*1.4} {y} {x} {y+s*0.9} Z" fill="#FF6B8A" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>')

def seed(x, y, s=7):
    return f'<ellipse cx="{x}" cy="{y}" rx="{s}" ry="{s*1.35}" fill="#C98A3D" stroke="{INK}" stroke-width="3.5" transform="rotate(-18 {x} {y}"/>'

def crumb(x, y, r=3.5):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="#C98A3D" stroke="{INK}" stroke-width="2.5"/>'

# ---------------- eye children ----------------
def eye_open(ex, ey, r, pr, dx=0):
    return (f'<g id="open"><circle cx="{ex}" cy="{ey}" r="{r}" fill="{WHITE}" stroke="{INK}" stroke-width="{SW}"/>'
            f'<circle cx="{ex+dx+2}" cy="{ey+2}" r="{pr}" fill="{INK}"/>'
            f'<circle cx="{ex+dx-1}" cy="{ey-2}" r="{pr*0.34:.1f}" fill="{WHITE}"/></g>')

def eye_closed(ex, ey, r):
    return (f'<g id="closed"><path d="M{ex-r} {ey} Q{ex} {ey+r*0.9} {ex+r} {ey}" fill="none" '
            f'stroke="{INK}" stroke-width="{SW}" stroke-linecap="round"/></g>')

def eye_happy(ex, ey, r):
    return (f'<g id="happy"><path d="M{ex-r} {ey+5} Q{ex} {ey-r-2} {ex+r} {ey+5}" fill="none" '
            f'stroke="{INK}" stroke-width="{SW}" stroke-linecap="round"/></g>')

def eye_sleepy(ex, ey, r):
    return (f'<g id="sleepy"><path d="M{ex-r} {ey-2} Q{ex} {ey+r*0.55} {ex+r} {ey-2}" fill="none" '
            f'stroke="{INK}" stroke-width="7" stroke-linecap="round"/>'
            f'<path d="M{ex-r+1} {ey-1} l-7 5 M{ex+r-1} {ey-1} l7 5" stroke="{INK}" stroke-width="3.5" stroke-linecap="round"/></g>')

def eye_surprised(ex, ey, r, pr=5):
    return (f'<g id="surprised"><circle cx="{ex}" cy="{ey}" r="{r+3}" fill="{WHITE}" stroke="{INK}" stroke-width="{SW}"/>'
            f'<circle cx="{ex}" cy="{ey+1}" r="{pr}" fill="{INK}"/>'
            f'<circle cx="{ex-2}" cy="{ey-2}" r="2" fill="{WHITE}"/></g>')

def eye_wink(ex, ey, r):
    return (f'<g id="wink"><path d="M{ex-r} {ey} Q{ex} {ey+6} {ex+r} {ey}" fill="none" '
            f'stroke="{INK}" stroke-width="{SW}" stroke-linecap="round"/></g>')

EYE_FNS = {"open": eye_open, "closed": eye_closed, "happy": eye_happy,
           "sleepy": eye_sleepy, "surprised": eye_surprised, "wink": eye_wink}

def eye_group(side, ex, ey, r, pr, active, dx=0):
    parts = []
    for name in ("open", "closed", "happy", "sleepy", "surprised", "wink"):
        if name == "open":
            inner = eye_open(ex, ey, r, pr, dx)
        elif name == "wink":
            inner = eye_wink(ex, ey, r)
        else:
            inner = EYE_FNS[name](ex, ey, r) if name != "surprised" else eye_surprised(ex, ey, r)
        if name == active:
            parts.append(inner)
        else:
            parts.append(inner.replace(f'<g id="{name}"', f'<g id="{name}" style="display:none"'))
    return f'<g id="eye_{side}">' + "".join(parts) + "</g>"

# ---------------- stage base geometry ----------------
# returns dict with body/face anchor numbers (pre mood-offset)
def base(stage):
    if stage == 1:
        return dict(kind="egg", cx=120, top=30, w=120, h=172,
                    ex_l=102, ex_r=138, ey=163, er=10, pr=4.5)
    if stage == 2:
        return dict(kind="bird", cx=120, cy=122, rx=42, ry=42,
                    belly=(120, 138, 24, 20), feet=None,
                    ex_l=106, ex_r=134, ey=120, er=11, pr=5,
                    wing="stub", tail=None, tuft="small")
    if stage == 3:
        return dict(kind="bird", cx=120, cy=132, rx=63, ry=60,
                    belly=(120, 157, 39, 33), feet=(99, 141, 195),
                    ex_l=96, ex_r=144, ey=129, er=16, pr=7.5,
                    wing="stub", tail="nub", tuft="mid")
    # stage 4 songbird: taller slimmer pear body, visible neck, crest, long wings/tail
    return dict(kind="pear", cx=120, top=58, bottom=196, w_head=42, w_neck=30, w_body=58, neck_y=120,
                belly=(120, 162, 33, 25), feet=(95, 145, 194),
                ex_l=98, ex_r=142, ey=112, er=15, pr=7,
                wing="s4", tail="fan3", tuft="crest")

def egg_path(cx, top, w, h, wob=0, squash=1.0):
    x0 = cx - w / 2 + wob
    x1 = cx + w / 2 + wob
    my = top + h * squash
    return (f"M{cx+wob} {top} C{cx-w*0.35+wob} {top} {x0} {top+h*0.38} {x0+4} {top+h*0.62} "
            f"C{x0+8} {my-26} {cx-30+wob} {my} {cx+wob} {my} "
            f"C{cx+30+wob} {my} {x1-8} {my-26} {x1-4} {top+h*0.62} "
            f"C{x1} {top+h*0.38} {cx+w*0.35+wob} {top} {cx+wob} {top} Z")

def tuft_svg(stage, cx, top_y, col, big=1.0):
    if stage == 2:
        pts = [(110, 86), (122, 82), (133, 88)]; rr = (7, 8, 6.5)
    else:
        pts = [(102, 68), (120, 60), (138, 68)]; rr = (11, 12.5, 11)
    s = ""
    for (x, y), r in zip(pts, rr):
        s += f'<circle cx="{x}" cy="{y+top_y}" r="{r*big:.1f}" fill="{col}"/>'
    return (f'<g id="head_tuft" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">{s}</g>')

def pear_path(cx, top, bottom, w_head, w_neck, w_body, neck_y, sx=0, dtop=0, dbot=0):
    """Slimmer pear body with a visible neck pinch. sx widens, dtop/dbot slump."""
    top += dtop; bottom += dbot
    wh, wn, wb = w_head + sx, w_neck + sx, w_body + sx
    return (f"M{cx} {top} "
            f"C{cx+wh} {top} {cx+wh+7} {top+36} {cx+wn+8} {neck_y} "
            f"C{cx+wb+7} {neck_y+22} {cx+wb} {bottom-32} {cx} {bottom} "
            f"C{cx-wb} {bottom-32} {cx-wb-7} {neck_y+22} {cx-wn-8} {neck_y} "
            f"C{cx-wh-7} {top+36} {cx-wh} {top} {cx} {top} Z")

def crest_svg(cx, hy, col, tdx=0):
    pts = [(96, 58, 11), (114, 46, 13), (134, 48, 12), (150, 60, 10)]
    s = "".join(f'<circle cx="{x+tdx}" cy="{y+hy}" r="{r}" fill="{col}"/>' for x, y, r in pts)
    return (f'<g id="head_tuft" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">{s}</g>')

# stage-4 long pointed wings: (shoulder, tip, width) per side-mirrored pose
S4_POINT = {
    "s4down":  dict(sx=68, sy=128, tx=46, ty=196, w=19),
    "s4tuck":  dict(sx=66, sy=132, tx=54, ty=168, w=17),
    "s4up":    dict(sx=66, sy=122, tx=26, ty=60, w=21),
    "s4flare": dict(sx=66, sy=122, tx=20, ty=110, w=21),
    "s4droop": dict(sx=66, sy=138, tx=56, ty=176, w=16),
    "s4hip":   dict(sx=64, sy=150, tx=44, ty=158, w=17, front=True),
}

def wing_point_svg(side, cx, P, col):
    sx = cx - P["sx"] if side == "l" else cx + P["sx"]
    tx = cx - P["tx"] if side == "l" else cx + P["tx"]
    sy, ty, w = P["sy"], P["ty"], P["w"]
    import math
    dx, dy = tx - sx, ty - sy
    L = math.hypot(dx, dy) or 1
    nx, ny = -dy / L * w / 2, dx / L * w / 2
    mx, my = (sx + tx) / 2, (sy + ty) / 2
    return (f'<g id="wing_{side}"><path d="M{sx:.1f} {sy} Q{mx+nx:.1f} {my+ny:.1f} {tx} {ty} '
            f'Q{mx-nx:.1f} {my-ny:.1f} {sx:.1f} {sy} Z" fill="{col}" '
            f'stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/></g>')

def wing_svg(side, cx, cy, rx, ry, rot, col):
    x = cx
    return (f'<g id="wing_{side}"><ellipse cx="{x}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{col}" '
            f'stroke="{INK}" stroke-width="{SW}" transform="rotate({rot} {x} {cy})"/></g>')

WING_POSES = {
    # (cx_off_l, cy, rx, ry, rot_l) — mirrored for right
    "down":   dict(cy=143, rx=15, ry=23, rot=-8, off=60),
    "tuck":   dict(cy=152, rx=14, ry=20, rot=-6, off=58),
    "up":     dict(cy=92, rx=15, ry=27, rot=-32, off=76),
    "flare":  dict(cy=130, rx=14, ry=25, rot=-55, off=84),
    "hip":    dict(cy=155, rx=13, ry=20, rot=38, off=52),
    "wave":   dict(cy=100, rx=14, ry=24, rot=-70, off=72),
    "droop":  dict(cy=158, rx=13, ry=17, rot=-4, off=58),
    "hip":    dict(cy=158, rx=16, ry=23, rot=52, off=58, front=True),
    "s2down": dict(cy=128, rx=10, ry=16, rot=-6, off=38),
    "s2hip": dict(cy=140, rx=11, ry=17, rot=50, off=36, front=True),
    "s2up":   dict(cy=92, rx=10, ry=18, rot=-35, off=52),
    "s4down": dict(cy=134, rx=16, ry=27, rot=-6, off=62),
    "s4up":   dict(cy=84, rx=16, ry=30, rot=-30, off=78),
    "s4flare":dict(cy=124, rx=16, ry=29, rot=-55, off=86),
}

def tail_svg(stage, col, pose="rest"):
    if stage in (1, 2):
        return '<g id="tail"></g>'
    if stage == 3:
        if pose == "wag":
            d = "M104 184 L96 204 L112 196 L120 206 L128 196 L144 204 L136 184 Z"
        else:
            d = "M108 186 L112 202 L120 194 L128 202 L132 186 Z"
        return (f'<g id="tail" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">'
                f'<path d="{d}" fill="{col}"/></g>')
    # stage 4: three long tail feathers fanned behind, tips peeking below the feet
    spread = {"rest": (-20, 0, 20), "fan": (-30, 0, 30), "lift": (-24, -6, 24)}.get(pose, (-20, 0, 20))
    parts = []
    for (x, y, r) in ((96, 192, spread[0]), (120, 194, spread[1]), (144, 192, spread[2])):
        parts.append(f'<ellipse cx="{x}" cy="{y}" rx="14" ry="27" fill="{col}" transform="rotate({r} {x} {y})"/>')
    return (f'<g id="tail" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">{"".join(parts)}</g>')

def beak_closed(bx, by, w=28):
    return (f'<g id="beak_top"><path d="M{bx-w//2} {by} Q{bx} {by-5} {bx+w//2} {by} '
            f'Q{bx+w//2-4} {by+11} {bx} {by+13} Q{bx-w//2+4} {by+11} {bx-w//2} {by} Z" '
            f'fill="{PEACH}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/></g>'
            f'<g id="beak_bottom" style="display:none"><ellipse cx="{bx}" cy="{by+8}" rx="10" ry="7"/></g>')

def beak_open(bx, by, w=32, h=22):
    return (f'<g id="beak_top"><path d="M{bx-w//2} {by} Q{bx} {by-6} {bx+w//2} {by} L{bx+w//2-4} {by+4} L{bx-w//2+4} {by+4} Z" '
            f'fill="{PEACH}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/></g>'
            f'<g id="beak_bottom"><ellipse cx="{bx}" cy="{by+h//2+4}" rx="{w//2-3}" ry="{h//2}" fill="{INK}"/>'
            f'<ellipse cx="{bx}" cy="{by+h//2+8}" rx="7" ry="4.5" fill="{PEACH}"/></g>')

def beak_o(bx, by):
    return (f'<g id="beak_top" style="display:none"><path d="M{bx} {by}"/></g>'
            f'<g id="beak_bottom"><ellipse cx="{bx}" cy="{by+6}" rx="11" ry="12" fill="{INK}"/>'
            f'<ellipse cx="{bx}" cy="{by+9}" rx="5" ry="5" fill="{PEACH}"/></g>')

def cheeks(ex_l, ex_r, ey, dy=23, op=0.55, rx=10):
    return (f'<g id="cheek_l"><ellipse cx="{ex_l-21}" cy="{ey+dy}" rx="{rx}" ry="6.5" fill="{PEACH}" opacity="{op}"/></g>'
            f'<g id="cheek_r"><ellipse cx="{ex_r+21}" cy="{ey+dy}" rx="{rx}" ry="6.5" fill="{PEACH}" opacity="{op}"/></g>')

def berry(x, y, r=11):
    return (f'<g><circle cx="{x}" cy="{y}" r="{r}" fill="#E5484D" stroke="{INK}" stroke-width="5"/>'
            f'<circle cx="{x-r*0.35}" cy="{y-r*0.35}" r="{r*0.28:.1f}" fill="{WHITE}" opacity="0.85"/>'
            f'<path d="M{x+r*0.5} {y-r*0.9} q7 -6 13 -3 q-5 7 -13 3 Z" fill="#3FA67E" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/></g>')

def crumb_big(x, y, r=3.5):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="#8B5A2B" stroke="{INK}" stroke-width="2.5"/>'

def beak_snore(bx, by):
    return (f'<g id="beak_top"><path d="M{bx-14} {by} Q{bx} {by-5} {bx+14} {by} '
            f'Q{bx+10} {by+9} {bx} {by+10} Q{bx-10} {by+9} {bx-14} {by} Z" '
            f'fill="{PEACH}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/></g>'
            f'<g id="beak_bottom"><ellipse cx="{bx}" cy="{by+19}" rx="7" ry="8.5" fill="{INK}"/></g>')

def nightcap_svg(cx, hy, tilt=0):
    bx = cx + 8 + tilt
    return (f'<g><path d="M{bx-30} {hy+6} Q{bx-6} {hy-34} {bx+34} {hy-26} Q{bx+44} {hy-22} {bx+40} {hy-10} '
            f'L{bx+6} {hy-2} L{bx-28} {hy-2} Z" fill="{PURPLE}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
            f'<rect x="{bx-32}" y="{hy-4}" width="66" height="13" rx="6.5" fill="{WHITE}" stroke="{INK}" stroke-width="4.5"/>'
            f'<circle cx="{bx+42}" cy="{hy-8}" r="8" fill="{WHITE}" stroke="{INK}" stroke-width="4.5"/></g>')

def feet_svg(stage, dy=0, lift_r=0):
    if stage in (1, 2):
        return '<g id="feet"></g>'
    fy = {3: 195, 4: 194}[stage]
    fx_l, fx_r = {3: (99, 141), 4: (95, 145)}[stage]
    fr = fy + dy + lift_r
    fl = fy + dy
    return (f'<g id="feet" stroke="{INK}" stroke-width="{SW}">'
            f'<ellipse cx="{fx_l}" cy="{fl}" rx="13" ry="8.5" fill="{PEACH}"/>'
            f'<ellipse cx="{fx_r}" cy="{fr}" rx="13" ry="8.5" fill="{PEACH}"/></g>')

def brows(active, ex_l, ex_r, ey, r, kind="none"):
    if kind == "none":
        return '<g id="brow_l"></g><g id="brow_r"></g>'
    if kind == "raise":
        # surprised: short arcs lifted high above the eyes, tilted up-outward
        s = ""
        for side, ex in (("l", ex_l), ("r", ex_r)):
            y = ey - r - 16
            m = 7 if side == "l" else -7
            s += (f'<g id="brow_{side}"><path d="M{ex-12} {y+m} Q{ex} {y-4} {ex+12} {y-m}" fill="none" '
                  f'stroke="{INK}" stroke-width="5" stroke-linecap="round"/></g>')
        return s
    dh = {"worry": -8, "proud": -6, "sleepy": 4}[kind]
    tilt = {"worry": 12, "proud": -8, "sleepy": 0}[kind]
    s = ""
    for side, ex in (("l", ex_l), ("r", ex_r)):
        y = ey - r - 10 + dh
        m = -tilt if side == "r" and kind != "sleepy" else tilt
        s += (f'<g id="brow_{side}"><path d="M{ex-12} {y} L{ex+12} {y+m}" fill="none" '
              f'stroke="{INK}" stroke-width="5" stroke-linecap="round"/></g>')
    return s

HIGHLIGHT = '<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#FFFFFF" opacity="0.55" transform="rotate(-18 {x} {y})"/>'

# ---------------- main bird renderer ----------------
def render_bird(stage, mood, n, skin="sunny", acc="none"):
    B, BEL, W = SKINS[skin]
    b = base(stage)
    dy = 0; squash = (0, 0); tilt_tuft = 0; eye = "open"; beak = "closed"
    wing = "down"; tailp = "rest"; fx = ""; brow = "none"
    hl = True; cheek_op = 0.55; cheek_rx = 10; pupil_dx = 0; lift_r = 0
    tilt = 0  # head lean (sleepy)
    slump = (0, 0, 0)  # pear-only extra (sx, dtop, dbot)
    nightcap = False
    bdy, bdx = 0, 0  # body offset
    if stage == 2:
        wing = "s2down"
    if stage == 4:
        wing = "s4down"

    M = mood
    # ---- idle ----
    if M == "idle":
        if n == 1:
            pass
        else:
            bdy = 2; tilt_tuft = 3; pupil_dx = 1
            squash = (2, -2)
    # ---- blink: neutral idle pose, eyes closed, nothing else ----
    elif M == "blink":
        eye = "closed" if n == 2 else "open"
    # ---- happy ----
    elif M == "happy":
        if n == 1:  # anticipation squash
            squash = (8, -8); bdy = 8; wing = "tuck" if stage > 2 else wing
            eye = "happy"; beak = "closed"; brow = "none"
        elif n == 2:  # peak jump
            dy_jump = -18
            bdy = dy_jump; eye = "happy"; beak = "open"; cheek_op = 0.7
            wing = {"2": "s2up", "3": "up", "4": "s4up"}.get(str(stage), "up")
            tailp = "wag" if stage == 3 else ("fan" if stage == 4 else tailp)
            tilt_tuft = -4
            fx = (spark(34, 60, 12, PURPLE) + spark(206, 60, 10, "#F4B400", True)
                  + spark(48, 108, 7) + spark(192, 108, 7, PEACH)
                  + spark(120, 34, 8, WHITE, True))
        else:  # settle
            squash = (6, -5); bdy = 6; eye = "happy"; beak = "closed"
            wing = "droop" if stage > 2 else wing
            fx = spark(200, 70, 7, PURPLE) + spark(40, 74, 6, "#F4B400", True)
    # ---- eating: big berry approaches → beak open, berry in mouth → crunch + crumbs ----
    elif M == "eating":
        if n == 1:
            eye = "open"; beak = "closed"; pupil_dx = 2
            wing = "tuck" if stage > 2 else wing
        elif n == 2:  # peck: beak open, berry entering the mouth
            bdy = 8; squash = (4, -3); eye = "happy"; beak = "open"
            wing = "droop" if stage > 2 else wing
            cheek_op = 0.7
        else:  # crunch: cheeks puffed, crumbs burst
            eye = "happy"; beak = "closed"; cheek_op = 0.9; cheek_rx = 13; bdy = -2
            wing = "tuck" if stage > 2 else wing
    # ---- sleepy: head tilted + leaning, body slumped (squash ~0.94), heavy lids,
    # small snore mouth, Zzz, nightcap (s3/s4) — asleep even without the Zzz ----
    elif M == "sleepy":
        if n == 1:
            eye = "sleepy"; beak = "closed"; bdy = 5; tilt = 5
            squash = (3, -2); wing = "droop" if stage > 2 else wing
        elif n == 2:
            eye = "closed"; beak = "snore"; bdy = 9; tilt = 10
            squash = (5, -4); slump = (3, 3, -2); tilt_tuft = 5
            wing = "droop" if stage > 2 else wing
            nightcap = stage in (3, 4)
        else:
            eye = "closed"; beak = "snore"; bdy = 11; tilt = 12
            squash = (6, -5); slump = (4, 4, -3)
            wing = "droop" if stage > 2 else wing
            nightcap = stage in (3, 4)
    # ---- surprised ----
    elif M == "surprised":
        if n == 1:
            eye = "open"; beak = "closed"; brow = "raise"; pupil_dx = 0
            wing = "tuck" if stage > 2 else wing; bdy = 2
        elif n == 2:
            bdy = -12; eye = "surprised"; beak = "o"; brow = "raise"
            wing = {"2": "s2up", "3": "flare", "4": "s4flare"}.get(str(stage), "flare")
            tilt_tuft = -8; tailp = "fan" if stage == 4 else tailp
            fx = (excl(206, 56) + spark(36, 66, 8, PURPLE)
                  + f'<path d="M40 108 L50 116 M200 108 L190 116" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>')
        else:
            eye = "open"; beak = "closed"; bdy = 2; wing = "tuck" if stage > 2 else wing
            fx = spark(204, 66, 6, PURPLE)
    # ---- proud ----
    elif M == "proud":
        if n == 1:
            bdy = -4; squash = (-3, 4); eye = "open"; beak = "closed"; brow = "proud"
            wing = "hip" if stage > 2 else ("s2hip" if stage == 2 else "down")
            cheek_op = 0.4
        else:
            bdy = -5; squash = (-4, 5); eye = "open"; beak = "closed"; brow = "proud"
            wing = "hip" if stage > 2 else ("s2hip" if stage == 2 else "down")
            fx = spark(150, 150, 9, "#F4B400", True) + spark(196, 120, 6, PURPLE)

    # stage-4 pointed-wing remap (generic pose names → songbird wings)
    if stage == 4:
        wing = {"down": "s4down", "tuck": "s4tuck", "up": "s4up",
                "flare": "s4flare", "droop": "s4droop", "hip": "s4hip"}.get(wing, "s4down")

    if b["kind"] == "pear":
        sx = squash[0] + slump[0]
        dtop = -squash[1] * 0.75 + slump[1]
        dbot = squash[1] * 0.25 + slump[2]
        body_d = pear_path(b["cx"], b["top"], b["bottom"], b["w_head"], b["w_neck"],
                           b["w_body"], b["neck_y"], sx=sx, dtop=dtop, dbot=dbot)
        belly = b["belly"]
        bcx, bcy, brx, bry = belly[0], belly[1] + bdy, belly[2], belly[3]
        belly_s = (f'<g id="belly"><ellipse cx="{bcx}" cy="{bcy}" rx="{brx}" ry="{bry}" fill="{BEL}"/></g>')
        cx, cy = b["cx"], (b["top"] + b["bottom"]) / 2 + bdy
        ex_l, ex_r, ey = b["ex_l"] + tilt, b["ex_r"] + tilt, b["ey"] + bdy
        er, pr = b["er"], b["pr"]
        rx = b["w_body"]
        # crest + head-top for nightcap
        tdx = tilt_tuft + tilt
        tuft = crest_svg(cx, bdy + dtop, B, tdx)
        headtop = b["top"] + bdy + dtop
        P = S4_POINT[wing]
        P2 = dict(P, sy=P["sy"] + bdy, ty=P["ty"] + bdy)
        wl = wing_point_svg("l", cx, P2, W)
        wr = wing_point_svg("r", cx, P2, W)
        front_wings = P.get("front", False)
        body_s = f'<g id="body"><path d="{body_d}" fill="{B}" stroke="{INK}" stroke-width="{SW}"/></g>'
        hl_s = HIGHLIGHT.format(x=cx - 28, y=86 + bdy, rx=16, ry=9) if hl else ""
        shadow_rx = 68
    else:
        cx, cy, rx, ry = b["cx"], b["cy"], b["rx"] + squash[0], b["ry"] + squash[1]
        cy += bdy
        ex_l, ex_r, ey = b["ex_l"] + tilt, b["ex_r"] + tilt, b["ey"] + bdy
        er, pr = b["er"], b["pr"]
        belly = b["belly"]
        bcx, bcy, brx, bry = belly[0], belly[1] + bdy, belly[2] + squash[0] * 0.5, belly[3] + squash[1] * 0.5

    # proud wink on n2
    eye_r_active = "wink" if (M == "proud" and n == 2) else eye

    if b["kind"] != "pear":
        # wings (round stages)
        wp = WING_POSES[wing] if wing in WING_POSES else WING_POSES["down"]
        wl = wing_svg("l", cx - wp["off"], wp["cy"] + bdy, wp["rx"], wp["ry"], wp["rot"], W)
        wr = wing_svg("r", cx + wp["off"], wp["cy"] + bdy, wp["rx"], wp["ry"], -wp["rot"], W)
        front_wings = wp.get("front", False)
        # tuft sway (stage 2 tuft leans left, poking from under the shell cap)
        tdx = tilt_tuft + tilt
        if stage == 2:
            tuft = (f'<g id="head_tuft" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">'
                    f'<circle cx="{102+tdx}" cy="{84+bdy}" r="7" fill="{B}"/>'
                    f'<circle cx="{114+tdx}" cy="{80+bdy}" r="8" fill="{B}"/>'
                    f'<circle cx="{125+tdx}" cy="{85+bdy}" r="6.5" fill="{B}"/></g>')
        else:
            tuft = (f'<g id="head_tuft" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">'
                    f'<circle cx="{102+tdx}" cy="{68+bdy}" r="11" fill="{B}"/>'
                    f'<circle cx="{120+tdx}" cy="{60+bdy}" r="12.5" fill="{B}"/>'
                    f'<circle cx="{138+tdx}" cy="{68+bdy}" r="11" fill="{B}"/></g>')
            headtop = 60 + bdy
        body_s = (f'<g id="body"><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{B}" '
                  f'stroke="{INK}" stroke-width="{SW}"/></g>')
        belly_s = (f'<g id="belly"><ellipse cx="{bcx}" cy="{bcy}" rx="{brx}" ry="{bry}" fill="{BEL}"/></g>')
        hl_s = HIGHLIGHT.format(x=cx - 23, y=cy - 29, rx=18, ry=10) if hl else ""
        shadow_rx = {2: 44, 3: 62}[stage]

    # beak (head-leaned)
    bx, by = cx + tilt, ey + 21 + (2 if beak == "open" else 0)
    if beak == "open":
        beak_s = beak_open(bx, by)
    elif beak == "o":
        beak_s = beak_o(bx, by - 4)
    elif beak == "snore":
        beak_s = beak_snore(bx, by)
    else:
        beak_s = beak_closed(bx, by)

    # eating + sleepy fx need the beak position (berry at the mouth, Zzz clear of head)
    if M == "eating":
        if n == 1:
            fx = (berry(bx + 58, by - 70)
                  + f'<path d="M{bx+58} {by-56} Q{bx+52} {by-30} {bx+16} {by-4}" fill="none" '
                  f'stroke="{INK}" stroke-width="3" stroke-linecap="round" stroke-dasharray="2 7"/>')
        elif n == 2:
            fx = (berry(bx + 10, by + 10)
                  + crumb_big(bx - 62, by + 22) + crumb_big(bx + 62, by + 20))
        else:
            fx = (berry(bx + 22, by + 14, 7)
                  + crumb_big(bx - 40, by + 34) + crumb_big(bx + 44, by + 28)
                  + crumb_big(bx - 18, by + 50) + crumb_big(bx + 24, by + 54)
                  + crumb_big(bx + 58, by + 44))
    elif M == "sleepy":
        zx = {2: 168, 3: 184, 4: 176}[stage]
        if n == 2:
            fx = zzz(zx, 84, 15) + zzz(zx + 18, 110, 11, 0.75)
        elif n == 3:
            fx = zzz(zx, 62, 18) + zzz(zx + 20, 94, 13, 0.75) + zzz(zx - 12, 112, 10, 0.5)

    # shell hat (s2) / cup
    shell_top = '<g id="shell_top"></g>'; shell_bottom = '<g id="shell_bottom"></g>'
    if stage == 2:
        # cracked shell cap tilted on the head; tuft pokes out from under its left rim
        hy = 80 + bdy  # head top
        hx = cx + 14
        shell_top = (f'<g id="shell_top"><path d="M{hx-30} {hy-8} Q{hx-26} {hy-30} {hx-8} {hy-30} '
                    f'Q{hx+8} {hy-34} {hx+26} {hy-26} Q{hx+34} {hy-22} {hx+32} {hy-10} '
                    f'L{hx+20} {hy-2} L{hx+8} {hy-10} L{hx-4} {hy-2} L{hx-16} {hy-9} Z" '
                    f'fill="#FFF8E8" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>'
                    f'<circle cx="{hx+2}" cy="{hy-20}" r="3.5" fill="{PURPLE}"/></g>')
        shell_bottom = (f'<g id="shell_bottom"><path d="M{78} {150+bdy} L{92} {162+bdy} L{106} {150+bdy} '
                        f'L{120} {164+bdy} L{134} {150+bdy} L{148} {162+bdy} L{162} {150+bdy} '
                        f'L{158} {186+bdy} Q120 {198+bdy} {82} {186+bdy} Z" fill="#FFF8E8" '
                        f'stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>'
                        f'<circle cx="100" cy="176" r="4.5" fill="{PURPLE}"/><circle cx="140" cy="178" r="4" fill="{PURPLE}"/></g>')

    acc_head, acc_neck, acc_face = accessory_svg(acc, stage, cx, cy, rx, bdy, B)
    if nightcap and acc == "none":
        acc_head += nightcap_svg(cx, headtop, tilt)
    shw = 212
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" role="img" aria-label="Mochi s{stage} {mood} {n} {skin}">']
    out.append(f'<g id="shadow"><ellipse cx="120" cy="{shw}" rx="{shadow_rx}" ry="11" fill="{INK}" opacity="0.12"/></g>')
    out.append(tail_svg(stage, W, tailp))
    if not front_wings:
        out.append(wl); out.append(wr)
    out.append(body_s)
    out.append(belly_s)
    if front_wings:
        # wings on hips are drawn OVER the body so the elbows read at 48px
        out.append(wl); out.append(wr)
    if hl:
        out.append(f'<g id="highlight">{hl_s}</g>')
    out.append(cheeks(ex_l, ex_r, ey, 23, cheek_op, cheek_rx))
    out.append(tuft)
    out.append(eye_group("l", ex_l, ey, er, pr, eye, pupil_dx))
    out.append(eye_group("r", ex_r, ey, er, pr, eye_r_active, -pupil_dx if M == "proud" else pupil_dx))
    out.append(brows(eye, ex_l, ex_r, ey, er, brow))
    out.append(beak_s)
    out.append(feet_svg(stage, bdy, lift_r))
    out.append(shell_top); out.append(shell_bottom)
    out.append(f'<g id="accessory_head">{acc_head}</g>')
    out.append(f'<g id="accessory_neck">{acc_neck}</g>')
    out.append(f'<g id="accessory_face">{acc_face}</g>')
    out.append(f'<g id="fx">{fx}</g>')
    out.append('</svg>')
    return "\n".join(out)

# ---------------- egg renderer ----------------
def render_egg(mood, n, skin="sunny", acc="none"):
    B, BEL, W = SKINS[skin]
    wob = 0; crack_wide = 0; rock = 0; eye = "open"; fx = ""
    snore = False
    cx = 120  # pre-branch estimate (wob/rock are 0 for eating; refined below)
    by = 0
    M = mood
    if M in ("idle", "blink"):
        if n == 2:
            rock = 3 if M == "idle" else 0
            eye = "closed" if M == "blink" else "open"
    elif M == "happy":
        if n == 1:
            wob = -4
        elif n == 2:
            by = -14; wob = 3
            fx = spark(40, 70, 10, PURPLE) + spark(200, 66, 9, "#F4B400", True) + spark(120, 26, 8, WHITE, True) + spark(66, 120, 6, PEACH)
            eye = "happy"
        else:
            wob = -2; eye = "happy"
            fx = spark(196, 80, 6, PURPLE)
    elif M == "eating":
        # peek & nibble: big berry approaches the crack → nibble → crumbs
        if n == 1:
            fx = (berry(170, 84)
                  + f'<path d="M170 98 Q160 122 144 142" fill="none" '
                  f'stroke="{INK}" stroke-width="3" stroke-linecap="round" stroke-dasharray="2 7"/>')
        elif n == 2:
            crack_wide = 4; eye = "happy"
            fx = (berry(cx + 26, 148 + by, 10)
                  + crumb_big(88, 176, 3.5) + crumb_big(164, 178, 3))
        else:
            eye = "happy"
            fx = (berry(cx + 34, 158 + by, 7)
                  + crumb_big(84, 172, 3.5) + crumb_big(110, 182, 3) + crumb_big(140, 184, 3)
                  + crumb_big(166, 172, 2.8) + heart(188, 84, 7))
    elif M == "sleepy":
        # slow rock + heavy lids + snore mouth + Zzz (nightcap n/a for egg)
        eye = "closed" if n >= 2 else "sleepy"
        rock = 5 if n == 2 else (3 if n == 3 else 1)
        snore = n >= 2
        if n == 2:
            fx = zzz(168, 90, 14) + zzz(188, 114, 10, 0.7)
        elif n == 3:
            fx = zzz(166, 70, 17) + zzz(188, 100, 12, 0.75) + zzz(156, 118, 9, 0.5)
    elif M == "surprised":
        if n == 2:
            crack_wide = 8; by = -8; eye = "surprised"
            fx = excl(204, 52) + spark(38, 70, 8, PURPLE)
        elif n == 1:
            eye = "open"
        else:
            crack_wide = 2; fx = spark(202, 62, 6, PURPLE)
    elif M == "proud":
        eye = "open" if n == 1 else "wink"
        if n == 2:
            fx = (spark(120, 120, 9, WHITE, True)
                  + f'<path d="M60 120 Q120 150 180 118" stroke="{WHITE}" stroke-width="6" stroke-linecap="round" fill="none" opacity="0.8"/>')

    cx = 120 + wob + rock
    top, w, h = 30 + by, 120, 172
    d = egg_path(cx, top, w, h)
    er = 10; pr = 4.5
    ex_l, ex_r, ey = cx - 18, cx + 18, 163 + by
    spots = (f'<circle cx="{cx-30}" cy="78" r="7" fill="{PURPLE}"/><circle cx="{cx+22}" cy="64" r="5.5" fill="{PURPLE}"/>'
             f'<circle cx="{cx+38}" cy="102" r="6" fill="{PURPLE}"/><circle cx="{cx-42}" cy="120" r="5" fill="{PURPLE}"/>')
    crack = (f'<path d="M{cx-58} {146+by} L{cx-34} {136+by-crack_wide} L{cx-20} {152+by} L{cx-4} '
             f'{140+by-crack_wide} L{cx+14} {156+by} L{cx+32} {144+by-crack_wide} L{cx+58} {152+by}" '
             f'fill="none" stroke="{INK}" stroke-width="{SW}" stroke-linecap="round" stroke-linejoin="round"/>')
    if eye == "happy":
        el = eye_happy(ex_l, ey, er).replace('<g id="happy"', '<g id="happy"')
        er_ = eye_happy(ex_r, ey, er)
        def wrap(g, side):
            s = ""
            for name in ("open", "closed", "happy", "sleepy", "surprised", "wink"):
                if name == "happy":
                    s += g.replace('id="happy"', 'id="happy"')
                else:
                    s += f'<g id="{name}" style="display:none"></g>'
            return f'<g id="eye_{side}">{s}</g>'
        eyes = wrap(el, "l") + wrap(er_, "r")
    elif eye == "surprised":
        eyes = eye_group("l", ex_l, ey, er, pr, "surprised") + eye_group("r", ex_r, ey, er, pr, "surprised")
    elif eye == "closed":
        eyes = eye_group("l", ex_l, ey, er, pr, "closed") + eye_group("r", ex_r, ey, er, pr, "closed")
    elif eye == "sleepy":
        eyes = eye_group("l", ex_l, ey, er, pr, "sleepy") + eye_group("r", ex_r, ey, er, pr, "sleepy")
    elif eye == "wink":
        eyes = eye_group("l", ex_l, ey, er, pr, "open") + eye_group("r", ex_r, ey, er, pr, "wink")
    else:
        eyes = eye_group("l", ex_l, ey, er, pr, "open") + eye_group("r", ex_r, ey, er, pr, "open")

    hl = HIGHLIGHT.format(x=cx + 30, y=68 + by, rx=17, ry=9)
    # egg shell groups: whole egg = shell_bottom, crack flap = shell_top
    shell_top = (f'<g id="shell_top"><path d="M{cx-58} {146+by} L{cx-34} {136+by-crack_wide} L{cx-20} {152+by} '
                 f'L{cx-4} {140+by-crack_wide} L{cx+14} {156+by} L{cx+32} {144+by-crack_wide} L{cx+58} {152+by} '
                 f'L{cx+58} {132+by-crack_wide} L{cx-58} {132+by-crack_wide} Z" fill="#FFF8E8" opacity="0"/>'
                 f'{crack}</g>')
    acc_head, acc_neck, acc_face = accessory_svg(acc, 1, cx, 163, 60, by, B)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" role="img" aria-label="Mochi s1 {mood} {n} {skin}">']
    out.append(f'<g id="shadow"><ellipse cx="120" cy="212" rx="58" ry="11" fill="{INK}" opacity="0.12"/></g>')
    out.append('<g id="tail"></g>')
    out.append('<g id="wing_l"></g><g id="wing_r"></g>')
    out.append(f'<g id="body"><path d="{d}" fill="#FFF8E8" stroke="{INK}" stroke-width="{SW}"/></g>')
    out.append(f'<g id="belly">{spots}</g>')
    out.append(f'<g id="highlight">{hl}</g>')
    out.append('<g id="cheek_l"></g><g id="cheek_r"></g>')
    out.append(f'<g id="head_tuft"></g>')
    out.append(eyes)
    out.append('<g id="brow_l"></g><g id="brow_r"></g>')
    if snore:
        out.append('<g id="beak_top"></g>'
                   f'<g id="beak_bottom"><ellipse cx="{cx+4}" cy="{182+by}" rx="6" ry="7" fill="{INK}"/></g>')
    else:
        out.append('<g id="beak_top"></g><g id="beak_bottom"></g>')
    out.append('<g id="feet"></g>')
    out.append(shell_top)
    out.append(f'<g id="shell_bottom"><path d="{d}" fill="none" stroke="none"/></g>')
    out.append(f'<g id="accessory_head">{acc_head}</g>')
    out.append(f'<g id="accessory_neck">{acc_neck}</g>')
    out.append(f'<g id="accessory_face">{acc_face}</g>')
    out.append(f'<g id="fx">{fx}</g>')
    out.append('</svg>')
    return "\n".join(out)

# ---------------- accessories ----------------
def accessory_svg(acc, stage, cx, cy, rx, bdy, body_col):
    head = ""; neck = ""; face = ""
    if acc == "none":
        return head, neck, face
    if stage == 1:
        hy = 30 + bdy
        if acc == "bow":
            head = (f'<ellipse cx="{cx-16}" cy="{hy+6}" rx="13" ry="10" fill="#FF6B8A" stroke="{INK}" stroke-width="5" transform="rotate(-24 {cx-16} {hy+6})"/>'
                    f'<ellipse cx="{cx+16}" cy="{hy+6}" rx="13" ry="10" fill="#FF6B8A" stroke="{INK}" stroke-width="5" transform="rotate(24 {cx+16} {hy+6})"/>'
                    f'<circle cx="{cx}" cy="{hy+8}" r="8" fill="#E14A73" stroke="{INK}" stroke-width="5"/>')
        elif acc == "cap":
            head = (f'<path d="M{cx-34} {hy+22} Q{cx} {hy-26} {cx+34} {hy+22} Z" fill="#4E9AE0" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
                    f'<circle cx="{cx}" cy="{hy-22}" r="7" fill="{WHITE}" stroke="{INK}" stroke-width="4"/>'
                    f'<rect x="{cx-36}" y="{hy+18}" width="72" height="12" rx="6" fill="{WHITE}" stroke="{INK}" stroke-width="4.5"/>')
        elif acc == "scarf":
            neck = (f'<path d="M{cx-52} {160} Q{cx} {176} {cx+52} {160} L{cx+52} {176} Q{cx} {192} {cx-52} {176} Z" '
                    f'fill="#3FA67E" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
                    f'<rect x="{cx+18}" y="{172}" width="20" height="30" rx="9" fill="#3FA67E" stroke="{INK}" stroke-width="5"/>')
        elif acc == "glasses":
            face = (f'<circle cx="{cx-18}" cy="163" r="16" fill="{WHITE}" opacity="0.35" stroke="{INK}" stroke-width="5"/>'
                    f'<circle cx="{cx+18}" cy="163" r="16" fill="{WHITE}" opacity="0.35" stroke="{INK}" stroke-width="5"/>'
                    f'<path d="M{cx-2} 163 L{cx+2} 163" stroke="{INK}" stroke-width="5"/>')
        return head, neck, face
    # bird stages: head top approx
    if stage == 2:
        ty = 82 + bdy; hhx = 122
    elif stage == 3:
        ty = 60 + bdy; hhx = 120
    else:
        ty = 56 + bdy; hhx = 118
    ny = {2: 150, 3: 168, 4: 132}[stage] + bdy  # neck/scarf line
    ey = {"2": 120, "3": 129, "4": 112}[str(stage)] + bdy
    if acc == "bow":
        bx = hhx + 34
        head = (f'<g><ellipse cx="{bx-13}" cy="{ty-6}" rx="14" ry="11" fill="#FF6B8A" stroke="{INK}" stroke-width="5" transform="rotate(-24 {bx-13} {ty-6})"/>'
                f'<ellipse cx="{bx+13}" cy="{ty-6}" rx="14" ry="11" fill="#FF6B8A" stroke="{INK}" stroke-width="5" transform="rotate(24 {bx+13} {ty-6})"/>'
                f'<circle cx="{bx}" cy="{ty-4}" r="8.5" fill="#E14A73" stroke="{INK}" stroke-width="5"/></g>')
    elif acc == "cap":
        head = (f'<g><path d="M{hhx-36} {ty+16} Q{hhx} {ty-34} {hhx+36} {ty+16} Z" fill="#4E9AE0" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
                f'<circle cx="{hhx}" cy="{ty-30}" r="7.5" fill="{WHITE}" stroke="{INK}" stroke-width="4"/>'
                f'<rect x="{hhx-38}" y="{ty+12}" width="76" height="13" rx="6.5" fill="{WHITE}" stroke="{INK}" stroke-width="4.5"/>'
                f'<path d="M{hhx+36} {ty+16} L{hhx+56} {ty+22} L{hhx+36} {ty+26} Z" fill="#4E9AE0" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/></g>')
    elif acc == "scarf":
        w = rx
        neck = (f'<g><path d="M{cx-w} {ny} Q{cx} {ny+18} {cx+w} {ny} L{cx+w} {ny+16} Q{cx} {ny+34} {cx-w} {ny+16} Z" '
                f'fill="#3FA67E" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
                f'<rect x="{cx+14}" y="{ny+12}" width="22" height="34" rx="10" fill="#3FA67E" stroke="{INK}" stroke-width="5"/>'
                f'<path d="M{cx+18} {ny+30} L{cx+32} {ny+30}" stroke="{WHITE}" stroke-width="3.5" stroke-linecap="round"/></g>')
    elif acc == "glasses":
        er = {2: 11, 3: 16, 4: 15}[stage]
        ex_l, ex_r = {"2": (106, 134), "3": (96, 144), "4": (98, 142)}[str(stage)]
        face = (f'<g><circle cx="{ex_l}" cy="{ey}" r="{er+6}" fill="{WHITE}" opacity="0.3" stroke="{INK}" stroke-width="5"/>'
                f'<circle cx="{ex_r}" cy="{ey}" r="{er+6}" fill="{WHITE}" opacity="0.3" stroke="{INK}" stroke-width="5"/>'
                f'<path d="M{ex_l+er+6} {ey} L{ex_r-er-6} {ey}" stroke="{INK}" stroke-width="5"/>'
                f'<path d="M{ex_l-er-6} {ey-4} L{ex_l-er-12} {ey-10}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'
                f'<path d="M{ex_r+er+6} {ey-4} L{ex_r+er+12} {ey-10}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/></g>')
    return head, neck, face

# ---------------- evolve frames ----------------
def evolve_frame(s_from, k):
    # k=1: glow charge on old stage; k=2: pop reveal of new stage
    import copy
    if k == 1:
        base_svg = render_bird(s_from, "happy", 1) if s_from > 1 else render_egg("happy", 1)
        glow = (f'<g id="fx">'
                + spark(40, 60, 12, "#F4B400", True) + spark(200, 60, 12, "#F4B400", True)
                + spark(120, 28, 10, WHITE, True) + spark(52, 150, 9, "#F4B400", True)
                + spark(188, 150, 9, "#F4B400", True)
                + f'<circle cx="120" cy="125" r="86" fill="none" stroke="#F4B400" stroke-width="5" opacity="0.7"/>'
                + f'<circle cx="120" cy="125" r="98" fill="none" stroke="{PURPLE}" stroke-width="4" opacity="0.5" stroke-dasharray="10 8"/>'
                + '</g>')
        base_svg = base_svg.replace('<g id="fx"></g>', glow).replace('<g id="fx">', glow, 1) if '<g id="fx"></g>' in base_svg else base_svg
        # simpler: replace last fx group
        i = base_svg.rfind('<g id="fx">')
        j = base_svg.find('</g>', i)
        # find matching close: fx group may contain nested </g>? our fx has no nested g except none. ok
        base_svg = base_svg[:i] + glow + base_svg[base_svg.find('</svg>')-0:]
        return base_svg
    else:
        ns = s_from + 1
        base_svg = render_bird(ns, "happy", 2) if ns > 1 else render_egg("happy", 2)
        burst = (f'<g id="fx">'
                 + spark(36, 90, 11, PURPLE) + spark(204, 90, 11, PURPLE)
                 + spark(70, 36, 9, "#F4B400", True) + spark(170, 36, 9, "#F4B400", True)
                 + f'<circle cx="60" cy="160" r="5" fill="{PURPLE}"/><circle cx="180" cy="160" r="5" fill="{PURPLE}"/>'
                 + f'<circle cx="90" cy="200" r="4" fill="#F4B400"/><circle cx="150" cy="200" r="4" fill="#F4B400"/>'
                 + '</g>')
        i = base_svg.rfind('<g id="fx">')
        # cut from i to the fx close: find '</g>\n</svg>' tail
        tail = '\n</svg>'
        base_svg = base_svg[:i] + burst + tail
        return base_svg

MOODS_N = {"idle": 2, "blink": 2, "happy": 3, "eating": 3, "sleepy": 3, "surprised": 3, "proud": 2}

def main():
    poses = os.path.join(A, "poses"); skins = os.path.join(A, "skins")
    accd = os.path.join(A, "accessories"); evd = os.path.join(A, "evolve")
    for d in (poses, skins, accd, evd):
        os.makedirs(d, exist_ok=True)
    nfiles = 0
    for s in (1, 2, 3, 4):
        for mood, cnt in MOODS_N.items():
            for n in range(1, cnt + 1):
                svg = render_egg(mood, n) if s == 1 else render_bird(s, mood, n)
                p = os.path.join(poses, f"s{s}_{mood}_{n}.svg")
                open(p, "w").write(svg)
                nfiles += 1
    # skins: fledgling idle + happy peak in 4 skins (idle n1, happy n2)
    for skin in SKINS:
        for mood, n in (("idle", 1), ("happy", 2)):
            svg = render_bird(3, mood, n, skin=skin)
            open(os.path.join(skins, f"s3_{mood}_{n}_{skin}.svg"), "w").write(svg)
            nfiles += 1
    # accessories: all 4 stages idle fitted
    for acc in ("bow", "cap", "scarf", "glasses"):
        for s in (1, 2, 3, 4):
            svg = render_egg("idle", 1, acc=acc) if s == 1 else render_bird(s, "idle", 1, acc=acc)
            open(os.path.join(accd, f"s{s}_idle_{acc}.svg"), "w").write(svg)
            nfiles += 1
    # evolve key frames
    for s_from, s_to in ((1, 2), (2, 3), (3, 4)):
        for k in (1, 2):
            svg = evolve_frame(s_from, k)
            open(os.path.join(evd, f"evolve_s{s_from}_to_s{s_to}_{k}.svg"), "w").write(svg)
            nfiles += 1
    print("wrote", nfiles, "svgs")

if __name__ == "__main__":
    main()
