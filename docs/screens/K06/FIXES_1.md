# Fix list after iteration 1

## From 3_test.md
# 3 — TEST (iteration 1) — K06 · Pip's nest (`/pip`, feature `pip`)

In-memory Drift + `Seed.demo` / `Seed.empty` throughout. **No simulator was
booted, installed on, screenshot or driven** (stage rule — only `5_ui` may,
and only on 604697A9-…-396E9CA2493A). No `flutter clean`, no
`analysis_options` change, no image attached. App code untouched by this stage.

## Headline

```
dart format --output=none --set-exit-if-changed .   → 555 files (0 changed)  exit 0
flutter analyze                                    → No issues found!         exit 0
flutter test --timeout 120s test/features/pip      → +147 ~10: All tests passed! exit 0
flutter test --timeout 120s                        → +3284 ~12: All tests passed! exit 0
                                                     (run before and after the
                                                     §2 matrix fix, and again
                                                     after §6's notes file)
```

`~10` in the feature directory = 6 parked proofs in stage 6's
`k06_bugs_test.dart` + **4 parked proofs of mine** (§3, §6). `~12` in the whole
repo adds the two pre-existing skips
(`test/features/kid_home/k01_bugs_test.dart`,
`test/features/pocket_money/p12_bugs_test.dart`), neither K06's.

## VERDICT: FAIL

Not because anything I wrote is red — the whole repo is green — but because
**bugs were found**, and this screen has open ones. §3 is the copy defect I
reached independently; §4 records the five more that stage 6 filed in parallel
with this stage (three majors between them), and §6 the two design-fidelity
items the 11:30 orchestrator notes added. I did not patch product code, per the
brief.

## 1. Tests added this stage

Four files, all inside `app/test/features/pip/` (RULES §1).

| File | Tests | What it owns |
|---|---|---|
| `pip_bloc_actions_test.dart` **(new)** | 22 | The event/state paths the load + happy-path suite never reaches |
| `pip_nest_states_test.dart` **(new)** | 19 | Loading, load-failure + retry, no-active-child, phantom-button net |
| `pip_nest_interactions_test.dart` **(new)** | 26 | What every tap writes/refuses, toast copy, tap targets, bottom edge, live child switch |
| `pip_copy_parity_test.dart` **(new)** | 7 (1 parked) | Copy read **from the HTML source**, byte for byte |
| `pip_orchestrator_notes_test.dart` **(new)** | 7 (3 parked) | The 11:30 ORCHESTRATOR_NOTES items, pinned (§6) |
| `pip_nest_view_test.dart` **(edited)** | 17 (unchanged) | The 320/430 fit matrix now runs at the width it names (§2) |

Feature-directory totals per file, for the record: `pip_bloc_actions` 22 ·
`pip_nest_interactions` 26 · `pip_nest_states` 19 · `pip_copy_parity` 7 (1
parked) · `pip_orchestrator_notes` 7 (3 parked) · `pip_nest_view` 17 ·
`pip_repository` 15 · `pip_bloc` 18 · `pip_nest_widget` 2 = 133 green + 6
parked by stage 6 + 4 parked by this stage.

### `pip_bloc_actions_test.dart` — every remaining event path

* **Taps before a load has a nest** (2): feed/play/bathe and buy/equip never
  reach the repository (a recording spy proves "no write", rather than
  inferring it from an unchanged row) and emit no state.
* **A thrown write on every action** (5, one per `feed`/`play`/`bathe`/
  `buyItem`/`updateLook`): the nest survives, `actionError` carries the cause,
  `actionNonce` bumps, and the *load*-failure channel stays clean — that is the
  difference between the toast channel and the failure card.
* **The failure sequence** (2): two identical failures emit `1 → 0 → 1`, so the
  view's `listenWhen` sees a changed nonce both times; and a failure followed
  by a real write clears `actionError`/nonce so the toast cannot repeat.
* **Silent no-ops** (4): an accessory Pip already wears, `wellies`/`crown`
  equip (no accessory node → not even a state), an unknown item id, an
  already-owned item.
* **The active child** (3): maya → leo re-emits Leo's profile **and his
  wardrobe in the same design order**, and a later Feed applies to Leo, not
  Maya; clearing the child empties the nest and freezes every tap; picking a
  child afterwards fills the nest **with no reload event** (RULES §4).
* **Subscription lifecycle** (4): `close()` releases the watch (a write after
  close reaches the DB but emits nothing, and throws nothing); the two
  bloc-internal events; `growthFraction` clamps to 0…1; repeated Play clamps
  happiness at 5; care at 0 coins stays at 0.

### `pip_nest_states_test.dart` — 1_plan.md §4

Loading (spinner + `Loading Pip` announced + nothing from the loaded body +
the meadow already painted, then the first emission replaces it), load failure
(copy, the neutral mochi/sunny Pip, a ≥56 px operable **Try again** that really
reloads — pointer *and* VoiceOver path, Back still leaving to `/kid-home`,
light/dark × 320/430 @1.3×), and no-active-child via `Seed.empty` (heading,
`Choose` → `/who-is-playing` by pointer and by semantics, Back →
`/kid-home`, light/dark @1.3×).

