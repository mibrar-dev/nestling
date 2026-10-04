# P16 · Family & settings — Stage 6 adversarial bug hunt (iteration 1)

Route `/settings` · feature `settings` · parent mode · design
`design/html-source/screens/P16-settings.html` + light/dark PNGs
(1170×2532 ÷ 3). This stage changed **nothing** in `app/lib/**`; it added
`app/test/features/settings/p16_bugs_test.dart` (7 skipped open-bug proofs +
13 unskipped regression guards) and this report. No simulator was booted,
installed on, screenshotted or driven. Tests are pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`.

Tree tested: the worktree at `d1eb135` **plus** the concurrently-written
iteration-1 outputs that had landed by the end of the stage
(`settings_navigation_test.dart`, `settings_responsive_test.dart`,
`settings_states_test.dart`, `p16_test_support.dart`, `4_review.md`,
`5_ui.md`). Where a finding overlaps `4_review.md` it is marked; both were
re-verified independently here (B01 by a full-app proof, B06 against the
design PNG at pixel level).

## Result

**7 findings — 3 major, 4 minor.** Every one is pinned by a skipped test in
`p16_bugs_test.dart`; `flutter test … --run-skipped` proves all 7 fail (each
failure message is recorded below). The strongest is **P16-B07**, which the
direct-view widget tests structurally could not see.

| id | severity | finding | failing proof |
|---|---|---|---|
| P16-B07 | **major** | “Delete family account” → Cancel/Delete pops the *settings page* off its branch, not the dialog: GoRouter assertion, route tree destroyed, Delete loses its toast | `[P16-B07] Cancel closes the delete dialog, never the settings page` |
| P16-B01 | **major** | After “Not now”, the time-zone picker drops the device zone row and its “· Current location” marker (ORCHESTRATOR_NOTES violation; = `4_review` finding 1) | `[P16-B01] the picker keeps the device zone after “Not now”` |
| P16-B06 | **major** | Subscription card renders with a 24 px corner where the design pins 16 px (`r-m`; = `4_review` finding 2, verified against the PNG) | `[P16-B06] the subscription card uses the design’s 16 px corner radius` |
| P16-B02 | minor | “Not now” is not session-scoped: leaving `/settings` and returning re-shows the move prompt in the same session | `[P16-B02] “Not now” hides the move prompt for the whole session` |
| P16-B03 | minor | Zone-picker sheet overflows on 320×568 @ 1.3 text scale (36 px, no scroll) | `[P16-B03] the zone picker scrolls instead of overflowing on 320×568 @1.3` |
| P16-B04 | minor | CLOCK rule: 4 `DateTime.now()` calls in feature code (= `4_review` finding 4) | `[P16-B04] feature code never calls DateTime.now()` |
| P16-B05 | minor | A child with exactly 1 coin reads “1 coins” | `[P16-B05] a single coin reads “1 coin”, not “1 coins”` |

## The bugs in detail

### P16-B07 · major · the delete-confirm dialog pops the settings page

**Repro (full app).** Open `/settings` → scroll to Privacy → tap **Delete
family account** → the confirm dialog opens → tap **Cancel** (or **Delete**).
`Navigator.of(context).pop(...)` in both dialog buttons
(`settings_view.dart:338`, `:346`) uses the outer `SettingsView` context,
which resolves to the **shell branch navigator**, while `showDialog` puts the
dialog on the **root navigator**. The button therefore pops `/settings` off
its branch instead of dismissing the dialog:

```
You have popped the last page off of the stack, there are no pages left to show
'package:go_router/src/delegate.dart': Failed assertion: line 178 pos 7:
'currentConfiguration.isNotEmpty'
```

plus `navigator.dart:4128 '!_debugLocked' is not true` while the tree tears
down. Debug: exception + corrupted tree; release: the branch loses its page
and the dialog stays. The **Delete** path additionally never reaches its
toast (`toast=0`). DB rows stay intact (nothing is wiped — the TODO(P16) path
is not the problem; the pop target is).

**Proof:** `[P16-B07]` (skipped). Expected `failure == null`; measured
`failure=Multiple exceptions (2) …`, `dialogOpen=false`.

**Suggested fix:** pop the dialog on the navigator that owns it —
`Navigator.of(context, rootNavigator: true).pop(false / true)` in both
buttons, or capture the `showNestModal` builder's context. Un-skip the proof
after the fix (it then asserts a clean cancel).

### P16-B01 · major · picker loses the device zone after “Not now”

`_ZonePickerList` derives the device zone from `state.pendingZone`
(`zone_picker_sheet.dart:43-52`), which `SettingsMoveDismissed` nulls. After
one “Not now”, the picker no longer leads with “Asia/Dubai · Current location”
even though the device zone still differs from the family zone — a direct
violation of the mandatory ORCHESTRATOR_NOTES wording (“device zone first
when known and ≠ family zone”). `4_review` finding 1 says the same.

**Repro:** device zone Dubai + family London; dismiss the banner; open the
time-zone picker. **Proof:** `[P16-B01]` (skipped) — measured `deviceRows=0`,
expected 1.

**Suggested fix:** keep the device zone in its own
`SettingsState.deviceZoneId` field (populated by the same one-shot read) and
order the picker by that field; `pendingZone` stays the banner-only input.

### P16-B06 · major · subscription card corner radius 24 px vs design 16 px

`settings_view.dart:172` renders the card with `NestCard.standard`
(`NestRadii.allL` = 24). The design pins
`.subcard{border-radius:var(--r-m)}` = **16 px**
(`P16-settings.html:7`, `tokens.css:77`). Independently verified on
`design/screens/light/P16-settings.png`: the subcard’s top-left corner arc
matches r≈48 device px (16 logical), not 72 (24). `4_review` finding 2.

**Proof:** `[P16-B06]` (skipped) — measured `BorderRadius.circular(24.0)`,
expected `16.0`.

**Suggested fix:** render the subcard with `NestRadii.allM` + `cardShadow`
(same construction as `_LockHint`), or add a radius override to `NestCard`
(SHARED_REQUEST — do not change the shared default).

### P16-B02 · minor · “Not now” is not session-scoped

`dismissedZones` lives in the route-scoped `SettingsBloc`; every `/settings`
visit builds a new bloc, so the prompt re-appears while the parent is still in
the same session. ORCHESTRATOR_NOTES: “show exactly once (until confirmed or
dismissed for the session)”.

**Repro/proof:** `[P16-B02]` (skipped) — dismiss in visit A, re-enter; measured
`bannerShown=1`, expected 0.

**Suggested fix:** keep one `SettingsBloc` for the session (e.g. a
`registerLazySingleton`, guarding the one load) or hoist `dismissedZones` into
a session-scoped store.

### P16-B03 · minor · zone picker overflows at 320×568 @ 1.3

The sheet child is a non-scrollable `Column`; with the device row the 7 rows
overflow: `A RenderFlex overflowed by 36 pixels on the bottom.` At 1.0 scale
and on 375×667 / 390×844 it fits; only the small screen at 1.3 is affected.
The home-edge padding is eaten, so on shorter devices rows can sit under the
gesture bar.

**Repro/proof:** `[P16-B03]` (skipped), mini-router at 320×568, 1.3 scale,
device zone Dubai.

**Suggested fix:** wrap the picker rows in a shrink-wrapped scrollable
(`ListView(shrinkWrap: true)`) inside the sheet so the list scrolls when
capped.

### P16-B04 · minor · CLOCK rule — 4 × DateTime.now() in feature code

`settings_view.dart:115` (zone row offset), `zone_picker_sheet.dart:85`
(picker subtitles), `settings_repository_impl.dart:114`, `:125` (write
timestamps). The rule: app code never calls `DateTime.now()`; use
`clock.now()` / `appNowUtc()`. `4_review` finding 4. The expectations in
`settings_view_test.dart` are computed from the same wall clock, so they can
never pin BST vs GMT.

**Proof:** `[P16-B04]` (source scan, skipped) — offenders
`settings_view.dart:115`, `zone_picker_sheet.dart:85`,
`settings_repository_impl.dart:114,125`.

**Suggested fix (after the loop’s main merge):** swap all four to
`appNowUtc()` (`lib/core/data/app_clock.dart` on `main`) and pin the offset
assertions to the Sat 3 Oct 2026 clock.

### P16-B05 · minor · “1 coins”

`_ChildRow` builds `'Pip: ${stage} · ${coins} coins'` unconditionally; a
child with exactly 1 coin reads “1 coins”.

**Proof:** `[P16-B05]` (skipped) — set Leo to 1 coin; measured `singular=0`,
`plural=1`.

**Suggested fix:** `coins == 1 ? '1 coin' : '$coins coins'`.

## Verified clean (13 unskipped guards)

* **Real app loading.** `pumpAppRoute('/settings')` + `runAsync` reaches
  “Family & settings” with no spinner. The bloc’s load does await the
  device-zone read under the hood, and under the *fake* clock only, that
  platform round-trip never fires; that is a harness artefact (the stage-3
  `settleSettings` documents it), **not** a product bug — so no “stuck
  spinner” finding is filed.
* **Deep links / guards.** Kid-mode `/settings` → `/parental-gate`;
  onboarding-incomplete → `/welcome`; aged-out trial → `/paywall`; system
  Back pops a pushed `/settings` to `/today`.
* **Data edges.** `Seed.empty` (Sarah only, no James, Add child present);
  6 children incl. `Maximilian-Alexander`, 9999 / 0 coins, 320 px + 1.3 dark,
  no overflow (aside from B05’s copy).
* **Persistence.** A flipped notification toggle survives a fresh view+bloc
  over the same Drift database.
* **Rapid double taps.** Two same-frame taps on the time-zone row open one
  sheet; on the Maya row push one route; two taps on Delete open one modal.
* **Accessibility.** All 13 controls expose `SemanticsAction.tap`;
  `performAction(tap)` on the toggle flips the real DB row; the picker row
  opens the sheet. (The delete modal’s *behaviour* bug is B07, not a
  semantics gap.)
* **Picker before any dismissal.** Leads with “Asia/Dubai · Current
  location”; raw IANA appears only inside the picker.
* **Timezone.** BST boundary: `Europe/London` 00:30Z 25 Oct 2026 → `GMT+1`,
  01:30Z → `GMT+0`; New York `GMT-4`, Karachi `GMT+5`, Sydney `GMT+11`.
* **Dark mode contrast.** Every P16 text pair (ink/ink2/ink3/leaf/danger on
  paper/surface/surface2/leafTint) clears 4.5:1 in both themes (worst ≈ 5.7).

**Not applicable on P16:** no money arithmetic (subscription copy is static
by plan §(g); coins are integers), no Pip (avatars only), no async
emit-after-close found.

## Cross-stage notes (not P16 screen bugs)

* `settings_navigation_test.dart`’s two red tests are the full-app proof of
  **B07**; they go green with the fix.
* The two stage-3 harness failures seen mid-stage were fixed by that stage
  while this hunt ran (`find.text('About')` never matched the uppercased
  `ABOUT` section label; the `.linkrow` assertion measured the Text’s line box
  instead of the 52 px row). The settings suite is now **+74 ~7 -2**, the two
  reds being B07.
* The UI stage’s subtitle truncation / chevron position is the shared
  `NestListRow` trailing bug (ORCHESTRATOR_NOTES 02:20); not reported here.

## Gates (this worktree, `app/`)

Snapshot taken while the concurrent stage-3 test files were still being
written (their `p16_test_support.dart` was mid-edit at 02:52), so repo-wide
numbers belong to that snapshot; this stage's own file is clean and
self-contained.

```
$ dart format .                    # 0 remaining changes
$ flutter analyze test/features/settings/p16_bugs_test.dart
                                   # No issues found!
$ flutter test test/features/settings/p16_bugs_test.dart
                                   # +13 ~7: all unskipped guards pass
$ flutter test test/features/settings/p16_bugs_test.dart --run-skipped
                                   # +13 -7: the 7 open-bug proofs fail, each
                                   # with the message recorded above
$ flutter test test/features/settings      # (02:50 snapshot)
                                   # +74 ~7 -2 (the 2 reds are B07’s proofs)
$ flutter test                     # (02:50 snapshot) +2455 ~8 -37; the 33
                                   # behind-main failures are the known
                                   # process baseline, the 4 settings reds
                                   # decompose into the 2 B07 proofs + the
                                   # two stage-3 harness failures fixed
                                   # during this run
```

Repo-wide `flutter analyze` at the end of the stage also reported errors in
the stage-3 files that were being edited at that moment
(`p16_test_support.dart`, scratch `zz_probe_test.dart`); those are the
concurrent test stage's in-flight work, not P16 lib code and not this
stage's file.

VERDICT: FAIL
