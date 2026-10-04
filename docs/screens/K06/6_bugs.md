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

VERDICT: FAIL
