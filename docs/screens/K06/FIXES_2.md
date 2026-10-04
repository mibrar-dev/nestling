# Fix list after iteration 2

## From 5_ui.md
# K06 · Pip's nest (`/pip`) — Stage 5 UI check (iteration 2)

Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844), `demo kid maya`.
Shots: `docs/screens/K06/ui/app_light_2.png`, `app_dark_2.png`.
Sheets: `cmp_light_2.png`, `cmp_dark_2.png` (design | app | heat-map).
Iteration-1 artefacts (`*_1.png`) kept for history.

- Light: `mean diff: 2.28%` (was 3.67%) — bands: 0: 1.55, 1: 1.74, 2: 2.50
  (was 12.05), 3: 0.44, 4: 1.21, 5: 2.08, 6: 4.48, 7: 4.27.
- Dark: `mean diff: 2.00%` (was 3.01%) — bands: 0: 1.58, 1: 1.23, 2: 2.20
  (was 9.41), 3: 0.35, 4: 1.38, 5: 2.04, 6: 4.34, 7: 2.90.
- Band 2 residual is the allowed Pip-art swap (own `PipAvatar` vs the v1
  illustration per the PIP rule); the nest body width matches ±1.5 px/side
  and the slot bottom edge now matches the design exactly (323.7 = 323.7).
- Band 6 residual is deviations D2/D3 below (glyph art + DB prices).

## Measured y positions, design vs app (logical px, ÷3; ±2 px rule)

Row-edge detector (background-deviation scan, x 20–370, iteration-2 shots):

| Element | Design y | App y | Δ |
|---|---|---|---|
| Title `Pip · Fledgling` top / bottom | 114.0 / 132.7 | 114.0 / 132.7 | 0 |
| Growth card top border | 372.0 | 372.0 | 0 |
| Progress track top / bottom | 427.0 / 442.7 | 427.0 / 442.7 | 0 |
| Growth card bottom border | 483.0–485.7 | 483.0–485.7 | 0 |
| Care row top (Feed/Play/Bath bg rect) | 502.0 | 502.0 | 0 |
| Care row bottom | 592.7 | 592.7 | 0 (91 tall ✓) |
| Section `Pip's wardrobe` text | 618.0–627.7 | 619.0–628.7 | +1 ✓ |
| Wardrobe tile tops (all 4 share) | 651.0 | 651.0 | 0 |
| Wardrobe tile bottoms | 766.7 | 766.7 | 0 (116 tall ✓) |
| Caption text | 790.7–797.7 | 790.7–797.7 | 0 |
| Nest body width at y=300 | 155.0 | 158.3 | ±1.5/side ✓ |

No uniform vertical shift. 20 px gutters everywhere; growth card, care row
and wardrobe rows share edges x20–370. Meadow runs to the physical edge;
no bar on this screen, so the BOTTOM EDGE rule passes in both themes.

Copy (character-exact vs HTML): `Pip · Fledgling` (U+00B7), `Pip's wardrobe`
(U+2019), `Nothing here is a chore — it is all just for fun.` (U+2014),
`175 coins` / `250 to grow`, `Feed 5` / `Play Free` / `Bath 3`,
`Scarf`/`Sun hat` Owned — exact. Dark mode: same geometry; peach Feed,
light-blue Play with dark Free pill, dark Bath card, dark cards with light
borders, leaf-ink Owned — all token-correct, no dark-only deviation.

Excluded (not deviations): OS status-bar time/icons; OS home-indicator pill
(app 831–835.7 vs design-drawn 825–829.7); Pip/nest artwork style inside the
slot (PIP rule, ORCHESTRATOR_NOTES item 4 confirms correct); wardrobe prices
(DB-driven — DATA OVER MOCKS, see D3).

## Deviations

### D1 (iteration-1 major — FIXED, verified light + dark)

Locked tiles had no border. Now: pixel proof, light, Wellies centre x=240 —
y649–650 page bg (lum ~221), y651–653 border (74,70,104), y654+ tile fill —
3 px dashed-length edge paints in both themes (crop + band-6 border edges
confirm; owned tiles unchanged). Closed.

### D2 (major, still open — shared-owned): wardrobe Scarf/Wellies glyphs are look-alikes, not the design glyphs

- Design value (HTML `.k6-ward` inline SVGs): scarf = two vertical strokes +
  flag + one tick; wellies = boot body + two top ticks.
- App value: shared `NestIcons.scarf` (fringed-blanket art) and
  `NestIcons.wellies` (filled boot) — recognisably a scarf/boot, visibly
  different drawing (2× crop + art rows glowing in band 6).
