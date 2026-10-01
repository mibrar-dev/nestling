#!/usr/bin/env node
// Render every app/assets/icons/*.svg into a labelled contact sheet so the
// drawings can be eyeballed at their real on-device size.
//
//   node tools/render-icon-sheet.mjs
//
// Output: design/ICONS_OVERVIEW.png
// Section A is every icon at true 1x (24px, the size Flutter actually paints
// it at) inside its 24px viewBox, so overflow and mush are visible.
// Section B is the same set at 3x for shape inspection.

import { readdir, readFile, writeFile, mkdir } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import sharp from 'sharp'

const HERE = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(HERE, '..')
const ICON_DIR = resolve(ROOT, 'app/assets/icons')
const OUT = resolve(ROOT, 'design/ICONS_OVERVIEW.png')

const COLUMNS = 9
const CELL = 132
const PAD = 28
const ICON_PX = 24

const INK = '#1d2b24'
const MUTED = '#6b7a72'
const CARD = '#f4f1ea'
const PAGE = '#fbf9f5'
const RULE = '#dcd6c9'

/** Pull the body out of a <svg> wrapper so we can re-host it in the sheet. */
function innerSvg(markup) {
  const open = markup.indexOf('>')
  const close = markup.lastIndexOf('</svg>')
  if (open === -1 || close === -1) throw new Error('not an svg')
  return markup.slice(open + 1, close).trim()
}

function escapeXml(s) {
  return s.replace(/[<>&'"]/g, c =>
    ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' })[c])
}

function section({ title, subtitle, icons, scale, cellH }) {
  const rows = Math.ceil(icons.length / COLUMNS)
  const w = PAD * 2 + COLUMNS * CELL
  const h = PAD * 2 + 64 + rows * cellH
  const out = []

  out.push(`<text x="${PAD}" y="${PAD + 20}" font-family="Menlo,DejaVu Sans Mono,monospace" font-size="20" font-weight="700" fill="${INK}">${escapeXml(title)}</text>`)
  out.push(`<text x="${PAD}" y="${PAD + 42}" font-family="Menlo,DejaVu Sans Mono,monospace" font-size="13" fill="${MUTED}">${escapeXml(subtitle)}</text>`)

  icons.forEach((icon, i) => {
    const col = i % COLUMNS
    const row = Math.floor(i / COLUMNS)
    const x = PAD + col * CELL
    const y = PAD + 64 + row * cellH

    // Card.
    out.push(`<rect x="${x + 6}" y="${y + 6}" width="${CELL - 12}" height="${cellH - 12}" rx="10" fill="${CARD}" stroke="${RULE}"/>`)

    // The icon, centred, with its viewBox drawn faintly so padding is visible.
    const box = ICON_PX * scale
    const ix = x + (CELL - box) / 2
    const iy = y + 22
    out.push(`<rect x="${ix}" y="${iy}" width="${box}" height="${box}" fill="none" stroke="${RULE}" stroke-width="${scale >= 3 ? 1 : 0.5}" stroke-dasharray="${scale >= 3 ? 0 : '1 1'}"/>`)
    out.push(
      `<g transform="translate(${ix} ${iy}) scale(${scale})" ` +
      `fill="none" stroke="${INK}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" color="${INK}">` +
      icon.inner +
      `</g>`)

    out.push(`<text x="${x + CELL / 2}" y="${y + cellH - 22}" text-anchor="middle" font-family="Menlo,DejaVu Sans Mono,monospace" font-size="11" fill="${INK}">${escapeXml(icon.name.replace(/^ic_/, ''))}</text>`)
    out.push(`<text x="${x + CELL / 2}" y="${y + cellH - 9}" text-anchor="middle" font-family="Menlo,DejaVu Sans Mono,monospace" font-size="9" fill="${MUTED}">${icon.name}</text>`)
  })

  return { svg: out.join('\n'), w, h }
}

const files = (await readdir(ICON_DIR)).filter(f => f.endsWith('.svg')).sort()
const icons = []
for (const f of files) {
  const markup = await readFile(resolve(ICON_DIR, f), 'utf8')
  icons.push({ file: f, name: f.replace(/\.svg$/, ''), inner: innerSvg(markup) })
}

const a = section({
  title: `Nestling icons — ${icons.length} glyphs`,
  subtitle: 'Section A: true 1x — each icon painted at 24px inside its 24px viewBox (dashed = viewBox edge)',
  icons,
  scale: 1,
  cellH: 116,
})
const b = section({
  title: 'Section B — 3x detail',
  subtitle: 'Same geometry at 72px. Shape errors that hide at 24px show up here.',
  icons,
  scale: 3,
  cellH: 168,
})

const sheet = `<svg xmlns="http://www.w3.org/2000/svg" width="${a.w}" height="${a.h + b.h}" viewBox="0 0 ${a.w} ${a.h + b.h}">
<rect width="100%" height="100%" fill="${PAGE}"/>
${a.svg}
<g transform="translate(0 ${a.h})">${b.svg}</g>
</svg>`

await mkdir(dirname(OUT), { recursive: true })
await sharp(Buffer.from(sheet), { density: 200 })
  .png({ compressionLevel: 9 })
  .toFile(OUT)

console.log(`wrote ${OUT} (${icons.length} icons)`)
