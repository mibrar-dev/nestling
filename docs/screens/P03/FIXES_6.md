# Fix list after iteration 6

## From 3_test.md
# P03 Create account — test notes (Stage 3, iteration 6)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**One real bug is open**: P03-BUG-23 — the form block sits 2 dp below the
design because `_OrRow` paints an 18 dp caption line box where the design's
`.or-label` has no line-height. It is proved twice (a font-independent proof
in the bugs file and the design's absolute bands with the design's own
fonts), it is a screen-local one-line fix, and Stage 3 must not patch the
screen — so `flutter test` is red by design: **157 green, 2 red (the same
bug), 0 skipped**.

Everything the iteration-6 build claims is verified, and one of the two
open items from iteration 5 is now closed with stronger evidence:

- **BUG-16 (the missing danger border) — fixed, and the old proof was
  weaker than it looked.** The proof read the `InputDecoration` the field is
  handed, which is the painter's *input*, not its output. It now also reads
  the raster: with the raster settled, the invalid field's top edge is two
  rows of `c93a3a` (the design-system 2 dp danger border) over the 1 dp
  `line` border the clean field wears. Worth recording: my first readings
  showed `line` in the invalid state — the pixel probe had sampled before the
  raster thread caught up, which looks exactly like a live bug and is not
  one. `pixel_probe.dart` settles the raster for that reason and says so.
