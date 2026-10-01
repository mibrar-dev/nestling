#!/usr/bin/env python3
"""Storybook C pose library generator — 100% original art, contract-compliant ids.
Style: pear body, wispy tuft, feather lines, 5px ink, one soft highlight, no gradients/text.
Canvas 240, baseline y=214, shadow (120,214)."""
import os, math

ROOT = "/Users/ibrar/Desktop/infinora.noworkspace/nestling-pip-v2"
C = os.path.join(ROOT, "design/pip-v2/C")
POSES = os.path.join(C, "poses"); SKINS=os.path.join(C,"skins"); ACC=os.path.join(C,"accessories"); EVO=os.path.join(C,"evolve")
for d in (POSES,SKINS,ACC,EVO): os.makedirs(d,exist_ok=True)

INK="#1E1B3A"; SW=5
PEACH="#FF8A5B"; PURPLE="#7C6CF2"; GOLD="#F4B400"; SEEDC="#8A5A2B"; DARKMOUTH="#1E1B3A"

SKINMAP={
 "sunny": dict(body="#FFD93D",belly="#FFF1B8",wing="#F2A900",shade="#B97E00"),
 "berry": dict(body="#FF9EBB",belly="#FFE1EA",wing="#E56B8C",shade="#A83A5C"),
 "sky":   dict(body="#8EC9FF",belly="#E2F1FF",wing="#5A9AE6",shade="#2F5FA3"),
 "mint":  dict(body="#8EE3B5",belly="#DDF8E8",wing="#4FBF84",shade="#2A7A52"),
}

def star4(cx,cy,r,fill,opacity=1.0,stroke=None,sw=3):
    p=f"M{cx} {cy-r} Q{cx+r*0.18} {cy-r*0.18} {cx+r} {cy} Q{cx+r*0.18} {cy+r*0.18} {cx} {cy+r} Q{cx-r*0.18} {cy+r*0.18} {cx-r} {cy} Q{cx-r*0.18} {cy-r*0.18} {cx} {cy-r} Z"
    s=f' stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"' if stroke else ""
    return f'<path d="{p}" fill="{fill}" opacity="{opacity}"{s}/>'

def dot(cx,cy,r,fill,op=1.0,stroke=None):
    s=f' stroke="{INK}" stroke-width="3" ' if stroke else ""
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" opacity="{op}"{s}/>'

def zzz(x,y,s,color=PURPLE,op=1.0,w=5):
    # Z as polyline shape (no text): horizontal-diagonal-horizontal
    return (f'<path d="M{x} {y} L{x+s} {y} L{x} {y+s*0.72} L{x+s} {y+s*0.72}" fill="none" '
            f'stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" opacity="{op}"/>')

def excl(x,y,s,color=PURPLE):
    # "!" drawn as shapes: rounded bar + dot, ink outline
    w=s*0.34
    bar=(f'<rect x="{x-w/2}" y="{y}" width="{w}" height="{s}" rx="{w/2}" fill="{color}" stroke="{INK}" stroke-width="4"/>')
    d=(f'<circle cx="{x}" cy="{y+s+16}" r="{w*0.72}" fill="{color}" stroke="{INK}" stroke-width="4"/>')
    return bar+d

def seed(x,y,s=1.0):
    return (f'<g><ellipse cx="{x}" cy="{y}" rx="{9*s}" ry="{12*s}" fill="{SEEDC}" stroke="{INK}" stroke-width="4"/>'
            f'<ellipse cx="{x-3*s}" cy="{y-4*s}" rx="{2.6*s}" ry="{4*s}" fill="#FFFFFF" opacity="0.55"/></g>')

def crumb(x,y,r,fill="#C98A3D"):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{INK}" stroke-width="3"/>'

def heart(x,y,s,fill=PEACH):
    return (f'<path d="M{x} {y+s*0.9} C{x-s*1.2} {y} {x-s*0.5} {y-s*0.9} {x} {y-s*0.2} '
            f'C{x+s*0.5} {y-s*0.9} {x+s*1.2} {y} {x} {y+s*0.9} Z" fill="{fill}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>')

# ---------- eyes ----------
def eye_sub(mode,cx,cy,r,dx=0,dy=0):
    """Return inner svg for one eye mode."""
    if mode=="open":
        return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#FFFFFF" stroke="{INK}" stroke-width="{SW}"/>'
                f'<circle cx="{cx+dx}" cy="{cy+dy}" r="{r*0.46}" fill="{INK}"/>'
                f'<circle cx="{cx+dx-r*0.2}" cy="{cy+dy-r*0.28}" r="{r*0.17}" fill="#FFFFFF"/>')
    if mode=="surprised":
        rr=r*1.28
        return (f'<circle cx="{cx}" cy="{cy}" r="{rr}" fill="#FFFFFF" stroke="{INK}" stroke-width="{SW}"/>'
                f'<circle cx="{cx+dx*0.4}" cy="{cy+dy*0.4}" r="{r*0.34}" fill="{INK}"/>'
                f'<circle cx="{cx+dx*0.4-r*0.12}" cy="{cy+dy*0.4-r*0.14}" r="{r*0.13}" fill="#FFFFFF"/>')
    if mode=="closed":
        return (f'<path d="M{cx-r} {cy} Q{cx} {cy+9} {cx+r} {cy}" fill="none" stroke="{INK}" stroke-width="{SW}" stroke-linecap="round"/>')
    if mode=="happy":
        return (f'<path d="M{cx-r} {cy+5} Q{cx} {cy-r-2} {cx+r} {cy+5}" fill="none" stroke="{INK}" stroke-width="{SW}" stroke-linecap="round"/>')
    if mode=="sleepy":
        return (f'<path d="M{cx-r} {cy-2} Q{cx} {cy+6} {cx+r} {cy-2}" fill="none" stroke="{INK}" stroke-width="{SW}" stroke-linecap="round"/>'
                f'<path d="M{cx-r+3} {cy+7} l-5 4 M{cx+r-3} {cy+7} l5 4" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>')
    if mode=="wink":
        return (f'<path d="M{cx-r} {cy} Q{cx} {cy+10} {cx+r} {cy}" fill="none" stroke="{INK}" stroke-width="{SW}" stroke-linecap="round"/>')
    return ""

def eyes_group(mode_l,mode_r,cx_l,cy_l,cx_r,cy_r,r,dx_l=2,dy_l=2,dx_r=2,dy_r=2):
    out=[]
    for side,mode,cx,cy,dx,dy in (("eye_l",mode_l,cx_l,cy_l,dx_l,dy_l),("eye_r",mode_r,cx_r,cy_r,dx_r,dy_r)):
        subs=[]
        for m in ("open","closed","happy","sleepy","surprised","wink"):
            inner = eye_sub(m,cx,cy,r,dx,dy) if m==mode else ""
            subs.append(f'<g id="{m}">{inner}</g>')
        out.append(f'<g id="{side}">'+"".join(subs)+"</g>")
    return "".join(out)

