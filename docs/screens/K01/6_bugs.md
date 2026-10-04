# K01 · Who's playing? — Stage 6 bug hunt (iteration 2)

Adversarial pass over `/who-is-playing` on the iteration-2 build
(`e195954`, main merged). Every proof lives in
`app/test/features/kid_home/k01_bugs_test.dart` and runs against the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake for the failure paths. No screen code was changed by
this stage.

```
flutter test test/features/kid_home/k01_bugs_test.dart
  → +21 ~2: All tests passed!       (2 proofs parked for the open bugs)

flutter test --run-skipped test/features/kid_home/k01_bugs_test.dart
  → 2 deterministic failures: K01-BUG-3, K01-BUG-6
```

## Status of the iteration-1 findings

| # | Severity | Iteration-2 status |
|---|---|---|
| K01-BUG-1 | major | **FIXED and verified** — `_OverflowTileRow` keeps 167 px tiles and scrolls |
| K01-BUG-2 | major | **FIXED and verified** — one burst pushes exactly one route |
| K01-BUG-3 | major | **STILL OPEN** — the new `KidHomeSelectionHandled` event is never dispatched |
| K01-BUG-4 | minor | **FIXED and verified** — blank nickname falls back to `Kid` |
| K01-BUG-5 | major | **FIXED and verified** — profiles retry restores the picker |
| K01-BUG-6 | major | **NEW, open** — the pushed route and the persisted active child disagree |

Also fixed this pass (tracked by the other stages, re-verified here):
5_ui D1/D2 — tiles and caption now sit at the design y (simulator 297.3 /
639.3 / caption ink 747; a widget-level regression probe compares the
corner-corrected design box: design centre 468.8, height 361.8), and the
title apostrophe now matches the HTML source (ASCII `'`).

---

## K01-BUG-3 — major — STILL OPEN — a tile is dead after returning from a kid route

The iteration-2 build added `KidHomeSelectionHandled`, its handler
(`kid_home_bloc.dart:154-159`), `copyWithSelectionHandled()` and updated
comments that say the picker "pushes the route, then dispatches"
`KidHomeSelectionHandled`. **No call site dispatches it.** `grep -rn
"KidHomeSelectionHandled" lib/` finds only the event definition, the state
doc-comment, the state method, and the bloc registration — never
`context.read<KidHomeBloc>().add(...)` in `profile_picker_view.dart` or
anywhere else. The mechanism is dead code.

**Repro (unchanged from iteration 1, re-confirmed on e195954):** Seed.demo
has `activeChildId == 'maya'`. Tap Maya → `/kid-pin`; back to the picker;
the picker's bloc still holds `selectedProfileId == 'maya'` (asserted);
tap Maya again → the path stays `/who-is-playing` — no navigation, no
toast. The equal `copyWithSelection('maya')` is dropped by the bloc.

**Failing test:** `K01-BUG-3: tapping the same tile after back does nothing`
(skipped; the first assertion pins the mechanism, the second the missed
navigation).

**Suggested fix (one line, in the picker's listener):** after
`context.push(...)` starts, dispatch
`context.read<KidHomeBloc>().add(const KidHomeSelectionHandled())` — or
consume the one-shot inside the bloc when the route push is acknowledged.
The bloc half already exists; only the view call site is missing.

## K01-BUG-6 — major — NEW — the pushed route and the persisted active child disagree

The new `_navPending` guard (K01-BUG-2 fix) single-flights the
**navigation**, but both `KidHomeProfileSelected` events still reach the
bloc: each awaits its own `setActiveChild` write and then emits. The first
emission pushes its route and sets the guard; the second emission is
swallowed — **but its write has already landed**, so `app_state` names the
other child. Every selection in the burst writes; only one navigates.

**Repro (deterministic, 3/3 runs):** two fingers down on Maya and Leo
before either up. Top route `/kid-pin` (Maya, whose PIN `1234` the child
would be asked for), `activeChildId == 'leo'`. When K02 finishes its PIN
flow, `watchHome` resolves `app_state.activeChildId` — the kid lands on
Leo's home after authenticating as Maya. The inverse order is symmetric
(`/kid-home` for Leo with `activeChildId == 'maya'`); the tapped route's
child and the persisted child can never agree while both writes run.

**Failing test:** `K01-BUG-6: route child and active child disagree`
(skipped). Measured: `opened maya (/kid-pin) but persisted leo`.

**Suggested fix:** drop the second selection’s **write** together with its
navigation — e.g. a synchronous `bool _selecting` in `KidHomeBloc` set
before the first `await` in `_onProfileSelected` and cleared on
completion/handled/failure, so concurrent events return early; or have the
picker disable all tiles with `IgnorePointer` for the burst. Combine with
the BUG-3 fix so the flag can never wedge.

---

## Iteration-2 regression checks (green, unskipped)

- **BUG-1** (4 proofs): 3 children keep 167 px tiles; 4+ children keep the
  avatar/pet discs circular; 6 children keep 167 px tiles and the row
  scrolls (the 6th tile is off the gutter until dragged, then reachable);
  a scrolled-to extra child (`Omar`) still selects and navigates to
  `/kid-home` with `activeChildId == 'omar'`.
- **BUG-2**: a two-finger burst pushes exactly one kid route and one
  Navigator pop returns to `/who-is-playing`.
- **BUG-5**: profiles-only failure → Try again → the recovered roster
  replaces the failure card and the title renders.
- **D1/D2**: widget probe (real bundled fonts) — tile centre 468.5 vs
  design 468.8, caption box top 738 (simulator ink row 747); 5_ui
  iteration 2 measured the simulator at 297.3/639.3/747 vs 297.7/640.0/747.
- **BUG-4**: an empty nickname renders the tile label `Kid, Age …`
  instead of an empty accessible name.
- **Copy**: the title is now the HTML source's ASCII `"Who's playing?"`
  (en dashes in the ages, ASCII hyphen in `Grown-ups` unchanged).
- Unchanged iteration-1 probes still green: 0 children / 1 child / long
  UK name at 320×1.3 / empty age band / no money or dates / same-tile and
  lock double taps / deep links kid+parent / restart persistence / 16
  contrast pairs / title-sub-caption fit at 320×1.3 / tap semantics.

## Process notes (not K01 findings)

- `app/test/features/kid_home/zz_scratch_measure_test.dart` (untracked,
  another stage's file, header says "deleted before commit") currently has
  one failing/timing-out test and 9 analyzer infos; while it exists, a
  whole-repo `flutter analyze` is red. `k01_bugs_test.dart` itself is
  analyzer-clean (`dart analyze` → No issues found).
- `k01_profile_picker_matrix_test.dart` et al. finished green
  (`flutter test test/features/kid_home/` → +310 ~2 −1, where the single
  failure is the scratch file above and the 2 skips are this file's open
  bugs).

VERDICT: FAIL
