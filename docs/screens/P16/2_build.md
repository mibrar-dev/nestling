# P16 Settings — Stage 2 INTEGRATE (iteration 1)

Job: make the two parallel halves (`2a_build_logic.md` + `2b_build_ui.md`)
compile and pass together. Smallest change, no redesign.

**Outcome: PASS. One integration breakage existed, it was fixed, and the
combination is green on current `main`.**

## Summary of the two halves

**2a — logic (`domain` / `data` / `bloc` / DI).** Additive contract, nothing
removed or renamed:

1. `SettingsChildEntry` / `SettingsMemberEntry` entities; `settingsPipStageName`
   (`1 Egg` … `4 Songbird`); `SettingsMemberEntry(id,name,role,inviteStatus)`.
2. `SettingsRepository` += `watchRoster()` (creation order — Maya then Leo,
   never alpha) + `watchMembers()` (`rowid` = insertion order — Sarah then
   James), read straight off Drift in `SettingsRepositoryImpl`.
3. `SettingsState` += `settings`, `familyRoster`, `memberRows`, `familyZoneId`
   (default `Europe/London`), `pendingZone`, `dismissedZones`,
   `clearPendingZone`. `copyWith` is the only way to null the banner.
4. `SettingsEvent` += `SettingsNotificationsChanged({approvals,payout,summary})`,
   `SettingsTimeZonePicked(zoneId)`, `SettingsMoveConfirmed()`,
   `SettingsMoveDismissed(zone)`.
5. `SettingsBloc({repository, zoneService})` — one `emit.forEach` over
   `combineLatest3(watchSettings+watchFamilyZone, watchRoster+watchMembers,
   _watchPendingMove)`, house `_closeOnError` so "Try again" does not leak
   watchers. Write handlers never emit (streams re-emit); only
   `SettingsMoveDismissed` emits, because no stream backs it. Exports
   `gmtOffsetLabel(zoneId, nowUtc)`.
6. 23 tests (`settings_repository_test.dart` 9, `settings_bloc_test.dart` 14).

**2b — UI (`views` + `widgets`).** 8 widget tests.

1. `settings_view.dart` rewritten to the plan/HTML: Family / Children /
   Subscription / Time zone / Notifications / Privacy / About, move banner,
   `.lockhint`, delete-confirm modal, all state-driven.
2. `settings_rows.dart` — `SettingsRow` (a `NestListRow`-metric row for the
   arbitrary 32 px avatar leading slot and the danger title colour shared
   `NestListRow` cannot express) + `settingsChevron` + `settingsAvatarColor`.
3. `zone_picker_sheet.dart` — `openZonePickerSheet` (device zone first with
   `IANA · Current location`, curated list with `IANA · GMT±n`, check on the
   stored zone) + `settingsZoneSummary`.
4. Deleted the unused `settings_placeholder_card.dart`.

The two halves did not collide: 2a's contract is exactly what 2b coded against,
including 2a's documented placement note (the GMT formatter lives in the bloc,
not the widgets file).

## FIXES items

| # | item | status |
|---|---|---|
| 1 | `test/features/today/today_view_test.dart:525` anchored on the deleted placeholder `AppBar('P16 Settings')` — **the only** breakage the merge caused | **DONE** (below) |
| 2 | 2a's `use_null_aware_elements` info on `settings_rows.dart:47` (2b's file) | **GONE** — `flutter analyze` clean; `?lead` is the 3.13 null-aware element syntax |
| 3 | `settings_placeholder_card.dart` deleted but still referenced | **DONE** — 2b removed the only import |
| 4 | Mismatched BLoC states / events between 2a and 2b | **none** — 0 |
| 5 | Imports / renamed members | **none** — 0 |

### FIX 1 — placeholder-title assertion in a P08-owned test

`test/features/today/today_view_test.dart` `avatar opens settings` asserted
`find.text('P16 Settings')` + the path under it. 2b replaced the placeholder
`AppBar` with the real screen (`Family & settings`), so the test failed with
`Found 0 widgets with text "P16 Settings"`. Fixed with the swap already
prescribed by `_shared/router_push_test_fix_REPORT.md` and already used a few
lines above it for P11 (`today_view_test.dart:215-220`):

```dart
expect(pushedPath(tester), '/settings');
```

Two lines became one assertion plus the rationale comment. This asserts the
location the Navigator actually rendered (`GoRouter.state.uri.path`) instead of
markup that only ever existed on the scaffold — the same evidence P11 and the
shared report accept, and screen-independent by construction.

Proved non-vacuous: a negative control (`expect(pushedPath(tester),
'/NEGATIVE-CONTROL')`) fails; restored to `/settings` passes.

