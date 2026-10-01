import fs from 'node:fs';
import { svg } from './rig.mjs';

const out = process.argv[2] || '/tmp/bolttest';
fs.mkdirSync(out, { recursive: true });

const tests = [
  { stage: 1, mood: 'idle', n: 1 },
  { stage: 2, mood: 'idle', n: 1 },
  { stage: 3, mood: 'idle', n: 1 },
  { stage: 4, mood: 'idle', n: 1 },
  { stage: 3, mood: 'happy', n: 2, wingL: { rot: 118, dy: -16 }, wingR: { rot: -118, dy: -16 }, eyeL: 'happy', eyeR: 'happy', beak: 'open', bodyDy: -24, bodySy: 1.08, tuftLift: 1.2, shadowSx: 0.7 },
  { stage: 3, mood: 'proud', n: 1, wingFront: true, wingL: { rot: 46, dy: 30, dx: -14, sy: 0.9 }, wingR: { rot: -46, dy: 30, dx: 14, sy: 0.9 }, eyeL: 'wink', eyeR: 'open', headRot: -7, headDy: -5, beakDy: -5, tuftLean: -4 },
  { stage: 3, mood: 'surprised', n: 2, eyeL: 'surprised', eyeR: 'surprised', beak: 'o', tuftLift: 1.3, wingL: { rot: 60, dy: -8 }, wingR: { rot: -60, dy: -8 }, bodyDy: -16, bodySy: 1.08, shadowSx: 0.72, fx: [{ t: 'bang', x: 190, y: 66, s: 30 }] },
  { stage: 4, mood: 'happy', n: 2, wingL: { rot: 104, dy: -22 }, wingR: { rot: -104, dy: -22 }, eyeL: 'happy', eyeR: 'happy', beak: 'open', bodyDy: -24, bodySy: 1.08, shadowSx: 0.7 },
  { stage: 3, mood: 'eating', n: 2, headRot: 17, headDy: 6, beak: 'thin', cheekPuff: 1.5, eyeSy: 0.82, gaze: { dy: 1 }, fx: [{ t: 'seed', x: 120, y: 126, s: 7 }] },
  { stage: 3, mood: 'sleepy', n: 3, eyeL: 'sleepy', eyeR: 'sleepy', headRot: 19, headDy: 8, bodySy: 1.07, tuftLean: 7, tuftLift: 0.82, fx: [{ t: 'z', x: 168, y: 96, s: 15, sw: 5 }, { t: 'z', x: 192, y: 70, s: 19, sw: 5 }] },
  { stage: 2, mood: 'happy', n: 2, wingL: { rot: 110, dy: -8 }, wingR: { rot: -110, dy: -8 }, eyeL: 'happy', eyeR: 'happy', beak: 'open', bodyDy: -18, bodySy: 1.06, shadowSx: 0.8, fx: [{ t: 'sparkle', x: 58, y: 82, s: 10 }] },
  { stage: 1, mood: 'surprised', n: 2, crackOpen: 12, bodySy: 1.1, bodyDy: -8, tuftLift: 1.25, eyeL: 'surprised', eyeR: 'surprised', fx: [{ t: 'bang', x: 192, y: 74, s: 28 }] },
];

for (const t of tests) fs.writeFileSync(`${out}/s${t.stage}_${t.mood}_${t.n}.svg`, svg(t));
console.log('wrote', tests.length, 'test svgs to', out);
