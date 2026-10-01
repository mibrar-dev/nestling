/* ==========================================================================
   Pip v2 · Bolt — key-pose library
   Every mood is full-body acting. Contract beats are respected:
     happy  = anticipation squash → jump (≥18px) → apex → land squash
     eating = seed in → 3 pecks + cheek puff + crumbs → satisfied
     sleepy = droop → nod → deep slow breathing + Zzz
     surprise = jolt → jump-back → hold → settle
     proud  = chest out + chin up → wing on hip → wink + chest sparkle
   Egg adaptations per contract: happy hop/wobble, eating = peek & nibble,
   sleepy = slow rock + Zzz, surprised = jolt + crack widens, proud = shine sweep.
   ========================================================================== */

const HOP = { 2: 20, 3: 26, 4: 28 };   // apex lift in px (contract: ≥18)

/* helper: mirrored wing pair from a single spec */
const W = (rot, dy = 0, dx = 0, extra = {}) => ({
  wingL: { rot, dy, dx, ...extra }, wingR: { rot: -rot, dy, dx, ...extra },
});

/* ───────────────────────── stage 1 · EGG ───────────────────────── */
const EGG = {
  idle: [
    { note: 'rest', eyeL: 'open', eyeR: 'open', fx: [] },
    { note: 'breathe in', bodySy: 1.035, bodyDy: -2, headDy: -1, tuftLift: 1.04 },
    { note: 'rock + tuft sway', bodyRot: -3, bodySy: 0.98, bodyDy: 2, headRot: -2, tuftLean: -5, crackOpen: 1.5 },
  ],
  blink: [
    { note: 'eyes open', eyeL: 'open', eyeR: 'open' },
    { note: 'closed (2 frames)', eyeL: 'closed', eyeR: 'closed', bodySy: 1.02 },
    { note: 'reopen', eyeL: 'open', eyeR: 'open', eyeSy: 0.55 },
  ],
  happy: [
    { note: 'anticipation squash', bodySy: 0.88, bodyDy: 6, shadowSx: 1.12, tuftLift: 0.9 },
    { note: 'hop up', bodySy: 1.04, bodyDy: -20, shadowSx: 0.58, crackOpen: -2,
      fx: [{ t: 'sparkle', x: 62, y: 96, s: 11 }, { t: 'sparkle', x: 180, y: 78, s: 9 }] },
    { note: 'apex + sparkle burst', bodySy: 0.97, bodyDy: -24, bodyRot: 3, shadowSx: 0.5, crackOpen: -3,
      fx: [{ t: 'sparkle', x: 52, y: 74, s: 13 }, { t: 'sparkle', x: 188, y: 58, s: 12 },
        { t: 'sparkle', x: 118, y: 40, s: 8 }, { t: 'dot', x: 38, y: 110, s: 3.4 }] },
    { note: 'land + wobble', bodySy: 0.84, bodyDy: 10, bodyRot: -6, shadowSx: 1.18,
      fx: [{ t: 'dot', x: 46, y: 206, s: 3.4 }, { t: 'dot', x: 196, y: 208, s: 3 }] },
  ],
  eating: [
    { note: 'seed falls in', crackOpen: 3, headDy: -3, beak: 'thin', gaze: { dy: -1 },
      fx: [{ t: 'seed', x: 120, y: 118, s: 8 }] },
    { note: 'nibble 1', crackOpen: 8, beak: 'thin', beakDy: -3, eyeSy: 0.9,
      fx: [{ t: 'crumb', x: 104, y: 172, s: 3.4 }, { t: 'crumb', x: 136, y: 168, s: 3 }] },
    { note: 'nibble 2 — crumbs fly', crackOpen: 12, beak: 'thin', beakDy: -4, eyeSy: 0.8, headRot: 3,
      fx: [{ t: 'crumb', x: 86, y: 160, s: 3.8 }, { t: 'crumb', x: 152, y: 154, s: 3.2 },
        { t: 'crumb', x: 128, y: 178, s: 3 }, { t: 'crumb', x: 108, y: 150, s: 2.6 }] },
    { note: 'swallow', crackOpen: 6, eyeL: 'happy', eyeR: 'happy',
      fx: [{ t: 'crumb', x: 112, y: 190, s: 3 }, { t: 'crumb', x: 130, y: 196, s: 2.8 }] },
    { note: 'satisfied', crackOpen: 0, eyeL: 'happy', eyeR: 'happy',
      fx: [{ t: 'sparkle', x: 176, y: 84, s: 10 }] },
  ],
  sleepy: [
    { note: 'lids droop', eyeL: 'sleepy', eyeR: 'sleepy', bodyRot: 3, bodyDy: 3, tuftLift: 0.9 },
    { note: 'slow rock back', eyeL: 'sleepy', eyeR: 'sleepy', bodyRot: -3, bodySy: 1.04, bodyDy: -1, tuftLean: 5,
      fx: [{ t: 'z', x: 168, y: 104, s: 13, sw: 4.4 }] },
    { note: 'asleep', eyeL: 'closed', eyeR: 'closed', bodyRot: 4, bodySy: 1.07, bodyDy: 5, tuftLift: 0.82, tuftLean: 7,
      fx: [{ t: 'z', x: 172, y: 86, s: 17, sw: 4.8 }, { t: 'z', x: 196, y: 58, s: 21, sw: 5 }] },
    { note: 'deep breathing', eyeL: 'closed', eyeR: 'closed', bodyRot: -2, bodySy: 1.1, bodyDy: 7, tuftLean: -4,
      fx: [{ t: 'z', x: 176, y: 96, s: 15, sw: 4.6 }, { t: 'z', x: 202, y: 62, s: 23, sw: 5.2 }] },
  ],
  surprised: [
    { note: 'jolt', bodySy: 1.13, bodyDy: -6, crackOpen: 4, tuftLift: 1.3, tuftSpread: 1.1 },
    { note: 'shock — crack widens', bodySy: 1.06, bodyDy: -14, crackOpen: 15, tuftLift: 1.36,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', shadowSx: 0.8,
      fx: [{ t: 'bang', x: 192, y: 66, s: 26 }] },
    { note: 'held', bodySy: 1.02, bodyDy: -19, crackOpen: 20, tuftLift: 1.4,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', shadowSx: 0.68,
      fx: [{ t: 'bang', x: 194, y: 62, s: 32 }, { t: 'motion', x: 40, y: 150, rot: 74, len: 20, sw: 5 }] },
    { note: 'settle', bodySy: 1.04, bodyDy: -6, crackOpen: 11, eyeL: 'surprised', eyeR: 'surprised',
      beak: 'o', beakSx: 0.9, shadowSx: 0.95, fx: [{ t: 'bang', x: 190, y: 74, s: 20 }] },
  ],
  proud: [
    { note: 'rise up', bodySy: 1.05, bodyDy: -5, shadowSx: 0.85 },
    { note: 'shine sweep', bodySy: 1.07, bodyDy: -8, shadowSx: 0.74,
      fx: [{ t: 'sweep', x: 112, y: 112, len: 34, w: 9, rot: 32 }, { t: 'sweep', x: 138, y: 146, len: 24, w: 7, rot: 32 }] },
    { note: 'hold + sparkle', bodySy: 1.04, bodyDy: -6, shadowSx: 0.8, tuftLean: -4,
      fx: [{ t: 'sparkle', x: 186, y: 70, s: 12 }, { t: 'sweep', x: 118, y: 124, len: 30, w: 8, rot: 32 }] },
    { note: 'shine sweep again', bodySy: 1.03, bodyDy: -6, shadowSx: 0.82, tuftLean: -3,
      fx: [{ t: 'sweep', x: 122, y: 136, len: 26, w: 7, rot: 32 }, { t: 'sparkle', x: 58, y: 96, s: 9 }] },
    { note: 'settle, still glossy', bodySy: 1.01, bodyDy: -3, shadowSx: 0.92,
      fx: [{ t: 'sparkle', x: 182, y: 82, s: 8 }] },
  ],
};

