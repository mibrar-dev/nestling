#!/usr/bin/env python3
"""gen_mochi.py - build the Mochi (body style A) Rive project.

Source art: design/pip-v2/A/poses/*.svg (approved), accessories/*.svg,
evolve/*.svg. Output: tools/rive/mochi/{shared,stage1..4,pipstage}.rml.

Rig per stage (Node "bone chains", pivots from the art's own bboxes):
  root (feet baseline: jump + squash & stretch, volume preserving)
    body (breathing centre)
      head (tilts) -> tuft (sway, lagging = follow-through/overlap)
      wing_l / wing_r (shoulder pivots)
      tail (base pivot) / cheek nodes / scarf node / beak nodes
      eye variant nodes eye_{l,r}_{open,closed,happy,sleepy,surprised,wink}
  fx_* nodes (artboard level, owned by the FX layer)
  acc_* nodes (owned by data binding, Formula converters on `accessory`)

Layer ownership (no two layers key the same property):
  Body -> root/body/head/tuft/wings/tail/beak/cheeks/shadow/nightcap
  Eyes -> the 12 eye-variant opacities (+pop scales)
  FX   -> the 7 fx node opacities/transforms

View model Pip (one shared instance, client 0):
  mood/stage/skin/accessory as Numbers with the contract's enum values,
  bodyColor/darkColor/bellyColor Colors, evolve/tap/blink Triggers.
"""

from __future__ import annotations

import math
import os
import re
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(HERE, "..")))
import svg2rml as S  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
POSE_DIR = os.path.join(ROOT, "design", "pip-v2", "A", "poses")
ACC_DIR = os.path.join(ROOT, "design", "pip-v2", "A", "accessories")
EVOLVE_DIR = os.path.join(ROOT, "design", "pip-v2", "A", "evolve")
NEST_SVG = os.path.join(ROOT, "app", "assets", "illustrations", "nest.svg")
OUT = HERE

SVGNS = "{http://www.w3.org/2000/svg}"

# ---------------------------------------------------------------- contract
MOODS = {"idle": 0, "happy": 1, "eating": 2, "sleepy": 3, "surprised": 4, "proud": 5}
SKINS = {"sunny": 0, "berry": 1, "sky": 2, "mint": 3}
SKIN_COLORS = {
    "sunny": ("FFD93D", "E8A800", "FFF1B8"),
    "berry": ("FF9EBB", "E0608C", "FFE1EA"),
    "sky": ("8EC9FF", "4E9AE0", "E2F1FF"),
    "mint": ("8EE3B5", "3FA67E", "DDF8E8"),
}
# sunny fills that become data-bound: body, dark (wings/tuft/tail), belly
SKIN_BIND = {"#FFD93D": "bodyColor", "#E8A800": "darkColor", "#FFF1B8": "bellyColor"}
ACCESSORIES = {"none": 0, "bow": 1, "cap": 2, "scarf": 3, "glasses": 4}

B = 0


def sid(n):
    return f"{B}:{n}"


def use_ns(b):
    global B
    B = b


# Fixed node table (ids 200+i). Every stage has every node (empty when the
# art lacks the part, e.g. egg wings) so animations never branch on stage.
NODE_TABLE = [
    "root", "body", "head", "tuft", "wing_l", "wing_r", "tail",
    "cheek_l", "cheek_r", "beak_bottom_n", "beak_alt_n", "nightcap",
    "eye_l_open", "eye_l_closed", "eye_l_happy", "eye_l_sleepy",
    "eye_l_surprised", "eye_l_wink",
    "eye_r_open", "eye_r_closed", "eye_r_happy", "eye_r_sleepy",
    "eye_r_surprised", "eye_r_wink",
    "acc_bow", "acc_cap", "acc_scarf", "acc_glasses",
    "fx_happy", "fx_seed", "fx_crumbs", "fx_zzz", "fx_bang",
    "fx_proud", "fx_ring",
]
EYE_VARS = ["open", "closed", "happy", "sleepy", "surprised", "wink"]

# State / animation ids inside a stage namespace
SM, L_BODY, L_EYES, L_FX = 300, 301, 302, 303
ST_B = {"idle": 310, "happy": 311, "eating": 312, "sleepy": 313,
        "surprised": 314, "proud": 315, "evolve": 316}
ST_E = {"open": 320, "blink": 321, "happy": 322, "eating": 323,
        "sleepy": 324, "surprised": 325, "proud": 326}
ST_F = {"idle": 330, "happy": 331, "eating": 332, "sleepy": 333,
        "surprised": 334, "proud": 335, "evolve": 336}
A_B = {"idle": 400, "happy": 401, "eating": 402, "sleepy": 403,
       "surprised": 404, "proud": 405, "evolve": 406}
A_E = {"open": 410, "blink": 411, "happy": 412, "eating": 413,
       "sleepy": 414, "surprised": 415, "proud": 416}
A_F = {"idle": 420, "happy": 421, "eating": 422, "sleepy": 423,
       "surprised": 424, "proud": 425, "evolve": 426}

DUR = {"idle": 180, "happy": 72, "eating": 108, "sleepy": 240,
       "surprised": 48, "proud": 72, "evolve": 90, "open": 180,
       "blink": 12, "fxidle": 4, "fxsleepy": 240, "eyessleepy": 120}


# ------------------------------------------------------- svg geometry
def rd(v):
    dx, dy = v[0], v[1]
    return math.atan2(dy, dx), math.hypot(dx, dy)


def subpaths(d):
    out = []
    for sp in S.parse_path(d):
        pts = list(sp)
        if len(pts) > 1 and abs(pts[0][0] - pts[-1][0]) < 1e-6 \
                and abs(pts[0][1] - pts[-1][1]) < 1e-6:
            first, last = pts[0], pts[-1]
            pts = pts[:-1]
            pts[0] = (first[0], first[1], last[2], first[3])
        if len(pts) >= 2:
            out.append(pts)
    return out


def style_has_fill(prim):
    f = prim["style"].get("fill", "none")
    return bool(f) and f != "none"