- Fix (not screen-side): replace `app/assets/icons/ic_scarf.svg` +
  `ic_wellies.svg` with the HTML path data. Filed as `SHARED_REQUEST.md`
  §5 (design paths quoted verbatim, asset-vs-design diff table, proof test
  `pip_orchestrator_notes_test.dart` item 2 parked with `--run-skipped`).
  RULES §1 forbids the screen touching `core/**` and the note forbids
  substituting a glyph, so there is zero screen-side work left. §5 says
  "Blocks: no" for landing, but the visual target (note item 2, mandatory)
  is unmet in-product, so the UI check cannot pass until the shared assets
  land on main and are merged in.

### D3 (not a deviation — DB truth + escalated): Wellies 40 / Crown 120 vs design 30 / 60

- App renders `watchWardrobe(item).priceCoins` (seed rows), never a literal —
  correct per DATA OVER MOCKS, and DB-driven content is excluded from the UI
  verdict rule. The seed-vs-design conflict is filed as `SHARED_REQUEST.md`
  §6 with both orchestrator options (fix seed to 30/60, or update design to
  40/120) and flip-honestly tests. No screen action possible.

## verdict data

- `shot.sh` light + dark on the assigned simulator: stable frames saved.
- `compare.py` light + dark: sheets written, tables above.
- Geometry: every element within ±2 px (all structural Δ 0, section +1).
- Remaining designer-visible deviation: D2 (shared-owned, escalated, needs
  a main-side asset swap + merge before any UI re-check can pass).


## From 6_bugs.md
# K06 · Pip's nest — Stage 6 bug hunt (iteration 2)

Re-audit of the iteration-2 build (`a7da86b`, `main` merged). All six
iteration-1 findings are **FIXED** and their proofs now run live in
`app/test/features/pip/k06_bugs_test.dart`; this pass re-verified them
end-to-end, added two new green two-thumb regressions and one dark-mode pixel
proof, and filed **one new minor finding (K06-BUG-7)**. One **major** stays
open — the Scarf/Wellies glyph assets (`ORCHESTRATOR_NOTES` item 2 /
`5_ui.md` D2), shared-owned and escalated — so this stage's verdict is FAIL
until that shared change merges. No product code was changed by this stage.
Iteration 1's full write-ups are preserved in `FIXES_1.md`.

```
flutter analyze test/features/pip/k06_bugs_test.dart    → No issues found!
flutter test --timeout 120s test/features/pip/k06_bugs_test.dart
  → +23 ~1: All tests passed!               (K06-BUG-7 parked)

flutter test --timeout 120s --run-skipped test/features/pip/k06_bugs_test.dart
  → +23 -1: only K06-BUG-7 fails            (expected the kind toast, got null)

flutter test --timeout 120s test/features/pip/
  → +180 ~4: All tests passed!
     (~4 = K06-BUG-7 + the three parked glyph proofs of
      pip_orchestrator_notes_test.dart, item 2 below)
```

## Status of every finding

| # | Severity | Status |
|---|---|---|
| K06-BUG-1 | major (iter 1) | **FIXED (2a), verified live** — atomic conditional `_care`; burst now 110, 5-burst 95, feed+bath 112, never negative |
| K06-BUG-2 | major (iter 1) | **FIXED (2a), verified live** — transactional conditional `buyItem`; wellies+crown leaves exactly one owned, balance never negative |
| K06-BUG-3 | minor (iter 1) | **FIXED (2b), verified live** — `"Pip's wardrobe"` ASCII 0x27 |
| K06-BUG-4 | minor (iter 1) | **FIXED (2b), verified live** — nest box 230×206, `BoxFit.contain`; PNG width measurement (173 px) matches |
| K06-BUG-5 | minor (iter 1) | **FIXED (2b), verified live** — `IntrinsicHeight` + stretch; heights equal at scale 1.3, 91 px at 1.0 |
| K06-BUG-6 | major (iter 1) | **FIXED (2b), verified live** — `foregroundPainter`; dark + light pixel proofs green |
| K06-BUG-7 | **minor (new)** | **OPEN** — a buy refused by the fresh balance is silent (no kind toast) |
| ORCH item 2 · glyphs / `5_ui` D2 | **major (design fidelity, shared-blocked)** | **OPEN** — `SHARED_REQUEST.md` §5 filed; 3 parked proofs; needs shared assets |
| ORCH item 3 · prices | data ruling (not a screen bug) | OPEN request — `SHARED_REQUEST.md` §6; screen renders the seeded row (DATA OVER MOCKS) |

