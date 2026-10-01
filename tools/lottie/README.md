# tools/lottie/

Dev-only generator and previewer for Nestling's four Lottie one-shots. **Nothing
here ships with the app** — only the JSON it writes into
`app/assets/animations/lottie/` does.

```sh
npm install        # once — lottie-web + puppeteer-core (no Chromium download)
node build.js      # generate the JSON, enforce the invariants
node preview.js    # render frames headlessly + build the contact sheet
node preview.js check_tick   # …just one asset
```

## What it produces

| Output | Path |
| --- | --- |
| The animations | `app/assets/animations/lottie/*.json` |
| Per-frame stills | `design/animations/previews/<name>_f{0,25,50,75,100}.png` |
| Reduced-motion stills | `design/animations/previews/<name>_still.png` |
| Contact sheet | `design/animations/LOTTIE_PREVIEW.png` |

Docs, Flutter usage and the reduced-motion rule: `docs/animation/LOTTIE.md`.

## Why a generator

Bodymovin JSON is verbose, and every one of its failure modes is **silent** — a
file with the wrong property arity, a missing bezier handle or a style declared
before the geometry it paints loads without error and renders nothing at all.
`lib/bodymovin.js` exists so those rules are enforced in one place instead of
being rediscovered as a blank PNG:

- shape art must be authored in **layer-local** coordinates (a layer transform
  already applies `translate(position)`);
- a `gr` must contain exactly one `tr`, passed as the *second argument* —
  geometry must precede styles in `it`;
- every layer needs a unique `ind`; lottie-web indexes its element array by it,
  so one missing value blanks the whole file;
- every keyframe but the last needs `i`/`o` handles — lottie-web dereferences
  them unguarded;
- positions and anchors are emitted 2D, since neither runtime reads the third
  component;
- gradient stops are `[offset, r, g, b]` per stop with 0–1 offsets, and a
  gradient's `s`/`e` must be distinct points.

`build.js` additionally fails the build on an expression, an embedded image, a
frame rate other than 60, a duration that disagrees with `lib/brand.js`, a
missing/duplicate `ind`, a file over 40 KB, or a `still` marker that lands on a
frame where nothing draws.

## Why `preview.js` is not optional

`preview.js` renders with real Chrome and treats an empty SVG or a swallowed
renderer error as a **failure** (non-zero exit). lottie-web catches exceptions
inside `renderFrame` and re-emits them as an `error` event with an empty
`nativeError`, so without that check a broken file is indistinguishable from a
working one — which is exactly how four of these bugs shipped into the first
build.

Run it and **look at `design/animations/LOTTIE_PREVIEW.png`** after any change to
`lib/bodymovin.js` or `src/*.js`. It is the QA gate, the way
`tools/render-icon-sheet.mjs` is for icons.

## Layout

```
lib/bodymovin.js   Bodymovin writer — shapes, keyframes, easings, group ordering
lib/brand.js       Colours from tokens.css, durations, seeded PRNG, pendulum maths
src/*.js           One file per animation, each documenting its art source
build.js           Writes the JSON, enforces invariants, prints the size table
preview.js         Headless frame capture + contact sheet
```
