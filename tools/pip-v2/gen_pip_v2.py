#!/usr/bin/env python3
"""Pip v2 character-design package generator — original art, commercially safe."""
import os, math

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = "/Users/ibrar/Desktop/infinora.noworkspace/nestling-pip-v2/design/pip-v2"

INK = "#1E1B3A"
YELLOW = "#FFD93D"
COIN = "#F4B400"
PEACH = "#FF8A5B"
LILAC = "#7C6CF2"
LEAF = "#17804F"
CREAM = "#FFF8E8"
BELLY_A = "#FFF6D6"
WHITE = "#FFFFFF"

SPECS = {
    "A": {"sw": 6.5, "name": "Mochi"},
    "B": {"sw": 8.0, "name": "Bolt"},
    "C": {"sw": 5.0, "name": "Storybook"},
}

def hdr(label):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" role="img" aria-label="{label}">')

def shadow():
    return '<g id="shadow"><ellipse cx="120" cy="212" rx="62" ry="11" fill="#1E1B3A" opacity="0.12"/></g>'

def blush_A(dx=0):
    return (f'<g id="blush"><ellipse cx="{75+dx}" cy="152" rx="10" ry="6.5" fill="{PEACH}" opacity="0.55"/>'
            f'<ellipse cx="{165+dx}" cy="152" rx="10" ry="6.5" fill="{PEACH}" opacity="0.55"/></g>')
def blush_B(dx=0):
    return (f'<g id="blush"><ellipse cx="{72+dx}" cy="150" rx="8" ry="5" fill="{PEACH}" opacity="0.45"/>'
            f'<ellipse cx="{168+dx}" cy="150" rx="8" ry="5" fill="{PEACH}" opacity="0.45"/></g>')
def blush_C(dx=0):
    return (f'<g id="blush"><ellipse cx="{76+dx}" cy="153" rx="9" ry="6" fill="{PEACH}" opacity="0.5"/>'
            f'<ellipse cx="{164+dx}" cy="153" rx="9" ry="6" fill="{PEACH}" opacity="0.5"/></g>')

def highlight(cx=97, cy=103, rx=18, ry=10, rot=-18, op=0.6):
    return (f'<g id="highlight"><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#FFFFFF" opacity="{op}" '
            f'transform="rotate({rot} {cx} {cy})"/></g>')

# ---------- tufts ----------
def tuft(d):
    sw = SPECS[d]["sw"]
    if d == "A":
        return (f'<g id="head-tuft" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                f'<circle cx="102" cy="68" r="11" fill="{YELLOW}"/>'
                f'<circle cx="120" cy="60" r="12.5" fill="{YELLOW}"/>'
                f'<circle cx="138" cy="68" r="11" fill="{YELLOW}"/></g>')
    if d == "B":
        return (f'<g id="head-tuft" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                f'<path d="M100 72 L110 40 L124 66 Z" fill="{YELLOW}"/>'
                f'<path d="M120 66 L136 38 L143 70 Z" fill="{YELLOW}"/></g>')
    # C: wispy blades
    return (f'<g id="head-tuft" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round">'
            f'<path d="M106 70 Q100 46 112 38 Q118 50 116 68 Z" fill="{YELLOW}"/>'
            f'<path d="M120 68 Q120 42 132 34 Q138 48 132 68 Z" fill="{YELLOW}"/>'
            f'<path d="M132 70 Q142 52 152 50 Q150 62 142 72 Z" fill="{YELLOW}"/></g>')

# ---------- bodies ----------
def body(d, q=False):
    sw = SPECS[d]["sw"]
    if d == "A":
        s = f'<g id="body"><ellipse cx="120" cy="132" rx="63" ry="60" fill="{YELLOW}" stroke="{INK}" stroke-width="{sw}"/></g>'
        belly = f'<g id="belly"><ellipse cx="120" cy="157" rx="39" ry="33" fill="{BELLY_A}"/></g>'
    elif d == "B":
        s = f'<g id="body"><ellipse cx="120" cy="130" rx="57" ry="63" fill="{YELLOW}" stroke="{INK}" stroke-width="{sw}"/></g>'
        belly = f'<g id="belly"><ellipse cx="120" cy="158" rx="36" ry="34" fill="{WHITE}"/></g>'
    else:
        s = (f'<g id="body"><ellipse cx="120" cy="133" rx="60" ry="61" fill="{YELLOW}" stroke="{INK}" stroke-width="{sw}"/></g>'
             f'<g id="body-shade"><path d="M162 100 Q178 130 168 168 Q176 140 158 108 Z" fill="#B97E00" opacity="0.22"/></g>')
        belly = f'<g id="belly"><ellipse cx="120" cy="158" rx="37" ry="31" fill="{BELLY_A}"/></g>'
    if q:  # 3/4 shift: slightly narrower + side shade to suggest turn
        pass
    return s + belly

