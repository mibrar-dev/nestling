#!/usr/bin/env python3
"""
svg2rml.py - convert Nestling's brand SVG illustrations into Rive RML.

Rive's custom geometry is a <PointsPath> holding vertices. Each vertex carries
an incoming and an outgoing control point expressed as (rotation, distance)
from the vertex. SVG paths are cubic/quadratic Beziers, so this script:

  1. parses the `d` attribute into absolute segments (M/L/H/V/C/S/Q/T/Z),
  2. promotes quadratics to cubics (exact, not an approximation),
  3. emits one vertex per anchor point:
       StraightVertex        when both adjacent sides are straight
       CubicDetachedVertex   otherwise, with in/out rotation + distance
       - a 0 distance means "this side is a straight line".

Ellipse / circle / rect map onto Rive's parametric primitives, which is exact
and far smaller than tessellating them.

Every shape is emitted with its pivot as the Shape's x/y and its geometry
expressed relative to that pivot, so rotations and scales happen about a point
we choose rather than about the origin.
"""

from __future__ import annotations

import math
import re
import xml.etree.ElementTree as ET

SVG_NS = "{http://www.w3.org/2000/svg}"

# Largest number of decimals kept in the emitted RML. Rive stores f32, so
# 3 decimals is already well past the noise floor and keeps the file small.
ND = 2


def num(v: float) -> str:
    """Format a float compactly, dropping trailing zeros."""
    s = f"{v:.{ND}f}".rstrip("0").rstrip(".")
    return "0" if s in ("", "-0") else s


# --------------------------------------------------------------------------
# SVG path data
# --------------------------------------------------------------------------

TOKEN = re.compile(r"([MmZzLlHhVvCcSsQqTt])|([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)")


def tokenize(d: str):
    for m in TOKEN.finditer(d):
        if m.group(1):
            yield ("cmd", m.group(1))
        else:
            yield ("num", float(m.group(2)))


def parse_path(d: str):
    """Return a list of subpaths; each subpath is a list of
    (x, y, in_ctrl | None, out_ctrl | None) anchors."""
    toks = list(tokenize(d))
    i = 0
    subpaths = []
    cur = []
    cx = cy = 0.0          # current point
    sx = sy = 0.0          # subpath start
    prev_c2 = None         # previous cubic's second control point, for S
    prev_q = None          # previous quadratic control point, for T
    cmd = None
    just_moved = False     # extra coordinate pairs after M/m are implicit L/l

    def flush():
        nonlocal cur
        if len(cur) > 1:
            subpaths.append(cur)
        cur = []

    def anchor(x, y, inc, outc):
        # Replace a trailing anchor that is identical to this one, keeping the
        # side we already recorded and adopting the new outgoing control.
        if cur and abs(cur[-1][0] - x) < 1e-9 and abs(cur[-1][1] - y) < 1e-9:
            px, py, pin, _ = cur[-1]
            cur[-1] = (px, py, pin, outc)
        else:
            cur.append((x, y, inc, outc))

    def need(n):
        nonlocal i
        vals = []
        for _ in range(n):
            vals.append(toks[i][1])
            i += 1
        return vals

    while i < len(toks):
        kind, val = toks[i]
        if kind == "cmd":
            cmd = val
            i += 1
            just_moved = cmd in "Mm"
            if cmd in "Zz":
                # SVG's Z is always a straight closing side, so it carries no
                # control points. Append the start anchor if the path did not
                # already end there; Rive closes the contour for us.
                if cur:
                    fx, fy, _, _ = cur[0]
                    if abs(fx - cx) > 1e-9 or abs(fy - cy) > 1e-9:
                        cur.append((fx, fy, None, None))
                flush()
                cx, cy = sx, sy
                prev_c2 = prev_q = None
                continue
        else:
            # Implicit repeat: extra coordinate pairs after M/m are L/l.
            if just_moved:
                cmd = "L" if cmd == "M" else "l"
                just_moved = False

        rel = cmd.islower()
        c = cmd.upper()

        if c == "M":
            x, y = need(2)
            if rel:
                x, y = cx + x, cy + y
            flush()
            cur = []
            anchor(x, y, None, None)
            cx, cy = x, y
            sx, sy = x, y
            prev_c2 = prev_q = None
        elif c == "L":
            x, y = need(2)
            if rel:
                x, y = cx + x, cy + y
            anchor(x, y, None, None)
            cx, cy = x, y
            prev_c2 = prev_q = None
        elif c == "H":
            (x,) = need(1)
            if rel:
                x = cx + x
            anchor(x, cy, None, None)
            cx = x
            prev_c2 = prev_q = None
        elif c == "V":
            (y,) = need(1)
            if rel:
                y = cy + y
            anchor(cx, y, None, None)
            cy = y
            prev_c2 = prev_q = None
        elif c == "C":
            x1, y1, x2, y2, x, y = need(6)
            if rel:
                x1, y1, x2, y2, x, y = (cx + x1, cy + y1, cx + x2, cy + y2,
                                         cx + x, cy + y)
            anchor(x, y, (x2, y2), None)
            px, py, pin, _ = cur[-2] if len(cur) >= 2 else (cx, cy, None, None)
            cur[-2] = (px, py, pin, (x1, y1))
            cx, cy = x, y
            prev_c2 = (x2, y2)
            prev_q = None
        elif c == "S":
            x2, y2, x, y = need(4)
            if rel:
                x2, y2, x, y = cx + x2, cy + y2, cx + x, cy + y
            if prev_c2 is None:
                x1, y1 = cx, cy
            else:
                x1 = 2 * cx - prev_c2[0]
                y1 = 2 * cy - prev_c2[1]
            anchor(x, y, (x2, y2), None)
            px, py, pin, _ = cur[-2] if len(cur) >= 2 else (cx, cy, None, None)
            cur[-2] = (px, py, pin, (x1, y1))
            cx, cy = x, y
            prev_c2 = (x2, y2)
            prev_q = None
        elif c in ("Q", "T"):
            if c == "Q":
                qx, qy, x, y = need(4)
                if rel:
                    qx, qy, x, y = cx + qx, cy + qy, cx + x, cy + y
            else:
                x, y = need(2)
                if rel:
                    x, y = cx + x, cy + y
                if prev_q is None:
                    qx, qy = cx, cy
                else:
                    qx = 2 * cx - prev_q[0]
                    qy = 2 * cy - prev_q[1]
            # Exact quadratic -> cubic promotion.
            c1 = (cx + 2 / 3 * (qx - cx), cy + 2 / 3 * (qy - cy))
            c2 = (x + 2 / 3 * (qx - x), y + 2 / 3 * (qy - y))
            anchor(x, y, c2, None)
            px, py, pin, _ = cur[-2] if len(cur) >= 2 else (cx, cy, None, None)
            cur[-2] = (px, py, pin, c1)
            cx, cy = x, y
            prev_q = (qx, qy)
            prev_c2 = None
        else:
            raise ValueError(f"unsupported SVG path command: {cmd!r}")

    flush()
    return subpaths


