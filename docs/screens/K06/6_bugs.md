# K06 · Pip's nest — Stage 6 bug hunt (iteration 3)

Re-audit of the iteration-3 build (`a17df6b`, shared batch 7 merged). **All
seven filed findings are FIXED** and run live in
`app/test/features/pip/k06_bugs_test.dart`; this pass re-verified them
end-to-end, added the end-to-end refusal-toast regression, and probed the new
`PipBuyResult` contract and the carried action outcome. One **major** stays
open, shared-owned: the residual **sun-hat glyph** (`SHARED_REQUEST.md` §7 —
batch 7 fixed Scarf/Wellies and left the third tile). No product code was
changed by this stage.

```
flutter analyze test/features/pip/k06_bugs_test.dart   → No issues found!
flutter test --timeout 120s test/features/pip/k06_bugs_test.dart
  → +25: All tests passed!                 (no skips in this file)

flutter test --timeout 120s test/features/pip/
  → all green, exactly one skip: the parked sun-hat glyph
     proof in pip_orchestrator_notes_test.dart (item 2 / section 7 below)
```

## Status of every finding

| # | Severity | Status |
|---|---|---|
| K06-BUG-1 | major (iter 1) | **FIXED (2a), verified live** — atomic `_care`; 2 feeds 110, 5 feeds 95, feed+bath 112 |
| K06-BUG-2 | major (iter 1) | **FIXED (2a), verified live** — atomic `buyItem`; 70 coins → exactly one of 30+60 |
| K06-BUG-3 | minor (iter 1) | **FIXED (2b), verified live** — ASCII apostrophe, byte oracle green |
| K06-BUG-4 | minor (iter 1) | **FIXED (2b), verified live** — nest box 230×206, `BoxFit.contain` |
| K06-BUG-5 | minor (iter 1) | **FIXED (2b), verified live** — equal care heights at 1.3, 91 px at 1.0 |
| K06-BUG-6 | major (iter 1) | **FIXED (2b), verified live** — dashed border over the fill, light + dark pixel proofs |
| K06-BUG-7 | minor (iter 2) | **FIXED (3a), verified live** — `PipBuyResult` + `cannotAfford` toast; new end-to-end regression |
| ORCH item 2 · scarf/wellies | major (iter 2) | **FIXED (2/integrate), verified live** — exact shared assets + `pip_look.dart` switch; byte proofs green |
| ORCH item 2 · sun-hat (residual) | **major (design fidelity, shared-blocked)** | **OPEN** — `SHARED_REQUEST.md` §7; one parked proof; see below |
| ORCH item 2 · local-copy switch | minor (compliance, scheduled) | OPEN — `2_build.md` §5.1; refactor to `NestPetStage`/`NestKidButton`/`NestDashedBorder`; no functional impact |
| ORCH item 3 · prices | done | **FIXED upstream** — seed 30/60; every K06 test reads the seeded row (no typed price) |
| `kPipNotWearable` | minor (copy ratification) | OPEN — unchanged since iteration 1 |
| `NestProgress` kid highlight | shared | OPEN — shared component, out of screen scope |

