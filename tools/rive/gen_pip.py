#!/usr/bin/env python3
"""
gen_pip.py - generate the Rive CLI project under tools/rive/pip/ from the
brand SVGs in app/assets/illustrations/.

The SVGs are the single source of truth for the art. This script converts
them to RML and wraps every stage in the SAME rig contract, so
app/lib/core/design_system/motion/pip_rive.dart never branches on stage:

  artboard   <stage artboard name>
  machine    "Pip"
  viewmodel  "Pip"   ->  mood, stage, evolve, tap

Id scheme (readable in diffs, and Rive only requires "n:m" uniqueness):
  0:*  shapes, in emission order
  1:*  state machine, layer, states, animations
  2:*  view model, instance, properties
"""

from __future__ import annotations

import math
import os

import svg2rml as S

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SVG_DIR = os.path.join(ROOT, "app", "assets", "illustrations")
OUT = os.path.join(HERE, "pip")

# Ids must be unique across the WHOLE document, not per artboard, so every
# artboard owns a namespace. Within a namespace:
#   :1..:199   shapes          :300..:399  state machine, states
#   :201..:299 group nodes     :400..:499  animations
#   :500..:599 view model
B = 0


def sid(n):
    return f"{B}:{n}"


def use_namespace(b):
    global B, SM, LAYER, ST_IDLE, ST_HAPPY, ST_EAT, ST_EVOLVE
    global A_IDLE, A_HAPPY, A_EAT, A_EVOLVE
    global VM, VMI, P_MOOD, P_STAGE, P_EVOLVE, P_TAP
    B = b
    SM, LAYER = sid(300), sid(301)
    ST_IDLE, ST_HAPPY, ST_EAT, ST_EVOLVE = (sid(302), sid(303), sid(304), sid(305))
    A_IDLE, A_HAPPY, A_EAT, A_EVOLVE = (sid(400), sid(401), sid(402), sid(403))
    VM, VMI = sid(500), sid(501)
    P_MOOD, P_STAGE, P_EVOLVE, P_TAP = (sid(502), sid(503), sid(504), sid(505))

STAGES = [
    # `pivot` is the body centre (breathing). `root` is the feet baseline
    # (jump + squash & stretch), so Pip stays planted.
    dict(ns=1, stage_x=0, file="egg", artboard="PipEgg", jump=8, stretch=1.0, svg="pip_stage_1.svg", stage=1,
         pivot=(120, 120), root=(120, 212), body="body",
         pupils=["pupil_l", "pupil_r"],
         glints=[], wings=[], beak=None, highlight=None, wobble=True,
         groups=[(None, None, ["shadow"]),
                 ("egg", (120, 120), None)]),
    dict(ns=2, stage_x=320, file="hatchling", artboard="PipHatchling", jump=12, stretch=1.0,
         svg="pip_stage_2.svg", stage=2,
         pivot=(120, 150), root=(120, 208), body="body",
         pupils=["pupil_l", "pupil_r"],
         glints=["glint_l", "glint_r"], wings=["wing_l", "wing_r"],
         beak="beak", highlight="shine", wobble=False,
         groups=[(None, None, ["shadow"]),
                 ("chick", (120, 150), None)]),
    dict(ns=3, stage_x=640, file="fledgling", artboard="PipFledgling", jump=20, stretch=1.0,
         svg="pip_stage_3.svg", stage=3,
         pivot=(120, 135), root=(120, 207), body="body",
         pupils=["pupil_l", "pupil_r"],
         glints=["glint_l", "glint_r"], wings=["wing_l", "wing_r"],
         beak="beak", highlight="shine", wobble=False,
         groups=[(None, None, ["shadow"]),
                 ("feet", (120, 207), ["foot_l", "foot_r"]),
                 ("chick", (120, 135), None)]),
    dict(ns=4, stage_x=960, file="songbird", artboard="PipSongbird", jump=0, stretch=0.35,
         svg="pip_stage_4.svg", stage=4,
         pivot=(120, 122), root=(120, 208), body="body",
         pupils=["pupil_l", "pupil_r"],
         glints=["glint_l", "glint_r"], wings=["wing_l", "wing_r"],
         beak="beak", highlight="shine", wobble=False,
         # The green tip is part of the wing, so the two are wrapped in a
         # node that pivots on the shoulder and the whole node is what flaps.
         flaps=[("flap_l", "wing_l", ["wing_l", "wing_tip_l"]),
                ("flap_r", "wing_r", ["wing_r", "wing_tip_r"])],
         groups=[(None, None, ["shadow"]),
                 ("tail", (120, 190), ["tail_a", "tail_b", "tail_c"]),
                 ("feet", (120, 208), ["foot_l", "foot_r"]),
                 ("chick", (120, 122), None)]),
]

# Which SVG element becomes which rig name, per stage, in document order.
# Anything not listed is auto-named art_NN and left in place.
NAMES = {
    "pip_stage_1.svg": ["shadow", "body", "spot_1", "spot_2", "spot_3", "spot_4",
                        "spot_5", "shine", "crack", "band", "eye_l", "pupil_l",
                        "eye_r", "pupil_r"],
    "pip_stage_2.svg": ["shadow", "shell_bottom", "body", "shine", "wing_l",
                        "wing_r", "eye_l", "eye_r", "pupil_l", "pupil_r",
                        "glint_l", "glint_r", "beak", "shell_hat"],
    "pip_stage_3.svg": ["shadow", "foot_l", "foot_r", "body", "shine",
                        ["wing_l", "wing_r"],
                        ["crest_1", "crest_2", "crest_3"],
                        "eye_l", "eye_r",
                        "pupil_l", "pupil_r", "glint_l", "glint_r", "beak"],
    "pip_stage_4.svg": ["shadow", "tail_a", "tail_b", "tail_c", "foot_l",
                        "foot_r", "body", "shine", "belly", "wing_l",
                        "wing_tip_l", "wing_r", "wing_tip_r",
                        ["crest_1", "crest_2"],
                        "scarf", "scarf_knot", "scarf_tail",
                        "eye_l", "eye_r",
                        "pupil_l", "pupil_r", "glint_l", "glint_r", "beak"],
}


# ------------------------------------------------------------------ helpers

def rd(v):
    """rotation, distance from a vertex to a control point."""
    dx, dy = v[0], v[1]
    return math.atan2(dy, dx), math.hypot(dx, dy)


def subpaths(d):
    """Contours with the duplicated closing anchor folded into the first one.

    An SVG path that curves back to its start (for example `... c ... Z`) ends
    with a second anchor at the start point. That anchor carries the LAST
    segment's incoming control point, so it must be merged into the first
    anchor, not simply dropped - dropping it turns the closing curve into a
    straight chord, which is very visible on a rounded silhouette.
    """
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


def geometry(prim, origin, ind, name="", sid=None, xf=(1.0, 0.0, 0.0)):
    """Path/ellipse/rect geometry relative to `origin`, as a list of
    (pivot, rotation, rows) parts - one per subpath.

    `xf` is an (scale, dx, dy) affine applied in the SVG's own coordinate
    space, so one drawing can be placed into a composed artboard without
    re-deriving its geometry. PipStage uses it to drop nest.svg into scene
    space; the stage rigs leave it at identity and are placed by their wrapper
    Node instead.
    """
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
            # An anchor is (x, y, in_control, out_control); both bezier
            # controls are absolute coordinates and scale with the anchor.
            def t(c):
                return None if c is None else (c[0] * sc + dx, c[1] * sc + dy)
            sp = [(x * sc + dx, y * sc + dy, t(ic), t(oc))
                  for (x, y, ic, oc) in sp]
        px, py = choose_pivot(sp, name)
        out.append(((px, py), ang, _points(sp, filled, (px, py), ind)))
    return out


