'use strict';
/**
 * brand.js — the single source of truth for colours and motion constants.
 *
 * Values are read straight from `design/html-source/tokens.css` and the
 * `app/assets/illustrations/*.svg` art. If a token changes there, change it
 * here; nothing below this file hard-codes a hex.
 */

const C = {
  ink: '#1E1B3A',
  ink2: '#4A4668',
  paper: '#FBF7F0',
  white: '#FFFFFF',
  leaf: '#17804F',
  leafInk: '#0B5C38',
  leafBright: '#1F9D63',
  leafTint: '#E3F5EC',
  coin: '#F4B400',
  coinInk: '#6B4E00',
  coinTint: '#FFF4D1',
  sky: '#2563D6',
  skyBright: '#3D7FF0',
  lilac: '#7C6CF2',
  lilacStrong: '#6A58E8',
  peach: '#FF8A5B',
  pipYellow: '#FFD93D',
  pipShadow: '#FFB800',
  cream: '#FFF8E8',
  coinRim: '#FFF6D8',
};

/** Confetti + coin-burst palette, in the order the SVG art uses them. */
const CELEBRATION = [C.coin, C.leafBright, C.lilac, C.peach, C.skyBright];

/** Duration of each asset in seconds, and the frame count at 60 fps. */
const DURATIONS = {
  check_tick: 0.6,
  coin_burst: 1.0,
  confetti: 2.5,
  badge_unlock: 0.9,
};

const F = (seconds) => Math.round(seconds * 60);

/* ------------------------------------------------------------- small maths */

const lerp = (a, b, t) => a + (b - a) * t;
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const round = (n, p = 2) => Math.round(n * 10 ** p) / 10 ** p;

/**
 * Deterministic PRNG (mulberry32). Confetti that differs on every build makes
 * preview diffs useless and makes it impossible to tell a regression from a
 * reshuffle, so the generator is seeded and reproducible.
 */
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a += 0x6d2b79f5;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Damped pendulum angle at time `t` (seconds) for a release from `theta0`.
 *
 *   θ(t) = θ₀ · e^(−ζωt) · cos(ω_d t)
 *
 * Sampled per-frame into keyframes rather than expressed as an expression,
 * because Flutter's lottie runtime has no expression engine.
 */
function pendulum(theta0, t, { zeta = 0.16, omega = 9.0 } = {}) {
  return theta0 * Math.exp(-zeta * omega * t) * Math.cos(omega * Math.sqrt(1 - zeta * zeta) * t);
}

/** Same envelope, for a value that should ring and settle rather than swing. */
function dampedOsc(amplitude, t, { zeta = 0.3, omega = 14 } = {}) {
  return amplitude * Math.exp(-zeta * omega * t) * Math.cos(omega * Math.sqrt(1 - zeta * zeta) * t);
}

module.exports = { C, CELEBRATION, DURATIONS, F, lerp, clamp, round, rng, pendulum, dampedOsc };
