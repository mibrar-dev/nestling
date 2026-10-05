# P08b · 2_build — INTEGRATE (iteration 1)

Scope of this stage: make the merged result of 2a (logic) + 2b (UI)
compile and pass. Smallest-change fixes only; no redesign.

## Result: the two halves already merged cleanly

No integration breakage existed — **zero code changes were needed** in
this stage. The five files below are the builders' work, exactly as
handed over (verified, not re-authored).

## Summary of 2a (`2a_build_logic.md`)

- Contract unchanged: events (`TodayLoadRequested`), `TodayState` shape,
  `TodayRepository` interface, DI registration and `/today-empty` route
  all as-is — the UI half codes against the existing state fields.
- One bloc change (`presentation/bloc/today_bloc.dart`): the date line
  suffix becomes the static design string when there are no summaries —
  `'${formatLondonDay(now)} · ${summaries.isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}'`
  (middle dot U+00B7). Gated on `summaries.isEmpty`, so the P08
  demo-seed path is byte-identical. Clock still `appNowUtc()`; greeting
  still `dayPartForHour(toLondon(now).hour)`.
- `test/features/today/today_bloc_test.dart` extended to assert the new
  `dateLine` in the existing empty-state blocTest.
- Router/shell move left to `SHARED_REQUEST.md` (shared file, RULES §1).

## Summary of 2b (`2b_build_ui.md`)

- `presentation/widgets/today_loaded_body.dart` carries the ONE shared
  empty state (orchestrator ruling): `/today` and `/today-empty` both
  render it via `TodayLoadedBody`, branching on
  `state.items.isEmpty || state.summaries.isEmpty`. The populated P08
  branch below is untouched and unreachable on the demo seed, so P08's
  UI does not move. New private widgets: `_EmptyGreeting` (h1 28/34
  title + 15/22 w500 ink-2 date line, **no** plus button, **no**
  avatar), `_EmptyCard` (`NestCard` standard, padding 28/20, 140 px
  `PipAvatar(mochi, sunny, stage 1)` in an `image` semantics node, h2
  title, ink-2 message capped at 260 px, 8 px spacer, primary
  `NestButton('Add a quest')`, underlined sky `Browse ideas` link row
  wrapped in `Semantics(button, excludeSemantics, onTap:)` at ≥ 44
  height), `_TipCard` (`NestCard(inset)`, `Tip for new nests` + tip
  body). `NestEmptyState` deliberately not used (h3 title, 160 art box,
  different insets).
- Message copy derived from DB children (`emptyMessageSuffix`): 0 →
  first sentence only; 1 → `… Maya will see it straight away.`;
  2 → `… Maya and Leo …`; 3+ → UK comma-free
  `… Maya, Leo and Ava will see it straight away.` Names never
  hard-coded.
- `views/today_empty_view.dart`: doc-comment only — still renders the
  shared body, no separate empty view (per ORCHESTRATOR_NOTES item 1).
- `test/features/today/today_view_test.dart`: fixed the test that
  enshrined the truncated-message bug (now expects the Seed.empty
  first-sentence copy + byte-exact tip title/body), added a dark-theme
  same-copy test and a 320 px + 1.3× scroll-through-the-tip test.

## Integration checks run (all green)

- `dart format .` → `Formatted 625 files (0 changed)` — no reformatting
  needed after the merge.
- `flutter analyze` → `No issues found!` — so no import breakage, no
  unused imports left behind by the emptied `_EmptyCard`, no undefined
  members. The UI half's imports (`design_system.dart`,
  `pip_avatar.dart`) resolve against the merged file, and the
  pre-existing route imports (`approvals_routes`, `family_routes`,
  `kid_home_routes`, `settings_routes`, `quests_routes`) are still
  used by the populated branch.
- Full suite `flutter test --timeout 120s` → `+4293 ~10: All tests
  passed!` — 0 failures. P08's own tests are in that run (unchanged
  render path, unchanged greeting with `+`/avatar), and the P08b tests
  that already existed (quiet-nest card, `/today-empty` copy, Pip
  avatar 140, empty-state gutters 20/370, bottom-edge) all pass.