def style_has_fill(prim):
    f = prim["style"].get("fill", "none")
    return bool(f) and f != "none"


def contour_bbox(pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


# A rig name may ask for a specific pivot. The default is the contour's own
# centre, which is what a parametric primitive does anyway.
PIVOTS = {
    #   name          -> (mode, dx, dy)   dx/dy nudge the chosen pivot
    "wing_l":        ("left_shoulder", 0, 0),
    "wing_r":        ("right_shoulder", 0, 0),
    "beak":          ("top_hinge", 0, 0),
    "crest_1":       ("crest_base", 0, 0),
    "crest_2":       ("crest_base", 0, 0),
    "crest_3":       ("crest_base", 0, 0),
    "tail_a":        ("tail_base", 0, 0),
    "tail_b":        ("tail_base", 0, 0),
    "tail_c":        ("tail_base", 0, 0),
}


def choose_pivot(pts, name):
    x0, y0, x1, y1 = contour_bbox(pts)
    mode, dx, dy = PIVOTS.get(name, ("centre", 0, 0))
    if mode == "left_shoulder":
        # the wing's inner edge, mid height: where it meets the body
        return (x1 + dx, (y0 + y1) / 2 + dy)
    if mode == "right_shoulder":
        return (x0 + dx, (y0 + y1) / 2 + dy)
    if mode == "top_hinge":
        return ((x0 + x1) / 2 + dx, y0 + dy)
    if mode == "crest_base":
        # a tuft sways from the bottom of its stroke, not its middle
        return ((x0 + x1) / 2 + dx, y1 + dy)
    if mode == "tail_base":
        return ((x0 + x1) / 2 + dx, y0 + dy)
    return ((x0 + x1) / 2 + dx, (y0 + y1) / 2 + dy)


def _points(pts, closed, origin, ind):
    """A Rive vertex per anchor.

    A vertex's incoming control point is the SECOND control of the cubic that
    arrives at it (pts[i].in), and its outgoing control is the FIRST control of
    the cubic that leaves it (pts[i].out). A side with no control is a straight
    line, which is how a StraightVertex is chosen.
    """
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


def paints(style, opacity, ind, scale=1.0):
    """Fill + stroke rows for one element. `scale` multiplies the stroke width
    so it keeps its weight when the geometry is scaled with it."""
    pad = " " * ind
    rows = []
    fill = style.get("fill", "none")
    stroke = style.get("stroke", "none")
    sw = float(style.get("stroke-width", "0") or 0) * scale
    line_op = float(style.get("opacity", "1")) * opacity
    if fill and fill != "none":
        a = line_op * float(style.get("fill-opacity", "1"))
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


# ------------------------------------------------------------- artboard build

def rig(cfg, ind, skip_shadow=False):
    """Emit one stage's rig (nodes + shapes) in the CURRENT id namespace.

    Returns (lines, name_to_id). The rig is authored in the SVG's own 240x240
    space, so a caller can wrap it in a Node to place and scale it anywhere -
    which is how PipStage reuses the same art inside a composed scene.
    """
    global NAMES_INDEX, OWNER_NAMES, OWNER_NAMES
    prims, vb = S.collect(os.path.join(SVG_DIR, cfg["svg"]))
    raw = NAMES[cfg["svg"]]
    assert len(raw) == len(prims), \
        f"{cfg['svg']}: {len(raw)} names for {len(prims)} elements"

    vb_w, vb_h = vb[2], vb[3]
    px, py = cfg["pivot"]

    # Flatten the per-element names, and remember which element each came from
    # so multi-subpath elements can expand into several shapes.
    names, owner = [], []
    for i, n in enumerate(raw):
        parts = n if isinstance(n, list) else [n]
        for ci, part in enumerate(parts):
            names.append(part)
            # (element index, which contour of that element)
            owner.append((i, ci))

    ids = {n: sid(k + 1) for k, n in enumerate(names)}
    NAMES_INDEX = ids
    OWNER_NAMES = names
    used = {n for _, _, k in cfg["groups"] if k for n in k}
    grouped = []
    for gname, gorigin, keep in cfg["groups"]:
        members = list(keep) if keep is not None else [n for n in names if n not in used]
        grouped.append((gname, gorigin, members))

    def shapes_for(name, origin, ind):
        """One <Shape> per rig name. A name selects a single contour, so a
        two-contour path (stage 3's wings) becomes two independent shapes."""
        ei, ci = owner[names.index(name)]
        prim = prims[ei]
        parts = geometry(prim, origin, ind, name)
        # Each name owns ONE contour. Selecting a fixed index instead is how
        # both wings ended up drawing the left wing, and how the three crest
        # tufts all drew the same tuft.
        p, ang, geom = parts[ci if ci < len(parts) else len(parts) - 1]
        pad = " " * ind
        rot = f' rotation="{S.num(ang)}"' if abs(ang) > 1e-9 else ""
        rows = [f'{pad}<Shape x="{S.num(p[0]-origin[0])}" '
                f'y="{S.num(p[1]-origin[1])}"{rot} name="{name}" '
                f'id="{ids[name]}">']
        rows += geom
        rows += paints(prim["style"], prim["opacity"], ind)
        rows.append(f"{pad}</Shape>")
        return rows

    body = []
    _pad = " " * ind

    for gname, gorigin, members in reversed(grouped):
        if gname is None:
            # Ungrouped: the artboard is the parent, so geometry is expressed
            # in artboard coordinates. PipStage drops the shadow, because in
            # that composition the NEST casts the one ground shadow.
            for m in reversed(members):
                if skip_shadow and m == "shadow":
                    continue
                body += shapes_for(m, (0, 0), ind)
        else:
            is_pivot = gorigin == (px, py)
            ox, oy = (px, py) if is_pivot else gorigin
            if is_pivot:
                # Two levels on purpose:
                #   <Node root>  pivots on the feet baseline: jump and squash.
                #   <Node chick> pivots on the body centre: breathing only.
                rx, ry = cfg["root"]
                body.append(f'{_pad}<Node x="{S.num(rx)}" y="{S.num(ry)}" '
                            f'name="{gname}_root" '
                            f'id="{sid(210 + gname_id(cfg, gname))}">')
                body.append(f'{_pad}  <Node x="0" y="{S.num(oy - ry)}" '
                            f'name="{gname}" '
                            f'id="{sid(200 + gname_id(cfg, gname))}">')
                flap_members = {n for _, _, ms in cfg.get("flaps", [])
                                for n in ms}
                for m in reversed(members):
                    if m in flap_members:
                        continue
                    body += shapes_for(m, (ox, oy), ind + 4)
                for fname, wing, ms in cfg.get("flaps", []):
                    fp = _pivot_of(prims, names, owner, wing)
                    body.append(f'{_pad}      <Node x="{S.num(fp[0]-ox)}" '
                                f'y="{S.num(fp[1]-oy)}" name="{fname}" '
                                f'id="{sid(220 + gname_id(cfg, fname))}">')
                    for m in reversed(ms):
                        body += shapes_for(m, fp, ind + 6)
                    body.append(f"{_pad}      </Node>")
                body.append(f"{_pad}  </Node>")
                body.append(f"{_pad}</Node>")
            else:
                body.append(f'{_pad}<Node x="{S.num(ox)}" y="{S.num(oy)}" '
                            f'name="{gname}" '
                            f'id="{sid(200 + gname_id(cfg, gname))}">')
                for m in reversed(members):
                    body += shapes_for(m, (ox, oy), ind + 2)
                body.append(f"{_pad}</Node>")
        body.append("")

    return body, ids


def build_stage(cfg):
    """A standalone Pip artboard: the rig, its state machine and its view model."""
    body, _ = rig(cfg, 8)
    _, vb = S.collect(os.path.join(SVG_DIR, cfg["svg"]))
    out = ['<Rive version="1" kind="fragment">']
    out.append(f'    <Artboard name="{cfg["artboard"]}" x="{cfg["stage_x"]}" '
               f'y="0" width="{S.num(vb[2])}" height="{S.num(vb[3])}" '
               f'defaultStateMachineId="{SM}" '
               f'viewModelId="{VM}" viewModelInstanceId="{VMI}" '
               f'styleId="{sid(999)}" id="{sid(998)}">')
    out.append(f'        <LayoutComponentStyle name="Artboard Style" '
               f'id="{sid(999)}"/>')
    out.append("")
    out += body
    out += state_machine(cfg)
    out.append("")
    out += animations(cfg)
    out.append("    </Artboard>")
    out.append("")
    out += view_model(cfg)
    out.append("</Rive>")
    return "\n".join(out)
    return "\n".join(body)


def _pivot_of(prims, names, owner, name):
    """The absolute pivot a rig name animates about."""
    ei, ci = owner[names.index(name)]
    prim = prims[ei]
    if prim["tag"] == "path":
        subs = subpaths(prim["el"].attrib["d"])
        return choose_pivot(subs[min(ci, len(subs) - 1)], name)
    return _abs_origin(prims, owner, name)


def _abs_origin(prims, owner, name):
    prim = prims[owner[OWNER_NAMES.index(name)][0]]
    el = prim["el"]
    if prim["tag"] == "path":
        pts = [sp for s in subpaths(el.attrib["d"]) for sp in s]
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        return ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2)
    if prim["tag"] == "rect":
        return (float(el.attrib["x"]) + float(el.attrib["width"]) / 2,
                float(el.attrib["y"]) + float(el.attrib["height"]) / 2)
    return (float(el.attrib["cx"]), float(el.attrib["cy"]))


