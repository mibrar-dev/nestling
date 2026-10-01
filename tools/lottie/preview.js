'use strict';
/**
 * preview.js — headless frame capture + contact sheet.
 *
 *   node tools/lottie/preview.js [name ...]
 *
 * Renders each Lottie with lottie-web in real Chrome (puppeteer-core, no
 * bundled Chromium download) and screenshots frames at 0 / 25 / 50 / 75 / 100 %
 * into `design/animations/previews/`, then composites a labelled contact sheet
 * at `design/animations/LOTTIE_PREVIEW.png`.
 *
 * Chrome is the *reference* renderer here, not the shipping one — the shipping
 * renderer is flutter lottie on Impeller. Its value is catching authoring
 * mistakes (wrong layer order, a trim path that never closes, a coin parked
 * off-frame) before the Dart side is ever run. `npm run verify` in the app
 * package is the Dart-side check.
 *
 * The background is a checkerboard rather than a flat colour so a transparent
 * animation cannot be mistaken for a white one, and a hairline frame marks
 * the comp bounds so "is it centred?" is answerable from the PNG alone.
 */

const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer-core');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ROOT = path.join(__dirname, '..', '..');
const LOTTIE_DIR = path.join(ROOT, 'app', 'assets', 'animations', 'lottie');
const OUT_DIR = path.join(ROOT, 'design', 'animations', 'previews');
const SHEET = path.join(ROOT, 'design', 'animations', 'LOTTIE_PREVIEW.png');

const LOTTIE_JS = path.join(__dirname, 'node_modules', 'lottie-web', 'build', 'player', 'lottie.js');

/** Percentages of the timeline to capture, plus the reduced-motion still. */
const STOPS = [0, 25, 50, 75, 100];
/** Extra frame captured for the `still` marker written by the generator. */
const STILL = 25; // file suffix: <name>_still.png

/** Output scale — 2x so thin strokes and 1 px keylines survive inspection. */
const SCALE = 2;
const PAD = 24;

/**
 * A checkerboard page. The animation is scaled to fit `box` while preserving
 * the comp's own aspect ratio, so a 390×844 confetti frame and a 64×64 check
 * are both drawn at the correct proportion.
 */
function pageFor(comp, box, lottieSrc) {
  return `<!doctype html><html><head><meta charset="utf-8">
<style>
  html,body{margin:0;padding:0;background:#fff;}
  #wrap{position:relative;width:${box.w}px;height:${box.h}px;
        background-color:#fff;
        background-image:
          linear-gradient(45deg,#EDEAF3 25%,transparent 25%,transparent 75%,#EDEAF3 75%),
          linear-gradient(45deg,#EDEAF3 25%,transparent 25%,transparent 75%,#EDEAF3 75%);
        background-size:16px 16px;
        background-position:0 0,8px 8px;}
  #box{position:absolute;left:${PAD}px;top:${PAD}px;
       width:${box.iw}px;height:${box.ih}px;
       outline:1px solid rgba(30,27,58,.28);outline-offset:0;}
  /* centre guides — the acceptance criterion is "centred", so draw it */
  #cx{position:absolute;left:${PAD + box.iw / 2}px;top:${PAD}px;width:1px;height:${box.ih}px;
      background:rgba(124,108,242,.30);}
  #cy{position:absolute;left:${PAD}px;top:${PAD + box.ih / 2}px;width:${box.iw}px;height:1px;
      background:rgba(124,108,242,.30);}
  #anim{position:absolute;inset:0;}
</style></head><body>
<div id="wrap"><div id="box"><div id="cx"></div><div id="cy"></div><div id="anim"></div></div></div>
<script>${lottieSrc}</script>
</body></html>`;
}