**One open major remains** — the Scarf/Wellies glyphs (`5_ui.md` iteration 2,
D2: "the UI check cannot pass until the shared assets land on main and are
merged in"; `ORCHESTRATOR_NOTES` item 2, mandatory). The screen-side action
prescribed by that note — `SHARED_REQUEST.md` §5 with the design path data —
is complete; the fix is a shared-asset swap, so this stage stays **FAIL**
until it lands. K06-BUG-7 is minor; item 3 is a data ruling, not a screen
bug.

---

## ORCH item 2 / `5_ui` D2 — major — wardrobe Scarf and Wellies glyphs are look-alikes

**Mechanism.** The locked/owned wardrobe tiles paint `NestIcons.scarf` and
`NestIcons.wellies`, which resolve to the shared
`assets/icons/ic_scarf.svg` / `ic_wellies.svg` — a fringed-blanket and a
different boot — not the design's inline glyphs in `K06-pip.html` (`.k6-ward`
lines 73–76). `sunhat` is the same idea at different coordinates with an
extra stroke; `crown` matches.

**Evidence.** `pip_orchestrator_notes_test.dart` item 2 compares the asset
path data with the path data read from the HTML at test time; scarf, wellies
and sunhat fail deterministically under `--run-skipped` (verified this
pass). `5_ui.md` iteration 2 measures the same in both themes (D2, major).

**Failing tests (test stage, parked).**
`ORCHESTRATOR NOTES item 2: the scarf / wellies / sunhat glyph is the design
path` — run with
`flutter test test/features/pip/pip_orchestrator_notes_test.dart --run-skipped`.

**Suggested fix.** Replace the three shared assets (or their declarations)
with the design's path data — already quoted verbatim in
`SHARED_REQUEST.md` §5. No `features/pip/**` change is needed or permitted
(RULES §1); once the assets merge, the parked proofs flip green and the UI
re-check can pass.

---

## K06-BUG-7 — minor — a refused purchase is silent

**Mechanism.** `PipBloc._onBuyRequested` pre-checks the *cached*
`state.nest.profile.coins`. When two tiles are tapped in one burst the cache
is stale for the second, so both pass the pre-check. The iteration-2 atomic
`buyItem` correctly refuses the one the fresh balance cannot afford — but it
returns `Future<void>`, so the bloc cannot tell "refused" from "bought" and
emits nothing. The child gets no feedback for that tap; the tile simply stays
locked until the stream refresh explains why.

**Evidence (real DB + real bloc, measured).** With the demo seed (120 coins)
and both tiles locked, a burst of `PipWardrobeBuyRequested('wellies')` +
`PipWardrobeBuyRequested('crown')`:

- exactly one item ends owned (the money fix works), and
- `bloc.state.actionError == null` — the kind refusal copy never fires.

`1_plan.md` §1f requires a locked-tile failure to surface
`'Not enough coins yet — keep going!'`. It does for the *stale pre-check*
path (an item visibly unaffordable) and no longer for the race path.

**Repro.** Two-thumb burst on Wellies and Crown from 120 coins: one buys,
the other does nothing with no toast. Tap the unaffordable tile again — now
that the stream has updated, the toast appears, so the gap is one silent
tap in a race.

**Failing test.** `K06-BUG-7: a buy refused by the fresh balance must still
be announced` (parked, `skip: true`; expects `kPipNotEnoughCoins`, gets
`null`).

```
flutter test test/features/pip/k06_bugs_test.dart --run-skipped --plain-name K06-BUG-7
```

**Suggested fix.** Give the repository a result: `Future<bool> buyItem(...)`
(or a small enum: `bought | cannotAfford | alreadyOwned`) in
`domain/pip_repository.dart` + `data/pip_repository_impl.dart` (both inside
RULES §1). The impl already knows (`paid == 0` ⇒ cannot afford; `row.owned`
⇒ already owned). In `PipBloc._onBuyRequested`, when the result is
`cannotAfford`, emit `state.withActionFailed(kPipNotEnoughCoins)`; success
stays event-free (the stream re-emits). Keep the cached pre-check as the
fast path.

---

## Iteration-1 fixes re-verified (live proofs, no skips)

- **K06-BUG-1** — two rapid Feed taps now spend 10 (110); five spend 25 (95);
  feed+bath spend 8 (112); the price is inclusive (5 coins → exactly one
  Feed); a burst below the balance charges only what fits; happiness clamps
  at 5; unknown child is a no-op. Single-write behaviour is unchanged.