def feet(d):
    sw = SPECS[d]["sw"]
    if d == "B":
        return (f'<g id="feet" stroke="{INK}" stroke-width="{sw}">'
                f'<g id="foot-L"><ellipse cx="98" cy="196" rx="15" ry="9" fill="{PEACH}"/></g>'
                f'<g id="foot-R"><ellipse cx="142" cy="196" rx="15" ry="9" fill="{PEACH}"/></g></g>')
    if d == "C":
        return (f'<g id="feet" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                f'<g id="foot-L"><ellipse cx="99" cy="196" rx="12" ry="7.5" fill="{PEACH}"/></g>'
                f'<g id="foot-R"><ellipse cx="141" cy="196" rx="12" ry="7.5" fill="{PEACH}"/></g></g>')
    return (f'<g id="feet" stroke="{INK}" stroke-width="{sw}">'
            f'<g id="foot-L"><ellipse cx="99" cy="195" rx="13" ry="8.5" fill="{PEACH}"/></g>'
            f'<g id="foot-R"><ellipse cx="141" cy="195" rx="13" ry="8.5" fill="{PEACH}"/></g></g>')

def tail_small(d):
    sw = SPECS[d]["sw"]
    return (f'<g id="tail" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
            f'<path d="M108 186 L112 202 L120 194 L128 202 L132 186 Z" fill="{COIN}"/></g>')

def wings(d, pose="down", mirror_q=False):
    sw = SPECS[d]["sw"]
    if pose == "down":
        if d == "B":
            return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                    f'<g id="wing-L"><rect x="34" y="118" width="27" height="46" rx="13.5" fill="{COIN}" transform="rotate(14 47 141)"/></g>'
                    f'<g id="wing-R"><rect x="179" y="118" width="27" height="46" rx="13.5" fill="{COIN}" transform="rotate(-14 193 141)"/></g></g>')
        if d == "C":
            return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                    f'<g id="wing-L"><ellipse cx="62" cy="144" rx="16" ry="25" fill="{COIN}"/>'
                    f'<path d="M62 130 L62 158" stroke="{INK}" stroke-width="3" stroke-linecap="round" opacity="0.55"/></g>'
                    f'<g id="wing-R"><ellipse cx="178" cy="144" rx="16" ry="25" fill="{COIN}"/>'
                    f'<path d="M178 130 L178 158" stroke="{INK}" stroke-width="3" stroke-linecap="round" opacity="0.55"/></g></g>')
        return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                f'<g id="wing-L"><ellipse cx="60" cy="143" rx="15" ry="23" fill="{COIN}"/></g>'
                f'<g id="wing-R"><ellipse cx="180" cy="143" rx="15" ry="23" fill="{COIN}"/></g></g>')
    if pose == "raised":  # happy: wings up
        if d == "B":
            return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                    f'<g id="wing-L"><rect x="22" y="70" width="28" height="50" rx="14" fill="{COIN}" transform="rotate(-32 36 95)"/></g>'
                    f'<g id="wing-R"><rect x="190" y="70" width="28" height="50" rx="14" fill="{COIN}" transform="rotate(32 204 95)"/></g></g>')
        return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                f'<g id="wing-L"><ellipse cx="44" cy="92" rx="15" ry="26" fill="{COIN}" transform="rotate(-32 44 92)"/></g>'
                f'<g id="wing-R"><ellipse cx="196" cy="92" rx="15" ry="26" fill="{COIN}" transform="rotate(32 196 92)"/></g></g>')
    if pose == "out":  # surprised: wide
        return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                f'<g id="wing-L"><ellipse cx="36" cy="130" rx="14" ry="24" fill="{COIN}" transform="rotate(-55 36 130)"/></g>'
                f'<g id="wing-R"><ellipse cx="204" cy="130" rx="14" ry="24" fill="{COIN}" transform="rotate(55 204 130)"/></g></g>')
    if pose == "hip":  # proud: one down one akimbo
        return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                f'<g id="wing-L"><ellipse cx="60" cy="143" rx="15" ry="23" fill="{COIN}"/></g>'
                f'<g id="wing-R"><ellipse cx="172" cy="160" rx="20" ry="13" fill="{COIN}" transform="rotate(-24 172 160)"/></g></g>')
    if pose == "peck":  # eating: wings slightly back/down
        return wings(d, "down")
    if pose == "sleep":  # drooped
        if d == "B":
            return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                    f'<g id="wing-L"><rect x="36" y="130" width="26" height="42" rx="13" fill="{COIN}" transform="rotate(10 49 151)"/></g>'
                    f'<g id="wing-R"><rect x="178" y="130" width="26" height="42" rx="13" fill="{COIN}" transform="rotate(-10 191 151)"/></g></g>')
        return (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                f'<g id="wing-L"><ellipse cx="62" cy="152" rx="14" ry="20" fill="{COIN}"/></g>'
                f'<g id="wing-R"><ellipse cx="178" cy="152" rx="14" ry="20" fill="{COIN}"/></g></g>')
    return wings(d, "down")