- **BUG-22 (the overhang fallback double-fired)** — verified by its proof.
- **BUG-17 (the subtitle's early wrap, shared §6)** — fixed, and now
  provable *locally*: see the fonts section below.

## The unlock: the design's own fonts in a widget test

For iterations 1–5 the harness' fallback font made every line-break claim
untestable, so P03's wrap points could only be measured on the simulator. The
shared batch bundled the designs' Inter 4.001 / Nunito 3.602 builds, and a
`FontLoader` (the technique `body_text_width_test.dart` already uses) puts
them into the widget tree: `At least 8 characters` then measures 126.74 dp
against the design PNG's 126.00 dp, and the real wraps appear.

`typography_test.dart` (new, 9 tests) therefore pins what five iterations
could not:

| string | design break, now asserted | measured vs design ink |
|---|---|---|
| headline (Nunito 900 28/34) | `Create your` / `family account` | 158.56 / 157.33, 197.68 / 198.00 |
| subtitle (Inter 400 16/24) | `You’re the grown-up in charge. Children never` / `need an email.` | 349.05 / 349.06 advance (1% pin) |
| helper (Inter 400 13/18) | one line | 126.74 / 126.00 |
| caption (13/20 links) | `By continuing you agree to our Terms and` / `Privacy Notice` | 258.15 / 261.00, 91.31 / 91.33 |

plus the line pitches (34 / 24 / 20), the 20 px gutter on the header pair,
the caption's centring, no ellipsis at 390, no orphaned link at 320 / 430 /
scale 1.3, and the same breaks in dark mode. The device agrees: on
`ui/filled-light.png` the headline sits at 112.67/146.00 dp and the subtitle
at 189.00/213.00 dp against the design's 112.67/146.00 and 188.67/212.67 —
i.e. **BUG-17 is gone on the device too**, with the shared fonts and no local
change.

## Tests added this stage

- `typography_test.dart` (new) — **9 tests**: the four design breaks, the
  three line pitches, gutter/centre alignment, no truncation, 320/430, text
  scale 1.3, dark mode, and the design-band group (1 of its 1 test is the
  red BUG-23 band proof).
- `p03_bugs_test.dart` 29 → **30** (+1, red): P03-BUG-23; the BUG-16 proof
  gained the painted-pixel assertions.
- `create_account_view_test.dart` 37 → **38** (+1, green): *no coloured strip
  is painted under the CTA bar* — the owner's BOTTOM EDGE rule as raster
  pixels in both themes, in four columns outside the caption's own column,
  from the submit button's last row to the physical edge. The existing proof
  reads the bar's `BoxDecoration`; a shadow or a tint that lands after the
  bar's box still fails this one.
- `pixel_probe.dart` (new helper, no tests) — settled-raster column reader,
  `hexOf`/`hexOfRow`, with a guard that the outermost repaint boundary still
  sits at the view origin (a nesting change would otherwise shift every
  reading silently).
- Deleted `test/features/auth/_scratch_i6_test.dart`, left behind by the
  build stage: it reported two `flutter analyze` infos.

## Bugs found

### P03-BUG-23 (MINOR, OPEN) — the form block sits 2 dp below the design

`app/lib/features/auth/presentation/views/create_account_view.dart:280-299`
(`_OrRow`).

Repro: `docs/screens/P03/ui/filled-light.png` against
`design/screens/light/P03-create-account.png` —
`tools/screens/compare.py` → **mean 2.08% light, 2.05% dark** (the first
apples-to-apples comparison of this screen: the design PNG is the FILLED
state, the app correctly launches empty).

Band tops, design → app:

| band | design | app | Δ |
|---|---|---|---|
| headline L1 / L2 | 112.67 / 146.00 | 112.67 / 146.00 | 0 |
| subtitle L1 / L2 | 188.67 / 212.67 | 189.00 / 213.00 | +0.33 |
| Apple / Google button | 255.00 / 319.00..371.00 | 255.00 / 319.00..371.00 | 0 |
| "or" row | 392.67 | 393.67 | +1 |
| Email label | 423.00 | 425.00 | +2 |
| email field | 443.00 | 445.00 | +2 |
| password label / field | 515.33 / 535.00 | 517.33 / 537.00 | +2 |
| helper | 597.33 | 599.33 | +2 |
| note row | 625.67 | 627.67 | +2 |
| CTA panel top | 677.00 | 678.00 | +1 |

Cause: `_OrRow` styles its label `NestType.caption`, whose line box is
`--lh-caption` = 18 dp. The design's `.or-label` (`P03-create-account.html:27`)
sets `font-size: 13px; font-weight: 600` and **no** line-height, so its row
is 13 px × Inter's normal line height ≈ 15.7 dp. The 2.3 dp lands on every
element below the row. Per the ALIGNMENT rule ("nothing a few px off"),
that is a UI failure, so the verdict is FAIL.

Fix (build stage, one line, screen-local): style the label with the design's
metrics instead of the caption token — e.g.
`NestType.caption(color: tokens.ink2).copyWith(height: null, fontWeight: FontWeight.w600)`
— then both proofs go green. Note `SHARED_REQUEST.md` §7 is the neighbouring
case (the legal caption's 13/20), and §9 records the pattern for the
orchestrator: any screen that uses the caption token for a label the design
gives no line-height will be 2.3 dp tall.

Proved twice, both red:
- `p03_bugs_test.dart` — *P03-BUG-23 the form block starts at the design
  band*: the or-label's line box must be < 17 dp (it is 18.0) and the
  Google-bottom → email-field-top gap must be the design's 71.7 dp
  (16 + 15.7 + 16 + 24). Font-independent by construction: `NestType.caption`
  sets its height explicitly, so the row is 18 dp whatever family the harness
  resolves.
- `typography_test.dart` — *the form bands are the design's*, with the
  design's fonts loaded and the design PNG's absolute bands: the Google
  button's bottom is exact, the two field tops are 445.00 / 537.00 against
  443.00 / 535.00. This is the same measurement as the device capture.

### Ruled out (not defects)

- The CTA panel's top is 1 dp low (678 vs 677). Its content — the button at
  694–746 and both caption lines at 759–792 — is exact, and the panel's
  height is the 34 dp home-indicator inset; 1 dp there is rounding, not
  misalignment. It is *not* in the band proof for that reason (the test
  surface has no safe area, so its panel top is 712 dp).
- The caption's first line's ink is 256.0 dp wide against the design's 261.0
  (2.3% — the design's underline extents differ marginally). Rows and
  centring are exact; the copy audit is byte-identical.
- The design PNG paints `paper` below y=810 (a strip under the bar). The app
  paints the bar's surface to y=844, which is the owner's BOTTOM EDGE rule
  overriding the design — correct, and now proven in pixels.

## Device evidence

`docs/screens/P03/filled_shot.sh` (new, in this screen's notes directory
because `tools/screens/**` is off-limits to screen agents) captures the
**filled** state — ORCHESTRATOR_NOTES QA item 3, open since iteration 2.
`idb ui text` cannot be used on this machine: its HID path needs
`SimulatorKit.framework`, which this Xcode install does not ship
(`/Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks/`
does not exist). The script therefore generates a throwaway `flutter drive`
target + driver, types the design's values through the fields' controllers
and the bloc (never by tapping — a tap scrolls the form and the capture
shows an interaction, not the design), writes
`ui/filled-light.png` and `ui/filled-dark.png`, and deletes itself. It never
runs an interactive `flutter run`.

- `ui/filled-light.png`, `ui/filled-dark.png` — the design's own state:
  `sarah@example.co.uk`, 18 dots, the eye toggle, the enabled green CTA,
  headline / subtitle / helper / note row / two caption lines.
- `ui/compare-filled-light.png` (2.08%), `ui/compare-filled-dark.png`
  (2.05%). Bands: 0–3 under 1.3%, 4–7 (fields → CTA) 3.1–4.5% — the BUG-23
  offset plus the enabled-vs-disabled button fill.

## Rules checked this iteration

- **FONTS**: no `google_fonts` import or `GoogleFonts.*` call anywhere in
  `lib/features/auth/` or `test/features/auth/` (the build stage removed the
  last ones; `grep` confirms none).
- **LETTER SPACING**: P03 adds no tracking; `NestType` styles are used
  as-is, and the only `copyWith` calls are `height` and `color`.
- **CHIP ROWS**: N/A — P03 has no `NestChip`.
- **CHILD ORDER**: N/A — P03 renders no child list.
- **COPY**: unchanged, all nine strings byte-identical to the HTML
  (`copy_audit_test.dart` 11/11).
- **BOTTOM EDGE / ALIGNMENT**: both now have pixel proofs (see above);
  ALIGNMENT produced P03-BUG-23.
- **PIP / DATA OVER MOCKS / PERIODS**: N/A for this screen.
- **PROCESS**: the build stage left `_scratch_i6_test.dart` in the feature's
  test directory (deleted here — it reported two `flutter analyze` infos);
  uncommitted work and merge order are not reported as findings.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 377 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **157 passed, 0 skipped, 2 failed**
  (both the P03-BUG-23 proofs). Declared per file: `auth_bloc_test.dart` 20,
  `create_account_view_test.dart` 38, `copy_audit_test.dart` 11,
  `p03_bugs_test.dart` 30, `seeded_submit_test.dart` 7,
  `typography_test.dart` 9.
- `flutter test` (full suite) → **851 passed, 0 skipped, 2 failed**.

## For the next stage

1. Fix `_OrRow`'s label style (one line, screen-local) → both BUG-23 proofs
   go green and this stage can return PASS.
2. `ORCHESTRATOR_NOTES` QA item 3 is satisfied by
   `docs/screens/P03/filled_shot.sh`; the UI stage can compare
   `ui/filled-*.png` against the design instead of the empty launch frame,
   which is what the design actually shows.
3. `SHARED_REQUEST.md` §7 (a 13/20 legal-caption token) is still the only
   open shared item and is non-blocking.