def gname_id(cfg, gname):
    """A small stable index per rig node, used only to space out ids."""
    names = [g for g, _, _ in cfg["groups"]]
    names += [f for f, _, _ in cfg.get("flaps", [])]
    return names.index(gname) + 1


# ------------------------------------------------------------- shared rig
P = "        "

NAMES_INDEX = {}
OWNER_NAMES = []


def _cond(dest, prop, duration, value, ind=P):
    return [
        f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}">',
        f'{ind}    <TransitionViewModelCondition opValue="equal">',
        f'{ind}      <TransitionPropertyViewModelComparator>',
        f'{ind}        <BindablePropertyNumber>',
        f'{ind}          <DataBindContext sourcePathIds="{VM}-{prop}" '
        f'propertyKey="636"/>',
        f'{ind}        </BindablePropertyNumber>',
        f'{ind}      </TransitionPropertyViewModelComparator>',
        f'{ind}      <TransitionValueNumberComparator value="{value}"/>',
        f'{ind}    </TransitionViewModelCondition>',
        f'{ind}  </StateTransition>',
    ]


def state_machine(cfg):
    r = [f'{P}<StateMachine name="Pip" id="{SM}">',
         f'{P}  <StateMachineLayer name="Body" id="{LAYER}">',
         f'{P}    <AnyState x="560" y="-120"/>',
         f'{P}    <ExitState x="760" y="-120"/>',
         f'{P}    <EntryState x="40" y="-120">',
         f'{P}      <StateTransition stateToId="{ST_IDLE}" duration="0"/>',
         f'{P}    </EntryState>',
         f'{P}    <AnimationState x="160" y="-120" animationId="{A_IDLE}" '
         f'id="{ST_IDLE}">']
    r += _cond(ST_HAPPY, P_MOOD, 120, 1)
    r += _cond(ST_EAT, P_MOOD, 120, 2)
    r += [f'{P}      <StateTransition stateToId="{ST_EVOLVE}" duration="100">',
          f'{P}        <TransitionViewModelCondition opValue="equal">',
          f'{P}          <TransitionPropertyViewModelComparator>',
          f'{P}            <BindablePropertyTrigger>',
          f'{P}              <DataBindContext sourcePathIds="{VM}-{P_EVOLVE}" '
          f'propertyKey="686"/>',
          f'{P}            </BindablePropertyTrigger>',
          f'{P}          </TransitionPropertyViewModelComparator>',
          f'{P}          <TransitionValueTriggerComparator value="1"/>',
          f'{P}        </TransitionViewModelCondition>',
          f'{P}      </StateTransition>',
          f'{P}    </AnimationState>']
    for (st, anim, blend, sx, sy) in (
            (ST_HAPPY, A_HAPPY, 220, 360, -40),
            (ST_EAT, A_EAT, 220, 560, -40),
            (ST_EVOLVE, A_EVOLVE, 300, 360, 60)):
        r += [f'{P}    <AnimationState x="{sx}" y="{sy}" animationId="{anim}" '
              f'id="{st}">',
              f'{P}      <StateTransition stateToId="{ST_IDLE}" duration="{blend}" '
              f'enableExitTime="true" exitTimeIsPercetange="true" exitTime="100"/>',
              f'{P}    </AnimationState>']
    r += [f"{P}  </StateMachineLayer>", f"{P}</StateMachine>"]
    return r


def _keyed(oid, key, frames, ind):
    """frames: list of (value, frame|None, interpolation)."""
    out = [f'{ind}<KeyedObject objectId="{oid}">',
           f'{ind}  <KeyedProperty propertyKey="{key}">']
    for val, fr, interp in frames:
        f = f' frame="{fr}"' if fr else ""
        out.append(f'{ind}    <KeyFrameDouble value="{S.num(val)}" '
                   f'interpolationType="{interp}"{f}/>')
    out.append(f"{ind}  </KeyedProperty>")
    out.append(f"{ind}</KeyedObject>")
    return out


