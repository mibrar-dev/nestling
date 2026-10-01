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
    { note: 'rock + tuft sway', bodySy: 0.98, bodyDy: 2, headRot: -2, tuftLean: -5, crackOpen: 1.5 },
  ],
  blink: [
    { note: 'eyes open', eyeL: 'open', eyeR: 'open' },
    { note: 'closed (2 frames)', eyeL: 'closed', eyeR: 'closed' },
    { note: 'reopen', eyeL: 'open', eyeR: 'open' },
  ],
  happy: [
    { note: 'anticipation squash', bodySy: 0.88, bodyDy: 6, shadowSx: 1.12, tuftLift: 0.9 },
    { note: 'hop up', bodySy: 1.04, bodyDy: -20, shadowSx: 0.58, crackOpen: -2, eyeL: 'happy', eyeR: 'happy', beak: 'thin',
      fx: [{ t: 'sparkle', x: 62, y: 96, s: 11 }, { t: 'sparkle', x: 180, y: 78, s: 9 }] },
    { note: 'apex + sparkle burst', bodySy: 0.97, bodyDy: -24, shadowSx: 0.5, crackOpen: -3, eyeL: 'happy', eyeR: 'happy', beak: 'thin',
      fx: [{ t: 'sparkle', x: 52, y: 74, s: 13 }, { t: 'sparkle', x: 188, y: 58, s: 12 },
        { t: 'sparkle', x: 118, y: 40, s: 8 }, { t: 'dot', x: 38, y: 110, s: 4.2 }] },
    { note: 'land + wobble', bodySy: 0.84, bodyDy: 10, shadowSx: 1.18, eyeL: 'happy', eyeR: 'happy',
      fx: [{ t: 'dot', x: 46, y: 206, s: 4.2 }, { t: 'dot', x: 196, y: 208, s: 3 }] },
  ],
  eating: [
    { note: 'seed arrives at the crack', crackOpen: 4, headDy: -3, beak: 'thin', gaze: { dy: -1 },
      fx: [{ t: 'seed', x: 120, y: 118, s: 12 }] },
    { note: 'beak open, seed enters', crackOpen: 9, beak: 'open', beakDy: -4, gaze: { dy: -1 }, seed: 12 },
    { note: 'nibble — crumbs fly', crackOpen: 13, beak: 'thin', beakDy: -5, headRot: -2,
      fx: [{ t: 'crumb', x: 86, y: 168, s: 4 }, { t: 'crumb', x: 154, y: 162, s: 4.4 },
        { t: 'crumb', x: 128, y: 186, s: 3.2 }, { t: 'crumb', x: 106, y: 156, s: 2.8 }] },
    { note: 'nibble 2 — more crumbs', crackOpen: 13, beak: 'thin', beakDy: -5, headRot: -2,
      fx: [{ t: 'crumb', x: 72, y: 158, s: 4.2 }, { t: 'crumb', x: 168, y: 154, s: 5.4 },
        { t: 'crumb', x: 100, y: 192, s: 4.2 }, { t: 'crumb', x: 142, y: 194, s: 3.2 }] },
    { note: 'satisfied ^^', crackOpen: 4, eyeL: 'happy', eyeR: 'happy',
      fx: [{ t: 'crumb', x: 116, y: 200, s: 2.8 }, { t: 'sparkle', x: 180, y: 78, s: 10 }] },
  ],
  sleepy: [
    { note: 'lids droop', eyeL: 'sleepy', eyeR: 'sleepy', bodySy: 0.95, bodyDy: 4, tuftLift: 0.9, beak: 'snore' },
    { note: 'slow rock back', eyeL: 'sleepy', eyeR: 'sleepy', bodySy: 1.04, bodyDy: -1, tuftLean: 5,
      fx: [{ t: 'z', x: 168, y: 104, s: 13, sw: 4.4 }] },
    { note: 'asleep', eyeL: 'closed', eyeR: 'closed', bodySy: 1.07, bodyDy: 5, tuftLift: 0.82, tuftLean: 7,
      fx: [{ t: 'z', x: 172, y: 86, s: 17, sw: 4.8 }, { t: 'z', x: 196, y: 58, s: 21, sw: 5 }] },
    { note: 'deep breathing', eyeL: 'closed', eyeR: 'closed', bodySy: 1.1, bodyDy: 7, tuftLean: -4,
      fx: [{ t: 'z', x: 176, y: 96, s: 15, sw: 4.6 }, { t: 'z', x: 202, y: 62, s: 23, sw: 5.2 }] },
  ],
  surprised: [
    { note: 'jolt', bodySy: 1.13, bodyDy: -6, crackOpen: 4, tuftLift: 1.3, tuftSpread: 1.1 },
    { note: 'shock — crack widens', bodySy: 1.06, bodyDy: -14, crackOpen: 15,
      eyeL: 'surprised', eyeR: 'surprised', eyeScale: 0.8, beak: 'o', shadowSx: 0.8,
      fx: [{ t: 'bang', x: 192, y: 66, s: 26 }] },
    { note: 'held', bodySy: 1.02, bodyDy: -19, crackOpen: 20,
      eyeL: 'surprised', eyeR: 'surprised', eyeScale: 0.8, beak: 'o', shadowSx: 0.68,
      fx: [{ t: 'bang', x: 194, y: 62, s: 32 }, { t: 'motion', x: 40, y: 150, rot: 74, len: 20, sw: 5 }] },
    { note: 'settle', bodySy: 1.04, bodyDy: -6, crackOpen: 11, eyeL: 'surprised', eyeR: 'surprised',
      eyeScale: 0.85, beak: 'o', shadowSx: 0.95, fx: [{ t: 'bang', x: 190, y: 74, s: 20 }] },
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
    { note: 'head tilt', headRot: -2, tuftLean: -5, shellHatRot: 3 },
  ],
  blink: [
    { note: 'eyes open' },
    { note: 'closed (2 frames)', eyeL: 'closed', eyeR: 'closed' },
    { note: 'reopen — neutral idle' },
  ],
  happy: [
    { note: 'anticipation squash', bodySy: 0.87, bodyDy: 7, shadowSx: 1.1, tuftLift: 0.9,
      ...W(24, 6) },
    { note: 'jump + wings up', bodySy: 1.09, bodyDy: -HOP[2], shadowSx: 0.6, tuftLift: 1.05,
      eyeL: 'happy', eyeR: 'happy', beak: 'open', ...W(112, -13, 5),
      fx: [{ t: 'sparkle', x: 58, y: 92, s: 11 }, { t: 'sparkle', x: 184, y: 74, s: 9 }] },
    { note: 'apex', bodySy: 1.03, bodyDy: -HOP[2] - 4, shadowSx: 0.52, tuftLift: 1.08, tuftLean: -6,
      eyeL: 'happy', eyeR: 'happy', beak: 'wide', ...W(120, -16, 6),
      fx: [{ t: 'sparkle', x: 48, y: 66, s: 13 }, { t: 'sparkle', x: 194, y: 52, s: 12 },
        { t: 'heart', x: 42, y: 44, s: 11 }, { t: 'dot', x: 34, y: 108, s: 4.2 }] },
    { note: 'land squash', bodySy: 0.84, bodyDy: 10, shadowSx: 1.16, ...W(58, 6, 2),
      fx: [{ t: 'dot', x: 44, y: 208, s: 4.2 }, { t: 'dot', x: 198, y: 210, s: 3 }] },
  ],
  eating: [
    { note: 'seed approaches', headDy: -6, beak: 'thin', gaze: { dy: -1 }, tuftLift: 1.06,
      fx: [{ t: 'seed', x: 120, y: 110, s: 12 }] },
    { note: 'beak open, seed enters', headDy: -2, beak: 'open', gaze: { dy: -1 }, seed: 12 },
    { note: 'crunch 1 — crumbs fly', headRot: 2, headDy: 5, beak: 'thin', beakDy: 2,
      cheekPuff: 1.5, tuftLean: 5,
      fx: [{ t: 'crumb', x: 88, y: 164, s: 4 }, { t: 'crumb', x: 152, y: 158, s: 4.4 },
        { t: 'crumb', x: 120, y: 182, s: 3.2 }] },
    { note: 'crunch 2 — cheeks full', headRot: 2, headDy: 6, beak: 'thin', beakDy: 1,
      cheekPuff: 1.8,
      fx: [{ t: 'crumb', x: 74, y: 154, s: 4.2 }, { t: 'crumb', x: 166, y: 150, s: 5.4 },
        { t: 'crumb', x: 100, y: 188, s: 4.2 }, { t: 'crumb', x: 142, y: 192, s: 3.2 },
        { t: 'crumb', x: 122, y: 170, s: 2.8 }] },
    { note: 'swallow — satisfied', headRot: -2, headDy: 0, cheekPuff: 1, eyeL: 'happy', eyeR: 'happy',
      fx: [{ t: 'crumb', x: 114, y: 200, s: 2.8 }, { t: 'sparkle', x: 180, y: 80, s: 10 }] },
  ],
  sleepy: [
    { note: 'lids droop', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 2, bodySy: 0.97, bodyDy: 4, beak: 'snore', nightcap: 1 },
    { note: 'head nods, body slumps', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 2, headDy: 6, nightcap: 1,
      bodySy: 0.94, bodyDy: 6, beak: 'snore', tuftLean: 6,
      fx: [{ t: 'z', x: 188, y: 86, s: 14, sw: 4.6 }] },
    { note: 'asleep — head droops', eyeL: 'closed', eyeR: 'closed', headRot: 2, headDy: 11,
      bodySy: 0.93, bodyDy: 7, beak: 'snore', tuftLift: 0.84, tuftLean: 7, nightcap: 1,
      fx: [{ t: 'z', x: 174, y: 78, s: 18, sw: 5 }, { t: 'z', x: 200, y: 48, s: 22, sw: 5.2 }] },
    { note: 'deep slow breathing + snore', eyeL: 'closed', eyeR: 'closed', headRot: 2, headDy: 15,
      bodySy: 0.92, bodyDy: 8, beak: 'snore', tuftLean: 9, nightcap: 1,
      fx: [{ t: 'z', x: 178, y: 88, s: 16, sw: 4.8 }, { t: 'z', x: 204, y: 52, s: 24, sw: 5.4 }] },
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
    { note: 'settle', bodySy: 1.05, bodyDy: -6, eyeL: 'surprised', eyeR: 'surprised', beak: 'o',
      ...W(54, -6), fx: [{ t: 'bang', x: 190, y: 70, s: 21 }] },
  ],
  proud: [
    { note: 'chest out + chin up', bodySy: 1.03, bodyDy: -4, headRot: -2, headDy: -6, beak: 'thin',
      tuftLean: -5, shellHatRot: 14, ...W(-16, -4) },
    { note: 'wings on hips', bodySy: 1.04, bodyDy: -5, headRot: -2, headDy: -9,
      eyeL: 'wink', eyeR: 'open', brow: 1, beak: 'thin', tuftLean: -6, shellHatRot: 14,
      wingL: { rot: -44, dy: 20 }, wingR: { rot: 44, dy: 20 },
      fx: [{ t: 'sparkle', x: 112, y: 172, s: 9 }] },
    { note: 'hold', bodySy: 1.02, bodyDy: -3, headRot: -2, headDy: -6, eyeL: 'wink', eyeR: 'open',
      beak: 'thin', tuftLean: -3, shellHatRot: 12,
      wingL: { rot: -42, dy: 20 }, wingR: { rot: 42, dy: 20 },
      fx: [{ t: 'sparkle', x: 108, y: 168, s: 7 }] },
    { note: 're-puff the chest', bodySy: 1.06, bodyDy: -7, headRot: -2, headDy: -10,
      eyeL: 'open', eyeR: 'open', brow: 1, beak: 'thin', tuftLean: -8, shellHatRot: 15,
      wingL: { rot: -46, dy: 22 }, wingR: { rot: 46, dy: 22 },
      fx: [{ t: 'sparkle', x: 116, y: 174, s: 9 }] },
    { note: 'settle, still smug', bodySy: 1.01, bodyDy: -3, headRot: -2, headDy: -6,
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
    { note: 'head tilt + tuft sway', headRot: -2, tuftLean: -6, bodySy: 0.99 },
  ],
  blink: [
    { note: 'eyes open' },
    { note: 'closed (2 frames)', eyeL: 'closed', eyeR: 'closed' },
    { note: 'reopen — neutral idle' },
  ],
  happy: [
    { note: 'anticipation squash', bodySy: 0.85, bodyDy: 8, shadowSx: 1.12, tuftLift: 0.88, ...W(26, 8) },
    { note: 'jump ≥18px, wings fully up', bodySy: 1.1, bodyDy: -HOP[3], shadowSx: 0.58, tuftLift: 1.2,
      eyeL: 'happy', eyeR: 'happy', beak: 'open', ...W(88, -18, 4, { sx: 1.12 }),
      fx: [{ t: 'sparkle', x: 54, y: 96, s: 11 }, { t: 'sparkle', x: 186, y: 76, s: 9 }] },
    { note: 'apex + sparkle burst', bodySy: 1.04, bodyDy: -HOP[3] - 4, shadowSx: 0.5,
      tuftLift: 1.28, tuftLean: -7, eyeL: 'happy', eyeR: 'happy', beak: 'wide', tail: { spread: 48 },
      ...W(92, -22, 5, { sx: 1.12 }),
      fx: [{ t: 'sparkle', x: 44, y: 64, s: 14 }, { t: 'sparkle', x: 196, y: 50, s: 12 },
        { t: 'sparkle', x: 120, y: 30, s: 9 }, { t: 'dot', x: 30, y: 104, s: 4.4 }, { t: 'dot', x: 212, y: 96, s: 3 }] },
    { note: 'land squash', bodySy: 0.8, bodyDy: 11, shadowSx: 1.18, tuftLift: 0.9,
      eyeL: 'happy', eyeR: 'happy', ...W(62, 6, 2),
      fx: [{ t: 'dot', x: 40, y: 210, s: 4.4 }, { t: 'dot', x: 202, y: 212, s: 3.2 }, { t: 'motion', x: 62, y: 196, rot: 8, len: 22, sw: 5 }] },
  ],
  eating: [
    { note: 'seed approaches', headDy: -7, beak: 'thin', gaze: { dy: -1 }, tuftLift: 1.06,
      fx: [{ t: 'seed', x: 120, y: 110, s: 13 }] },
    { note: 'beak open, seed enters', headDy: -2, beak: 'open', gaze: { dy: -1 }, seed: 13 },
    { note: 'crunch 1 — crumbs fly', headRot: 2, headDy: 5, beak: 'thin', beakDy: 2,
      cheekPuff: 1.55, tuftLean: 5,
      fx: [{ t: 'crumb', x: 80, y: 156, s: 5.2 }, { t: 'crumb', x: 160, y: 152, s: 5.4 },
        { t: 'crumb', x: 120, y: 184, s: 4.2 }] },
    { note: 'crunch 2 — cheeks full', headRot: 2, headDy: 6, beak: 'thin', beakDy: 1,
      cheekPuff: 1.9, tuftLean: 7,
      fx: [{ t: 'crumb', x: 66, y: 148, s: 5.4 }, { t: 'crumb', x: 174, y: 144, s: 4 },
        { t: 'crumb', x: 96, y: 192, s: 4.4 }, { t: 'crumb', x: 146, y: 196, s: 4.2 },
        { t: 'crumb', x: 122, y: 172, s: 3 }] },
    { note: 'swallow — satisfied ^^', headRot: -2, headDy: 0, cheekPuff: 1, eyeL: 'happy', eyeR: 'happy',
      bodyRot: 0,
      fx: [{ t: 'crumb', x: 112, y: 206, s: 3 }, { t: 'sparkle', x: 186, y: 78, s: 11 }] },
  ],
  sleepy: [
    { note: 'lids droop', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 2, bodySy: 0.97, bodyDy: 4, beak: 'snore', nightcap: 1 },
    { note: 'head nods, body slumps', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 2, headDy: 6, nightcap: 1,
      bodySy: 0.94, bodyDy: 7, beak: 'snore', tuftLean: 6,
      fx: [{ t: 'z', x: 188, y: 86, s: 15, sw: 4.8 }] },
    { note: 'asleep — head droops', eyeL: 'closed', eyeR: 'closed', headRot: 2, headDy: 12,
      bodySy: 0.93, bodyDy: 8, beak: 'snore', tuftLift: 0.84, tuftLean: 7, nightcap: 1, ...W(10, 12),
      fx: [{ t: 'z', x: 174, y: 78, s: 19, sw: 5 }, { t: 'z', x: 202, y: 44, s: 23, sw: 5.2 }] },
    { note: 'deep slow breathing + snore', eyeL: 'closed', eyeR: 'closed', headRot: 2, headDy: 16,
      bodySy: 0.92, bodyDy: 9, beak: 'snore', tuftLean: 9, nightcap: 1, ...W(6, 14),
      fx: [{ t: 'z', x: 178, y: 88, s: 17, sw: 5 }, { t: 'z', x: 208, y: 48, s: 25, sw: 5.4 }] },
  ],
  surprised: [
    { note: 'jolt', bodySy: 1.13, bodyDy: -6, tuftLift: 1.34, tuftSpread: 1.12, shadowSx: 0.9,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'thin', ...W(44, -6) },
    { note: 'jump back', bodySy: 1.07, bodyDy: -18, shadowSx: 0.74, tuftLift: 1.38, tuftSpread: 1.14,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', tail: { spread: 48 }, ...W(78, -12),
      fx: [{ t: 'bang', x: 192, y: 58, s: 28 }] },
    { note: 'held — wings flare', bodySy: 1.02, bodyDy: -23, shadowSx: 0.62, tuftLift: 1.44, tuftSpread: 1.16,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', tail: { spread: 54 }, ...W(94, -16),
      fx: [{ t: 'bang', x: 194, y: 50, s: 34 },
        { t: 'motion', x: 30, y: 128, rot: 70, len: 24, sw: 5 }, { t: 'motion', x: 30, y: 164, rot: 70, len: 18, sw: 4.4 }] },
    { note: 'settle', bodySy: 1.05, bodyDy: -7, eyeL: 'surprised', eyeR: 'surprised', beak: 'o',
      shadowSx: 0.95, ...W(56, -6), fx: [{ t: 'bang', x: 190, y: 66, s: 22 }] },
  ],
  proud: [
    { note: 'chest out + chin up', bodySy: 1.03, bodyDy: -4, headRot: -2, headDy: -7, beak: 'thin',
      tuftLean: -5, tail: { spread: 34 }, ...W(-18, -6) },
    { note: 'both wings on hips + wink', bodySy: 1.04, bodyDy: -5, headRot: -2, headDy: -10,
      eyeL: 'wink', eyeR: 'open', brow: 1, beak: 'thin', tuftLean: -7, tail: { spread: 34 },
      wingL: { rot: -46, dy: 24 }, wingR: { rot: 46, dy: 24 },
      fx: [{ t: 'sparkle', x: 112, y: 176, s: 10 }] },
    { note: 'hold', bodySy: 1.02, bodyDy: -3, headRot: -2, headDy: -7, eyeL: 'wink', eyeR: 'open',
      beak: 'thin', tuftLean: -4, tail: { spread: 32 },
      wingL: { rot: -44, dy: 24 }, wingR: { rot: 44, dy: 24 },
      fx: [{ t: 'sparkle', x: 108, y: 172, s: 8 }, { t: 'dot', x: 186, y: 96, s: 3 }] },
    { note: 're-puff the chest', bodySy: 1.06, bodyDy: -7, headRot: -2, headDy: -11,
      eyeL: 'open', eyeR: 'open', brow: 1, beak: 'thin', tuftLean: -8, tail: { spread: 36 },
      wingL: { rot: -50, dy: 26 }, wingR: { rot: 50, dy: 26 },
      fx: [{ t: 'sparkle', x: 116, y: 178, s: 9 }, { t: 'sparkle', x: 180, y: 104, s: 7 }] },
    { note: 'settle, still smug', bodySy: 1.01, bodyDy: -3, headRot: -2, headDy: -6,
      eyeL: 'open', eyeR: 'open', beak: 'thin', tuftLean: -3, tail: { spread: 32 },
      wingL: { rot: -42, dy: 24 }, wingR: { rot: 42, dy: 24 },
      fx: [{ t: 'sparkle', x: 108, y: 172, s: 7 }] },
  ],
};

