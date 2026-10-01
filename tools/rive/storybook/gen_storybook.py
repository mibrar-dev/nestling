#!/usr/bin/env python3
"""
gen_storybook.py — build the Storybook (style C) Rive project.

Source art: design/pip-v2/C/ (APPROVED pose library, skins, accessories,
evolve frames) + app/assets/illustrations/nest.svg for PipStage.
Output: tools/rive/storybook/artboards/*.rml + rive.yaml
Built:   app/assets/animations/rive/pip_storybook.riv (via `rive --once`)

Contract (docs/pip-v2/PIP_V2_CONTRACT.md):
  artboards Stage1..Stage4 + PipStage | view model Pip | state machine Pip
  (Body / Eyes / FX layers) | part ids = contract ids.

Method: the idle pose of each stage is the rest art. Eye/beak variants, FX
sets and accessories are harvested from the peak poses (with the poses' baked
rigid transforms applied), and every mood is keyed Node transforms +
opacity swaps — so motion is full-body acting, not a face swap.

RML traps respected (docs/animation/RIVE_GUIDE.md §7):
  scale = multiplier · x/y = ABSOLUTE · first child draws ON TOP ·
  exitTimeIsPercetange typo · transition duration = ms · states have no name.
"""

from __future__ import annotations

import math
import os
import re
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
import svg2rml as S  # noqa: E402
import gen_pip as G  # noqa: E402 — reuse SVG->RML geometry + nest constants

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
C_DIR = os.path.join(ROOT, "design", "pip-v2", "C")
POSES = os.path.join(C_DIR, "poses")
SKINS = os.path.join(C_DIR, "skins")
ACC = os.path.join(C_DIR, "accessories")
OUT = HERE  # artboards/ + rive.yaml live next to this script

SVG_NS = "{http://www.w3.org/2000/svg}"
STAGES = [int(os.environ.get("SB_STAGE", "0"))] if os.environ.get("SB_STAGE") else [1, 2, 3, 4]

GROUND_Y = 214.0  # contract: feet/egg base baseline; shadow centre (120, 214)

MOODS = ["idle", "happy", "eating", "sleepy", "surprised", "proud"]
SKIN_NAMES = ["sunny", "berry", "sky", "mint"]
ACC_NAMES = ["bow", "cap", "scarf", "glasses"]

# ---------------------------------------------------------------- affine 2D


def mat_mul(m, n):
    a, b, c, d, tx, ty = m
    e, f, g, h, ux, uy = n
    return (a * e + b * g, a * f + b * h, c * e + d * g, c * f + d * h,
            a * ux + b * uy + tx, c * ux + d * uy + ty)


IDENT = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
NUM = r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
XF = re.compile(r"(translate|rotate|scale|matrix)\s*\(([^)]*)\)")


def parse_transform(t):
    m = IDENT
    for kind, args in XF.findall(t or ""):
        v = [float(x) for x in re.findall(NUM, args)]
        if kind == "translate":
            tx, ty = (v + [0.0])[:2]
            m = mat_mul(m, (1, 0, 0, 1, tx, ty))
        elif kind == "scale":
            sx = v[0]
            sy = v[1] if len(v) > 1 else sx
            m = mat_mul(m, (sx, 0, 0, sy, 0, 0))
        elif kind == "rotate":
            a = math.radians(v[0])
            co, si = math.cos(a), math.sin(a)
            if len(v) >= 3:
                cx, cy = v[1], v[2]
                m = mat_mul(m, (1, 0, 0, 1, cx, cy))
                m = mat_mul(m, (co, si, -si, co, 0, 0))
                m = mat_mul(m, (1, 0, 0, 1, -cx, -cy))
            else:
                m = mat_mul(m, (co, si, -si, co, 0, 0))
        elif kind == "matrix" and len(v) == 6:
            m = mat_mul(m, tuple(v))
    return m


def mat_apply(m, x, y):
    a, b, c, d, tx, ty = m
    return (a * x + b * y + tx, c * x + d * y + ty)


def mat_params(m):
    """rotation + uniform scale of a rigid matrix; warns via return flag."""
    a, b, c, d, _, _ = m
    sx = math.hypot(a, b)
    sy = math.hypot(c, d)
    rot = math.atan2(b, a)
    rigid = abs(sx - sy) < 1e-6
    return rot, sx, rigid


# ------------------------------------------------------- group-aware collect


def _style(el, parent):
    st = dict(parent)
    for attr in ("fill", "stroke", "stroke-width", "stroke-linecap",
                 "stroke-linejoin", "fill-opacity", "stroke-opacity", "opacity"):
        if attr in el.attrib:
            st[attr] = el.attrib[attr]
    return st


BASE_STYLE = {"fill": "#000", "stroke": "none", "stroke-width": "0",
              "stroke-linecap": "butt", "stroke-linejoin": "miter",
              "fill-opacity": "1", "stroke-opacity": "1", "opacity": "1"}


def collect_tree(svg_path):
    """Walk an SVG; return (prims, vb). Each prim:
    {tag, el, style, opacity, matrix, chain} where chain = ancestor g ids
    from the root (id-less g's recorded as None)."""
    tree = ET.parse(svg_path)
    root = tree.getroot()
    vb = [float(v) for v in root.attrib.get("viewBox", "0 0 240 240").split()]
    prims = []

    def walk(node, style, matrix, chain):
        if node.tag in (f"{SVG_NS}defs", f"{SVG_NS}clipPath"):
            return
        tag = node.tag.replace(SVG_NS, "")
        if tag == "g":
            st = _style(node, style)
            m = mat_mul(matrix, parse_transform(node.attrib.get("transform", "")))
            ch = chain + [node.attrib.get("id")]
            for kid in node:
                walk(kid, st, m, ch)
            return
        if tag in ("path", "ellipse", "circle", "rect"):
            st = _style(node, style)
            m = mat_mul(matrix, parse_transform(node.attrib.get("transform", "")))
            prims.append({"tag": tag, "el": node, "style": st,
                          "opacity": float(st.get("opacity", "1")),
                          "matrix": m, "chain": list(chain)})

    for ch in root:
        walk(ch, dict(BASE_STYLE), IDENT, [])
    return prims, vb


def top_groups(svg_path):
    """Top-level contract groups in doc order, splicing id-less wrappers."""
    tree = ET.parse(svg_path)
    root = tree.getroot()
    out = []

    def expand(node):
        for ch in node:
            if ch.tag != f"{SVG_NS}g":
                continue
            gid = ch.attrib.get("id")
            if gid:
                out.append(ch)
            else:
                expand(ch)  # pose offset wrapper — splice through

    expand(root)
    return out


def find_group(svg_path, *ids):
    """Prims whose ancestor chain ends with the given id path."""
    prims, _ = collect_tree(svg_path)
    return [p for p in prims
            if [c for c in p["chain"] if c][-len(ids):] == list(ids)]


# ------------------------------------------------------------- shape emit


class Ids:
    def __init__(self, ns):
        self.ns = ns
        self.shape = 0
        self.node = 200

    def s(self):
        self.shape += 1
        return f"{self.ns}:{self.shape}"

    def n(self):
        self.node += 1
        return f"{self.ns}:{self.node}"


def _contours(prim):
    """Absolute (240-space) contours with the pose's baked matrix applied."""
    el, tag, m = prim["el"], prim["tag"], prim["matrix"]
    rot, sc, rigid = mat_params(m)
    if tag == "ellipse":
        cx, cy = mat_apply(m, float(el.attrib["cx"]), float(el.attrib["cy"]))
        w = 2 * float(el.attrib["rx"]) * sc
        h = 2 * float(el.attrib["ry"]) * sc
        return ("ellipse", (cx, cy), rot, w, h)
    if tag == "circle":
        cx, cy = mat_apply(m, float(el.attrib["cx"]), float(el.attrib["cy"]))
        d = 2 * float(el.attrib["r"]) * sc
        return ("ellipse", (cx, cy), rot, d, d)
    if tag == "rect":
        x = float(el.attrib["x"])
        y = float(el.attrib["y"])
        w = float(el.attrib["width"]) * sc
        h = float(el.attrib["height"]) * sc
        rr = float(el.attrib.get("rx", 0) or 0) * sc
        cx, cy = mat_apply(m, x + w / 2 / sc, y + h / 2 / sc) \
            if False else mat_apply(m, x + float(el.attrib["width"]) / 2,
                                    y + float(el.attrib["height"]) / 2)
        return ("rect", (cx, cy), rot, w, h, rr)
    filled = prim["style"].get("fill", "none") not in ("none", "")
    out = []
    for sp in G.subpaths(el.attrib["d"]):
        tsp = []
        for (x, y, ic, oc) in sp:
            nx, ny = mat_apply(m, x, y)
            nic = mat_apply(m, *ic) if ic else None
            noc = mat_apply(m, *oc) if oc else None
            tsp.append((nx, ny, nic, noc))
        out.append((tsp, filled))
    return ("paths", out)


def _bbox_of_prims(prims):
    xs, ys = [], []
    for p in prims:
        c = _contours(p)
        if c[0] == "ellipse":
            (_, (cx, cy), _, w, h) = c
            xs += [cx - w / 2, cx + w / 2]
            ys += [cy - h / 2, cy + h / 2]
        elif c[0] == "rect":
            (_, (cx, cy), _, w, h, _) = c
            xs += [cx - w / 2, cx + w / 2]
            ys += [cy - h / 2, cy + h / 2]
        else:
            for sp, _ in c[1]:
                xs += [pt[0] for pt in sp]
                ys += [pt[1] for pt in sp]
    return (min(xs), min(ys), max(xs), max(ys))


