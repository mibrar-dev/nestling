# 4 — QA code review (iteration 3) — P13 Payout (parent)

Scope reviewed: `git diff main...HEAD` as of `d5e3d82` (iteration-3 build
checkpoint, main merged at `9e1663e`). Since iteration 2 (`bf9f239`,
reviewed PASS) the feature delta is small and surgical:

- `presentation/views/payout_view.dart` (+7/−1) — 5_ui deviation 1.
- `presentation/widgets/payout_sheet.dart` (+13/−2) — P13-BUG-06 / P13-I2-01.
- Tests: `p13_iter2_audit_test.dart` (new, 629 lines, committed),
  `p13_bugs_test.dart` (+128), `payout_widget_geometry_test.dart` (+41),
  `payout_responsive_test.dart` (+10/−4).
- The savings-toggle deviation was fixed on **main** (`shared_batch5`:
  `NestToggle` 51×31 track + `_ToggleHitSlop`), which this branch picked up
  by merge — it is not part of this diff and is only re-verified here.

All diff paths remain inside the RULES §1 allow-list
(`features/pocket_money/**`, `test/features/pocket_money/**`,
`docs/screens/P13/**`). `analysis_options.yaml` untouched.

## Gates run by this stage (no simulator, no code edited)

```
flutter analyze lib                                    → No issues found! (3.3 s)
flutter analyze                                        → 11 infos, ALL inside one
                                                         untracked scratch file
dart format --set-exit-if-changed .                    → 1 changed = same scratch file
flutter test test/features/pocket_money                → all committed tests pass;
                                                         2 failures, BOTH inside the
                                                         other untracked scratch file
```

The worktree again holds **concurrent stage scratch files**
(`_probe3_p13_test.dart`, stage 6; `p13_iter3_audit_test.dart`, stage 3 —
both untracked, both being written live as I reviewed; the audit currently
does not compile: `'await' in a non-async method` at its line 356). Per the
process rule they are not findings; I verified **every** current
analyze/format/test failure maps to one of those two untracked files and
none to anything in the committed diff. Same pattern as iteration 2, where
the identical situation resolved into the committed, green
`p13_iter2_audit_test.dart`.

## Iteration-3 targets — independently verified

| Item | Status | Evidence |
|---|---|---|
| 5_ui deviation 1 — summary text centred, design left-aligned | **fixed** | `textAlign: TextAlign.start` with a comment that overrides `1_plan.md` §(a) (`payout_view.dart:322-327`); CSS truth confirmed: `.caption` sets no `text-align` (`components.css:34`), only `.cap` is centred and it applies only to the sheet's closing caption. Geometry test pins `textAlign == TextAlign.start` and glyph-box left ≈ 36 (card 20 + pad 16; design glyph origin measured 37) — `payout_widget_geometry_test.dart:107-121` |
| 5_ui deviation 2 — toggle track 4 px left (301–351 vs design 305–355) | **fixed** (via main) | New shared `NestToggle` lays out the 51×31 track as its own box with the 59×44 hit area overhanging via `_ToggleHitSlop` (`nest_toggle.dart:10-16, 96-169`), so the track now right-flushes to the saverow content edge (370 − 14 = 356). New geometry test pins `left ≈ 305 ±2`, `right ≈ 356 ±2`, `top ≈ 633 ±2`, `51×31` (`payout_widget_geometry_test.dart:169-194`). Component behaviour covered on main by `shared_batch5_test.dart:95-141` (size, 4 px-outside tap, semantics action) |
| P13-BUG-06 / P13-I2-01 — "her Lego fund" for a goal-bearing Leo (my iteration-2 minor 1) | **fixed** | `PayoutSaveRow.label(name, goalTitle, {childId})` now returns the design string only for the exact seeded shape (`childId == 'maya' && title == 'Lego Friends set'`), the neutral data-driven sentence otherwise (`payout_sheet.dart:421-437, 455`). Both reproducers un-skipped and green: `p13_bugs_test.dart:621` (goal moved to Leo on the real DB), `p13_iter2_audit_test.dart:343` (`goal-lego-leo` fixture). Seeded path still byte-for-byte (`p13_iter2_audit_test.dart:249-273`) |
| Iteration-2 test-stage finding retirement | **done** | Every `skip:` in the feature is now `skip: false` with a "fixed" note; the only `skip: true` left under `test/features/pocket_money/` is pre-existing P12 (`p12_bugs_test.dart:320`) |

## New findings (iteration 3) — minor only

