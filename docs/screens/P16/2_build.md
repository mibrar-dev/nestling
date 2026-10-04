# P16 Settings — Stage 2 INTEGRATE (iteration 2)

Job: make the two parallel halves (`2a_build_logic.md` + `2b_build_ui.md`)
compile and pass together. Smallest change, no redesign.

**Outcome: PASS. The halves integrated clean — I changed no product code and no
test.** Both halves' claims reproduced on my first run, so what follows is the
independent verification I ran instead of taking the notes at face value, plus
the FIXES accounting and the items deliberately left open.

This supersedes iteration 1's `2_build.md`, which is kept as an appendix.

## Summary of the two halves

Both halves worked the iteration-1 `FIXES_1.md` list (test stage 2 bugs, review
8 findings, UI 3 deviations, bug hunt 7 bugs) rather than starting from the
plan. `main` was merged in before this build, so `appNowUtc()` and the shared
`list_row_trailing` fix are now available in-tree.

**2a — logic (`domain` / `presentation/bloc` / `settings_di`).**

1. **Added `SettingsState.deviceZoneId`** — the raw device zone, kept
   regardless of dismissal, so the picker can order by it instead of the
   banner-only `pendingZone` (review 1 / B01 logic half).
2. **Added `SettingsSessionStore`** (new file, DI lazy singleton) — "Not now"
   dismissals now outlive the route-scoped bloc, so the ORCHESTRATOR_NOTES
   "exactly once … for the session" rule holds across `/settings` visits
   (B02). The bloc takes an optional store: DI singleton when registered, else
   a fresh one so direct unit constructions stay hermetic.
3. **Removed `SettingsState.items`** (review 5). `SettingsItem` /
   `settingsItemsFor` are deliberately kept — the shared
   `repositories_test` settings group still pins repository `watchItems()`,
   so deleting them would have broken a shared test for no gain.
4. Repository CLOCK proof added (writes stamp `updatedAt` with
   `appNowUtc()`, pinned `2026-10-03 08:41Z`). 37 logic tests.

**2b — UI (`views` / `widgets`).**

1. B07/T01 (blocker) — both delete-confirm buttons now pop the **root**
   navigator, so the dialog no longer pops the settings page.
2. B06 — subscription card renders the design's 16 px radius
   (`tokens.surface` + `NestRadii.allM` + `cardShadow`, key `p16_subcard`)
   instead of `NestCard.standard`'s 24 px.
3. B03 — picker column wrapped in `Flexible` + `SingleChildScrollView`, so it
   shrink-wraps when it fits and scrolls at 320×568 @ 1.3.
4. B05 — `_ChildRow` pluralises (`1 coin` / `N coins`).
5. B04 — both view call sites now read `appNowUtc()`.
6. B01 UI half — picker orders by `state.deviceZoneId`.
7. Review 8 — the "Manage subscription" wrapper uses `excludeSemantics: true`,
   leaving one labelled node with one tap action (and `onTap:` still passed —
   see the ACCESSIBILITY verification below).
8. Vertical drift (UI deviation 2) — section labels render through a local
   `_P16Sect` that measures Inter's natural line height with a one-off
   `TextPainter` instead of `NestSectionLabel`'s pinned 18 px box.
9. 8 widget/nav/a11y/responsive/bug-proof files; suite **+105 ~1**.

## FIXES accounting

### Bugs (6_bugs) and test findings (3_test)

| id | severity | status |
|---|---|---|
| P16-B07 = P16-T01 delete-confirm pops the wrong navigator | blocker | **DONE** (2b) — `rootNavigator: true`; 2 nav proofs un-skipped, green |
| P16-B01 picker loses the device zone after "Not now" | major | **DONE** (2a `deviceZoneId` + 2b picker) — proof un-skipped, green |
| P16-B06 subcard radius 24 vs design 16 | major | **DONE** (2b) |
| P16-B02 "Not now" not session-scoped | minor | **DONE** (2a) — proof un-skipped, green |
| P16-B03 picker overflows 320×568 @ 1.3 | minor | **DONE** (2b) |
| P16-B04 CLOCK rule, 4 × `DateTime.now()` | minor | **DONE** (2b views; repo stamps came from the main merge) |
| P16-B05 "1 coins" | minor | **DONE** (2b) |
| **P16-T02 switch tap target ≈36 px, not 44 px** | **major** | **LEFT — see below** |

### Review findings (4_review)