- Cross-half contract: 2b consumes `state.dateLine` verbatim, so 2a's
  new string needs no consumer change. `_PushOnce` (2b's guard) is
  defined in the same file above the new widgets. `TodayState.items`
  and `.summaries` still exist (unchanged shape), which is what the
  widened empty branch reads.
- Token fidelity spot-check against `design/html-source/screens/P08b-today-empty.html`
  (no hard-coded sizes/colour): `padding: 28px 20px` → the code's
  `NestSpacing.s8 - NestSpacing.s1` = 32 − 4 = **28** with
  `padSide` = 20 ✓; `h1` 28/34 w900 Nunito = `NestType.h1` ✓;
  `h2` 22/28 w800 = `NestType.h2` ✓; `.date` 15/22 w500 = `bodySmall`
  + `w500` ✓; `.linkrow a` 15 w600 sky underlined = `bodySmallStrong`
  + underline ✓; `.caption` 13/18 = `NestType.caption` ✓; no
  `letterSpacing` overrides added (loop rule) ✓.
- Copy bytes vs the HTML: `Your nest is quiet`, `Add your first quest
  and Pip will start to hatch.`, `Tip for new nests`, and the tip body
  with em dash `—`, curly quotes `“ ”` and en dash `–` inside
  `“Reading – 20 minutes”` — all match byte-for-byte in the merged
  code and in the fixed test.
- No `DateTime.now()`, no `google_fonts`/`GoogleFonts` anywhere in
  `lib/features/today/` or `test/features/today/` ✓.

## FIXES items

DONE (by 2a/2b, verified here):

- [x] Bloc date line → `A fresh nest` for the empty state, with test.
- [x] One shared empty state in `TodayLoadedBody` (no
      `TodayEmptyLoadedBody`); `TodayEmptyView` renders the same body.
- [x] Empty greeting without `+` and without avatar; P08 greeting
      untouched.
- [x] Children-ordered message copy (0/1/2/3+ variants), names from
      the DB.
- [x] Inset tip card + `Browse ideas` link row, byte-exact copy.
- [x] `PipAvatar(mochi, sunny, stage 1)` at 140 px with an
      `image` semantics label; no v1 `pip_stage_*.svg`.
- [x] Both actions carry `SemanticsAction.tap` (the link wrapper passes
      `onTap:` alongside `excludeSemantics: true`); navigation to
      `/quest-editor` (empty query) and `/quests` asserted by existing
      tests.
- [x] 320 px + 1.3× overflow test through the tip; dark-theme test.
- [x] Fixed the test that enshrined the truncated message.
- [x] `dart format` clean, `flutter analyze` clean, full suite green.

LEFT (not this stage's to fix — no compile/test blocker):

- [ ] `SHARED_REQUEST.md` — move `/today-empty` into the Today
      `StatefulShellBranch` in `app/lib/app/router.dart` (shared file).
      Until it lands, `/today-empty` has no `NestTabBar`, so the
      design's tab bar and the owner bottom-edge rule cannot be checked
      on this route; the existing bottom-edge test passes via `/today`
      with the empty seed meanwhile. Orchestrator owns
      `shared/p08b_shell`.
- [ ] `SEED=new_family` (Sarah + Maya + Leo, no quests) — will
      exercise the 2-name message variant on `/today-empty`. The 0-name
      variant is covered by `Seed.empty()` today; a widget test for the
      2-name sentence is worth adding once the seed lands on main.
- [ ] OBSERVATION for the review stage, not changed here: the message
      names come from `state.summaries`, which the shared repository
      sorts **eldest-first** (`today_repository_impl.dart`), not by
      insertion order. For Maya (9) then Leo (6) that coincides with
      creation order, so the mandatory CHILD ORDER ruling holds for the
      seeds in play, but a family whose second child is the elder would
      render the names in age order. Changing the ordering is shared
      repository behaviour used by P08's kids grid too, so it is not a
      P08b integration fix.
- [ ] Plan §f items not yet covered by a test (review/test stages, not
      integration failures): an explicit `SemanticsAction.tap`
      `performAction` test for the two P08b actions (taps are covered,
      the semantics-action path is not), and a bottom-edge assertion on
      `/today-empty` itself (blocked on the shell move).

## Verification tails

```
$ dart format .
Formatted 625 files (0 changed) in 2.96 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 13.9s)

$ flutter test --timeout 120s
03:15 +4293 ~10: All tests passed!
```

Zero failures; 10 pre-existing skips; no ignores added to
`analysis_options.yaml`; no simulator was booted, installed on,
screenshot or driven by this stage.

VERDICT: PASS
