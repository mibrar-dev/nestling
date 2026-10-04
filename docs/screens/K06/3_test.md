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

VERDICT: FAIL
