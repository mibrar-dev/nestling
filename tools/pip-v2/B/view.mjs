#!/usr/bin/env node
/* Big side-by-side QA render of a few SVGs (light + dark halves), no grid. */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const dir = process.argv[2];
const outPng = process.argv[3];
const cell = Number(process.argv[4] || 420);
const files = process.argv.slice(5).length ? process.argv.slice(5) : fs.readdirSync(dir).filter((f) => f.endsWith('.svg')).sort();
const W = cell * files.length, H = cell + 24;
const layers = [];
for (let i = 0; i < files.length; i++) {
  const f = fs.existsSync(path.join(dir, files[i])) ? files[i] : files[i];
  const src = fs.readFileSync(path.resolve(dir, f));
  const big = await sharp(src, { density: 400 }).resize(cell, cell, { fit: 'fill', background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
  layers.push({ input: { create: { width: cell, height: cell / 2, channels: 4, background: '#FBF7F0' } }, left: i * cell, top: 24 });
  layers.push({ input: { create: { width: cell, height: cell / 2, channels: 4, background: '#15131F' } }, left: i * cell, top: 24 + cell / 2 });
  layers.push({ input: big, left: i * cell, top: 24 });
  const lab = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${cell}" height="24"><rect width="${cell}" height="24" fill="#E9E4F7"/><text x="6" y="17" font-family="Menlo,monospace" font-size="13" fill="#1E1B3A">${f.replace('.svg', '')}</text></svg>`);
  layers.push({ input: lab, left: i * cell, top: 0 });
}
await sharp({ create: { width: W, height: H, channels: 4, background: '#FFFFFF' } }).composite(layers).png().toFile(outPng);
console.log('view', outPng, W + 'x' + H);
