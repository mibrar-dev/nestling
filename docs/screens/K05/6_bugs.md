# K05 · Quest complete — Stage 6 bug hunt (iteration 2)

Adversarial pass over the iteration-2 build (`a7bda00`, plus the concurrent
test/review/UI stages' uncommitted artefacts). Iteration 1's four findings
are **fixed and verified**; this pass re-audited those fixes and found
**two new minor issues (K05-BUG-5, K05-BUG-6)** — no major bug. **No screen
code was changed in this stage.** No simulator was booted, installed on or
driven (only `5_ui` may use 604697A9-11DA-462F-9837-396E9CA2493A).

Hunted this pass: the four fixes' edge windows, data edges (0/1/6 children,
long UK names, 0/1/2/100/9999 coins, empty lists, deleted active child),
rapid double taps and double pushes, back navigation and deep links, restart
persistence, parent/kid mode, dark mode, 320/390/430 × 1.0/1.3, async gaps,
Europe/London/BST, and rounding. Timezone/BST and £ rounding have nothing to
fail on this screen (integer coins only, no clock).

```
flutter analyze test/features/kid_home/k05_bugs_test.dart   → No issues found!
flutter test --timeout 120s test/features/kid_home/k05_bugs_test.dart
  → +18 pass, ~2 skip (the two new proofs; suite green)
flutter test --timeout 120s --run-skipped test/features/kid_home/k05_bugs_test.dart
  → the 2 skipped proofs FAIL exactly as documented below
flutter test --timeout 120s test/features/kid_home/quest_complete_view_test.dart
  test/features/kid_home/quest_complete_geometry_test.dart
  → +31 pass, 0 skip, 0 fail (K05 core suite, iteration-1 fixes verified)
```

## Findings

| # | Severity | Area | Status |
|---|---|---|---|
| K05-BUG-1 | minor | copy/plural (`+1 coins`) | **FIXED (iter 2), verified** — proofs green |
| K05-BUG-2 | minor | rounding label (249/250 → 100 %) | **FIXED (iter 2), verified** — label proof green (value is K05-BUG-6) |
| K05-BUG-3 | minor | 320 px @ 1.3× count-row truncation | **FIXED (iter 2), verified** — proof green (heuristic hole is K05-BUG-5) |
| K05-BUG-4 | minor | long UK name hero truncation | **FIXED (iter 2), verified** — proof green |
| K05-BUG-5 | minor | count row still ellipsises 4-digit counts | OPEN — proof skipped, fails when run |
| K05-BUG-6 | minor | progress value contradicts its label | OPEN — proof skipped, fails when run |

---

### K05-BUG-5 (minor) — a 4-digit lifetime count still ellipsises on one line

**Repro.** Set Maya's `pip_total_coins = 9999` (the brief's 9999-coins edge)
and open `/quest-complete`:

- 390 px @ 1.3×: `"9999 of 250 coins"` needs 162.1 px and `"Next: Songbird"`
  136.0 px. The K05-BUG-3 decision checks `162.1 + 8 + 136.0 = 306.1 <= 312`
  and keeps **one line**, but the one-line `Row` gives each `Flexible`
  `(312 − 8) / 2 = 152 px`. Measured: the count box is x 39…191 (152 px,
  `didExceedMaxLines == true`), `Next:` x 215…351 (fits), both on the same
  line.
- 320 px @ 1.0×: `124.7 + 8 + 104.6 = 237.3 <= 242` keeps one line; the cap
  is 117 px. Measured: count x 39…156 (117 px, ellipsised), `Next:`
  x 176.4…281 (fits).

The flaw: the heuristic only checks that the pair *sum* fits, not that each
label fits the half-width the equal-flex `Row` actually gives it. An
asymmetric pair (a 4-digit count with the short fixed `Next:` label) is cut
even though the decision says one line.

**Failing test.** `K05-BUG-5: a 4-digit lifetime count must not ellipsise on
one line` (skipped; run with `--run-skipped`).

**Suggested fix.** Keep the one-line branch only when
`max(countW, nextW) <= (maxWidth - NestSpacing.s2) / 2`, or allocate the flex
proportional to the measured widths (`Expanded(flex: countW.round())` etc.) so
the count gets the room it needs; the stacked branch already exists for the
overflow case. Seed values (175 → 150.4 px) stay one line.

---

### K05-BUG-6 (minor) — the progress node's value contradicts its own label

**Repro.** The K05-BUG-2 fix floored the view's progress **label** but the
shared `NestProgress` still computes its semantics **value** as
`(fraction * 100).round()` (`nest_progress.dart:65-66`). Measured on the real
widget:

| `pip_total_coins` | node label | node value |
|---|---|---|
| 249 | `Pip is 99% of the way to Songbird` | `100 percent` |
| 174 | `Pip is 69% of the way to Songbird` | `70 percent` |
| 124 | `Pip is 49% of the way to Songbird` | `50 percent` |

VoiceOver reads the label and value as one announcement
("… 99% of the way to Songbird, 100 percent"), so whenever the hundredths
round up the node contradicts itself — the same defect K05-BUG-2 closed for
the label. The seed values (175 → 70, 60 → 24) are consistent.