/** Fit a comp into the sheet cell, preserving aspect. */
function fitBox(comp) {
  const maxW = 320;
  const maxH = 320;
  const ar = comp.w / comp.h;
  let iw = maxW;
  let ih = Math.round(maxW / ar);
  if (ih > maxH) {
    ih = maxH;
    iw = Math.round(maxH * ar);
  }
  return { w: iw + PAD * 2, h: ih + PAD * 2, iw, ih };
}

async function main() {
  const only = process.argv.slice(2);
  if (!fs.existsSync(CHROME)) {
    console.error(`\n  ✗ Chrome not found at ${CHROME}\n`);
    process.exit(1);
  }
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const files = fs
    .readdirSync(LOTTIE_DIR)
    .filter((f) => f.endsWith('.json') && (!only.length || only.includes(f.replace('.json', ''))))
    .sort();

  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    protocolTimeout: 180000,
    args: ['--allow-file-access-from-files', '--force-device-scale-factor=1', '--hide-scrollbars'],
  });

  // Inlined rather than <script src="file://…">: setContent gives the page an
  // about:blank base URL, and a file:// subresource from about:blank is
  // blocked. The preview must not silently degrade to an unrendered frame.
  const lottieSrc = fs.readFileSync(LOTTIE_JS, 'utf8');
  if (!lottieSrc.includes('loadAnimation')) {
    console.error(`  ✗ ${LOTTIE_JS} does not look like lottie-web's player build.`);
    process.exit(1);
  }

  const meta = [];
  // A preview run that produces blank frames is worse than no run: it reads as
  // a pass. Track renderer errors and empty SVGs and exit non-zero.
  let bad = false;
  for (const file of files) {
    const name = file.replace('.json', '');
    const json = fs.readFileSync(path.join(LOTTIE_DIR, file), 'utf8');
    const comp = JSON.parse(json);
    const box = fitBox(comp);

    const page = await browser.newPage();
    await page.setViewport({ width: box.w, height: box.h, deviceScaleFactor: SCALE });
    await page.setContent(pageFor(comp, box, lottieSrc), { waitUntil: 'load' });

    const loaded = await page.evaluate(
      (data, stops) =>
        new Promise((resolve) => {
          let done = false;
          const finish = (v) => {
            if (done) return;
            done = true;
            resolve(v);
          };
          // A preview that hangs is worse than one that fails: without this the
          // whole run dies on puppeteer's protocolTimeout with no clue which
          // asset was stuck.
          setTimeout(() => finish({ ok: false, reason: 'timeout' }), 15000);

          let anim;
          try {
            anim = lottie.loadAnimation({
              container: document.getElementById('anim'),
              renderer: 'svg',
              loop: false,
              autoplay: false,
              animationData: data,
            });
          } catch (e) {
            finish({ ok: false, reason: `throw: ${e && e.message}` });
            return;
          }
          // Keep a global handle and collect swallowed render errors. lottie-web
          // catches exceptions inside renderFrame and re-emits them as an
          // `error` event with an empty nativeError, so without this a broken
          // file looks identical to a working one.
          window.__anim = anim;
          window.__errs = [];
          anim.addEventListener('error', (e) => {
            const n = (e && e.nativeEvent) || {};
            const err = n.nativeError;
            window.__errs.push({
              type: e.type,
              detail: err ? String(err.message || err) : 'no nativeError',
            });
          });
          // `isLoaded` is already true when the JSON is tiny enough to parse
          // synchronously, so the event is a race — check the flag as well.
          const onReady = () => {
            if (done) return;
            try {
              anim.goToAndStop(0, true);
              let bounds = null;
              anim.goToAndStop(Math.round(anim.totalFrames * 0.5), true);
              const svg = document.querySelector('#anim svg');
              if (svg) {
                const b = svg.getBBox();
                const vb = svg.viewBox.baseVal;
                bounds = {
                  x: +b.x.toFixed(1), y: +b.y.toFixed(1),
                  w: +b.width.toFixed(1), h: +b.height.toFixed(1),
                  vw: vb.width, vh: vb.height,
                };
              }
              finish({
                ok: true,
                totalFrames: anim.totalFrames,
                duration: anim.getDuration(false),
                bounds,
                renderer: svg ? svg.querySelectorAll('g').length : 0,
              });
            } catch (e) {
              finish({ ok: false, reason: `render: ${e && e.message}` });
            }
          };
          anim.addEventListener('DOMLoaded', onReady);
          anim.addEventListener('data_failed', () => finish({ ok: false, reason: 'parse' }));
          if (anim.isLoaded) onReady();
          void stops;
        }),
      comp,
      STOPS,
    );

    if (!loaded.ok) {
      console.error(`  ✗ ${name}: lottie-web failed to load (${loaded.reason})`);
      await page.close();
      continue;
    }

    for (const pct of STOPS) {
      const frame = pct === 100 ? loaded.totalFrames - 0.001 : (loaded.totalFrames * pct) / 100;
      // Seek via the handle we created, not `getRegisteredAnimations()[0]`:
      // that global array accumulates across pages and index 0 is not
      // necessarily ours.
      const seeked = await page.evaluate((f) => {
        const a = window.__anim;
        if (!a) return { ok: false, reason: 'no handle' };
        a.goToAndStop(f, true);
        const svg = document.querySelector('#anim svg');
        return { ok: true, nodes: svg ? svg.querySelectorAll('path,ellipse,rect,g').length : 0, errors: window.__errs || [] };
      }, frame);
      if (!seeked.ok) {
        console.error(`  ✗ ${name} @${pct}%: ${seeked.reason}`);
        bad = true;
        continue;
      }
      if (seeked.nodes < 2) {
        console.error(`  ✗ ${name} @${pct}%: SVG has ${seeked.nodes} nodes — nothing drawn.`);
        bad = true;
      }
      if (seeked.errors.length) {
        console.error(`  ✗ ${name} @${pct}%: renderer error ${JSON.stringify(seeked.errors[0])}`);
        bad = true;
      }
      const out = path.join(OUT_DIR, `${name}_f${pct}.png`);
      await page.screenshot({ path: out });
    }

    // Capture the reduced-motion still declared by the generator's `still`
    // marker, so the fallback frame can be eyeballed like any other.
    const stillFrame = (comp.markers || []).find((m) => m.cm === 'still');
    if (stillFrame) {
      await page.evaluate((f) => window.__anim.goToAndStop(f, true), stillFrame.tm);
      await page.screenshot({ path: path.join(OUT_DIR, `${name}_still.png`) });
      console.log(`      still frame ${stillFrame.tm} → ${name}_still.png`);
    }

    const b = loaded.bounds;
    const centred = b
      ? Math.abs((b.x + b.w / 2) - b.vw / 2) < b.vw * 0.06 &&
        Math.abs((b.y + b.h / 2) - b.vh / 2) < b.vh * 0.06
      : null;
    meta.push({
      name,
      w: comp.w,
      h: comp.h,
      frames: loaded.totalFrames,
      // Derive seconds from the frame count and the comp's own `fr`, not from
      // `getDuration()` — that returns a frame count, not milliseconds, so
      // dividing it by 1000 prints "0.001s" for every file.
      duration: +(loaded.totalFrames / comp.fr).toFixed(2),
      centred,
      box,
      bounds: b,
    });
    console.log(
      `  ✓ ${name.padEnd(15)} ${String(comp.w).padStart(3)}×${String(comp.h).padEnd(3)} ` +
        `${loaded.totalFrames} f / ${(loaded.totalFrames / comp.fr).toFixed(2)}s  ` +
        `mid-bounds ${b ? `${b.w}×${b.h} @${b.x},${b.y}` : 'n/a'}  centred=${centred}`,
    );
    await page.close();
  }

  await browser.close();

  /* ------------------------------------------------------- contact sheet --- */
  if (meta.length) {
    // One column per timeline stop, plus a "still" column showing the frame the
    // reduced-motion fallback seeks to — the last thing that should be checked
    // before shipping, because it is what a user with animations disabled sees.
    const hasStill = meta.some((m) => fs.existsSync(path.join(OUT_DIR, `${m.name}_still.png`)));
    const COLS = STOPS.length + (hasStill ? 1 : 0);
    const cellW = 190;
    const cellH = 210;
    const labelH = 26;
    const headH = 54;
    const width = COLS * cellW;
    const height = headH + meta.length * (cellH + labelH);

    const page = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--hide-scrollbars'] });
    const sheet = await page.newPage();
    await sheet.setViewport({ width, height, deviceScaleFactor: 2 });
    const head = `<div class="h">
        <div class="t">Nestling — Lottie one-shots</div>
        <div class="s">Bodymovin 5.7 · 60 fps · transparent · no expressions · generated by tools/lottie</div>
      </div>`;
    const cell = (file) => {
      // Inline as a data URI: the sheet is built with setContent, so its base
      // URL is about:blank and a file:// <img> is blocked — the sheet renders
      // as a grid of broken-image icons, which looks like a pass.
      if (!fs.existsSync(file)) return '<div class="c"></div>';
      const b64 = fs.readFileSync(file).toString('base64');
      return `<div class="c"><img src="data:image/png;base64,${b64}"/></div>`;
    };
    const rows = meta
      .map((m) => {
        const cells =
          STOPS.map((pct) => cell(path.join(OUT_DIR, `${m.name}_f${pct}.png`))).join('') +
          (hasStill ? cell(path.join(OUT_DIR, `${m.name}_still.png`)) : '');
        return `<div class="r">
            <div class="lbl"><b>${m.name}.json</b>
              <span>${m.w}×${m.h} · ${m.duration}s · ${m.frames}f · one-shot</span></div>
            ${cells}
          </div>`;
      })
      .join('');
    await sheet.setContent(`<!doctype html><meta charset="utf-8"><style>
      *{box-sizing:border-box;margin:0;padding:0}
      body{width:${width}px;height:${height}px;background:#FBF7F0;font:12px/1.4 -apple-system,system-ui,sans-serif;color:#1E1B3A;padding:14px 18px}
      .h{border-bottom:2px solid #17804F;padding-bottom:8px;margin-bottom:6px}
      .t{font-size:17px;font-weight:800;letter-spacing:-.01em}
      .s{color:#6E6A8A;font-size:11px;margin-top:2px}
      .r{display:flex;align-items:center;gap:6px;padding:6px 0;border-bottom:1px solid #E7E0D4}
      .lbl{width:150px;flex:none}
      .lbl b{display:block;font-size:12.5px}
      .lbl span{color:#6E6A8A;font-size:10px}
      .c{width:${cellW - 12}px;height:${cellH}px;flex:none;display:flex;align-items:center;justify-content:center;
         background:#fff;border:1px solid #E7E0D4;border-radius:8px;overflow:hidden}
      .c img{max-width:100%;max-height:100%;display:block}
      .hdr{display:flex;gap:6px;padding:0 0 4px}
      .hdr .lbl{width:150px}
      .hdr div{width:${cellW - 12}px;text-align:center;font-size:10px;font-weight:700;color:#4A4668}
      .hdr div.st{color:#17804F}
      .c:empty{border-style:dashed;opacity:.5}
    </style><body>
      ${head}
      <div class="hdr"><div class="lbl">asset</div>${STOPS.map((s) => `<div>${s}%</div>`).join('')}${
        hasStill ? '<div class="st">still · reduced motion</div>' : ''
      }</div>
      ${rows}
    </body>`, { waitUntil: 'networkidle0' });
    await sheet.screenshot({ path: SHEET, fullPage: true });
    await page.close();
    console.log(`\n  ✓ contact sheet → ${path.relative(ROOT, SHEET)}\n`);
  }

  if (bad) {
    console.error('  ✗ one or more frames failed to render — see above.\n');
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