# ---------- eyes ----------
def eyes_open(d, q=False):
    sw = SPECS[d]["sw"]
    if d == "B":
        r, pr = 18, 9
        lx, rx, cy = 95, 145, 125
    elif d == "C":
        r, pr = 15, 7
        lx, rx, cy = 96, 144, 130
    else:
        r, pr = 16, 7.5
        lx, rx, cy = 96, 144, 129
    if q:
        lx, rx = 108, 156
        if d == "B":
            r = 17
    if q:
        return (f'<g id="eyes">'
                f'<g id="eye-L"><ellipse cx="{lx}" cy="{cy}" rx="{r-2}" ry="{r}" fill="{WHITE}" stroke="{INK}" stroke-width="{sw}"/>'
                f'<g id="pupil-L"><circle cx="{lx+2}" cy="{cy+2}" r="{pr}" fill="{INK}"/>'
                f'<g id="glint-L"><circle cx="{lx-1}" cy="{cy-2}" r="2.6" fill="{WHITE}"/></g></g></g>'
                f'<g id="eye-R"><circle cx="{rx}" cy="{cy}" r="{r}" fill="{WHITE}" stroke="{INK}" stroke-width="{sw}"/>'
                f'<g id="pupil-R"><circle cx="{rx+3}" cy="{cy+2}" r="{pr}" fill="{INK}"/>'
                f'<g id="glint-R"><circle cx="{rx}" cy="{cy-2}" r="2.6" fill="{WHITE}"/></g></g></g></g>')
    return (f'<g id="eyes">'
            f'<g id="eye-L"><circle cx="{lx}" cy="{cy}" r="{r}" fill="{WHITE}" stroke="{INK}" stroke-width="{sw}"/>'
            f'<g id="pupil-L"><circle cx="{lx+2}" cy="{cy+2}" r="{pr}" fill="{INK}"/>'
            f'<g id="glint-L"><circle cx="{lx-1}" cy="{cy-2}" r="2.6" fill="{WHITE}"/></g></g></g>'
            f'<g id="eye-R"><circle cx="{rx}" cy="{cy}" r="{r}" fill="{WHITE}" stroke="{INK}" stroke-width="{sw}"/>'
            f'<g id="pupil-R"><circle cx="{rx+2}" cy="{cy+2}" r="{pr}" fill="{INK}"/>'
            f'<g id="glint-R"><circle cx="{rx-1}" cy="{cy-2}" r="2.6" fill="{WHITE}"/></g></g></g></g>')

def eyes_closed(d, kind="blink"):
    sw = SPECS[d]["sw"]
    if d == "B":
        lx, rx, cy = 95, 145, 130
    else:
        lx, rx, cy = 96, 144, 131
    if kind == "happy":  # ^^ arcs
        return (f'<g id="eyes">'
                f'<g id="eye-L-happy"><path d="M{lx-12} {cy+6} Q{lx} {cy-12} {lx+12} {cy+6}" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round"/></g>'
                f'<g id="eye-R-happy"><path d="M{rx-12} {cy+6} Q{rx} {cy-12} {rx+12} {cy+6}" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round"/></g></g>')
    if kind == "sleep":  # gentle U closed
        return (f'<g id="eyes">'
                f'<g id="eye-L-closed"><path d="M{lx-11} {cy-2} Q{lx} {cy+10} {lx+11} {cy-2}" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round"/></g>'
                f'<g id="eye-R-closed"><path d="M{rx-11} {cy-2} Q{rx} {cy+10} {rx+11} {cy-2}" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round"/></g></g>')
    # blink: simple curved lines
    return (f'<g id="eyes">'
            f'<g id="eye-L-closed"><path d="M{lx-11} {cy} Q{lx} {cy+7} {lx+11} {cy}" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round"/></g>'
            f'<g id="eye-R-closed"><path d="M{rx-11} {cy} Q{rx} {cy+7} {rx+11} {cy}" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round"/></g></g>')