class StageArt:
    def __init__(self, stage):
        self.stage = stage
        self.base = os.path.join(POSES, f"s{stage}_idle_1.svg")
        self.prims, _ = collect_tree(self.base)
        self.groups = {}
        for g in top_groups(self.base):
            gid = g.attrib.get("id")
            self.groups.setdefault(gid, [])
            # prims whose outermost named ancestor is this group
            for p in self.prims:
                named = [c for c in p["chain"] if c]
                if named and named[0] == gid:
                    self.groups[gid].append(p)
        self.has = lambda gid: len(self.groups.get(gid, [])) > 0
        self._harvest()

    def _eye(self, side, variant, files):
        for f in files:
            ps = find_group(f, f"eye_{side}", variant)
            if ps:
                return ps
        return []

    def _harvest(self):
        s = self.stage
        P = lambda *a: os.path.join(POSES, *a)  # noqa: E731
        F = lambda m, n=1: P(f"s{s}_{m}_{n}.svg")  # noqa: E731
        self.eye = {}
        for side in ("l", "r"):
            self.eye[side] = {
                "open": find_group(self.base, f"eye_{side}", "open"),
                "closed": self._eye(side, "closed",
                                    [P(f"s{s}_blink_2.svg"), F("sleepy", 2),
                                     F("sleepy", 3)]),
                "happy": self._eye(side, "happy",
                                   [F("happy", 2), F("happy", 1), F("happy", 3),
                                    F("eating", 2)]),
                "sleepy": self._eye(side, "sleepy", [F("sleepy", 1)]) or
                self._eye(side, "closed", [F("sleepy", 2), F("sleepy", 3)]),
                "surprised": self._eye(side, "surprised",
                                       [F("surprised", 2), F("surprised", 1)]),
                "wink": self._eye(side, "wink", [F("proud", 2)]),
            }
        # beak: base closed top; open bottom from a feeding/happy peak
        self.beak_bottom = []
        for f in (F("happy", 2), F("eating", 2), F("happy", 3)):
            if os.path.exists(f):
                ps = find_group(f, "beak_bottom")
                if ps:
                    self.beak_bottom = ps
                    break
        self.beak_top_o = []
        for f in (F("surprised", 2), F("surprised", 1)):
            if os.path.exists(f):
                ps = find_group(f, "beak_top")
                if len(ps) >= 2:
                    self.beak_top_o = ps
                    break
        # fx sets, split by sub-group where the pose separates them
        def fx_of(m, n=2):
            f = F(m, n)
            return find_group(f, "fx") if os.path.exists(f) else []
        self.fx = {}
        self.fx["happy"] = fx_of("happy")
        seed = fx_of("eating")
        self.fx["seed"] = [p for p in seed if (p["chain"][-1] is None)]
        # eating_2 fx = sub-g(seed ตpples) + loose crumb circles
        grouped = [p for p in seed if p not in self.fx["seed"]]
        self.fx["crumbs"] = grouped if grouped else []
        if not self.fx["seed"] and seed:
            self.fx["seed"] = seed[:2]
            self.fx["crumbs"] = seed[2:]
        sl = fx_of("sleepy")
        # sleepy_2 fx = id-less sub-g (nightcap, rides the head) + Z letters
        self.fx["sleep"] = [p for p in sl if p["chain"] and p["chain"][-1] is None]
        self.fx["zzz"] = [p for p in sl if p not in self.fx["sleep"]]
        if not self.fx["sleep"] and sl:
            # no sub-group: keep cap slot empty, drift the whole set as Zzz
            self.fx["zzz"] = sl
        self.fx["bang"] = fx_of("surprised")
        self.fx["proud"] = fx_of("proud")
        # accessories (full-scene files; take only the accessory groups)
        self.acc = {}
        bow_f = os.path.join(ACC, f"s{s}_idle_bow.svg")
        cap_f = os.path.join(ACC, f"s{s}_idle_cap.svg")
        scarf_f = os.path.join(ACC, f"s{s}_idle_scarf.svg")
        gl_f = os.path.join(ACC, f"s{s}_idle_glasses.svg")
        self.acc["bow"] = find_group(bow_f, "accessory_head")
        self.acc["cap"] = find_group(cap_f, "accessory_head")
        self.acc["scarf"] = find_group(scarf_f, "accessory_neck")
        self.acc["glasses"] = find_group(gl_f, "accessory_face")

    def anchors(self):
        """Key pivots in absolute 240-space + eye/beak metrics from base."""
        A = {}
        A["root"] = (120.0, GROUND_Y)
        body = self.groups.get("body", [])
        if body:
            A["body"] = _ctr(body)
        else:
            A["body"] = (120.0, 140.0)
        lo = self.eye["l"]["open"]
        ro = self.eye["r"]["open"]
        if lo and ro:
            lc, rc = _ctr(lo), _ctr(ro)
            A["head"] = ((lc[0] + rc[0]) / 2, (lc[1] + rc[1]) / 2)
            A["eye_l"], A["eye_r"] = lc, rc
            A["eye_rx"] = _bbox_of_prims(lo)[2] - lc[0]
        else:
            A["head"] = (120.0, 130.0)
            A["eye_l"], A["eye_r"] = (96.0, 130.0), (144.0, 130.0)
            A["eye_rx"] = 14.0
        tuft = self.groups.get("head_tuft", [])
        if tuft:
            x0, _, x1, y1 = _bbox_of_prims(tuft)
            A["tuft"] = ((x0 + x1) / 2, y1)
        else:
            A["tuft"] = None
        for w in ("wing_l", "wing_r"):
            ps = self.groups.get(w, [])
            if ps:
                x0, y0, x1, y1 = _bbox_of_prims(ps)
                A[w] = (x1, (y0 + y1) / 2) if w == "wing_l" else (x0, (y0 + y1) / 2)
            else:
                A[w] = None
        tail = self.groups.get("tail", [])
        if tail:
            x0, y0, x1, y1 = _bbox_of_prims(tail)
            A["tail"] = ((x0 + x1) / 2, y0)
        else:
            A["tail"] = None
        bt = self.groups.get("beak_top", [])
        if bt:
            x0, y0, x1, y1 = _bbox_of_prims(bt)
            A["beak"] = ((x0 + x1) / 2, (y0 + y1) / 2)
            A["beak_hw"] = (x1 - x0) / 2
        else:
            A["beak"] = (A["head"][0], A["head"][1] + 22)
            A["beak_hw"] = 13.0
        A["art_bottom"] = _bbox_of_prims(
            [p for p in self.prims if "shadow" not in p["chain"]])[3]
        return A


def _ctr(prims):
    x0, y0, x1, y1 = _bbox_of_prims(prims)
    return ((x0 + x1) / 2, (y0 + y1) / 2)


# synth variants are built in the rig emitter (needs anchors first)

INK = "#1E1B3A"


def _mk_prim(tag, attrs, style):
    el = ET.Element(tag, attrs)
    return {"tag": tag, "el": el, "style": dict(style), "opacity": 1.0,
            "matrix": IDENT, "chain": []}


def _full_style(fill="none", stroke="none", sw=0, cap="round", join="round"):
    return {"fill": fill, "stroke": stroke, "stroke-width": str(sw),
            "stroke-linecap": cap, "stroke-linejoin": join,
            "fill-opacity": "1", "stroke-opacity": "1", "opacity": "1"}


def _stroke_of(prims, default_w=5.0):
    for p in prims:
        st = p["style"]
        if st.get("stroke", "none") not in ("none", ""):
            try:
                return float(st.get("stroke-width", default_w) or default_w)
            except ValueError:
                return default_w
    return default_w


def synth_variants(art, A):
    """Procedural eye/beak variants on base anchors (styles borrowed from the
    harvested peak poses so the linework matches the approved art)."""
    V = {}
    lc, rc = A["eye_l"], A["eye_r"]
    rx = A.get("eye_rx", 14.0)
    lo = art.eye["l"]["open"]
    w_white = _stroke_of(lo)
    # white/pupil geometry from base open prims (for surprised scaling)
    white_c, white_r, pupil_c, pupil_r = None, None, None, None
    for p in lo:
        f = p["style"].get("fill", "")
        if p["tag"] in ("ellipse", "circle") and f.upper() == "#FFFFFF" \
                and white_c is None:
            c = _contours(p)
            if c[0] == "ellipse":
                white_c, white_r = c[1], (c[3] / 2, c[4] / 2)
        if f.upper() == INK and pupil_c is None and p["tag"] in ("ellipse", "circle"):
            c = _contours(p)
            if c[0] == "ellipse":
                pupil_c, pupil_r = c[1], c[3] / 2
    if white_c is None:
        white_c, white_r = lc, (rx, rx)
    if pupil_c is None:
        pupil_c, pupil_r = lc, 5.0
    happy_src = art.eye["l"]["happy"] or art.eye["l"]["open"]
    hw = _stroke_of(happy_src, w_white)
    ink_curve = _full_style(fill="none", stroke=INK, sw=hw)
    closed_src = art.eye["l"]["closed"] or art.eye["l"]["open"]
    cw = _stroke_of(closed_src, w_white)

    for side, c in (("l", lc), ("r", rc)):
        d = {}
        # closed: gentle downward curve
        d["closed"] = [_mk_prim(
            "path", {"d": f"M{c[0]-rx} {c[1]+1} Q{c[0]} {c[1]+7} {c[0]+rx} {c[1]+1}"},
            _full_style(fill="none", stroke=INK, sw=cw))]
        # happy ^^: high arc
        d["happy"] = [_mk_prim(
            "path", {"d": f"M{c[0]-rx} {c[1]+5} Q{c[0]} {c[1]-12} {c[0]+rx} {c[1]+5}"},
            ink_curve)]
        # sleepy: low droop curve
        d["sleepy"] = [_mk_prim(
            "path", {"d": f"M{c[0]-rx} {c[1]-1} Q{c[0]} {c[1]+5} {c[0]+rx} {c[1]-1}"},
            _full_style(fill="none", stroke=INK, sw=cw))]
        # wink: shallow happy arc
        d["wink"] = [_mk_prim(
            "path", {"d": f"M{c[0]-rx} {c[1]+3} Q{c[0]} {c[1]-6} {c[0]+rx} {c[1]+3}"},
            ink_curve)]
        # surprised: bigger white + bigger pupil (base style, scaled).
        # Pupil offset is mirrored per side so each pupil sits centred in
        # its own white (same relative offset as the approved art).
        wc = (c[0], c[1])
        dx = (pupil_c[0] - white_c[0]) if (white_c and pupil_c) else 2.0
        dy = (pupil_c[1] - white_c[1]) if (white_c and pupil_c) else 2.0
        pr = pupil_r * 1.5
        d["surprised"] = [
            _mk_prim("ellipse",
                     {"cx": S.num(wc[0]), "cy": S.num(wc[1]),
                      "rx": S.num(white_r[0] * 1.3), "ry": S.num(white_r[1] * 1.35)},
                     _full_style(fill="#FFFFFF", stroke=INK, sw=w_white)),
            _mk_prim("circle",
                     {"cx": S.num(c[0] + dx),
                      "cy": S.num(c[1] + dy), "r": S.num(pr)},
                     _full_style(fill=INK)),
            _mk_prim("circle",
                     {"cx": S.num(c[0] + dx - pr * 0.35),
                      "cy": S.num(c[1] + dy - pr * 0.4),
                      "r": S.num(pr * 0.38)},
                     _full_style(fill="#FFFFFF")),
        ]
        V[side] = d
    # open mouth interior: style harvested from a peak beak_bottom
    interior = "#7A2E3A"
    for p in (art.beak_bottom or []):
        f = p["style"].get("fill", "")
        if f and f.upper() not in ("#FF8A5B", INK, "NONE", ""):
            interior = f
            break
    bcx, bcy, bhw = A["beak"][0], A["beak"][1], A["beak_hw"]
    V["beak_bottom_open"] = [_mk_prim(
        "ellipse", {"cx": S.num(bcx), "cy": S.num(bcy + 9),
                    "rx": S.num(bhw * 0.95), "ry": "10"},
        _full_style(fill=interior, stroke=INK, sw=4))]
    V["beak_top_o"] = [_mk_prim(
        "ellipse", {"cx": S.num(bcx), "cy": S.num(bcy + 5),
                    "rx": S.num(bhw * 0.55), "ry": "9"},
        _full_style(fill=interior, stroke=INK, sw=4.5))]
    return V