/* ──────────────────────── stage 4 · SONGBIRD ─────────────────────── */
const SONG = {
  idle: [
    { note: 'rest — planted stance' },
    { note: 'breathe in', bodySy: 1.04, bodyDy: -3, headDy: -2, tuftLean: 4, tail: { rot: -4 } },
    { note: 'head tilt + tail sway', headRot: -2, tuftLean: -6, tail: { rot: 6, spread: 84 } },
  ],
  blink: [
    { note: 'eyes open — neutral idle' },
    { note: 'closed (2 frames)', eyeL: 'closed', eyeR: 'closed' },
    { note: 'reopen', eyeL: 'open', eyeR: 'open' },
  ],
  happy: [
    { note: 'anticipation squash', bodySy: 0.85, bodyDy: 10, shadowSx: 1.12, tuftLift: 0.88,
      tail: { spread: 86 }, wingL: { rot: 18, dy: 4 }, wingR: { rot: 18, dy: 4 } },
    { note: 'jump ≥18px, wings up', bodySy: 1.1, bodyDy: -26, shadowSx: 0.56, tuftLift: 1.16,
      eyeL: 'happy', eyeR: 'happy', beak: 'open', tail: { spread: 84 },
      wingL: { rot: 96, dy: -18 }, wingR: { rot: 96, dy: -18 },
      fx: [{ t: 'sparkle', x: 46, y: 92, s: 12 }, { t: 'sparkle', x: 194, y: 68, s: 10 }] },
    { note: 'apex + sparkle burst', bodySy: 1.04, bodyDy: -30, shadowSx: 0.48,
      tuftLift: 1.22, tuftLean: -7, eyeL: 'happy', eyeR: 'happy', beak: 'wide', tail: { spread: 80 },
      wingL: { rot: 102, dy: -22 }, wingR: { rot: 102, dy: -22 },
      fx: [{ t: 'sparkle', x: 36, y: 56, s: 15 }, { t: 'sparkle', x: 204, y: 42, s: 13 },
        { t: 'sparkle', x: 120, y: 18, s: 10 }, { t: 'dot', x: 22, y: 100, s: 4.4 }, { t: 'dot', x: 220, y: 90, s: 3.2 }] },
    { note: 'land squash', bodySy: 0.79, bodyDy: 13, shadowSx: 1.2, tuftLift: 0.9,
      eyeL: 'happy', eyeR: 'happy', tail: { spread: 86 },
      wingL: { rot: 54, dy: 8 }, wingR: { rot: 54, dy: 8 },
      fx: [{ t: 'dot', x: 34, y: 212, s: 4.4 }, { t: 'dot', x: 208, y: 214, s: 3.2 }] },
  ],
  eating: [
    { note: 'seed approaches', headDy: -7, beak: 'thin', gaze: { dy: -1 }, tuftLift: 1.06,
      fx: [{ t: 'seed', x: 120, y: 88, s: 13 }] },
    { note: 'beak open, seed enters', headDy: -2, beak: 'open', gaze: { dy: -1 }, seed: 13 },
    { note: 'crunch 1 — crumbs fly', headRot: 2, headDy: 5, beak: 'thin', beakDy: 2,
      cheekPuff: 1.55, tuftLean: 5,
      fx: [{ t: 'crumb', x: 78, y: 150, s: 5.2 }, { t: 'crumb', x: 162, y: 146, s: 5.4 },
        { t: 'crumb', x: 120, y: 178, s: 4.2 }] },
    { note: 'crunch 2 — cheeks full', headRot: 2, headDy: 6, beak: 'thin', beakDy: 1,
      cheekPuff: 1.45, headRot: 2, headDy: 8, tuftLean: 8, tail: { spread: 82 },
      fx: [{ t: 'crumb', x: 64, y: 142, s: 5.4 }, { t: 'crumb', x: 176, y: 138, s: 4 },
        { t: 'crumb', x: 96, y: 186, s: 4.4 }, { t: 'crumb', x: 148, y: 190, s: 4.2 },
        { t: 'crumb', x: 122, y: 166, s: 3 }] },
    { note: 'swallow — satisfied ^^', headRot: -2, headDy: 0, cheekPuff: 1, eyeL: 'happy', eyeR: 'happy',
      tail: { spread: 80 },
      fx: [{ t: 'crumb', x: 112, y: 200, s: 3 }, { t: 'sparkle', x: 190, y: 74, s: 11 }] },
  ],
  sleepy: [
    { note: 'lids droop', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 2, bodySy: 0.97, bodyDy: 4, nightcap: 1 },
    { note: 'head nods, body slumps', eyeL: 'sleepy', eyeR: 'sleepy', headRot: 2, headDy: 5, nightcap: 1,
      bodySy: 0.94, bodyDy: 6, beak: 'snore', tuftLean: 6,
      fx: [{ t: 'z', x: 188, y: 86, s: 15, sw: 4.8 }] },
    { note: 'asleep — head droops', eyeL: 'closed', eyeR: 'closed', headRot: 2, headDy: 12,
      bodySy: 0.93, bodyDy: 7, beak: 'snore', tuftLift: 0.84, tuftLean: 7, nightcap: 1, tail: { rot: -8 },
      wingL: { rot: 12, dy: 12 }, wingR: { rot: 12, dy: 12 },
      fx: [{ t: 'z', x: 176, y: 74, s: 19, sw: 5.2 }, { t: 'z', x: 206, y: 40, s: 23, sw: 5.4 }] },
    { note: 'deep slow breathing + snore', eyeL: 'closed', eyeR: 'closed', headRot: 2, headDy: 16,
      bodySy: 0.92, bodyDy: 8, beak: 'snore', tuftLean: 9, nightcap: 1, tail: { rot: -10 },
      wingL: { rot: 8, dy: 14 }, wingR: { rot: 8, dy: 14 },
      fx: [{ t: 'z', x: 180, y: 84, s: 17, sw: 5 }, { t: 'z', x: 212, y: 44, s: 25, sw: 5.6 }] },
  ],
  surprised: [
    { note: 'jolt', bodySy: 1.13, bodyDy: -7, shadowSx: 0.9, tuftLift: 1.3, tuftSpread: 1.12,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'thin',
      wingL: { rot: 42, dy: -6 }, wingR: { rot: 42, dy: -6 } },
    { note: 'jump back', bodySy: 1.07, bodyDy: -19, shadowSx: 0.72, tuftLift: 1.34, tuftSpread: 1.14,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', tail: { spread: 84 },
      wingL: { rot: 70, dy: -14 }, wingR: { rot: 70, dy: -14 },
      fx: [{ t: 'bang', x: 196, y: 50, s: 29 }] },
    { note: 'held — wings flare wide', bodySy: 1.02, bodyDy: -24, shadowSx: 0.6, tuftLift: 1.4, tuftSpread: 1.18,
      eyeL: 'surprised', eyeR: 'surprised', beak: 'o', tail: { spread: 88 },
      wingL: { rot: 90, dy: -18 }, wingR: { rot: 90, dy: -18 },
      fx: [{ t: 'bang', x: 198, y: 40, s: 35 },
        { t: 'motion', x: 22, y: 120, rot: 70, len: 26, sw: 5 }, { t: 'motion', x: 22, y: 156, rot: 70, len: 20, sw: 4.4 }] },
    { note: 'settle', bodySy: 1.05, bodyDy: -8, eyeL: 'surprised', eyeR: 'surprised', beak: 'o',
      shadowSx: 0.95, tail: { spread: 82 }, wingL: { rot: 48, dy: -6 }, wingR: { rot: 48, dy: -6 },
      fx: [{ t: 'bang', x: 194, y: 58, s: 23 }] },
  ],
  proud: [
    { note: 'chest out + chin up', bodySy: 1.03, bodyDy: -5, headRot: -2, headDy: -8, beak: 'thin',
      tuftLean: -5, tail: { spread: 84 }, wingL: { rot: 10, dy: -4 }, wingR: { rot: 10, dy: -4 } },
    { note: 'both wings on hips + wink', bodySy: 1.04, bodyDy: -6, headRot: -2, headDy: -11,
      eyeL: 'wink', eyeR: 'open', brow: 1, beak: 'thin', tuftLean: -7, tail: { spread: 86 },
      wingL: { rot: -40, dy: 22 }, wingR: { rot: -40, dy: 22 },
      fx: [{ t: 'sparkle', x: 112, y: 176, s: 10 }] },
    { note: 'hold', bodySy: 1.02, bodyDy: -4, headRot: -2, headDy: -8, eyeL: 'wink', eyeR: 'open',
      beak: 'thin', tuftLean: -4, tail: { spread: 84 },
      wingL: { rot: -38, dy: 22 }, wingR: { rot: -38, dy: 22 },
      fx: [{ t: 'sparkle', x: 108, y: 172, s: 8 }, { t: 'dot', x: 192, y: 88, s: 3 }] },
    { note: 're-puff the chest', bodySy: 1.06, bodyDy: -8, headRot: -2, headDy: -12,
      eyeL: 'open', eyeR: 'open', brow: 1, beak: 'thin', tuftLean: -8, tail: { spread: 86 },
      wingL: { rot: -42, dy: 24 }, wingR: { rot: -42, dy: 24 },
      fx: [{ t: 'sparkle', x: 116, y: 178, s: 9 }, { t: 'sparkle', x: 186, y: 96, s: 7 }] },
    { note: 'settle, still smug', bodySy: 1.01, bodyDy: -4, headRot: -2, headDy: -7,
      eyeL: 'open', eyeR: 'open', beak: 'thin', tuftLean: -3, tail: { spread: 84 },
      wingL: { rot: -36, dy: 22 }, wingR: { rot: -36, dy: 22 },
      fx: [{ t: 'sparkle', x: 108, y: 172, s: 7 }] },
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