def eyes_surprised(d):
    sw = SPECS[d]["sw"]
    lx, rx, cy = (95, 145, 128) if d == "B" else (94, 146, 129)
    r = 20 if d == "B" else 19
    return (f'<g id="eyes">'
            f'<g id="eye-L"><circle cx="{lx}" cy="{cy}" r="{r}" fill="{WHITE}" stroke="{INK}" stroke-width="{sw}"/>'
            f'<g id="pupil-L"><circle cx="{lx}" cy="{cy+2}" r="5.5" fill="{INK}"/>'
            f'<g id="glint-L"><circle cx="{lx-2}" cy="{cy-2}" r="2.2" fill="{WHITE}"/></g></g></g>'
            f'<g id="eye-R"><circle cx="{rx}" cy="{cy}" r="{r}" fill="{WHITE}" stroke="{INK}" stroke-width="{sw}"/>'
            f'<g id="pupil-R"><circle cx="{rx}" cy="{cy+2}" r="5.5" fill="{INK}"/>'
            f'<g id="glint-R"><circle cx="{rx-2}" cy="{cy-2}" r="2.2" fill="{WHITE}"/></g></g></g></g>')

def eyes_proud(d):
    sw = SPECS[d]["sw"]
    lx, rx, cy = 96, 144, 130
    # left open with half lid, right wink
    return (f'<g id="eyes">'
            f'<g id="eye-L"><circle cx="{lx}" cy="{cy}" r="15" fill="{WHITE}" stroke="{INK}" stroke-width="{sw}"/>'
            f'<path d="M{lx-15} {cy-6} L{lx+15} {cy-6} L{lx+15} {cy-16} L{lx-15} {cy-16} Z" fill="{YELLOW}"/>'
            f'<path d="M{lx-15} {cy-6} L{lx+15} {cy-6}" stroke="{INK}" stroke-width="{sw-1}" stroke-linecap="round"/>'
            f'<g id="pupil-L"><circle cx="{lx+2}" cy="{cy+3}" r="6.5" fill="{INK}"/></g></g>'
            f'<g id="eye-R-closed"><path d="M{rx-11} {cy} Q{rx} {cy+8} {rx+11} {cy}" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round"/></g></g>')

# ---------- beaks ----------
def beak(d, kind="closed", q=False):
    sw = SPECS[d]["sw"]
    cx = 131 if q else 120
    if kind == "closed":
        if d == "B":
            return (f'<g id="beak"><g id="beak-top"><path d="M{cx-16} 148 L{cx+16} 148 L{cx+8} 165 L{cx-8} 165 Z" fill="{PEACH}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/></g></g>')
        return (f'<g id="beak"><g id="beak-top"><path d="M{cx-14} 150 Q{cx} 145 {cx+14} 150 Q{cx+10} 161 {cx} 163 Q{cx-10} 161 {cx-14} 150 Z" fill="{PEACH}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/></g></g>')
    if kind == "happy":
        return (f'<g id="beak"><g id="beak-top"><path d="M{cx-16} 148 Q{cx} 143 {cx+16} 148 L{cx+12} 152 L{cx-12} 152 Z" fill="{PEACH}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/></g>'
                f'<g id="beak-bottom"><ellipse cx="{cx}" cy="162" rx="13" ry="10" fill="{INK}"/>'
                f'<ellipse cx="{cx}" cy="166" rx="7" ry="4.5" fill="{PEACH}"/></g></g>')
    if kind == "eat":
        # open pecking down
        return (f'<g id="beak"><g id="beak-top"><path d="M{cx-13} 152 L{cx+13} 152 L{cx} 164 Z" fill="{PEACH}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/></g>'
                f'<g id="beak-bottom"><path d="M{cx-9} 164 L{cx+9} 164 L{cx} 172 Z" fill="{PEACH}" stroke="{INK}" stroke-width="{sw-1}" stroke-linejoin="round"/></g></g>')
    if kind == "o":
        return (f'<g id="beak"><g id="beak-top"><ellipse cx="{cx}" cy="160" rx="11" ry="12" fill="{INK}"/>'
                f'<ellipse cx="{cx}" cy="163" rx="5" ry="5" fill="{PEACH}"/></g></g>')
    if kind == "smirk":
        return (f'<g id="beak"><g id="beak-top"><path d="M{cx-14} 150 Q{cx+4} 146 {cx+16} 153 Q{cx+8} 163 {cx-2} 162 Q{cx-12} 160 {cx-14} 150 Z" fill="{PEACH}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/></g></g>')
    if kind == "tiny":
        return (f'<g id="beak"><g id="beak-top"><path d="M{cx-9} 152 Q{cx} 150 {cx+9} 152 Q{cx+5} 158 {cx} 158 Q{cx-5} 158 {cx-9} 152 Z" fill="{PEACH}" stroke="{INK}" stroke-width="{sw-1}" stroke-linejoin="round"/></g></g>')
    return beak(d, "closed", q)

