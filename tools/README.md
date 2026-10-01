# tools/

Dev-only scripts. Nothing here ships with the app.

## `render-icon-sheet.mjs`

Renders every `app/assets/icons/*.svg` into a labelled contact sheet so the
drawings can be checked at the size Flutter actually paints them.

```sh
npm i          # once - installs sharp
node tools/render-icon-sheet.mjs
```

Output: `design/ICONS_OVERVIEW.png`

- **Section A** — all icons at true **1x**: each glyph painted at 24 px inside a
  dashed 24 px viewBox, so overflow and mush at real size are both visible.
- **Section B** — the same geometry at **3x**, for catching shape errors that
  only show up when you can actually see them.

Nine columns. The script is the QA gate for icon work: after editing any
`ic_*.svg`, re-run it and read the PNG before calling the icon done.

## `sim_shots.sh` — design-system visual QA

One command screenshots every section of the design-system gallery, light and
dark, on the booted iPhone 16e simulator (390×844 @3x, the width the gallery is
built against), then builds a contact sheet per theme.

```sh
tools/sim_shots.sh <label>          # e.g. tools/sim_shots.sh baseline
```

Output in `design/qa/sim/<label>/`:

- `<theme>_<nn>_<slug>.png` — one shot per section, the section pinned to the
  top of the viewport so runs line up. `<theme>` is `light` or `dark`, `<nn>` is
  the capture order shared by both themes, `<slug>` is the section.
- `SHEET_light.png`, `SHEET_dark.png` — 4-column contact sheets, each shot
  scaled to 390 wide and captioned with its slug.

Then compare any two runs side by side, one row per section, with the pixel
difference in the gutter:

```sh
tools/sim_compare.py <labelA> <labelB>
# → design/qa/sim/compare_<A>_vs_<B>.png
```

The plumbing:

| Where | What |
| --- | --- |
| `app/integration_test/gallery_shots_test.dart` | walks the sections, calls `binding.takeScreenshot` |
| `app/test_driver/integration_test.dart` | writes the returned PNGs into `design/qa/sim/<label>/` |
| `tools/sim_shots.sh` | sets `RUN_LABEL`, runs `flutter drive`, builds the sheets |
| `tools/sim_sheet.py` | the contact sheet (also runnable alone: `sim_sheet.py <label>`) |
| `tools/sim_compare.py` | the A/B sheet |

Sections are found by their `ValueKey('ds-section-<slug>')`. Add a section to the
gallery and the key goes on the section label (or the `_Section` in
`design_system_gallery_view.dart`); add the slug to `gallerySections` in the
integration test so it gets a stable number in the file names. The run takes a
few minutes — `flutter drive` builds the app — and the simulator must be booted.

Two things to expect in the output: the red **DEBUG** ribbon in the corner of
every shot (`flutter drive` runs a debug build; `debugShowCheckedModeBanner:
false` in `NestlingApp` removes it), and a moving `*_motion.png`, because the
motion lab plays its scripted demo while the shutter is open.

## `rive/`

Rive CLI (vendored, unsigned) plus the RML source for `pip.riv`.
See `docs/animation/RIVE_GUIDE.md`.

## `lottie/`

Node generator and headless previewer for the four Lottie one-shots. The
animations are **generated, not hand-edited** — `build.js` writes the JSON and
`preview.js` renders frames to a contact sheet.

```sh
cd tools/lottie && npm i   # once — lottie-web + puppeteer-core
node tools/lottie/build.js
node tools/lottie/preview.js
```

Output: `app/assets/animations/lottie/*.json`, `design/animations/previews/`,
`design/animations/LOTTIE_PREVIEW.png`. See `docs/animation/LOTTIE.md`.

`preview.js` is the QA gate for animation work, for the same reason the icon
sheet is: Lottie's authoring errors are **silent** — a valid-looking JSON file
that renders nothing — so the render is checked and the run exits non-zero on an
empty frame.
