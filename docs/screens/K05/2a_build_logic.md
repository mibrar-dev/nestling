# K05 Quest complete — 2a build logic (iteration 1)

## CONTRACT CHANGES

1. `KidChild.pipTotalCoins` is **defaulted (`= 0`)**, not `required` as the
   plan §b words it. Reason: a `required` field breaks all 15 existing
   `KidChild(` fixtures, most of them in view/widget tests owned by the
   parallel UI builder and outside this stage's editable set
   (`bloc`/`cubit`/`repository`/`data`-named tests only). A default keeps
   every existing call site compiling with identical runtime semantics —
   the repository always maps the real DB value. UI builder: you may pass
   `pipTotalCoins:` explicitly or omit it; both compile.
2. Growth helpers live in a **new domain file**
   `domain/entities/kid_growth.dart` (`kidPipCoinsRemaining`,
   `kidPipGrowthFraction`, `kidPipGrowthCopy`, `kidPipGrowthCount`) instead
   of the view / `kid_style_helpers.dart` (widgets are UI-builder owned and
   off-limits to this stage). Same formulas as plan §b; threshold is the
   canonical `PipProfile.evolveAtCoins` (250) via import, never hard-coded.
   Singular handled (`1 more coin`); `remaining == 0` →
   `Pip is ready to grow!`; fraction clamped `0.0..1.0`. Next-stage name
   (`Next: Songbird`) stays with `pipStageName` in the UI layer per plan.
3. No BLoC event/state shape change: no new events; `copyWithLoaded`
   already carries the `KidChild` object, so `pipTotalCoins` flows through
   untouched. Route/DI unchanged (`/quest-complete` already wired with
   `KidHomeLoadRequested`).

## Files changed

- `app/lib/features/kid_home/domain/entities/kid_child.dart` — added
  `pipTotalCoins` (default 0) + `props` entry.
- `app/lib/features/kid_home/domain/entities/kid_growth.dart` — NEW, pure
  growth helpers (no clock, no widgets).
- `app/lib/features/kid_home/data/kid_home_repository_impl.dart` — `_toChild`
  maps `pipTotalCoins: row.pipTotalCoins`.
- `app/test/features/kid_home/kid_home_bloc_test.dart` — `_maya`/`_leo`
  fixtures carry 175/60; new test: `copyWithLoaded` carries the field and
  it shapes equality.
- `app/test/features/kid_home/kid_home_repository_test.dart` — new `K05
  pipTotalCoins mapping + growth helpers` group: DB truth (Maya 175, Leo
  60, creation order), remaining 75 / fraction 0.7, Leo 190 / 0.24, card
  copy/count incl. ready-to-grow clamp.

## Items done (plan §b)

- `KidChild.pipTotalCoins` mapped in `_toChild` from `row.pipTotalCoins`.
- Growth helpers: remaining, fraction, copy, count — pure, tested.
- No new events; celebration reads `extra` + stream child (view-owned).
- No `google_fonts`, no `DateTime.now()`, no new ids, no hard-coded numbers.

## Verification

- `flutter analyze lib/features/kid_home` → No issues found.
- `flutter test --timeout 120s kid_home_repository_test kid_home_bloc_test`
  → All tests passed (62).
- `flutter test --timeout 120s quest_detail_bloc_test k01_bloc_paths_test`
  → All tests passed (32, compile guard for older fixtures).
- `dart format` clean on all touched files.
- `git status`: only domain/data + in-scope tests + this note; no
  views/widgets/core/router/DI edits. No simulator use.

## LEFT FOR NEXT ITERATION

- Nothing in this layer. UI builder consumes: `state.child.pipTotalCoins`
  + `kid_growth.dart` helpers + `pipStageName(child.pipStage + 1)` for
  `Next: …`. Integrator runs the full suite + goldens.

VERDICT: PASS