/* ─────────────────────── stage 2 · HATCHLING ─────────────────────── */
const HATCH = {
  idle: [
    { note: 'rest' },
    { note: 'breathe in', bodySy: 1.04, bodyDy: -2, headDy: -2, tuftLean: 4 },
    { note: 'head tilt', headRot: -6, headDx: -2, tuftLean: -5, shellHatRot: 3 },
  ],
  blink: [
    { note: 'eyes open' },
    { note: 'closed (2 frames)', eyeL: 'closed', eyeR: 'closed', bodySy: 1.02 },
    { note: 'reopen', eyeSy: 0.55 },
  ],
  happy: [
    { note: 'anticipation squash', bodySy: 0.87, bodyDy: 7, shadowSx: 1.1, tuftLift: 0.9,
      ...W(24, 6) },
    { note: 'jump + wings up', bodySy: 1.09, bodyDy: -HOP[2], shadowSx: 0.6, tuftLift: 1.2,
      eyeL: 'happy', eyeR: 'happy', beak: 'open', ...W(66, -13, 5),
      fx: [{ t: 'sparkle', x: 58, y: 92, s: 11 }, { t: 'sparkle', x: 184, y: 74, s: 9 }] },
    { note: 'apex', bodySy: 1.03, bodyDy: -HOP[2] - 4, bodyRot: -3, shadowSx: 0.52, tuftLift: 1.26, tuftLean: -6,
      eyeL: 'happy', eyeR: 'happy', beak: 'wide', ...W(72, -16, 6),
      fx: [{ t: 'sparkle', x: 48, y: 66, s: 13 }, { t: 'sparkle', x: 194, y: 52, s: 12 },
        { t: 'heart', x: 120, y: 34, s: 11 }, { t: 'dot', x: 34, y: 108, s: 3.4 }] },
    { note: 'land squash', bodySy: 0.84, bodyDy: 10, shadowSx: 1.16, ...W(58, 6, 2),
      fx: [{ t: 'dot', x: 44, y: 208, s: 3.4 }, { t: 'dot', x: 198, y: 210, s: 3 }] },
  ],
  eating: [
    { note: 'seed falls in', headDy: -5, beak: 'thin', gaze: { dy: -1 }, tuftLift: 1.06,
      fx: [{ t: 'seed', x: 120, y: 112, s: 8 }] },
    { note: 'dip', headRot: 15, headDy: 4, beak: 'thin', eyeSy: 0.82, gaze: { dy: 1 } },
    { note: 'peck 1', headRot: 21, headDy: 8, beak: 'thin', beakDy: 3, cheekPuff: 1.5, eyeSy: 0.7,
      fx: [{ t: 'crumb', x: 96, y: 168, s: 3.6 }, { t: 'crumb', x: 146, y: 162, s: 3 }] },
    { note: 'peck 2 + crumbs', headRot: 19, headDy: 9, beak: 'thin', beakDy: 2, cheekPuff: 1.75,
      fx: [{ t: 'crumb', x: 82, y: 152, s: 4 }, { t: 'crumb', x: 156, y: 148, s: 3.2 },
        { t: 'crumb', x: 122, y: 178, s: 3.2 }, { t: 'crumb', x: 104, y: 142, s: 2.6 }] },
    { note: 'peck 3 — satisfied', headRot: 0, headDy: 0, cheekPuff: 1, eyeL: 'happy', eyeR: 'happy',
      fx: [{ t: 'crumb', x: 114, y: 190, s: 3 }, { t: 'sparkle', x: 178, y: 84, s: 10 }] },
  ],
  sleepy: [
    { note: 'lids droop', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 8, bodySy: 1.03 },
    { note: 'nod', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 15, headDy: 5, bodySy: 1.05, eyeSy: 0.8, tuftLean: 5,
      fx: [{ t: 'z', x: 168, y: 106, s: 13, sw: 4.4 }] },
    { note: 'asleep', eyeL: 'closed', eyeR: 'closed', headRot: 20, headDy: 8, bodySy: 1.07,
      tuftLift: 0.84, tuftLean: 8, ...W(-14, 8), fx: [{ t: 'z', x: 174, y: 84, s: 17, sw: 4.8 }, { t: 'z', x: 198, y: 54, s: 21, sw: 5 }] },
    { note: 'deep breathing', eyeL: 'closed', eyeR: 'closed', headRot: 23, headDy: 11, bodySy: 1.1,
      tuftLean: 10, ...W(-20, 12), fx: [{ t: 'z', x: 178, y: 94, s: 15, sw: 4.6 }, { t: 'z', x: 204, y: 58, s: 23, sw: 5.2 }] },
  ],
  surprised: [
    { note: 'jolt', bodySy: 1.13, bodyDy: -5, tuftLift: 1.34, tuftSpread: 1.12,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'thin', ...W(42, -4) },
    { note: 'jump back', bodySy: 1.07, bodyDy: -16, shadowSx: 0.74, tuftLift: 1.38,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', ...W(74, -10),
      fx: [{ t: 'bang', x: 192, y: 62, s: 27 }] },
    { note: 'held', bodySy: 1.03, bodyDy: -21, shadowSx: 0.64, tuftLift: 1.42, tuftSpread: 1.14,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', ...W(88, -14),
      fx: [{ t: 'bang', x: 194, y: 56, s: 33 }, { t: 'motion', x: 34, y: 140, rot: 72, len: 22, sw: 5 }] },
    { note: 'settle', bodySy: 1.05, bodyDy: -6, eyeL: 'surprised', eyeR: 'surprised', beak: 'o', beakSx: 0.92,
      ...W(54, -6), fx: [{ t: 'bang', x: 190, y: 70, s: 21 }] },
  ],
  proud: [
    { note: 'chest out + chin up', bodySy: 1.03, bodyDy: -4, headRot: -8, headDy: -6, beak: 'thin',
      tuftLean: -5, shellHatRot: 14, ...W(-16, -4) },
    { note: 'wings on hips', bodySy: 1.04, bodyDy: -5, headRot: -9, headDy: -8,
      eyeL: 'wink', eyeR: 'open', browL: 1, browR: 1, beak: 'thin', tuftLean: -6, shellHatRot: 14,
      wingL: { rot: -44, dy: 20 }, wingR: { rot: 44, dy: 20 },
      fx: [{ t: 'sparkle', x: 112, y: 172, s: 9 }] },
    { note: 'hold', bodySy: 1.02, bodyDy: -3, headRot: -7, headDy: -6, eyeL: 'wink', eyeR: 'open',
      beak: 'thin', tuftLean: -3, shellHatRot: 12,
      wingL: { rot: -42, dy: 20 }, wingR: { rot: 42, dy: 20 },
      fx: [{ t: 'sparkle', x: 108, y: 168, s: 7 }] },
    { note: 're-puff the chest', bodySy: 1.06, bodyDy: -7, headRot: -10, headDy: -9,
      eyeL: 'open', eyeR: 'open', browL: 1, browR: 1, beak: 'thin', tuftLean: -8, shellHatRot: 15,
      wingL: { rot: -46, dy: 22 }, wingR: { rot: 46, dy: 22 },
      fx: [{ t: 'sparkle', x: 116, y: 174, s: 9 }] },
    { note: 'settle, still smug', bodySy: 1.01, bodyDy: -3, headRot: -7, headDy: -6,
      eyeL: 'open', eyeR: 'open', beak: 'thin', tuftLean: -3, shellHatRot: 11,
      wingL: { rot: -40, dy: 20 }, wingR: { rot: 40, dy: 20 },
      fx: [{ t: 'sparkle', x: 108, y: 168, s: 7 }] },
  ],
};