def flatten(subpaths):
    """Merge subpaths into one closed list of anchors, linking the closing side."""
    if not subpaths:
        return []
    sp = subpaths[0]
    pts = list(sp)
    if abs(pts[0][0] - pts[-1][0]) < 1e-9 and abs(pts[0][1] - pts[-1][1]) < 1e-9:
        # Duplicate end anchor: absorb its out-control into the first anchor.
        first, last = pts[0], pts[-1]
        pts = pts[:-1]
        pts[0] = (first[0], first[1], first[2], last[3] or first[3])
    return pts


# --------------------------------------------------------------------------
# Colour
# --------------------------------------------------------------------------

def argb(colour: str, alpha: float = 1.0) -> str:
    """AARRGGBB, exactly 8 hex digits, no leading '#'."""
    c = colour.lstrip("#")
    if len(c) == 3:
        c = "".join(ch * 2 for ch in c)
    r, g, b = int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)
    a = max(0, min(255, round(alpha * 255)))
    return f"{a:02X}{r:02X}{g:02X}{b:02X}"


# --------------------------------------------------------------------------
# Element walking
# --------------------------------------------------------------------------

def _style(el, parent_style):
    st = dict(parent_style)
    for attr in ("fill", "stroke", "stroke-width", "stroke-linecap",
                 "stroke-linejoin", "fill-opacity", "stroke-opacity", "opacity"):
        if attr in el.attrib:
            st[attr] = el.attrib[attr]
    st["_opacity"] = st.get("opacity", "1")
    return st


def _parse_transform(el):
    """Only the rotate(a cx cy) form used by our SVGs is needed."""
    t = el.attrib.get("transform", "")
    if not t:
        return 0.0, 0.0, 0.0
    m = re.match(r"rotate\(([-\d.]+)[,\s]+([-\d.]+)[,\s]+([-\d.]+)\)", t.strip())
    if m:
        return math.radians(float(m.group(1))), float(m.group(2)), float(m.group(3))
    m = re.match(r"rotate\(([-\d.]+)\)", t.strip())
    if m:
        return math.radians(float(m.group(1))), 0.0, 0.0
    return 0.0, 0.0, 0.0


def collect(svg_path):
    """Walk an SVG, returning an ordered list of primitive dicts in SVG
    paint order (first = bottom)."""
    tree = ET.parse(svg_path)
    root = tree.getroot()
    vb = [float(v) for v in root.attrib.get("viewBox", "0 0 240 240").split()]
    out = []

    def walk(node, style):
        if node.tag == f"{SVG_NS}defs" or node.tag == f"{SVG_NS}clipPath":
            return
        st = _style(node, style)
        tag = node.tag.replace(SVG_NS, "")
        op = float(st.get("opacity", "1"))

        if tag == "g":
            for ch in node:
                walk(ch, st)
            return
        if tag in ("path", "ellipse", "circle", "rect"):
            out.append({"tag": tag, "el": node, "style": st, "opacity": op})

    base = {"fill": "#000", "stroke": "none", "stroke-width": "0",
            "stroke-linecap": "butt", "stroke-linejoin": "miter",
            "fill-opacity": "1", "stroke-opacity": "1", "opacity": "1"}
    for ch in root:
        walk(ch, base)

    return out, vb