# ---------- beaks ----------
def beak_closed(cx,cy,w=28,smile=True):
    top=(f'<path d="M{cx-w/2} {cy} Q{cx} {cy-5} {cx+w/2} {cy} Q{cx+w/2-4} {cy+11} {cx} {cy+13} Q{cx-w/2+4} {cy+11} {cx-w/2} {cy} Z" '
         f'fill="{PEACH}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>')
    return top,""
def beak_open_happy(cx,cy,w=32):
    top=(f'<path d="M{cx-w/2} {cy} Q{cx} {cy-6} {cx+w/2} {cy} L{cx+w/2-5} {cy+5} L{cx-w/2+5} {cy+5} Z" fill="{PEACH}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>')
    bot=(f'<ellipse cx="{cx}" cy="{cy+14}" rx="13" ry="10" fill="{DARKMOUTH}" stroke="{INK}" stroke-width="4"/>'
         f'<ellipse cx="{cx}" cy="{cy+18}" rx="6.5" ry="4" fill="{PEACH}"/>')
    return top,bot
def beak_o(cx,cy,r=11):
    top=(f'<ellipse cx="{cx}" cy="{cy}" rx="{r}" ry="{r+2}" fill="{DARKMOUTH}" stroke="{INK}" stroke-width="{SW}"/>'
         f'<ellipse cx="{cx}" cy="{cy+5}" rx="{r*0.45}" ry="{r*0.4}" fill="{PEACH}"/>')
    return top,""
def beak_peck(cx,cy,w=26):
    top=(f'<path d="M{cx-w/2} {cy-4} Q{cx} {cy-8} {cx+w/2} {cy-4} L{cx+4} {cy+10} L{cx-8} {cy+8} Z" fill="{PEACH}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>')
    bot=(f'<path d="M{cx-8} {cy+8} L{cx+4} {cy+10} L{cx} {cy+18} Z" fill="{DARKMOUTH}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>')
    return top,bot

# ---------- wings / tuft / tail ----------
def wing(side,cx,cy,rx,ry,rot,wingfill,feather=True,op=1.0):
    f=(f'<path d="M{cx} {cy-ry+6} L{cx} {cy+ry-6}" stroke="{INK}" stroke-width="3" stroke-linecap="round" opacity="0.55"/>' if feather else "")
    return (f'<g id="wing_{"l" if side=="L" else "r"}" opacity="{op}"><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" '
            f'fill="{wingfill}" stroke="{INK}" stroke-width="{SW}" transform="rotate({rot} {cx} {cy})"/>{f}</g>')

def tuft(variant,bodyfill,dx=0):
    # three wispy feathers; variants: normal, up, droop, sway_r, sway_l, flat, tall
    base=[
      (106,70,100,46,112,38,118,50,116,68),
      (120,68,120,42,132,34,138,48,132,68),
      (132,70,142,52,152,50,150,62,142,72),
    ]
    if variant=="up":
        base=[(106,70,96,40,110,30,118,46,116,68),(120,68,120,34,134,26,140,44,132,68),(134,70,146,46,158,44,154,60,144,72)]
    elif variant=="tall":
        base=[(106,70,94,36,110,26,118,44,116,68),(120,68,120,30,134,22,140,40,132,68),(134,70,148,42,160,40,156,58,144,72)]
    elif variant=="droop":
        base=[(106,70,88,60,96,50,108,58,114,70),(120,68,112,52,126,46,132,58,130,70),(132,70,142,60,152,60,148,68,140,73)]
    elif variant=="flat":
        base=[(106,70,96,58,108,52,116,60,116,68),(120,68,118,56,130,52,134,60,132,68),(132,70,140,60,150,60,146,66,142,72)]
    elif variant in ("sway_r","sway_l"):
        s=6 if variant=="sway_r" else -6
        base=[(b[0]+dx,b[1],b[2]+s,b[3],b[4]+s,b[5],b[6]+s,b[7],b[8]+dx,b[9]) for b in base]
    else:
        base=[(b[0]+dx,b[1],b[2]+dx,b[3],b[4]+dx,b[5],b[6]+dx,b[7],b[8]+dx,b[9]) for b in base]
    ps=[]
    for (x0,y0,x1,y1,x2,y2,x3,y3,x4,y4) in base:
        ps.append(f'<path d="M{x0} {y0} Q{x1} {y1} {x2} {y2} Q{x3} {y3} {x4} {y4} Z" fill="{bodyfill}"/>')
    return (f'<g id="head_tuft" stroke="{INK}" stroke-width="{SW}" stroke-linecap="round" stroke-linejoin="round">{"".join(ps)}</g>')

def tail_s3(cx=120,y=186,fill=GOLD,lift=0):
    return (f'<g id="tail" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">'
            f'<path d="M108 {y+lift} L112 {202+lift} L120 {194+lift} L128 {202+lift} L132 {y+lift} Z" fill="{fill}"/></g>')

def tail_s4(y=172,fill=GOLD,spread=0,lift=0):
    s=spread
    return (f'<g id="tail" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">'
            f'<path d="M{92-s} {y} Q{84-s} {198+lift} {94-s} {208+lift} Q{104-s} {202+lift} {104-s} {174} Z" fill="{fill}"/>'
            f'<path d="M112 {y+4+lift} Q110 {204+lift} 120 {210+lift} Q130 {204+lift} 128 {y+4+lift} Z" fill="{fill}"/>'
            f'<path d="M{132+s} {174+lift} Q{138+s} {198+lift} {148+s} {202+lift} Q{152+s} {192+lift} {140+s} {y+lift} Z" fill="{fill}"/></g>')

def cheeks(cx_l,cy,cx_r,puff=0):
    rx=9+puff; ry=6+puff*0.6
    return (f'<g id="cheek_l"><ellipse cx="{cx_l}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{PEACH}" opacity="0.5"/></g>'
            f'<g id="cheek_r"><ellipse cx="{cx_r}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{PEACH}" opacity="0.5"/></g>')

def brows(mode,cx_l,cy,cx_r):
    if mode=="surprised":
        return (f'<g id="brow_l"><path d="M{cx_l-14} {cy-6} L{cx_l+12} {cy-12}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/></g>'
                f'<g id="brow_r"><path d="M{cx_r-12} {cy-12} L{cx_r+14} {cy-6}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/></g>')
    if mode=="proud":
        return (f'<g id="brow_l"><path d="M{cx_l-12} {cy-4} L{cx_l+12} {cy-8}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/></g>'
                f'<g id="brow_r"><path d="M{cx_r-12} {cy-8} L{cx_r+12} {cy-4}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/></g>')
    if mode=="sleepy":
        return (f'<g id="brow_l"><path d="M{cx_l-12} {cy} L{cx_l+12} {cy+2}" stroke="{INK}" stroke-width="4" stroke-linecap="round" opacity="0.6"/></g>'
                f'<g id="brow_r"><path d="M{cx_r-12} {cy+2} L{cx_r+12} {cy}" stroke="{INK}" stroke-width="4" stroke-linecap="round" opacity="0.6"/></g>')
    return '<g id="brow_l"></g><g id="brow_r"></g>'

