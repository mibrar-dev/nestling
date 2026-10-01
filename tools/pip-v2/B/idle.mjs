/* Canonical idle frames per stage, used by skins / accessories / boards so every
   derived asset sits on the same rest pose as the pose library. */
import { STAGES } from './rig.mjs';

export const IDLE = {
  1: { idle: { stage: 1, mood: 'idle', n: 1, note: 'rest' } },
  2: { idle: { stage: 2, mood: 'idle', n: 1, note: 'rest' } },
  3: { idle: { stage: 3, mood: 'idle', n: 1, note: 'rest' } },
  4: { idle: { stage: 4, mood: 'idle', n: 1, note: 'rest' } },
};

/* peak-frame index per mood for the mood board (1-based, per stage where they differ) */
export const PEAK = {
  1: { idle: 1, blink: 1, happy: 3, eating: 3, sleepy: 3, surprised: 2, proud: 2 },
  2: { idle: 1, blink: 1, happy: 3, eating: 4, sleepy: 3, surprised: 3, proud: 2 },
  3: { idle: 1, blink: 1, happy: 3, eating: 4, sleepy: 3, surprised: 3, proud: 2 },
  4: { idle: 1, blink: 1, happy: 3, eating: 4, sleepy: 3, surprised: 3, proud: 2 },
};

export { STAGES };
