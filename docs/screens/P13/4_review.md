# 4 — QA code review (iteration 4) — P13 Payout (parent)

Scope reviewed: `git diff main...HEAD` as of `ad85ec5` (iteration-4 build
checkpoint). Diff paths: 5 product files + 10 test files, all under
`features/pocket_money/` and `test/features/pocket_money/`, plus
`docs/screens/P13/**` — every path inside the RULES §1 allow-list.
`analysis_options.yaml`, `core/`, `app/`, other features, `tools/screens/`
untouched.

Since iteration 3 (`d5e3d82`, reviewed PASS) the product-code delta is one
file: `presentation/widgets/payout_sheet.dart` (+36/−27), implementing the
**ORCHESTRATOR_NOTES 23:25 copy mandate**. The rest of the delta is tests
(the committed `p13_iter3_audit_test.dart`, 530 lines, plus expectation
updates in five files) and notes.

## Mandatory ORCHESTRATOR_NOTES — verified against the tree

- **23:25 pronoun / no seed ids.** `PayoutSaveRow.label(name, goalTitle)`
  no longer takes `childId` at all — the seed-id gate is *deleted, not
  relocated* (`payout_sheet.dart:412-425`), so product code cannot branch
  on a seed id. Verified by grep: no `'maya'` / `'leo'` / `'goal-lego'` /
  `'Lego Friends set'` string in `lib/features/pocket_money/presentation/`
  outside a doc comment. The sentence is byte-exact against the mandate:
  `"Move $amount of $name's to their $title fund"` and
  `"Move $amount of $name's money to savings"` when the (trimmed) title is
  empty — including the ASCII 0x27 apostrophe. Row geometry kept: the
  saverow card stays `(20,612,370,684)` and the toggle track 51×31 at
  `(305,633)`, both still pinned (`payout_widget_geometry_test.dart`,
  `p13_bugs_test.dart`); the longer sentence wraps to two lines, which I
  verified is what the design itself does (two ink bands at y≈632–644 and
  ≈654–663 in `P13-payout.png`, so the 72 px row is text-driven either
  way). Copy tests updated everywhere: `kSaveCopy` in
  `payout_view_test.dart` / `payout_responsive_test.dart`, the geometry
  test's card-owner string, both audit files, `p13_bugs_test.dart`.
- **19:48 items 1–3** (full-screen scrim, inline 13 px amount, row text y
  ±1): unchanged since iteration 2 and still pinned green — now also in
  **dark** (`p13_iter3_audit_test.dart:386-445`).
- **23:55 family_time exemption** — see *Out-of-scope observations* §A.

## Gates run by this stage (no simulator, no code edited)

```
flutter analyze                          → No issues found! (5.1 s)
dart format --set-exit-if-changed
  lib/features/pocket_money test/features/pocket_money → 49 files, 0 changed
flutter test test/features/pocket_money  → +464 ~1: All tests passed!
flutter test (full repo)                 → 35 failures, ALL outside
                                           pocket_money (see §A)
```

## New findings (iteration 4) — none

No blocker, major or minor findings in this iteration's delta. The single
product change is a faithful implementation of the 23:25 mandate, and the
test updates are consistent across all six files (constants, expectations,
comments).

## Carried from earlier iterations — still open, still minor

1. **MINOR — `_lastFailure` re-arm block has an unreachable branch.**
   `payout_view.dart:51, 210-214`: the failure listener always clears
   `_submitted` when it toasts (`:86-89`) and the only writer of
   `_submitted` also nulls `_lastFailure` (`:239-240`), so
   `error != _lastFailure` can never be false and `:213
   _submitted.clear()` can never run. The reachable half (same-frame
   re-entry drop) is correct and tested. Fix: delete the block or comment
   it as defensive-only.
2. **MINOR — no `performAction` test for the scrim's dismiss node.**
   `'Close payout'` now has `hasAction` coverage in two files
   (`payout_view_test.dart:556-561`, `p13_iter3_audit_test.dart:484-501`)
   and a physical `tapAt` dismissal test, but nothing calls
   `performAction(SemanticsAction.tap)` on the node — the exact path
   VoiceOver/TalkBack uses. Node wiring is correct
   (`payout_view.dart:337-341`); coverage gap only. Fix: three lines —
   `performAction`, settle, assert `currentPath == '/money'`.
3. **MINOR — stale narrative comment in the BUG-01 regression test.**
   `p13_bugs_test.dart:313-314` still says "the sheet has no in-flight
   state — the CTA stays enabled and looks untouched" in the present tense,
   above assertions that pass *because* the CTA is `loading:` and inert.
   Fix: reword to past tense.

## Out-of-scope observations (NOT findings — for the orchestrator)