def shadow(rx=62,op=0.12,cx=120):
    return f'<g id="shadow"><ellipse cx="{cx}" cy="214" rx="{rx}" ry="11" fill="{INK}" opacity="{op}"/></g>'

def highlight(cx,cy,rx=17,ry=10,rot=-18,op=0.55):
    return f'<g id="highlight"><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#FFFFFF" opacity="{op}" transform="rotate({rot} {cx} {cy})"/></g>'

def acc_shapes(kind,stage,skin):
    """Return (head,neck,face) inner strings."""
    head=neck=face=""
    if kind=="bow":
        y = 58 if stage in (3,4) else (78 if stage==2 else 0)
        if stage==1:
            head=(f'<g><path d="M150 46 L178 34 L172 62 Z" fill="#FF6B8A" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<path d="M150 46 L178 58 L172 30 Z" fill="#FF6B8A" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round" opacity="0"/>'
                  f'<path d="M152 44 L180 36 L174 64 Z" fill="#FF6B8A" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<circle cx="150" cy="50" r="8" fill="#E5456B" stroke="{INK}" stroke-width="4.5"/></g>')
            # simpler bow on egg top-right
            head=(f'<path d="M148 52 L172 38 L168 66 Z" fill="#FF6B8A" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<path d="M148 52 L126 40 L130 66 Z" fill="#FF8FAB" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<circle cx="148" cy="53" r="8" fill="#E5456B" stroke="{INK}" stroke-width="4.5"/>')
        elif stage==2:
            head=(f'<path d="M140 74 L162 62 L158 88 Z" fill="#FF6B8A" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<path d="M140 74 L120 64 L124 88 Z" fill="#FF8FAB" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<circle cx="140" cy="75" r="7.5" fill="#E5456B" stroke="{INK}" stroke-width="4.5"/>')
        else:
            head=(f'<path d="M148 60 L174 44 L169 76 Z" fill="#FF6B8A" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<path d="M148 60 L124 46 L129 76 Z" fill="#FF8FAB" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<circle cx="148" cy="61" r="8" fill="#E5456B" stroke="{INK}" stroke-width="4.5"/>')
    elif kind=="cap":
        if stage==1:
            head=(f'<path d="M78 108 Q120 84 162 108 L158 118 Q120 98 82 118 Z" fill="#5A9AE6" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<ellipse cx="120" cy="92" rx="30" ry="14" fill="#5A9AE6" stroke="{INK}" stroke-width="4.5"/>'
                  f'<circle cx="120" cy="80" r="6" fill="#FFD93D" stroke="{INK}" stroke-width="4"/>')
        elif stage==2:
            head=(f'<path d="M84 92 Q120 62 156 92 L156 100 Q120 78 84 100 Z" fill="#5A9AE6" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<ellipse cx="120" cy="78" rx="26" ry="12" fill="#5A9AE6" stroke="{INK}" stroke-width="4.5"/>'
                  f'<circle cx="120" cy="68" r="5.5" fill="#FFD93D" stroke="{INK}" stroke-width="4"/>')
        else:
            head=(f'<path d="M82 84 Q122 50 162 84 L160 94 Q122 66 84 94 Z" fill="#5A9AE6" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<ellipse cx="122" cy="66" rx="28" ry="13" fill="#5A9AE6" stroke="{INK}" stroke-width="4.5"/>'
                  f'<circle cx="122" cy="55" r="6" fill="#FFD93D" stroke="{INK}" stroke-width="4"/>')
    elif kind=="scarf":
        if stage==1:
            neck=(f'<path d="M70 150 Q120 168 170 150 L168 166 Q120 184 72 166 Z" fill="#4FBF84" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<rect x="132" y="160" width="22" height="30" rx="9" fill="#3AA76D" stroke="{INK}" stroke-width="4.5"/>')
        elif stage==2:
            neck=(f'<path d="M82 148 Q120 162 158 148 L156 162 Q120 176 84 162 Z" fill="#4FBF84" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<rect x="132" y="156" width="20" height="28" rx="9" fill="#3AA76D" stroke="{INK}" stroke-width="4.5"/>')
        else:
            neck=(f'<path d="M68 168 Q120 188 172 168 L170 184 Q120 204 70 184 Z" fill="#4FBF84" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                  f'<rect x="134" y="178" width="24" height="32" rx="10" fill="#3AA76D" stroke="{INK}" stroke-width="4.5"/>'
                  f'<path d="M136 184 L156 184" stroke="{INK}" stroke-width="3" stroke-linecap="round" opacity="0.4"/>')
    elif kind=="glasses":
        if stage==1:
            face=(f'<g stroke="{INK}" stroke-width="4.5"><circle cx="102" cy="163" r="16" fill="#FFFFFF" opacity="0.35"/><circle cx="138" cy="163" r="16" fill="#FFFFFF" opacity="0.35"/>'
                  f'<path d="M118 163 L122 163" stroke="{INK}" stroke-width="4.5"/></g>')
        elif stage==2:
            face=(f'<g stroke="{INK}" stroke-width="4"><circle cx="106" cy="120" r="17" fill="#FFFFFF" opacity="0.35"/><circle cx="134" cy="120" r="17" fill="#FFFFFF" opacity="0.35"/>'
                  f'<path d="M123 120 L121 120" stroke="{INK}" stroke-width="4"/><path d="M89 118 L80 114 M151 118 L160 114" stroke="{INK}" stroke-width="4" stroke-linecap="round"/></g>')
        else:
            face=(f'<g stroke="{INK}" stroke-width="4.5"><circle cx="96" cy="130" r="21" fill="#FFFFFF" opacity="0.32"/><circle cx="144" cy="130" r="21" fill="#FFFFFF" opacity="0.32"/>'
                  f'<path d="M117 130 Q120 128 123 130" fill="none" stroke="{INK}" stroke-width="4.5"/>'
                  f'<path d="M75 128 L64 122 M165 128 L176 122" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/></g>')
    return head,neck,face

# ================= STAGE RENDERERS =================
def svg_wrap(label,inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" role="img" aria-label="{label}">'
            f'{"".join(inner)}</svg>')

