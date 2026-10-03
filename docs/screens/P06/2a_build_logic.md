# P06 Pocket money setup — logic build (Stage 2a, iteration 7)

## CONTRACT CHANGES

None. No event/state shape changes and no repository interface changes —
same events, `PocketMoneyState.setup`, same
`watchSetup/setMode/setPayoutDay/setWeeklyBasePence` signatures. One
private helper deleted (see below); all feature fakes still compile
untouched.

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart`
  - Review #4: deleted the feature-private `_watchChildrenInsertionOrder`
    (raw `customSelect … ORDER BY rowid` plus its factually wrong
    "orders by nickname" rationale) and subscribed `watchSetup` to the
    canonical `AppDatabase.watchChildren(Seed.familyId)`, which implements
    the CHILD ORDER ruling (`ORDER BY createdAt, rowid`). Behaviour is
    unchanged (seed `createdAt` order == `rowid` order; ad-hoc inserts use
    per-insert `now()`), and the insertion-order tests pin it — including
    the Anna case, which now exercises the canonical query.

## Items done (FIXES_6, logic-layer only)

- #4 (custom child-order query): fixed as above.
- Everything else in FIXES_6 is view / view-test / shared-component /
  orchestrator-decision territory and was deliberately not touched: #1
  (coin-value right alignment, `_CoinValueRow`), #2 (semantics `onTap` on
  option cards/day cells), #3 (shared `NestButton`/`NestChip` tap action —
  core, forbidden; SHARED_REQUEST matter), #5 (`_FailureBody` watch), #6
  (radio semantics), #7 (empty-state copy ratification), #8 (spacing token
  as size).
- Skipped bug tests in my layer: none — the single remaining skip in
  `p06_bugs_test.dart` is P06-BUG-13 (coin-label wrap at 320×1.3), a
  view-layout probe that can only go green after the view fix for #1.

## Checks run (stage-allowed only)

- `dart format` on the touched file → clean.
- `flutter analyze` on domain + data + bloc + the three test files →
  `No issues found!`
- `flutter test pocket_money_setup_bloc_test +
  pocket_money_setup_repository_test` → `All tests passed!` (45/45).
- `flutter test p06_bugs_test` → `All tests passed!` (+27 ~1; the skip is
  the view-layer BUG-13 probe).
- Full-app `flutter test` and simulator NOT run (integrator owns them;
  per the SIMULATORS rule only the UI-check stage may boot one).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Open items for the UI chunk / shared track /
integrator / orchestrator: coin-row alignment (#1, then un-skip BUG-13),
semantics actions (#2, + shared #3 via SHARED_REQUEST), `_FailureBody`
watch (#5), radio semantics (#6), copy ratification (#7), radio-dot
constant (#8).

VERDICT: PASS
