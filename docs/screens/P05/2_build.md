# P05 · Add children — build notes (STAGE 2, iteration 2)

Route `/add-children` (feature `family`, parent mode). Iteration 1 record is
superseded below; the loop's shared fixes that landed on main since (compact
nav 60 px + null-title support, `SEED=onboarding_kids`) are consumed, not
re-patched. Every item in `docs/screens/P05/FIXES_1.md` is addressed; all 8
skipped proofs in `app/test/features/family/p05_bugs_test.dart` are un-skipped
and green.

## Files changed (RULES §1 only)

- `app/lib/features/family/presentation/bloc/family_event.dart` — deleted
  `FamilyChildrenRequested` (review finding 4; nothing dispatched it, and the
  review shows its justifying comment was wrong about bloc transformers).
- `app/lib/features/family/presentation/bloc/family_state.dart` — added
  `lastSavedNickname` (`String?`, null; copyWith + props) for the BUG-5
  conditional clear.
- `app/lib/features/family/presentation/bloc/family_bloc.dart` —
  `_closeOnError` transform on the load subscription (finding 3 / P05-BUG-4,
  same construction as P08-B08); `if (state.saveInProgress) return;` guard
  (P05-BUG-2); draft clears only when unchanged since the save started +
  records `lastSavedNickname` (P05-BUG-5); `debugPrint` on save failure
  (finding 12); presentation helpers moved out (finding 11).
- `app/lib/features/family/presentation/widgets/child_display.dart` — NEW
  feature-private home for `avatarColourFor` / `displayAgeBand` (finding 11).
- `app/lib/features/family/presentation/views/add_children_view.dart` —
  dropped the `title: ''` + `TODO(P05)` workaround (shared nav fix landed;
  passes no title); Continue branches on the bloc draft (finding 9);
  save-success listener clears the field only while it still holds the saved
  nickname (P05-BUG-5); h1 wrapped in `Semantics(header: true)` (finding 7 /
  P05-BUG-7).
- `app/lib/features/family/presentation/widgets/add_child_form_card.dart` —
  each chip in `IntrinsicWidth` (P05-BUG-1 P05-local fix); chip row in
  `Semantics(container, label 'Age band')` (finding 5); swatches rebuilt on
  `Material` + `InkWell(CustomBorder: CircleBorder)` (finding 6); band
  labels via shared `displayAgeBand` (dup helper removed).
- `app/lib/features/family/presentation/widgets/kid_card_grid.dart` —
  `Center` → `Align(topCenter)` so content starts at the 12 px padding
  (finding 8); the 1 px pencil offsets stay with a mirrors-`.edit` comment
  (finding 13 — no 1 px step exists in `NestSpacing`, core is read-only);
  imports helpers from `child_display.dart`.
- `app/lib/features/family/data/family_repository_impl.dart` — `addChild`
  derives `ageYears` from the band (4-6→6, 7-9→9, 10-12→12, 13+→13, else 7)
  instead of inheriting the schema default (P05-BUG-6). Interface untouched.
- `app/test/features/family/add_children_test.dart` — the two
  `FamilyChildrenRequested` blocTests removed (event deleted; the
  load-event equivalents already cover roster + stream-error); helper import
  moved to `child_display.dart`; two save-success expects now assert
  `lastSavedNickname`.
- `app/test/features/family/p05_bugs_test.dart` — all 8 skips removed. The
  two BUG-1 proofs assert the fix's mechanism, not test-font geometry (see
  below); header comment updated.
- `docs/screens/P05/SHARED_REQUEST.md` — nav-crash and nav-height items
  marked LANDED; chip component fix still open (P05-local workaround
  recorded); push investigation still open.
- `docs/screens/P05/2_build.md` — this file.

No files outside RULES §1 touched. No `domain/` interface changes, no
signature changes to existing members (additive `lastSavedNickname` only),
so P15 is unaffected.

## What was done about each fix item

- **P05-BUG-1 (major) + review finding 1 — chips stacked full-width.**
  Shared `nest_chip.dart` is read-only here, so the P05-local path from the
  review: each chip wrapped in `IntrinsicWidth` (44-min tap minimum
  survives). Measured in-test (fallback font ≈30% wider than Nunito): 4
  full-width rows → pills of 74/74/102/74 px on ≤2 rows, zero overflow at
  320/1.3. Production (real Nunito, review measurement ≈252–304 px ≤ 322 px
  run) renders the design's single row. The two un-skipped proofs assert
  this font-robustly — every chip box narrower than the 322 px run with at
  most two rows, and the chip block ≤100 px tall (was 200) — instead of the
  as-written single-row geometry, which only the production font can show.
  The UI stage re-verifies on-simulator.
