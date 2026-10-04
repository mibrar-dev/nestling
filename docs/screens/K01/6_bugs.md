# K01 · Who's playing? — Stage 6 bug hunt (iteration 3)

Adversarial pass over `/who-is-playing` on the iteration-3 build
(`b9ba00a`, main merged). Every proof lives in
`app/test/features/kid_home/k01_bugs_test.dart` and runs against the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake. No screen code was changed by this stage.

```
flutter test test/features/kid_home/k01_bugs_test.dart
  → +23 ~1: All tests passed!        (K01-BUG-7 parked, minor)

flutter test --run-skipped test/features/kid_home/k01_bugs_test.dart
  → 1 deterministic failure: K01-BUG-7
```

## Status of every finding

| # | Severity | Status |
|---|---|---|
| K01-BUG-1 | major | **FIXED (iter 2), re-verified** — `_OverflowTileRow`: 167 px tiles, scrolls, discs circular |
| K01-BUG-2 | major | **FIXED (iter 2), re-verified** — one burst pushes exactly one route |
| K01-BUG-3 | major | **FIXED (iter 3), verified** — the listener dispatches `KidHomeSelectionHandled`; a tile navigates again after back |
| K01-BUG-4 | minor | **FIXED (iter 2), re-verified** — blank nickname falls back to `Kid` |
| K01-BUG-5 | major | **FIXED (iter 2), re-verified** — profiles retry restores the picker |
| K01-BUG-6 | major | **FIXED (iter 3), verified** — route child and persisted active child always agree |
| K01-BUG-7 | minor | **OPEN** — a latent orphaned-selection lock (no shipped flow reaches it) |

Also green: 5_ui iteration 3 PASS (tile top 297.3 vs design 297.7, caption
ink 747 vs 747, gutters, dark mode, bottom edge, meadow), and the
`1_plan.md` §0 copy record now matches the HTML source (ASCII apostrophe);
my copy probe agrees.

---

## K01-BUG-7 — minor — OPEN — an orphaned selection locks every tile

**Mechanism.** `_ProfilePickerViewState` arms `_busy` before dispatching a
selection and releases it on the pop, on a failure toast, or when the
listener cannot resolve the pending profile
(`profile_picker_view.dart`: `if (tapped == null) { _busy = false; return; }`
— this early return is the only path that releases `_busy` **without**
dispatching `KidHomeSelectionHandled`). In that window the bloc's one-shot
`selectedProfileId` stays set. The next tap arms `_busy` again, the bloc's
gate (`if (state.selectedProfileId != null) return;`) drops the event
silently, and `_busy` is never released: every further tap is swallowed
with no navigation and no feedback — a permanently dead picker.

**Repro (deterministic, widget test with a fake repo):** the roster loses
the tapped child while its selection write is still in flight
(`_RosterSwapRepository` drops Maya during `setActiveChild`), the empty
state renders, then Maya returns. The next tap on Maya leaves the path at
`/who-is-playing` instead of `/kid-pin`; measured exactly in the test.

**Reachability:** today no shipped flow writes the `children` table while
the picker holds a selection — parent add/remove (P05/P15) lives on other
routes, and v1 has no sync/import — so this is a latent hardening hole, not
a user-visible defect. That is why it is minor, not major.

**Failing test:** `K01-BUG-7: an orphaned selection locks every tile`
(skipped with `skip: true`; bug id in the test description).

**Suggested fix (small):** dispatch
`context.read<KidHomeBloc>().add(const KidHomeSelectionHandled())` before
the `tapped == null` return (or clear the one-shot in the bloc when no
profile matches), and reset the view’s `_busy` whenever a selection is
dropped. A bloc-level selection flag set before the first `await` would
close the whole class.

---

## Verified fixed this pass

- **K01-BUG-3** — `profile_picker_view.dart:74-78` now dispatches
  `KidHomeSelectionHandled` right after `context.push` starts, so the
  one-shot is consumed instead of relying on the racy home-stream emission.
  The drained regression (tap Maya → `/kid-pin` → back → `selectedProfileId`
  null → tap Maya → `/kid-pin`) is green.
- **K01-BUG-6** — `_busy` is armed *before* the selection event is
  dispatched, so a two-finger burst yields one `KidHomeProfileSelected` (one
  write, one route); the bloc gate is a second belt. The burst repro now
  asserts route child == persisted `activeChildId` (was `opened maya
  (/kid-pin) but persisted leo`) and passes.
- **K01-BUG-1** (4 proofs) — 3 children keep 167 px tiles; 4+ keep the
  discs circular; 6 keep 167 px and scroll; a scrolled-to extra child
  selects and navigates.
- **K01-BUG-2** — one burst, one route; one Navigator pop returns to the
  picker.
- **K01-BUG-5** — profiles-only failure → Try again → roster restores the
  loaded picker.
- **Unchanged probes still green:** 0 children / 1 child / long UK name at
  320×1.3 / empty age band / no money or dates / same-tile and lock double
  taps / deep links kid+parent / restart persistence / 16 dark-contrast
  pairs / title-sub-caption fit at 320×1.3 / tap semantics / D1+D2 geometry
  regression (corner-corrected design centre 468.8 and caption box 738).

## Notes (not bugs, for awareness)

- **Review iteration 3, finding 1 (minor):** `KidHomeState.profilesFailed`
  is now write-only in product code — the bloc tracks the same fact with
  its local `_profilesFailed` and the view no longer reads the state field
  (the iteration-2 view heal was removed). Harmless dead public state;
  either surface it or drop it in a later cleanup.
- **Review iteration 3, finding 3:** the bloc gate drops a second in-flight
  selection silently — correct when the first is pending (the view’s
  `_busy` prevents it in practice).
- `k01_bugs_test.dart` is analyzer-clean and `dart format`-clean; the
  concurrent stage’s `zz_scratch_measure_test.dart` has been deleted.

VERDICT: PASS