**Failing test.** `K05-BUG-6: the progress node must not announce a
contradictory value` (skipped).

**Suggested fix.** Give `NestProgress` an optional `semanticValue` (or floor
`(f * 100)` the same way the view floors its label) so label and value always
agree; `core/**` is outside this screen's edit set, so this is a
SHARED_REQUEST-style shared fix. A screen-only alternative is wrapping the
progress in K05's own labelled node, but that would drop the component's
`role=img` contract.

---

### Iteration-1 findings — fixed and verified

- **K05-BUG-1** — a 1-coin quest now renders `+1 coin` and announces
  `1 coin earned` (`K05-BUG-1a/1b` run green; the view singularises both).
- **K05-BUG-2** — the label floors to 99 % at 249/250 (`K05-BUG-2` green);
  the remaining value mismatch is K05-BUG-6.
- **K05-BUG-3** — the count row stacks at 320/1.3 instead of ellipsising
  (`K05-BUG-3` green); the one-line heuristic's asymmetric window is
  K05-BUG-5.
- **K05-BUG-4** — the hero allows 3 lines: `Maximilian-Alexander` is whole at
  390/1.0 (3 lines), at 390/1.3 (3 lines, measured) and at 320/1.0 (3 lines);
  `K05-BUG-4` green.

## Checked clean (evidence in `k05_bugs_test.dart`, un-skipped and green)

| Area | Probe / test | Result |
|---|---|---|
| rapid double tap, same frame / staggered | `a same-frame double tap of the CTA lands on /kid-home once`, `a staggered double tap of the CTA still lands once` | pass |
| double push of the celebration | iteration-2 probe: two pushes → CTA lands on `/kid-home` | pass |
| CTA + system back, same frame | iteration-2 probe: settles on `/kid-home`, no exception | pass |
| lock → back → CTA | iteration-2 probe: gate → K05 → home | pass |
| lock double tap / a11y action | `the lock opens the gate exactly once…`, `the lock semantics action drives the real gate push` | pass |
| system back from a pushed celebration | `system back from a pushed celebration returns to the pusher` | pass |
| restart persistence | `a completed quest survives an app restart` | pass — same DB answers `+10` |
| 0 children / empty lists | `Seed.empty offers the picker…`, `an empty quest list still celebrates with +0 coins` | pass |
| 6 children / deleted active child | `six children do not change the active celebration`, `deleting the active child mid-view falls back to the picker` | pass |
| pill matrix 0/1/2/100 | iteration-2 probe: `+0 coins` / `+1 coin` / `+2 coins` / `+100 coins` + labels | pass |
| count row at 390/1.0, 390/1.3, 320/1.0, 320/1.3 | iteration-2 probes: one line / one line / one line / stacked, no ellipsis with seed values | pass |
| percent labels 0/1/125/249/250/260 | iteration-2 probe: 0 / 0 / 50 / 99 / 100 / 100 | pass |
| card label no longer duplicates the percent | iteration-2 probe: card node = `… Next Songbird.`, progress node separate | pass |
| 9999 coins @ 320/1.3 | `9999 coins at 320 px / 1.3x fits the pill` | pass — pill fits; count row is K05-BUG-5 |
| stress: 6 children + long name + dark + 320/1.3 | iteration-2 probe: renders, no exception | pass |
| dark bottom edge under a 34 px inset | `the dark bar surface reaches the edge under a 34 px inset` | pass |
| contrast | `every K05 token pair meets WCAG contrast…` | pass — 18/18 ≥ 4.5:1 |
| rebuild scope (`buildWhen`) | `quest_complete_view_test.dart` roster-only emission | pass |
| device matrix | `quest_complete_matrix_test.dart` overflow/gutters/tap-target cells | pass (bottom-band cells: see note) |

## Notes (not product findings)

- **4-line nicknames still ellipsise.** `Maximilian-Alexander-Wellington`
  needs 4 natural hero lines; the K05-BUG-4 fix caps at 3, so it ellipsises
  (no exception, full name in the semantics). The design h1 has no cap, but
  the cap keeps the realistic double-barrelled names whole; noted, not filed.
- **The test-stage matrix file's bottom-band cells are a false positive.**
  `quest_complete_matrix_test.dart` (owned by the concurrent test stage)
  iterates every `DecoratedBox` overlapping the band below the CTA and
  requires the bar surface colour — but `KidScope`'s full-screen background
  box (`color: kidSkyBottom` + gradient, `Positioned.fill`) overlaps it and
  is painted *behind* the bar, so all band cells fail regardless of the
  product. The product's bottom edge is correct: the iteration-2 `5_ui`
  capture measures the bar surface to the physical edge (and would fail a
  strip), and the pixel probes in iteration 1 agree. Left to the test stage.
- **Deep-link fallback order** (review finding 1) and **`kid_growth.dart`
  location** (review finding 2) remain carried minors outside this stage.
- **`NestProgress`'s `TextPainter` disposal** (review finding 5) and the
  **`pi` literal** (finding 6) are hygiene, not product bugs.

VERDICT: PASS