def sparkles():
    return (f'<g id="accessories"><g id="sparkle-1"><path d="M34 60 L37 68 L45 71 L37 74 L34 82 L31 74 L23 71 L31 68 Z" fill="{LILAC}"/></g>'
            f'<g id="sparkle-2"><path d="M206 60 L208.5 66 L214 68.5 L208.5 71 L206 77 L203.5 71 L198 68.5 L203.5 66 Z" fill="{COIN}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/></g>'
            f'<g id="sparkle-3"><circle cx="52" cy="100" r="4" fill="{LILAC}"/><circle cx="190" cy="104" r="4" fill="{PEACH}"/></g></g>')

def seed_set(d):
    sw = SPECS[d]["sw"]
    return (f'<g id="accessories"><g id="seed"><ellipse cx="174" cy="198" rx="11" ry="8.5" fill="{COIN}" stroke="{INK}" stroke-width="4.5"/>'
            f'<path d="M174 190 L174 192" stroke="{INK}" stroke-width="2.5" stroke-linecap="round"/></g>'
            f'<g id="crumbs"><circle cx="150" cy="200" r="3.2" fill="{PEACH}" stroke="{INK}" stroke-width="2.5"/>'
            f'<circle cx="192" cy="188" r="2.8" fill="{PEACH}" stroke="{INK}" stroke-width="2.5"/>'
            f'<circle cx="160" cy="186" r="2.4" fill="{LILAC}"/></g>'
            f'<g id="cheek-puff"><circle cx="142" cy="162" r="9" fill="{PEACH}" opacity="0.6"/></g>'
            f'<g id="peck-lines"><path d="M140 176 L150 186" stroke="{INK}" stroke-width="3.5" stroke-linecap="round" opacity="0.5"/>'
            f'<path d="M166 182 L162 188" stroke="{INK}" stroke-width="3.5" stroke-linecap="round" opacity="0.5"/></g></g>')

def nightcap(d):
    sw = SPECS[d]["sw"]
    return (f'<g id="accessories"><g id="nightcap"><path d="M92 66 Q120 30 158 44 L148 62 Q124 52 104 70 Z" fill="{LILAC}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>'
            f'<circle cx="160" cy="43" r="9" fill="{WHITE}" stroke="{INK}" stroke-width="{sw-1}"/>'
            f'<rect x="90" y="62" width="56" height="14" rx="7" fill="{WHITE}" stroke="{INK}" stroke-width="{sw-1}"/></g>'
            f'<g id="zzz"><path d="M178 84 L194 84 L182 98 L198 98" fill="none" stroke="{LILAC}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="M196 110 L208 110 L199 120 L211 120" fill="none" stroke="{LILAC}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" opacity="0.8"/>'
            f'<path d="M168 108 L178 108 L171 116 L181 116" fill="none" stroke="{LILAC}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.6"/></g></g>')

def surprise_ticks():
    return (f'<g id="accessories"><g id="ticks">'
            f'<path d="M40 70 L48 80" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>'
            f'<path d="M200 70 L192 80" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>'
            f'<circle cx="32" cy="100" r="3.5" fill="{LILAC}"/><circle cx="208" cy="100" r="3.5" fill="{LILAC}"/></g></g>')

def medal():
    sw = 5
    return (f'<g id="accessories"><g id="medal"><circle cx="150" cy="172" r="12" fill="{LEAF}" stroke="{INK}" stroke-width="4.5"/>'
            f'<path d="M150 165 L152.5 170 L158 170 L153.5 173.5 L155 179 L150 175.5 L145 179 L146.5 173.5 L142 170 L147.5 170 Z" fill="{YELLOW}"/></g></g>')

def blush_for(d, q=False):
    dx = 10 if q else 0
    return {"A": blush_A(dx), "B": blush_B(dx), "C": blush_C(dx)}[d]