def animations(cfg, aids=None):
    """The four mood timelines for one rig. `aids` overrides the animation ids
    so PipStage can re-emit the same timelines under its own id block."""
    a_idle, a_happy, a_eat, a_evolve = aids or (A_IDLE, A_HAPPY, A_EAT, A_EVOLVE)
    px, py = cfg["pivot"]
    g = gname_id(cfg, "egg" if cfg["wobble"] else "chick")
    ry = cfg["root"][1]          # the root node's REST y. A keyed y is
                                 # ABSOLUTE, not a delta, so it has to be
                                 # restated in full.
    gid = sid(200 + g)          # body centre: breathing
    rid = sid(210 + g)          # feet baseline: jump + squash & stretch
    r = []

    # ---- idle: 3 s loop. breathe (or wobble for the egg) + a blink at f132.
    r.append(f'{P}<LinearAnimation name="idle" duration="180" fps="60" '
             f'loopValue="loop" id="{a_idle}">')
    if cfg["wobble"]:
        r += _keyed(rid, 15, [(0, None, "linear"), (0.05, 45, "cubic"),
                             (-0.05, 135, "cubic"), (0, 180, "cubic")], P + "  ")
    else:
        r += _keyed(gid, 17, [(1, None, "linear"), (1.03, 90, "cubic"),
                              (1, 180, "cubic")], P + "  ")
    for p in cfg["pupils"]:
        r += _keyed(ids_of(cfg, p), 17, [(1, None, "hold"), (0.08, 132, "cubic"),
                                         (1, 140, "cubic")], P + "  ")
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- happy: 1.2 s jump. Squash & stretch is VOLUME PRESERVING
    #      (scaleX * scaleY == 1) and keyed on the feet-baseline node, so Pip
    #      stays planted. Wings rotate about their shoulder pivots only.
    r.append(f'{P}<LinearAnimation name="happy" duration="72" fps="60" '
             f'loopValue="oneShot" id="{a_happy}">')
    # Squash & stretch is VOLUME PRESERVING (scaleX * scaleY == 1) and the
    # amplitude is scaled per stage so a tall character cannot clip the
    # artboard at the top of its hop.
    st_ = cfg.get("stretch", 1.0)
    r += _keyed(rid, 16, [(1, None, "cubic"),
                          (1 + 0.08 * st_, 8, "cubic"),
                          (1 - 0.07 * st_, 24, "cubic"),
                          (1, 46, "cubic"),
                          (1 - 0.01 * st_, 62, "cubic"), (1, 72, "cubic")],
                P + "  ")
    r += _keyed(rid, 17, [(1, None, "cubic"),
                          (1 - 0.07 * st_, 8, "cubic"),
                          (1 + 0.08 * st_, 24, "cubic"),
                          (1, 46, "cubic"),
                          (1 + 0.01 * st_, 62, "cubic"), (1, 72, "cubic")],
                P + "  ")
    flaps = cfg.get("flaps")
    if flaps:
        # Flap the node that carries the whole wing, tip included.
        for i, (fname, _, _) in enumerate(flaps):
            sd = 1 if i == 0 else -1
            r += _keyed(sid(220 + gname_id(cfg, fname)), 15,
                        [(0, None, "cubic"), (-0.4363 * sd, 12, "cubic"),
                         (0.4363 * sd, 24, "cubic"), (-0.4363 * sd, 36, "cubic"),
                         (0, 48, "cubic")], P + "  ")
    else:
        for i, w in enumerate(cfg["wings"]):
            sd = 1 if i == 0 else -1
            # +/- 25 degrees about the shoulder. No x/y keys: the wing must
            # never leave the body.
            r += _keyed(ids_of(cfg, w), 15,
                        [(0, None, "cubic"), (-0.4363 * sd, 12, "cubic"),
                         (0.4363 * sd, 24, "cubic"), (-0.4363 * sd, 36, "cubic"),
                         (0, 48, "cubic")], P + "  ")
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- eat: 1.8 s of three chews. The beak hinges at its top and opens and
    #      closes; the crest is not involved.
    r.append(f'{P}<LinearAnimation name="eat" duration="108" fps="60" '
             f'loopValue="oneShot" id="{a_eat}">')
    if cfg["beak"]:
        r += _keyed(ids_of(cfg, cfg["beak"]), 17,
                    [(1, None, "cubic"), (0.45, 10, "cubic"),
                     (1.06, 20, "cubic"), (0.45, 34, "cubic"),
                     (1.06, 44, "cubic"), (0.45, 58, "cubic"),
                     (1, 72, "cubic")], P + "  ")
        # A little travel so the beak reads as opening, not just flattening.
        r += _keyed(ids_of(cfg, cfg["beak"]), 14,
                    [(0, None, "cubic"), (3, 10, "cubic"),
                     (0, 20, "cubic"), (3, 34, "cubic"),
                     (0, 44, "cubic"), (3, 58, "cubic"),
                     (0, 72, "cubic")], P + "  ")
    r += _keyed(gid, 17, [(1, None, "cubic"), (1.03, 30, "cubic"),
                          (1, 70, "cubic")], P + "  ")
    r.append(f"{P}</LinearAnimation>")
    r.append("")

    # ---- evolve: 1.5 s. Squat, then a small volume-preserving pop with a
    #      highlight flare. Amplitude capped at 1.12 / 0.9 on the baseline
    #      node so Pip never stretches into an egg.
    r.append(f'{P}<LinearAnimation name="evolve" duration="90" fps="60" '
             f'loopValue="oneShot" id="{a_evolve}">')
    ev = cfg.get("stretch", 1.0)
    r += _keyed(rid, 16, [(1, None, "cubic"), (1 + 0.06 * ev, 16, "cubic"),
                          (1 - 0.05 * ev, 36, "cubic"), (1, 66, "cubic"),
                          (1, 90, "cubic")], P + "  ")
    r += _keyed(rid, 17, [(1, None, "cubic"), (1 - 0.06 * ev, 16, "cubic"),
                          (1 + 0.06 * ev, 36, "cubic"), (1, 66, "cubic"),
                          (1, 90, "cubic")], P + "  ")
    pop = cfg.get("jump", 12) * 0.6
    r += _keyed(rid, 14, [(ry, None, "cubic"), (ry - pop, 36, "cubic"),
                          (ry, 62, "cubic")], P + "  ")
    if cfg["highlight"]:
        r += _keyed(ids_of(cfg, cfg["highlight"]), 18,
                    [(0.55, None, "cubic"), (1, 36, "cubic"),
                     (0.55, 90, "cubic")], P + "  ")
    r.append(f"{P}</LinearAnimation>")
    return r


def view_model(cfg):
    return [
        f'{P[:-4]}<ViewModel name="Pip" defaultInstanceId="{VMI}" id="{VM}">',
        f'{P[:-4]}    <ViewModelPropertyNumber name="mood" id="{P_MOOD}"/>',
        f'{P[:-4]}    <ViewModelPropertyNumber name="stage" id="{P_STAGE}"/>',
        f'{P[:-4]}    <ViewModelPropertyTrigger name="evolve" id="{P_EVOLVE}"/>',
        f'{P[:-4]}    <ViewModelPropertyTrigger name="tap" id="{P_TAP}"/>',
        f'{P[:-4]}    <ViewModelInstance exports="true" name="Default" id="{VMI}">',
        f'{P[:-4]}        <ViewModelInstanceNumber propertyValue="0" '
        f'viewModelPropertyId="{P_MOOD}"/>',
        f'{P[:-4]}        <ViewModelInstanceNumber propertyValue="{cfg["stage"]}" '
        f'viewModelPropertyId="{P_STAGE}"/>',
        f'{P[:-4]}        <ViewModelInstanceTrigger viewModelPropertyId="{P_EVOLVE}"/>',
        f'{P[:-4]}        <ViewModelInstanceTrigger viewModelPropertyId="{P_TAP}"/>',
        f'{P[:-4]}    </ViewModelInstance>',
        f'{P[:-4]}</ViewModel>',
    ]


def ids_of(cfg, name):
    return NAMES_INDEX[name]


# ------------------------------------------------------------------ the jar
J = "        "
# Jar artboard ids.
J_LID, J_GLASS, J_CLIP, J_GOLD, J_OUTLINE = (sid(1), sid(2), sid(3), sid(4), sid(5))
J_PLUS, J_GLOSS, J_NODE, J_CLIPNODE = sid(6), sid(7), sid(8), sid(9)
J_SPLASH = sid(20)
J_COINS = [sid(30 + i) for i in range(8)]
J_SM = sid(300)
J_LAYER = sid(301)
J_ST_HOLD, J_ST_DROP = sid(302), sid(303)
J_A_FILL, J_A_DROP = sid(400), sid(401)
J_VM, J_VMI = sid(500), sid(501)
J_P_FILL, J_P_DROP = sid(502), sid(503)
J_RANGE = sid(600)

# Coin circles from jar_coins.svg, in the SVG's own order.
JAR_COINS = [(66, 128, 15), (102, 118, 13), (134, 132, 15), (82, 154, 16),
             (120, 158, 14), (100, 182, 15), (58, 178, 13), (144, 180, 12)]
# The jar's inner window: rect x=36 y=40 w=128 h=168 rx=24.
JX, JY, JW, JH, JR = 36, 40, 128, 168, 24
# The gold band spans y 104..208 inside the window (y 40..208). It is anchored
# to the BOTTOM of the window and grows upward as `fill` rises.
GOLD_TOP, GOLD_BOT = 104, 208


