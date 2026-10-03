# P11 · Approvals — Stage 2 INTEGRATE (iteration 1)

Job: make the two parallel halves (`2a_build_logic.md` + `2b_build_ui.md`)
compile and pass together. No redesign, no new behaviour.

## Summary of the two halves

**2a — logic (non-UI layer).** CONTRACT CHANGES: none. Events/states are
exactly `1_plan.md` §2 (`ApprovalsApproveRequested`,
`ApprovalsNotYetRequested`, `ApprovalsApproveAllRequested`,
`ApprovalsActionErrorConsumed`; state gains `busyIds` / `approveAllBusy` /
`actionError` + `clearActionError`). Added `Approval.createdAtTz` (entity +
model + repo) for zone-correct day/time labels; the bloc sorts a copy of
`createdAt` descending (newest first) and toggles busy flags around the repo
calls. 18 logic tests (repo 9, bloc 9) + `SHARED_REQUEST.md`. Iteration-2
follow-up inside 2a: `approveAll()` stopped opening with
`await watchItems().first` (a Drift query stream never delivers its first
event under `testWidgets` fake async, so "Approve all" hung in widget tests)
and now runs the same predicate as a one-shot `select().get()`.

**2b — UI (presentation layer).** No `lib/` change was needed; it
re-verified the existing view/widget layer line by line against `1_plan.md`,
the HTML source and both PNGs, then added the proof suites stage 5 needs:
`approvals_view_geometry_test.dart` (NEW, 7 tests — real-font layout anchors
pinned to the design within ±2 px, light + dark) and 5 `SemanticsAction.tap`
tests in `approvals_view_test.dart`. 27 UI tests + 16 card-widget tests. It
found the "uniform vertical shift" trap: pumped **without** the bundled
faces the helper copy wraps to 3 lines and every card slides down 20 px, so
the geometry test loads Inter/Nunito via `FontLoader` and asserts the
2-line banner directly.

**Merge state.** The two halves did not collide: 2b touched only
`presentation/views|widgets` and `test/features/approvals`; 2a touched only
`domain`, `data` and `presentation/bloc`. No mismatched BLoC states/events,
no renamed members, no missing imports. The single cross-half dependency
2a had to fix was `approveAll()` hanging under fake async once 2b's
end-to-end widget tests started driving the CTA.

## FIXES items

### 1. DONE — two `today`-owned tests broken by the placeholder deletion

The only real integration breakage. Both halves passed, but the **full**
suite was red:

```
00:51 +2185 ~1 -2: Some tests failed.
Failing tests:
  test/features/today/p08_bugs_test.dart: [P08-B07] system back from approvals returns to Today
  test/features/today/today_view_test.dart: Review opens approvals
```

Cause (evidence, not guess): at `eed280d` the foundation placeholder was
`Scaffold(appBar: AppBar(title: Text('P11 Approvals')))`. The UI half replaced
it with the real screen (`Waiting for you (N)`, per DESIGN_SPEC §5 P11), so
two P08 tests that anchored on `find.text('P11 Approvals')` to locate the
pushed `/approvals` page now found 0 widgets. Not a P11 defect and not a
routing defect — `currentPath`/`pushedPath` were always `/approvals`.

`docs/screens/_shared/router_push_test_fix_REPORT.md` §"Optional, not
blocking" had already flagged exactly these two files and prescribed the fix:
*"they are equally fragile and would be fixed by the same swap to
`pushedPath`/`currentPath`"* — never assert a placeholder view title, assert
the route path.

Smallest change applied (4 lines + 2 dead lines, tests only, no `lib/`):

| file | change |
|---|---|
| `test/features/today/p08_bugs_test.dart` | `expect(find.text('P11 Approvals')…` + `expect(currentUri(tester, find.text('P11 Approvals')).path, '/approvals')` → `expect(pushedPath(tester), '/approvals')`; deleted the now-unused local `currentUri` helper (its last call site). `GoRouter` stays imported (still used at line ~708) so no `unused_import`. |
| `test/features/today/today_view_test.dart` | same swap in `Review opens approvals`. `_currentUri` kept — 7 other scenarios still use it. |

Both files already `import '../../test_scope.dart';`, where the shared
`pushedPath(tester)` helper lives. No new import, no new test, no skipped
test, no `analysis_options` change. Rationale comment added at both sites.