def render_bird(stage,mood_idx,skin="sunny",acc="none",fx_extra="",label="pip C"):
    S=SKINMAP[skin]; body=S["body"]; belly=S["belly"]; wingf=S["wing"]; shade=S["shade"]
    # stage geometry
    if stage==2:
        bcx,bcy,br=120,122,42
        bellypos=(120,138,24,20); ey=(106,120,134,120,11); beakc=(120,136); cheeky=140; cheekx=(88,152)
        feetpos=(99,141,186); wingbase=(82,128,10,16,0,158,128,10,16,0); tufty=0
        tail=""  # s2 no tail -> empty group
        body_ellipse=f'<ellipse cx="{bcx}" cy="{bcy}" rx="{br}" ry="{br}" fill="{body}" stroke="{INK}" stroke-width="{SW}"/>'
        belly_svg=f'<ellipse cx="{bellypos[0]}" cy="{bellypos[1]}" rx="{bellypos[2]}" ry="{bellypos[3]}" fill="{belly}"/>'
        feet_svg=(f'<g id="feet" stroke="{INK}" stroke-width="{SW}"><ellipse cx="99" cy="186" rx="11" ry="7" fill="{PEACH}"/>'
                  f'<ellipse cx="141" cy="186" rx="11" ry="7" fill="{PEACH}"/></g>')
        shell_bot=(f'<g id="shell_bottom" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">'
                   f'<path d="M56 148 L72 160 L86 148 L102 162 L118 149 L134 163 L150 149 L164 162 L180 150 L184 148 L176 196 Q120 208 64 196 Z" fill="#FFF8E8"/>'
                   f'<circle cx="92" cy="180" r="5" fill="{PURPLE}"/><circle cx="140" cy="184" r="4.5" fill="{PURPLE}"/></g>')
        shell_top=(f'<g id="shell_top" stroke="{INK}" stroke-width="4" stroke-linejoin="round">'
                   f'<path d="M104 82 L114 70 L124 80 L134 70" fill="#FFF8E8"/></g>')
        # placeholder positions overridden per mood below via params dict
        P=dict(bcy=bcy,rx=br,ry=br,ey_l=(106,120),ey_r=(134,120),er=11,beak=(120,136),
               wingl=(82,128,10,16,0),wingr=(158,128,10,16,0),tuft="normal",belly=(120,138,24,20),
               feet_y=186,shadow_rx=58,eye_mode=("open","open"),beak_mode="closed",puff=0,
               hl=(102,106,12,7),brows="none",pdx=(2,2),pdy=(2,2))
    elif stage==3:
        P=dict(bcy=133,rx=60,ry=61,ey_l=(96,130),ey_r=(144,130),er=15,beak=(120,150),
               wingl=(62,144,16,25,0),wingr=(178,144,16,25,0),tuft="normal",belly=(120,158,37,31),
               feet_y=196,shadow_rx=62,eye_mode=("open","open"),beak_mode="closed",puff=0,
               hl=(96,102,17,10),brows="none",pdx=(2,2),pdy=(2,2))
        body_ellipse=None; belly_svg=None; feet_svg=None; shell_bot='<g id="shell_bottom"></g>'; shell_top='<g id="shell_top"></g>'; tail=None
    else: # stage 4
        P=dict(bcy=124,rx=60,ry=65,ey_l=(96,130),ey_r=(144,130),er=15,beak=(120,150),
               wingl=(60,134,17,28,0),wingr=(180,134,17,28,0),tuft="normal",belly=(120,150,39,36),
               feet_y=198,shadow_rx=64,eye_mode=("open","open"),beak_mode="closed",puff=0,
               hl=(96,94,18,10),brows="none",pdx=(2,2),pdy=(2,2))
        body_ellipse=None; belly_svg=None; feet_svg=None; shell_bot='<g id="shell_bottom"></g>'; shell_top='<g id="shell_top"></g>'; tail=None

    # ---- mood pose adjustments (keyed by mood_idx string like "happy_2") ----
    fx=""
    if mood_idx=="idle_1":
        pass
    elif mood_idx=="idle_2":
        P["ry"]+=3; P["belly"]=(P["belly"][0],P["belly"][1],P["belly"][2],P["belly"][3]+2); P["tuft"]="sway_r"
        P["ey_l"]=(P["ey_l"][0]+2,P["ey_l"][1]); P["ey_r"]=(P["ey_r"][0]+2,P["ey_r"][1]); P["beak"]=(P["beak"][0]+2,P["beak"][1])
    elif mood_idx=="blink_1":
        pass
    elif mood_idx=="blink_2":
        P["eye_mode"]=("closed","closed")
    elif mood_idx=="happy_1":
        P["ry"]-=7; P["rx"]+=7; P["bcy"]+=7; P["belly"]=(P["belly"][0],P["belly"][1]+7,P["belly"][2]+4,P["belly"][3]-4)
        P["eye_mode"]=("happy","happy"); P["tuft"]="flat"; P["shadow_rx"]+=8
        P["wingl"]=(P["wingl"][0]-4,P["wingl"][1]+8,P["wingl"][2],P["wingl"][3]-3, -12)
        P["wingr"]=(P["wingr"][0]+4,P["wingr"][1]+8,P["wingr"][2],P["wingr"][3]-3, 12)
    elif mood_idx=="happy_2":
        P["bcy"]-=20; P["belly"]=(P["belly"][0],P["belly"][1]-20,P["belly"][2],P["belly"][3])
        P["ey_l"]=(P["ey_l"][0],P["ey_l"][1]-20); P["ey_r"]=(P["ey_r"][0],P["ey_r"][1]-20)
        P["beak"]=(P["beak"][0],P["beak"][1]-20); P["eye_mode"]=("happy","happy"); P["beak_mode"]="open_happy"
        P["tuft"]="sway_r"; P["shadow_rx"]-=16
        if stage==2:
            P["wingl"]=(52,84,10,18,-32); P["wingr"]=(188,84,10,18,32)
        elif stage==3:
            P["wingl"]=(44,92,15,26,-32); P["wingr"]=(196,92,15,26,32)
        else:
            P["wingl"]=(38,86,17,30,-35); P["wingr"]=(202,86,17,30,35)
        P["feet_y"]-=14
        fx=(star4(34,60,11,PURPLE)+star4(206,60,10,GOLD,stroke=True)+dot(52,100,4,PURPLE)+dot(190,104,4,PEACH)
            +star4(120,36,7,"#FFFFFF",stroke=True))
    elif mood_idx=="happy_3":
        P["ry"]-=5; P["rx"]+=5; P["bcy"]+=5; P["belly"]=(P["belly"][0],P["belly"][1]+5,P["belly"][2]+2,P["belly"][3]-2)
        P["eye_mode"]=("happy","happy"); P["beak_mode"]="open_happy"; P["shadow_rx"]+=6
        P["wingl"]=(P["wingl"][0]-6,P["wingl"][1]+4,P["wingl"][2],P["wingl"][3],-14)
        P["wingr"]=(P["wingr"][0]+6,P["wingr"][1]+4,P["wingr"][2],P["wingr"][3],14)
        fx=star4(40,70,8,PURPLE,opacity=0.7)+star4(200,72,7,GOLD,opacity=0.7,stroke=True)
    elif mood_idx=="eating_1":
        P["eye_mode"]=("open","open"); P["pdy"]=(-4,-4)
        fx=seed(P["beak"][0],P["beak"][1]-70)+dot(P["beak"][0]-14,P["beak"][1]-48,3,PURPLE,0.8)+dot(P["beak"][0]+14,P["beak"][1]-52,3,GOLD,0.8)
    elif mood_idx=="eating_2":
        P["bcy"]+=5; P["belly"]=(P["belly"][0],P["belly"][1]+5,P["belly"][2],P["belly"][3])
        P["ey_l"]=(P["ey_l"][0],P["ey_l"][1]+5); P["ey_r"]=(P["ey_r"][0],P["ey_r"][1]+5)
        P["beak"]=(P["beak"][0],P["beak"][1]+5); P["eye_mode"]=("happy","happy"); P["beak_mode"]="peck"
        P["wingl"]=(P["wingl"][0]-6,P["wingl"][1],P["wingl"][2],P["wingl"][3],-14)
        P["wingr"]=(P["wingr"][0]+6,P["wingl"][1],P["wingr"][2],P["wingr"][3],14)
        fx=(seed(P["beak"][0]+4,P["beak"][1]-13)+crumb(P["beak"][0]-24,P["beak"][1]-6,4)+crumb(P["beak"][0]+30,P["beak"][1]-10,3.4)
            +crumb(P["beak"][0]+18,P["beak"][1]+22,3)+dot(P["beak"][0]-34,P["beak"][1]+10,2.6,GOLD))
    elif mood_idx=="eating_3":
        P["eye_mode"]=("happy","happy"); P["puff"]=4; P["beak_mode"]="closed"
        fx=heart(P["belly"][0]+44,P["belly"][1]-34,7)+crumb(P["beak"][0]+22,P["beak"][1]+8,3.4)+crumb(P["beak"][0]-30,P["beak"][1]+26,3)
    elif mood_idx=="sleepy_1":
        P["eye_mode"]=("sleepy","sleepy"); P["brows"]="sleepy"; P["tuft"]="droop"
        P["wingl"]=(P["wingl"][0],P["wingl"][1]+8,P["wingl"][2]-2,P["wingl"][3]-5,0)
        P["wingr"]=(P["wingr"][0],P["wingr"][1]+8,P["wingr"][2]-2,P["wingr"][3]-5,0)
    elif mood_idx=="sleepy_2":
        P["eye_mode"]=("closed","closed"); P["bcy"]+=4; P["belly"]=(P["belly"][0],P["belly"][1]+4,P["belly"][2],P["belly"][3])
        P["ey_l"]=(P["ey_l"][0],P["ey_l"][1]+4); P["ey_r"]=(P["ey_r"][0],P["ey_r"][1]+4)
        P["beak"]=(P["beak"][0],P["beak"][1]+4); P["tuft"]="droop"; P["brows"]="sleepy"
        P["wingl"]=(P["wingl"][0],P["wingl"][1]+8,P["wingl"][2]-2,P["wingl"][3]-5,0)
        P["wingr"]=(P["wingr"][0],P["wingr"][1]+8,P["wingr"][2]-2,P["wingr"][3]-5,0)
        # nightcap on stages 3-4 (and 2) — anchored to body so it sits on the head
        capdy = P["bcy"]-(122 if stage==2 else (133 if stage==3 else 124))
        capx,capy=(92,62+capdy) if stage==2 else (92,66+capdy)
        capyc = capy+14  # band row
        capdoty = 43+capdy
        fx=(f'<g><path d="M{capx} {capy} Q120 {30+capdy} 158 {44+capdy} L148 {62+capdy} Q124 {52+capdy} 104 {70+capdy} Z" fill="{PURPLE}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>'
            f'<circle cx="160" cy="{capdoty}" r="9" fill="#FFFFFF" stroke="{INK}" stroke-width="4"/>'
            f'<rect x="90" y="{capyc}" width="56" height="14" rx="7" fill="#FFFFFF" stroke="{INK}" stroke-width="4"/></g>'
            +zzz(178,84,16)+zzz(196,110,12,op=0.8,w=4))
    elif mood_idx=="sleepy_3":
        P["eye_mode"]=("closed","closed"); P["rx"]+=3; P["ry"]+=2; P["tuft"]="droop"; P["brows"]="sleepy"
        capdy3 = P["bcy"]-(122 if stage==2 else (133 if stage==3 else 124))
        capy3=(62+capdy3) if stage==2 else (66+capdy3)
        fx=(f'<g><path d="M92 {capy3} Q120 {30+capdy3} 158 {44+capdy3} L148 {62+capdy3} Q124 {52+capdy3} 104 {70+capdy3} Z" fill="{PURPLE}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>'
            f'<circle cx="160" cy="{43+capdy3}" r="9" fill="#FFFFFF" stroke="{INK}" stroke-width="4"/>'
            f'<rect x="90" y="{capy3+14}" width="56" height="14" rx="7" fill="#FFFFFF" stroke="{INK}" stroke-width="4"/></g>'
            +zzz(176,70,20)+zzz(198,100,14,op=0.8,w=4)+zzz(168,108,10,op=0.6,w=3.5))
    elif mood_idx=="surprised_1":
        P["eye_mode"]=("surprised","surprised"); P["beak_mode"]="o_small"; P["brows"]="surprised"; P["tuft"]="up"
        P["wingl"]=(P["wingl"][0]-10,P["wingl"][1]-4,P["wingl"][2],P["wingl"][3],-30)
        P["wingr"]=(P["wingr"][0]+10,P["wingr"][1]-4,P["wingr"][2],P["wingr"][3],30)
        fx=dot(32,100,3.5,PURPLE)+dot(208,100,3.5,PURPLE)
    elif mood_idx=="surprised_2":
        P["bcy"]-=12; P["belly"]=(P["belly"][0],P["belly"][1]-12,P["belly"][2],P["belly"][3])
        P["ey_l"]=(P["ey_l"][0],P["ey_l"][1]-12); P["ey_r"]=(P["ey_r"][0],P["ey_r"][1]-12)
        P["beak"]=(P["beak"][0],P["beak"][1]-12); P["eye_mode"]=("surprised","surprised"); P["beak_mode"]="o"
        P["brows"]="surprised"; P["tuft"]="tall"; P["shadow_rx"]-=10
        if stage==2:
            P["wingl"]=(48,120,10,18,-55); P["wingr"]=(192,120,10,18,55)
        elif stage==3:
            P["wingl"]=(36,130,14,24,-55); P["wingr"]=(204,130,14,24,55)
        else:
            P["wingl"]=(32,128,17,30,-55); P["wingr"]=(208,128,17,30,55)
        P["feet_y"]-=8
        fx=excl(196,52,26)+star4(40,64,7,PURPLE)+dot(52,96,3.5,GOLD)
    elif mood_idx=="surprised_3":
        P["eye_mode"]=("open","open"); P["beak_mode"]="closed"; P["tuft"]="normal"
        P["wingl"]=(P["wingl"][0]-6,P["wingl"][1],P["wingl"][2],P["wingl"][3],-16)
        P["wingr"]=(P["wingr"][0]+6,P["wingr"][1],P["wingr"][2],P["wingr"][3],16)
        fx=excl(198,70,14)+dot(44,80,3,PURPLE,0.6)
    elif mood_idx=="proud_1":
        P["belly"]=(P["belly"][0],P["belly"][1],P["belly"][2]+4,P["belly"][3]+2)
        P["beak"]=(P["beak"][0],P["beak"][1]-5); P["ey_l"]=(P["ey_l"][0],P["ey_l"][1]-3); P["ey_r"]=(P["ey_r"][0],P["ey_r"][1]-3)
        P["brows"]="proud"; P["tuft"]="normal"
        # wings on hips: tuck inward
        P["wingl"]=(P["belly"][0]-P["belly"][2]-2,P["belly"][1]+6,12,20,-38)
        P["wingr"]=(P["belly"][0]+P["belly"][2]+2,P["belly"][1]+6,12,20,38)
    elif mood_idx=="proud_2":
        P["belly"]=(P["belly"][0],P["belly"][1],P["belly"][2]+4,P["belly"][3]+2)
        P["beak"]=(P["beak"][0],P["beak"][1]-5); P["ey_l"]=(P["ey_l"][0],P["ey_l"][1]-3); P["ey_r"]=(P["ey_r"][0],P["ey_r"][1]-3)
        P["eye_mode"]=("wink","open"); P["brows"]="proud"; P["tuft"]="up"
        P["wingl"]=(P["belly"][0]-P["belly"][2]-2,P["belly"][1]+6,12,20,-38)
        P["wingr"]=(P["belly"][0]+P["belly"][2]+2,P["belly"][1]+6,12,20,38)
        fx=star4(P["belly"][0]+22,P["belly"][1]+10,9,"#FFFFFF",stroke=True)+star4(52,66,7,PURPLE)+star4(190,70,6,GOLD,stroke=True)
    elif mood_idx=="proud_3":
        P["belly"]=(P["belly"][0],P["belly"][1],P["belly"][2]+2,P["belly"][3]+1)
        P["eye_mode"]=("happy","happy"); P["tuft"]="normal"
        P["wingl"]=(P["belly"][0]-P["belly"][2]-2,P["belly"][1]+6,12,20,-38)
        P["wingr"]=(P["belly"][0]+P["belly"][2]+2,P["belly"][1]+6,12,20,38)
        fx=star4(P["belly"][0]+22,P["belly"][1]+10,7,"#FFFFFF",opacity=0.8,stroke=True)+heart(P["belly"][0]-30,P["belly"][1]-20,6)

    fx = fx + fx_extra
    # ---- build parts ----
    bcy=P["bcy"]; rx=P["rx"]; ry=P["ry"]
    if stage==2:
        body_ellipse=f'<ellipse cx="120" cy="{bcy}" rx="{rx}" ry="{ry}" fill="{body}" stroke="{INK}" stroke-width="{SW}"/>'
        belly_svg=f'<ellipse cx="{P["belly"][0]}" cy="{P["belly"][1]}" rx="{P["belly"][2]}" ry="{P["belly"][3]}" fill="{belly}"/>'
        feet_svg=(f'<g id="feet" stroke="{INK}" stroke-width="{SW}"><ellipse cx="99" cy="{P["feet_y"]}" rx="11" ry="7" fill="{PEACH}"/>'
                  f'<ellipse cx="141" cy="{P["feet_y"]}" rx="11" ry="7" fill="{PEACH}"/></g>')
        tail_svg='<g id="tail"></g>'
        hl = highlight(P["hl"][0],P["hl"][1],P["hl"][2],P["hl"][3]) if mood_idx not in ("sleepy_2","sleepy_3") else ""
        # tuft small bubbles for s2
        tuft_svg=(f'<g id="head_tuft" stroke="{INK}" stroke-width="4" stroke-linejoin="round">'
                  f'<circle cx="110" cy="{86+(bcy-122)}" r="7" fill="{body}"/><circle cx="122" cy="{82+(bcy-122)}" r="8" fill="{body}"/>'
                  f'<circle cx="133" cy="{88+(bcy-122)}" r="6.5" fill="{body}"/></g>')
    else:
        body_ellipse=f'<ellipse cx="120" cy="{bcy}" rx="{rx}" ry="{ry}" fill="{body}" stroke="{INK}" stroke-width="{SW}"/>'
        shade_d = ("M162 100 Q178 130 168 168 Q176 140 158 108 Z" if stage==3 else "M162 92 Q178 122 168 162 Q176 132 158 100 Z")
        # shift shade with bcy delta
        dy = bcy-(133 if stage==3 else 124)
        body_ellipse+=f'<g id="body_shade"><path d="{shade_d}" fill="{shade}" opacity="0.22" transform="translate(0 {dy})"/></g>'
        belly_svg=f'<ellipse cx="{P["belly"][0]}" cy="{P["belly"][1]}" rx="{P["belly"][2]}" ry="{P["belly"][3]}" fill="{belly}"/>'
        feet_svg=(f'<g id="feet" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round">'
                  f'<ellipse cx="99" cy="{P["feet_y"]}" rx="{12 if stage==3 else 13}" ry="{7.5 if stage==3 else 8}" fill="{PEACH}"/>'
                  f'<ellipse cx="141" cy="{P["feet_y"]}" rx="{12 if stage==3 else 13}" ry="{7.5 if stage==3 else 8}" fill="{PEACH}"/></g>')
        if stage==3: tail_svg=tail_s3(fill=wingf,lift=(bcy-133))
        else: tail_svg=tail_s4(fill=wingf,lift=(bcy-124))
        hl = highlight(P["hl"][0],P["hl"][1]+(bcy-(133 if stage==3 else 124)),P["hl"][2],P["hl"][3]) if mood_idx not in ("sleepy_2","sleepy_3") else highlight(P["hl"][0],P["hl"][1],P["hl"][2],P["hl"][3],op=0.4)
        # tuft y shift with body? keep fixed head top approx bcy-ry
        tuft_svg=tuft(P["tuft"],body)
        shell_bot='<g id="shell_bottom"></g>'; shell_top='<g id="shell_top"></g>'

    wl=P["wingl"]; wr=P["wingr"]
    wingl_svg=wing("L",wl[0],wl[1],wl[2],wl[3],wl[4],wingf)
    wingr_svg=wing("R",wr[0],wr[1],wr[2],wr[3],wr[4],wingf)
    # eyes
    er=P["er"] if mood_idx!="surprised_2" else P["er"]
    ml,mr=P["eye_mode"]
    eyes_svg=eyes_group(ml,mr,P["ey_l"][0],P["ey_l"][1],P["ey_r"][0],P["ey_r"][1],er,dx_l=P["pdx"][0],dy_l=P["pdy"][0] if "pdy" in P else (2,2))
    # beak
    bcx,bcyb=P["beak"]
    if P["beak_mode"]=="open_happy": bt,bb=beak_open_happy(bcx,bcyb)
    elif P["beak_mode"]=="o": bt,bb=beak_o(bcx,bcyb,11)
    elif P["beak_mode"]=="o_small": bt,bb=beak_o(bcx,bcyb,8)
    elif P["beak_mode"]=="peck": bt,bb=beak_peck(bcx,bcyb)
    else: bt,bb=beak_closed(bcx,bcyb)
    beak_top_svg=f'<g id="beak_top">{bt}</g>'; beak_bot_svg=f'<g id="beak_bottom">{bb}</g>'
    chx = cheekx if stage==2 else ((76,153,164,153))
    if stage==2: cheek_svg=cheeks(80,142,160,puff=P["puff"])
    else: cheek_svg=cheeks(76,P["belly"][1]-5 if "belly" in P else 153,164,puff=P["puff"])
    brow_svg=brows(P["brows"],P["ey_l"][0],P["ey_l"][1]-22,P["ey_r"][0])
    # accessories
    ah,an,af=acc_shapes(acc,stage,skin)
    parts=[
      shadow(rx=P["shadow_rx"]),
      tail_svg,
      wingl_svg, wingr_svg,
      f'<g id="body">{body_ellipse}</g>',
      f'<g id="belly">{belly_svg}</g>',
      cheek_svg,
      tuft_svg if stage!=2 else tuft_svg,
      f'<g id="eyes">{eyes_svg}</g>' if False else f'{eyes_svg}',
      brow_svg,
      beak_top_svg, beak_bot_svg,
      feet_svg,
      shell_top, shell_bot,
      f'<g id="accessory_head">{ah}</g><g id="accessory_neck">{an}</g><g id="accessory_face">{af}</g>',
      hl,
      f'<g id="fx">{fx}</g>',
    ]
    # fix: eyes wrapper — contract wants eye_l/eye_r top-level; we already emit them. wrap in nothing.
    return svg_wrap(label,parts)

