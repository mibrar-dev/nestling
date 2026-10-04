# K08 · Reward shop — stage 3 test (iteration 3)

Scope: tests only. `app/test/features/kid_shop/**` — no `lib/` file was
modified, no screen code was patched. No simulator was booted, installed on,
driven or screenshotted; no `flutter clean`; `analysis_options` untouched; no
`skip:` marker anywhere in the feature.

Iteration 2 ended at 166 K08 tests with 4 failing proofs for K08-BUG-4 and
K08-BUG-5. The iteration-3 builders fixed both, landed `SHARED_REQUEST.md` §1
(`NestKidButtonColor.muted`) and §2 (route assertions), and changed the
`requestReward` contract from `Future<void>` to `Future<String?>`. This stage
adds **21** tests for that new surface and ends at **187 K08 tests, all green**.

| file | iter 2 | iter 3 | added |
|---|---|---|---|
| `kid_shop_bloc_test.dart` | 36 | 38 | +2 |
| `kid_shop_repository_test.dart` | 18 | 18 | — (2b added the status contract) |
| `reward_shop_view_test.dart` | 68 | 71 | +3 |
| `reward_shop_widget_geometry_test.dart` | 24 | 24 | — |
| `shop_reward_icons_test.dart` | 7 | 7 | — |
| `shop_reward_a11y_test.dart` | 7 | 7 | K08-BUG-5 now green |
| `shop_reward_get_off_test.dart` | — | 14 | **+14 (new file)** |
| `k08_bugs_test.dart` | 7 | 7 | all six proofs now green |

## What changed on `main`, and what it made testable

- **K08-BUG-4 fixed** — `requestReward` returns the status it wrote
  (`'approved' | 'requested' | null`) and `_onRewardRequested` toasts from
  *that*, never from a flag captured before the write. The transaction now
  returns its value.
- **K08-BUG-5 fixed** — `.k8-n` and the "N more to go" note each carry
  `Semantics(container: true)`, so no two rewards share an announcement.
- **`SHARED_REQUEST.md` §1 landed** — `NestKidButtonColor.muted` renders
  `surface-2` / `ink-2` at FULL opacity even when disabled, and the card uses
  it for `.k8-get.off`. This closes the deviation `1_plan.md` §g recorded
  (the washed-out `white` + 0.45 fallback) — and it is the first **visual**
  change to K08 since the design build, so it needed its own colour proof.
- **`SHARED_REQUEST.md` §2 landed** — the two `kid_home_view_test.dart`
  placeholder-copy assertions became route assertions, so the whole-app suite
  is green for the first time in three iterations.
- `ORCHESTRATOR_NOTES.md` UPDATE (17:10) confirmed the muted colourway is
  required; nothing outstanding in the file.

## Tests added

### `shop_reward_get_off_test.dart` (new, 14) — the `.k8-get.off` colourway

Reads the live palette through `context.nest` (the same extension the widgets
use, so the assertion cannot drift from what was painted) and the painted
`AnimatedContainer` inside each `NestKidButton`. In **both themes**:

- the out-of-reach café card paints `surface-2` with an `ink-2` label — the
  design's `.k8-get.off` pair, exactly;
- the control is at **full opacity**: the whole point of `muted` is that the
  grey pair IS the disabled look, with no 0.45 wash stacked on top;
- the five affordable cards stay `leaf` / `onLeaf` at full opacity, so the two
  states are told apart by colour rather than by a wash (a wash would make the
  *disabled* one the pale one);
- the box is untouched by the colour swap: 62-tall widget box (56 painted + 6
  `--sh-kid` shadow room), radius 16, **3 px ink border** (still `ink`, not
  `ink-2`), shadow kept, and the same width/height as an affordable card;
- it is still **disabled**: `isButton`, `enabled: false`, no tap action;
- the label is still 17 px w900 in `ink-2`;
- **WCAG AA**: `ink-2` on `surface-2` clears 4.5:1 in light *and* dark (≈7.7:1
  and ≈8.6:1 measured), and the enabled `leaf`/`onLeaf` pair still clears 3:1.
  This is the assertion that gives the swap its value: the old 0.45 wash over
  white was ≈1.9:1, i.e. unreadable.
- the colour is **derived, not remembered**: at 0 coins the café is
  `surface-2`; when the balance is raised to 200 the same card repaints
  `leaf`, its label flips to "Get it", and the "150 more to go" note
  disappears — so nothing about the off state can go stale behind the stream.

### `kid_shop_bloc_test.dart` (+2) — the rest of the new status contract

The builders covered `'approved'` → enjoy and `'requested'` → thumbs-up. The
two branches the new code added are untested until now, and both are reachable:

