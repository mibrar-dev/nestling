# K06 · Pip's nest — Stage 6 bug hunt (iteration 4)

Re-audit of the iteration-4 build (`006f3ed`; `shared_batch7` and
`shared/k06_glyphs` merged). **Every finding from iterations 1–3 is FIXED and
verified**, the last local design-system forks are deleted, and this pass
found **no new product bugs** — major or minor. One minor copy item still
awaits orchestrator ratification, and two shared-component notes are carried;
none is a screen defect. This stage changed no product code.

```
flutter analyze test/features/pip/k06_bugs_test.dart   → No issues found!
flutter test --timeout 120s test/features/pip/k06_bugs_test.dart
  → +26: All tests passed!                 (no skips in this file)

flutter test --timeout 120s test/features/pip/
  → +227: All tests passed!                (zero skips anywhere in the dir)

5_ui.md (iteration 4) → PASS: 2.13 % light / 1.84 % dark, every
structural edge Δ 0 (section +1), care row 502–592.7, tiles 651–766.7,
no numbered deviation.
```

## Status of every finding

| # | Severity | Status |
|---|---|---|
| K06-BUG-1 | major (iter 1) | **FIXED (2a), verified live** — atomic `_care`; 2 feeds 110, 5 feeds 95 |
| K06-BUG-2 | major (iter 1) | **FIXED (2a), verified live** — atomic `buyItem`; 70 coins → one of 30+60 |
| K06-BUG-3 | minor (iter 1) | **FIXED (2b), verified live** — ASCII apostrophe, byte oracle green |
| K06-BUG-4 | minor (iter 1) | **FIXED (2b), verified live** — nest box 230×206, `contain`; shared `NestPetStage` reproduces it |
| K06-BUG-5 | minor (iter 1) | **FIXED (2b), verified live** — painted care cards equal, 91 px at 1.0 |
| K06-BUG-6 | major (iter 1) | **FIXED (2b), verified live** — dashed border over the fill, light + dark pixel proofs |
| K06-BUG-7 | minor (iter 2) | **FIXED (3a), verified live** — `PipBuyResult` + `cannotAfford` toast + carried outcome; end-to-end toast regression |
| ORCH item 2 · scarf/wellies/sunhat + Feed/Play glyphs | major (iter 3) | **FIXED (4), verified live** — exact shared assets, byte proofs un-skipped and green; **zero skips left** |
| ORCH 13:52 · component switch | major (review iter 3 #1) | **FIXED (4), verified live** — `NestPetStage`, `NestKidButton(trailing:)`, `NestDashedBorder`; all three local forks deleted; structural probe added |
| ORCH item 3 · prices | done | **FIXED upstream** — seed 30/60; every test reads the seeded row |
| `kPipNotWearable` copy | minor (awaiting ratification) | OPEN — unchanged since iteration 1 |
| `NestProgress` kid highlight | shared | OPEN — shared component, out of screen scope |
| `DESIGN_SPEC.md` §5 prose | shared doc | OPEN — `SHARED_REQUEST.md` §8 (spec amend, not runtime) |

No open product bugs on K06 ⇒ **VERDICT: PASS**.

---

## Iteration-4 verification (what this pass actually checked)

**The seven proofs run live** (`k06_bugs_test.dart`, no `skip:`): atomic
care bursts, atomic buys at the design prices, ASCII apostrophe, nest box
230×206, equal care heights at 1.3, dashed border in light **and** dark,
`PipBuyResult` refusal toast — plus the three regressions added along the
way (two-thumb care burst → 112, two-thumb buy burst → exactly one of
30/60, end-to-end refusal toast).

**New structural guard (green).** `the presentation composes the shared
batch-7 components` asserts exactly `NestPetStage` ×1, `NestKidButton` ×3 and
`NestDashedBorder` ×2 on the loaded screen, so a future edit cannot silently
re-fork the components that were deleted this iteration.

**Independent pixel checks of the switch** (widget capture at 1×, compared
with `design/screens/{light,dark}/K06-pip.png`; no simulator, file-reader
only):

- Pet slot: the nest's first painted pixel at x=118 is **y 257.0 in the
  design and y 257.0 in the app** (x=122: 253.3 vs 253.0); the widest brown
  row is 162.3 px design vs 161.0 px app (anti-aliasing) — the shared
  `NestPetStage` K06 params reproduce the local slot exactly, and the
  front-rim composition matches the design crop.
- Wardrobe: exact design glyphs for scarf/sun hat/wellies/crown, dashed
  ink-2 locked borders, `30`/`60` prices — visually identical to the design
  crops.
- Care row: bowl / seamed ball / bubbles glyphs and the 91 px cards match;
  the `Free` pill, coin rows and colours are unchanged.
- Whole-frame band diff from my widget capture: **2.08 % light / 2.11 %
  dark**, consistent with `5_ui`'s simulator numbers (2.13 / 1.84) — no
  component-switch regression in any band.

**Behaviour probes re-run** (iteration-3 coverage, still green): all four
`PipBuyResult` paths; the carried outcome surviving a sibling refresh,
re-announcing on a repeat refusal (`1 → 0 → 1`), clearing on success and
never re-firing across a child switch; five concurrent feeds → 95;
same-item double buy charges once; restart persistence 85 (120 − 5 − 30).

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
| Restart (file-backed Drift reopen) | 85 persists, Wellies owned |
| Live active-child switch | one subscription follows maya → leo → none |
| Stale active child id (`ghost`) | `watchNest` emits null (no-child state) |
| Leo active | `Pip · Hatchling`, `PipAvatar` bolt / sky / stage 2 |
| Real 320 px @ 1.3× | renders with no overflow |
| Dark-mode contrast | 10 K06 pairs all ≥ 4.5:1 |
| Copy characters | middle dot U+00B7, ASCII apostrophe 0x27, em dash U+2014 |

## Notes (not product findings)

- **Empty-wardrobe caption spacing (cosmetic, unreachable with the seed).**
  The shared `NestKidButton` reserves 6 px under the painted card for its
  press shadow; the view compensates with `SizedBox(s4 − gap6)` only inside
  the `items.isNotEmpty` branch. With an empty wardrobe the caption therefore
  sits 22 px under the painted card instead of the design pitch 16. Every
  seeded child has four wardrobe rows, and no in-app flow clears them, so no
  user can see it; noted rather than filed.
- **Rapid repeated refusals queue identical toasts.** Shared
  `showNestToast` (`nest_toast.dart`) uses `ScaffoldMessenger.showSnackBar`
  without hiding the current one, so mashing an unaffordable tile queues one
  3 s toast per tap. Shared component, same copy, user-initiated; noted.
- **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
  the one on-screen string the design does not define; awaits ratification
  (`4_review.md` #10).
- **`NestProgress`'s kid highlight spans the whole track** — shared
  component, out of the screen's scope.
- **`DESIGN_SPEC.md` §5 K06 prose** still quotes the superseded 280 px stage
  / 72 px tiles; `SHARED_REQUEST.md` §8 files the amend. The screen follows
  the measured PNG (stage-5 table: all structural Δ 0), which is the oracle.
- **Copy-check note for the record:** `5_ui.md` iteration 4's copy line
  parenthesises `Pip's wardrobe` as U+2019; the HTML source byte is ASCII
  0x27 and the screen renders 0x27 — the byte oracle in
  `pip_copy_parity_test.dart` is green. Documentation typo, not a screen
  finding.
- **Ghost active child id under widget-test fake async** — carried over:
  the real async path emits null (plain test green); the device shows the
  no-child card. Deliberately not a bug.
- **Timezone (BST) and money rounding** — K06 shows no dates/times and no £
  amounts; coins are integers end-to-end. Nothing to fail on this screen.
- **Parent/kid mode guard** — `/pip` remains reachable in parent mode by
  design; no path from K06 reaches parent-only content without the gate.

VERDICT: PASS