- **P05-BUG-2 (minor) + review finding 2 — same-frame double submit.**
  `if (state.saveInProgress) return;` as the handler's first line. Both
  un-skipped proofs (add+add, add+Continue, gated repo) assert exactly one
  `addChild` call and pass.
- **Finding 3 / P05-BUG-4 — retry leaks watchers.** Copied P08's
  `_closeOnError` transformer onto the combined load subscription, so the
  error closes the stream and Try again starts exactly one fresh set.
  Un-skipped proof (cancel count 1, subscribe count 2) passes.
- **Finding 4 — dead `FamilyChildrenRequested`.** Deleted the event, its
  registration/handler, and the incorrect comment; the load subscription
  already covers the roster. Its two blocTests removed (load-event tests
  cover the same paths).
- **Finding 5 — chip group semantics.** Chip `Wrap` wrapped in
  `Semantics(container: true, label: 'Age band')`, mirroring the swatch
  group and the design's `role="group"`.
- **Finding 6 — raw `GestureDetector` swatches.** Rebuilt as
  `Semantics > Material(circle) > InkWell(CircleBorder) > Container`, the
  codebase pattern; keys, labels, `selected`, 44×44 size and ring unchanged.
- **Finding 7 / P05-BUG-7 — h1 header landmark.**
  `Semantics(header: true)` around "Who's in your nest?". Un-skipped proof
  (`isHeader`) passes.
- **Finding 8 — card content 5 px low.** `Center` → `Align(topCenter)`;
  avatar starts at the 12 px padding, 10 px slack rests at the bottom per
  the design. Card height unchanged, pencil inside.
- **Finding 9 — Continue read the controller.** Now reads
  `bloc.state.draftNickname` (synced on every keystroke); controller stays
  the field surface + refocus handle.
- **Finding 10 — `onSaved` callback on the event: NOT changed (explicitly
  optional in the review).** Removing it would change an existing member's
  signature (P15 shares this bloc; review confirms additive-only) and churn
  ~10 call sites/tests; the double-fire root cause is closed by the BUG-2
  guard instead.
- **Finding 11 — helpers in the bloc file.** Moved to
  `presentation/widgets/child_display.dart`; bloc, grid, form card and
  tests import from there. Duplicate `_displayBand` removed.
- **Finding 12 — swallowed save error.** `debugPrint('P05 addChild
  failed: $error')` alongside the inline message.
- **Finding 13 — hard-coded 1 px offsets.** Kept with a `mirrors .edit`
  comment (core tokens are read-only; no 1 px step exists to use).
- **P05-BUG-5 — typing mid-save discarded.** Bloc records
  `lastSavedNickname` and clears the draft only when it still holds the
  saved nickname; the view clears the controller only while the field still
  holds it. Un-skipped proof (type 'Ada' mid-save of 'Ollie' → field shows
  'Ada') passes; the normal save-and-clear tests still pass.
- **P05-BUG-6 — `ageYears` always 7.** `addChild` derives it from the band
  in the impl (no interface change). Un-skipped proof (13+ Zara →
  ageYears ≥ 13) passes.
- **P05-BUG-3 (observation) — roster order.** Untouched by design: DB
  nickname order is consumed as required; orchestrator owns the
  mock-vs-ordering call.
- **Cleanup notes.** `title: ''` workaround removed (shared fix verified in
  the merged `nest_nav_bar.dart`); review-only quality notes without
  functional defect folded into findings 5/6/10/11/12 above. Autofocus
  deliberately NOT added (review: design ring is a mock state).
- **Orchestrator notes (mandatory).** Chips flow horizontally with 8 px
  gaps (item 1); header not patched locally (item 3, shared fix consumed);
  bottom edge + alignment untouched and still covered by owner-rule tests
  (item 4). Item 2 (`SEED=onboarding_kids` for the UI check) is a stage-5
  concern; the grid already renders DB children either way.

## Verification tails

`dart format .` — clean (re-ran after every edit).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:11 +558: All tests passed!` (exit 0,
zero skips — `grep -c "skip: true"` returns 0 in both family test files).
Every widget test that pumps the app ends with `disposeApp(tester)`.

VERDICT: PASS
