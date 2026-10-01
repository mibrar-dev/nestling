#!/usr/bin/env node
/* Contact sheet: rasterise a folder of SVGs into a labelled QA grid (light/dark halves + 48px chip). */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const dir = process.argv[2];
const outPng = process.argv[3];
const cols = Number(process.argv[4] || 5);
const cell = Number(process.argv[5] || 250);

const files = fs.readdirSync(dir).filter((f) => f.endsWith('.svg')).sort();
if (!files.length) { console.error('no svgs in', dir); process.exit(1); }

const LAB = 22, CHIP = 48, rows = Math.ceil(files.length / cols);
const W = cols * cell, H = rows * (cell + LAB) + 8;

const labelSvg = (txt, w, h, fill, fg, size) =>
  Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><rect width="${w}" height="${h}" fill="${fill}"/>`
    + `<text x="6" y="${Math.round(h / 2) + Math.round(size * 0.35)}" font-family="Menlo,monospace" font-size="${size}" fill="${fg}">${txt.replace(/[<>&]/g, '')}</text></svg>`);

const layers = [];
for (let i = 0; i < files.length; i++) {
  const x = (i % cols) * cell, y = Math.floor(i / cols) * (cell + LAB) + 4;
  layers.push({ input: labelSvg(files[i].replace('.svg', ''), cell, LAB, '#E9E4F7', '#1E1B3A', 13), left: x, top: y });
  const yb = y + LAB;
  layers.push({ input: { create: { width: cell, height: cell / 2, channels: 4, background: '#FBF7F0' } }, left: x, top: yb });
  layers.push({ input: { create: { width: cell, height: cell / 2, channels: 4, background: '#15131F' } }, left: x, top: yb + cell / 2 });
  const src = fs.readFileSync(path.join(dir, files[i]));
  const big = await sharp(src, { density: 400 }).resize(cell, cell, { fit: 'fill', background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
  layers.push({ input: big, left: x, top: yb });
  const s48 = await sharp(src, { density: 400 }).resize(CHIP, CHIP, { fit: 'fill', background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
  layers.push({ input: { create: { width: CHIP + 8, height: CHIP + 8, channels: 4, background: '#7C6CF2' } }, left: x + 6, top: yb + 6 });
  layers.push({ input: s48, left: x + 10, top: yb + 10 });
}
await sharp({ create: { width: W, height: H, channels: 4, background: '#FFFFFF' } }).composite(layers).png().toFile(outPng);
console.log('sheet', outPng, `${W}x${H}`, files.length, 'tiles');