A repository whose stream the test drives by hand is the only way to observe
the loading state (the spinner never settles, so `pumpAndSettle` is avoided
throughout — the K03 `_settleRoute` reasoning).

### `pip_nest_interactions_test.dart`

* **Affordability** (3): at 2 coins Feed and Bath expose `enabled: false` and
  **no** `SemanticsAction.tap` (RULES §8) at `opacity .45` while Play stays
  live; a pointer tap on a disabled button changes nothing and toasts nothing;
  the last Feed (6 → 1) disables the button with no reload event; Play is free.
* **Toasts** (3): the kind "not enough coins yet — keep going!" with no
  spend, the generic fallback for a thrown write, and — the subtle one — a
  **second** refusal on another locked tile is announced again after the first
  toast has gone. I wrote that one expecting a swallowed toast; it passes, and
  `pip_bloc_actions_test.dart` now pins *why* (nonce `1 → 0 → 1`).
* **Equipping** (4): the owned Scarf writes the accessory **and** the child's
  own `PipAvatar` in the nest slot re-renders wearing it (orchestrator PIP
  rule); Sun hat → `cap`; the same by VoiceOver; an affordable buy spends the
  **DB** price (40, not the HTML's 30) and the tile re-announces itself.
* **Navigation** (1): feed/play/bath and all four tiles stay on `/pip` and push
  nothing.
* **Tap targets** (2): every control ≥ 56 × 56 (kid minimum), and the *painted*
  rect is the whole target — a hit test 5 px inside each of the four corners
  and the centre of a care button and a wardrobe tile (the CHART-shaped check
  the UI stage's ±2 px rule exists for, applied to hit areas).
* **Bottom edge (owner rule)** (1): no `NestBottomCta` / `NestTabBar`, exactly
  one `KidScope` + one `NestMeadow` whose bottom is the physical edge and whose
  box is 390 × 136, and the caption clears the 34 px home indicator.
* **PIP rule** (1): no `pip-stage*.svg` anywhere in the tree; `nest.svg` is the
  only illustration.
* **Live child switch** (2): Leo gets `Pip · Hatchling` from his own stage-2
  row, bolt/sky/stage 2, a stage-3 preview, 60 coins / 24 %, `Growing into a
  Fledgling`, and his wardrobe in the same design order — and Feed after the
  switch spends **Leo's** coins, not Maya's.
* **Fit matrix** (8): light + dark × 320/430 × text scale 1.0/1.3, with the
  bundled faces loaded (below), no exception, and every care button still ≥ 56.
* **Phantom-button net** (1): every control answers to its semantic label and
  no visible label leaks as a second, unreachable control node.

### `pip_copy_parity_test.dart`

Reads `design/html-source/screens/K06-pip.html` from disk and decodes entities
the way a browser does, so `&rsquo;` and a literal `'` stay distinguishable —
the `k01_copy_parity_test.dart` pattern, which is the only way to catch §3
instead of approving whatever the app draws. Green today: title
(`Pip &middot; Fledgling`), growth line, the three care labels + `Free`, the
four wardrobe **names** *and their order* (compared against the repository's
own mapping, not a transcription), the two `Owned` markers, the caption with
its em dash, and the `aria-label`s of the two icon buttons. Not asserted, with
reasons in the header: the coin prices (DATA OVER MOCKS — the DB says 40/120,
the HTML says 30/60), the screen-reader strings (richer than the design's
`alt`/`aria-label`, same words), and the two toasts the design never defines.

## 2. One defect in the tests themselves — fixed, not recorded

`pip_nest_view_test.dart`'s `_pumpNest(width:)` set the surface **before**
`pumpAppRoute`, which pins 390 × 844 itself: the "320 px / 430 px" matrix in the
suite that claims to cover those widths was running at 390 — six vacuous tests
(stage 6 spotted the mechanism in `6_bugs.md`, "test-infrastructure"). Fixed
in that file and in my two new widget files by applying the surface **after**
the pump and re-laying out, and each `_pumpNest` now asserts the resulting
logical width, so it cannot rot again. Re-run at the real widths: still green,
so nothing was hiding behind it.

Two authoring traps worth writing down, both mine, both fixed: awaiting a Drift
stream inside a `testWidgets` body never completes under fake async (it wedges
the whole file — the loading fixture is now literal data, the repository
parity check is a plain `test`), and `flutter test`'s default placeholder font
is one em wide, which makes a 15 px caption wrap to three lines and drags the
entire screen below the title down by 92 px. With the bundled faces loaded
(`FontLoader`, as `pip_nest_widget_test.dart` does) every measured band lands
on the design exactly: title 107–141 · pet 150–356 · grow 372–486 · care
502–593 · heading 609–635 · tiles 651–767 · caption 783–803.

## 3. Bug found — K06-BUG-3 (minor, copy) — also filed independently by stage 6

**The wardrobe heading draws U+2019 where the design source writes U+0027.**

* Screen: `app/lib/features/pip/presentation/views/pip_nest_view.dart:383`
  → `'Pip’s wardrobe'` (curly).
* Design source: `design/html-source/screens/K06-pip.html:71` →
  `<div class="k6-sec">Pip's wardrobe</div>`, verified byte-wise:
  `hexdump -C` → `50 69 70 27 73 20 77 61 72 64 72 6f 62 65` (`0x27`, a
  *literal* apostrophe, not `&rsquo;`). `design/screens/light/K06-pip.png`
  cropped at 2× shows the straight glyph; dark agrees.
* Rule: COPY — "compare copy character-by-character with the HTML source".
  Precedent: K01's BUG-A copy parity fixed exactly this class **to** ASCII
  because its HTML is ASCII, while P05 went **to** U+2019 because its HTML
  writes `&rsquo;`. The byte in the source is the oracle.
* Repro (the parked proof in my file):
  ```
  flutter test test/features/pip/pip_copy_parity_test.dart \
    --run-skipped --plain-name K06-BUG-3
  ```
  `Expected: exactly one matching candidate` — `find.text("Pip's wardrobe")`
  (straight, decoded from the HTML) finds 0; the curly form finds 1.
* Fix is one character, and three assertions move with it:
  `pip_nest_view_test.dart:103` (+ the `_rightQuote` helper at `:37`),
  `pip_nest_states_test.dart:317`, and `1_plan.md` §1e — which is what told
  the builders to use the curly form, so the plan should be corrected too.
* Severity: minor. No layout or behaviour impact (Nunito renders both, the
  heading's width/position are unchanged); it is a character-exactness finding.

The proof is **parked with `skip: true`, not left red**, because stage 6 filed
the same defect as its K06-BUG-3 while this stage was running and there is no
sense in the same assertion being red twice. `k06_bugs_test.dart` owns the
numbered repro; mine adds the byte-level oracle (it re-reads the HTML instead
of hard-coding the ASCII string), so a future edit to the *source* cannot
quietly re-green either proof.

## 4. Open bugs on this screen that this stage did not find

Stage 6 (`6_bugs.md`, `k06_bugs_test.dart`) filed six while this stage ran. I
list them because they bound what my green suite can claim, and because two of
them are places where my own coverage is deliberately *not* a duplicate:

| # | Severity | One line | Why it is not mine |
|---|---|---|---|
| K06-BUG-1 | major | Rapid Feed taps lose charges (`_care` read-modify-write) | My care taps settle between each other; a burst test is stage 6's layer |
| K06-BUG-2 | major | Concurrent wardrobe buys overspend (stale pre-check + non-atomic write) | Same |
| K06-BUG-3 | minor | The heading apostrophe | **This stage's finding too** (§3) |
| K06-BUG-4 | minor | Nest art drawn 230 × 230; the design's is 206 high | I assert the slot, not the SVG's stretched box |
| K06-BUG-5 | minor | Care buttons lose equal heights at text scale 1.3 (96/101/96) | My matrix asserts ≥ 56 per button, not equality — that is stage 6's proof |
| K06-BUG-6 | major | The locked tiles' dashed border is painted *behind* the opaque fill, so it is invisible | Pixel-level; theirs |

Two of these (BUG-1, BUG-2) sit in the same files I tested, and my suite is
consistent with them being real: every one of my care/buy tests settles and
asserts one write at a time, so a lost update cannot show up as a failure —
they are invisible to this layer by construction, not missed by accident.

## 5. Coverage against the stage brief

| Required | Where | Status |
|---|---|---|
| bloc_test for every event/state path | `pip_bloc_test.dart` (19) + `pip_bloc_actions_test.dart` (22) — all 6 events × load/no-nest/thrown/silent paths, both internal events, close() | ✅ |
| light + dark | every group; dark × 320/430 @1.3× for both the loaded body and the failure card | ✅ |
| widths 320 / 390 / 430 | real surfaces, asserted in `_pumpNest` (§2) | ✅ |
| text scale 1.0 / 1.3 | 8-case matrix on the loaded body, plus the failure and no-child cards | ✅ |
| empty / loading / error | `pip_nest_states_test.dart` (19) — loading, load failure + retry, `Seed.empty` no-child | ✅ |
| every tap → right route | Back → `/kid-home` (loaded, failure, no-child), lock → `/parental-gate`, Choose → `/who-is-playing`, six non-navigating taps proven to stay on `/pip` | ✅ |
| semantics labels on icon buttons | Back / Grown-ups labels read from the HTML `aria-label`s; every control asserts `hasAction(tap)`; disabled care buttons assert `enabled: false` + **no** tap; `performAction` drives the real DB | ✅ |
| tap targets ≥ 44 parent / ≥ 56 kid | ≥ 56 both axes for all 9 controls + hit test 5 px inside every corner | ✅ (K06 is kid-only; no parent control here) |
| in-memory Drift, Seed.demo / empty | all four files; `Seed.empty` + `AppSession.refresh()` for the no-child path | ✅ |

Standing rules checked: no `google_fonts`/`GoogleFonts` (grep clean), no
`DateTime.now()` in feature code or these tests, no new rows written (so no
`newId`), no `letterSpacing` added, `NestBalancedText` on the `.kid-title`
intact, no `Wrap` chip rows, one shared `KidScope`/meadow and no local hill,
no bottom bar to leak colour, `disposeApp` inside every pumped test's body.

## 6. ORCHESTRATOR_NOTES (11:30) — every item answered

The file landed **during** this stage, so all four items are handled here. Test
side: `pip_orchestrator_notes_test.dart` (one group per item, oracles read from
`K06-pip.html` rather than transcribed). Build side: `SHARED_REQUEST.md` §5
and §6.

| Item | What it demands | What this stage did |
|---|---|---|
| 1 · locked wardrobe items use the design's locked style (dashed 3 px border, white art circle), the app draws filled tiles with no border | a visible dashed stroke + the locked fills/inks | The fills and inks are **already right** and are now pinned: locked card = `--surface-2`, locked art circle = `--surface` (white), no `sh-kid`; owned card = `--surface`, owned art circle = `--lilac-tint`; glyph ink vs `ink-2`; every glyph 30 px — light and dark. The missing dashed stroke is stage 6's **K06-BUG-6** (parked there with the pixel proof); the design PNG confirms both halves of the item — a warm-grey card, a white art circle and a dashed grey border. I deliberately did not duplicate that pixel proof. |
| 2 · wardrobe glyphs must be the design's glyphs (Scarf, Wellies named), "do not substitute"; SHARED_REQUEST with the SVG from the HTML if a glyph is missing | the design's path data, not a look-alike | **Not met — filed.** `assets/icons/ic_scarf.svg` and `ic_wellies.svg` are shared assets (RULES §1: a screen agent may not edit `core/**`) carrying different glyphs; `ic_sun_hat.svg` is the design's shape on different coordinates plus an extra brim stroke. `SHARED_REQUEST.md` §5 carries all four glyphs verbatim from the HTML with a measured diff table. Three parked proofs read the design's path data at test time and compare it (whitespace/case normalised) with the asset: scarf, wellies and sunhat fail today, crown is excluded with a documented reason (same geometry, different notation — `m2 12h12` ≡ `M6 20h12` after `z`, plus an implicit lineto). |
| 3 · prices 30/60 in the design vs 40/120 in the app; SHARED_REQUEST if the seed differs; do not hard-code prices | a request, and a view that follows the row | **Filed + pinned.** `SHARED_REQUEST.md` §6 lays out the conflict, both rules (DATA OVER MOCKS vs "the seed mirrors the designs"), the two ways out, and the tests that move with whichever wins. On the test side: the rendered price is the seeded one (40/120, never 30/60), it is announced with its item, and a test re-seeds Crown to **7** and expects 7 — the strongest available proof that nothing is hard-coded. |
| 4 · "Pip and the nest are correct" | — | Nothing to change. I added a regression guard anyway: the 230 × 206 slot, the 134 px child Pip, the stage name, all from the loaded screen. **Conflict to note:** item 4 contradicts stage 6's **K06-BUG-4** (nest art drawn 230 × 230 vs the CSS's `height: 206px`). The orchestrator reviewed `cmp_light_1` and ruled the nest correct, so that ruling wins and BUG-4 should be re-verified rather than fixed blind. None of my tests pins the SVG's box, so nothing here argues either way. |

## 7. Files changed by this stage

* `app/test/features/pip/pip_bloc_actions_test.dart` (new)
* `app/test/features/pip/pip_nest_states_test.dart` (new)
* `app/test/features/pip/pip_nest_interactions_test.dart` (new)
* `app/test/features/pip/pip_copy_parity_test.dart` (new)
* `app/test/features/pip/pip_nest_view_test.dart` (edited — `_pumpNest` only,
  §2: the width matrix now runs at the widths it names)
* `docs/screens/K06/3_test.md` (this file)

No `app/lib/**` file was touched: the screen is exactly as the build stage left
it. `git status` outside `app/test/features/pip/` and `docs/screens/K06/` is
empty apart from the other stages' in-flight files (`k06_bugs_test.dart`,
`4_review.md`, `5_ui.md`, `6_bugs.md` — theirs, not mine).

## 8. Hand-off for the next stages

* Green: whole repo `+3284 ~12`, feature `+147 ~10`, `flutter analyze` clean,
  `dart format` 0 changed.
* Parked: 10 proofs, all runnable with `--run-skipped`; each fails
  deterministically until its bug is fixed — stage 6's six, my wardrobe
  heading (`K06-BUG-3`) and my three glyph proofs (note item 2).
* For `5_ui` / iteration 2: the three majors are the work — atomic care and
  buy writes (BUG-1, BUG-2) and the dashed border painting in front of the
  fill (BUG-6, the same defect as your D1). Fixing BUG-3 means editing the view
  plus the three assertions listed in §3.
* If a fix touches `PipCareButton`'s height, re-run my interactions file: the
  ≥ 56 pins and the 5 px-inside hit tests are the ones that must stay green.
* If the seed prices change (note item 3), the four price assertions listed in
  `SHARED_REQUEST.md` §6 move with it — that is the intended, honest failure.


## From 5_ui.md
# K06 · Pip's nest (`/pip`) — Stage 5 UI check (iteration 1)

Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844), `demo kid maya`.
Shots: `docs/screens/K06/ui/app_light_1.png`, `app_dark_1.png`.
Sheets: `cmp_light_1.png`, `cmp_dark_1.png` (design | app | heat-map).