def jar():
    r = ['<Rive version="1" kind="fragment">']
    r.append(f'    <Artboard name="Jar" x="1280" y="0" '
             f'width="200" height="236" '
             f'defaultStateMachineId="{J_SM}" viewModelId="{J_VM}" '
             f'viewModelInstanceId="{J_VMI}" styleId="{sid(999)}" '
             f'id="{sid(998)}">')
    r.append(f'        <LayoutComponentStyle name="Artboard Style" id="{sid(999)}"/>')
    r.append("")

    # Draw order is front-to-back.
    # 1. the lilac plus badge (top-most detail)
    r.append(f'{J}<Shape x="134" y="50" name="plus" id="{J_PLUS}">')
    r.append(f'{J}  <PointsPath isClosed="false">')
    for x, y in ((134, 44), (134, 56)):
        r.append(f'{J}    <StraightVertex x="{x-134}" y="{y-50}"/>')
    r.append(f'{J}  </PointsPath>')
    r.append(f'{J}  <PointsPath isClosed="false">')
    for x, y in ((128, 50), (140, 50)):
        r.append(f'{J}    <StraightVertex x="{x-134}" y="{y-50}"/>')
    r.append(f'{J}  </PointsPath>')
    r.append(f'{J}  <Stroke name="S" thickness="4" cap="round">'
             f'<SolidColor colorValue="FF7C6CF2" name="C"/></Stroke>')
    r.append(f"{J}</Shape>")
    r.append("")

    # 2. glass highlight
    r.append(f'{J}<Shape x="50" y="80" name="gloss" id="{J_GLOSS}">')
    r.append(f'{J}  <PointsPath isClosed="false">')
    r.append(f'{J}    <StraightVertex x="0" y="-24"/>')
    r.append(f'{J}    <StraightVertex x="-4" y="-8"/>')
    r.append(f'{J}    <StraightVertex x="-2" y="24"/>')
    r.append(f'{J}  </PointsPath>')
    r.append(f'{J}  <Stroke name="S" thickness="7" cap="round">'
             f'<SolidColor colorValue="E6FFFFFF" name="C"/></Stroke>')
    r.append(f"{J}</Shape>")
    r.append("")

    # 3. glass outline (drawn over the coins, as in the SVG)
    r.append(f'{J}<Shape x="{JX+JW/2}" y="{JY+JH/2}" name="glass_outline" '
             f'id="{J_OUTLINE}">')
    r.append(f'{J}  <Rectangle width="{JW}" height="{JH}" cornerRadiusTL="{JR}" '
             f'linkCornerRadius="true" name="P"/>')
    r.append(f'{J}  <Stroke name="S" thickness="4">'
             f'<SolidColor colorValue="FF1E1B3A" name="C"/></Stroke>')
    r.append(f"{J}</Shape>")
    r.append("")

    # 4. the contents. A ClippingShape nests INSIDE the shape it masks, and
    #    the source is a normal shape with no paints: it contributes geometry
    #    without drawing anything itself.
    r.append(f'{J}<Node name="contents" x="0" y="0" id="{J_NODE}">')
    # Coins first: the FIRST child draws on top, and the coins must sit on the
    # gold rather than under it.
    for i, (cx, cy, cr) in enumerate(JAR_COINS):
        r.append(f'{J}  <Shape x="{cx}" y="{cy}" name="coin_{i+1}" '
                 f'id="{J_COINS[i]}">')
        r.append(f'{J}    <Ellipse width="{2*cr}" height="{2*cr}" name="P"/>')
        r.append(f'{J}    <Fill name="F">'
                 f'<SolidColor colorValue="FFF4B400" name="C"/></Fill>')
        r.append(f'{J}    <Stroke name="S" thickness="3">'
                 f'<SolidColor colorValue="FF1E1B3A" name="C"/></Stroke>')
        r.append(f'{J}    <ClippingShape sourceId="{J_CLIP}" name="Clip"/>')
        r.append(f'{J}  </Shape>')
    r.append(f'{J}  <Shape x="{JX}" y="{GOLD_BOT}" name="gold" id="{J_GOLD}">')
    r.append(f'{J}    <Rectangle width="{JW}" height="0" cornerRadiusBL="{JR}" '
             f'cornerRadiusBR="{JR}" linkCornerRadius="false" originX="0" '
             f'originY="1" name="P">')
    r.append(f'{J}      <DataBindContext sourcePathIds="{J_VM}-{J_P_FILL}" '
             f'propertyKey="21" converterId="{J_RANGE}"/>')
    r.append(f'{J}    </Rectangle>')
    r.append(f'{J}    <Fill name="F">'
             f'<SolidColor colorValue="FFE09700" name="C"/></Fill>')
    r.append(f'{J}    <ClippingShape sourceId="{J_CLIP}" name="Clip"/>')
    r.append(f'{J}  </Shape>')
    r.append(f'{J}</Node>')
    r.append("")

    # 5. splash ring, hidden until a coin lands
    r.append(f'{J}<Shape x="100" y="{GOLD_TOP}" name="splash" id="{J_SPLASH}">')
    r.append(f'{J}  <Ellipse width="10" height="4" name="P"/>')
    r.append(f'{J}  <Fill name="F">'
             f'<SolidColor colorValue="66F4B400" name="C"/></Fill>')
    r.append(f'{J}</Shape>')
    r.append("")

    # 6. the mask itself. No Fill, no Stroke - it must not draw.
    r.append(f'{J}<Shape x="{JX+JW/2}" y="{JY+JH/2}" name="window_mask" '
             f'id="{J_CLIP}">')
    r.append(f'{J}  <Rectangle width="{JW}" height="{JH}" cornerRadiusTL="{JR}" '
             f'linkCornerRadius="true" name="P"/>')
    r.append(f'{J}</Shape>')
    r.append("")

    # 7. glass body, then the lid
    r.append(f'{J}<Shape x="100" y="120" name="glass" id="{J_GLASS}">')
    r.append(f'{J}  <Rectangle width="144" height="192" cornerRadiusTL="30" '
             f'linkCornerRadius="true" name="P"/>')
    r.append(f'{J}  <Fill name="F">'
             f'<SolidColor colorValue="FFF2FAFF" name="C"/></Fill>')
    r.append(f'{J}</Shape>')
    r.append(f'{J}<Shape x="100" y="15" name="lid" id="{J_LID}">')
    r.append(f'{J}  <Rectangle width="100" height="22" cornerRadiusTL="10" '
             f'linkCornerRadius="true" name="P"/>')
    r.append(f'{J}  <Fill name="F">'
             f'<SolidColor colorValue="FF7C6CF2" name="C"/></Fill>')
    r.append(f'{J}  <Stroke name="S" thickness="4">'
             f'<SolidColor colorValue="FF1E1B3A" name="C"/></Stroke>')
    r.append(f'{J}</Shape>')
    r.append("")

    # ---- state machine: hold <-> drop, gated on the `drop` trigger
    r.append(f'{J}<StateMachine name="Jar" id="{J_SM}">')
    r.append(f'{J}  <StateMachineLayer name="Body" id="{J_LAYER}">')
    r.append(f'{J}    <AnyState x="560" y="-120"/>')
    r.append(f'{J}    <ExitState x="760" y="-120"/>')
    r.append(f'{J}    <EntryState x="40" y="-120">')
    r.append(f'{J}      <StateTransition stateToId="{J_ST_HOLD}" duration="0"/>')
    r.append(f'{J}    </EntryState>')
    r.append(f'{J}    <AnimationState x="160" y="-120" animationId="{J_A_FILL}" '
             f'id="{J_ST_HOLD}">')
    r.append(f'{J}      <StateTransition stateToId="{J_ST_DROP}" duration="80">')
    r.append(f'{J}        <TransitionViewModelCondition opValue="equal">')
    r.append(f'{J}          <TransitionPropertyViewModelComparator>')
    r.append(f'{J}            <BindablePropertyTrigger>')
    r.append(f'{J}              <DataBindContext sourcePathIds="{J_VM}-{J_P_DROP}" '
             f'propertyKey="686"/>')
    r.append(f'{J}            </BindablePropertyTrigger>')
    r.append(f'{J}          </TransitionPropertyViewModelComparator>')
    r.append(f'{J}          <TransitionValueTriggerComparator value="1"/>')
    r.append(f'{J}        </TransitionViewModelCondition>')
    r.append(f'{J}      </StateTransition>')
    r.append(f'{J}    </AnimationState>')
    r.append(f'{J}    <AnimationState x="360" y="60" animationId="{J_A_DROP}" '
             f'id="{J_ST_DROP}">')
    r.append(f'{J}      <StateTransition stateToId="{J_ST_HOLD}" duration="0" '
             f'enableExitTime="true" exitTimeIsPercetange="true" exitTime="100"/>')
    r.append(f'{J}    </AnimationState>')
    r.append(f'{J}  </StateMachineLayer>')
    r.append(f'{J}</StateMachine>')
    r.append("")

    # ---- the resting timeline holds whatever `fill` says (no keys)
    r.append(f'{J}<LinearAnimation name="hold" duration="1" fps="60" '
             f'loopValue="loop" id="{J_A_FILL}"/>')
    r.append("")

    # ---- 1.6 s drop: the level rises, three coins fall, the splash pops
    r.append(f'{J}<LinearAnimation name="drop" duration="96" fps="60" '
             f'loopValue="oneShot" id="{J_A_DROP}">')
    # The band's height is data-bound, so the drop animation drives the bound
    # value rather than the property: keying the bound property would fight it.
    r += _keyed(J_NODE, 17, [(1, None, "hold"), (1, 62, "cubic"),
                             (1, 96, "linear")], J + "  ")
    r += _keyed(J_SPLASH, 16, [(0, None, "hold"), (1, 66, "cubic"),
                               (0, 90, "cubic")], J + "  ")
    r += _keyed(J_SPLASH, 17, [(1, None, "hold"), (3.4, 66, "cubic"),
                               (1, 90, "cubic")], J + "  ")
    # Three coins fall in from above the rim, land, and stay.
    for i, (cid, delay) in enumerate(((J_COINS[0], 0), (J_COINS[1], 9),
                                      (J_COINS[2], 18))):
        rest = JAR_COINS[i][1]
        r += _keyed(cid, 14, [(rest - 150, delay, "cubic"),
                              (rest, delay + 32, "cubic"),
                              (rest, 96, "linear")], J + "  ")
        r += _keyed(cid, 16, [(0, delay, "hold"), (1, delay + 32, "cubic"),
                              (1, 96, "linear")], J + "  ")
    r.append(f"{J}</LinearAnimation>")
    r.append("    </Artboard>")
    r.append("")

    # ---- view model: fill (0..1) + drop trigger
    r.append(f'    <DataConverterRangeMapper minInput="0" maxInput="1" '
             f'minOutput="0" maxOutput="{GOLD_BOT - JY}" clampLower="true" '
             f'clampUpper="true" name="ToHeight" id="{J_RANGE}"/>')
    r.append(f'    <ViewModel name="Jar" defaultInstanceId="{J_VMI}" id="{J_VM}">')
    r.append(f'        <ViewModelPropertyNumber name="fill" id="{J_P_FILL}"/>')
    r.append(f'        <ViewModelPropertyTrigger name="drop" id="{J_P_DROP}"/>')
    r.append(f'        <ViewModelInstance exports="true" name="Default" '
             f'id="{J_VMI}">')
    r.append(f'            <ViewModelInstanceNumber propertyValue="0.55" '
             f'viewModelPropertyId="{J_P_FILL}"/>')
    r.append(f'            <ViewModelInstanceTrigger '
             f'viewModelPropertyId="{J_P_DROP}"/>')
    r.append(f'        </ViewModelInstance>')
    r.append(f'    </ViewModel>')
    r.append("</Rive>")
    return "\n".join(r)


