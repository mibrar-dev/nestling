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

VERDICT: FAIL