# ------------------------------------------------------------ skin binding

SKIN_DEFAULTS = {
    "sunny":  ("#FFD93D", "#FFF1B8"),
    "berry":  ("#FF9EBB", "#FFE1EA"),
    "sky":    ("#8EC9FF", "#E2F1FF"),
    "mint":   ("#8EE3B5", "#DDF8E8"),
}
# sunny reference fills (measured from skins/s3_idle_sunny.svg)
SKIN_BASES = {}  # fill upper -> color prop


def load_skin_bases():
    f = os.path.join(SKINS, "s3_idle_sunny.svg")
    prims, _ = collect_tree(f)
    by_group = {}
    for p in prims:
        named = [c for c in p["chain"] if c]
        g = named[0] if named else ""
        by_group.setdefault(g, []).append(p["style"].get("fill", ""))
    def fill(g, i=0):
        return (by_group.get(g, [""])[i] or "").upper()
    SKIN_BASES.clear()
    SKIN_BASES[fill("body")] = "bodyColor"
    SKIN_BASES[fill("head_tuft")] = "bodyColor"
    SKIN_BASES[fill("belly")] = "bellyColor"
    SKIN_BASES[fill("wing_l")] = "wingColor"
    SKIN_BASES[fill("wing_r")] = "wingColor"
    SKIN_BASES[fill("tail")] = "wingColor"
    # body shade (second body fill) gets its own prop
    if len(by_group.get("body", [])) > 1:
        SKIN_BASES[by_group["body"][1].upper()] = "shadeColor"


COLOR_DEFAULTS = {
    "bodyColor": "#FFD93D", "bellyColor": "#FFF1B8",
    "wingColor": "#F2A900", "shadeColor": "#F2B705",
}


# ------------------------------------------------------------ rig emission

class Ctx:
    def __init__(self, ns):
        self.ns = ns
        self.ids = Ids(ns)
        # state machine / animation / view model ids (filled by caller order)
        self.SM = f"{ns}:300"
        self.L_BODY = f"{ns}:301"
        self.L_EYES = f"{ns}:302"
        self.L_FX = f"{ns}:303"
        self.VM = f"{ns}:500"
        self.VMI = f"{ns}:501"


def _shape_rows(prims, name, sid, origin, ind, ctx, props, opacity=None,
                extra_binds=()):
    """Shapes for prims + optional skin fill binds + extra DataBindContexts
    (extra_binds: propertyKeys bound to the SHAPE, e.g. opacity)."""
    pad = " " * ind
    rows = []
    minted = []
    for p in prims:
        c = _contours(p)
        geos = []  # (geo_rows, rot, px, py)
        if c[0] == "ellipse":
            (_, (cx, cy), rot, w, h) = c
            geos.append((f'{pad}  <Ellipse width="{S.num(w)}" height="{S.num(h)}" '
                         f'name="P"/>', rot, cx, cy))
        elif c[0] == "rect":
            (_, (cx, cy), rot, w, h, rr) = c
            geos.append((f'{pad}  <Rectangle width="{S.num(w)}" height="{S.num(h)}" '
                         f'cornerRadiusTL="{S.num(rr)}" linkCornerRadius="true" '
                         f'name="P"/>', rot, cx, cy))
        else:
            for sp, filled in c[1]:
                xs = [pt[0] for pt in sp]
                ys = [pt[1] for pt in sp]
                px, py = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2)
                rel = [((x - px, y - py,
                         (ic[0] - px, ic[1] - py) if ic else None,
                         (oc[0] - px, oc[1] - py) if oc else None))
                       for (x, y, ic, oc) in sp]
                grows = [f'{pad}  <PointsPath isClosed="{str(filled).lower()}">']
                for (vx, vy, ic, oc) in rel:
                    if ic is None and oc is None:
                        grows.append(f'{pad}    <StraightVertex x="{S.num(vx)}" '
                                     f'y="{S.num(vy)}"/>')
                        continue
                    ir = G.rd((ic[0] - vx, ic[1] - vy)) if ic else (0.0, 0.0)
                    orr = G.rd((oc[0] - vx, oc[1] - vy)) if oc else (0.0, 0.0)
                    grows.append(
                        f'{pad}    <CubicDetachedVertex x="{S.num(vx)}" '
                        f'y="{S.num(vy)}" inRotation="{S.num(ir[0])}" '
                        f'inDistance="{S.num(ir[1])}" '
                        f'outRotation="{S.num(orr[0])}" '
                        f'outDistance="{S.num(orr[1])}"/>')
                grows.append(f"{pad}  </PointsPath>")
                geos.append(("\n".join(grows), 0.0, px, py))
        # one RML Shape per contour; paint rows per source prim
        for (geo, rot, px, py) in geos:
            one_id = ctx.ids.s()  # every Shape needs a unique id
            minted.append(one_id)
            rot_s = f' rotation="{S.num(rot)}"' if abs(rot) > 1e-9 else ""
            op_s = f' opacity="{opacity}"' if opacity is not None else ""
            rows.append(f'{pad}<Shape x="{S.num(px - origin[0])}" '
                        f'y="{S.num(py - origin[1])}"{rot_s}{op_s} name="{name}" '
                        f'id="{one_id}">')
            rows.append(geo)
            rows += _paint_rows(p, ind, ctx, props)
            for pk, prop in extra_binds:
                rows.append(f'{pad}  <DataBindContext sourcePathIds="{ctx.VM}-{prop}" '
                            f'propertyKey="{pk}"/>')
            rows.append(f"{pad}</Shape>")
    return rows, minted


def _paint_rows(prim, ind, ctx=None, props=None):
    rows = G.paints(prim["style"], prim["opacity"], ind)
    if ctx is not None and props is not None:
        fill = (prim["style"].get("fill", "") or "").upper()
        if fill in SKIN_BASES:
            prop = props[SKIN_BASES[fill]]
            # attach the bind inside the Fill's SolidColor only (the first
            # one); the Stroke keeps its authored ink.
            out = []
            bound = False
            for r in rows:
                out.append(r)
                if not bound and '<SolidColor colorValue=' in r and 'name="C"' in r:
                    bound = True
                    out.append(f'{" " * ind}  <DataBindContext sourcePathIds="{ctx.VM}-{prop}" '
                               f'propertyKey="37"/>')
                    # SolidColor must wrap the context: rewrite as open element
                    out[-2] = r.replace('name="C"/>', 'name="C">')
                    out.append(f'{" " * ind}  </SolidColor>')
            return out
    return rows


# ------------------------------------------------------------ rig assembly

def _node_open(name, nid, x, y, ind, opacity=None, binds=(), ctx=None):
    pad = " " * ind
    op = f' opacity="{opacity}"' if opacity is not None else ""
    rows = [f'{pad}<Node x="{S.num(x)}" y="{S.num(y)}"{op} name="{name}" id="{nid}">']
    for pk, prop in binds:
        rows.append(f'{pad}  <DataBindContext sourcePathIds="{ctx.VM}-{prop}" '
                    f'propertyKey="{pk}"/>')
    return rows