- **K06-BUG-2** — wellies+crown from 120 leaves exactly one purchase; the
  balance never goes negative; same-item bursts charge once; the 40-coin
  tile is buyable at exactly 40 and not at 39; an unknown item/child is a
  no-op; equip is untouched.
- **K06-BUG-3** — the section heading is byte-equal to the HTML source's
  ASCII apostrophe; the byte-level oracle in `pip_copy_parity_test.dart`
  (which re-reads the HTML) is green too.
- **K06-BUG-4** — the nest `SvgPicture` render box is 230×206 at the slot's
  bottom; `contain` paints the art uniformly at the PNG's 206 scale (the
  UI stage's re-run confirms pixels; the app no longer draws the 230-scale
  194 px ellipse).
- **K06-BUG-5** — care buttons share one height at scale 1.3 (and one top);
  at scale 1.0 the row is still the design's 91 px.
- **K06-BUG-6** — the locked tiles' dashed `ink-2` border is painted over
  the fill; the top-band pixel probe counts border pixels in **light** (dark
  on light) and in **dark** (light on dark). Owned controls stay visible in
  both themes.

## New regression cover added this pass (green)

- **Two-thumb care burst** — `Feed` + `Bath` fired from two simultaneous
  gestures: 120 → 112 (every tap charges against the current balance).
- **Two-thumb buy burst** — `Wellies` + `Crown` from two gestures: exactly
  one owned, balance consistent with the winner (80, or 0 if Crown won).
- **Dark-mode dashed border** — the K06-BUG-6 pixel proof now covers the
  night theme as well.

## Categories re-checked clean (green, in the suite)

| Area | Result |
|---|---|
| 0 children (`Seed.empty`) | "Who's playing?" + Choose renders; no crash |
| 6 children + long UK nickname | active child's nest unchanged; K06 shows no child name |
| Empty wardrobe | heading + strip omitted, caption kept |
| 9999 coins / 9999 lifetime coins | label renders, progress clamps to 1.0, no overflow |
| 3 coins | Feed disabled (`enabled:false`, no tap); Bath operable (3 → 0) |
| Deep-link `/pip` Back | lands on `/kid-home` |
| Grown-ups burst | one gate route; back returns to `/pip` |
| Restart (file-backed Drift reopen) | care spend (75) + Wellies purchase persist |
| Live active-child switch | one subscription follows maya → leo → none |
| Stale active child id (`ghost`) | `watchNest` emits null (no-child state) |
| Leo active | `Pip · Hatchling`, `PipAvatar` bolt / sky / stage 2 |
| Real 320 px @ 1.3× | renders with no overflow |
| Dark-mode contrast | 10 K06 pairs all ≥ 4.5:1 |
| Copy characters | middle dot U+00B7, em dash U+2014 exact |

## Notes (not product findings)

- **ORCHESTRATOR_NOTES item 2 (glyphs)** — verified open and blocking: the
  three parked proofs in `pip_orchestrator_notes_test.dart` fail
  deterministically under `--run-skipped` (scarf / wellies / sunhat asset
  paths ≠ the design paths read from `K06-pip.html`; crown matches), and
  `5_ui.md` iteration 2 rates it D2 major ("the UI check cannot pass until
  the shared assets land on main and are merged in"). The screen's only
  permitted action per the note is `SHARED_REQUEST.md` §5, which is filed;
  the remaining work is the shared `assets/icons/*.svg` replacement and its
  merge. This is the report's one open major and the reason for the FAIL
  verdict.
- **ORCHESTRATOR_NOTES item 3 (prices)** — the screen renders
  `item.priceCoins` with no literal (proved by re-seeding Crown to 7 and
  seeing 7); the seed-vs-design conflict is `SHARED_REQUEST.md` §6. DATA
  OVER MOCKS keeps the DB authoritative until the orchestrator rules.
- **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
  the one on-screen string the design does not define; awaits ratification
  (`4_review.md` #10). Not a regression.
- **`NestProgress`'s kid highlight spans the whole track** — shared
  component, out of the screen's scope (`2b_build_ui.md` item 5).
- **Ghost active child id under widget-test fake async** — carried over from
  iteration 1: the real async path emits null (plain test green); the
  screen's device behaviour is the no-child card. Deliberately not a bug.
- **Timezone (BST) and money rounding** — K06 shows no dates/times and no £
  amounts; coins are integers end-to-end. Nothing to fail on this screen.
- **Parent/kid mode guard** — `/pip` remains reachable in parent mode by
  design; no path from K06 reaches parent-only content without the gate.

