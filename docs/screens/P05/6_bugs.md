# P05 · Add children — bug hunt (STAGE 6, iteration 2)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on
`screen/P05` at the iteration-2 build (working tree after
`8f7a170 P05: loop iteration 1`, uncommitted iteration-2 fixes; main merged
through `45c5605`).

Gates on this build: `dart format` clean · `flutter analyze` No issues
found! · `flutter test test/features/family` **98 passed, 1 skipped, 0
failed** · no file outside RULES §1 touched.

Proofs: `app/test/features/family/p05_bugs_test.dart` — the eight
iteration-1 proofs (P05-BUG-1, 2, 4, 5, 6, 7) run **un-skipped and green**;
the new **P05-BUG-8** proof carries `skip: true` with the id in the name so
the suite stays green. Verified failing with
`flutter test --run-skipped test/features/family/p05_bugs_test.dart`
→ the eight fixed proofs pass, P05-BUG-8 fails exactly as recorded.

**Result: 1 major open (P05-BUG-8, the device-only grid inset bug already
reported by stage 4/5 — now proved deterministically in-widget), 0 new minor
bugs. All eight iteration-1 bugs are fixed and stay fixed. VERDICT: FAIL**
— the major clips the swatch row and the helper caption behind the bottom CTA
on any device with safe-area insets.

---

## P05-BUG-8 — MAJOR — the kid grid re-applies the device safe-area insets, pushing the form card ~81 px down and clipping the swatches + caption behind the CTA

**Where:** `app/lib/features/family/presentation/widgets/kid_card_grid.dart:33-44`
— the inner `GridView.builder` passes no `padding`. `BoxScrollView` only
consumes `MediaQuery.padding` when `padding == null`, so on a device the
47 px top / 34 px bottom insets become the grid's own `SliverPadding`
(the outer `ListView` is immune because it passes explicit padding, and it
does not remove the ambient padding for its children).

**Repro (deterministic, in-widget — this is what stage 4's probe missed):**
the test surface defaults to zero insets, so the suite cannot see it. Set the
device insets the way a real device reports them — `MediaQuery.padding` comes
from `view.padding`, `viewPadding` from `view.viewPadding`:

```dart
const insets = FakeViewPadding(top: 47 * 3, bottom: 34 * 3); // physical px @3x
tester.view.padding = insets;      // ← stage 4 only set viewPadding, so
tester.view.viewPadding = insets;  //   MediaQuery.padding stayed zero
await pumpAppRoute(tester, '/add-children');
```

Measured (390×844, demo seed, fallback font):

| gap | design (HTML) | zero insets | device insets |
|---|---|---|---|
| subtitle bottom → first card top | 14 (`.kid-grid` margin-top) | **14.0** ✓ | **61.0** (14 + 47) |
| last card bottom → form card top | 12 (`.form-card` margin-top) | **12.0** ✓ | **46.0** (12 + 34) |

On-device impact, measured from the loop's own artifacts in stage 4/5
(`docs/screens/P05/ui/iteration2_test_probe_light.png`, `app_light_2.png`):
kid grid top 234 vs 187 design (+47), form card top 404 vs 315 (+89), only
the swatch tops peek above the CTA (top 645) and “We only ask for an age
range so quests suit them.” is not on screen at first paint. A secondary
consequence of the same padding: when the keyboard opens, `padding.bottom`
collapses to 0 and the grid's 34 px bottom padding disappears, shifting the
content under the finger.

**Proof:** `[P05-BUG-8] the kid grid does not add the device safe-area
insets` (skip: true) — expected 14, actual 61; the second assertion is 12 vs
46.

**Suggested fix (one line, RULES §1):** `padding: EdgeInsets.zero` on the
`GridView.builder` in `kid_card_grid.dart`. The review's `Wrap` alternative
(no nested scrollable at all, `SPACING_SPEC` §10.2 allows it) also closes it.
After the fix, re-measure the ~23 px of known excess (kid card +11 px pencil
headroom, chip row +12 px 44-px tap boxes — `5_ui.md` deviations 2/3): the
design fits with zero slack, so the caption may still kiss the CTA.

---

## Iteration-1 bugs — all fixed and regression-proofed

| # | Bug (iteration 1) | Fix | Proof status |
|---|---|---|---|
| P05-BUG-1 | Chips stacked full-width, swatches under the CTA | P05-local `IntrinsicWidth` per chip; shared `NestChip` request still open | green (2 proofs) |
| P05-BUG-2 | Same-frame double submit | `if (state.saveInProgress) return;` first line of the handler | green (2 proofs) |
| P05-BUG-4 | Retry leaked the failed load's watchers | `_closeOnError` transform on the combined load stream | green |
| P05-BUG-5 | Typing mid-save discarded | `lastSavedNickname` + conditional clear in bloc and view | green |
| P05-BUG-6 | New children always stored `ageYears = 7` | band → age mapping in `FamilyRepositoryImpl.addChild` | green |
| P05-BUG-7 | H1 had no header landmark | `Semantics(header: true)` | green |
| P05-BUG-3 | Roster order (DB vs mock) | Orchestrator-owned; unchanged | observation |

The iteration-2 changes were also re-read adversarially: the `saveInProgress`
guard cannot drop a legitimate retry (state clears on success and failure),
the conditional clear cannot clear newer typing (`lastSavedNickname` compares
trimmed values and the field is only cleared while it still holds the saved
name), `_closeOnError` still delivers the failure state before closing, and
the `ageYears` mapping is monotonic (6/9/12/13, unknown → 7) matching the
seed’s own ages.

## Verified sound (adversarial probes on the iteration-2 build)

| Area | Result |
|---|---|
| Rapid double taps | two same-frame taps with the real DB insert **one** child (bloc guard); next-frame re-tap already covered |
| Data edge cases | 0 children → form-only; 1 child → 170 px card; 6 children incl. “Maximilian-Alexander” → 3 computed rows; empty roster list → no grid; no exceptions |
| Text scale 1.3 × 320 | six children + long names, **with device insets too** → no overflow, grid scrolls |
| Kid-mode guard | kid-mode deep link to `/add-children` → `/parental-gate` |
| Restart / Drift persistence | child added, fresh app launch over the same DB → card present |
| Dark mode + insets | CTA surface runs to the physical bottom edge (624…844) with the 34 px home-indicator inset |
| Async gaps | bloc drops emits after close; `onSaved` callbacks are `mounted`-guarded |
| Money / timezone | P05 renders no money or dates — N/A by construction |
| Owner rules (zero insets) | 20 px gutters, form card == CTA edges, CTA to the physical edge — existing tests green |

## Fix-pass notes

* P05-BUG-8 is the only gate blocker; it is the same defect stage 4 filed as
  finding 1 and stage 5 as deviation 1, now with a deterministic widget proof
  (stage 4's probe set only `viewPadding`, which does not feed
  `MediaQuery.padding` in tests).
* The shared `NestChip` request (`SHARED_REQUEST.md` #3) stays open: the P05
  `IntrinsicWidth` workaround holds until the component fix lands.
* Known residuals after the BUG-8 fix (stage 5 deviations 2/3): kid card
  +11 px, chip row +12 px — re-measure the caption against the CTA.

VERDICT: FAIL