1. **MINOR — the toggle hit-slop test taps inside the track, not outside
   it.** `payout_responsive_test.dart:314-344` ("a tap outside the toggle
   pill but inside its target lands") taps at `pill.top + 2`. While main's
   old `NestToggle` laid out a 59×44 box, `top + 2` was outside the painted
   31 px track; after batch5, `tester.getRect(find.byType(NestToggle))`
   **is** the 51×31 track, so `top + 2` is 2 px *inside* it — the test
   passes without exercising the hit-slop overhang its name and comment
   claim. Not a product defect (the overhang itself is covered on main by
   `shared_batch5_test.dart:107` "a tap 4 px outside the track still
   toggles", and the sibling assertion now honestly pins the track rect to
   51×31). Fix: tap at `pill.top - 5` (5 px above the track, inside the
   6.5 px overhang) so the P13-level test tests what it says.

## Carried from iteration 2 — still open, still minor (unchanged)

2. **MINOR — `_lastFailure` re-arm block has an unreachable branch.**
   `payout_view.dart:51, 210-214`: the failure listener always clears
   `_submitted` when it toasts (`:86-89`), and the only writer of
   `_submitted` also nulls `_lastFailure` (`:239-240`), so the
   `error != _lastFailure` comparison can never be false and
   `:213 _submitted.clear()` can never run. The reachable half (same-frame
   re-entry drop) is correct and tested; the rest is belt-and-braces that
   reads as load-bearing. Fix: delete the block, or comment it as
   defensive-only.
3. **MINOR — no `performAction` test for the scrim's dismiss node.**
   `'Close payout'` is asserted for `hasAction(SemanticsAction.tap)`
   (`payout_view_test.dart:556-561`) and dismissed by physical `tapAt`
   (`p13_bugs_test.dart`), but nothing calls
   `performAction(SemanticsAction.tap)` on the node — the exact path
   VoiceOver/TalkBack uses (the ACCESSIBILITY ACTIONS rule's second half).
   The node is wired correctly (`payout_view.dart:337-341`); coverage gap
   only. Fix: three lines — `performAction` on the node, settle, assert
   `currentPath == '/money'`.
4. **MINOR — stale narrative comment in the BUG-01 regression test.**
   `p13_bugs_test.dart:317-318`: "the sheet has no in-flight state — the
   CTA stays enabled and looks untouched" describes the pre-fix behaviour in
   the present tense, directly above assertions that now pass *because* the
   CTA is `loading:` and inert. Fix: reword to past tense.

## Out-of-scope observations (NOT findings — for the orchestrator)

A. **`test/core/family_time_test.dart:319` remains red after 20:00 UTC** —
   the main-side, wall-clock flake documented in SHARED_REQUEST #2 (filed by
   the iteration-2 test stage; mechanism independently confirmed by this
   reviewer in iteration 2: Dubai's day rolls over at 20:00 UTC, the seeded
   3-Oct `q-plants` row leaves the period, `completeQuest` inserts a second
   row, `leoRows.single` throws). The whole-repo gate is red for every
   screen loop after 20:00 UTC until the orchestrator lands a fix; P13's
   diff touches none of the involved files (all verified byte-identical to
   the merge-base by the iteration-3 integrate stage).
B. **Concurrent scratch files** (above) — stage 3 and stage 6 iteration-3
   sessions are live in this worktree. Their files are untracked, excluded
   from this review's verdict, and every gate failure I observed maps to
   them alone.
C. **Drift "multiple databases" debug warning** — benign, from
   `setUpTestScope` constructing a second `AppDatabase` on a different
   executor (`test_scope.dart:24`); pre-existing, informational.

## Checked and found correct (no action)

- **Iteration-3 patches.** `textAlign: TextAlign.start` is behaviour-neutral
  beyond the intended fix (it is the platform default, now explicit and
  commented); the `label()` gate's only other caller-visible change is the
  added optional `childId` (`payout_sheet.dart:455`), and the seeded render
  is asserted byte-for-byte. Both patches are inside the allow-list, token-
  and component-clean, and introduce no new strings except none at all.
- **Shared toggle adoption.** P13's call site is unchanged; the new
  `_ToggleHitSlop` render object forwards clamped hits so the
  `GestureDetector` arena still tracks the real pointer; semantics stay on
  the wrapper (`label`, `toggled`, `onTap`) — the toggle remains
  VoiceOver-operable (asserted in `shared_batch5_test.dart:136` and by the
  P13 semantics tests).
- **Architecture / RULES §1.** No new domain/data edits this iteration;
  route/DI untouched; no `core/`, `app/`, other-feature or
  `tools/screens/**` paths in the diff.
- **Design system / tokens.** No literal colours/sizes/fonts introduced;
  the two patches add no metrics at all; no `google_fonts`; no
  `letterSpacing`; `NestBalancedText` correctly absent.
- **Copy.** Seeded saverow byte-for-byte (`P13-payout.html:29`, ASCII 0x27);
  the neutral fallback triggers only off the seeded shape and is covered by
  three tests; summary string unchanged, only its alignment.
- **Accessibility.** Scrim/title/header semantics unchanged from the
  iteration-2 PASS state; busy CTA exposes no tap action (audit-tested);
  disabled CTA reports `enabled: false`.
- **Performance / error handling / Children's Code.** Unchanged from the
  iteration-2 PASS state: no timers or owned streams, `buildWhen` narrowing,
  stream-proof success, friendly retry, no analytics/ads, kid-mode guard at
  `/payout` intact.
- **Test hygiene.** No P13 skips; the one P12 skip is pre-existing; the
  audit file is independent (fixture + gated repos) and well-isolated via
  `setUpTestScope`'s GetIt reset.

## Verdict

No blocker and no major findings. One new minor (mis-measuring toggle
hit-slop test) plus three carried minors (unreachable re-arm branch, missing
scrim `performAction` test, stale BUG-01 comment). Both 5_ui deviations and
the BUG-06/I2-01 pronoun defect are fixed and pinned; all iteration-1/2
findings remain fixed; the committed feature suite, `analyze` and `format`
are green once the two untracked concurrent-scratch files are set aside.

VERDICT: PASS