# ================= EGG =================
def render_egg(mood_idx,skin="sunny",acc="none",label="pip C egg"):
    S=SKINMAP[skin]
    INK5=SW
    tilt=0; dy=0; crack_gap=0; eye_mode=("open","open"); fx=""; beak_peek=""; shine=""
    hl='<ellipse cx="150" cy="68" rx="17" ry="9" fill="#FFFFFF" opacity="0.7" transform="rotate(-24 150 68)"/>'
    if mood_idx=="idle_1": pass
    elif mood_idx=="idle_2": tilt=4
    elif mood_idx=="blink_1": pass
    elif mood_idx=="blink_2": eye_mode=("closed","closed")
    elif mood_idx=="happy_1": tilt=-8; eye_mode=("happy","happy")
    elif mood_idx=="happy_2":
        tilt=8; dy=-14; eye_mode=("happy","happy")
        fx=star4(40,70,10,PURPLE)+star4(200,66,9,GOLD,stroke=True)+dot(58,108,4,PURPLE)+dot(184,110,4,PEACH)
    elif mood_idx=="happy_3": tilt=0; dy=-4; eye_mode=("happy","happy"); fx=star4(44,80,7,PURPLE,opacity=0.7)+star4(196,78,6,GOLD,opacity=0.7,stroke=True)
    elif mood_idx=="eating_1":
        fx=seed(120,60)+dot(106,84,3,PURPLE,0.8)+dot(134,86,3,GOLD,0.8)
    elif mood_idx=="eating_2":
        beak_peek=(f'<g id="beak_top"><path d="M110 146 L130 146 L120 160 Z" fill="{PEACH}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/></g>'
                   f'<g id="beak_bottom"></g>')
        fx=seed(148,150,0.8)+crumb(96,150,3.6)+crumb(164,158,3)+crumb(120,170,2.8)
        eye_mode=("happy","happy")
    elif mood_idx=="eating_3":
        eye_mode=("happy","happy"); fx=heart(164,120,6)+crumb(142,148,3.2)
    elif mood_idx=="sleepy_1": eye_mode=("sleepy","sleepy"); tilt=-5
    elif mood_idx=="sleepy_2": eye_mode=("closed","closed"); tilt=6; fx=zzz(176,80,16)+zzz(196,108,12,op=0.8,w=4)
    elif mood_idx=="sleepy_3": eye_mode=("closed","closed"); tilt=-6; fx=zzz(174,66,20)+zzz(198,96,14,op=0.8,w=4)+zzz(166,104,10,op=0.6,w=3.5)
    elif mood_idx=="surprised_1": eye_mode=("surprised","surprised"); fx=dot(40,100,3.5,PURPLE)+dot(200,100,3.5,PURPLE)
    elif mood_idx=="surprised_2":
        eye_mode=("surprised","surprised"); crack_gap=7; dy=-8; fx=excl(196,52,26)+star4(44,66,7,PURPLE)
    elif mood_idx=="surprised_3": eye_mode=("open","open"); crack_gap=3; fx=excl(198,72,13)
    elif mood_idx in ("proud_1","proud_2","proud_3"):
        shine=(f'<path d="M84 60 L104 56 L88 130 L72 126 Z" fill="#FFFFFF" opacity="0.5"/>')
        fx=star4(168,84,9,"#FFFFFF",stroke=True)+star4(52,110,6,PURPLE)
        if mood_idx=="proud_2": eye_mode=("wink","open"); fx+=star4(120,120,8,GOLD,stroke=True)
        elif mood_idx=="proud_3": eye_mode=("happy","happy")
    # egg base path
    egg_d="M120 30 C78 30 58 94 62 138 C65 176 90 201 120 201 C150 201 175 176 178 138 C182 94 162 30 120 30 Z"
    crack_y=146
    crack=f"M62 {crack_y} L86 {crack_y-10} L100 {crack_y+6-crack_gap} L124 {crack_y-6-crack_gap} L142 {crack_y+10} L160 {crack_y-2} L178 {crack_y+6}"
    # eyes below crack
    def egg_eye(cx,mode):
        cy=163+dy*0.3
        if mode=="open": return (f'<circle cx="{cx}" cy="{cy}" r="10" fill="#FFFFFF" stroke="{INK}" stroke-width="4.5"/><circle cx="{cx+1.5}" cy="{cy+1.5}" r="4.5" fill="{INK}"/>')
        if mode=="surprised": return (f'<circle cx="{cx}" cy="{cy}" r="13" fill="#FFFFFF" stroke="{INK}" stroke-width="4.5"/><circle cx="{cx}" cy="{cy+1}" r="4" fill="{INK}"/><circle cx="{cx-1.5}" cy="{cy-1}" r="1.5" fill="#FFFFFF"/>')
        if mode=="closed": return f'<path d="M{cx-10} {cy} Q{cx} {cy+8} {cx+10} {cy}" fill="none" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>'
        if mode=="happy": return f'<path d="M{cx-10} {cy+3} Q{cx} {cy-9} {cx+10} {cy+3}" fill="none" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>'
        if mode=="sleepy": return f'<path d="M{cx-10} {cy-1} Q{cx} {cy+5} {cx+10} {cy-1}" fill="none" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>'
        if mode=="wink": return f'<path d="M{cx-10} {cy} Q{cx} {cy+8} {cx+10} {cy}" fill="none" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>'
        return ""
    ml,mr=eye_mode
    # build eye groups with children to satisfy contract (6 each)
    def full_eye(side,cx,mode):
        subs=[]
        for m in ("open","closed","happy","sleepy","surprised","wink"):
            inner=egg_eye(cx,m) if m==mode else ""
            subs.append(f'<g id="{m}">{inner}</g>')
        return f'<g id="{side}">'+"".join(subs)+"</g>"
    eyes_svg=full_eye("eye_l",102,ml)+full_eye("eye_r",138,mr)
    ah,an,af=acc_shapes(acc,1,skin)
    gtrans=f"rotate({tilt} 120 130) translate(0 {dy})"
    inner_egg=(f'<g transform="{gtrans}">'
      f'<g id="body"><path d="{egg_d}" fill="#FFF8E8" stroke="{INK}" stroke-width="{SW}"/></g>'
      f'<g id="shell_top"><circle cx="90" cy="78" r="7" fill="{PURPLE}"/><circle cx="142" cy="64" r="5.5" fill="{PURPLE}"/><circle cx="158" cy="102" r="6" fill="{PURPLE}"/><circle cx="78" cy="120" r="5" fill="{PURPLE}"/>{shine}</g>'
      f'<g id="shell_bottom"><path d="{crack}" fill="none" stroke="{INK}" stroke-width="{SW}" stroke-linecap="round" stroke-linejoin="round"/></g>'
      f'<g id="highlight">{hl}</g>'
      f'{eyes_svg}'
      f'{(beak_peek if beak_peek else "<g id=\"beak_top\"></g><g id=\"beak_bottom\"></g>")}'
      f'<g id="cheek_l"></g><g id="cheek_r"></g><g id="head_tuft"></g><g id="tail"></g><g id="wing_l"></g><g id="wing_r"></g>'
      f'<g id="belly"></g><g id="feet"></g><g id="brow_l"></g><g id="brow_r"></g>'
      f'<g id="accessory_head">{ah}</g><g id="accessory_neck">{an}</g><g id="accessory_face">{af}</g>'
      f'<g id="fx">{fx}</g>'
      f'</g>')
    parts=[shadow(rx=62 if dy==0 else 52),inner_egg]
    return svg_wrap(label,parts)