This is a cross-feature test edit, which RULES §1 normally forbids. It is the
one exception the stage brief asks for explicitly ("failing tests caused by the
merge of the two halves"), the fix is 2 lines, and P11 set the precedent in
this exact file. `main` has since fixed the neighbouring P15 assertion the same
way; **my hunk and main's hunk 3-way merge cleanly** (`git merge-file`, no
conflict markers), verified below.

### LEFT for the next iteration

1. **Stage 5 (`5_ui`) owns the simulator work.** No simulator was booted,
   installed on, screenshotted or driven in this stage.
2. **CLOCK rule — carry into `5_review`, fix after the `main` merge.**
   2b calls `DateTime.now().toUtc()` twice:
   `presentation/views/settings_view.dart:115` (zone row offset) and
   `presentation/widgets/zone_picker_sheet.dart:85` (picker row offsets). The
   rule is "app code never calls `DateTime.now()`; use `clock.now()` /
   `appNowUtc()`", and `appNowUtc()` **does** exist — in
   `lib/core/data/app_clock.dart` **on `main`** (it also replaced the two
   pre-existing calls in `settings_repository_impl.dart:_write`). It is absent
   from this worktree because the branch is 36 commits behind `main`, so
   importing it here would break `flutter analyze`. Each call is a one-line
   swap to `appNowUtc()` once the loop merges `main`. Related: the
   `time-zone row shows the short label and GMT offset` test computes its
   expectation with the same `DateTime.now()`, so it is self-consistent but
   never pins BST vs GMT — worth pinning while fixing the above.
3. **`sarah@example.co.uk` in `_MemberRow` is hard-coded copy.** The `members`
   table has no email column (`id, familyId, name, role, inviteStatus`), so
   DATA-OVER-MOCKS cannot reach it without a schema change (shared). Noted
   for `5_review`; if it should be DB-driven it is a `SHARED_REQUEST`.
4. Not a finding, recorded so the orchestrator does not re-investigate: the
   `items` legacy field and `settingsItemsFor` are still carried by the state
   and repo although the rewritten view no longer renders `items`. 2a moved the
   body rather than deleting it so the pre-redesign view kept compiling; the
   view is now replaced, so a later cleanup can drop `SettingsItem` if no other
   feature imports it.

## Verification

### Proof that the 33 remaining failures are not mine

`git stash`-free method (the builders' uncommitted work was never at risk):
two throwaway worktrees, `HEAD` (bbaf31f, no builder work) and `main`
(6feb877), full suite in each, both deleted afterwards.

| tree | full suite |
|---|---|
| P16 worktree `HEAD` **before** any builder work | 33 failing blocks |
| P16 worktree **with** 2a + 2b | 34 failing blocks |
| `main` (current, untouched) | `01:16 +2710 ~1: All tests passed!` |
| **`main` + P16's 2a + 2b + this stage's fix** | **`01:29 +2741 ~1: All tests passed!`** |

`+2741 − +2710 = +31` = exactly P16's new settings tests. The 33 failures at
`HEAD` are the branch being 36 commits behind `main` (K03/P11/P08-B11/kid_home
/approvals), i.e. the merge-order process item the orchestrator rules exclude
from findings — they are green on `main`, so the loop's pre-build merge clears
them. **Final state of this worktree: 33 failing blocks, an exact set-match with
the `HEAD` baseline — zero new failures, zero regressions.** Every one of them
is in `test/features/kid_home`, `test/features/approvals`,
`test/features/today/p08_bugs_test.dart` (P08-B11, which does not appear at all
in the `main` or merged logs).

The merged tree was built for real, not assumed: P16's `lib/features/settings`
+ `test/features/settings` copied onto a `main` worktree, P16's hunk in
`today_view_test.dart` merged into main's version with `git merge-file`
(clean), and `main`'s `appNowUtc()` hunk re-applied to
`settings_repository_impl.dart` with `git apply --3way` (clean — 2a never
touched `_write`).

### Gates (this worktree, `app/`)

```
$ dart format .
Formatted 490 files (0 changed) in 2.02 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.7s)

$ flutter test test/features/settings
00:02 +31: All tests passed!

$ flutter test
00:47 +2745 ~1 -33: Some tests failed.
```

The `-33` is the behind-`main` set above, byte-identical to the `HEAD`
baseline. Gates on the merged tree (what the loop's pre-build merge produces):

```
$ dart format .
Formatted 514 files (0 changed) in 2.15 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 9.1s)

$ flutter test
01:29 +2741 ~1: All tests passed!
```

The single `~1` is the pre-existing `p12_bugs_test.dart:320` skip, present on
`main` too — not a P16 test and not introduced here.

## Code changed by this stage

One file, two lines of assertion replaced by one (plus the rationale comment):
`app/test/features/today/today_view_test.dart`. No `lib/**` change, no lint
weakened, no `ignore:` added, no test skipped to go green (`grep "skip: true"
test/` → the one pre-existing P12 hit), no `google_fonts` anywhere in the
feature, no simulator touched.

VERDICT: PASS