def emit_rig(art, A, V, ctx, props, ind, P=None):
    """Front-to-back node tree + shape id registry for the animators."""
    s = art.stage
    ids = ctx.ids
    R = {"eye_op": {}, "open": [], "cheeks": [], "fx": {}, "acc": {},
         "rest": {}}
    rows = []
    pad = " " * ind
    RX, RY = A["root"]

    def shapes(prims, name, origin, level, opacity=None, extra=()):
        sid = ids.s()
        r, minted = _shape_rows(prims, name, sid, origin, level, ctx, props,
                               opacity=opacity, extra_binds=extra)
        rows.extend(r)
        return minted

    # ---- pip_root
    R["root"] = ids.n()
    R["rest"][R["root"]] = (RX, RY)
    rows += _node_open("pip_root", R["root"], RX, RY, ind)

    # ---- fx nodes (topmost): Node at root point, shapes absolute
    for fname, prims in (("happy", art.fx["happy"]), ("seed", art.fx["seed"]),
                         ("crumbs", art.fx["crumbs"]),
                         ("sleep", art.fx["sleep"]), ("zzz", art.fx["zzz"]),
                         ("bang", art.fx["bang"]), ("proud", art.fx["proud"])):
        nid = ids.n()
        R["fx"][fname] = nid
        R["rest"][nid] = (0, 0)
        rows += _node_open(f"fx_{fname}", nid, 0, 0, ind + 2, opacity=0, ctx=ctx)
        if prims:
            shapes(prims, f"fx_{fname}", (RX, RY), ind + 4)
        rows.append(f'{" " * (ind + 2)}</Node>')
    # procedural evolve glow ring at the body centre (kept small: max
    # radius 40*1.5=60 < 45% of the 240 artboard; faded out by fx_evolve).
    # The node sits AT the body centre so scale pivots concentrically:
    # a node at the root would shrink the rings toward the feet.
    nid = ids.n()
    R["fx"]["glow"] = nid
    bcx, bcy = A["body"]
    R["rest"][nid] = (bcx - RX, bcy - RY)
    rows += _node_open("fx_glow", nid, bcx - RX, bcy - RY, ind + 2,
                       opacity=0, ctx=ctx)
    ring = _full_style(fill="none", stroke="#FFFFFF", sw=6)
    glow_prims = [
        _mk_prim("ellipse", {"cx": S.num(bcx), "cy": S.num(bcy),
                             "rx": "30", "ry": "30"}, ring),
        _mk_prim("ellipse", {"cx": S.num(bcx), "cy": S.num(bcy),
                             "rx": "40", "ry": "40"},
                 _full_style(fill="none", stroke="#FFF1B8", sw=3.5)),
    ]
    shapes(glow_prims, "fx_glow", (bcx, bcy), ind + 4)
    rows.append(f'{" " * (ind + 2)}</Node>')

    # ---- accessories (bound visibility, default none)
    for aname, prop in (("bow", P["accBow"]), ("cap", P["accCap"]),
                        ("scarf", P["accScarf"]), ("glasses", P["accGlasses"])):
        prims = art.acc.get(aname, [])
        nid = ids.n()
        R["acc"][aname] = nid
        R["rest"][nid] = (0, 0)
        rows += _node_open(f"acc_{aname}", nid, 0, 0, ind + 2, opacity=0,
                           binds=(("18", prop),), ctx=ctx)
        if prims:
            shapes(prims, f"acc_{aname}", (RX, RY), ind + 4)
        rows.append(f'{" " * (ind + 2)}</Node>')

    # ---- highlight, shell pieces, feet (static in root)
    if art.has("highlight"):
        R["highlight"] = shapes(art.groups["highlight"], "highlight",
                                (RX, RY), ind + 2)
    for gid in ("shell_top", "shell_bottom"):
        if art.has(gid) and not (gid == "shell_top" and s == 2):
            shapes(art.groups[gid], gid, (RX, RY), ind + 2)
    if art.has("feet"):
        shapes(art.groups["feet"], "feet", (RX, RY), ind + 2)

    # ---- head (eyes/beak/tuft/cheeks ride together)
    HX, HY = A["head"]
    R["head"] = ids.n()
    R["rest"][R["head"]] = (HX - RX, HY - RY)
    rows += _node_open("head", R["head"], HX - RX, HY - RY, ind + 2)

    def hshapes(prims, name, opacity=None):
        sid = ids.s()
        r, minted = _shape_rows(prims, name, sid, (HX, HY), ind + 4, ctx,
                               props, opacity=opacity)
        rows.extend(r)
        return minted

    R["beakbot"] = hshapes(V["beak_bottom_open"], "beak_bottom", opacity=0)
    R["beakbot_y"] = (A["beak"][1] + 9) - HY  # authored y in head space
    R["beako"] = hshapes(V["beak_top_o"], "beak_top_o", opacity=0)
    if art.has("beak_top"):
        hshapes(art.groups["beak_top"], "beak_top")
    for side in ("r", "l"):
        R["eye_op"].setdefault(side, {})
        order = ["surprised", "happy", "sleepy", "closed"] + \
                (["wink"] if side == "l" else []) + ["open"]
        for var in order:
            if var == "open":
                prims = art.eye[side]["open"]
            else:
                # surprised included: the review spec is the normal eye
                # scaled 1.3x symmetric (same centre, same outline weight),
                # not the raised peak variant, so entry cross-fades can
                # never double-image into a ring.
                prims = V[side][var]
            # RML draws the FIRST sibling on top: emit topmost-first
            # (reverse of SVG paint order) so pupils/highlights sit above
            # their white instead of being covered by it.
            prims = list(reversed(prims))
            op = None if var == "open" else 0
            got = hshapes(prims, f"eye_{side}_{var}", opacity=op)
            R["eye_op"][side][var] = got
            if var == "open":
                R["open"].extend(got)
    if art.has("head_tuft") and A["tuft"]:
        TX, TY = A["tuft"]
        R["tuft"] = ids.n()
        R["rest"][R["tuft"]] = (TX - HX, TY - HY)
        rows += _node_open("head_tuft", R["tuft"], TX - HX, TY - HY, ind + 4)
        sid = ids.s()
        r, _ = _shape_rows(art.groups["head_tuft"], "head_tuft", sid,
                           (TX, TY), ind + 6, ctx, props)
        rows.extend(r)
        rows.append(f'{" " * (ind + 4)}</Node>')
    for ch in ("cheek_r", "cheek_l"):
        if art.has(ch):
            R["cheeks"].extend(hshapes(art.groups[ch], ch))
    if s == 2 and art.has("shell_top"):
        hshapes(art.groups["shell_top"], "shell_top")
    rows.append(f'{" " * (ind + 2)}</Node>')  # head

    # ---- body (breathing node)
    BX, BY = A["body"]
    R["body"] = ids.n()
    R["rest"][R["body"]] = (BX - RX, BY - RY)
    rows += _node_open("body", R["body"], BX - RX, BY - RY, ind + 2)

    def bshapes(prims, name):
        sid = ids.s()
        r, minted = _shape_rows(prims, name, sid, (BX, BY), ind + 4, ctx, props)
        rows.extend(r)
        return minted

    if art.has("belly"):
        bshapes(art.groups["belly"], "belly")
    body_ps = art.groups.get("body", [])
    if len(body_ps) > 1:
        bshapes(body_ps[1:], "body_shade")
        bshapes(body_ps[:1], "body")
    elif body_ps:
        bshapes(body_ps, "body")
    rows.append(f'{" " * (ind + 2)}</Node>')  # body

    # ---- wings / tail
    for w in ("wing_r", "wing_l"):
        if A[w]:
            WX, WY = A[w]
            nid = ids.n()
            R[w] = nid
            R["rest"][nid] = (WX - RX, WY - RY)
            rows += _node_open(w, nid, WX - RX, WY - RY, ind + 2)
            sid = ids.s()
            r, _ = _shape_rows(art.groups[w], w, sid, (WX, WY), ind + 4,
                               ctx, props)
            rows.extend(r)
            rows.append(f'{" " * (ind + 2)}</Node>')
    if A["tail"] and art.has("tail"):
        TX, TY = A["tail"]
        nid = ids.n()
        R["tail"] = nid
        R["rest"][nid] = (TX - RX, TY - RY)
        rows += _node_open("tail", nid, TX - RX, TY - RY, ind + 2)
        sid = ids.s()
        r, _ = _shape_rows(art.groups["tail"], "tail", sid, (TX, TY),
                           ind + 4, ctx, props)
        rows.extend(r)
        rows.append(f'{" " * (ind + 2)}</Node>')

    rows.append(f'{pad}</Node>')  # pip_root

    # ---- ground shadow (stays planted; artboard level = drawn under pip)
    r, minted = _shape_rows(art.groups.get("shadow", []), "shadow", ids.s(),
                            (0, 0), ind, ctx, props)
    rows.extend(r)
    R["shadow_ids"] = minted
    return rows, R





# ------------------------------------------------------------ animations

IO = (0.42, 0.0, 0.58, 1.0)
OO = (0.0, 0.0, 0.58, 1.0)
IN = (0.42, 0.0, 1.0, 1.0)
BACK = (0.34, 1.3, 0.64, 1.0)  # slight overshoot ease


def _keyed(oid, key, frames, ind):
    """frames: (value, frame|None, interp, ease). cubic needs an ease tuple;
    elastic needs (amplitude, period); hold ignores ease."""
    out = [f'{ind}<KeyedObject objectId="{oid}">',
           f'{ind}  <KeyedProperty propertyKey="{key}">']
    for val, fr, interp, ease in frames:
        f = f' frame="{fr}"' if fr is not None else ""
        if interp == "cubic":
            x1, y1, x2, y2 = ease or IO
            out.append(f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                       f'interpolationType="cubic"{f}>')
            out.append(f'{ind}      <CubicEaseInterpolator x1="{x1}" y1="{y1}" '
                       f'x2="{x2}" y2="{y2}"/>')
            out.append(f'{ind}    </KeyFrameDouble>')
        elif interp == "elastic":
            amp, per = ease or (1.0, 0.4)
            out.append(f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                       f'interpolationType="elastic"{f}>')
            out.append(f'{ind}      <ElasticInterpolator easingValue="1" '
                       f'amplitude="{amp}" period="{per}"/>')
            out.append(f'{ind}    </KeyFrameDouble>')
        else:
            out.append(f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                       f'interpolationType="{interp}"{f}/>')
    out.append(f"{ind}  </KeyedProperty>")
    out.append(f"{ind}</KeyedObject>")
    return out


def _H(v, f=None):
    return (v, f, "hold", None)


def _C(v, f, ease=IO):
    return (v, f, "cubic", ease)


DURS = {"idle": 180, "happy": 72, "eat": 108, "sleepy": 240,
        "surprised": 48, "proud": 72, "evolve": 90, "blinkloop": 210,
        "blinkshot": 12, "eyesrest": 4, "fx_idle": 4, "fx_happy": 72,
        "fx_eat": 108, "fx_sleepy": 240, "fx_surprised": 48,
        "fx_proud": 72, "fx_evolve": 90}


