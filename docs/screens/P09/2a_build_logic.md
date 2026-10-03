# P09 — 2a build, logic chunk (FIXES_1 iteration)

## CONTRACT CHANGES (UI builder: read first)

Two additive interface changes on `QuestsRepository` (no renames, no shape
changes to events/states). The view half of each bug is yours; the data
half is done and tested here:

1. **NEW: `Stream<int> watchCoinValuePencePerCoin()`** (BUG-P09-1). Reads
   the `families` row — the source of truth, same read as pocket_money's
   setup — emits `1` until the row exists, re-emits on every change. The
   editor's Reward helper must subscribe to this and render
   `'= ${coins * rate}p at payout'` instead of `const _pencePerCoin = 1`.
   Do NOT read it via `SettingsRepository.watchSettings()`: the skipped
   proof writes the `families` row directly, so only the families-backed
   stream un-skips it. Keep the demo-seed `= 15p at payout` assertion (rate
   is 1 there) and add the 2p case from the bug repro.
2. **NEW: `createQuest`/`updateQuest` throw on coins outside 1..100**
   (BUG-P09-4: `AssertionError` in debug, `ArgumentError` in release —
   same assert+throw shape as pocket_money's `setMode`/`setPayoutDay`).
   Writes never reach Drift, so the stored row is provably untouched; the
   bloc already maps the throw to `editorStatus.failure` + `editorError`
   (toast). The stepper clamp on load is still yours (view half).
3. No bloc/event/state changes. BUG-P09-2 (double-tap Save) has no
   logic-layer fix: bloc handlers run sequentially, so an in-flight guard
   would be dead code — the pill-disable + `_saving` flag from the bug
   report (view half) is the deterministic repair. BUG-P09-3 (icon aliases)
   and BUG-P09-5 (orphaned assignee fallback to Anyone) are view-only.

## Files changed (logic layer + one forced knock-on)

- `app/lib/features/quests/domain/quests_repository.dart` — new
  `watchCoinValuePencePerCoin()` + 1..100 contract docs on
  create/update.
- `app/lib/features/quests/data/quests_repository_impl.dart` — the rate
  stream (`families` row, `?? 1`); `minCoins/maxCoins` + `_checkCoins`
  called first in `createQuest`/`updateQuest` (now `async` so the throw
  surfaces as a failed future the bloc can catch).
- `app/test/features/quests/quests_repository_test.dart` (my file) — new
  `BUG-P09-1` group (seed rate 1; families rate 2 → stream emits 2, i.e.
  the bug repro at repo level; re-emits 1→2→1) and `BUG-P09-4` group
  (create 0/101/9999 throws + nothing written; update 9999 throws + stored
  row keeps 15 coins; boundaries 1/100 accepted).
- `app/test/features/quests/quest_editor_states_test.dart` — ONE added
  delegation override (`watchCoinValuePencePerCoin` → `_inner`). This file
  is outside my named scope, but the hand-written `_FaultyRepository`
  `implements QuestsRepository` and would not compile after the interface
  addition; the line is pure delegation with no fault injected and changes
  none of that stage's assertions. Flagged here, not hidden.

Not changed: bloc/events/state (sequential-handler analysis above),
entity, DI, routes. No `google_fonts`. No shared-file edits → no new
`SHARED_REQUEST.md` (P09's stepper-glyph §5, text-inset §6 and icon-glyph
§4 requests stand). `p09_bugs_test.dart` untouched: its 5 skipped proofs
stay skipped until the view halves land — un-skipping is the bugs stage's,
not this layer's.

## Verification (logic layer only)

- `flutter analyze lib/features/quests test/features/quests` → No issues
  found.
- Feature scope, split runs (one full-dir run was SIGKILLed by the
  machine, infra flake — halves all green): 63 + 75 + 58 + 69 + 65 =
  330 pass, `~5` skipped = exactly the documented BUG-P09-* proofs.
- `dart format` applied to all four touched files.
- Two implementation bugs caught by my own tests while building: sync
  throw invisible to `expectLater` (fixed: `async` bodies) and
  `Future<int>` vs `Future<void>` under `async` (fixed: `await`).
  Whole-app `flutter test` and any simulator deliberately NOT run
  (integrator / stage 5 own them); no simulator was booted.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. View halves for the UI builder:
  BUG-P09-1 helper wiring (item 1), BUG-P09-2 pill-disable + `_saving`
  flag, BUG-P09-3 alias map, BUG-P09-4 load clamp, BUG-P09-5 Anyone
  fallback; then the bugs stage un-skips the five proofs. Open P09 items
  elsewhere: `NestSegmented` shared fix; stage 5 UI check (±2 px).

VERDICT: PASS