# -------------------------------------------------------------------- main

BG_FILL = ('        <Fill name="Background">'
           '<SolidColor colorValue="FFFFFDF8" name="C"/></Fill>')


def emit_preview(out_dir, bg="FFFFFDF8"):
    """A throwaway copy of every artboard with an opaque backdrop.

    `rive --screenshot` always renders on an opaque black backdrop, which makes
    a side-by-side against a transparent SVG useless. The shipping artboards
    stay transparent; this copy exists only so design review can see the art on
    a real surface. It is a separate project, so ids need no remapping.
    """
    os.makedirs(os.path.join(out_dir, "artboards"), exist_ok=True)
    for f in sorted(os.listdir(os.path.join(OUT, "artboards"))):
        if not f.endswith(".rml"):
            continue
        xml = open(os.path.join(OUT, "artboards", f)).read()
        xml = xml.replace(
            "        <LayoutComponentStyle",
            f'        <Fill name="Background">'
            f'<SolidColor colorValue="{bg}" name="C"/></Fill>\n'
            f'        <LayoutComponentStyle', 1)
        with open(os.path.join(out_dir, "artboards", f), "w") as fh:
            fh.write(xml)
    with open(os.path.join(out_dir, "rive.yaml"), "w") as fh:
        fh.write("name: pip-preview\nmain: PipFledgling\n")
    return out_dir


def main():
    os.makedirs(os.path.join(OUT, "artboards"), exist_ok=True)
    for old in os.listdir(os.path.join(OUT, "artboards")):
        if old.endswith(".rml"):
            os.remove(os.path.join(OUT, "artboards", old))

    for cfg in STAGES:
        use_namespace(cfg["ns"])
        xml = build_stage(cfg)
        path = os.path.join(OUT, "artboards", f"{cfg['file']}.rml")
        with open(path, "w") as fh:
            fh.write(xml + "\n")
        print(f"  {cfg['file']:>10}  {len(xml):>6} bytes  -> {path}")

    use_namespace(5)
    xml = jar()
    path = os.path.join(OUT, "artboards", "jar.rml")
    with open(path, "w") as fh:
        fh.write(xml + "\n")
    print(f"  {'jar':>10}  {len(xml):>6} bytes  -> {path}")

    use_namespace(6)
    xml = build_pipstage()
    path = os.path.join(OUT, "artboards", "pipstage.rml")
    with open(path, "w") as fh:
        fh.write(xml + "\n")
    print(f"  {'pipstage':>10}  {len(xml):>6} bytes  -> {path}")

    # The old hand-written stage-3 scene is superseded.
    legacy = os.path.join(OUT, "scene.rml")
    if os.path.exists(legacy):
        os.remove(legacy)
        print("  removed legacy scene.rml")

    with open(os.path.join(OUT, "rive.yaml"), "w") as fh:
        fh.write("name: pip\nmain: PipFledgling\n"
                 "build:\n  directory: build\nlogs:\n  file: build/rive.log\n"
                 "  problems: build/problems.log\n")




# ---------------------------------------------------------------- PipStage
# Pip standing IN the nest, composed in Rive so the layering is one file and
# one draw order instead of three stacked Flutter widgets.
#
# Scene space is 350 x 260. nest.svg's own 240 x 240 space is mapped into it
# with NEST_S/NEST_D, so the nest body lands 200 wide and centred, and Pip is
# wrapped in a Node that scales his 240-space rig down to PIP_S and places his
# feet on the front-rim split line.
STAGE_W, STAGE_H = 350, 260
NEST_S = 200 / 196          # nest body is 196 wide in its own viewBox
NEST_DX = 175 - 120 * NEST_S
NEST_DY = 192 - 202 * NEST_S
# Nest landmarks in scene space. nest.svg's bowl spans y 98..202, so NEST_DY
# (which lands 202 on the baseline) is the bowl's BOTTOM, not its top.
NEST_TOP = NEST_DY + 98 * NEST_S
NEST_BOT = NEST_DY + 202 * NEST_S
NEST_H = NEST_BOT - NEST_TOP

