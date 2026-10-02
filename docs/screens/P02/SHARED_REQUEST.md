# Shared requests — P02 value tour

## 1. Compact nav-bar wide action — DONE (landed in batch 1, adopted)

The shared compact trailing slot is now content-sized with a 44 minimum, so
P02 retires its feature-private `_TourNav` and uses `NestNavBar(compact:
true, actionLabel: 'Skip', onAction: …)` plus an 8px outer pad that keeps
Skip on the 20px owner gutter (design nav inset is 12px).

Files: was `app/lib/core/design_system/components/nest_nav_bar.dart`.

Blocks: no.

## 2. Compact preview-row variant — WITHDRAWN (solved locally)

The P02-only `ValueTourPreviewRow` now covers the `.pv-row` metrics
permanently (38dp rows composed from shared `NestIcon`/`NestCoinPill`/tokens,
plus a `FittedBox(scaleDown)` title slot so design names render in full at
390dp under any font rendering — ORCHESTRATOR_NOTES 3). No shared change is
needed for this screen anymore; keeping this note only as provenance. A
shared compact-row variant remains desirable for the design system in general
but nothing on P02 blocks on it.

Files: none (was: `app/lib/core/design_system/components/nest_list_row.dart`).

Blocks: no.

## 3. Design tokens for the pager metrics — DONE (landed in batch 1, adopted)

`NestPager` (`stage` 52, `pet` 158, `lineMinHeight` 32, `addDashWidth` 1.5,
`addDashLength` 6, `addDashGap` 4, `addMinHeight` 44) covers every pager
metric; P02's private consts are retired except the 40px stage-dot art
(which has no token).

Files: was `app/lib/core/design_system/tokens/spacing.dart`.

Blocks: no.

## 4. Shared push/pop contract expects the P02 placeholder title

Need: `app/test/app/router_push_test.dart` (`push /value-tour from /welcome,
pop returns`) asserts `find.text('P02 Value tour')` after pushing
`/value-tour`. That literal only exists on main's placeholder
(`AppBar(title: 'P02 Value tour')`); on screen/P02 the screen is fully
implemented per the design, so the assertion fails. Suggested: expect real
copy for the implemented screen (e.g. `'Set quests in seconds'`), as the
same file already does for P01 (`showsFrom: 'Chores that feel like a
game.'`).

Files: `app/test/app/router_push_test.dart:91` (`showsTo`).

Blocks: yes — `flutter test` (full) cannot go all-green on this branch until
the shared expectation is updated; the screen code itself is complete
(RULES §1 keeps `test/app/` outside screen scope, and no design text may be
added to the view to satisfy a test).

Stage 3 (test) confirmation, iteration 3: still red, independently
reproduced. `flutter test test/app/router_push_test.dart` fails at
`router_push_test.dart:46` via `showsTo` (`:91`) with
`Expected: true / Actual: <false>`; the other three cases in that file pass.
`grep -rn "P02 Value tour" lib/features/onboarding/` matches only a doc
comment, so no rendered string can satisfy it. Feature suite is unaffected:
`flutter test test/features/onboarding` → 135 passed / 0 failed, and the full
suite is 612 passed / 1 failed (only this case). Fix stays one line: expect
real copy (`showsTo: 'Set quests in seconds'`), as the same file already does
for P01's `showsFrom`.