def animations(R, A, ctx):
    P = "        "
    aids = {}
    names = ["idle", "happy", "eat", "sleepy", "surprised", "proud",
             "evolve", "blinkloop", "blinkshot", "eyesrest",
             "fx_idle", "fx_happy", "fx_eat", "fx_sleepy",
             "fx_surprised", "fx_proud", "fx_evolve"]
    for i, n in enumerate(names):
        aids[n] = f"{ctx.ns}:{400 + i}"
    loop_of = {"idle": "loop", "sleepy": "loop", "blinkloop": "loop",
               "eyesrest": "loop", "fx_idle": "loop", "fx_sleepy": "loop"}
    out = []

    RX, RY = A["root"]
    HR = R["rest"][R["head"]]
    has_tuft = R.get("tuft") is not None
    WL = R.get("wing_l")
    WR = R.get("wing_r")
    TAL = R.get("tail")

    def eye_keys(active):
        r = []
        for side in ("l", "r"):
            for var, got in R["eye_op"][side].items():
                v = 1 if active.get(side) == var else 0
                for oid in got:
                    r += _keyed(oid, 18, [_H(v, 0)], P + "  ")
        return r

    def beak_keys(bottom=0, top_o=0):
        r = []
        for oid in R.get("beakbot", []):
            r += _keyed(oid, 18, [_H(bottom, 0)], P + "  ")
        for oid in R.get("beako", []):
            r += _keyed(oid, 18, [_H(top_o, 0)], P + "  ")
        return r

    def fx_hold(which_on=None, frames_for=None):
        r = []
        for fname, nid in R["fx"].items():
            if frames_for and fname in frames_for:
                r += _keyed(nid, 18, frames_for[fname], P + "  ")
                continue
            v = 1 if fname == which_on else 0
            r += _keyed(nid, 18, [_H(v, 0)], P + "  ")
        return r

    def begin(name):
        out.append(f'{P}<LinearAnimation name="{name}" duration="{DURS[name]}" '
                   f'fps="60" loopValue="{loop_of.get(name, "oneShot")}" '
                   f'id="{aids[name]}">')

    def end():
        out.append(f"{P}</LinearAnimation>")
        out.append("")

    # ---- idle: breathe + head tilt + tuft sway + wing micro (3 s loop)
    begin("idle")
    out += _keyed(R["body"], 16, [_C(1, None), _C(1.015, 90), _C(1, 180)], P + "  ")
    out += _keyed(R["body"], 17, [_C(1, None), _C(1.04, 90), _C(1, 180)], P + "  ")
    out += _keyed(R["head"], 15, [_C(0, None), _C(0.07, 60), _C(-0.07, 120),
                                  _C(0, 180)], P + "  ")
    if has_tuft:
        out += _keyed(R["tuft"], 15, [_C(0, None), _C(0.12, 75), _C(-0.1, 140),
                                      _C(0, 180)], P + "  ")
    if WL:
        out += _keyed(WL, 15, [_C(0, None), _C(0.07, 90), _C(0, 180)], P + "  ")
        out += _keyed(WR, 15, [_C(0, None), _C(-0.07, 90), _C(0, 180)], P + "  ")
    if TAL:
        out += _keyed(TAL, 15, [_C(0, None), _C(0.1, 90), _C(0, 180)], P + "  ")
    for oid in R["shadow_ids"]:
        out += _keyed(oid, 16, [_C(1, None), _C(0.97, 90), _C(1, 180)], P + "  ")
        out += _keyed(oid, 17, [_C(1, None), _C(0.97, 90), _C(1, 180)], P + "  ")
    out += eye_keys({"l": "open", "r": "open"})
    out += beak_keys()
    end()

    # ---- happy: antic squash -> jump +22px, wings up flap x2, land squash
    begin("happy")
    out += _keyed(R["root"], 14, [_C(RY, None), _C(RY + 2, 9, IN), _C(RY - 22, 24, OO),
                                  _C(RY - 22, 40), _C(RY, 48, BACK), _C(RY, 72)], P + "  ")
    out += _keyed(R["root"], 16, [_C(1, None), _C(1.16, 9, IN), _C(0.94, 24, OO),
                                  _C(0.94, 40), _C(1.12, 48), _C(1, 60), _C(1, 72)], P + "  ")
    out += _keyed(R["root"], 17, [_C(1, None), _C(0.85, 9, IN), _C(1.07, 24, OO),
                                  _C(1.07, 40), _C(0.9, 48), _C(1, 60), _C(1, 72)], P + "  ")
    if WL:
        out += _keyed(WL, 15, [_C(0, None), _C(0, 9), _C(2.5, 20, OO),
                               _C(1.5, 28), _C(2.5, 36), _C(1.5, 44),
                               _C(0, 56), _C(0, 72)], P + "  ")
        out += _keyed(WR, 15, [_C(0, None), _C(0, 9), _C(-2.5, 20, OO),
                               _C(-1.5, 28), _C(-2.5, 36), _C(-1.5, 44),
                               _C(0, 56), _C(0, 72)], P + "  ")
    out += _keyed(R["head"], 15, [_C(0, None), _C(0.1, 9), _C(-0.14, 24),
                                  _C(0.1, 48), _C(0, 60), _C(0, 72)], P + "  ")
    if has_tuft:
        out += _keyed(R["tuft"], 15, [_C(0, None), _C(0, 12), _C(0.32, 28, OO),
                                      _C(-0.2, 44), _C(0.1, 56), _C(0, 72)], P + "  ")
    if TAL:
        out += _keyed(TAL, 15, [_C(0, None), _C(-0.3, 24), _C(0.2, 48),
                                _C(0, 60), _C(0, 72)], P + "  ")
    for oid in R["shadow_ids"]:
        out += _keyed(oid, 16, [_C(1, None), _C(1.12, 9), _C(0.78, 24),
                                        _C(0.78, 40), _C(1.06, 48), _C(1, 60), _C(1, 72)], P + "  ")
        out += _keyed(oid, 17, [_C(1, None), _C(1.12, 9), _C(0.78, 24),
                                        _C(0.78, 40), _C(1.06, 48), _C(1, 60), _C(1, 72)], P + "  ")
    out += eye_keys({"l": "happy", "r": "happy"})
    for oid in R.get("beakbot", []):
        out += _keyed(oid, 18, [_H(0, 0), _H(1, 14), _H(1, 52), _H(0, 56)], P + "  ")
        out += _keyed(oid, 14, [_C(R["beakbot_y"], 0), _C(R["beakbot_y"] + 4, 24),
                                _C(R["beakbot_y"], 48), _C(R["beakbot_y"], 72)], P + "  ")
    end()

    # ---- eat: 3 pecks, beak chews, cheek puff, satisfied ^^
    begin("eat")
    pecks = [(20, 28), (46, 54), (72, 80)]
    hy = [_C(HR[1], 0), _C(HR[1], 12)]
    hr = [_C(0, 0), _C(0, 12)]
    for dip, back in pecks:
        hy += [_C(HR[1] + 16, dip, IN), _C(HR[1] + 2, back, OO)]
        hr += [_C(0.38, dip, IN), _C(0.05, back, OO)]
    hy += [_C(HR[1], 92), _C(HR[1], 108)]
    hr += [_C(0, 92), _C(0, 108)]
    out += _keyed(R["head"], 14, hy, P + "  ")
    out += _keyed(R["head"], 15, hr, P + "  ")
    for oid in R.get("beakbot", []):
        bk = [_H(0, 0)]
        for dip, back in pecks:
            bk += [_H(1, dip - 2), _H(0, back)]
        bk += [_H(0, 92)]
        out += _keyed(oid, 18, bk, P + "  ")
    for oid in R.get("cheeks", []):
        out += _keyed(oid, 16, [_C(1, 0), _C(1, 66), _C(1.32, 84, OO),
                                _C(1.32, 96), _C(1, 108)], P + "  ")
        out += _keyed(oid, 17, [_C(1, 0), _C(1, 66), _C(1.32, 84, OO),
                                _C(1.32, 96), _C(1, 108)], P + "  ")
    if has_tuft:
        out += _keyed(R["tuft"], 15, [_C(0, 0)] + [_C(0.18 if i % 2 == 0 else -0.1, dip, OO)
                                                  for i, (dip, _) in enumerate(pecks)] +
                    [_C(0, 92), _C(0, 108)], P + "  ")
    if WL:
        out += _keyed(WL, 15, [_C(0, 0), _C(0.25, 20), _C(0, 30),
                               _C(0.25, 46), _C(0, 56), _C(0.25, 72),
                               _C(0, 84), _C(0, 108)], P + "  ")
        out += _keyed(WR, 15, [_C(0, 0), _C(-0.25, 20), _C(0, 30),
                               _C(-0.25, 46), _C(0, 56), _C(-0.25, 72),
                               _C(0, 84), _C(0, 108)], P + "  ")
    out += eye_keys({"l": "happy", "r": "happy"})
    out += beak_keys()
    out += _keyed(R["body"], 17, [_C(1, 0), _C(1, 12)] +
                  [_C(1.05, dip, OO) for dip, _ in pecks] +
                  [_C(1, 84), _C(1, 108)], P + "  ")
    end()

    # ---- sleepy: slump + deep 4 s breath + nod + closed eyes (loop)
    begin("sleepy")
    out += _keyed(R["body"], 16, [_C(1.03, None), _C(1.0, 120), _C(1.03, 240)], P + "  ")
    out += _keyed(R["body"], 17, [_C(0.94, None), _C(1.0, 120), _C(0.94, 240)], P + "  ")
    out += _keyed(R["head"], 14, [_C(HR[1] + 6, 0), _C(HR[1] + 9, 120), _C(HR[1] + 6, 240)],
                   P + "  ")
    out += _keyed(R["head"], 15, [_C(0.3, None), _C(0.38, 60), _C(0.3, 120),
                                  _C(0.22, 180), _C(0.3, 240)], P + "  ")
    if has_tuft:
        out += _keyed(R["tuft"], 15, [_C(0.1, None), _C(-0.06, 120), _C(0.1, 240)], P + "  ")
    if WL:
        out += _keyed(WL, 15, [_C(-0.18, 0), _C(-0.18, 240)], P + "  ")
        out += _keyed(WR, 15, [_C(0.18, 0), _C(0.18, 240)], P + "  ")
    if TAL:
        out += _keyed(TAL, 15, [_C(-0.12, 0), _C(-0.12, 240)], P + "  ")
    out += eye_keys({"l": "closed", "r": "closed"})
    out += beak_keys()
    end()

    # ---- surprised: jump-back 10px, wide eyes, o-beak, flare, tuft spring
    begin("surprised")
    out += _keyed(R["root"], 13, [_C(RX, None), _C(RX + 2, 6, IN), _C(RX - 10, 14, OO),
                                  _C(RX - 10, 26), _C(RX - 2, 36), _C(RX, 48)], P + "  ")
    out += _keyed(R["root"], 14, [_C(RY, None), _C(RY + 1, 6), _C(RY - 8, 14, OO),
                                  _C(RY - 8, 26), _C(RY, 36, BACK), _C(RY, 48)], P + "  ")
    out += _keyed(R["root"], 16, [_C(1, None), _C(1.08, 6), _C(0.93, 14),
                                  _C(0.93, 26), _C(1.08, 36), _C(1, 44), _C(1, 48)], P + "  ")
    out += _keyed(R["root"], 17, [_C(1, None), _C(0.94, 6), _C(1.08, 14),
                                  _C(1.08, 26), _C(0.94, 36), _C(1, 44), _C(1, 48)], P + "  ")
    if WL:
        out += _keyed(WL, 15, [_C(0, None), _C(0.4, 6), _C(1.15, 14, OO),
                               _C(1.15, 26), _C(0, 38), _C(0, 48)], P + "  ")
        out += _keyed(WR, 15, [_C(0, None), _C(-0.4, 6), _C(-1.15, 14, OO),
                               _C(-1.15, 26), _C(0, 38), _C(0, 48)], P + "  ")
    out += _keyed(R["head"], 15, [_C(0, None), _C(-0.1, 14), _C(-0.1, 26),
                                  _C(0, 38), _C(0, 48)], P + "  ")
    if has_tuft:
        out += _keyed(R["tuft"], 15, [_C(0, None), _C(0.55, 14, BACK),
                                      _C(0.55, 22), _C(0, 36, IO), _C(0, 48)], P + "  ")
    if TAL:
        out += _keyed(TAL, 15, [_C(0, None), _C(0.35, 14), _C(0, 36), _C(0, 48)],
                      P + "  ")
    out += eye_keys({"l": "surprised", "r": "surprised"})
    out += beak_keys(top_o=1)
    end()

    # ---- proud: chest out, chin up, wings to hip, wink, chest sparkle
    begin("proud")
    out += _keyed(R["root"], 14, [_C(RY, None), _C(RY - 5, 14, OO), _C(RY - 5, 54),
                                  _C(RY, 66), _C(RY, 72)], P + "  ")
    out += _keyed(R["body"], 16, [_C(1, None), _C(1.08, 14, OO), _C(1.08, 54),
                                  _C(1, 66), _C(1, 72)], P + "  ")
    out += _keyed(R["body"], 17, [_C(1, None), _C(0.97, 14, OO), _C(0.97, 54),
                                  _C(1, 66), _C(1, 72)], P + "  ")
    out += _keyed(R["head"], 15, [_C(0, None), _C(-0.2, 14, OO), _C(-0.2, 54),
                                  _C(0, 66), _C(0, 72)], P + "  ")
    if WL:
        out += _keyed(WL, 15, [_C(0, None), _C(-0.5, 14, OO),
                               _C(-0.5, 54), _C(0, 66), _C(0, 72)], P + "  ")
        out += _keyed(WR, 15, [_C(0, None), _C(0.5, 14, OO),
                               _C(0.5, 54), _C(0, 66), _C(0, 72)], P + "  ")
    if has_tuft:
        out += _keyed(R["tuft"], 15, [_C(0, None), _C(0.16, 14), _C(0.16, 54),
                                      _C(0, 66), _C(0, 72)], P + "  ")
    out += eye_keys({"l": "wink", "r": "open"})
    out += beak_keys()
    end()

    # ---- evolve: glow ring + squash-pop
    begin("evolve")
    out += _keyed(R["root"], 14, [_C(RY, None), _C(RY + 2, 14, IN), _C(RY - 14, 38, OO),
                                  _C(RY, 60, BACK), _C(RY, 90)], P + "  ")
    out += _keyed(R["root"], 16, [_C(1, None), _C(1.15, 14, IN), _C(0.9, 38, OO),
                                  _C(1.02, 60), _C(1, 74), _C(1, 90)], P + "  ")
    out += _keyed(R["root"], 17, [_C(1, None), _C(0.82, 14, IN), _C(1.14, 38, OO),
                                  _C(0.98, 60), _C(1, 74), _C(1, 90)], P + "  ")
    if has_tuft:
        out += _keyed(R["tuft"], 15, [_C(0, None), _C(0.6, 38, OO), _C(0, 60),
                                      _C(0, 90)], P + "  ")
    if WL:
        out += _keyed(WL, 15, [_C(0, None), _C(0.9, 38, OO),
                               _C(0, 60), _C(0, 90)], P + "  ")
        out += _keyed(WR, 15, [_C(0, None), _C(-0.9, 38, OO),
                               _C(0, 60), _C(0, 90)], P + "  ")
    for oid in R.get("highlight", []):
        out += _keyed(oid, 18, [_C(1, 0), _C(1, 30), _C(1, 52), _C(1, 90)], P + "  ")
    out += eye_keys({"l": "happy", "r": "happy"})
    out += beak_keys()
    end()

    # ---- blink loop (Eyes layer, independent of Body)
    begin("blinkloop")
    for oid in R["open"]:
        out += _keyed(oid, 17, [_C(1, 0), _C(1, 178), _C(0.07, 182, IN),
                                _H(0.07, 186), _C(1, 192, OO), _C(1, 210)], P + "  ")
    end()
    begin("blinkshot")
    for oid in R["open"]:
        out += _keyed(oid, 17, [_C(1, 0), _C(0.07, 4, IN), _H(0.07, 6),
                                _C(1, 10, OO), _C(1, 12)], P + "  ")
    end()
    begin("eyesrest")
    for oid in R["open"]:
        out += _keyed(oid, 17, [_H(1, 0)], P + "  ")
    end()

    # ---- FX timelines (mirror durations; own every fx node explicitly)
    begin("fx_idle")
    out += fx_hold()
    end()
    begin("fx_happy")
    out += fx_hold("happy")
    nid = R["fx"]["happy"]
    out += _keyed(nid, 16, [_C(0.6, 0), _C(1.15, 26, OO), _C(1.15, 50), _C(1, 62),
                            _C(1, 72)], P + "  ")
    out += _keyed(nid, 17, [_C(0.6, 0), _C(1.15, 26, OO), _C(1.15, 50), _C(1, 62),
                            _C(1, 72)], P + "  ")
    end()
    begin("fx_eat")
    out += fx_hold()
    seed, crumbs = R["fx"]["seed"], R["fx"]["crumbs"]
    out += _keyed(seed, 18, [_H(0, 0), _H(1, 4), _H(1, 88), _H(0, 96)], P + "  ")
    out += _keyed(seed, 14, [_C(-46, 0), _C(0, 16, IN), _C(0, 88), _C(-46, 108)], P + "  ")
    first = True
    for dip, back in [(20, 28), (46, 54), (72, 80)]:
        if first:
            out += _keyed(crumbs, 18, [_H(0, 0), _H(1, dip), _H(1, dip + 8),
                                       _H(0, dip + 14)], P + "  ")
            first = False
        else:
            out += _keyed(crumbs, 18, [_H(0, dip - 4), _H(1, dip), _H(1, dip + 8),
                                       _H(0, dip + 14)], P + "  ")
    end()
    begin("fx_sleepy")
    out += fx_hold("sleep")
    zzz = R["fx"]["zzz"]
    sleep = R["fx"]["sleep"]
    out += _keyed(sleep, 18, [_H(1, 0)], P + "  ")
    out += _keyed(zzz, 18, [_C(0, 0), _C(1, 20, OO), _C(1, 90), _C(0, 120),
                            _C(0, 130), _C(1, 150, OO), _C(1, 210), _C(0, 240)], P + "  ")
    out += _keyed(zzz, 14, [_C(0, 0), _C(-17, 60), _C(-34, 120), _C(0, 130),
                            _C(-17, 180), _C(-34, 240)], P + "  ")
    end()
    begin("fx_surprised")
    out += fx_hold("bang")
    bang = R["fx"]["bang"]
    out += _keyed(bang, 16, [_C(0.3, 0), _C(0.3, 8), _C(1.2, 16, BACK),
                             _C(1.2, 30), _C(1, 40), _C(1, 48)], P + "  ")
    out += _keyed(bang, 17, [_C(0.3, 0), _C(0.3, 8), _C(1.2, 16, BACK),
                             _C(1.2, 30), _C(1, 40), _C(1, 48)], P + "  ")
    end()
    begin("fx_proud")
    out += fx_hold("proud")
    proud = R["fx"]["proud"]
    out += _keyed(proud, 16, [_C(0.7, 0), _C(0.7, 22), _C(1.2, 34, OO),
                              _C(0.9, 46), _C(1.1, 54), _C(1, 62), _C(1, 72)], P + "  ")
    out += _keyed(proud, 17, [_C(0.7, 0), _C(0.7, 22), _C(1.2, 34, OO),
                              _C(0.9, 46), _C(1.1, 54), _C(1, 62), _C(1, 72)], P + "  ")
    end()
    begin("fx_evolve")
    out += fx_hold(frames_for={"glow": [_H(1, 0), _C(1, 52), _C(0, 90)]})
    glow = R["fx"]["glow"]
    out += _keyed(glow, 16, [_C(0.3, 0), _C(0.3, 8), _C(1.1, 44, OO), _C(1.1, 60),
                             _C(1.5, 90)], P + "  ")
    out += _keyed(glow, 17, [_C(0.3, 0), _C(0.3, 8), _C(1.1, 44, OO), _C(1.1, 60),
                             _C(1.5, 90)], P + "  ")
    end()
    return out, aids