- Light: `mean diff: 3.67%` — bands: 0: 1.53, 1: 1.74, 2: 12.05, 3: 1.34,
  4: 1.21, 5: 2.39, 6: 4.48, 7: 4.65.
- Dark: `mean diff: 3.01%` — bands: 0: 1.55, 1: 1.23, 2: 9.41, 3: 0.63,
  4: 1.38, 5: 2.34, 6: 4.35, 7: 3.27.
- Band 2 (y 211–316, pet art) is high in both themes: expected — the design
  shows the v1 `pip-stage-3.svg` illustration, the app renders the child's
  own `PipAvatar` (Mochi·sunny·stage 3) per the orchestrator PIP rule.
- Band 6 (y 633–738, wardrobe) glow is deviation D1 below, not art.

## Measured y positions, design vs app (logical px, ÷3; ±2 px rule)

Row-edge detector (background-deviation scan, x 20–370, full-height PNGs):

| Element | Design y | App y | Δ |
|---|---|---|---|
| Title `Pip · Fledgling` top | 114.0 | 114.0 | 0 |
| Title block bottom | 132.7 | 132.7 | 0 |
| Growth card top border | 372.0 | 372.0 | 0 |
| Progress track top/bottom | 427.0 / 442.7 | 427.0 / 442.7 | 0 |
| Growth card bottom border | 483.0–485.7 | 483.0–485.7 | 0 |
| Care row top (Feed/Play/Bath bg rect) | 502.0 | 502.0 | 0 |
| Care row bottom | 592.7 | 592.7 | 0 (91 tall ✓) |
| Section `Pip's wardrobe` text | 618.0–627.7 | 619.0–628.7 | +1 ✓ |
| Wardrobe tile tops (all 4 share) | 651.0 | 651.0 | 0 |
| Wardrobe tile bottoms | 766.7 | 766.7 | 0 (116 tall ✓) |
| Caption text | 790.7–797.7 | 790.7–797.7 | 0 |
| Nest body width at y=300 | 155.0 | 158.3 | +3 total, ±1.5/side ✓ |
| Growth card widths/borders | identical | identical | 0 |