/* ─────────────────────── stage 3 · FLEDGLING ─────────────────────── */
const FLEDG = {
  idle: [
    { note: 'rest' },
    { note: 'breathe in (1.04)', bodySy: 1.04, bodyDy: -3, headDy: -2, tuftLean: 4 },
    { note: 'head tilt + tuft sway', headRot: -6, headDx: -2, tuftLean: -6, bodySy: 0.99 },
  ],
  blink: [
    { note: 'eyes open' },
    { note: 'closed (2 frames)', eyeL: 'closed', eyeR: 'closed', bodySy: 1.02 },
    { note: 'reopen', eyeSy: 0.55 },
  ],
  happy: [
    { note: 'anticipation squash', bodySy: 0.85, bodyDy: 8, shadowSx: 1.12, tuftLift: 0.88, ...W(26, 8) },
    { note: 'jump ≥18px, wings fully up', bodySy: 1.1, bodyDy: -HOP[3], shadowSx: 0.58, tuftLift: 1.2,
      eyeL: 'happy', eyeR: 'happy', beak: 'open', tail: { spread: 40 }, ...W(68, -24, 6),
      fx: [{ t: 'sparkle', x: 54, y: 96, s: 11 }, { t: 'sparkle', x: 186, y: 76, s: 9 }] },
    { note: 'apex + sparkle burst', bodySy: 1.04, bodyDy: -HOP[3] - 4, bodyRot: -4, shadowSx: 0.5,
      tuftLift: 1.28, tuftLean: -7, eyeL: 'happy', eyeR: 'happy', beak: 'wide', tail: { spread: 48 },
      ...W(74, -28, 7),
      fx: [{ t: 'sparkle', x: 44, y: 64, s: 14 }, { t: 'sparkle', x: 196, y: 50, s: 12 },
        { t: 'sparkle', x: 120, y: 30, s: 9 }, { t: 'dot', x: 30, y: 104, s: 3.6 }, { t: 'dot', x: 212, y: 96, s: 3 }] },
    { note: 'land squash', bodySy: 0.8, bodyDy: 11, shadowSx: 1.18, tuftLift: 0.9,
      eyeL: 'happy', eyeR: 'happy', ...W(62, 6, 2),
      fx: [{ t: 'dot', x: 40, y: 210, s: 3.6 }, { t: 'dot', x: 202, y: 212, s: 3.2 }, { t: 'motion', x: 62, y: 196, rot: 8, len: 22, sw: 5 }] },
  ],
  eating: [
    { note: 'seed falls in', headDy: -6, beak: 'thin', gaze: { dy: -1 }, tuftLift: 1.06,
      fx: [{ t: 'seed', x: 120, y: 112, s: 8.5 }] },
    { note: 'head dips', headRot: 16, headDy: 4, beak: 'thin', eyeSy: 0.82, gaze: { dy: 1 }, tuftLean: 5 },
    { note: 'peck 1', headRot: 22, headDy: 9, beak: 'thin', beakDy: 3, cheekPuff: 1.5, eyeSy: 0.68,
      fx: [{ t: 'crumb', x: 90, y: 176, s: 3.8 }, { t: 'crumb', x: 152, y: 168, s: 3.2 }] },
    { note: 'peck 2 + crumbs fly', headRot: 20, headDy: 10, beak: 'thin', beakDy: 2, cheekPuff: 1.8,
      bodyRot: -3, tuftLean: 7,
      fx: [{ t: 'crumb', x: 74, y: 158, s: 4.2 }, { t: 'crumb', x: 164, y: 152, s: 3.4 },
        { t: 'crumb', x: 120, y: 186, s: 3.4 }, { t: 'crumb', x: 100, y: 146, s: 2.8 }] },
    { note: 'peck 3 — satisfied ^^', headRot: 0, headDy: 0, cheekPuff: 1, eyeL: 'happy', eyeR: 'happy',
      bodyRot: 0,
      fx: [{ t: 'crumb', x: 110, y: 198, s: 3 }, { t: 'crumb', x: 134, y: 204, s: 2.8 },
        { t: 'sparkle', x: 182, y: 82, s: 11 }] },
  ],
  sleepy: [
    { note: 'lids droop', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 8, bodySy: 1.03 },
    { note: 'head nods', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 15, headDy: 5, bodySy: 1.05, eyeSy: 0.8, tuftLean: 6,
      fx: [{ t: 'z', x: 168, y: 104, s: 14, sw: 4.6 }] },
    { note: 'asleep — head droops', eyeL: 'closed', eyeR: 'closed', headRot: 21, headDy: 9, bodySy: 1.07,
      tuftLift: 0.84, tuftLean: 9, ...W(-16, 10),
      fx: [{ t: 'z', x: 174, y: 82, s: 18, sw: 5 }, { t: 'z', x: 200, y: 50, s: 22, sw: 5.2 }] },
    { note: 'deep slow breathing', eyeL: 'closed', eyeR: 'closed', headRot: 24, headDy: 12, bodySy: 1.1,
      tuftLean: 12, ...W(-22, 14),
      fx: [{ t: 'z', x: 178, y: 92, s: 16, sw: 4.8 }, { t: 'z', x: 206, y: 54, s: 24, sw: 5.4 }] },
  ],
  surprised: [
    { note: 'jolt', bodySy: 1.13, bodyDy: -6, tuftLift: 1.34, tuftSpread: 1.12, shadowSx: 0.9,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'thin', ...W(44, -6) },
    { note: 'jump back', bodySy: 1.07, bodyDy: -18, shadowSx: 0.74, tuftLift: 1.38, tuftSpread: 1.14,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', tail: { spread: 48 }, ...W(78, -12),
      fx: [{ t: 'bang', x: 192, y: 58, s: 28 }] },
    { note: 'held — wings flare', bodySy: 1.02, bodyDy: -23, shadowSx: 0.62, tuftLift: 1.44, tuftSpread: 1.16,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', beakSx: 1.06, tail: { spread: 54 }, ...W(94, -16),
      fx: [{ t: 'bang', x: 194, y: 50, s: 34 },
        { t: 'motion', x: 30, y: 128, rot: 70, len: 24, sw: 5 }, { t: 'motion', x: 30, y: 164, rot: 70, len: 18, sw: 4.4 }] },
    { note: 'settle', bodySy: 1.05, bodyDy: -7, eyeL: 'surprised', eyeR: 'surprised', beak: 'o', beakSx: 0.94,
      shadowSx: 0.95, ...W(56, -6), fx: [{ t: 'bang', x: 190, y: 66, s: 22 }] },
  ],
  proud: [
    { note: 'chest out + chin up', bodySy: 1.03, bodyDy: -4, headRot: -8, headDy: -7, beak: 'thin',
      tuftLean: -5, tail: { spread: 34 }, ...W(-18, -6) },
    { note: 'both wings on hips + wink', bodySy: 1.04, bodyDy: -5, headRot: -10, headDy: -9,
      eyeL: 'wink', eyeR: 'open', browL: 1, browR: 1, beak: 'thin', tuftLean: -7, tail: { spread: 34 },
      wingL: { rot: -46, dy: 24 }, wingR: { rot: 46, dy: 24 },
      fx: [{ t: 'sparkle', x: 112, y: 176, s: 10 }] },
    { note: 'hold', bodySy: 1.02, bodyDy: -3, headRot: -8, headDy: -7, eyeL: 'wink', eyeR: 'open',
      beak: 'thin', tuftLean: -4, tail: { spread: 32 },
      wingL: { rot: -44, dy: 24 }, wingR: { rot: 44, dy: 24 },
      fx: [{ t: 'sparkle', x: 108, y: 172, s: 8 }, { t: 'dot', x: 186, y: 96, s: 3 }] },
    { note: 're-puff the chest', bodySy: 1.06, bodyDy: -7, headRot: -11, headDy: -10,
      eyeL: 'open', eyeR: 'open', browL: 1, browR: 1, beak: 'thin', tuftLean: -8, tail: { spread: 36 },
      wingL: { rot: -50, dy: 26 }, wingR: { rot: 50, dy: 26 },
      fx: [{ t: 'sparkle', x: 116, y: 178, s: 9 }, { t: 'sparkle', x: 180, y: 104, s: 7 }] },
    { note: 'settle, still smug', bodySy: 1.01, bodyDy: -3, headRot: -7, headDy: -6,
      eyeL: 'open', eyeR: 'open', beak: 'thin', tuftLean: -3, tail: { spread: 32 },
      wingL: { rot: -42, dy: 24 }, wingR: { rot: 42, dy: 24 },
      fx: [{ t: 'sparkle', x: 108, y: 172, s: 7 }] },
  ],
};