# How far down the bowl the back/front split sits, as a fraction of the bowl's
# height. The bowl's outer rim starts at ~41% of nest height, so a split at
# 55% keeps the whole back rim in the back half and the front rim in the
# front half: the halves join seamlessly behind Pip instead of reading as a
# hat above and a plate below.
SPLIT_FRAC = 0.55
SPLIT_Y = NEST_TOP + SPLIT_FRAC * NEST_H

# How far down the bowl Pip's feet sit, as a fraction of the bowl's height.
# On the cushion dome, just above the front-rim split, so the feet rest
# visibly ON the cushion (like K03) and the front rim passes just below them.
FEET_FRAC = 0.40
FEET_Y = NEST_TOP + FEET_FRAC * NEST_H

# Pip's VISIBLE height in the scene, crest to feet. Not the 240 box: every
# stage SVG carries a different amount of transparent margin around it, so a
# shared box scale would make the egg as tall as the songbird. Scaling each
# rig by its own art box keeps one constant across all four stages.
PIP_VISIBLE_H = 130


def art_bbox(cfg):
    """(x0, x1, y0, y1) of a stage's visible art in its own 240-space, with the
    SVG's baked ground shadow left out - the nest casts the one shadow in this
    composition, so Pip must not bring his own."""
    prims, _vb = S.collect(os.path.join(SVG_DIR, cfg["svg"]))
    raw = NAMES[cfg["svg"]]
    acc = []
    for i, prim in enumerate(prims):
        nm = raw[i]
        if (nm if isinstance(nm, str) else nm[0]) == "shadow":
            continue
        el = prim["el"]
        tag = el.tag.split("}")[-1]
        if tag == "ellipse":
            cx, cy = float(el.attrib["cx"]), float(el.attrib["cy"])
            rx, ry = float(el.attrib["rx"]), float(el.attrib["ry"])
            acc += [(cx - rx, cy - ry), (cx + rx, cy + ry)]
        elif tag == "rect":
            x, y = float(el.attrib["x"]), float(el.attrib["y"])
            w, h = float(el.attrib["width"]), float(el.attrib["height"])
            acc += [(x, y), (x + w, y + h)]
        elif tag == "path":
            acc += [(px, py) for (px, py, _i, _o)
                    in S.flatten(S.parse_path(el.attrib["d"]))]
    xs = [p[0] for p in acc]
    ys = [p[1] for p in acc]
    return min(xs), max(xs), min(ys), max(ys)


def pip_placement(cfg):
    """Scale + offset that put this rig's visible art at PIP_VISIBLE_H tall,
    horizontally centred on the nest, with its feet on FEET_Y."""
    x0, x1, y0, y1 = art_bbox(cfg)
    sc = PIP_VISIBLE_H / (y1 - y0)
    return sc, STAGE_W / 2 - (x0 + x1) / 2 * sc, FEET_Y - y1 * sc

# Ids must be unique document-wide, so every block PipStage needs gets its own
# range inside namespace 6. The stage rigs themselves live in namespaces 31-34.
NEST_MASK_FRONT = 650
NEST_MASK_BACK = 651
# 4 ids per SVG element: enough for its contours plus slack.
NEST_BACK = {i: 610 + i * 4 for i in range(7)}
NEST_FRONT = {i: 710 + i * 4 for i in range(7)}
STAGE_NODE = {n: 2010 + (n - 1) * 10 for n in (1, 2, 3, 4)}
RIG_NS = {n: 30 + n for n in (1, 2, 3, 4)}
SM_PIPSTAGE = sid(1)
PS_STAGE_LAYER = 2
PS_MOOD_LAYER = {n: 40 + n for n in (1, 2, 3, 4)}
PS_STAGE_STATE = {n: 20 + n for n in (1, 2, 3, 4)}
PS_STAGE_ANIM = {n: 30 + n for n in (1, 2, 3, 4)}
PS_MOOD_STATE = {n: [1100 + (n - 1) * 10 + k for k in range(4)]
                 for n in (1, 2, 3, 4)}
PS_MOOD_ANIM = {n: [1200 + (n - 1) * 10 + k for k in range(4)]
                for n in (1, 2, 3, 4)}


def _nest_svg():
    return S.collect(os.path.join(SVG_DIR, "nest.svg"))


def build_pipstage():
    prims, vb = _nest_svg()
    body = ['<Rive version="1" kind="fragment">']
    body.append(f'    <Artboard name="PipStage" x="1600" y="0" '
                f'width="{STAGE_W}" height="{STAGE_H}" '
                f'defaultStateMachineId="{sid(1)}" '
                f'viewModelId="{VM}" viewModelInstanceId="{VMI}" '
                f'styleId="{sid(999)}" id="{sid(998)}">')
    body.append(f'        <LayoutComponentStyle name="Artboard Style" '
                f'id="{sid(999)}"/>')
    body.append("")

    names = [f"nest_{i}" for i in range(len(prims))]

    def nest_shape(i, origin, ind, clip_to=None):
        """One Shape per CONTOUR. nest.svg's twig path carries three strokes in
        one element, and a Rive Shape has a single path.

        Front and back are the SAME geometry (same prims, same NEST_S/DX/DY
        transform, same x/y): only the clip mask differs, so the halves can
        never drift apart."""
        prim = prims[i]
        parts = geometry(prim, origin, ind, names[i],
                         xf=(NEST_S, NEST_DX, NEST_DY))
        base = NEST_FRONT[i] if clip_to == "front" else NEST_BACK[i]
        pad = " " * ind
        rows = []
        for k, (p, ang, geom) in enumerate(parts):
            name = names[i] if k == 0 else f"{names[i]}_{k}"
            rows.append(f'{pad}<Shape x="{S.num(p[0]-origin[0])}" '
                        f'y="{S.num(p[1]-origin[1])}" name="{name}" '
                        f'id="{sid(base + k)}">')
            rows += geom
            rows += paints(prim["style"], prim["opacity"], ind, NEST_S)
            if clip_to is not None:
                mask = (NEST_MASK_FRONT if clip_to == "front"
                        else NEST_MASK_BACK)
                rows.append(f'{pad}  <ClippingShape sourceId="{sid(mask)}" '
                            f'name="Clip"/>')
            rows.append(f"{pad}</Shape>")
        return rows

    # ---- draw order is front-to-back -------------------------------
    #  1. nest FRONT rim, masked to below the split, so it bites Pip's feet
    #  2. the four stage rigs; one state-machine layer each, and a stage
    #     layer that shows exactly the one `stage` selects
    #  3. nest BACK, masked to above the split
    #  4. the single soft ground shadow under the nest
    for i in reversed(range(1, len(prims))):  # skip 0: the nest's own shadow
        body += nest_shape(i, (0, 0), 8, clip_to="front")

    for cfg in STAGES:
        n = cfg["stage"]
        psc, pdx, pdy = pip_placement(cfg)
        use_namespace(6)          # the wrapper node id lives in the machine's
        body.append(f'        <Node x="{S.num(pdx)}" y="{S.num(pdy)}" '
                    f'scaleX="{S.num(psc)}" scaleY="{S.num(psc)}" '
                    f'name="pip_stage_{n}" id="{sid(STAGE_NODE[n])}">')
        use_namespace(RIG_NS[n])   # the rig's own shapes get their own block
        lines, _ = rig(cfg, 12, skip_shadow=True)
        body += lines
        body.append("        </Node>")
    use_namespace(6)

    for i in reversed(range(1, len(prims))):
        body += nest_shape(i, (0, 0), 8, clip_to="back")

    body += nest_shape(0, (0, 0), 8)        # the one ground shadow
    body.append("")

    # ---- the masks: back keeps everything above the split, front keeps
    #      everything below it. Both are full-width scene rects, so the two
    #      nest halves tile exactly with no seam and no overlap.
    body.append(f'        <Shape x="{S.num(STAGE_W / 2)}" '
                f'y="{S.num(SPLIT_Y / 2)}" name="back_mask" '
                f'id="{sid(NEST_MASK_BACK)}">')
    body.append(f'            <Rectangle width="{STAGE_W}" '
                f'height="{S.num(SPLIT_Y)}" cornerRadiusTL="0" '
                f'linkCornerRadius="true" name="P"/>')
    body.append("        </Shape>")
    body.append(f'        <Shape x="{S.num(STAGE_W / 2)}" '
                f'y="{S.num((SPLIT_Y + STAGE_H) / 2)}" name="front_mask" '
                f'id="{sid(NEST_MASK_FRONT)}">')
    body.append(f'            <Rectangle width="{STAGE_W}" '
                f'height="{S.num(STAGE_H - SPLIT_Y)}" cornerRadiusTL="0" '
                f'linkCornerRadius="true" name="P"/>')
    body.append("        </Shape>")
    body.append("")

    body += pipstage_machine()
    body.append("")
    body += pipstage_animations()
    body.append("    </Artboard>")
    body.append("")
    body += view_model(STAGES[2])
    body.append("</Rive>")
    return "\n".join(body)


