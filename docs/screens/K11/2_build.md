# K11 · Badges — stage 2 build, INTEGRATE (iteration 2)

Merge of the two parallel builders for feature `badges`. Sources:
`2a_build_logic.md` (logic chunk, iteration 2) + `2b_build_ui.md` (UI chunk,
iteration 2), plan in `1_plan.md`, mandatory items in
`ORCHESTRATOR_NOTES.md`. There is no `FIXES_1.md` for this screen, so the fix
list is the orchestrator notes + `6_bugs.md` (K11-BUG-1/2) + `4_review.md`
findings 1–4.

**Outcome: the two halves merged with ZERO integration fixes.** The builders
touched disjoint file sets (logic: domain/data/bloc + repo/bloc tests; UI:
views/widgets + view/geometry tests), 2a reports no contract changes, and the
merged tree was already green — per "smallest change / do not redesign" this
stage changed no file under `app/`.

## Summary of 2a (logic chunk — domain / data / bloc)

- K11-BUG-2 fixed in the logic layer (orchestrator-mandatory):
  `watchActiveBadges` now combines `watchAppState` with the roster
  (`watchChildren(Seed.familyId)`, creation order) and resolves via
  `_resolveChildId` — persisted id when it names a real child, else the first
  child, else null → empty `BadgesData(childId: '', …)`. `watchItems` routes
  through the same resolution (its `?? 'maya'` is gone too). Doc contract
  updated, no signature change.
- Review finding 1 fixed (legacy `new(...)` constructor → modern syntax);
  finding 4 fixed (`BadgesState.copyWithLoading()`, loading path uses it so a
  retry starts with no stale `errorMessage`); finding 2 is widget code (2b's
  item); finding 3 is explicit hardening-only ("if ever touched") — left as is.
- Tests updated for the landed 9-row design seed
  (`shared/k11_badges_seed`): insertion order, 4 earned / 5 todo, new
  `child resolution (K11-BUG-2)` group (null active → Maya, unknown id →
  Maya, Zoe-only family → Zoe, no children → empty shelf, `watchItems` follows
  suit), bloc retry-spinner assertion tightened + `copyWithLoading` semantics.
- 2a's evidence on the still-skipped `k11_bugs_test.dart` K11-BUG-2 widget
  test: it fails identically against the ORIGINAL `?? 'maya'` implementation
  (temporary `git show HEAD:` swap, restored), and raw Drift watches stay
  silent in that write-then-subscribe widget pattern while one-shot queries
  work — i.e. below the logic layer (test-infra/FakeAsync), not product code.
  Un-skipping belongs to the test/bugs stage, not to a logic edit.

## Summary of 2b (UI chunk — views / widgets)

- K11-BUG-1 fixed in the UI chunk (orchestrator-mandatory):
  `happy_week_card.dart` clamps once (`final days = happyDays.clamp(0, 7)`)
  for both dots and why-line, and `HappyWeekCopy.why` clamps its own input
  too. A stored 8 fills seven dots and reads "7 happy days", never "8 happy
  days". Verified in this tree's diff (verified above, not taken on trust).
- `TODO(K11)` removed from `badges_view.dart` — the orchestrator's
  `shared/k11_badges_seed` landed, so the seed carries the design's nine
  badges in order with Maya's earned set unchanged. Verified: no `TODO(K11)`
  remains under `app/lib/features/badges`.
- Badge art: no edit needed — `_artFor` already maps all nine design ids to
  their own medal in earned and locked states, light and dark.
- Tests (own files only): geometry 8→9 cells at 320/1.3, new
  `K11 happy-day clamp (K11-BUG-1 regression)` group (3 tests) in
  `badges_view_test.dart`. `k11_bugs_test.dart` left skipped for the bugs
  stage (outside the UI chunk's filenames).

## FIXES items

### Done (verified on the merged tree)

- K11-BUG-1 — widget clamp + `why` clamp + 3 regression tests (2b).
- K11-BUG-2 — repository resolution, no hard-coded `'maya'` anywhere in the
  feature (2a); proven by the 5-test repo resolution group. Only the
  write-then-subscribe *widget-pattern* repro in `k11_bugs_test.dart` still
  skips — see LEFT.
- Review findings 1 (ctor syntax), 2 (= K11-BUG-1 clamp), 4 (stale error on
  loading) — fixed. Finding 3 left as is per its own hardening-only note.
- `SHARED_REQUEST.md` seed item — closed, landed as `shared/k11_badges_seed`;
  `TODO(K11)` removed; grid renders DB order.

### LEFT (not integration issues, owned by later stages)

- Un-skip K11-BUG-1 in `k11_bugs_test.dart` now that the widget clamp lands
  (bugs stage).
- Un-skip K11-BUG-2 in `k11_bugs_test.dart` (bugs/test stage — needs the
  write-then-subscribe widget-pattern silence investigated; 2a's control
  experiment shows it reproduces without the logic change, likely
  infra/FakeAsync rather than product code).
- UI check not run (stage 5 owns the simulator).

## Orchestrator rules re-checked on the merged tree

- `grep google_fonts|GoogleFonts|DateTime.now` over `lib/features/badges` +
  `test/features/badges` → comment mentions only, zero call sites.
- Tokens only; `KidScope` shared sky+meadow (no local hills); `NestBalancedText`
  on the `.kid-title`; children/badges in DB insertion order (Maya, then Leo;
  never alphabetical); counts from the database; no `clock`/`newId` misuse in
  the feature; no simulator booted by this stage; no `flutter clean`;
  `analysis_options` untouched; no `pkill`/`killall`.
- Files modified are all inside `app/lib/features/badges/**`,
  `app/test/features/badges/**`, `docs/screens/K11/**` (RULES §1).

## Command tails (verbatim)

```
$ dart format .
Formatted 660 files (0 changed) in 3.31 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 9.1s)

$ flutter test --timeout 120s test/features/badges/
00:02 +129 ~2: All tests passed!

$ flutter test --timeout 120s   (full suite)
01:38 +4746 ~15: All tests passed!
```

Full suite: **4746 passed, ~15 skipped, 0 failed.** Feature suite: **129
passed, 2 skipped** (the two `k11_bugs_test.dart` skips), 0 failed. `dart
format` clean, `flutter analyze` → No issues found. No integration breakage:
no mismatched BLoC states/events, no import or rename conflicts, no failing
test caused by the merge — nothing to fix.

VERDICT: PASS
