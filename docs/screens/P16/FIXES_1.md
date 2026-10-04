# Fix list after iteration 1

## From 3_test.md
# P16 Settings — Stage 3 TEST (iteration 1)

Job: prove the Family & settings screen with tests — every bloc path, every
tap, both themes, three widths, two text scales, all four states, and the
accessibility contract. If a test exposed a bug, record it, do not patch the
screen.

**Outcome: FAIL — the suite is green and the bugs it found are pinned, but two
real defects came out of it (P16-T01, P16-T02). Both are skip-marked with their
id so `flutter test` stays green and the loop can iterate; both fail under
`--run-skipped`.**

Numbers: **+38 tests** added (80 → 118 in `test/features/settings`, of which 10
belong to the concurrent stage-6 agent's `p16_bugs_test.dart`), **0 new
failures**, **2 bugs**.

---

## 1. Tests added

`app/test/features/settings/`

| File | Passed | Skipped | What it pins |
|---|---|---|---|
| `settings_repository_test.dart` | 9 | 0 | (unchanged — stage 2a) roster/members order, zone write + validation, `movedToDubai` |
| `settings_bloc_test.dart` | 25 | 0 | **+11** event/state paths (below) |
| `settings_view_test.dart` | 8 | 0 | (unchanged except two expectations) char-exact copy, write-through toggles, move banner, picker, delete modal |
| `p16_test_support.dart` | — | — | shared harness (new): real app at `/settings` on any surface, bundled fonts, faked device zone, DB readers, semantics-tree walkers |
| `settings_navigation_test.dart` | 12 | 2 | **new**: every control's destination |
| `settings_states_test.dart` | 6 | 0 | **new**: loading / failure+retry / empty seed / dark |
| `settings_responsive_test.dart` | 11 | 0 | **new**: 320/390/430 × 1.0/1.3 × light/dark |
| `settings_a11y_test.dart` | 9 | 1 | **new**: labels, tap actions, activation, targets |

### 1.1 Bloc paths added (`settings_bloc_test.dart`, +11)

Every event in `SettingsEvent` now has a path, and the "did not happen" paths
are pinned too:

- all three toggles in one `SettingsNotificationsChanged`;
- an event with **no** fields writes nothing and emits nothing;
- the payout and summary switches round-trip on their own (approvals already
  covered);
- re-picking the zone already stored emits nothing (Equatable dedupe);
- `SettingsMoveConfirmed` with an unreadable device zone is a no-op (no throw,
  no write, no banner);
- `SettingsMoveDismissed` for a zone that is **not** the pending one keeps the
  prompt (guards a real logic edge in `_onMoveDismissed`);
- a dismissal dispatched **before** the load survives the state the load builds;
- a child inserted while the screen is open joins the roster **last**
  (CHILD ORDER ruling, not alphabetical) and starts at Pip stage `Egg`;
- a member invite accepted mid-session re-renders as `active`, member order
  unchanged;
- `gmtOffsetLabel`: half-hour zones (`Asia/Kolkata` `GMT+5:30`,
  `America/St_Johns` ADT `GMT-2:30` / NST `GMT-3:30`) and an unknown id falling
  back to London instead of throwing.

### 1.2 Navigation (`settings_navigation_test.dart`, new)

Pumps the **real app** at `/settings` (router, shell, seeded in-memory Drift)
and drives the actual taps, because a `context.push` pointing at the wrong
place is invisible to a test that pumps `SettingsView` in isolation.
Destinations are asserted with `pushedPath` (what the Navigator renders,
including imperative pushes), never with a pushed screen's title.

| Control | Asserted |
|---|---|
| Maya / Leo row | `/child-profile` (and the declarative location stays `/settings`) |
| Add child | `/add-children` |
| Manage subscription | `/paywall` |
| Download our data, Privacy Notice | `/privacy` |
| Invite co-parent, Help & feedback | toast, **no** navigation |
| Time zone row | bottom sheet (device zone first with its raw IANA id), **no** route |
| picking a zone | writes the DB, closes the sheet, clears the move banner, stays on `/settings` |
| Version row | **no** tap action anywhere in the semantics tree |
| Delete → Cancel / Delete | **[P16-T01]** — see §3 |
| shell | `/settings` sits on the Family tab (exactly one selected tab), tab-bar surface runs to y 844 |

### 1.3 States (`settings_states_test.dart`, new)

Loading (spinner, no rows, then the loaded tree), failure + **Try again**
(a one-shot failing repository proves the error path and that the retry
re-subscribes), `Seed.empty` (parent kept, children dropped, "Add child" alone,
every other section still rendered, lock hint reads the DB kid-gate value),
dark mode (dark `paper`, cards on dark `surface`, whole page scrolls, no
overflow) and the tab-bar bottom edge in both themes.

### 1.4 Responsive (`settings_responsive_test.dart`, new)

320 / 390 / 430 px × text scale 1.0 / 1.3 × light / dark:

- **ALIGNMENT**: the title, every `NestSectionLabel` and every `NestList` /
  `NestCard` share one 20 px gutter and one content width — checked at three
  scroll stops, because the list builds lazily;
- **BOTTOM EDGE**: the bar surface reaches the physical edge (no tinted strip);
- switches stay at the design's 51×31 track at every width;
- no overflow anywhere (`tester.takeException()`), with the bundled fonts
  loaded — the fallback face invents overflows that do not exist on device;
- row copy stays `maxLines: 1` + ellipsis at 320 / 1.3 (the longest strings:
  the member e-mail, the Pip summary, the zone subtitle);
- the lock hint shares the gutter and wraps instead of clipping; the move
  banner shares it and both buttons stay ≥ 44 px; the subscription card keeps
  its 16 px inset and the `.linkrow` 52 px row (measured on the row, not on its
  15 px label); the title keeps the `.ptitle` metrics (28/34, w900,
  letterSpacing 0).

### 1.5 Accessibility (`settings_a11y_test.dart`, new)

- all 15 controls announce themselves and expose `SemanticsAction.tap` (labels
  are matched as **substrings**: Flutter announces one node per gesture
  boundary, so a row's node carries title + subtitle + chevron);
- the only unlabelled tappable nodes on the screen are the three switch tracks,
  and each one sits exactly on a `NestToggle` rect — so a new unlabelled or
  icon-only control fails (this is the "semantics labels on icon buttons"
  guard);
- every non-switch control is ≥ 44 px tall (parent rule);
- a switch flips the Drift row on its own track, twice (tap / untap), and the
  widget follows the stream;
- **[P16-T02]** the 44 px switch target — skip-marked, see §3;
- semantics activation drives the **real** state: `p16ActivateSemantics` acts on
  the inspected node and then reads the database (`notifApprovals` flips), the
  Maya row navigates to `/child-profile`, the banner's Switch stores
  `Asia/Dubai` and clears the banner, a picker row announces its short label +
  raw IANA id and writes `Asia/Karachi`, and the delete confirm exposes both
  buttons as ≥ 44 px targets.

---

## 2. Results

```
$ dart format .
Formatted 495 files (0 changed) in 2.06 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.9s)

$ flutter test test/features/settings
00:11 +93 ~10: All tests passed!

$ flutter test --run-skipped test/features/settings/settings_navigation_test.dart \
    test/features/settings/settings_a11y_test.dart
00:07 +21 -3: Some tests failed.        # exactly the three bug proofs below
```

Full suite, with and without this stage's files:

| tree | `flutter test` |
|---|---|
| this worktree **without** the five new test files | `01:17 +2437 ~8 -35` |
| this worktree **with** them | `02:26 +2475 ~11 -35` |

The 35 failing blocks are a **byte-identical set** in both runs
(`diff` of the two failure lists is empty) and none is in
`test/features/settings`: `kid_home/kid_home_view_test.dart` (20),
`kid_home/k03_bugs_test.dart` (8), `approvals/approvals_view_states_test.dart`
(3), `approvals/approvals_view_test.dart` (1), `today/p08_bugs_test.dart` (2),
`core/family_time_test.dart` (1) — the branch is 36 commits behind `main`
(the merge-order process item the orchestrator rules exclude; stage 2 measured
the same set). **Net effect of this stage: +38 passing, +3 skipped, 0 new
failures.**

The `~11` includes 7 skip-marked proofs from `p16_bugs_test.dart`, written by
the stage-6 agent that shares this worktree (see §6), and 3 of mine.

---

## 3. Bugs found

Both were exposed by a test; **neither the screen nor any shared file was
patched**, per the stage brief. Each proof is committed skip-marked with its id
(following the convention already used by `p16_bugs_test.dart` and P08/P14), so
`flutter test` stays green and the bug stays reproducible with
`flutter test test/features/settings --run-skipped`.

### P16-T01 — the delete-confirm buttons pop the wrong navigator (**blocker for the destructive action**)

`app/lib/features/settings/presentation/views/settings_view.dart:338` and
`:346`

```dart
onPressed: () => Navigator.of(context).pop(false),   // Cancel
onPressed: () => Navigator.of(context).pop(true),    // Delete
```

`context` is `_SettingsLoaded`'s build context. `showNestModal`
(`core/design_system/components/nest_modal.dart:59`) calls `showDialog` with
the default `useRootNavigator: true`, so the `Dialog` lives on the **root**
navigator — while `Navigator.of(context)` from inside `/settings` resolves to
the go_router **shell's** `CustomNavigator`. The pop therefore removes
`/settings` from the shell instead of closing the dialog.

**Repro** (real app; `settings_navigation_test.dart`, `--run-skipped`):

1. `pumpSettingsApp(tester)` — real app at `/settings`, `Seed.demo()`.
2. scroll to "Delete family account", tap it → the modal opens correctly.
3. tap **Cancel** (or **Delete**).

Observed:

```
You have popped the last page off of the stack, there are no pages left to show
'package:go_router/src/delegate.dart':
Failed assertion: line 178 pos 7: 'currentConfiguration.isNotEmpty'
   #5 _CustomNavigatorState._handlePopPage (go_router/src/builder.dart:452)
   #7 _SettingsLoaded._confirmDelete.<anonymous closure> (settings_view.dart:338)
```

i.e. on device the destructive-action confirm crashes the route (red screen in
debug) and the modal is never dismissed; `await showNestModal<bool>` never
returns, so neither the toast nor any navigation can happen.

**Why the existing test missed it.** `settings_view_test.dart` pumps
`SettingsView` as a `MaterialApp` home, where the view's nearest navigator *is*
the root navigator the dialog uses — the pop lands on the right route there.
Only a real app at `/settings` (inside `StatefulShellRoute.indexedStack`)
exposes it. This is why the new tests drive the real route.

**Fix** (screen-local, presentation is mine): dismiss through the dialog's own
context — wrap the two buttons in a `Builder` and pop that context's
navigator — or `Navigator.of(context, rootNavigator: true).pop(...)`.
Contrast the picker, which gets it right: `zone_picker_sheet.dart:94` pops with
the **sheet row's** context.

### P16-T02 — the three switches' effective tap target is ~36 px, not 44 px (**major**, owner rule)

`app/lib/features/settings/presentation/views/settings_view.dart:237`, `:248`,
`:258` (a `NestToggle` in the shared `NestListRow`),
`app/lib/core/design_system/components/nest_list_row.dart:53`
(`padding: EdgeInsets.fromLTRB(12, 10, 16, 10)`)

`NestToggle` deliberately lays out at the design's 51×31 track and extends its
hit area 4 px left/right and 6.5 px above/below via `_ToggleHitSlop` (shared
batch 5: "51×31 track, 44 hit via slop"). On P16 that slop never reaches the
pointer: the toggle sits inside the row's 10 px vertical padding, so its
nearest ancestor box is a 36 px content box, and a padded ancestor forwards no
hit outside its own box.

**Measured** on `/settings` (Notifications section, 390×844):

| tap | track.top − 12 / −9 / −7 / −6 / −5 / −2 / 0 |
|---|---|
| flips the switch | ✗ ✗ ✗ ✗ ✗ ✓ ✓ |

→ live range `track.top − 2 … track.bottom + 2`, i.e. **≈ 36 px**, against the
owner rule's 44 px. A `hitTestInView` path at `track.top − 5` contains no
toggle render object at all (the row's `InkWell` takes it), while at
`track.top − 1` the path contains the toggle's
`DecoratedBox/ConstrainedBox/PointerListener`.

**Fix** (screen-local is enough): render the three switch rows with P16's own
`SettingsRow` at a 6 px vertical padding (content box 44 px → the whole slop is
live, row height still 56). If the orchestrator prefers one fix for every
screen, it belongs in `nest_list_row.dart` — shared, so it needs a
`SHARED_REQUEST`. P14 does not show it because its switch sits in a card whose
vertical slack is far larger than 6.5 px.

---

## 4. Observations (not bugs, for `4_review`)

1. **CLOCK rule.** `settings_view.dart:115` (zone row offset) and
   `zone_picker_sheet.dart:85` (picker row offsets) call `DateTime.now()`;
   `settings_repository_impl.dart:114/125` do too. Same finding as the stage-6
   agent's P16-B04. I removed the wall-clock dependence from the *tests*
   (`settings_view_test.dart` now pins Sat 3 Oct 2026 08:41Z, `GMT+1`), so
   once `appNowUtc()` lands on `main` the expectation is exact rather than
   self-consistent.
2. **The Family list is one announcement.** Its two static rows
   (Sarah, James) have no `Semantics` node of their own, so their text merges
   into the next tappable node: a screen reader announces
   `"Sarah — you / sarah@example.co.uk / James — co-parent / Invited · awaiting
   reply / Invite co-parent"` as **one** button and cannot stop on Sarah alone.
   Every other list on the screen has a tappable row per row, so only the
   Family list is affected. A `Semantics(container: true)` (or a label) on the
   static rows fixes it; the shared `NestListRow` no-`onTap` branch has the same
   shape.
3. **Known shared wart, blast radius pinned.** A control built as
   `Semantics(label:, onTap:) > InkWell` (every `NestListRow`/`SettingsRow`, and
   `NestToggle`'s `GestureDetector`) exposes a second node — here a duplicate
   announcement for tappable rows and an unlabelled one for the three switch
   tracks. Pre-existing on /today and P14 (`rewards_a11y_test.dart` documents
   it), lives in `core/design_system`. `settings_a11y_test.dart` pins the blast
   radius so P16 cannot add another.
4. **Balanced heading: not required here.** `.ptitle`
   (`design/html-source/screens/P16-settings.html:3`) does **not** declare
   `text-wrap: balance` — `.h1` does, in `components.css:29` — so the title is
   a plain `Text` with `NestType.h1`, consistent with the CSS as written.
   `settings_responsive_test.dart` pins its metrics. If the intent was the `.h1`
   treatment, switching to `NestBalancedText` is a one-line change (P12's
   ledger title does the same thing today).
5. **`sarah@example.co.uk` is hard-coded copy** (`settings_view.dart:374`): the
   `members` table has no email column, so DATA-OVER-MOCKS cannot reach it
   without a schema change (shared). Carried from stage 2.
6. **Legacy `items` field.** `SettingsState.items` / `settingsItemsFor` are still
   carried although the rewritten view never renders `items`; a later cleanup
   can drop them once no feature imports `SettingsItem`.

## 5. Harness notes (so the next iteration does not rediscover them)

- **`SettingsBloc` serves the screen from `emit.forEach` over Drift query
  streams.** Under a widget test's fake clock those never fire, so a route-level
  test sits in the loading spinner forever — and `pumpAndSettle` cannot help
  (the spinner animates). `p16_test_support.dart:settleSettings` wraps a real
  250 ms delay in `tester.runAsync`; use it after every pump that must see
  database state.
- **`await bloc.close()` deadlocks inside `testWidgets`** (the bloc awaits
  cancelling live Drift subscriptions, which needs real async). Close with
  `unawaited(bloc.close())` before `disposeApp(tester)` — the existing
  convention in this directory.
- **`SemanticsNode.transform` maps a node into its PARENT's space**, and the
  chain ends in device pixels: `p16NodeRect(tester, node)` walks the ancestors
  and divides by the device pixel ratio so its rects are directly comparable
  with `tester.getRect`. A semantics node also survives off screen, so scroll a
  control into view before measuring it.
- `testWidgets(..., skip: …)` takes a **bool** in this Flutter version (3.47.5)
  — the bug reason goes in a comment above `skip: true`, not in the string.

## 6. Worktree note (not a finding)

The orchestrator started the review / bugs / UI stages for this screen at the
same time as the test stage, so `p16_bugs_test.dart`,
`docs/screens/P16/4_review.md`, `5_ui.md` and `docs/screens/P16/ui/` appeared in
this worktree during this stage. `p16_bugs_test.dart` (10 tests, 7 of them
skip-marked proofs for P16-B01…B05) is the stage-6 agent's file and is counted
in the `+93 ~10` above but was not written or edited here. Its bug ids do not
collide with the `P16-T0x` ids used here.

---


## From 4_review.md
# P16 Settings — QA code review (iteration 1)

Reviewed `git diff main...HEAD` against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, the design system in
`app/lib/core/design_system/`, `docs/DESIGN_SPEC.md` §5 P16 and
`design/html-source/screens/P16-settings.html`.

## Findings

1. **major** — Device zone is dropped from the picker after the banner is
   dismissed. `zone_picker_sheet.dart:48` derives the device zone from
   `state.pendingZone`, which the bloc nulls out on
   `SettingsMoveDismissed` (`settings_bloc.dart`, `_onMoveDismissed`) and
   everywhere the banner is hidden. ORCHESTRATOR_NOTES is mandatory and
   says the picker always shows "the device zone first when it differs".
   Once the user taps "Not now", the device zone loses its first-position
   row and its `· Current location` marker.
   Fix: keep the device zone in its own `SettingsState.deviceZoneId`
   field (populated by the same one-shot read), and have the picker order
   by that field instead of `pendingZone`. The comment at
   `zone_picker_sheet.dart:44-47` already concedes this gap.

2. **major** — Subscription card corner radius deviates from the design.
   `settings_view.dart:172` uses `NestCard.standard`, which decorates with
   `NestRadii.allL` (24 px, `nest_card.dart:34-38`), but the HTML design
   pins `.subcard{border-radius:var(--r-m)}` (16 px, tokens.css:77). Every
   other card on this screen (`NestList`, `_MoveBanner`, `_LockHint`)
   correctly uses 16 px, so the subcard will be visually off.
   Fix: render the subscription card with the same inline surface
   container as `_LockHint` (`color: tokens.surface`, `NestRadii.allM`,
   `tokens.cardShadow`, padding 14/16), or add a radius override to
   `NestCard` via SHARED_REQUEST.

3. **major** — Edit outside the feature's allowed paths.
   `app/test/features/today/today_view_test.dart` was modified
   (lines 522-530). RULES.md §1 allows a screen agent to edit only
   `app/lib/features/settings/**`, `app/test/features/settings/**` and
   `docs/screens/P16/**`. The intent (assert `/settings` via
   `pushedPath` after the placeholder title was replaced) is right, but
   the edit must be orchestrated onto `main` as a shared change.
   Fix: revert the hunk in this branch and file it as a SHARED_REQUEST
   (or ask the orchestrator to apply it); note the repo already has
   `docs/screens/_shared/router_push_test_fix_REPORT.md` covering this
   pattern.

4. **minor** — Orchestrator CLOCK rule deviation. `settings_view.dart:115`
   and `zone_picker_sheet.dart:85` call `DateTime.now().toUtc()`, and the
   widget tests (`settings_view_test.dart:174, 272`) compute expectations
   from real wall-clock time, so the asserted GMT offset changes with the
   season (e.g. London is GMT+1 in October but GMT+0 in January). The
   rule says app code uses `clock.now()` / `appNowUtc()` and tests never
   assert real-wall-clock copy. This mirrors existing shared code
   (`today_bloc.dart:56`, `family_zone_service.dart:94`), so it is a
   repo-wide inconsistency, but P16 should not extend it.
   Fix: inject the "now" (bloc field or `AppSession`-style clock) and use
   it in both the row and the picker; pin test expectations to the
   pinned Sat 3 Oct 2026.

5. **minor** — Legacy `items` state is now dead code. The replaced
   `SettingsView` no longer reads `state.items` (grep confirms no
   consumer), yet `settings_bloc.dart:73` still builds
   `settingsItemsFor(settings)` on every emission and
   `SettingsItem`/`settingsItemsFor` are kept "while the UI builder
   replaces the view" — it has been replaced in this same diff.
   Fix: delete `SettingsState.items`, `settingsItemsFor`, and the
   `items` branch from `SettingsStatus.loaded` handling, or keep them
   only behind an explicit TODO if a consumer is planned.

6. **minor** — Owner row hard-codes `sarah@example.co.uk`
   (`settings_view.dart:374`). Any `role == 'owner'` member renders that
   email regardless of the stored row, so a renamed/deleted Sarah would
   still display it. `SettingsMemberEntry` carries no email.
   Fix: extend the entity/repository to surface the stored email (or a
   generic subtitle such as `Owner`), or drop the hard-coded string to a
   token-driven placeholder.

7. **minor** — Hard-coded dimensions/typography in the new widgets.
   `settings_view.dart:431, 491` use `EdgeInsets.fromLTRB(14, 12, 14, 12)`,
   `height: 52` (line 198), banner text `fontSize: 14` / `height: 20 / 14`
   overrides, and `const SizedBox(height: 2)`; `_MoveBanner`/`_LockHint`
   hand-roll `BoxDecoration` instead of a design-system card. The
   spacing/typography values match tokens where they exist
   (`s3` = 12, `s4` = 16), but 14/52/2 are magic numbers and the hand-rolled
   containers duplicate `NestCard` internals.
   Fix: add the missing steps to `NestSpacing` (or reuse `s3`/`s4`) and
   expose the card shell via the design system rather than copying its
   decoration.

8. **minor** — Double semantics on the subscription manage row.
   `settings_view.dart:188-196` nests `Semantics(button: true, onTap: …)`
   inside an `InkWell(onTap: …)`, which already contributes a button
   semantics node; the composed node can duplicate the tap action for
   assistive tech.
   Fix: put the label on the InkWell's semantic child via a single
   `Semantics` wrapper (or use `MaterialButton`-style built-in labelling)
   and assert one `SemanticsAction.tap` node per control in tests.

## What checked out OK

- Feature-first structure respected inside settings: entities + abstract
  repo in `domain/`, Drift impl in `data/`, BLoC per screen in
  `presentation/bloc/`, DI via `registerSettings` wiring
  `FamilyZoneService` (settings_di.dart).
- Bloc uses a single `emit.forEach` over combined streams; write handlers
  do not emit (state follows the watched streams), matching house pattern
  and preventing re-subscription leaks; `_closeOnError` mirrors the
  P08-B08 leak fix.
- Roster ordering Maya → Leo via creation order; members via insertion
  order; both documented.
- Copy is char-exact vs HTML (em dashes, · separators, `›`, `Family &
  settings`, curly `’` in the banner); IANA ids only appear in the
  picker; kid mode cannot reach the route (parent shell).
- Toggle semantics asserted with `SemanticsAction.tap` performing the
  real DB write; banner Switch/Not now and picker paths covered by
  widget tests.
- No `google_fonts` imports, no analytics/ads, no child data leaks in
  the new code; `NestToggle`/`NestListRow`/`SettingsRow` metrics match
  the shared rows; bottom edge left to `ParentShell`.


## From 5_ui.md
# P16 Settings — 5_ui (iteration 1)

Route `/settings` · parent mode · child maya · seed demo · simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P16/ui/app_light_1.png`, `app_dark_1.png` (absolute OUT path — relative path fails because `shot.sh` cds into `app/` before copying).
Compares: `cmp_light_1.png`, `cmp_dark_1.png`.

Mean diff: light **3.58%**, dark **3.32%**.

Band table (light): 0–105: 1.75 · 105–211: 2.19 · 211–316: 3.86 · 316–422: 3.00 · 422–527: 3.37 · 527–633: 5.95 · 633–738: 4.53 · 738–844: 4.00.
Band table (dark): 0–105: 1.73 · 105–211: 2.17 · 211–316: 3.81 · 316–422: 2.94 · 422–527: 3.26 · 527–633: 5.82 · 633–738: 4.04 · 738–844: 2.77.
(Status-bar band diff is the real OS clock 02:08/02:09 vs design 9:41 — ignored per STATUS BAR rule.)

## Measured Y (logical px, design light vs app light, same script on both)

| Element | Design | App | Δ |
|---|---|---|---|
| Title text top ("Family & settings") | 60.3 | 60.3 | 0 |
| Title text bottom | 86.0 | 85.7 | −0.3 |
| FAMILY label | 116.7–125.7 | 117.7–126.7 | +1.0 |
| Family card top | 137.0 | 139.0 | +2.0 |
| First control title ("Sarah — you") | 152.3–166.3 | 154.3–169.3 | +2.0/+3.0 |
| CHILDREN label | 344.7–353.7 | 347.7–356.7 | +3.0 |
| Children card top | 365.0 | 369.0 | +4.0 |
| SUBSCRIPTION label | 572.3–581.7 | 577.7–586.7 | +5.3 |
| Subcard top | 593.0 | 599.0 | +6.0 |
| Tab bar top | 727.0 | 727.0 | 0 |

Drift grows ~+1–2 px per section below the title. Time-zone section and move banner are correctly absent from the visible viewport (zone = London, no pending move).

## Deviations (P16-owned)

1. Chevron rows truncate subtitles + park chevron mid-card (light + dark). Design: "Pip: Fledgling · 120 coins", "Pip: Hatchling · 45 coins", "Nickname + age band only" in full, chevron glyph at x≈352 (16 px from card right edge). App: "Pip: Fledgling · 120 …", "Pip: Hatchling · 45 …", "Nickname + age b…", chevron at x≈225. Rows without trailing (Sarah, James) are full-width and match design exactly, so the trailing widget is over-wide. Fix: audit `settingsChevron()` intrinsic width and the `SettingsRow`/`NestListRow` main-axis constraints — the text column must flex to fill like the chevron-less rows. Values are identical to the design (120/45 coins from DB), so this is layout, not DATA-OVER-MOCKS.
2. Progressive vertical drift exceeds ±2 px (UI VERDICT RULE). Children card top +4.0, subcard top +6.0, CHILDREN label +3.0, SUBSCRIPTION label +5.3, first-row title bottom +3.0. Fix: audit section rhythm — `NestSectionLabel` box height/line-height vs design 13 px caps, the 24/8 gaps, and row heights — until card tops read 137 / 365 / 593.
3. Family card top +2.0 (boundary of ±2 px tolerance; listed so the next iteration re-measures it after fixing 2).

## Shared observations (not P16-editable, for orchestrator)

4. Money tab icon differs: design = wallet/card glyph (rounded rect, top stripe, short dash); app = banknote glyph (rect, centre circle + side dots). Tab bar is shared shell code — needs a shell-side icon swap if the design is authoritative.
5. Bottom edge complies with the OWNER RULE (overrides design): below the tab bar the app extends the bar surface to the physical edge (white light / #1F1C2E dark, sampled to y=841.7), while the design PNGs show a paper strip + pill. No coloured strip under the bar in either theme.

## What matches

Copy char-exact (—, –, ·, &, ›, £, .co.uk); child order Maya then Leo; avatar colours (S leaf, J sky, M lilac, L peach); plus tiles; leaf-tint Invite tile; green "Manage subscription"; section order; side gutters 20; Family tab active; dark-mode surfaces/text; no Pip on screen (avatars only — PIP rule N/A).


## From 6_bugs.md
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