- **`written == null`** — `requestReward` returns null when the reward is GONE
  by the time the write runs (deleted after the stream last emitted, before
  the tap). The affordability guard reads `state.items` and still passes, so
  the write is the only thing that can catch it: the bloc must answer with the
  retry copy ("Hmm, that did not work. Try again.") and never "it's yours".
- **an unexpected status string** — the contract is `'approved' | 'requested' |
  null`; anything else must fall on the "a grown-up decides" side. Pins that
  the enjoy copy is reachable *only* from a real `'approved'`.

### `reward_shop_view_test.dart` (+3) — the empty state from REAL data

Iterations 1 and 2 both recorded that `Seed.empty` could not be pumped through
the app, because `Seed.empty` calls `db.clearAll()` on a database `AppSession`
is already watching and the reseed never completes in a widget-test isolate
(two stage-time hangs). That trap is now closed: seeding **before**
`configureDependencies` means there is no reseed at all, so the empty family
is proved against the real repository:

- `_useEmptySeed()` wires a scope around an `AppDatabase.memory()` seeded
  `Seed.empty` (onboarded parent, no children, no rewards);
- in light **and** dark the kid-voice empty state renders, with nothing stale
  from a populated shop (no cards, no balance pill, no footer promising coins
  the family does not have) — and the chrome still works: the lock reaches
  `/parental-gate` and back reaches `/kid-home`.

## Results

```
dart format .        Formatted 585 files (0 changed)
flutter analyze      No issues found! (ran in 3.0s)
flutter test --timeout 120s test/features/kid_shop/     187: All tests passed
flutter test --timeout 120s                          01:31 +3816 ~4: All tests passed!
```

**The whole app is green** for the first time in three iterations: the six
open proofs are fixed and the shared K03 blocker landed in `shared_batch8`. The
`~4` skips are the expected shared-code skips.

Rule audit: no `google_fonts` / `GoogleFonts`; no `DateTime.now()`; every
pumped app ends with `disposeApp`; no ids minted; the clock is the pinned
`test/flutter_test_config.dart` one (Sat 3 Oct 2026, no wall-clock copy
asserted); no simulator touched; no `skip:` in `test/features/kid_shop/**`; no
file outside RULES §1 modified.

## Bugs found (recorded, not patched)

**None this iteration.** K08-BUG-1 … -5 are all fixed and every proof for them
now runs green, which is the point of keeping them in the suite.

Hunt notes, so the next iteration knows where NOT to look again — each of these
was checked and is either a clean property or a defect in my own test:

| probe | result |
|---|---|
| every branch of the `Future<String?>` contract (`approved` / `requested` × covered / short / missing child / unknown id) | clean; all pinned |
| the bloc's `written == null` and unexpected-status branches | clean; both now pinned |
| `.k8-get.off` colour, opacity, box, semantics and contrast in both themes | clean; pinned in 14 tests |
| a card crossing back to affordable (coins 0 → 200) repaints fully — fill, label and note | clean; pinned |
| the `Semantics(container: true)` additions moved no layout | clean — the 24 geometry tests (which run with the real Nunito/Inter faces) still pin every rect within ±2 px |
| the café card at 120 coins is still out of reach | my first draft of the repaint test wrongly expected 120 coins to cover a 150-coin reward; the screen was right |
| `requestReward` writing an `approved` row and the coin deduction | still one transaction, so a failed deduction rolls the row back; the bloc's catch maps it to the retry copy |

## Defects in my own tests (recorded so they are not mistaken for findings)

Four, all found and fixed in this stage: a geometry assertion that used the
390 px column width inside a 320 px case; a WCAG helper whose `pow` was a no-op
stub (it reported 2.64:1 for a pair that actually measures 7.68:1 — the stub is
gone and the numbers are real); two test bodies that pumped the app without
`disposeApp`, which fails teardown with "A Timer is still pending" (Drift's
deferred stream-close). None of these touched `lib/`.

## Harness notes

- **`Seed.empty` IS pumpable** — seed before `configureDependencies`; see
  `_useEmptySeed()` in `reward_shop_view_test.dart`. The two iterations-1/2
  notes about this being impossible are now obsolete.
- **Drift writes inside `testWidgets` need `tester.runAsync`** (plus one
  real-zone turn) or the watch notification never lands and the shop sits on
  its spinner — the repaint test does this explicitly.
- **`pumpAndSettle` never meets a K08 loading state** (`CircularProgressIndicator`
  animates forever); the stalled-stream tests pump explicitly.

## Left for the next iteration

1. `5_ui` should re-shoot the café card: `.k8-get.off` is now a flat
   `surface-2`/`ink-2` block at full opacity instead of the washed-out white,
   so the design comparison for that one button is a real visual delta (the
   geometry around it is unchanged and still pinned).
2. Nothing is blocking `flutter test`.

VERDICT: PASS