/* ──────────────────────── stage 4 · SONGBIRD ─────────────────────── */
const SONG = {
  idle: [
    { note: 'rest' },
    { note: 'breathe in', bodySy: 1.04, bodyDy: -3, headDy: -2, tuftLean: 4, tail: { rot: -3 } },
    { note: 'head tilt + tail sway', headRot: -6, headDx: -2, tuftLean: -6, tail: { rot: 4, spread: 36 } },
  ],
  blink: [
    { note: 'eyes open' },
    { note: 'closed (2 frames)', eyeL: 'closed', eyeR: 'closed', bodySy: 1.02 },
    { note: 'reopen', eyeSy: 0.55 },
  ],
  happy: [
    { note: 'anticipation squash', bodySy: 0.85, bodyDy: 9, shadowSx: 1.12, tuftLift: 0.88, tail: { spread: 40 }, ...W(28, 9) },
    { note: 'jump ≥18px, wings up', bodySy: 1.1, bodyDy: -HOP[4], shadowSx: 0.56, tuftLift: 1.2,
      eyeL: 'happy', eyeR: 'happy', beak: 'open', tail: { spread: 46 }, ...W(66, -26, 8),
      fx: [{ t: 'sparkle', x: 48, y: 92, s: 12 }, { t: 'sparkle', x: 192, y: 70, s: 10 }] },
    { note: 'apex + sparkle burst', bodySy: 1.04, bodyDy: -HOP[4] - 5, bodyRot: -4, shadowSx: 0.48,
      tuftLift: 1.28, tuftLean: -7, eyeL: 'happy', eyeR: 'happy', beak: 'wide', tail: { spread: 56 },
      ...W(72, -30, 9),
      fx: [{ t: 'sparkle', x: 38, y: 58, s: 15 }, { t: 'sparkle', x: 202, y: 44, s: 13 },
        { t: 'sparkle', x: 120, y: 24, s: 10 }, { t: 'dot', x: 24, y: 100, s: 3.6 }, { t: 'dot', x: 218, y: 92, s: 3.2 }] },
    { note: 'land squash', bodySy: 0.79, bodyDy: 12, shadowSx: 1.2, tuftLift: 0.9,
      eyeL: 'happy', eyeR: 'happy', tail: { spread: 44 }, ...W(60, 8, 2),
      fx: [{ t: 'dot', x: 36, y: 212, s: 3.6 }, { t: 'dot', x: 206, y: 214, s: 3.2 },
        { t: 'motion', x: 58, y: 200, rot: 8, len: 24, sw: 5 }] },
  ],
  eating: [
    { note: 'seed falls in', headDy: -7, beak: 'thin', gaze: { dy: -1 }, tuftLift: 1.06,
      fx: [{ t: 'seed', x: 120, y: 108, s: 9 }] },
    { note: 'head dips', headRot: 17, headDy: 5, beak: 'thin', eyeSy: 0.82, gaze: { dy: 1 }, tuftLean: 5 },
    { note: 'peck 1', headRot: 24, headDy: 10, beak: 'thin', beakDy: 3, cheekPuff: 1.5, eyeSy: 0.68,
      fx: [{ t: 'crumb', x: 86, y: 178, s: 4 }, { t: 'crumb', x: 154, y: 170, s: 3.4 }] },
    { note: 'peck 2 + crumbs fly', headRot: 21, headDy: 11, beak: 'thin', beakDy: 2, cheekPuff: 1.8,
      bodyRot: -3, tuftLean: 7, tail: { spread: 44 },
      fx: [{ t: 'crumb', x: 68, y: 158, s: 4.4 }, { t: 'crumb', x: 170, y: 150, s: 3.6 },
        { t: 'crumb', x: 120, y: 190, s: 3.4 }, { t: 'crumb', x: 98, y: 144, s: 2.8 }] },
    { note: 'peck 3 — satisfied ^^', headRot: 0, headDy: 0, cheekPuff: 1, eyeL: 'happy', eyeR: 'happy',
      bodyRot: 0, tail: { spread: 40 },
      fx: [{ t: 'crumb', x: 108, y: 200, s: 3 }, { t: 'crumb', x: 136, y: 206, s: 2.8 },
        { t: 'sparkle', x: 186, y: 78, s: 11 }] },
  ],
  sleepy: [
    { note: 'lids droop', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 8, bodySy: 1.03 },
    { note: 'head nods', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 15, headDy: 6, bodySy: 1.05, eyeSy: 0.8, tuftLean: 6,
      fx: [{ t: 'z', x: 170, y: 100, s: 15, sw: 4.8 }] },
    { note: 'asleep — head droops', eyeL: 'closed', eyeR: 'closed', headRot: 22, headDy: 10, bodySy: 1.07,
      tuftLift: 0.84, tuftLean: 9, tail: { rot: -6 }, ...W(-16, 12),
      fx: [{ t: 'z', x: 176, y: 78, s: 19, sw: 5.2 }, { t: 'z', x: 204, y: 44, s: 23, sw: 5.4 }] },
    { note: 'deep slow breathing', eyeL: 'closed', eyeR: 'closed', headRot: 25, headDy: 13, bodySy: 1.1,
      tuftLean: 12, tail: { rot: -8 }, ...W(-22, 16),
      fx: [{ t: 'z', x: 180, y: 88, s: 17, sw: 5 }, { t: 'z', x: 210, y: 48, s: 25, sw: 5.6 }] },
  ],
  surprised: [
    { note: 'jolt', bodySy: 1.13, bodyDy: -7, tuftLift: 1.34, tuftSpread: 1.12, shadowSx: 0.9,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'thin', ...W(46, -6) },
    { note: 'jump back', bodySy: 1.07, bodyDy: -19, shadowSx: 0.72, tuftLift: 1.38, tuftSpread: 1.14,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', tail: { spread: 52 }, ...W(72, -14),
      fx: [{ t: 'bang', x: 194, y: 54, s: 29 }] },
    { note: 'held — wings flare wide', bodySy: 1.02, bodyDy: -24, shadowSx: 0.6, tuftLift: 1.46, tuftSpread: 1.18,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', beakSx: 1.08, tail: { spread: 58 }, ...W(92, -18),
      fx: [{ t: 'bang', x: 196, y: 44, s: 35 },
        { t: 'motion', x: 26, y: 124, rot: 70, len: 26, sw: 5 }, { t: 'motion', x: 26, y: 160, rot: 70, len: 20, sw: 4.4 }] },
    { note: 'settle', bodySy: 1.05, bodyDy: -8, eyeL: 'surprised', eyeR: 'surprised', beak: 'o', beakSx: 0.94,
      shadowSx: 0.95, ...W(52, -6), fx: [{ t: 'bang', x: 192, y: 62, s: 23 }] },
  ],
  proud: [
    { note: 'chest out + chin up', bodySy: 1.03, bodyDy: -5, headRot: -8, headDy: -8, beak: 'thin',
      tuftLean: -5, tail: { spread: 38 }, ...W(-20, -6) },
    { note: 'both wings on hips + wink', bodySy: 1.04, bodyDy: -6, headRot: -10, headDy: -10,
      eyeL: 'wink', eyeR: 'open', browL: 1, browR: 1, beak: 'thin', tuftLean: -7, tail: { spread: 38 },
      wingL: { rot: -48, dy: 26 }, wingR: { rot: 48, dy: 26 },
      fx: [{ t: 'sparkle', x: 112, y: 180, s: 10 }] },
    { note: 'hold', bodySy: 1.02, bodyDy: -4, headRot: -8, headDy: -8, eyeL: 'wink', eyeR: 'open',
      beak: 'thin', tuftLean: -4, tail: { spread: 36 },
      wingL: { rot: -46, dy: 26 }, wingR: { rot: 46, dy: 26 },
      fx: [{ t: 'sparkle', x: 108, y: 176, s: 8 }, { t: 'dot', x: 190, y: 92, s: 3 }] },
    { note: 're-puff the chest', bodySy: 1.06, bodyDy: -8, headRot: -11, headDy: -11,
      eyeL: 'open', eyeR: 'open', browL: 1, browR: 1, beak: 'thin', tuftLean: -8, tail: { spread: 40 },
      wingL: { rot: -52, dy: 28 }, wingR: { rot: 52, dy: 28 },
      fx: [{ t: 'sparkle', x: 116, y: 182, s: 9 }, { t: 'sparkle', x: 184, y: 100, s: 7 }] },
    { note: 'settle, still smug', bodySy: 1.01, bodyDy: -4, headRot: -7, headDy: -7,
      eyeL: 'open', eyeR: 'open', beak: 'thin', tuftLean: -3, tail: { spread: 36 },
      wingL: { rot: -44, dy: 26 }, wingR: { rot: 44, dy: 26 },
      fx: [{ t: 'sparkle', x: 108, y: 176, s: 7 }] },
  ],
};

const LIB = { 1: EGG, 2: HATCH, 3: FLEDG, 4: SONG };
export const MOODS = ['idle', 'blink', 'happy', 'eating', 'sleepy', 'surprised', 'proud'];

/** flat list of every key pose */
export function allPoses() {
  const out = [];
  for (const stage of [1, 2, 3, 4]) {
    for (const mood of MOODS) {
      (LIB[stage][mood] || []).forEach((p, i) => {
        out.push({ stage, mood, n: i + 1, skin: 'sunny', ...p });
      });
    }
  }
  return out;
}
export { LIB };