MOODS=["idle_1","idle_2","blink_1","blink_2","happy_1","happy_2","happy_3",
 "eating_1","eating_2","eating_3","sleepy_1","sleepy_2","sleepy_3",
 "surprised_1","surprised_2","surprised_3","proud_1","proud_2","proud_3"]

def fname(stage,mood): return f"s{stage}_{mood}.svg"

count=0
for stage in (1,2,3,4):
    for m in MOODS:
        if stage==1: svg=render_egg(m,skin="sunny",label=f"Pip v2 C stage 1 {m}")
        else: svg=render_bird(stage,m,skin="sunny",label=f"Pip v2 C stage {stage} {m}")
        # mood short for filename: keep full like s3_idle_1
        with open(os.path.join(POSES,fname(stage,m)),"w") as f: f.write(svg)
        count+=1
print("poses",count)

# skins: fledgling idle + happy peak in 4 skins
for skin in ("sunny","berry","sky","mint"):
    for m,tag in (("idle_1","idle"),("happy_2","happy")):
        svg=render_bird(3,m,skin=skin,label=f"Pip v2 C s3 {tag} {skin}")
        with open(os.path.join(SKINS,f"s3_{tag}_{skin}.svg"),"w") as f: f.write(svg)
print("skins 8")

# accessories on all stages idle
for stage in (1,2,3,4):
    base = "idle_1"
    for acc in ("bow","cap","scarf","glasses"):
        if stage==1: svg=render_egg(base,acc=acc,label=f"Pip v2 C s1 idle {acc}")
        else: svg=render_bird(stage,base,acc=acc,label=f"Pip v2 C s{stage} idle {acc}")
        with open(os.path.join(ACC,f"s{stage}_idle_{acc}.svg"),"w") as f: f.write(svg)