# ------------------------------------------------------------ state machine

def _enum_cond(dest, vm, prop, op, value_id, duration, ind):
    return [
        f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}">',
        f'{ind}    <TransitionViewModelCondition opValue="{op}">',
        f'{ind}      <TransitionPropertyViewModelComparator>',
        f'{ind}        <BindablePropertyEnum>',
        f'{ind}          <DataBindContext sourcePathIds="{vm}-{prop}" '
        f'propertyKey="637"/>',
        f'{ind}        </BindablePropertyEnum>',
        f'{ind}      </TransitionPropertyViewModelComparator>',
        f'{ind}      <TransitionValueEnumComparator value="{value_id}"/>',
        f'{ind}    </TransitionViewModelCondition>',
        f'{ind}  </StateTransition>',
    ]


def _trigger_cond(dest, vm, prop, duration, ind):
    return [
        f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}">',
        f'{ind}    <TransitionViewModelCondition opValue="equal">',
        f'{ind}      <TransitionPropertyViewModelComparator>',
        f'{ind}        <BindablePropertyTrigger>',
        f'{ind}          <DataBindContext sourcePathIds="{vm}-{prop}" '
        f'propertyKey="686"/>',
        f'{ind}        </BindablePropertyTrigger>',
        f'{ind}      </TransitionPropertyViewModelComparator>',
        f'{ind}      <TransitionValueTriggerComparator value="1"/>',
        f'{ind}    </TransitionViewModelCondition>',
        f'{ind}  </StateTransition>',
    ]


def _exit(dest, duration, ind, cond=None):
    if cond:
        return cond
    return [f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}" '
            f'enableExitTime="true" exitTimeIsPercetange="true" exitTime="100"/>']