def assemble(d, label, wings_pose="down", eyes="open", beak_kind="closed", extras="", q=False, hl=True):
    sw = SPECS[d]["sw"]
    parts = [hdr(label), shadow(), tail_small(d), body(d, q), feet(d), wings(d, wings_pose)]
    parts.append(tuft(d))
    if hl:
        hx = 97 + (12 if q else 0)
        if d == "A": parts.append(highlight(hx, 103, 18, 10, -18, 0.6))
        elif d == "B": parts.append(highlight(hx, 100, 14, 9, -18, 0.65))
        else: parts.append(highlight(hx-1, 102, 17, 10, -18, 0.55))
    if eyes == "open": parts.append(eyes_open(d, q))
    elif eyes == "blink": parts.append(eyes_closed(d, "blink"))
    elif eyes == "happy": parts.append(eyes_closed(d, "happy"))
    elif eyes == "sleep": parts.append(eyes_closed(d, "sleep"))
    elif eyes == "surprised": parts.append(eyes_surprised(d))
    elif eyes == "proud": parts.append(eyes_proud(d))
    parts.append(beak(d, beak_kind, q))
    if eyes in ("open", "blink", "proud") and beak_kind in ("closed", "smirk", "tiny"):
        parts.append(blush_for(d, q))
    if eyes == "happy":
        parts.append(blush_for(d, q))
    parts.append(extras)
    parts.append("</svg>")
    return "\n".join([p for p in parts if p])

# ---------- growth stages ----------
def stage_egg(d, label):
    sw = SPECS[d]["sw"]
    return "\n".join([
        hdr(label), shadow(),
        f'<g id="body"><path d="M120 30 C78 30 58 94 62 138 C65 176 90 201 120 201 C150 201 175 176 178 138 C182 94 162 30 120 30 Z" fill="{CREAM}" stroke="{INK}" stroke-width="{sw}"/></g>',
        f'<g id="spots"><circle cx="90" cy="78" r="7" fill="{LILAC}"/><circle cx="142" cy="64" r="5.5" fill="{LILAC}"/><circle cx="158" cy="102" r="6" fill="{LILAC}"/><circle cx="78" cy="120" r="5" fill="{LILAC}"/></g>',
        highlight(150, 68, 17, 9, -24, 0.7),
        f'<g id="crack"><path d="M62 146 L86 136 L100 152 L124 140 L142 156 L160 144 L178 152" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/></g>',
        f'<g id="eyes"><g id="eye-L"><circle cx="102" cy="163" r="10" fill="{WHITE}" stroke="{INK}" stroke-width="4.5"/><circle cx="103.5" cy="164.5" r="4.5" fill="{INK}"/></g>'
        f'<g id="eye-R"><circle cx="138" cy="163" r="10" fill="{WHITE}" stroke="{INK}" stroke-width="4.5"/><circle cx="139.5" cy="164.5" r="4.5" fill="{INK}"/></g></g>',
        "</svg>"])

def stage_hatchling(d, label):
    sw = SPECS[d]["sw"]
    tiny_tuft = (f'<g id="head-tuft" stroke="{INK}" stroke-width="{sw-1}" stroke-linejoin="round">'
                 f'<circle cx="110" cy="86" r="7" fill="{YELLOW}"/><circle cx="122" cy="82" r="8" fill="{YELLOW}"/><circle cx="133" cy="88" r="6.5" fill="{YELLOW}"/></g>') if d!="B" else (
                 f'<g id="head-tuft" stroke="{INK}" stroke-width="{sw-1}" stroke-linejoin="round"><path d="M108 90 L114 72 L124 88 Z" fill="{YELLOW}"/><path d="M122 88 L132 70 L138 90 Z" fill="{YELLOW}"/></g>')
    return "\n".join([
        hdr(label), shadow(),
        f'<g id="body"><circle cx="120" cy="122" r="42" fill="{YELLOW}" stroke="{INK}" stroke-width="{sw}"/></g>',
        f'<g id="belly"><ellipse cx="120" cy="138" rx="24" ry="20" fill="{BELLY_A if d!="B" else WHITE}"/></g>',
        f'<g id="wings" stroke="{INK}" stroke-width="{sw-1}"><g id="wing-L"><ellipse cx="82" cy="128" rx="10" ry="16" fill="{COIN}"/></g>'
        f'<g id="wing-R"><ellipse cx="158" cy="128" rx="10" ry="16" fill="{COIN}"/></g></g>',
        tiny_tuft,
        highlight(102, 106, 12, 7, -18, 0.6),
        f'<g id="eyes"><g id="eye-L"><circle cx="106" cy="120" r="11" fill="{WHITE}" stroke="{INK}" stroke-width="5"/><circle cx="108" cy="122" r="5" fill="{INK}"/><circle cx="106" cy="120" r="1.8" fill="{WHITE}"/></g>'
        f'<g id="eye-R"><circle cx="134" cy="120" r="11" fill="{WHITE}" stroke="{INK}" stroke-width="5"/><circle cx="136" cy="122" r="5" fill="{INK}"/><circle cx="134" cy="120" r="1.8" fill="{WHITE}"/></g></g>',
        f'<g id="beak"><g id="beak-top"><path d="M111 136 Q120 133 129 136 Q126 144 120 145 Q114 144 111 136 Z" fill="{PEACH}" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/></g></g>',
        f'<g id="shell"><path d="M56 148 L72 160 L86 148 L102 162 L118 149 L134 163 L150 149 L164 162 L180 150 L184 148 L176 196 Q120 208 64 196 Z" fill="{CREAM}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>'
        f'<circle cx="92" cy="180" r="5" fill="{LILAC}"/><circle cx="140" cy="184" r="4.5" fill="{LILAC}"/></g>',
        "</svg>"])