A. **The full repo suite is red with 35 date-rollover failures, none in
   pocket_money.** My own full run reproduces the integrate stage's
   distribution exactly (`kid_home_view_test` 20, `k03_bugs_test` 8,
   `approvals_view_states_test` 3, `p08_bugs_test` 2,
   `approvals_view_test` 1, `family_time_test` 1): tests are pinned to Sat
   3 Oct 2026 (`test/flutter_test_config.dart`) while the real clock is now
   Sun 4 Oct, so the period rule correctly reclassifies seeded 3-Oct
   completions. The integrate stage verified by grep that none of the six
   failing files imports `pocket_money`; my run shows the same set and zero
   pocket_money failures. The 23:55 note exempts the single
   `family_time_test` case; the widened set needs the in-flight
   `shared/family_time_test_fix` (SHARED_REQUEST #2) to cover it. This is
   main-side and out of P13's edit rights — not a P13 finding.
B. **5_ui iteration 4 FAILed on the saverow copy — and the 23:25 mandate
   says it is not a finding.** The UI stage measured the mandated sentence
   (`Move £1.00 of Maya's to their Lego Friends set fund`) against the
   design HTML (`… to her Lego fund`) and reported it as a COPY deviation,
   while also measuring every affected shape (saverow card, toggle track,
   y-extents) at Δ 0. The orchestrator's 23:25 update is explicit: "this is
   the intended copy, so the design's 'her Lego fund' is NOT a finding",
   and ORCHESTRATOR_NOTES items are mandatory / override the designs. The
   code follows the highest-authority ruling; the UI verdict contradicts
   that ruling and is for the orchestrator to reconcile (e.g. by updating
   the note or the UI-stage brief). The product code should NOT be reverted
   to the design string without a new orchestrator decision.
C. **Concurrent stage activity** — during my run, the 6_bugs session
   edited `p13_bugs_test.dart`'s header comment (uncommitted, doc-only so
   far) and 5_ui wrote its `ui/*_4.png` artefacts. Uncommitted work per the
   process rule; the committed diff is what this review covers, and every
   gate result above was re-taken after the writes settled (analyze clean,
   format 0 changed, feature suite +464 ~1 green).

## Checked and found correct (no action)

- **The `label()` rewrite.** No callers other than the row; the `childId`
  parameter is gone from the signature and the call site
  (`payout_sheet.dart:447`); whitespace-only titles fall back to the
  savings sentence (tested, `p13_iter3_audit_test.dart:141-151`); case
  variants of the goal title interpolate verbatim (:133-139); the pure
  matrix asserts **no** shape can produce `" her "` (:153-170) and the
  seeded render is byte-exact end-to-end (:177-189).
- **New committed audit file** (`p13_iter3_audit_test.dart`, 19 tests, 0
  skips): isolated via `setUpTestScope`'s GetIt reset; real-font pins via
  `FontLoader`; dark re-pins of the scrim rect `(0,0,390,844)`, row-text y
  and the ink-2 amount; the toggle hit-slop probes now measure from the
  painted edge (`pill.top - 5` lands, `pill.top - 20` does not) — which
  also retires my iteration-3 minor about the mis-measuring probe in
  `payout_responsive_test.dart` (its own `top + 2` tap still exists, but
  the overhang is now genuinely covered here).
- **Architecture / RULES §1.** No new domain/data edits; the only `data/`
  change in the whole diff remains the iteration-2 `recordPayout` guards;
  route/DI untouched.
- **Design system / tokens.** No new literals, colours, fonts or tracking;
  the copy change introduces no metrics; `NestToggle` usage unchanged since
  main's batch5.
- **Copy.** Aside from the mandated sentence (highest authority), every
  other string is unchanged and byte-exact against `P13-payout.html`
  (apostrophes, `·`, `&`, em dash in the toast); summary string unchanged
  with `TextAlign.start` from iteration 3.
- **Accessibility / performance / error handling / Children's Code.**
  Unchanged from the iteration-2/3 PASS state: every control has a tap
  action, disabled/busy CTA exposes none, no timers or owned streams,
  `buildWhen` narrowing, stream-proof success, friendly retry, no
  analytics/ads, kid-mode guard intact.
- **Test hygiene.** No P13 `skip: true` anywhere (the sole feature skip is
  pre-existing P12); no `google_fonts`; the P12 `pageBack → handlePopRoute`
  change remains the only out-of-chunk line, mechanics-only.

## Verdict

No blocker and no major findings. The iteration-4 product change implements
the mandatory 23:25 copy decision exactly (seed-id gate deleted, one
ungendered data-driven sentence, row geometry kept) with consistent tests
and a strong new audit file. Three carried minors (unreachable re-arm
branch, missing scrim `performAction` test, stale BUG-01 comment) do not
gate. The repo-wide red suite is the documented main-side date rollover,
zero of it in `pocket_money`; the 5_ui copy deviation contradicts the
orchestrator's own 23:25 ruling and is flagged for reconciliation, not
coded against.

VERDICT: PASS