def state_machine(ctx, aids, enum_ids, P_MOOD, P_EVOLVE, P_TAP, P_BLINK):
    P = "        "
    E = enum_ids  # mood value key -> enum value id
    S = lambda n: f"{ctx.ns}:{300 + n}"  # noqa: E731
    L_BODY, L_EYES, L_FX = S(1), S(2), S(3)
    (ST_IDLE, ST_HAPPY, ST_EAT, ST_SLEEPY, ST_SURP, ST_PROUD, ST_EVO) = \
        [S(10 + i) for i in range(7)]
    (EY_LOOP, EY_SHOT, EY_REST) = S(20), S(21), S(22)
    (FX_IDLE, FX_HAPPY, FX_EAT, FX_SLEEPY, FX_SURP, FX_PROUD, FX_EVO) = \
        [S(30 + i) for i in range(7)]
    r = [f'{P}<StateMachine name="Pip" id="{ctx.SM}">']

    # ---- Body: idle loop + one-shot moods home at 100% (sleepy loops home)
    r += [f'{P}  <StateMachineLayer name="Body" id="{L_BODY}">',
          f'{P}    <AnyState x="560" y="-120"/>',
          f'{P}    <ExitState x="760" y="-120"/>',
          f'{P}    <EntryState x="40" y="-120">',
          f'{P}      <StateTransition stateToId="{ST_IDLE}" duration="0"/>',
          f'{P}    </EntryState>',
          f'{P}    <AnimationState x="160" y="-120" animationId="{aids["idle"]}" '
          f'id="{ST_IDLE}">']
    for mood, st in (("happy", ST_HAPPY), ("eating", ST_EAT),
                     ("sleepy", ST_SLEEPY), ("surprised", ST_SURP),
                     ("proud", ST_PROUD)):
        # surprised snaps in fast (50 ms): a slow cross-fade double-images
        # the offset eye variants into a grey ring mid-blend.
        dur = 50 if mood == "surprised" else 120
        r += _enum_cond(st, ctx.VM, P_MOOD, "equal", E[mood], dur, P + "  ")
    r += _trigger_cond(ST_EVO, ctx.VM, P_EVOLVE, 100, P + "  ")
    r += _trigger_cond(ST_HAPPY, ctx.VM, P_TAP, 120, P + "  ")
    r.append(f'{P}    </AnimationState>')
    for st, an, blend, sx, sy in (
            (ST_HAPPY, aids["happy"], 220, 360, -40),
            (ST_EAT, aids["eat"], 220, 560, -40),
            (ST_SURP, aids["surprised"], 150, 360, 60),
            (ST_PROUD, aids["proud"], 220, 560, 60),
            (ST_EVO, aids["evolve"], 300, 760, -40)):
        r += [f'{P}    <AnimationState x="{sx}" y="{sy}" animationId="{an}" '
              f'id="{st}">']
        r += _exit(ST_IDLE, blend, P + "    ")
        r.append(f'{P}    </AnimationState>')
    # sleepy loops until mood returns to idle
    r += [f'{P}    <AnimationState x="760" y="60" animationId="{aids["sleepy"]}" '
          f'id="{ST_SLEEPY}">']
    r += [f'{P}      <StateTransition stateToId="{ST_IDLE}" duration="300" '
          f'enableExitTime="true" exitTimeIsPercetange="true" exitTime="100">',
          f'{P}        <TransitionViewModelCondition opValue="equal">',
          f'{P}          <TransitionPropertyViewModelComparator>',
          f'{P}            <BindablePropertyEnum>',
          f'{P}              <DataBindContext sourcePathIds="{ctx.VM}-{P_MOOD}" '
          f'propertyKey="637"/>',
          f'{P}            </BindablePropertyEnum>',
          f'{P}          </TransitionPropertyViewModelComparator>',
          f'{P}          <TransitionValueEnumComparator value="{E["idle"]}"/>',
          f'{P}        </TransitionViewModelCondition>',
          f'{P}      </StateTransition>',
          f'{P}    </AnimationState>']
    r += [f"{P}  </StateMachineLayer>"]

    # ---- Eyes: independent blink loop; blink trigger; rests while sleepy
    r += [f'{P}  <StateMachineLayer name="Eyes" id="{L_EYES}">',
          f'{P}    <AnyState x="560" y="-240"/>',
          f'{P}    <ExitState x="760" y="-240"/>',
          f'{P}    <EntryState x="40" y="-240">',
          f'{P}      <StateTransition stateToId="{EY_LOOP}" duration="0"/>',
          f'{P}    </EntryState>',
          f'{P}    <AnimationState x="160" y="-240" animationId="{aids["blinkloop"]}" '
          f'id="{EY_LOOP}">']
    r += _trigger_cond(EY_SHOT, ctx.VM, P_BLINK, 60, P + "  ")
    r += _enum_cond(EY_REST, ctx.VM, P_MOOD, "equal", E["sleepy"], 200, P + "  ")
    r.append(f'{P}    </AnimationState>')
    r += [f'{P}    <AnimationState x="360" y="-160" animationId="{aids["blinkshot"]}" '
          f'id="{EY_SHOT}">']
    r += _exit(EY_LOOP, 60, P + "    ")
    r.append(f'{P}    </AnimationState>')
    r += [f'{P}    <AnimationState x="360" y="-320" animationId="{aids["eyesrest"]}" '
          f'id="{EY_REST}">']
    r += _enum_cond(EY_LOOP, ctx.VM, P_MOOD, "notEqual", E["sleepy"], 200, P + "  ")
    r.append(f'{P}    </AnimationState>')
    r += [f"{P}  </StateMachineLayer>"]

    # ---- FX: one state per mood, mirroring Body
    r += [f'{P}  <StateMachineLayer name="FX" id="{L_FX}">',
          f'{P}    <AnyState x="560" y="-360"/>',
          f'{P}    <ExitState x="760" y="-360"/>',
          f'{P}    <EntryState x="40" y="-360">',
          f'{P}      <StateTransition stateToId="{FX_IDLE}" duration="0"/>',
          f'{P}    </EntryState>',
          f'{P}    <AnimationState x="160" y="-360" animationId="{aids["fx_idle"]}" '
          f'id="{FX_IDLE}">']
    for mood, st in (("happy", FX_HAPPY), ("eating", FX_EAT),
                     ("sleepy", FX_SLEEPY), ("surprised", FX_SURP),
                     ("proud", FX_PROUD)):
        dur = 50 if mood == "surprised" else 120
        r += _enum_cond(st, ctx.VM, P_MOOD, "equal", E[mood], dur, P + "  ")
    r += _trigger_cond(FX_EVO, ctx.VM, P_EVOLVE, 100, P + "  ")
    r += _trigger_cond(FX_HAPPY, ctx.VM, P_TAP, 120, P + "  ")
    r.append(f'{P}    </AnimationState>')
    for st, an, blend, sx, sy in (
            (FX_HAPPY, aids["fx_happy"], 220, 360, -280),
            (FX_EAT, aids["fx_eat"], 220, 560, -280),
            (FX_SURP, aids["fx_surprised"], 150, 360, -440),
            (FX_PROUD, aids["fx_proud"], 220, 560, -440),
            (FX_EVO, aids["fx_evolve"], 300, 760, -280)):
        r += [f'{P}    <AnimationState x="{sx}" y="{sy}" animationId="{an}" '
              f'id="{st}">']
        r += _exit(FX_IDLE, blend, P + "    ")
        r.append(f'{P}    </AnimationState>')
    r += [f'{P}    <AnimationState x="760" y="-440" animationId="{aids["fx_sleepy"]}" '
          f'id="{FX_SLEEPY}">']
    r += [f'{P}      <StateTransition stateToId="{FX_IDLE}" duration="300" '
          f'enableExitTime="true" exitTimeIsPercetange="true" exitTime="100">',
          f'{P}        <TransitionViewModelCondition opValue="equal">',
          f'{P}          <TransitionPropertyViewModelComparator>',
          f'{P}            <BindablePropertyEnum>',
          f'{P}              <DataBindContext sourcePathIds="{ctx.VM}-{P_MOOD}" '
          f'propertyKey="637"/>',
          f'{P}            </BindablePropertyEnum>',
          f'{P}          </TransitionPropertyViewModelComparator>',
          f'{P}          <TransitionValueEnumComparator value="{E["idle"]}"/>',
          f'{P}        </TransitionViewModelCondition>',
          f'{P}      </StateTransition>',
          f'{P}    </AnimationState>']
    r += [f"{P}  </StateMachineLayer>", f"{P}</StateMachine>"]
    return r
# ------------------------------------------------------------ view model

def view_model(ctx, stage, P, E_IDS):
    """P: prop ids dict; E_IDS: (mood_enum, mood_vals, skin_enum, skin_vals,
    acc_enum, acc_vals)."""
    (EN_MOOD, MOOD_VALS, EN_SKIN, SKIN_VALS, EN_ACC, ACC_VALS) = E_IDS
    L = []
    L.append(f'<ViewModel name="Pip" defaultInstanceId="{ctx.VMI}" id="{ctx.VM}">')
    L.append(f'    <ViewModelPropertyEnumCustom enumId="{EN_MOOD}" name="mood" id="{P["mood"]}"/>')
    L.append(f'    <ViewModelPropertyNumber name="stage" id="{P["stage"]}"/>')
    L.append(f'    <ViewModelPropertyEnumCustom enumId="{EN_SKIN}" name="skin" id="{P["skin"]}"/>')
    L.append(f'    <ViewModelPropertyEnumCustom enumId="{EN_ACC}" name="accessory" id="{P["accessory"]}"/>')
    L.append(f'    <ViewModelPropertyColor name="bodyColor" id="{P["bodyColor"]}"/>')
    L.append(f'    <ViewModelPropertyColor name="bellyColor" id="{P["bellyColor"]}"/>')
    L.append(f'    <ViewModelPropertyColor name="wingColor" id="{P["wingColor"]}"/>')
    L.append(f'    <ViewModelPropertyColor name="shadeColor" id="{P["shadeColor"]}"/>')
    L.append(f'    <ViewModelPropertyNumber name="accBow" id="{P["accBow"]}"/>')
    L.append(f'    <ViewModelPropertyNumber name="accCap" id="{P["accCap"]}"/>')
    L.append(f'    <ViewModelPropertyNumber name="accScarf" id="{P["accScarf"]}"/>')
    L.append(f'    <ViewModelPropertyNumber name="accGlasses" id="{P["accGlasses"]}"/>')
    L.append(f'    <ViewModelPropertyTrigger name="evolve" id="{P["evolve"]}"/>')
    L.append(f'    <ViewModelPropertyTrigger name="tap" id="{P["tap"]}"/>')
    L.append(f'    <ViewModelPropertyTrigger name="blink" id="{P["blink"]}"/>')
    L.append(f'    <ViewModelInstance exports="true" name="Default" id="{ctx.VMI}">')
    L.append(f'        <ViewModelInstanceEnum propertyValue="{MOOD_VALS["idle"]}" '
             f'viewModelPropertyId="{P["mood"]}"/>')
    L.append(f'        <ViewModelInstanceNumber propertyValue="{stage}" '
             f'viewModelPropertyId="{P["stage"]}"/>')
    L.append(f'        <ViewModelInstanceEnum propertyValue="{SKIN_VALS["sunny"]}" '
             f'viewModelPropertyId="{P["skin"]}"/>')
    L.append(f'        <ViewModelInstanceEnum propertyValue="{ACC_VALS["none"]}" '
             f'viewModelPropertyId="{P["accessory"]}"/>')
    for cn in ("bodyColor", "bellyColor", "wingColor", "shadeColor"):
        L.append(f'        <ViewModelInstanceColor propertyValue="FF{COLOR_DEFAULTS[cn][1:]}" '
                 f'viewModelPropertyId="{P[cn]}"/>')
    for an in ("accBow", "accCap", "accScarf", "accGlasses"):
        L.append(f'        <ViewModelInstanceNumber propertyValue="0" '
                 f'viewModelPropertyId="{P[an]}"/>')
    L.append(f'        <ViewModelInstanceTrigger viewModelPropertyId="{P["evolve"]}"/>')
    L.append(f'        <ViewModelInstanceTrigger viewModelPropertyId="{P["tap"]}"/>')
    L.append(f'        <ViewModelInstanceTrigger viewModelPropertyId="{P["blink"]}"/>')
    L.append(f'    </ViewModelInstance>')
    L.append(f'</ViewModel>')
    return L