| # | severity | status |
|---|---|---|
| 1 device zone dropped from picker | major | **DONE** |
| 2 subcard radius | major | **DONE** |
| 3 edit outside allowed paths (`today_view_test.dart`) | major | **LEFT as a shared change — see below** (reverting it turns the branch red; the merge is the delivery) |
| 4 CLOCK rule (app + tests) | minor | **DONE, both halves** — app reads `appNowUtc()`; `settings_view_test.dart:178` builds its expectation from `p16PinnedNowUtc`, not the wall clock |
| 5 dead `state.items` | minor | **DONE** |
| 6 hard-coded `sarah@example.co.uk` | minor | **LEFT — needs a schema change** (`members` has no email column) |
| 7 magic numbers / hand-rolled card shells | minor | **PARTIAL** by 2b's own account — token steps where they exist; the residual 14/52/2 are the design's own CSS metrics. Three local component re-implementations remain, flagged below |
| 8 double semantics on Manage subscription | minor | **DONE** |

### UI deviations (5_ui)

| # | status |
|---|---|
| 1 chevron parked mid-card + truncated subtitles | **DONE** — fixed on `main` by the shared `list_row_trailing` patch; `settings_rows.dart` mirrors the construction |
| 2 progressive vertical drift (children card +4, subcard +6) | **ADDRESSED, needs re-measure** — `_P16Sect` targets the ~2 px/section line-box gap. I cannot confirm this here; stage 5 owns the remeasure |
| 3 Family card top +2.0 | **needs re-measure** (stage 5) |
| shared obs 4 money tab icon | not P16 — shell |
| shared obs 5 bottom edge | already compliant, no action |

## Items left open, and why

1. **P16-T02 (major, owner rule: 44 px tap targets) — genuinely unfixed.**
   The proof is still `skip: true`, as the bug stage created it; 2b declined to
   fake a fix and documented its measurement instead. I verified the skip is
   honest rather than hiding a green test: with `--run-skipped` the proof
   **fails** (`Expected: <false> Actual: <true>` — the DB value does not flip).
   2b's finding is that the fix is not reachable inside `presentation/**`: the
   `_RenderToggleHitSlop` inside `NestToggle` never registers outside its own
   box, and an ancestor `Padding` does not enlarge it, so even the report's
   suggested 6 px row padding leaves `track.top − 5` dead. Filed as shared
   request §1. Not blocking P16 (no false PASS claimed), but it is a real
   accessibility gap.
2. **Review 3 — the cross-feature `today_view_test.dart` hunk.** It stays in
   the branch because reverting it puts `avatar opens settings` straight back
   to red (`Found 0 widgets with text "P16 Settings"`), and this stage's brief
   is that the suite passes. I re-proved the delivery is clean: a 3-way merge
   of my hunk into `main`'s copy of that file (`git merge-file`, base = the
   branch point) produces **no conflict markers**. `main` has not touched those
   two lines, so the loop's merge carries the change. If the orchestrator
   prefers `main` to own it, the identical 2-line swap already landed for
   `/approvals` (`today_view_test.dart:215-220`) is the pattern to apply.
3. **Review 6 — owner email.** `members` = `id, familyId, name, role,
   inviteStatus`; there is no email to read, so the copy cannot be made
   DB-driven without a shared schema change. Shared request §4.
4. **Review 7 — three local re-implementations of shared components**
   (`SettingsRow`, the subcard `Container`, `_P16Sect`). Each is a deliberate
   workaround for a shared default that cannot express the design without
   editing `core/`, which RULES §1 forbids; each has a one-line swap-back once
   the shared component grows the capability. Raised as an integrator flag, not
   a blocker — the same call P11's integrator recorded for
   `ApprovalsBottomCta`. Shared requests §2 and §3 carry the shared half.

## Independent verification (I did not take the notes' word for it)