def contour_bbox(pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def _points(pts, closed, origin, ind):
    pad = " " * ind
    ox, oy = origin
    rows = [f'{pad}<PointsPath isClosed="{"true" if closed else "false"}">']
    for x, y, inc, outc in pts:
        vx, vy = x - ox, y - oy
        if inc is None and outc is None:
            rows.append(f'{pad}  <StraightVertex x="{S.num(vx)}" '
                        f'y="{S.num(vy)}"/>')
            continue
        ir = rd((inc[0] - x, inc[1] - y)) if inc else (0.0, 0.0)
        orr = rd((outc[0] - x, outc[1] - y)) if outc else (0.0, 0.0)
        rows.append(
            f'{pad}  <CubicDetachedVertex x="{S.num(vx)}" y="{S.num(vy)}" '
            f'inRotation="{S.num(ir[0])}" inDistance="{S.num(ir[1])}" '
            f'outRotation="{S.num(orr[0])}" outDistance="{S.num(orr[1])}"/>')
    rows.append(f"{pad}</PointsPath>")
    return rows


def geometry(prim, origin, ind, name="", xf=(1.0, 0.0, 0.0)):
    el, tag = prim["el"], prim["tag"]
    sc, dx, dy = xf
    pad = " " * ind
    ang, _, _ = S._parse_transform(el)
    if tag == "ellipse":
        cx = float(el.attrib["cx"]); cy = float(el.attrib["cy"])
        w = 2 * float(el.attrib["rx"]) * sc
        h = 2 * float(el.attrib["ry"]) * sc
        row = f'{pad}  <Ellipse width="{S.num(w)}" height="{S.num(h)}" name="P"/>'
        return [((cx * sc + dx, cy * sc + dy), ang, [row])]
    if tag == "circle":
        cx = float(el.attrib["cx"]); cy = float(el.attrib["cy"])
        d = 2 * float(el.attrib["r"]) * sc
        row = f'{pad}  <Ellipse width="{S.num(d)}" height="{S.num(d)}" name="P"/>'
        return [((cx * sc + dx, cy * sc + dy), ang, [row])]
    if tag == "rect":
        x = float(el.attrib["x"]); y = float(el.attrib["y"])
        w = float(el.attrib["width"]) * sc
        h = float(el.attrib["height"]) * sc
        rr = float(el.attrib.get("rx", 0) or 0) * sc
        row = (f'{pad}  <Rectangle width="{S.num(w)}" height="{S.num(h)}" '
               f'cornerRadiusTL="{S.num(rr)}" linkCornerRadius="true" name="P"/>')
        return [((x * sc + dx + w / 2, y * sc + dy + h / 2), 0.0, [row])]
    filled = style_has_fill(prim)
    out = []
    for sp in subpaths(el.attrib["d"]):
        if sc != 1.0 or dx or dy:
            def t(c):
                return None if c is None else (c[0] * sc + dx, c[1] * sc + dy)
            sp = [(x * sc + dx, y * sc + dy, t(ic), t(oc))
                  for (x, y, ic, oc) in sp]
        px, py = (sum(p[0] for p in sp) / len(sp),
                  sum(p[1] for p in sp) / len(sp))
        out.append(((px, py), ang, _points(sp, filled, (px, py), ind)))
    return out


def paints(style, opacity, ind, skin_bind=True):
    pad = " " * ind
    rows = []
    fill = style.get("fill", "none")
    stroke = style.get("stroke", "none")
    sw = float(style.get("stroke-width", "0") or 0)
    line_op = float(style.get("opacity", "1")) * opacity
    if fill and fill != "none":
        a = line_op * float(style.get("fill-opacity", "1"))
        bind = SKIN_BIND.get(fill.upper()) if skin_bind else None
        if bind:
            rows.append(f'{pad}<Fill name="F">')
            rows.append(f'{pad}  <SolidColor colorValue="{S.argb(fill, a)}" name="C">')
            rows.append(f'{pad}    <DataBindContext sourcePathIds="0:500-{VM_PROP[bind]}" '
                        f'propertyKey="37"/>')
            rows.append(f'{pad}  </SolidColor>')
            rows.append(f"{pad}</Fill>")
        else:
            rows.append(f'{pad}<Fill name="F">')
            rows.append(f'{pad}  <SolidColor colorValue="{S.argb(fill, a)}" name="C"/>')
            rows.append(f"{pad}</Fill>")
    if stroke and stroke != "none" and sw > 0:
        a = line_op * float(style.get("stroke-opacity", "1"))
        cap = {"round": "round", "butt": "butt", "square": "square"}.get(
            style.get("stroke-linecap", "butt"), "butt")
        join = {"round": "round", "miter": "miter", "bevel": "bevel"}.get(
            style.get("stroke-linejoin", "miter"), "miter")
        rows.append(f'{pad}<Stroke name="S" thickness="{S.num(sw)}" cap="{cap}" '
                    f'join="{join}">')
        rows.append(f'{pad}  <SolidColor colorValue="{S.argb(stroke, a)}" name="C"/>')
        rows.append(f"{pad}</Stroke>")
    return rows


VM_PROP = {"mood": "0:502", "stage": "0:503", "skin": "0:504",
           "accessory": "0:505", "bodyColor": "0:506", "darkColor": "0:507",
           "bellyColor": "0:508", "evolve": "0:509", "tap": "0:510",
           "blink": "0:511"}


# ------------------------------------------------------- svg collection
def collect_groups(path):
    tree = ET.parse(path)
    root = tree.getroot()
    vb = [float(v) for v in root.attrib.get("viewBox", "0 0 240 240").split()]
    out = []

    def walk(node, style, ancestors):
        if node.tag in (SVGNS + "defs", SVGNS + "clipPath"):
            return
        st = dict(style)
        for attr in ("fill", "stroke", "stroke-width", "stroke-linecap",
                      "stroke-linejoin", "fill-opacity", "stroke-opacity",
                      "opacity"):
            if attr in node.attrib:
                st[attr] = node.attrib[attr]
        tag = node.tag.replace(SVGNS, "")
        if tag == "g":
            gid = node.attrib.get("id", "")
            anc = ancestors + ((gid,) if gid else ())
            for ch in node:
                walk(ch, st, anc)
            return
        if tag in ("path", "ellipse", "circle", "rect"):
            op = float(st.get("opacity", "1"))
            out.append({"tag": tag, "el": node, "style": st,
                        "opacity": op, "groups": tuple(ancestors)})

    base = {"fill": "#000", "stroke": "none", "stroke-width": "0",
            "stroke-linecap": "butt", "stroke-linejoin": "miter",
            "fill-opacity": "1", "stroke-opacity": "1", "opacity": "1"}
    for ch in root:
        walk(ch, base, ())
    return out, vb


def prim_bbox(prim):
    el, tag = prim["el"], prim["tag"]
    if tag == "ellipse":
        cx, cy = float(el.attrib["cx"]), float(el.attrib["cy"])
        rx, ry = float(el.attrib["rx"]), float(el.attrib["ry"])
        return (cx - rx, cy - ry, cx + rx, cy + ry)
    if tag == "circle":
        cx, cy = float(el.attrib["cx"]), float(el.attrib["cy"])
        r = float(el.attrib["r"])
        return (cx - r, cy - r, cx + r, cy + r)
    if tag == "rect":
        x, y = float(el.attrib["x"]), float(el.attrib["y"])
        return (x, y, x + float(el.attrib["width"]),
                y + float(el.attrib["height"]))
    acc = []
    for sp in subpaths(el.attrib["d"]):
        acc += [(p[0], p[1]) for p in sp]
    xs = [p[0] for p in acc]; ys = [p[1] for p in acc]
    return (min(xs), min(ys), max(xs), max(ys))


def union_bbox(prims):
    boxes = [prim_bbox(p) for p in prims]
    return (min(b[0] for b in boxes), min(b[1] for b in boxes),
            max(b[2] for b in boxes), max(b[3] for b in boxes))


# ------------------------------------------------------- rml emission
class Emitter:
    def __init__(self):
        self.shape_n = 0
        self.lines = []

    def nid(self, name):
        return sid(200 + NODE_TABLE.index(name))

    def shape_id(self):
        self.shape_n += 1
        return sid(self.shape_n)

    def shapes_for(self, prims, origin, ind, prefix, opacity_node=None,
                     xf=(1.0, 0.0, 0.0)):
        """One <Shape> per (primitive, contour). Returns shape ids.

        Emission is reversed into front-to-back order: Rive draws the
        FIRST sibling on top, while SVG paints first (= document order)
        at the bottom. `xf` scales geometry about `origin` (stroke width
        is untouched, so outlines keep their authored weight)."""
        pad = " " * ind
        ids = []
        k = 0
        for prim in reversed(prims):
            parts = geometry(prim, origin, ind, prefix, xf=xf)
            for (p, ang, geom) in parts:
                nm = prefix if len(prims) == 1 and len(parts) == 1 \
                    else f"{prefix}_{k}"
                k += 1
                q = self.shape_id()
                ids.append(q)
                rot = f' rotation="{S.num(ang)}"' if abs(ang) > 1e-9 else ""
                self.lines.append(f'{pad}<Shape x="{S.num(p[0]-origin[0])}" '
                                  f'y="{S.num(p[1]-origin[1])}"{rot} name="{nm}" '
                                  f'id="{q}">')
                self.lines += geom
                self.lines += paints(prim["style"], prim["opacity"], ind)
                self.lines.append(f"{pad}</Shape>")
        return ids

    def node_open(self, name, x, y, ind, opacity=None, extra=""):
        pad = " " * ind
        at = f'x="{S.num(x)}" y="{S.num(y)}"'
        if opacity is not None:
            at += f' opacity="{S.num(opacity)}"'
        self.lines.append(f'{pad}<Node {at} name="{name}" '
                          f'id="{self.nid(name)}"{extra}>')

    def node_close(self, ind):
        self.lines.append(" " * ind + "</Node>")


EASE_IO = (0.42, 0.0, 0.58, 1.0)
EASE_OUT = (0.0, 0.0, 0.58, 1.0)
EASE_IN = (0.42, 0.0, 1.0, 1.0)


def ease_tag(e=EASE_IO):
    return (f'<CubicEaseInterpolator x1="{e[0]}" y1="{e[1]}" '
            f'x2="{e[2]}" y2="{e[3]}"/>')


def keyed(oid, pkey, frames, ind, mode="cubic"):
    """frames: [(value, frame|None)]. mode cubic|hold|color.

    cubic: every segment eases (last key linear terminator).
    hold: snaps, for opacity swaps. color: KeyFrameColor holder."""
    out = [f'{ind}<KeyedObject objectId="{oid}">',
           f'{ind}  <KeyedProperty propertyKey="{pkey}">']
    n = len(frames)
    for i, (val, fr) in enumerate(frames):
        f = "" if fr is None else f' frame="{fr}"'
        if mode == "color":
            it = "hold" if i < n - 1 else "linear"
            out.append(f'{ind}    <KeyFrameColor value="{val}" '
                       f'interpolationType="{it}"{f}/>')
        elif mode == "hold":
            out.append(f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                       f'interpolationType="hold"{f}/>')
        else:
            if i < n - 1:
                out.append(f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                           f'interpolationType="cubic"{f}>{ease_tag()}</KeyFrameDouble>')
            else:
                out.append(f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                           f'interpolationType="linear"{f}/>')
    out.append(f"{ind}  </KeyedProperty>")
    out.append(f"{ind}</KeyedObject>")
    return out


def keyed_elastic(oid, pkey, frames, ind, amplitude=1.0, period=0.35):
    out = [f'{ind}<KeyedObject objectId="{oid}">',
           f'{ind}  <KeyedProperty propertyKey="{pkey}">']
    n = len(frames)
    for i, (val, fr) in enumerate(frames):
        f = "" if fr is None else f' frame="{fr}"'
        if i < n - 1:
            out.append(
                f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                f'interpolationType="elastic"{f}>'
                f'<ElasticInterpolator easingValue="1" amplitude="{amplitude}" '
                f'period="{period}"/></KeyFrameDouble>')
        else:
            out.append(f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                       f'interpolationType="linear"{f}/>')
    out.append(f"{ind}  </KeyedProperty>")
    out.append(f"{ind}</KeyedObject>")
    return out



def surprised_prims(vp, piv):
    """Dedicated wide-eyed-shock geometry from the open eye (orchestrator).

    Sclera 1.15x, pupil 55% of sclera diameter, original glint plus a second
    tiny mirrored highlight, ink stroke untouched (exactly idle weight).
    Positions stay absolute; the caller applies the 1.15x `xf` about `piv`.
    """
    import copy
    import xml.etree.ElementTree as _E
    whites = [q for q in vp
              if q["tag"] in ("circle", "ellipse")
              and q["style"].get("fill", "").upper() == "#FFFFFF"]
    R = max(float(q["el"].attrib.get("r", q["el"].attrib.get("rx", 16)))
            for q in whites)
    pc, gc = None, None
    res = []
    for q in vp:
        if q["tag"] == "circle" \
                and q["style"].get("fill", "").upper() == "#1E1B3A":
            el2 = copy.deepcopy(q["el"])
            el2.attrib["r"] = str(0.55 * R)
            pc = (float(q["el"].attrib["cx"]), float(q["el"].attrib["cy"]))
            res.append({"tag": "circle", "el": el2, "style": dict(q["style"]),
                        "opacity": q["opacity"], "groups": q["groups"]})
        else:
            if q["tag"] == "circle" \
                    and q["style"].get("fill", "").upper() == "#FFFFFF" \
                    and float(q["el"].attrib.get("r", 0)) < R:
                gc = (float(q["el"].attrib["cx"]),
                      float(q["el"].attrib["cy"]))
            res.append(q)
    if pc is not None and gc is not None:
        hx, hy = 2 * pc[0] - gc[0], 2 * pc[1] - gc[1]
        hel = _E.fromstring(
            '<circle xmlns="http://www.w3.org/2000/svg" '
            f'cx="{hx}" cy="{hy}" r="{1.5 / 1.15}"/>')
        res.append({"tag": "circle", "el": hel, "style": {
            "fill": "#FFFFFF", "stroke": "none", "stroke-width": "0",
            "stroke-linecap": "butt", "stroke-linejoin": "miter",
            "fill-opacity": "1", "stroke-opacity": "1", "opacity": "1"},
            "opacity": 1.0, "groups": ("eye", "surprised")})
    return res, R

# ------------------------------------------------------- rig builder
def _by_group(prims, *path):
    return [p for p in prims if p["groups"][:len(path)] == tuple(path)]


def build_rig(n, em, egg):
    """Emit stage n's rig into emitter lines. Returns dict of pivots."""
    base, _vb = collect_groups(os.path.join(POSE_DIR, f"s{n}_idle_1.svg"))
    P = {}
    by_top = {}
    for p in base:
        by_top.setdefault(p["groups"][0] if p["groups"] else "", []).append(p)

    def grp(*a):
        return _by_group(base, *a)

    body_p = grp("body") or grp("shell_bottom") or base
    bb = union_bbox(body_p)
    bodyC = ((bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2)
    feet_p = grp("feet")
    if feet_p:
        fb = union_bbox(feet_p)
        feetY = fb[3] - 4
    elif grp("shell_bottom"):
        sb = union_bbox(grp("shell_bottom"))
        feetY = sb[3] - 6
    else:
        feetY = bb[3]
    eye_open = grp("eye_l", "open") + grp("eye_r", "open")
    if eye_open:
        eb = union_bbox(eye_open)
        headC = ((eb[0] + eb[2]) / 2, (eb[1] + eb[3]) / 2)
    else:
        headC = (bodyC[0], bodyC[1] - 20)
    tuft_p = grp("head_tuft")
    if tuft_p:
        tb = union_bbox(tuft_p)
        tuftC = ((tb[0] + tb[2]) / 2, tb[3])
    else:
        tuftC = (headC[0], headC[1] - 40)

    def shoulder(side):
        w = grp(f"wing_{side}")
        if not w:
            return (bodyC[0] + (30 if side == "r" else -30), bodyC[1] + 10)
        wb = union_bbox(w)
        x = wb[0] if side == "r" else wb[2]
        return (x, (wb[1] + wb[3]) / 2)

    shL, shR = shoulder("l"), shoulder("r")
    tail_p = grp("tail")
    if tail_p:
        tb2 = union_bbox(tail_p)
        tailC = ((tb2[0] + tb2[2]) / 2, tb2[1] + 4)
    else:
        tailC = (bodyC[0], bodyC[1] + 50)
    P.update(bodyC=bodyC, feetY=feetY, headC=headC, tuftC=tuftC,
             shL=shL, shR=shR, tailC=tailC, root=(120.0, feetY))
    RX, RY = 120.0, feetY

    L = em.lines
    # ---- front-to-back: fx, root(body...), shell extras, shadow
    for fx, src in (("fx_happy", f"s{n}_happy_2.svg"),
                    ("fx_seed", f"s{n}_eating_1.svg"),
                    ("fx_crumbs", f"s{n}_eating_3.svg"),
                    ("fx_zzz", f"s{n}_sleepy_3.svg"),
                    ("fx_bang", f"s{n}_surprised_2.svg"),
                    ("fx_proud", f"s{n}_proud_2.svg")):
        fxprims, _ = collect_groups(os.path.join(POSE_DIR, src))
        fx_p = _by_group(fxprims, "fx")
        em.node_open(fx, 0, 0, 8, opacity=0)
        em.shapes_for(fx_p, (0, 0), 10, fx)
        em.node_close(8)
        L.append("")
    # evolve ring: procedural glow ring + evolve-file fx
    evprims, _ = collect_groups(os.path.join(
        EVOLVE_DIR, f"evolve_s{min(n,3)}_to_s{min(n+1,4)}_{1 if n < 3 else 2}.svg"))
    evfx = _by_group(evprims, "fx")
    em.node_open("fx_ring", bodyC[0], bodyC[1], 8, opacity=0)
    ring_el = {"tag": "ellipse", "el": None, "style": {
        "fill": "none", "stroke": "#F4B400", "stroke-width": "5",
        "stroke-linecap": "round", "stroke-linejoin": "round",
        "fill-opacity": "1", "stroke-opacity": "1", "opacity": "1"},
        "opacity": 1.0}
    import xml.etree.ElementTree as _ET
    ring_el["el"] = _ET.fromstring(
        f'<ellipse xmlns="http://www.w3.org/2000/svg" cx="{bodyC[0]}" '
        f'cy="{bodyC[1]}" rx="72" ry="72"/>')
    em.shapes_for([ring_el], bodyC, 10, "fx_ring")
    em.shapes_for(evfx, bodyC, 10, "fx_ring_ev")
    em.node_close(8)
    L.append("")

    # ---- root: jump + squash & stretch (volume preserving)
    em.node_open("root", RX, RY, 8)
    # shell crack/cup rims read on top of the body (egg)
    em.shapes_for(grp("shell_top"), (RX, RY), 10, "shell_top")
    em.shapes_for(grp("shell_bottom"), (RX, RY), 10, "shell_bottom")
    # ---- body: breathing centre
    em.node_open("body", bodyC[0] - RX, bodyC[1] - RY, 10)
    # head (front)
    em.node_open("head", headC[0] - bodyC[0], headC[1] - bodyC[1], 12)
    # accessories on head (bow/cap) + glasses: art in absolute coords
    for acc, src, grpname in (("acc_bow", f"s{n}_idle_bow.svg", "accessory_head"),
                              ("acc_cap", f"s{n}_idle_cap.svg", "accessory_head"),
                              ("acc_glasses", f"s{n}_idle_glasses.svg", "accessory_face")):
        ap, _ = collect_groups(os.path.join(ACC_DIR, src))
        em.lines.append(
            f'            <Node x="{S.num(0)}" y="{S.num(0)}" opacity="0" '
            f'name="{acc}" id="{em.nid(acc)}">')
        em.lines.append(
            f'              <DataBindContext sourcePathIds="0:500-0:505" '
            f'propertyKey="18" converterId="0:{599 + ACCESSORIES[acc[4:]]}"/>')
        em.shapes_for(_by_group(ap, grpname), headC, 14, acc)
        em.lines.append("            </Node>")
    # tuft
    em.node_open("tuft", tuftC[0] - headC[0], tuftC[1] - headC[1], 14)
    em.shapes_for(tuft_p, tuftC, 16, "head_tuft")
    em.node_close(14)
    # eyes: 12 variant nodes
    gap_info = {}
    for side in ("l", "r"):
        for v in EYE_VARS:
            # Orchestrator call: the surprised variant reads as rings at
            # board scale, so surprised gets dedicated shock geometry built
            # from the open eye (1.15x, 55% pupil, dual highlights) with the
            # stroke at exactly idle weight (a node scale would thicken it
            # into rims, so the scale lives in the geometry instead).
            vp = grp(f"eye_{side}", "open" if v == "surprised" else v)
            node = f"eye_{side}_{v}"
            op = 1 if v == "open" else 0
            if vp:
                vb = union_bbox(vp)
                piv = ((vb[0] + vb[2]) / 2, (vb[1] + vb[3]) / 2)
            else:
                piv = headC
            dx, R = 0.0, None
            if v == "surprised" and vp:
                vp, R = surprised_prims(vp, piv)
                dx = -6.0 if side == "l" else 6.0
                gap_info[side] = (piv[0], R)
            em.node_open(node, piv[0] + dx - headC[0], piv[1] - headC[1],
                         14, opacity=op)
            xf = (1.15, -0.15 * piv[0], -0.15 * piv[1]) \
                if v == "surprised" else (1.0, 0.0, 0.0)
            em.shapes_for(vp, piv, 16, node, xf=xf)
            em.node_close(14)
    if gap_info:
        (lx, lr), (rx, rr) = gap_info["l"], gap_info["r"]
        idle_gap = (rx - rr) - (lx + lr)
        new_gap = (rx + 6 - 1.15 * rr) - (lx - 6 + 1.15 * lr)
        print(f"    stage eyes: idle sclera gap {idle_gap:.1f} -> "
              f"surprised {new_gap:.1f} (need >= {0.6 * idle_gap:.1f})")
        assert new_gap >= 0.6 * idle_gap, "surprised eyes touch!" 
    # brows (usually empty)
    em.shapes_for(grp("brow_l") + grp("brow_r"), headC, 14, "brow")
    # beak
    em.shapes_for(grp("beak_top"), headC, 14, "beak_top")
    em.node_open("beak_bottom_n", 0, 0, 14, opacity=0)
    em.shapes_for(grp("beak_bottom"), headC, 16, "beak_bottom")
    em.node_close(14)
    # surprised "o" beak from the peak pose
    alt, _ = collect_groups(os.path.join(POSE_DIR, f"s{n}_surprised_2.svg"))
    em.node_open("beak_alt_n", 0, 0, 14, opacity=0)
    em.shapes_for(_by_group(alt, "beak_bottom"), headC, 16, "beak_alt")
    em.node_close(14)
    # nightcap (sleepy-only, from approved sleepy pose)
    try:
        sl, _ = collect_groups(os.path.join(POSE_DIR, f"s{n}_sleepy_3.svg"))
        ncp = _by_group(sl, "accessory_head")
    except OSError:
        ncp = []
    em.node_open("nightcap", 0, 0, 14, opacity=0)
    em.shapes_for(ncp, headC, 16, "nightcap")
    em.node_close(14)
    em.node_close(12)  # head
    # wings
    for side, sh in (("l", shL), ("r", shR)):
        em.node_open(f"wing_{side}", sh[0] - bodyC[0], sh[1] - bodyC[1], 12)
        em.shapes_for(grp(f"wing_{side}"), sh, 14, f"wing_{side}")
        em.node_close(12)
    # scarf on body
    try:
        sc, _ = collect_groups(os.path.join(ACC_DIR, f"s{n}_idle_scarf.svg"))
        scp = _by_group(sc, "accessory_neck")
    except OSError:
        scp = []
    em.lines.append(
        f'            <Node x="{S.num(0)}" y="{S.num(0)}" opacity="0" '
        f'name="acc_scarf" id="{em.nid("acc_scarf")}">')
    em.lines.append(
        f'              <DataBindContext sourcePathIds="0:500-0:505" '
        f'propertyKey="18" converterId="0:602"/>')
    em.shapes_for(scp, bodyC, 14, "acc_scarf")
    em.lines.append("            </Node>")
    # cheeks
    for side in ("l", "r"):
        cp = grp(f"cheek_{side}")
        if cp:
            cb = union_bbox(cp)
            cc = ((cb[0] + cb[2]) / 2, (cb[1] + cb[3]) / 2)
        else:
            cc = bodyC
        em.node_open(f"cheek_{side}", cc[0] - bodyC[0], cc[1] - bodyC[1], 12)
        em.shapes_for(cp, cc, 14, f"cheek_{side}")
        em.node_close(12)
    # belly, highlight, body, tail (tail behind -> last)
    em.shapes_for(grp("belly"), bodyC, 12, "belly")
    em.shapes_for(grp("highlight"), bodyC, 12, "highlight")
    em.shapes_for(grp("body"), bodyC, 12, "body")
    em.node_open("tail", tailC[0] - bodyC[0], tailC[1] - bodyC[1], 12)
    em.shapes_for(tail_p, tailC, 14, "tail")
    em.node_close(12)
    em.node_close(10)  # body
    # feet ride the root (jump) but skip breathing
    em.shapes_for(grp("feet"), (RX, RY), 10, "feet")
    em.node_close(8)  # root
    L.append("")
    # shadow: artboard level, squash-syncs with jumps
    P["shadow_ids"] = em.shapes_for(grp("shadow"), (0, 0), 8, "shadow")
    L.append("")
    return P


# ------------------------------------------------------- animations
P = "        "


def body_anims(em, P_, egg, aids=None, ax=None):
    _ax = ax or (lambda v: sid(v))
    A = aids or A_B
    N = em.nid
    RY = P_["feetY"]
    r = []
    J = 8 if egg else 22  # happy jump height (spec: >= 18 px, egg hops)

    def ko(node, pkey, frames, mode="cubic"):
        return keyed(N(node), pkey, frames, P + "  ", mode)

    def kshadow(frames, mode="cubic"):
        out = []
        for q in P_.get("shadow_ids", []):
            out += keyed(q, 16, frames, P + "  ", mode)
        return out

    # ---- idle: 180f loop. breathe 1->1.04, head tilt +/-4deg, tuft sway
    r.append(f'{P}<LinearAnimation name="idle" duration="180" fps="60" '
             f'loopValue="loop" id="{_ax(A["idle"])}">')
    if egg:
        r += ko("root", 15, [(0, None), (0.05, 45), (-0.05, 135), (0, 180)])
        r += ko("root", 14, [(RY, None), (RY - 2, 90), (RY, 180)])
    else:
        r += ko("body", 16, [(1, None), (1.04, 90), (1, 180)])
        r += ko("body", 17, [(1, None), (1.04, 90), (1, 180)])
        r += ko("root", 14, [(RY, None), (RY - 1.5, 90), (RY, 180)])
    r += ko("head", 15, [(0, None), (0.07, 45), (-0.07, 135), (0, 180)])
    r += ko("tuft", 15, [(0, None), (0.1, 60), (-0.08, 120), (0, 180)])
    if not egg:
        r += ko("wing_l", 15, [(0, None), (0.06, 90), (0, 180)])
        r += ko("wing_r", 15, [(0, None), (-0.06, 90), (0, 180)])
        r += ko("tail", 15, [(0, None), (0.08, 90), (0, 180)])
    r += kshadow([(1, None), (0.97, 90), (1, 180)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- happy: 72f. squash(0.85y @9) -> jump -> flap x2 -> land squash
    r.append(f'{P}<LinearAnimation name="happy" duration="72" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["happy"])}">')
    r += ko("root", 16, [(1, None), (1.18, 9), (0.93, 24), (0.95, 36),
                         (1.15, 52), (1, 64), (1, 72)])
    r += ko("root", 17, [(1, None), (0.85, 9), (1.08, 24), (1.05, 36),
                         (0.88, 52), (1, 64), (1, 72)])
    r += ko("root", 14, [(RY, None), (RY + 2, 9), (RY - J, 24), (RY - J + 8, 36),
                         (RY, 48), (RY, 72)])
    r += ko("root", 15, [(0, None), (0, 72)] if egg else [(0, None), (0, 72)])
    if egg:
        r += ko("root", 15, [(0, None), (-0.08, 9), (0.08, 24), (-0.06, 40),
                             (0, 58), (0, 72)])
    else:
        r += ko("wing_l", 15, [(0, None), (-0.3, 9), (1.3, 20), (0.6, 28),
                               (1.3, 36), (0.2, 48), (0, 60), (0, 72)])
        axL = P_["shL"][0] - P_["bodyC"][0]
        r += ko("wing_l", 13, [(axL, None), (axL, 9), (axL - 12, 20),
                               (axL - 12, 36), (axL, 48), (axL, 72)])
        r += ko("wing_r", 15, [(0, None), (0.3, 9), (-1.3, 20), (-0.6, 28),
                               (-1.3, 36), (-0.2, 48), (0, 60), (0, 72)])
        axR = P_["shR"][0] - P_["bodyC"][0]
        r += ko("wing_r", 13, [(axR, None), (axR, 9), (axR + 12, 20),
                               (axR + 12, 36), (axR, 48), (axR, 72)])
    r += ko("head", 15, [(0, None), (0.08, 9), (-0.12, 24), (-0.06, 48),
                         (0, 64), (0, 72)])
    r += ko("tuft", 15, [(0, None), (-0.1, 9), (0.28, 26), (0.1, 42),
                         (-0.08, 56), (0, 68), (0, 72)])
    r += ko("beak_bottom_n", 18, [(0, None), (0, 11), (1, 12), (1, 54),
                                 (0, 55), (0, 72)], "hold")
    r += kshadow([(1, None), (1.12, 9), (1.3, 24), (1, 48), (1, 72)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- eating: 108f, 3 pecks
    r.append(f'{P}<LinearAnimation name="eating" duration="108" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["eating"])}">')
    dip = 3 if egg else 8
    tilt = 0.12 if egg else 0.35
    r += ko("head", 14, [(0, None), (dip, 20), (0, 30), (dip, 50), (0, 60),
                         (dip, 78), (0, 88), (0, 108)])
    r += ko("head", 15, [(0, None), (tilt, 20), (0, 30), (tilt, 50), (0, 60),
                         (tilt, 78), (0, 88), (0, 108)])
    if egg:
        r += ko("root", 15, [(0, None), (0.05, 20), (-0.04, 50), (0.05, 78),
                             (0, 100), (0, 108)])
    else:
        r += ko("body", 17, [(1, None), (0.98, 20), (1, 30), (0.98, 50),
                             (1, 60), (0.98, 78), (1, 88), (1, 108)])
    r += ko("beak_bottom_n", 18, [(0, None), (0, 17), (1, 18), (1, 25),
                                 (0, 26), (0, 42), (1, 43), (1, 50), (0, 51),
                                 (0, 67), (1, 68), (1, 75), (0, 76),
                                 (0, 108)], "hold")
    r += ko("cheek_l", 16, [(1, None), (1, 84), (1.25, 94), (1, 104),
                            (1, 108)])
    r += ko("cheek_r", 16, [(1, None), (1, 84), (1.25, 94), (1, 104),
                            (1, 108)])
    r += ko("tuft", 15, [(0, None), (0.08, 30), (-0.06, 60), (0.05, 88),
                         (0, 108)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- sleepy: 240f loop. slump 0.94, deep breathe, head nods, Zzz in FX
    r.append(f'{P}<LinearAnimation name="sleepy" duration="240" fps="60" '
             f'loopValue="loop" id="{_ax(A["sleepy"])}">')
    r += ko("body", 16, [(1, None), (1.06, 40), (1.0, 140), (1.06, 240)])
    r += ko("body", 17, [(1, None), (0.94, 40), (1.0, 140), (0.94, 240)])
    r += ko("root", 14, [(RY, None), (RY + 3, 40), (RY + 3, 240)])
    if egg:
        r += ko("root", 15, [(0, None), (0.04, 60), (-0.04, 120),
                             (0.04, 180), (0, 240)])
    r += ko("head", 15, [(0, None), (0.28, 40), (0.36, 100), (0.28, 140),
                         (0.36, 200), (0.28, 240)] if not egg else
            [(0, None), (0.15, 40), (0.2, 120), (0.15, 200), (0.15, 240)])
    r += ko("head", 14, [(0, None), (6 if not egg else 3, 40),
                         (6 if not egg else 3, 240)])
    r += ko("tuft", 15, [(0, None), (0.15, 40), (0.15, 240)])
    if not egg:
        r += ko("wing_l", 15, [(0, None), (0.12, 40), (0.12, 240)])
        r += ko("wing_r", 15, [(0, None), (-0.12, 40), (-0.12, 240)])
    r += ko("nightcap", 18, [(1, None), (1, 240)], "hold")
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- surprised: 48f. jump-back 10px, flare, tuft spring, "!" in FX
    r.append(f'{P}<LinearAnimation name="surprised" duration="48" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["surprised"])}">')
    r += ko("root", 14, [(RY, None), (RY - 10, 8), (RY - 10, 26), (RY, 38),
                         (RY, 48)])
    r += ko("root", 16, [(1, None), (1.08, 8), (1.08, 26), (0.94, 40),
                         (1, 48)])
    r += ko("root", 17, [(1, None), (1.08, 8), (1.08, 26), (1.06, 40),
                         (1, 48)])
    if egg:
        r += ko("root", 15, [(0, None), (0.07, 8), (-0.07, 20), (0, 34),
                             (0, 48)])
    else:
        r += ko("wing_l", 15, [(0, None), (1.3, 8), (1.3, 26), (0, 40),
                               (0, 48)])
        r += ko("wing_r", 15, [(0, None), (-1.3, 8), (-1.3, 26), (0, 40),
                               (0, 48)])
    r += ko("head", 15, [(0, None), (-0.12, 8), (-0.12, 26), (0, 40),
                         (0, 48)])
    r += keyed_elastic(N("tuft"), 15, [(0, None), (0.4, 10), (0, 40),
                                       (0, 48)], P + "  ")
    r += ko("beak_alt_n", 18, [(0, None), (0, 5), (1, 6), (1, 36), (0, 37),
                               (0, 48)], "hold")
    r += ko("beak_bottom_n", 18, [(0, None), (0, 48)], "hold")
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- proud: 72f. chest x1.06, chin up 8deg, wing to hip, wink in Eyes
    r.append(f'{P}<LinearAnimation name="proud" duration="72" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["proud"])}">')
    r += ko("body", 16, [(1, None), (1.1, 15), (1.1, 55), (1, 70), (1, 72)])
    r += ko("body", 17, [(1, None), (1.04, 15), (1.04, 55), (1, 70), (1, 72)])
    r += ko("head", 15, [(0, None), (-0.2, 15), (-0.2, 55), (0, 70),
                         (0, 72)])
    r += ko("head", 14, [(0, None), (-5, 15), (-5, 55), (0, 70), (0, 72)])
    r += ko("root", 14, [(RY, None), (RY, 8), (RY - 6, 20), (RY - 6, 50),
                         (RY, 64), (RY, 72)])
    if egg:
        r += ko("root", 15, [(0, None), (0.06, 15), (-0.06, 40), (0, 60),
                             (0, 72)])
    else:
        r += ko("wing_l", 15, [(0, None), (0.9, 15), (0.9, 55), (0, 70),
                               (0, 72)])
        r += ko("wing_r", 15, [(0, None), (-1.2, 15), (-1.2, 55), (0, 70),
                               (0, 72)])
    r += ko("tuft", 15, [(0, None), (-0.12, 15), (-0.12, 55), (0, 70),
                         (0, 72)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- evolve: 90f. squash-pop + glow ring in FX
    r.append(f'{P}<LinearAnimation name="evolve" duration="90" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["evolve"])}">')
    r += ko("root", 16, [(1, None), (1.12, 16), (0.92, 36), (1.03, 52),
                         (1, 66), (1, 90)])
    r += ko("root", 17, [(1, None), (0.85, 16), (1.12, 36), (0.97, 52),
                         (1, 66), (1, 90)])
    r += ko("root", 14, [(RY, None), (RY + 2, 16), (RY - 8, 36), (RY, 52),
                         (RY, 90)])
    r += ko("tuft", 15, [(0, None), (0.2, 36), (-0.1, 52), (0, 66), (0, 90)])
    if not egg:
        r += ko("wing_l", 15, [(0, None), (0.8, 36), (0, 56), (0, 90)])
        r += ko("wing_r", 15, [(0, None), (-0.8, 36), (0, 56), (0, 90)])
    r.append(f"{P}</LinearAnimation>")
    return r


def eyes_anims(em, aids=None, ax=None):
    _ax = ax or (lambda v: sid(v))
    A = aids or A_E
    N = em.nid
    r = []

    def eye(node, frames):
        return keyed(N(node), 18, frames, P + "  ", "hold")

    def all_eyes(except_on=(), val=0):
        out = []
        for side in ("l", "r"):
            for v in EYE_VARS:
                if (side, v) in except_on:
                    continue
                out += eye(f"eye_{side}_{v}", [(val, None), (val, 1)])
        return out

    # open: 180f loop, blink fully shut for ~6f at 150 (2.5-4s cadence)
    r.append(f'{P}<LinearAnimation name="eyesOpen" duration="180" fps="60" '
             f'loopValue="loop" id="{_ax(A["open"])}">')
    for side in ("l", "r"):
        r += eye(f"eye_{side}_open", [(1, None), (1, 148), (0, 150), (0, 156),
                                     (1, 158), (1, 180)])
        r += eye(f"eye_{side}_closed", [(0, None), (0, 148), (1, 150),
                                       (1, 156), (0, 158), (0, 180)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")
    # blink one-shot (blink trigger): shut in 2 frames, reopen
    r.append(f'{P}<LinearAnimation name="eyesBlink" duration="12" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["blink"])}">')
    for side in ("l", "r"):
        r += eye(f"eye_{side}_open", [(1, None), (0, 2), (0, 8), (1, 10),
                                     (1, 12)])
        r += eye(f"eye_{side}_closed", [(0, None), (1, 2), (1, 8), (0, 10),
                                       (0, 12)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")
    # happy ^^ (72f mirrors Body happy)
    r.append(f'{P}<LinearAnimation name="eyesHappy" duration="72" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["happy"])}">')
    for side in ("l", "r"):
        r += eye(f"eye_{side}_open", [(0, None), (0, 72)])
        r += eye(f"eye_{side}_happy", [(1, None), (1, 72)])
    for side in ("l", "r"):
        for v in ("closed", "sleepy", "surprised", "wink"):
            r += eye(f"eye_{side}_{v}", [(0, None), (0, 72)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")
    # eating: open + blink, satisfied ^^ at the end (108f mirrors Body)
    r.append(f'{P}<LinearAnimation name="eyesEat" duration="108" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["eating"])}">')
    for side in ("l", "r"):
        r += eye(f"eye_{side}_open", [(1, None), (1, 30), (0, 32), (0, 38),
                                     (1, 40), (1, 64), (0, 66), (0, 108)])
        r += eye(f"eye_{side}_closed", [(0, None), (0, 30), (1, 32), (1, 38),
                                       (0, 40), (0, 108)])
        r += eye(f"eye_{side}_happy", [(0, None), (0, 64), (1, 66), (1, 108)])
    for side in ("l", "r"):
        for v in ("sleepy", "surprised", "wink"):
            r += eye(f"eye_{side}_{v}", [(0, None), (0, 108)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")
    # sleepy: drooped lash lines, loop (no blink while sleepy)
    r.append(f'{P}<LinearAnimation name="eyesSleepy" duration="120" fps="60" '
             f'loopValue="loop" id="{_ax(A["sleepy"])}">')
    for side in ("l", "r"):
        r += eye(f"eye_{side}_sleepy", [(1, None), (1, 120)])
        for v in ("open", "closed", "happy", "surprised", "wink"):
            r += eye(f"eye_{side}_{v}", [(0, None), (0, 120)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")
    # surprised wide (48f mirrors Body, pop scale)
    r.append(f'{P}<LinearAnimation name="eyesSurprised" duration="48" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["surprised"])}">')
    for side in ("l", "r"):
        r += eye(f"eye_{side}_open", [(0, None), (0, 48)])
        r += eye(f"eye_{side}_surprised", [(1, None), (1, 48)])
    for side in ("l", "r"):
        for v in ("closed", "happy", "sleepy", "wink"):
            r += eye(f"eye_{side}_{v}", [(0, None), (0, 48)])
    r.append(f"{P}</LinearAnimation>")
    r.append("")
    # proud: left open, right wink (72f mirrors Body)
    r.append(f'{P}<LinearAnimation name="eyesProud" duration="72" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["proud"])}">')
    r += eye("eye_l_open", [(1, None), (1, 72)])
    r += eye("eye_r_open", [(0, None), (0, 72)])
    r += eye("eye_r_wink", [(1, None), (1, 72)])
    for v in ("closed", "happy", "sleepy", "surprised"):
        r += eye(f"eye_l_{v}", [(0, None), (0, 72)])
        r += eye(f"eye_r_{v}", [(0, None), (0, 72)])
    r += eye("eye_l_wink", [(0, None), (0, 72)])
    r.append(f"{P}</LinearAnimation>")
    return r


def fx_anims(em, P_, aids=None, ax=None):
    _ax = ax or (lambda v: sid(v))
    A = aids or A_F
    N = em.nid
    r = []

    def fx(node, frames, mode="cubic", pkey=18):
        return keyed(N(node), pkey, frames, P + "  ", mode)

    r.append(f'{P}<LinearAnimation name="fxIdle" duration="4" fps="60" '
             f'loopValue="loop" id="{_ax(A["idle"])}">')
    for fxname in ("fx_happy", "fx_seed", "fx_crumbs", "fx_zzz", "fx_bang",
                 "fx_proud", "fx_ring"):
        r += fx(fxname, [(0, None), (0, 4)], "hold")
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # happy sparkle burst
    r.append(f'{P}<LinearAnimation name="fxHappy" duration="72" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["happy"])}">')
    r += fx("fx_happy", [(0, None), (0, 13), (1, 14), (1, 40), (0, 58),
                         (0, 72)], "hold")
    r += fx("fx_happy", [(0.5, None), (1.15, 20), (1.0, 35), (1.0, 72)],
            "cubic", 16)
    r += fx("fx_happy", [(0.5, None), (1.15, 20), (1.0, 35), (1.0, 72)],
            "cubic", 17)
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # eating: seed drops in, crumbs burst per peck
    r.append(f'{P}<LinearAnimation name="fxEat" duration="108" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["eating"])}">')
    HY = P_["headC"][1]
    r += fx("fx_seed", [(1, None), (1, 23), (0, 24), (0, 108)], "hold")
    r += fx("fx_seed", [(HY - 90, None), (HY - 8, 20), (HY - 8, 108)],
            "cubic", 14)
    # crumbs: three staggered bursts (hold opacity windows)
    r += fx("fx_crumbs", [(0, None), (0, 24), (1, 25), (1, 40), (0, 46),
                          (0, 49), (1, 50), (1, 65), (0, 71), (0, 74),
                          (1, 75), (1, 92), (0, 98), (0, 108)], "hold")
    r += fx("fx_crumbs", [(0.6, None), (1.0, 45), (1.15, 75), (1.15, 108)],
            "cubic", 16)
    r += fx("fx_crumbs", [(6, None), (10, 45), (14, 75), (14, 108)],
            "cubic", 14)
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # sleepy Zzz: 3 rising pulses over the 240f loop
    r.append(f'{P}<LinearAnimation name="fxSleepy" duration="240" fps="60" '
             f'loopValue="loop" id="{_ax(A["sleepy"])}">')
    ZY = P_["headC"][1] - 30
    r += fx("fx_zzz", [(0, None), (0, 8), (1, 20), (1, 45), (0, 60), (0, 88),
                       (1, 100), (1, 125), (0, 140), (0, 168), (1, 180),
                       (1, 205), (0, 220), (0, 240)], "hold")
    r += fx("fx_zzz", [(ZY, None), (ZY - 40, 240)], "cubic", 14)
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # surprised "!": elastic pop
    r.append(f'{P}<LinearAnimation name="fxSurprise" duration="48" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["surprised"])}">')
    r += fx("fx_bang", [(0, None), (0, 5), (1, 6), (1, 36), (0, 44),
                        (0, 48)], "hold")
    r += keyed_elastic(N("fx_bang"), 16, [(0.2, None), (1.25, 12), (1.0, 18),
                                          (1.0, 48)], P + "  ")
    r += keyed_elastic(N("fx_bang"), 17, [(0.2, None), (1.25, 12), (1.0, 18),
                                          (1.0, 48)], P + "  ")
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # proud chest sparkle
    r.append(f'{P}<LinearAnimation name="fxProud" duration="72" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["proud"])}">')
    r += fx("fx_proud", [(0, None), (0, 14), (1, 15), (1, 55), (0, 63),
                         (0, 72)], "hold")
    r += fx("fx_proud", [(0.6, None), (1.35, 28), (1.0, 45), (1.0, 72)],
            "cubic", 16)
    r += fx("fx_proud", [(0.6, None), (1.35, 28), (1.0, 45), (1.0, 72)],
            "cubic", 17)
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # evolve glow ring
    r.append(f'{P}<LinearAnimation name="fxEvolve" duration="90" fps="60" '
             f'loopValue="oneShot" id="{_ax(A["evolve"])}">')
    r += fx("fx_ring", [(0, None), (0, 9), (1, 10), (1, 54), (0, 66),
                        (0, 90)], "hold")
    r += fx("fx_ring", [(0.4, None), (1.15, 36), (1.2, 60), (1.2, 90)],
            "cubic", 16)
    r += fx("fx_ring", [(0.4, None), (1.15, 36), (1.2, 60), (1.2, 90)],
            "cubic", 17)
    r.append(f"{P}</LinearAnimation>")
    return r


# ------------------------------------------------------- state machine
def _mood_cond(dest, mood_val, duration=150, ind=P):
    return [
        f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}">',
        f'{ind}    <TransitionViewModelCondition opValue="equal">',
        f'{ind}      <TransitionPropertyViewModelComparator>',
        f'{ind}        <BindablePropertyNumber>',
        f'{ind}          <DataBindContext sourcePathIds="0:500-0:502" '
        f'propertyKey="636"/>',
        f'{ind}        </BindablePropertyNumber>',
        f'{ind}      </TransitionPropertyViewModelComparator>',
        f'{ind}      <TransitionValueNumberComparator value="{mood_val}"/>',
        f'{ind}    </TransitionViewModelCondition>',
        f'{ind}  </StateTransition>',
    ]


def _trig_cond(dest, prop_id, duration=100, ind=P):
    return [
        f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}">',
        f'{ind}    <TransitionViewModelCondition opValue="equal">',
        f'{ind}      <TransitionPropertyViewModelComparator>',
        f'{ind}        <BindablePropertyTrigger>',
        f'{ind}          <DataBindContext sourcePathIds="0:500-{prop_id}" '
        f'propertyKey="686"/>',
        f'{ind}        </BindablePropertyTrigger>',
        f'{ind}      </TransitionPropertyViewModelComparator>',
        f'{ind}      <TransitionValueTriggerComparator value="1"/>',
        f'{ind}    </TransitionViewModelCondition>',
        f'{ind}  </StateTransition>',
    ]


def _exit(dest, duration, ind=P):
    return [f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}" '
            f'enableExitTime="true" exitTimeIsPercetange="true" '
            f'exitTime="100"/>']


def state_machine():
    r = [f'{P}<StateMachine name="Pip" id="{sid(SM)}">']
    # ---- Body: idle loop + one-shot moods (exit at 100%) + sleepy loop
    r += [f'{P}  <StateMachineLayer name="Body" id="{sid(L_BODY)}">',
          f'{P}    <AnyState x="560" y="-120"/>',
          f'{P}    <ExitState x="760" y="-120"/>',
          f'{P}    <EntryState x="40" y="-120">',
          f'{P}      <StateTransition stateToId="{sid(ST_B["idle"])}" duration="0"/>',
          f'{P}    </EntryState>',
          f'{P}    <AnimationState x="160" y="-120" animationId="{sid(A_B["idle"])}" '
          f'id="{sid(ST_B["idle"])}">']
    for m, v in (("happy", 1), ("eating", 2), ("sleepy", 3), ("surprised", 4),
                 ("proud", 5)):
        r += _mood_cond(sid(ST_B[m]), v, 150, P + "  ")
    r += _trig_cond(sid(ST_B["happy"]), "0:510", 120, P + "  ")   # tap pokes
    r += _trig_cond(sid(ST_B["evolve"]), "0:509", 100, P + "  ")
    r.append(f'{P}    </AnimationState>')
    for m, x, y in (("happy", 360, -40), ("eating", 560, -40),
                    ("surprised", 760, -40), ("proud", 960, -40),
                    ("evolve", 560, 60)):
        blend = 300 if m == "evolve" else 220
        r += [f'{P}    <AnimationState x="{x}" y="{y}" animationId="{sid(A_B[m])}" '
              f'id="{sid(ST_B[m])}">']
        r += _exit(sid(ST_B["idle"]), blend, P + "  ")
        r.append(f'{P}    </AnimationState>')
    r += [f'{P}    <AnimationState x="360" y="60" animationId="{sid(A_B["sleepy"])}" '
          f'id="{sid(ST_B["sleepy"])}">']
    r += _mood_cond(sid(ST_B["idle"]), 0, 200, P + "  ")
    for m, v in (("happy", 1), ("eating", 2), ("surprised", 4), ("proud", 5)):
        r += _mood_cond(sid(ST_B[m]), v, 150, P + "  ")
    r += _trig_cond(sid(ST_B["evolve"]), "0:509", 100, P + "  ")
    r.append(f'{P}    </AnimationState>')
    r.append(f"{P}  </StateMachineLayer>")

    # ---- Eyes: open blink loop + one-shot moods + sleepy loop (no blink)
    r += [f'{P}  <StateMachineLayer name="Eyes" id="{sid(L_EYES)}">',
          f'{P}    <AnyState x="560" y="-220"/>',
          f'{P}    <ExitState x="760" y="-220"/>',
          f'{P}    <EntryState x="40" y="-220">',
          f'{P}      <StateTransition stateToId="{sid(ST_E["open"])}" duration="0"/>',
          f'{P}    </EntryState>',
          f'{P}    <AnimationState x="160" y="-220" animationId="{sid(A_E["open"])}" '
          f'id="{sid(ST_E["open"])}">']
    for m, v in (("happy", 1), ("eating", 2), ("sleepy", 3), ("surprised", 4),
                 ("proud", 5)):
        r += _mood_cond(sid(ST_E[m]), v, 80, P + "  ")
    r += _trig_cond(sid(ST_E["blink"]), "0:511", 80, P + "  ")
    r.append(f'{P}    </AnimationState>')
    r += [f'{P}    <AnimationState x="360" y="-140" animationId="{sid(A_E["blink"])}" '
          f'id="{sid(ST_E["blink"])}">']
    r += _exit(sid(ST_E["open"]), 80, P + "  ")
    r.append(f'{P}    </AnimationState>')
    for m, x, y in (("happy", 560, -140), ("eating", 760, -140),
                    ("surprised", 960, -140), ("proud", 1160, -140)):
        r += [f'{P}    <AnimationState x="{x}" y="{y}" animationId="{sid(A_E[m])}" '
              f'id="{sid(ST_E[m])}">']
        r += _exit(sid(ST_E["open"]), 150, P + "  ")
        r.append(f'{P}    </AnimationState>')
    r += [f'{P}    <AnimationState x="360" y="-300" animationId="{sid(A_E["sleepy"])}" '
          f'id="{sid(ST_E["sleepy"])}">']
    r += _mood_cond(sid(ST_E["open"]), 0, 200, P + "  ")
    for m, v in (("happy", 1), ("eating", 2), ("surprised", 4), ("proud", 5)):
        r += _mood_cond(sid(ST_E[m]), v, 80, P + "  ")
    r.append(f'{P}    </AnimationState>')
    r.append(f"{P}  </StateMachineLayer>")

    # ---- FX: idle + one-shot bursts + sleepy Zzz loop
    r += [f'{P}  <StateMachineLayer name="FX" id="{sid(L_FX)}">',
          f'{P}    <AnyState x="560" y="-320"/>',
          f'{P}    <ExitState x="760" y="-320"/>',
          f'{P}    <EntryState x="40" y="-320">',
          f'{P}      <StateTransition stateToId="{sid(ST_F["idle"])}" duration="0"/>',
          f'{P}    </EntryState>',
          f'{P}    <AnimationState x="160" y="-320" animationId="{sid(A_F["idle"])}" '
          f'id="{sid(ST_F["idle"])}">']
    for m, v in (("happy", 1), ("eating", 2), ("sleepy", 3), ("surprised", 4),
                 ("proud", 5)):
        r += _mood_cond(sid(ST_F[m]), v, 120, P + "  ")
    r += _trig_cond(sid(ST_F["evolve"]), "0:509", 100, P + "  ")
    r.append(f'{P}    </AnimationState>')
    for m, x, y in (("happy", 360, -240), ("eating", 560, -240),
                    ("surprised", 760, -240), ("proud", 960, -240),
                    ("evolve", 560, -380)):
        blend = 250 if m == "evolve" else 180
        r += [f'{P}    <AnimationState x="{x}" y="{y}" animationId="{sid(A_F[m])}" '
              f'id="{sid(ST_F[m])}">']
        r += _exit(sid(ST_F["idle"]), blend, P + "  ")
        r.append(f'{P}    </AnimationState>')
    r += [f'{P}    <AnimationState x="360" y="-380" animationId="{sid(A_F["sleepy"])}" '
          f'id="{sid(ST_F["sleepy"])}">']
    r += _mood_cond(sid(ST_F["idle"]), 0, 200, P + "  ")
    for m, v in (("happy", 1), ("eating", 2), ("surprised", 4), ("proud", 5)):
        r += _mood_cond(sid(ST_F[m]), v, 120, P + "  ")
    r += _trig_cond(sid(ST_F["evolve"]), "0:509", 100, P + "  ")
    r.append(f'{P}    </AnimationState>')
    r.append(f"{P}  </StateMachineLayer>")
    r.append(f"{P}</StateMachine>")
    return r


# ------------------------------------------------------- shared vm
def shared_rml():
    L = ['<Rive version="1" kind="fragment">']
    for name, nid_, n in (("is_bow", 600, 1), ("is_cap", 601, 2),
                          ("is_scarf", 602, 3), ("is_glasses", 603, 4),
                          ("is_stage_1", 604, 1), ("is_stage_2", 605, 2),
                          ("is_stage_3", 606, 3), ("is_stage_4", 607, 4)):
        L.append(f'    <DataConverterFormula name="{name}" id="0:{nid_}">')
        L.append('        <FormulaTokenValue operationValue="1"/>')
        L.append('        <FormulaTokenOperation operationType="1"/>')
        L.append('        <FormulaTokenFunction functionType="0"/>')
        L.append('        <FormulaTokenValue operationValue="1"/>')
        L.append('        <FormulaTokenArgumentSeparator/>')
        L.append('        <FormulaTokenParenthesisOpen/>')
        L.append('        <FormulaTokenInput/>')
        L.append('        <FormulaTokenOperation operationType="1"/>')
        L.append(f'        <FormulaTokenValue operationValue="{n}"/>')
        L.append('        <FormulaTokenParenthesisClose/>')
        L.append('        <FormulaTokenOperation operationType="2"/>')
        L.append('        <FormulaTokenParenthesisOpen/>')
        L.append('        <FormulaTokenInput/>')
        L.append('        <FormulaTokenOperation operationType="1"/>')
        L.append(f'        <FormulaTokenValue operationValue="{n}"/>')
        L.append('        <FormulaTokenParenthesisClose/>')
        L.append('        <FormulaTokenParenthesisClose/>')
        L.append('    </DataConverterFormula>')
        L.append("")
    L.append('    <ViewModel name="Pip" defaultInstanceId="0:501" id="0:500">')
    L.append('        <ViewModelPropertyNumber name="mood" id="0:502"/>')
    L.append('        <ViewModelPropertyNumber name="stage" id="0:503"/>')
    L.append('        <ViewModelPropertyNumber name="skin" id="0:504"/>')
    L.append('        <ViewModelPropertyNumber name="accessory" id="0:505"/>')
    L.append('        <ViewModelPropertyColor name="bodyColor" id="0:506"/>')
    L.append('        <ViewModelPropertyColor name="darkColor" id="0:507"/>')
    L.append('        <ViewModelPropertyColor name="bellyColor" id="0:508"/>')
    L.append('        <ViewModelPropertyTrigger name="evolve" id="0:509"/>')
    L.append('        <ViewModelPropertyTrigger name="tap" id="0:510"/>')
    L.append('        <ViewModelPropertyTrigger name="blink" id="0:511"/>')
    L.append('        <ViewModelInstance exports="true" name="Default" id="0:501">')
    L.append('            <ViewModelInstanceNumber propertyValue="0" '
             'viewModelPropertyId="0:502"/>')
    L.append('            <ViewModelInstanceNumber propertyValue="3" '
             'viewModelPropertyId="0:503"/>')
    L.append('            <ViewModelInstanceNumber propertyValue="0" '
             'viewModelPropertyId="0:504"/>')
    L.append('            <ViewModelInstanceNumber propertyValue="0" '
             'viewModelPropertyId="0:505"/>')
    L.append('            <ViewModelInstanceColor propertyValue="FFFFD93D" '
             'viewModelPropertyId="0:506"/>')
    L.append('            <ViewModelInstanceColor propertyValue="FFE8A800" '
             'viewModelPropertyId="0:507"/>')
    L.append('            <ViewModelInstanceColor propertyValue="FFFFF1B8" '
             'viewModelPropertyId="0:508"/>')
    L.append('            <ViewModelInstanceTrigger viewModelPropertyId="0:509"/>')
    L.append('            <ViewModelInstanceTrigger viewModelPropertyId="0:510"/>')
    L.append('            <ViewModelInstanceTrigger viewModelPropertyId="0:511"/>')
    L.append('        </ViewModelInstance>')
    L.append('    </ViewModel>')
    L.append('</Rive>')
    return "\n".join(L) + "\n"


# ------------------------------------------------------- stage artboard
STAGE_X = {1: 0, 2: 320, 3: 640, 4: 960}


def build_stage(n):
    egg = (n == 1)
    use_ns(n)
    em = Emitter()
    L = em.lines
    out = ['<Rive version="1" kind="fragment">']
    out.append(f'    <Artboard name="Stage{n}" x="{STAGE_X[n]}" y="0" '
               f'width="240" height="240" defaultStateMachineId="{sid(SM)}" '
               f'viewModelId="0:500" viewModelInstanceId="0:501" '
               f'styleId="{sid(999)}" id="{sid(998)}">')
    out.append(f'        <LayoutComponentStyle name="Artboard Style" '
               f'id="{sid(999)}"/>')
    out.append("")
    P_ = build_rig(n, em, egg)
    out += L
    out += state_machine()
    out.append("")
    out += body_anims(em, P_, egg)
    out += eyes_anims(em)
    out += fx_anims(em, P_)
    out.append("    </Artboard>")
    out.append("</Rive>")
    return "\n".join(out) + "\n", P_


# ------------------------------------------------------- PipStage
STAGE_W, STAGE_H = 350, 260
NEST_S = 200 / 196
NEST_DX = 175 - 120 * NEST_S
NEST_DY = 192 - 202 * NEST_S
NEST_TOP = NEST_DY + 98 * NEST_S
NEST_BOT = NEST_DY + 202 * NEST_S
NEST_H = NEST_BOT - NEST_TOP
SPLIT_FRAC = 0.55
SPLIT_Y = NEST_TOP + SPLIT_FRAC * NEST_H
FEET_FRAC = 0.40
FEET_Y = NEST_TOP + FEET_FRAC * NEST_H
PIP_VISIBLE_H = 130
RIG_NS = {1: 31, 2: 32, 3: 33, 4: 34}


def art_bbox(n):
    prims, _ = collect_groups(os.path.join(POSE_DIR, f"s{n}_idle_1.svg"))
    acc = []
    for prim in prims:
        if prim["groups"] and prim["groups"][0] == "shadow":
            continue
        el, tag = prim["el"], prim["tag"]
        if tag == "ellipse":
            cx, cy = float(el.attrib["cx"]), float(el.attrib["cy"])
            rx, ry = float(el.attrib["rx"]), float(el.attrib["ry"])
            acc += [(cx - rx, cy - ry), (cx + rx, cy + ry)]
        elif tag == "circle":
            cx, cy = float(el.attrib["cx"]), float(el.attrib["cy"])
            r_ = float(el.attrib["r"])
            acc += [(cx - r_, cy - r_), (cx + r_, cy + r_)]
        elif tag == "rect":
            x, y = float(el.attrib["x"]), float(el.attrib["y"])
            acc += [(x, y), (x + float(el.attrib["width"]),
                             y + float(el.attrib["height"]))]
        elif tag == "path":
            acc += [(p[0], p[1]) for sp in subpaths(el.attrib["d"])
                    for p in sp]
    xs = [p[0] for p in acc]; ys = [p[1] for p in acc]
    return min(xs), max(xs), min(ys), max(ys)


def pip_placement(n):
    x0, x1, y0, y1 = art_bbox(n)
    sc = PIP_VISIBLE_H / (y1 - y0)
    return sc, STAGE_W / 2 - (x0 + x1) / 2 * sc, FEET_Y - y1 * sc


def nest_prims():
    return collect_groups(NEST_SVG)


def build_pipstage():
    prims, _vb = nest_prims()
    use_ns(6)
    L = ['<Rive version="1" kind="fragment">']
    L.append(f'    <Artboard name="PipStage" x="1600" y="0" '
             f'width="{STAGE_W}" height="{STAGE_H}" '
             f'defaultStateMachineId="{sid(1)}" '
             f'viewModelId="0:500" viewModelInstanceId="0:501" '
             f'styleId="{sid(999)}" id="{sid(998)}">')
    L.append(f'        <LayoutComponentStyle name="Artboard Style" '
             f'id="{sid(999)}"/>')
    L.append("")

    names = [f"nest_{i}" for i in range(len(prims))]

    def nest_shape(i, ind, clip_to=None):
        prim = prims[i]
        parts = geometry(prim, (0, 0), ind, names[i],
                         xf=(NEST_S, NEST_DX, NEST_DY))
        base = (710 + i * 4) if clip_to == "front" else (610 + i * 4)
        pad = " " * ind
        rows = []
        for k, (p, ang, geom) in enumerate(parts):
            name = names[i] if k == 0 else f"{names[i]}_{k}"
            rows.append(f'{pad}<Shape x="{S.num(p[0])}" y="{S.num(p[1])}" '
                        f'name="{name}" id="{sid(base + k)}">')
            rows += geom
            rows += paints(prim["style"], prim["opacity"], ind, NEST_S)
            if clip_to is not None:
                mask = 650 if clip_to == "front" else 651
                rows.append(f'{pad}  <ClippingShape sourceId="{sid(mask)}" '
                            f'name="Clip"/>')
            rows.append(f"{pad}</Shape>")
        return rows

    for i in reversed(range(1, len(prims))):
        L += nest_shape(i, 8, clip_to="front")
    L.append("")

    rig_P = {}
    for n in (1, 2, 3, 4):
        psc, pdx, pdy = pip_placement(n)
        use_ns(6)
        L.append(f'        <Node x="{S.num(pdx)}" y="{S.num(pdy)}" '
                 f'scaleX="{S.num(psc)}" scaleY="{S.num(psc)}" '
                 f'name="pip_stage_{n}" id="{sid(250 + n)}">')
        L.append(f'          <DataBindContext sourcePathIds="0:500-0:503" '
                 f'propertyKey="18" converterId="0:{603 + n}"/>')
        use_ns(RIG_NS[n])
        em = Emitter()
        rig_P[n] = build_rig(n, em, n == 1)
        # re-indent rig lines by 4 (they were authored at 8)
        for ln in em.lines:
            L.append(("    " + ln) if ln.strip() else "")
        L.append("        </Node>")
        L.append("")
    use_ns(6)
    for i in reversed(range(1, len(prims))):
        L += nest_shape(i, 8, clip_to="back")
    L.append("")
    L += nest_shape(0, 8)
    L.append("")
    L.append(f'        <Shape x="{S.num(STAGE_W / 2)}" '
             f'y="{S.num(SPLIT_Y / 2)}" name="back_mask" id="{sid(651)}">')
    L.append(f'            <Rectangle width="{STAGE_W}" '
             f'height="{S.num(SPLIT_Y)}" cornerRadiusTL="0" '
             f'linkCornerRadius="true" name="P"/>')
    L.append("        </Shape>")
    L.append(f'        <Shape x="{S.num(STAGE_W / 2)}" '
             f'y="{S.num((SPLIT_Y + STAGE_H) / 2)}" name="front_mask" '
             f'id="{sid(650)}">')
    L.append(f'            <Rectangle width="{STAGE_W}" '
             f'height="{S.num(STAGE_H - SPLIT_Y)}" cornerRadiusTL="0" '
             f'linkCornerRadius="true" name="P"/>')
    L.append("        </Shape>")
    L.append("")

    # ---- state machine: Stage selector + one Body/Eyes/FX trio per rig
    L.append(f'{P}<StateMachine name="Pip" id="{sid(1)}">')
    L.append(f'{P}  <StateMachineLayer name="Stage" id="{sid(2)}">')
    L.append(f'{P}    <AnyState x="560" y="-120"/>')
    L.append(f'{P}    <ExitState x="760" y="-120"/>')
    L.append(f'{P}    <EntryState x="40" y="-120">')
    L.append(f'{P}      <StateTransition stateToId="{sid(20 + 1)}" duration="0"/>')
    L.append(f'{P}    </EntryState>')
    for n in (1, 2, 3, 4):
        L.append(f'{P}    <AnimationState x="{120 * n}" y="-120" '
                 f'animationId="{sid(530 + n)}" id="{sid(20 + n)}">')
        for m in (1, 2, 3, 4):
            L.append(f'{P}      <StateTransition stateToId="{sid(20 + m)}" duration="120">')
            L.append(f'{P}        <TransitionViewModelCondition opValue="equal">')
            L.append(f'{P}          <TransitionPropertyViewModelComparator>')
            L.append(f'{P}            <BindablePropertyNumber>')
            L.append(f'{P}              <DataBindContext sourcePathIds="0:500-0:503" '
                     f'propertyKey="636"/>')
            L.append(f'{P}            </BindablePropertyNumber>')
            L.append(f'{P}          </TransitionPropertyViewModelComparator>')
            L.append(f'{P}          <TransitionValueNumberComparator value="{m}"/>')
            L.append(f'{P}        </TransitionViewModelCondition>')
            L.append(f'{P}      </StateTransition>')
        L.append(f'{P}    </AnimationState>')
    L.append(f"{P}  </StateMachineLayer>")

    # per-rig trios: Body/Eyes/FX layers per rig sharing one topology.
    # ns-6 id budget: layers Body 3..6, Eyes 7..10, FX 11..14; per rig i:
    # states SB..SB+6 (body), SB+10..SB+16 (eyes), SB+20..SB+26 (fx);
    # anims  AB..AB+6  (body), AB+10..AB+16 (eyes), AB+20..AB+26 (fx).
    BORD = ["idle", "happy", "eating", "sleepy", "surprised", "proud", "evolve"]
    EORD = ["open", "blink", "happy", "eating", "sleepy", "surprised", "proud"]
    FORD = ["idle", "happy", "eating", "sleepy", "surprised", "proud", "evolve"]
    for i, n in enumerate((1, 2, 3, 4)):
        SB, AB = 100 + i * 40, 400 + i * 30
        # ---- Body layer
        L.append(f'{P}  <StateMachineLayer name="Body{n}" id="{sid(3 + i)}">')
        L.append(f'{P}    <AnyState x="560" y="-120"/>')
        L.append(f'{P}    <ExitState x="760" y="-120"/>')
        L.append(f'{P}    <EntryState x="40" y="-120">')
        L.append(f'{P}      <StateTransition stateToId="{sid(SB)}" duration="0"/>')
        L.append(f'{P}    </EntryState>')
        for k, m in enumerate(BORD):
            L.append(f'{P}    <AnimationState x="{160 + 200 * k}" y="{-40 + 80 * i}" '
                     f'animationId="{sid(AB + k)}" id="{sid(SB + k)}">')
            if m == "idle":
                for mm, v in (("happy", 1), ("eating", 2), ("sleepy", 3),
                              ("surprised", 4), ("proud", 5)):
                    L += _mood_cond(sid(SB + BORD.index(mm)), v, 150, P + "  ")
                L += _trig_cond(sid(SB + 1), "0:510", 120, P + "  ")
                L += _trig_cond(sid(SB + 6), "0:509", 100, P + "  ")
            elif m == "sleepy":
                for mm, v in (("idle", 0), ("happy", 1), ("eating", 2),
                              ("surprised", 4), ("proud", 5)):
                    L += _mood_cond(sid(SB + BORD.index(mm)), v, 150, P + "  ")
                L += _trig_cond(sid(SB + 6), "0:509", 100, P + "  ")
            else:
                L += _exit(sid(SB), 220 if m != "evolve" else 300, P + "  ")
            L.append(f'{P}    </AnimationState>')
        L.append(f"{P}  </StateMachineLayer>")
        # ---- Eyes layer
        L.append(f'{P}  <StateMachineLayer name="Eyes{n}" id="{sid(7 + i)}">')
        L.append(f'{P}    <AnyState x="560" y="-220"/>')
        L.append(f'{P}    <ExitState x="760" y="-220"/>')
        L.append(f'{P}    <EntryState x="40" y="-220">')
        L.append(f'{P}      <StateTransition stateToId="{sid(SB + 10)}" duration="0"/>')
        L.append(f'{P}    </EntryState>')
        for k, m in enumerate(EORD):
            L.append(f'{P}    <AnimationState x="{160 + 200 * k}" y="{-140 + 80 * i}" '
                     f'animationId="{sid(AB + 10 + k)}" id="{sid(SB + 10 + k)}">')
            if m == "open":
                for mm, v in (("happy", 1), ("eating", 2), ("sleepy", 3),
                              ("surprised", 4), ("proud", 5)):
                    L += _mood_cond(sid(SB + 10 + EORD.index(mm)), v, 80, P + "  ")
                L += _trig_cond(sid(SB + 11), "0:511", 80, P + "  ")
            elif m == "sleepy":
                for mm, v in (("open", 0), ("happy", 1), ("eating", 2),
                              ("surprised", 4), ("proud", 5)):
                    L += _mood_cond(sid(SB + 10 + EORD.index(mm)), v, 80, P + "  ")
            elif m == "blink":
                L += _exit(sid(SB + 10), 80, P + "  ")
            else:
                L += _exit(sid(SB + 10), 150, P + "  ")
            L.append(f'{P}    </AnimationState>')
        L.append(f"{P}  </StateMachineLayer>")
        # ---- FX layer
        L.append(f'{P}  <StateMachineLayer name="FX{n}" id="{sid(11 + i)}">')
        L.append(f'{P}    <AnyState x="560" y="-320"/>')
        L.append(f'{P}    <ExitState x="760" y="-320"/>')
        L.append(f'{P}    <EntryState x="40" y="-320">')
        L.append(f'{P}      <StateTransition stateToId="{sid(SB + 20)}" duration="0"/>')
        L.append(f'{P}    </EntryState>')
        for k, m in enumerate(FORD):
            L.append(f'{P}    <AnimationState x="{160 + 200 * k}" y="{-240 + 80 * i}" '
                     f'animationId="{sid(AB + 20 + k)}" id="{sid(SB + 20 + k)}">')
            if m == "idle":
                for mm, v in (("happy", 1), ("eating", 2), ("sleepy", 3),
                              ("surprised", 4), ("proud", 5)):
                    L += _mood_cond(sid(SB + 20 + FORD.index(mm)), v, 120, P + "  ")
                L += _trig_cond(sid(SB + 26), "0:509", 100, P + "  ")
            elif m == "sleepy":
                for mm, v in (("idle", 0), ("happy", 1), ("eating", 2),
                              ("surprised", 4), ("proud", 5)):
                    L += _mood_cond(sid(SB + 20 + FORD.index(mm)), v, 120, P + "  ")
                L += _trig_cond(sid(SB + 26), "0:509", 100, P + "  ")
            else:
                L += _exit(sid(SB + 20), 180 if m != "evolve" else 250, P + "  ")
            L.append(f'{P}    </AnimationState>')
        L.append(f"{P}  </StateMachineLayer>")
    L.append(f"{P}</StateMachine>")
    L.append("")

    # ---- timelines: stage visibility + per-rig trios (nodes in 31..34,
    # anims in 6:* via ax)
    for n in (1, 2, 3, 4):
        L.append(f'{P}<LinearAnimation name="stage_{n}" duration="1" fps="60" '
                 f'loopValue="loop" id="{sid(530 + n)}">')
        for m in (1, 2, 3, 4):
            L.append(f'{P}  <KeyedObject objectId="{sid(250 + m)}">')
            L.append(f'{P}    <KeyedProperty propertyKey="18">')
            L.append(f'{P}      <KeyFrameDouble value="{1 if m == n else 0}" '
                     f'interpolationType="hold"/>')
            L.append(f"{P}    </KeyedProperty>")
            L.append(f"{P}  </KeyedObject>")
        L.append(f"{P}</LinearAnimation>")
        L.append("")
    for i, n in enumerate((1, 2, 3, 4)):
        SB, AB = 100 + i * 40, 400 + i * 30
        ax6 = lambda v: f"6:{v}"
        L.append(f"        <!-- rig {n} trio timelines (nodes {RIG_NS[n]}:*) -->")
        use_ns(RIG_NS[n])
        em = Emitter()
        L += body_anims(em, rig_P[n], n == 1,
                        aids={k: AB + kk for kk, k in enumerate(BORD)},
                        ax=ax6)
        L += eyes_anims(em,
                        aids={k: AB + 10 + kk for kk, k in enumerate(EORD)},
                        ax=ax6)
        L += fx_anims(em, rig_P[n],
                      aids={k: AB + 20 + kk for kk, k in enumerate(FORD)},
                      ax=ax6)
    use_ns(6)
    L.append("    </Artboard>")
    L.append("")
    L.append("<!-- shared view model + converters live in shared.rml -->")
    L.append("</Rive>")
    return "\n".join(L) + "\n"


def main():
    import shutil
    names = {1: "stage1", 2: "stage2", 3: "stage3", 4: "stage4"}
    for n in (1, 2, 3, 4):
        xml, _ = build_stage(n)
        path = os.path.join(OUT, f"{names[n]}.rml")
        with open(path, "w") as fh:
            fh.write(xml)
        print(f"  stage{n}  {len(xml):>7} bytes -> {path}")
    xml = build_pipstage()
    path = os.path.join(OUT, "pipstage.rml")
    with open(path, "w") as fh:
        fh.write(xml)
    print(f"  pipstage {len(xml):>7} bytes -> {path}")
    xml = shared_rml()
    path = os.path.join(OUT, "shared.rml")
    with open(path, "w") as fh:
        fh.write(xml)
    print(f"  shared   {len(xml):>7} bytes -> {path}")
    with open(os.path.join(OUT, "rive.yaml"), "w") as fh:
        fh.write("name: pip_mochi\nmain: Stage3\nbuild:\n  directory: build\n"
                 "logs:\n  file: build/rive.log\n  problems: build/problems.log\n")


if __name__ == "__main__":
    main()