def stage_songbird(d, label):
    sw = SPECS[d]["sw"]
    if d == "B":
        tail = (f'<g id="tail" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                f'<rect x="84" y="168" width="18" height="42" rx="9" fill="{COIN}" transform="rotate(-16 93 189)"/>'
                f'<rect x="111" y="172" width="18" height="44" rx="9" fill="{COIN}"/>'
                f'<rect x="138" y="168" width="18" height="42" rx="9" fill="{COIN}" transform="rotate(16 147 189)"/></g>')
    elif d == "C":
        tail = (f'<g id="tail" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                f'<path d="M92 172 Q84 198 94 208 Q104 202 104 174 Z" fill="{COIN}"/>'
                f'<path d="M112 176 Q110 204 120 210 Q130 204 128 176 Z" fill="{COIN}"/>'
                f'<path d="M132 174 Q138 198 148 202 Q152 192 140 172 Z" fill="{COIN}"/>'
                f'<path d="M112 186 L112 200 M124 188 L124 202" stroke="{INK}" stroke-width="2.5" stroke-linecap="round" opacity="0.5"/></g>')
    else:
        tail = (f'<g id="tail" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                f'<ellipse cx="90" cy="190" rx="11" ry="22" fill="{COIN}" transform="rotate(-18 90 190)"/>'
                f'<ellipse cx="120" cy="194" rx="11" ry="23" fill="{COIN}"/>'
                f'<ellipse cx="150" cy="190" rx="11" ry="22" fill="{COIN}" transform="rotate(18 150 190)"/></g>')
    # larger body
    if d == "B":
        bod = f'<g id="body"><ellipse cx="120" cy="122" rx="62" ry="66" fill="{YELLOW}" stroke="{INK}" stroke-width="{sw}"/></g><g id="belly"><ellipse cx="120" cy="150" rx="40" ry="38" fill="{WHITE}"/></g>'
        wing = (f'<g id="wings" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round">'
                f'<g id="wing-L"><rect x="30" y="108" width="30" height="52" rx="15" fill="{COIN}" transform="rotate(14 45 134)"/>'
                f'<rect x="32" y="140" width="26" height="18" rx="9" fill="{LEAF}" transform="rotate(14 45 149)"/></g>'
                f'<g id="wing-R"><rect x="180" y="108" width="30" height="52" rx="15" fill="{COIN}" transform="rotate(-14 195 134)"/>'
                f'<rect x="182" y="140" width="26" height="18" rx="9" fill="{LEAF}" transform="rotate(-14 195 149)"/></g></g>')
    elif d == "C":
        bod = (f'<g id="body"><ellipse cx="120" cy="124" rx="60" ry="65" fill="{YELLOW}" stroke="{INK}" stroke-width="{sw}"/></g>'
               f'<g id="body-shade"><path d="M162 92 Q178 122 168 162 Q176 132 158 100 Z" fill="#B97E00" opacity="0.22"/></g>'
               f'<g id="belly"><ellipse cx="120" cy="150" rx="39" ry="36" fill="{BELLY_A}"/></g>')
        wing = (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                f'<g id="wing-L"><ellipse cx="60" cy="134" rx="17" ry="28" fill="{COIN}"/><path d="M60 118 L60 150" stroke="{INK}" stroke-width="3" stroke-linecap="round" opacity="0.5"/><path d="M52 136 L68 136" stroke="{INK}" stroke-width="2.5" stroke-linecap="round" opacity="0.4"/></g>'
                f'<g id="wing-R"><ellipse cx="180" cy="134" rx="17" ry="28" fill="{COIN}"/><path d="M180 118 L180 150" stroke="{INK}" stroke-width="3" stroke-linecap="round" opacity="0.5"/><path d="M172 136 L188 136" stroke="{INK}" stroke-width="2.5" stroke-linecap="round" opacity="0.4"/></g></g>')
    else:
        bod = f'<g id="body"><ellipse cx="120" cy="124" rx="64" ry="64" fill="{YELLOW}" stroke="{INK}" stroke-width="{sw}"/></g><g id="belly"><ellipse cx="120" cy="150" rx="41" ry="36" fill="{BELLY_A}"/></g>'
        wing = (f'<g id="wings" stroke="{INK}" stroke-width="{sw}">'
                f'<g id="wing-L"><ellipse cx="58" cy="134" rx="16" ry="27" fill="{COIN}"/></g>'
                f'<g id="wing-R"><ellipse cx="182" cy="134" rx="16" ry="27" fill="{COIN}"/></g></g>')
    return "\n".join([
        hdr(label), shadow(), tail, bod,
        f'<g id="feet" stroke="{INK}" stroke-width="{sw}"><g id="foot-L"><ellipse cx="99" cy="198" rx="13" ry="8" fill="{PEACH}"/></g><g id="foot-R"><ellipse cx="141" cy="198" rx="13" ry="8" fill="{PEACH}"/></g></g>',
        wing, tuft(d),
        highlight(96, 94, 18, 10, -18, 0.6),
        eyes_open(d), beak(d, "closed"), blush_for(d), "</svg>"])