print("accessories 16")

# evolve sequences: 3 frames per transition
def evolve_frame(a,b,i,label):
    # glow rings + sparkles + morph hint
    fx=(f'<circle cx="120" cy="130" r="{70+i*14}" fill="#FFF1B8" opacity="{0.5-i*0.12}"/>'
        f'<circle cx="120" cy="130" r="{46+i*10}" fill="#FFFFFF" opacity="{0.35-i*0.08}"/>'
        +star4(60,70,10,PURPLE)+star4(180,70,10,GOLD,stroke=True)+star4(52,170,8,PEACH)+star4(188,170,8,PURPLE)
        +dot(90,50,4,GOLD)+dot(150,50,4,PURPLE))
    if a==1 and b==2:
        if i==1: svg=render_egg("idle_1",label=label); svg=svg.replace('<g id="fx">',f'<g id="fx">{fx}')
        elif i==2:
            svg=render_egg("surprised_2",label=label)
            burst=star4(120,140,26,"#FFFFFF",stroke=True)+star4(80,120,12,GOLD,stroke=True)+star4(160,120,12,PURPLE)
            svg=svg.replace('<g id="fx">',f'<g id="fx">{burst}{fx}')
        else: svg=render_bird(2,"happy_2",label=label); svg=svg.replace('<g id="fx">',f'<g id="fx">{fx}')
    elif a==2 and b==3:
        if i==1: svg=render_bird(2,"idle_1",label=label); svg=svg.replace('<g id="fx">',f'<g id="fx">{fx}')
        elif i==2:
            svg=render_bird(2,"happy_2",label=label)
            burst=star4(120,120,26,"#FFFFFF",stroke=True)+star4(70,100,12,GOLD,stroke=True)+star4(170,100,12,PURPLE)
            svg=svg.replace('<g id="fx">',f'<g id="fx">{burst}')
        else: svg=render_bird(3,"happy_2",label=label); svg=svg.replace('<g id="fx">',f'<g id="fx">{fx}')
    else:
        if i==1: svg=render_bird(3,"proud_2",label=label); svg=svg.replace('<g id="fx">',f'<g id="fx">{fx}')
        elif i==2:
            svg=render_bird(3,"happy_2",label=label)
            burst=star4(120,120,30,"#FFFFFF",stroke=True)+star4(60,90,12,GOLD,stroke=True)+star4(180,90,12,PURPLE)
            svg=svg.replace('<g id="fx">',f'<g id="fx">{burst}')
        else: svg=render_bird(4,"happy_2",label=label); svg=svg.replace('<g id="fx">',f'<g id="fx">{fx}')
    return svg

for a,b in ((1,2),(2,3),(3,4)):
    for i in (1,2,3):
        svg=evolve_frame(a,b,i,label=f"Pip v2 C evolve s{a}s{b} frame {i}")
        with open(os.path.join(EVO,f"s{a}s{b}_{i}.svg"),"w") as f: f.write(svg)
print("evolve 9")