| claim | how I checked | result |
|---|---|---|
| halves share one contract | 2a's `deviceZoneId` is exactly what 2b's picker reads (`zone_picker_sheet.dart:47`); `items` is gone from state and no view reads it; `SettingsSessionStore` is registered in `settings_di.dart` and passed to the bloc | confirmed |
| B01 really fixed, not test-shaped | picker reads `state.deviceZoneId`, which is populated on every emission regardless of dismissal | confirmed |
| B02 not cross-test leaky | `setUpTestScope` calls `GetIt.instance.reset()` first, so the store singleton is fresh per test | confirmed |
| B04 CLOCK | `grep DateTime.now() lib/features/settings/` → **0 hits**; both call sites read `appNowUtc()` | confirmed |
| review 8 vs the accessibility rule | the single `excludeSemantics: true` site (`settings_view.dart:241`) passes `onTap:` on the next line | confirmed |
| B06 radius | subcard decorates with `tokens.surface` + `NestRadii.allM`; `NestCard` no longer appears in the view | confirmed |
| B07 | both modal buttons use `Navigator.of(context, rootNavigator: true).pop(...)` | confirmed |
| B05 | `_ChildRow` line 454 has the `== 1 ? '1 coin' : 'N coins'` branch | confirmed |
| B03 | picker row column is `Flexible` + `SingleChildScrollView` | confirmed |
| review 4 test half | `settings_view_test.dart:178` builds the expected string from `p16PinnedNowUtc` | confirmed |
| nothing skipped to go green | whole tree has exactly 2 `skip: true`: `settings_a11y_test.dart:264` (P16-T02, present since iteration 1, proven still failing) and `pocket_money/p12_bugs_test.dart:321` (another feature, pre-existing). The builders **un-skipped 7** proofs (`skip: false` ×6 in `p16_bugs_test.dart` + 1 in `settings_navigation_test.dart`) | confirmed |
| bug proofs are live | all 6 `[P16-Bxx]` tests in `p16_bugs_test.dart` are `skip: false`; the file's only other `skip: true` is inside the header comment | confirmed |
| nothing outside the allowed paths | only `app/test/design_system/list_row_trailing_test.dart` escapes `lib/features/settings` + `test/features/settings` + `docs/screens/P16`. Its diff is 3 hunks of pure `dart format` call-joining (`await pumpNest(\n tester,\n …)` → one line) with **no assertion changed** — a side effect of the mandated `dart format .` on a file the branch had left unformatted. Disclosed, not a blocker | confirmed |
| full suite green | `flutter test` → `+2833 ~2`, zero failures | confirmed |

## Gates (this worktree, `app/`)

```
$ dart format .
Formatted 524 files (0 changed) in 2.41 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.7s)

$ flutter test test/features/settings
00:09 +105 ~1: All tests passed!

$ flutter test
01:34 +2833 ~2: All tests passed!
```

The `~2` is the two pre-existing skips above (P16-T02 by design, P12's).
`main` is merged in, so there is no behind-`main` test noise this iteration.

## Code changed by this stage

**None** — no `lib/**` change, no test edit, no lint weakened, no `// ignore:`
added, no test skipped, `analysis_options.yaml` untouched.

One docs-only addition: `docs/screens/P16/SHARED_REQUEST.md`, carrying the four
shared items the builders and the review stage left unwritten (§1 T02 hit slop,
§2 `NestSectionLabel` line box, §3 `NestCard` radius, §4 `members.email`).
RULES §2 names that file as the mechanism for shared work, review 3 asked for
one explicitly, and four "LEFT" items were otherwise going nowhere. It changes
no code and blocks nothing.

## Notes for the next stage

- Stage 5 owns the remeasure of the yard metrics after `_P16Sect` and the
  subcard radius change (UI deviations 2 and 3 are unverified).
- 2b's `2b_build_ui.md` has a stray non-English token in the P16-T02
  paragraph ("never registers **ngoài** its own box"). Left verbatim — it is
  another stage's record, not mine to edit.
- No simulator was booted, installed on, screenshotted or driven in this stage.

---

# Appendix — iteration 1 record (superseded, kept for history)

Two halves built P16 from `1_plan.md`; I fixed one integration breakage and
proved the combination green on `main`:

- **FIX (1):** `test/features/today/today_view_test.dart` asserted the deleted
  placeholder `find.text('P16 Settings')` → replaced with
  `expect(pushedPath(tester), '/settings')` per
  `_shared/router_push_test_fix_REPORT.md`, proved non-vacuous by a negative
  control. This is the hunk review finding 3 now asks to be orchestrated.
- Everything else was left to the test/review/ui/bugs stages, which is where
  `FIXES_1.md` came from.
- Evidence then: `dart format .` 490 files 0 changed · `flutter analyze` → No
  issues found · `flutter test test/features/settings` → 31/31 · merged with
  `main` → `01:29 +2741 ~1: All tests passed!` · the branch's own 33 failures
  were a behind-`main` artifact (0 behind after this iteration's merge).

VERDICT: PASS