**One open major remains** — the sun-hat glyph — so this stage's verdict is
**FAIL** until the shared asset lands. It is the same defect class the UI
stage rated D2 major in iteration 2 and the orchestrator mandated ("Wardrobe
icons must be the design's glyphs … Do not substitute"). Scarf and Wellies
are done; the sun hat was the third asset in `SHARED_REQUEST.md` §5 and batch
7 left it claiming it "already matches the design geometry", which the
byte-level proof shows it does not. No screen-side work remains for it.
K06-BUG-7 is fixed; the local-copy switch is a scheduled refactor with no
functional impact.

---

## ORCH item 2 residual — major — the sun-hat glyph is still not the design's

**Mechanism.** The wardrobe tile for the sun hat paints `NestIcons.sunHat`
(`assets/icons/ic_sun_hat.svg`). The design's inline glyph
(`K06-pip.html` line 74) is
`M3 16h18l-1.6 2.4H4.6z` + `M7 16a5 5 0 0 1 10 0z`; the asset draws
`M2.4 13.8h19.2l-1.6 2.8H4Z` + `M6.8 13.8a5.2 7 0 0 1 10.4 0Z` **plus an
extra `M7.4 11.6h9.2` stroke** — the brim sits 2.2 units higher in the
24-box, the dome is flatter (`ry 7` vs `5`), and the design has no third
stroke.

**Evidence.** `pip_orchestrator_notes_test.dart` item 2 (extra) compares the
asset's path data with the path data read from `K06-pip.html` at test time;
it fails deterministically under `--run-skipped` (verified this pass), and
it is the only `skip: true` left anywhere in `test/features/pip/`.
Scarf/wellies/crown are byte-correct.

**Failing test (test stage, parked).**
`ORCHESTRATOR NOTES item 2 (extra): the sunhat glyph is the design path` —
```
flutter test test/features/pip/pip_orchestrator_notes_test.dart --run-skipped
```

**Suggested fix.** Add a `wardrobeSunHat` asset with the design's two paths
(the scarf/wellies pattern from batch 7), point `NestIcons.sunHat` (or a new
constant the K06 mapping uses) at it, and unskip the proof. `features/pip/**`
cannot do it (RULES §1): `SHARED_REQUEST.md` §7 carries the paths.

---

## K06-BUG-7 re-verified (fixed in 3a) — a refused buy now announces itself

**The fix.** `PipRepository.buyItem` returns `PipBuyResult`
(`bought | cannotAfford | alreadyOwned | unavailable`); the bloc announces
`cannotAfford` with the existing `kPipNotEnoughCoins` toast; `PipState.
copyWithLoaded` carries a pending outcome so the refusal survives the sibling
write's stream refresh. All four result paths were probed on the real DB:
`bought` (30-coin wellies at 120 → 90), `alreadyOwned` (second same-item
tap), `unavailable` (unknown item and unknown child), `cannotAfford`
(5 coins vs 60-coin crown).

**Verified behaviour (real DB + real bloc + real view):**

- Burst Wellies(30)+Crown(60) from 70 coins → exactly one owned, balance
  consistent (40 or 10), **`actionError == kPipNotEnoughCoins`** and the toast
  visible (`find.text(kPipNotEnoughCoins)` finds one widget).
- Repeat refusal → the pinned `1 → 0 → 1` nonce sequence, so the second
  refusal toasts again (five rapid refusals each emit the
  started/failed pair — none swallowed).
- Carried outcome across a child switch (Maya's refusal → Leo's nest) never
  re-fires the listener (nonce unchanged), and a successful Leo purchase
  clears it (`null@0`).
- A failed care write and a failed buy still surface their own errors; a
  successful care action clears a carried refusal.

**New green regression added.** `a refused buy still shows the kind toast
end-to-end` — two simultaneous gestures on the two tiles, then the rendered
toast + balance + exactly-one-owned.

## Iteration-3 premises re-verified

- **Prices are the design's 30/60** for both children (probed from the seed
  rows: `maya:wellies=30, maya:crown=60, leo:wellies=30, leo:crown=60`;
  owned rows still 0). No K06 test types a price any more, so the next seed
  decision cannot silently re-green a stale number (the integrate stage
  re-based five premises to read the row and fixed two ambiguous cases:
  the two-item burst now runs at a balance strictly between the two prices,
  and Leo's two `30` tiles are matched per-tile by their announcements).
- **Scarf/Wellies glyphs are the design's**, byte-for-byte, verified by the
  live proofs that read `K06-pip.html` at test time.
- **The atomic write evidence is unchanged:** five concurrent feeds → 95,
  same-item double buy charges once, the refund path is unreachable under
  serialized transactions (harmless belt).

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
| Restart (file-backed Drift reopen) | 120 − 5 feed − 30 wellies = 85 persists, item owned |
| Live active-child switch | one subscription follows maya → leo → none |
| Stale active child id (`ghost`) | `watchNest` emits null (no-child state) |
| Leo active | `Pip · Hatchling`, `PipAvatar` bolt / sky / stage 2 |
| Real 320 px @ 1.3× | renders with no overflow |
| Dark-mode contrast | 10 K06 pairs all ≥ 4.5:1 |
| Copy characters | middle dot U+00B7, em dash U+2014 exact |

## Notes (not product findings)

- **Local-copy switch (scheduled, minor).** The batch-7 report's "delete the
  local copies" half is still open: `PipNestSlot` (→ `NestPetStage` with
  `slotHeight: 206, pipBottom: 81, nestFit: BoxFit.contain, showGlow: false,
  showGroundShadow: false`), `PipCareButton` (→ `NestKidButton(trailing:)`)
  and the local `_DashedBorderPainter` (→ `NestDashedBorder`) remain in
  `presentation/widgets/`. `2_build.md` §5.1 records the deferral with the
  exact call shapes and the reason (a refactor of working, UI-verified code
  needs a build iteration + a `5_ui` re-check). No behaviour bug: the six
  proofs and the pixel probes are green against the local implementations,
  and the shared components were built to reproduce them.
- **Rapid repeated refusals queue toasts.** `showNestToast` (shared
  `nest_toast.dart`) uses `ScaffoldMessenger.showSnackBar` without hiding the
  current one, so five rapid taps on an unaffordable tile queue five 3 s
  toasts of the same message. Shared component, user-initiated, identical
  copy; noted, not filed.
- **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
  the one on-screen string the design does not define; awaits ratification
  (`4_review.md` #10).
- **`NestProgress`'s kid highlight spans the whole track** — shared
  component, out of the screen's scope (`2b_build_ui.md` item 5).
- **Ghost active child id under widget-test fake async** — carried over: the
  real async path emits null (plain test green); the device shows the
  no-child card. Deliberately not a bug.
- **Timezone (BST) and money rounding** — K06 shows no dates/times and no £
  amounts; coins are integers end-to-end. Nothing to fail on this screen.
- **Parent/kid mode guard** — `/pip` remains reachable in parent mode by
  design; no path from K06 reaches parent-only content without the gate.

VERDICT: FAIL