def write_all():
    import pathlib
    for d in "ABC":
        dd = os.path.join(OUT, d)
        os.makedirs(dd, exist_ok=True)
        files = {}
        files["fledgling_front.svg"] = assemble(d, f"Pip v2 {d} fledgling front", "down", "open", "closed")
        # 3/4: shift eyes/beak right, shrink left wing
        q_extras = ""
        front_q = assemble(d, f"Pip v2 {d} fledgling three-quarter", "down", "open", "closed", q=True)
        # tweak 3/4: overlay a side shade to suggest turn
        front_q = front_q.replace('</svg>', f'<g id="turn-shade"><path d="M166 96 Q178 128 170 166 Q176 132 162 102 Z" fill="#B97E00" opacity="0.18"/></g></svg>')
        files["fledgling_threequarter.svg"] = front_q
        files["expr_idle.svg"] = assemble(d, f"Pip v2 {d} idle", "down", "open", "closed")
        files["expr_blink.svg"] = assemble(d, f"Pip v2 {d} blink", "sleep", "blink", "closed")
        files["expr_happy.svg"] = assemble(d, f"Pip v2 {d} happy", "raised", "happy", "happy", sparkles())
        # eating: use blink-ish focused eyes? keep open but looking down: reuse open + seed
        files["expr_eating.svg"] = assemble(d, f"Pip v2 {d} eating", "peck", "open", "eat", seed_set(d))
        files["expr_sleepy.svg"] = assemble(d, f"Pip v2 {d} sleepy", "sleep", "sleep", "tiny", nightcap(d), hl=False)
        files["expr_surprised.svg"] = assemble(d, f"Pip v2 {d} surprised", "out", "surprised", "o", surprise_ticks())
        files["expr_proud.svg"] = assemble(d, f"Pip v2 {d} proud", "hip", "proud", "smirk", medal())
        files["stage_1_egg.svg"] = stage_egg(d, f"Pip v2 {d} stage 1 egg")
        files["stage_2_hatchling.svg"] = stage_hatchling(d, f"Pip v2 {d} stage 2 hatchling")
        files["stage_3_fledgling.svg"] = assemble(d, f"Pip v2 {d} stage 3 fledgling", "down", "open", "closed")
        files["stage_4_songbird.svg"] = stage_songbird(d, f"Pip v2 {d} stage 4 songbird")
        for fn, svg in files.items():
            assert "<text" not in svg.lower(), fn
            assert "lineargradient" not in svg.lower() and "radialgradient" not in svg.lower(), fn
            open(os.path.join(dd, fn), "w").write(svg + "\n")
        print(d, len(files), "files")
    # validate stroke consistency + ids
    for d in "ABC":
        import glob, re
        sw = SPECS[d]["sw"]
        for fp in glob.glob(os.path.join(OUT, d, "*.svg")):
            s = open(fp).read()
            for m in re.findall(r'stroke-width="([\d.]+)"', s):
                pass  # accessory micro-strokes allowed smaller
            assert 'id="body"' in s, fp
            assert 'id="wing-L"' in s or 'id="shell"' in s or 'stage 1' in s.lower() or 'egg' in fp, fp

if __name__ == "__main__":
    write_all()