def _vm_cond(dest, prop, duration, value, ind=P):
    return [
        f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}">',
        f'{ind}    <TransitionViewModelCondition opValue="equal">',
        f'{ind}      <TransitionPropertyViewModelComparator>',
        f'{ind}        <BindablePropertyNumber>',
        f'{ind}          <DataBindContext sourcePathIds="{VM}-{prop}" '
        f'propertyKey="636"/>',
        f'{ind}        </BindablePropertyNumber>',
        f'{ind}      </TransitionPropertyViewModelComparator>',
        f'{ind}      <TransitionValueNumberComparator value="{value}"/>',
        f'{ind}    </TransitionViewModelCondition>',
        f'{ind}  </StateTransition>',
    ]


def _trigger_cond(dest, prop, duration, ind=P):
    return [
        f'{ind}  <StateTransition stateToId="{dest}" duration="{duration}">',
        f'{ind}    <TransitionViewModelCondition opValue="equal">',
        f'{ind}      <TransitionPropertyViewModelComparator>',
        f'{ind}        <BindablePropertyTrigger>',
        f'{ind}          <DataBindContext sourcePathIds="{VM}-{prop}" '
        f'propertyKey="686"/>',
        f'{ind}        </BindablePropertyTrigger>',
        f'{ind}      </TransitionPropertyViewModelComparator>',
        f'{ind}      <TransitionValueTriggerComparator value="1"/>',
        f'{ind}    </TransitionViewModelCondition>',
        f'{ind}  </StateTransition>',
    ]


def pipstage_machine():
    """One mood layer per stage, plus a stage layer that shows exactly the rig
    `stage` selects. Layers run independently, so a layer for a stage that is
    not the selected one simply never leaves its rest state."""
    r = [f'{P}<StateMachine name="Pip" id="{sid(1)}">']

    # ---- the stage layer: which rig is visible ------------------------
    r += [f'{P}  <StateMachineLayer name="Stage" id="{sid(PS_STAGE_LAYER)}">',
          f'{P}    <AnyState x="560" y="-120"/>',
          f'{P}    <ExitState x="760" y="-120"/>',
          f'{P}    <EntryState x="40" y="-120">',
          f'{P}      <StateTransition stateToId="{sid(PS_STAGE_STATE[1])}" '
          f'duration="0"/>',
          f'{P}    </EntryState>']
    for n in (1, 2, 3, 4):
        # One state per stage value, and every state carries a transition to
        # every state (itself included: the self-transition is what blends the
        # rigs in and out). A state with no outgoing transition can never be
        # left, which is how all four stages once rendered the entry rig.
        r.append(f'{P}    <AnimationState x="{120 * n}" y="-120" '
                 f'animationId="{sid(PS_STAGE_ANIM[n])}" '
                 f'id="{sid(PS_STAGE_STATE[n])}">')
        for m in (1, 2, 3, 4):
            r += _vm_cond(sid(PS_STAGE_STATE[m]), P_STAGE, 120, m, P + "  ")
        r.append(f'{P}    </AnimationState>')
    r.append(f"{P}  </StateMachineLayer>")

    # ---- one mood layer per stage -------------------------------------
    for n in (1, 2, 3, 4):
        st = [sid(i) for i in PS_MOOD_STATE[n]]
        an = [sid(i) for i in PS_MOOD_ANIM[n]]
        r += [f'{P}  <StateMachineLayer name="Mood{n}" '
              f'id="{sid(PS_MOOD_LAYER[n])}">',
              f'{P}    <AnyState x="560" y="-120"/>',
              f'{P}    <ExitState x="760" y="-120"/>',
              f'{P}    <EntryState x="40" y="-120">',
              f'{P}      <StateTransition stateToId="{st[0]}" duration="0"/>',
              f'{P}    </EntryState>',
              f'{P}    <AnimationState x="160" y="-120" animationId="{an[0]}" '
              f'id="{st[0]}">']
        r += _vm_cond(st[1], P_MOOD, 120, 1, P + "  ")
        r += _vm_cond(st[2], P_MOOD, 120, 2, P + "  ")
        r += _trigger_cond(st[3], P_EVOLVE, 100, P + "  ")
        r.append(f'{P}    </AnimationState>')
        for s_i, a_i, blend, sx, sy in ((1, 1, 220, 360, -40),
                                        (2, 2, 220, 560, -40),
                                        (3, 3, 300, 460, 60)):
            r += [f'{P}    <AnimationState x="{sx}" y="{sy}" '
                  f'animationId="{an[a_i]}" id="{st[s_i]}">',
                  f'{P}      <StateTransition stateToId="{st[0]}" '
                  f'duration="{blend}" enableExitTime="true" '
                  f'exitTimeIsPercetange="true" exitTime="100"/>',
                  f'{P}    </AnimationState>']
        r.append(f"{P}  </StateMachineLayer>")
    r.append(f"{P}</StateMachine>")
    return r


def pipstage_animations():
    """Every timeline PipStage needs: one mood set per stage rig, plus the
    stage-visibility set. The mood sets are the standalone rig's own four
    timelines, re-emitted in that rig's id namespace so their keyframes still
    point at the right shapes."""
    out = []
    for n in (1, 2, 3, 4):
        use_namespace(6)              # the timeline ids belong to the machine
        aids = [sid(i) for i in PS_MOOD_ANIM[n]]
        use_namespace(RIG_NS[n])      # the keyframes belong to the rig
        out += animations(STAGES[n - 1], aids)
        out.append("")
    use_namespace(6)

    # stage visibility: hold the selected rig at 1 and the others at 0
    for n in (1, 2, 3, 4):
        out.append(f'{P}<LinearAnimation name="stage_{n}" duration="1" fps="60" '
                   f'loopValue="loop" id="{sid(PS_STAGE_ANIM[n])}">')
        for m in (1, 2, 3, 4):
            out += _keyed(sid(STAGE_NODE[m]), 18,
                          [(1 if m == n else 0, None, "hold")], P + "  ")
        out.append(f"{P}</LinearAnimation>")
        out.append("")
    return out


if __name__ == "__main__":
    main()