def enums_block(ctx):
    """Custom enums + ids. Returns (lines, E_IDS, enum value map)."""
    ns = ctx.ns
    L = []
    EN_MOOD, EN_SKIN, EN_ACC = f"{ns}:550", f"{ns}:551", f"{ns}:552"
    MOOD_VALS, SKIN_VALS, ACC_VALS = {}, {}, {}
    L.append(f'<DataEnumCustom name="Mood" id="{EN_MOOD}">')
    for i, m in enumerate(["idle", "happy", "eating", "sleepy", "surprised", "proud"]):
        vid = f"{ns}:{560 + i}"
        MOOD_VALS[m] = vid
        L.append(f'    <DataEnumValue key="{m}" value="{m.title()}" id="{vid}"/>')
    L.append('</DataEnumCustom>')
    L.append(f'<DataEnumCustom name="Skin" id="{EN_SKIN}">')
    for i, m in enumerate(SKIN_NAMES):
        vid = f"{ns}:{570 + i}"
        SKIN_VALS[m] = vid
        L.append(f'    <DataEnumValue key="{m}" value="{m.title()}" id="{vid}"/>')
    L.append('</DataEnumCustom>')
    L.append(f'<DataEnumCustom name="Accessory" id="{EN_ACC}">')
    for i, m in enumerate(["none"] + ACC_NAMES):
        vid = f"{ns}:{580 + i}"
        ACC_VALS[m] = vid
        L.append(f'    <DataEnumValue key="{m}" value="{m.title()}" id="{vid}"/>')
    L.append('</DataEnumCustom>')
    P = {n: f"{ns}:{502 + i}" for i, n in enumerate(
        ["mood", "stage", "skin", "accessory", "bodyColor", "bellyColor",
         "wingColor", "shadeColor", "accBow", "accCap", "accScarf",
         "accGlasses", "evolve", "tap", "blink"])}
    E_IDS = (EN_MOOD, MOOD_VALS, EN_SKIN, SKIN_VALS, EN_ACC, ACC_VALS)
    return L, P, E_IDS


# ------------------------------------------------------------ artboards

ART = {1: "Stage1", 2: "Stage2", 3: "Stage3", 4: "Stage4"}


def build_stage(stage):
    ns = 10 + stage
    ctx = Ctx(ns)
    art = StageArt(stage)
    A = art.anchors()
    V = synth_variants(art, A)
    enum_lines, P, E_IDS = enums_block(ctx)
    props = {k: P[k] for k in ("bodyColor", "bellyColor", "wingColor", "shadeColor")}
    rig_lines, R = emit_rig(art, A, V, ctx, props, 8, P)
    anim_lines, aids = animations(R, A, ctx)
    sm_lines = state_machine(ctx, aids, E_IDS[1], P["mood"], P["evolve"],
                             P["tap"], P["blink"])
    out = ['<Rive version="1" kind="fragment">']
    out.append(f'    <Artboard name="{ART[stage]}" x="{340 * stage}" y="0" width="240" '
               f'height="240" defaultStateMachineId="{ctx.SM}" viewModelId="{ctx.VM}" '
               f'viewModelInstanceId="{ctx.VMI}" styleId="{ns}:999" id="{ns}:998">')
    out.append(f'        <LayoutComponentStyle name="Artboard Style" id="{ns}:999"/>')
    out.append("")
    out += rig_lines
    out.append("")
    out += sm_lines
    out.append("")
    out += anim_lines
    out.append("    </Artboard>")
    out.append("")
    out += enum_lines
    out.append("")
    out += view_model(ctx, stage, P, E_IDS)
    out.append("</Rive>")
    return "\n".join(out), R, A


# ------------------------------------------------------------ PipStage

def _nest_prims():
    prims, _ = S.collect(os.path.join(ROOT, "app", "assets", "illustrations", "nest.svg"))
    out = []
    for p in prims:
        el = p["el"]
        tag = el.tag.split("}")[-1]
        out.append({"tag": tag, "el": el, "style": dict(p["style"]),
                    "opacity": p["opacity"],
                    "matrix": (G.NEST_S, 0, 0, G.NEST_S, G.NEST_DX, G.NEST_DY),
                    "chain": []})
    return out


def build_pipstage():
    ns = 15
    ctx = Ctx(ns)
    enum_lines, P, E_IDS = enums_block(ctx)
    props = {k: P[k] for k in ("bodyColor", "bellyColor", "wingColor", "shadeColor")}
    SW, SH = G.STAGE_W, G.STAGE_H
    out = ['<Rive version="1" kind="fragment">']
    out.append(f'    <Artboard name="PipStage" x="1700" y="0" width="{SW}" height="{SH}" '
               f'defaultStateMachineId="{ctx.SM}" viewModelId="{ctx.VM}" '
               f'viewModelInstanceId="{ctx.VMI}" styleId="{ns}:999" id="{ns}:998">')
    out.append(f'        <LayoutComponentStyle name="Artboard Style" id="{ns}:999"/>')
    out.append("")
    nest = _nest_prims()
    # front rim (below split) first = on top; rigs; back; shadow
    for i, prim in reversed(list(enumerate(nest[1:]))):
        r, _ = _shape_rows([prim], f"nest_{i}", ctx.ids.s(), (0, 0), 8, ctx, {})
        # clip to front half
        out.extend(r[:-1])
        out.append(f'          <ClippingShape sourceId="{ns}:{650}" name="Clip"/>')
        out.append(r[-1])
    # fledgling rig (stage 3), placed by visible-art bbox like gen_pip
    art = StageArt(3)
    A = art.anchors()
    V = synth_variants(art, A)
    x0, y0, x1, y1 = _bbox_of_prims(
        [p for p in art.prims if "shadow" not in p["chain"]])
    sc = G.PIP_VISIBLE_H / (y1 - y0)
    pdx = SW / 2 - (x0 + x1) / 2 * sc
    pdy = G.FEET_Y - y1 * sc
    out.append(f'        <Node x="{S.num(pdx)}" y="{S.num(pdy)}" '
               f'scaleX="{S.num(sc)}" scaleY="{S.num(sc)}" name="pip_stage_3" '
               f'id="{ns}:2000">')
    rig_ids = Ids(31)
    ctx.ids = rig_ids  # rig shapes/nodes live in namespace 31
    rig_lines, R = emit_rig(art, A, V, ctx, props, 12, P)
    ctx.ids = Ids(ns)  # placeholder, replaced below
    out.extend(rig_lines)
    out.append("        </Node>")
    # keep a dedicated counter for the rest of ns 15
    rest_ids = Ids(ns)
    rest_ids.shape = 600
    rest_ids.node = 700
    ctx.ids = rest_ids
    for i, prim in reversed(list(enumerate(nest[1:]))):
        r, _ = _shape_rows([prim], f"nest_back_{i}", ctx.ids.s(), (0, 0), 8, ctx, {})
        out.extend(r[:-1])
        out.append(f'          <ClippingShape sourceId="{ns}:{651}" name="Clip"/>')
        out.append(r[-1])
    r, _ = _shape_rows([nest[0]], "nest_shadow", ctx.ids.s(), (0, 0), 8, ctx, {})
    out.extend(r)
    # masks (invisible geometry, no paints)
    out.append(f'        <Shape x="{S.num(SW / 2)}" y="{S.num(G.SPLIT_Y / 2)}" '
               f'name="back_mask" id="{ns}:651">')
    out.append(f'            <Rectangle width="{SW}" height="{S.num(G.SPLIT_Y)}" '
               f'cornerRadiusTL="0" linkCornerRadius="true" name="P"/>')
    out.append("        </Shape>")
    out.append(f'        <Shape x="{S.num(SW / 2)}" '
               f'y="{S.num((G.SPLIT_Y + SH) / 2)}" name="front_mask" id="{ns}:{650}">')
    out.append(f'            <Rectangle width="{SW}" height="{S.num(SH - G.SPLIT_Y)}" '
               f'cornerRadiusTL="0" linkCornerRadius="true" name="P"/>')
    out.append("        </Shape>")
    out.append("")
    # fix up: rig R ids are in ns 31; animations key them; machine/anims in ns 15
    anim_lines, aids = animations(R, A, ctx)
    # NOTE: animations() minted aids in ctx.ns (15) but KeyedObjects point at
    # rig ids (31:*) — intended: timelines live with the machine, keys reach
    # into the rig namespace. R node/shape ids were minted from rig_ids.
    sm_lines = state_machine(ctx, aids, E_IDS[1], P["mood"], P["evolve"],
                             P["tap"], P["blink"])
    out += sm_lines
    out.append("")
    out += anim_lines
    out.append("    </Artboard>")
    out.append("")
    out += enum_lines
    out.append("")
    out += view_model(ctx, 3, P, E_IDS)
    out.append("</Rive>")
    return "\n".join(out)


# ------------------------------------------------------------ main

def main():
    load_skin_bases()
    print("skin bases:", SKIN_BASES)
    adir = os.path.join(OUT, "artboards")
    os.makedirs(adir, exist_ok=True)
    for old in os.listdir(adir):
        if old.endswith(".rml"):
            os.remove(os.path.join(adir, old))
    for s in STAGES:
        xml, R, A = build_stage(s)
        path = os.path.join(adir, f"stage{s}.rml")
        with open(path, "w") as fh:
            fh.write(xml + "\n")
        n_shapes = len(R["open"]) + sum(len(v) for d in R["eye_op"].values() for v in d.values())
        print(f"  stage{s} {len(xml):>7} bytes  eyes={n_shapes} fx={len(R['fx'])} "
              f"acc={len(R['acc'])} -> {path}")
    if not os.environ.get("SB_STAGE"):
        xml = build_pipstage()
        path = os.path.join(adir, "pipstage.rml")
        with open(path, "w") as fh:
            fh.write(xml + "\n")
        print(f"  pipstage {len(xml):>7} bytes -> {path}")
    with open(os.path.join(OUT, "rive.yaml"), "w") as fh:
        fh.write("name: storybook\nmain: Stage3\n"
                 "build:\n  directory: build\nlogs:\n  file: build/rive.log\n"
                 "  problems: build/problems.log\n")


if __name__ == "__main__":
    main()