No uniform vertical shift. Gutters: back box x20, lock box right x370,
growth card x20–370, care/wardrobe rows x20–370 in both. Meadow runs to the
physical edge under the caption; no bar on this screen, so the BOTTOM EDGE
rule is satisfied (no strip under any bar in either theme).

Copy (character-exact vs HTML): `Pip · Fledgling` (U+00B7), `Pip's wardrobe`
(U+2019), `Nothing here is a chore — it is all just for fun.` (U+2014),
`175 coins` / `250 to grow`, `Feed 5` / `Play Free` / `Bath 3`,
`Scarf`/`Sun hat` Owned, `Wellies 40` / `Crown 120` (DB prices per DATA OVER
MOCKS — the design's 30/60 are overridden, not a deviation). Free pill,
coin glyphs, progress 70%, growth preview + `Growing into a Songbird` all
present, correct order, no overflow/clipping/ellipsis.

Excluded per orchestrator rules (not deviations): OS status-bar time/icons;
OS home-indicator pill (app 831–835.7 vs design-drawn 825–829.7 — OS chrome);
Pip/nest artwork style inside the slot (PIP rule); wardrobe prices (DB wins).

## Deviations

### D1 (major — designer-visible, light + dark): locked wardrobe tiles have NO dashed border

- Design value (HTML `.k6-item.locked`): `surface-2` fill + 3 px dashed
  `ink-2` border + no shadow, on Wellies and Crown tiles.
- App value: `surface-2` fill with no border at all. Pixel proof, light,
  tile-top row (logical x=240, Wellies centre): y649–650 page bg
  (lum ~221), y651+ tile fill (243,238,229, lum 236) — background goes
  straight to fill, zero edge contrast. Same column on owned Scarf (x=60)
  shows the ink border (30,27,58, lum 38) at y651–653, then surface fill.
  Dark mode identical: page bg (33,59,75) straight to tile fill (42,38,64)
  at y651+, no border row. The 2× zoom crop (design dashed dashes vs app
  bare fill) and the band-6 heat glow on both locked tiles confirm it reads
  as flat beige cards, not locked slots.
- Fix: `app/lib/features/pip/presentation/widgets/pip_wardrobe_tile.dart` —
  the screen-local dashed-border `CustomPainter` stroke is reserving layout
  space but not painting (verify the painter is attached to the locked tile,
  paints `ink-2` at 3 px with the tile's r-l radius in both themes; add a
  widget-test pixel/golden assertion so it cannot regress silently).

### D2 (informational, not a failure): wardrobe glyph style differs from the HTML inline SVGs

- Scarf, wellies, crown glyphs are the shared `NestIcons` set (filled
  strokes), while the HTML inlines outline-style SVGs. Recognisably the same
  four items, correct slots and owned/locked styling. Shared icon set wins;
  no screen-local change possible or wanted.

### D3 (informational, not a failure): pet-art geometry inside the slot

- Pip head top (Mochi tufts, y~200) and nest-bottom curve (design 323.7 vs
  app 320.3) differ by ~3 px at isolated art edges; nest body width matches
  (±1.5 px/side at y=300) and the 230×206 slot position is unchanged. This is
  the allowed PIP-rule art swap (own `PipAvatar` + shared nest asset), not a
  layout deviation.

## verdict data

- `shot.sh` light + dark on the assigned simulator: stable frames saved.
- `compare.py` light + dark: sheets written, tables above.
- Geometry: every element within ±2 px except excluded OS chrome and the
  allowed Pip-art swap.
- One designer-visible deviation (D1) present in both themes.


## From 6_bugs.md
# K06 · Pip's nest — Stage 6 bug hunt (iteration 1)

Adversarial pass over `/pip` on the iteration-1 build (`37c341e`, build
checkpoint; `main` merged). Everything below is proved by
`app/test/features/pip/k06_bugs_test.dart`, which runs against the real
in-memory Drift database (`Seed.demo`), the real repository and the real
`PipBloc` — no product code was changed by this stage.

```
flutter analyze test/features/pip/k06_bugs_test.dart   → No issues found!
flutter test --timeout 120s test/features/pip/k06_bugs_test.dart
  → +14 ~6: All tests passed!            (six proofs parked)

flutter test --timeout 120s --run-skipped test/features/pip/k06_bugs_test.dart
  → +14 -6: 6 deterministic failures     (K06-BUG-1 … K06-BUG-6)
```

The six parked proofs fail exactly as recorded below; each carries its bug
id in the test description (`skip: true`, so the normal suite stays green).
Run one proof with:

```
flutter test test/features/pip/k06_bugs_test.dart --run-skipped --plain-name K06-BUG-1
```

## Status of every finding

| # | Severity | Status |
|---|---|---|
| K06-BUG-1 | **major** | OPEN — rapid care taps lose charges (5 taps can cost 5 coins) |
| K06-BUG-2 | **major** | OPEN — concurrent wardrobe buys overspend (160 coins of goods from 120) |
| K06-BUG-3 | minor | OPEN — heading apostrophe U+2019 vs HTML ASCII 0x27 |
| K06-BUG-4 | minor | OPEN — nest art box 230×230 vs the design's 206-high nest |
| K06-BUG-5 | minor | OPEN — care buttons unequal height at text scale 1.3 |
| K06-BUG-6 | **major** | OPEN — locked tiles' dashed border is painted but invisible (5_ui D1) |

Three majors ⇒ **VERDICT: FAIL**. K06-BUG-6 is the same defect the UI stage
files as D1 (now with a deterministic widget proof); K06-BUG-3 is the same
copy item as `4_review.md` finding 9.

---

## K06-BUG-1 — major — rapid care taps lose charges

**Mechanism.** `PipRepositoryImpl._care`
(`app/lib/features/pip/data/pip_repository_impl.dart:112-123`) is a
read-modify-write: it `SELECT`s the child, then writes
`coins: kid.coins - cost` from that snapshot. `PipBloc` handles events
concurrently (bloc 9's default transformer), so two taps in one burst both
read 120 and both write 115.

**Evidence (all measured, real DB + real bloc).**

- `Future.wait([repo.feed('maya'), repo.feed('maya')])` → **115**, not 110.
- Five concurrent feeds → **115** — five taps, one 5-coin charge.
- Bloc burst (`PipCareRequested(feed)` twice in one turn) → **115**.
- Timezone/period rules are not involved; this is a plain lost update.

**Repro.** Open `/pip` with the demo seed (120 coins) and tap Feed twice as
fast as the UI allows (or two-finger tap). One charge lands; the second is
lost. Same for Feed+Bath (probe: 117, not 112). On a device the DB
round-trip widens the window; in the test the two handlers overlap
deterministically.

**Failing test.** `K06-BUG-1: two rapid Feed taps must spend 10 coins, not 5`
(expected 110, actual 115).

**Suggested fix.** Make the write atomic instead of read-then-write: one
conditional `UPDATE children SET coins = coins - :cost,
happiness = min(happiness + 1, 5) WHERE id = :id AND coins >= :cost`
(drift `customUpdate`/`UpdateStatement` inside a transaction) and treat
`updated == 0` as the insufficient-coins no-op; or serialize care writes per
child. Return value must not depend on a stale read.

---

## K06-BUG-2 — major — concurrent wardrobe buys overspend

**Mechanism.** Two layers of check-then-act:

1. `PipBloc._onBuyRequested` (`pip_bloc.dart:85-105`) pre-checks
   `nest.profile.coins`, which is the cached stream state; a second tap in
   the same burst still sees 120.
2. `PipRepositoryImpl.buyItem` (`pip_repository_impl.dart:126-143`) checks
   `kid.coins < row.priceCoins` **outside** its transaction, then writes
   `coins: kid.coins - row.priceCoins` from the stale read inside it.

**Evidence.** With the demo seed (120 coins) and both tiles locked:

- `Future.wait([buyItem(wellies · 40), buyItem(crown · 120)])` →
  **both owned, coins 0**. 160 coins of goods left a 120-coin balance.
- Bloc burst (`PipWardrobeBuyRequested('wellies')` +
  `PipWardrobeBuyRequested('crown')` in one turn) → same: both owned,
  coins 0. A fixed build can only ever mark one of the two owned.
- The single-item races are benign by luck (a second same-item buy re-writes
  the same stale values), which is why the existing single-buy tests stay
  green.

**Repro.** Tap Wellies and Crown near-simultaneously (kid double-thumb);
both purchases complete although only one can be afforded.

**Failing test.** `K06-BUG-2: two quick wardrobe buys must not overspend a
120-coin balance` (expected 1 owned, actual 2).

**Suggested fix.** One transaction that does the affordability *as part of
the write*: `UPDATE children SET coins = coins - :price WHERE id = :id AND
coins >= :price`; only mark `pip_wardrobe.owned = true` when that update
changed one row, and re-read `owned` inside the same transaction. The bloc
pre-check may stay as a fast toast path, but correctness must not depend on
it.

---

## K06-BUG-3 — minor — heading apostrophe is U+2019, HTML source is ASCII

**Mechanism.** `pip_nest_view.dart:383` renders `'Pip’s wardrobe'` (curly
U+2019). `design/html-source/screens/K06-pip.html` line 71 is
`<div class="k6-sec">Pip's wardrobe</div>` — ASCII `0x27` (verified with
`hexdump`: `50 69 70 27 73`). Both design PNGs render the straight glyph
(cropped and read at 2× during this pass). Orchestrator COPY
rule: character-exact vs the HTML source; K01 fixed the identical class of
bug to ASCII.

**Failing test.** `K06-BUG-3: the heading must be the HTML source's ASCII
"Pip's wardrobe"` (finds 0 widgets).

**Suggested fix.** Change the string to `"Pip's wardrobe"` and update the
assertions that pin U+2019: `pip_nest_view_test.dart` line 92 (+ the
`_rightQuote` helper at line 37) and `pip_nest_states_test.dart` line 307
(which currently asserts the curly string is absent). `1_plan.md` §1e also
records U+2019 and should be corrected.

---

## K06-BUG-4 — minor — the nest art is drawn 230×230, the design's nest is 206 high

**Mechanism.** `pip_nest_slot.dart:35` sets
`kPipNestArtSize = 230` and line 65-75 positions the nest 230×230 with
`BoxFit.fill`. The HTML says `.k6-pet .nest { width:230px; height:206px }`
(line 22), and the design PNG's rendered nest is a **uniform 206 scale**:
measured from `design/screens/light/K06-pip.png`, the nest's widest row
(y≈277) is 173 px wide = the SVG's 202-unit outer ellipse × 206/240; the app
draws the same ellipse 202 × 230/240 = **193.6 px** wide (≈10 px per side)
and its rim top sits ~14 px higher. Dark PNG agrees: its widest brown fill
row measures 163 px, while a 230-scale box would draw that 196-unit ellipse
at 196 × 230/240 = 188 px (the 206 scale predicts 168 px).

**Repro.** Compare the pet slot in `cmp_light_1.png` (UI stage already
records the pet band as the highest-diff band): the nest bowl is visibly
larger/stretched versus the design.

**Failing test.** `K06-BUG-4: the nest art box must be 230 x 206, not
230 x 230` (expected `Size(230, 206)`, actual `Size(230, 230)`).

**Suggested fix.** The PNG is the UI comparison target and shows a uniform
206×206 nest; the HTML says 230×206. Either way the current 230 height is
wrong — draw the nest at the PNG's scale (206 wide, centred at x195, bottom
of the slot) and keep the widget-test pin. If the designer confirms the
horizontal stretch is intended, use exactly 230×206 per the CSS. Also update
the `SHARED_REQUEST.md`/plan wording that describes the design as a
"230 × 230" nest.

---

## K06-BUG-5 — minor — care buttons lose their equal heights at text scale 1.3

**Mechanism.** `.k6-care` is a flex row, so all three `.btn-kid` columns
stretch to the tallest. `_CareRow` (`pip_nest_view.dart:480-483`) uses a
Flutter `Row` with `crossAxisAlignment: start`; each button's height is only
floored at `kPipCareButtonHeight = 91`. At scale 1.3 the Play button's 13 px
`Free` pill grows faster than the coin rows, so Play becomes 101 px while
Feed/Bath stay 96 px (measured; 390 and 320 px agree).

**Failing test.** `K06-BUG-5: at text scale 1.3 the three care buttons share
one height` (measured `{96.0, 101.0}`).

**Suggested fix.** Wrap the care row in `IntrinsicHeight` and use
`CrossAxisAlignment.stretch`, or size all three buttons to the tallest (the
row already computes one line box for each child).

---

## K06-BUG-6 — major — the locked wardrobe tiles' dashed border is invisible

**Mechanism.** `pip_wardrobe_tile.dart:83-115` attaches the screen-local
`_DashedBorderPainter` as `CustomPaint.painter`, which paints **behind** the
child. The child `Container` then paints an opaque `surface-2` decoration
over the same rect (its 3 px padding is inside that decoration), so the
dashed `ink-2` border is fully occluded. Only the owned tiles show an edge,
because their border is part of `BoxDecoration.border`.

**Evidence (widget pixel probe, light, demo seed).** Along the tiles' top
border band (y = tile.top + 1, full width): the owned Scarf tile has **23
dark pixels** (solid ink border); the locked Wellies tile has **0** — the
band is `surface-2` fill edge-to-edge. Matches `5_ui.md` D1 (simulator
pixels, both themes) and is ORCHESTRATOR_NOTES iteration-2 target #1.

**Failing test.** `K06-BUG-6: locked wardrobe tiles paint the 3 px dashed ink
border` (owned control passes; locked count is 0).

**Suggested fix.** Paint the dashed stroke **above** the fill: pass the
painter as `CustomPaint.foregroundPainter` (keep the 3 px inset/padding), or
draw the border in a foreground layer/Stack over the container. Keep the
pixel probe as the regression proof.

---

## Probes that came back clean (green, in the suite)

| Area | Result |
|---|---|
| 0 children (`Seed.empty`) | "Who's playing?" + Choose renders; no crash |
| 6 children + long UK nickname (`Maximilian-Alexander`) | active child's nest unchanged; K06 shows no child name |
| Empty wardrobe | heading + strip omitted, caption kept |
| 9999 coins / 9999 lifetime coins | label renders, progress clamps to 1.0, no overflow |
| 3 coins | Feed disabled (`enabled:false`, no tap action); Bath operable and spends 3 → 0 |
| Deep-link `/pip` Back | lands on `/kid-home` (no stack to pop) |
| Grown-ups burst | one gate route; back returns to `/pip` |
| Restart | file-backed Drift reopen keeps care spend (75) and the Wellies purchase |
| Live active-child switch | one subscription follows maya → leo → none |
| Stale active child id (`ghost`) | `watchNest` emits null (no-child state) |
| Leo active | `Pip · Hatchling`, `PipAvatar` bolt / sky / stage 2 |
| Real 320 px @ 1.3× | renders with no overflow (width asserted 320) |
| Dark-mode contrast | 10 K06 pairs all ≥ 4.5:1 |
| Copy characters | middle dot U+00B7, em dash U+2014 exact |

## Notes (not product findings)

- **Test-infrastructure (minor, test-only):** `pip_nest_view_test.dart`'s
  `_pumpNest(width:)` sets the view size *before* `pumpAppRoute`, which pins
  390×844 — so the "320px/430px @ scale" matrix actually runs at 390
  (reproduced: `MediaQuery.sizeOf` = 390 after a 320 setup; my suite's
  `_pumpPip` re-applies the width after the pump). The real 320×1.3 layout is
  clean (probe above), so this is a vacuous-test issue, not an overflow bug.
  Suggested next-iteration fix: set the size after `pumpAppRoute` in
  `_pumpNest`.
- **Ghost active child id under widget-test fake async:** a drift
  `watchSingleOrNull` query with zero rows does not deliver its initial null
  on `tester.pump` alone, so a widget test of `active_child_id='ghost'` sits
  on the spinner. The real async path emits null (plain test green) and the
  device shows the no-child card — deliberately NOT filed as a bug.
- **Non-design copy:** the not-wearable toast `kPipNotWearable` and the
  not-enough-coins toast are the only strings not in the HTML; both are
  plan-mandated and already flagged in `4_review.md` #10 for ratification.
- **Progress semantics article:** "Pip is N percent of the way to a
  Songbird" vs the design aria "…to Songbird" (`4_review.md` #11) —
  screen-reader-only wording; noted, not numbered.
- **ORCHESTRATOR_NOTES items 2 and 3** (wardrobe glyphs; seed prices 30/60
  vs the rendered DB 40/120) are iteration-2 build targets: the notes ask for
  a `SHARED_REQUEST.md` for the missing design glyphs and for the seed
  prices. The screen correctly renders whatever the DB holds, so neither is a
  K06 screen defect *and* neither is hard-coded here.
- **Timezone (BST) and money rounding:** K06 shows no dates/times and no £
  amounts; coins are integers end-to-end (`seed`, repo, view). Nothing on
  this screen can fail those categories.
- **Parent/kid mode guard:** `/pip` is reachable in parent mode by design
  (the router only blocks kid → parent-only, `router.dart:83-141`); no path
  from K06 reaches parent-only content without the parental gate. No bypass.