**Not a weakened test.** `pushedPath` reads `GoRouter.of(context).state.uri`,
which is built from the *full* match list — i.e. what the Navigator actually
renders, including the imperative push — so it still proves both "we are on
`/approvals`" and "the pushed page is the thing on screen". Negative control
run to prove the assertion is live, not vacuous: temporarily changing the
expected path to `/approvalsXX` fails with
`Expected: '/approvalsXX'  Actual: '/approvals'`, then reverted
(0 occurrences of `approvalsXX` in the tree). Both tests pass green.

Filed for the orchestrator in `docs/screens/P11/SHARED_REQUEST.md` (second
section): these two files are P08-owned, so RULES.md §1 does not let P11 own
them — the same 4-line swap must land on `main` (or be accepted from
`screen/P11`) so the `screen/P08` loop does not re-break them. Merge
order/conflict is a process item per the stage rules.

### 2. LEFT — `.qn` quote row has no data source (2b, unchanged)

`quest_completions` has no message/note column, so cards render without the
design's `.qn` line. `SHARED_REQUEST.md` item 1 asks for
`note TEXT DEFAULT ''` + seed values. Non-blocking; correct per
DATA OVER MOCKS (no hard-coded mock quotes). Stage 5 must expect cards 34 px
shorter than the PNG and quote-less card tops at 187/341/495.

### 3. LEFT — stage 5 (`5_ui`) owns the screenshots

Light + dark `shot.sh` for `/approvals` on `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`
and `compare.py`. Expected app positions are tabulated in `2b_build_ui.md`;
the two accepted deltas are the quote-less cards and the +42 px CTA pill
(`NestBottomCta` runs `surface` to the physical edge per the OWNER
bottom-edge rule; the design's own home-indicator strip is paper).
**No simulator was booted, installed on or captured in this stage.**

### 4. LEFT — nothing in the logic or presentation layer

Both halves are complete for their scope; 2a reported nothing outstanding.

## Orchestrator rules re-verified on the merged tree

| rule | check |
|---|---|
| FONTS | `google_fonts` / `GoogleFonts` in `lib/features/approvals` + `test/features/approvals`: **0** hits |
| tokens only | `Color(0x…)` in `lib/features/approvals`: **0** hits (the two `fontSize: 15/14` values are the design CSS's own `.btn` / `.helper` sizes via `copyWith`, asserted by the UI tests) |
| BOTTOM EDGE | `approvals_view.dart` 77–85: `NestBottomCta` paints `surface` to the physical edge and is removed when the inbox empties; asserted (`cta.bottom == screen.bottom`, fill `== tokens.surface`) in the view + geometry tests |
| COPY | helper export is byte-exact (`U+201C`/`U+201D`/em dash `U+2014`); title/CTA are DB-count driven (`Waiting for you (${state.items.length})`) |
| LETTER SPACING | nothing added; `NestType` defaults to 0 (P11 CSS sets none) |
| PIP / CHIP ROWS / BALANCED HEADINGS / TRIAL / STATUS BAR | none apply to this screen (initial avatars only, no chips, no `text-wrap: balance`, no subscription state, status bar is height-only) |
| ACCESSIBILITY ACTIONS | `hasAction(SemanticsAction.tap)` + `performAction(tap)` proven to change real state for back, both row buttons, the CTA and "Try again" (2b) |
| SIMULATORS | none used |

## Gates (run in this worktree, `app/`)

```
$ dart format .
Formatted 464 files (0 changed) in 1.15 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.5s)

$ flutter test test/features/approvals
00:01 +57: All tests passed!

$ flutter test test/features/today/today_view_test.dart test/features/today/p08_bugs_test.dart
00:03 +71: All tests passed!

$ flutter test
00:39 +2187 ~1: All tests passed!
```

The single `~1` (skipped) test is pre-existing and belongs to another
feature: `test/features/pocket_money/p12_bugs_test.dart:320` (`skip: true`).
It was `~1` before any of my edits as well. Nothing was skipped to make this
suite green.

## Result

Combined P11 half compiles, analyzes clean with no issues and no ignores,
and the whole repository suite is green (2187 pass, 1 pre-existing skip,
0 fail). One integration fix applied (tests only); two documented
non-blocking carry-overs handed to stage 5.

VERDICT: PASS