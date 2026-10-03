# P15 · Child profile — Stage 4 QA code review (iteration 1)

Scope: `git diff main...HEAD` on branch `screen/P15` (26 files, +2528/−44).
No code was edited by this stage.

Inputs read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/html-source/screens/P15-child-profile.html`
(+ `components.css`/`tokens.css`), `app/lib/core/design_system/**`,
`1_plan.md`, `2_build.md`, `2a_build_logic.md`, `2b_build_ui.md`.
`docs/screens/P15/ORCHESTRATOR_NOTES.md` does not exist.

## What holds up

Gates run in `app/` (no simulator touched — stage 4 must not):

```
$ dart format --output=none --set-exit-if-changed .
Formatted 488 files (0 changed)

$ flutter analyze
No issues found! (ran in 3.6s)

$ flutter test test/features/family/child_profile_bloc_test.dart \
    test/features/family/child_profile_view_test.dart \
    test/features/family/add_children_test.dart \
    test/features/family/p05_bugs_test.dart \
    test/features/today/today_view_test.dart
00:05 +208: All tests passed!
```

- **ARCHITECTURE** — feature-first respected. `ChildProfile` is an Equatable
  entity; `family_repository.dart` gained only an abstract method; one
  `FamilyBloc` extended (no second bloc); `FamilyRepositoryImpl` holds the
  logic; DI and routes unchanged. No cross-feature writes.
- **Design system** — tokens only. Zero `Color(0x…)`, `Colors.*`, raw hex or
  `google_fonts`/`GoogleFonts.*` in the new files. Every type style is a
  `NestType.x()` + `copyWith` screen override that reproduces the CSS exactly
  (`.hero h1` 24/30, `.stat .v` = `kidName` 22/26, `.stat .l` 12/16 w600,
  `.piprow` head 17/24 w800, `.hero .sub` 14/20 ink2). `NestCard`,
  `NestList`/`NestListRow`, `NestProgress`, `NestAvatar`, `NestButton`,
  `NestModal`, `NestEmptyState`, `NestStatusBar`, `showNestToast` all reused.
  No letter-spacing reintroduced (all `NestType` styles default to 0 and
  `copyWith` does not restore Material tracking).
- **Owner rules** — `PipAvatar` renders the child's own Pip from the DB row
  (`_PipCard` → `_pipStyle/_pipSkin/_pipAccessory`, `stage.clamp(1,4)`), no
  `pip_stage_*.svg`. Copy matches the HTML character-for-character
  (U+2013, U+00B7, U+203A, U+00A3 all asserted in
  `child_profile_view_test.dart`). Data over mocks: `4` / `120` / `4`,
  `6 active · 4 daily, 2 weekly`, `£4.20`. Child order is creation order
  (`watchChildren` sorts `createdAt, rowid`; `_selectProfileChild` does not
  re-sort). 20 px gutters on every band, pinned by rect assertions. No chip
  rows on this screen. No `subscription_status` write. Kid mode is redirected
  to `/parental-gate` by the shared router.
- **Streams/perf** — `watchProfile`'s controller cancels both the base
  subscription and the ledger subscription in `onCancel`; `_closeOnError`
  tears the single `emit.forEach` subscription down on failure (P05's
  failure-recovery test stays green). `ChildProfileBody` is stateless over an
  immutable `ChildProfile`, so there is no rebuild storm.
- **BALANCED HEADINGS** — correctly *not* applied: the P15 hero is a bare
  `<h1>` in the HTML, and `components.css:29` puts `text-wrap: balance` on the
  `.h1` **class** (which only P05's `<h1 class="h1">` carries). No finding.
- **Copy caveat already handled** — `On · Maya knows their code` deviates from
  the design's "her" because the schema stores no gender (see finding 8).

## Findings

### 1. BLOCKER — the `?childId=` deep link is ignored, so two entry points open the wrong child's profile

`app/lib/features/family/family_routes.dart:31-40` (builder takes `state` and
never reads it) and `app/lib/features/family/data/family_repository_impl.dart:62-152`
(`_selectProfileChild` resolves only `app_state.activeChildId`).

Two committed screens navigate to `/child-profile` **with** the child id in the
query string:

- `app/lib/features/family/presentation/widgets/kid_card_grid.dart:130-132` —
  the P05 Edit button, whose own comment states the contract: *"the child
  profile is a StatefulShellRoute branch page reached with `go` + `?childId=`"*.
- `app/lib/features/today/presentation/widgets/today_loaded_body.dart:557` —
  the P08 Today kid cards, `?childId=${summary.childId}`.

With the demo seed `activeChildId == 'maya'`, tapping **Edit** on Leo's card in
P05 — or Leo's kid card on P08 Today — opens **Maya's** profile. The screen then
renders Maya's PIN state, coins, owed pocket money, quests-this-week and Pip
under Leo's name. In a children's app this is wrong-child personal data on the
screen, from two independent entry points.

The contract is already asserted on `main`: `add_children_test.dart` (three
places) and `today_view_test.dart:541-544` both assert
`uri.queryParameters['childId'] == 'maya'` after the tap.

`1_plan.md` §(a) planned the selection from the `CHILD` launch flag alone
(`app/lib/app/launch.dart:57-58` does write `activeChildId`, so the flag path
works) and never considered the in-app query parameter. Fix belongs in the
feature, no shared change needed:

1. `family_routes.dart:34` — read `state.uri.queryParameters['childId']` and,
   when non-null and different from the session's active child, call
   `sl<AppSession>().setActiveChild(childId)` before/alongside providing the
   bloc (or pass it into the bloc as a `FamilyChildSelected(childId)` event).
2. `family_repository_impl.dart` — `_selectProfileChild` should prefer an
   explicit requested id over `activeChildId`, falling back to
   `activeChildId`, then the first child in creation order, then `null`.
3. Add the missing proof to `child_profile_view_test.dart`: pump
   `/child-profile?childId=leo` and assert Leo's name, Pip (`bolt · sky · 2`)
   and `£1.50 a week` — the deep link is currently untested, which is why the
   regression landed green.

### 2. MAJOR — `removeChild` leaves a dangling `app_state.activeChildId`, breaking six sibling features

`app/lib/features/family/data/family_repository_impl.dart:304-306`

```dart
Future<void> removeChild(String childId) {
  return (_db.delete(_db.children)..where((c) => c.id.equals(childId))).go();
}
```

P15 is the **first and only** caller of `removeChild`
(`family_bloc.dart:124`), so this screen is what makes the latent bug
reachable. The child row is deleted but `app_state.activeChildId` still points
at the deleted id, and six other repositories resolve the child straight from
that column with a `'maya'` fallback only when it is **NULL** — never when it is
stale:

- `features/kid_home/data/kid_home_repository_impl.dart:41,107`
- `features/kid_home/data/kid_home_repository_impl.dart:70,158` (period counts)
- `features/pocket_money/data/pocket_money_repository_impl.dart:30`
- `features/pip/data/pip_repository_impl.dart:25`
- `features/badges/data/badges_repository_impl.dart:20`
- `features/kid_shop/data/kid_shop_repository_impl.dart:22`
- `features/kid_jar/data/kid_jar_repository_impl.dart:24`

So after a parent removes Maya on P15, the screen itself looks right (finding
1's fallback picks Leo), but every kid screen and the Money ledger then resolve
a child id that no longer exists.

Fix (in scope — `app/lib/features/family/data/**` is editable under RULES §1):
make `removeChild` clear or repoint the active child in the same transaction,
e.g. when `activeChildId == childId` write
`AppStateCompanion(activeChildId: Value(null))`, and cascade-delete the
child's ledger/quest rows so `watchLedger` and the quest counts cannot go
stale either. Then assert it in `child_profile_bloc_test.dart`: after removing
Maya, `db.appState.activeChildId` is not `'maya'`.

### 3. MAJOR — `watchProfile`'s clock is not injectable, so the bloc test is time-bombed

`app/lib/features/family/data/family_repository_impl.dart:96` and `:102`

```dart
DateTime.now().toUtc(),
```

The orchestrator PERIODS ruling says `now` is taken at emission, which this
honours — but every other period-aware repository in the app injects its clock
and defaults it to the seed anchor, precisely so demo assertions stay
date-independent:

`app/lib/features/today/data/today_repository_impl.dart:24-26`
```dart
final DateTime Function() _clock;
static DateTime _defaultClock() =>
    Seed.anchorOverride ?? DateTime.now().toUtc();
```

`test/flutter_test_config.dart` pins `Seed.anchorOverride = DateTime.utc(2026, 10, 3)`
— the **seed** day — while P15 reads the real wall clock. The committed test

```dart
expect(profile.questsThisWeek, 4);   // child_profile_bloc_test.dart:137
```

passes only because the wall clock currently *is* 3 Oct 2026. From 4 Oct 2026
the daily completions fall outside `dayStartUtc(...)`, `questsThisWeek`
becomes 0, and `child_profile_bloc_test.dart` fails — breaking RULES §7 for
this screen the day after it lands. This mechanism was independently confirmed
in the worktree: desynchronising the anchor from `now` makes `questsThisWeek`
return 0 instead of 4.

Fix: give `FamilyRepositoryImpl` an injectable clock and default it the P08
way — `DateTime Function() _clock` defaulting to
`() => Seed.anchorOverride ?? DateTime.now().toUtc()` — then pass `_clock()` at
the emission site. `Seed.anchorOverride` is `null` in production, so the
shipped behaviour is unchanged.

### 4. MINOR — the error listener toasts the load-failure path too, duplicating the raw exception string

`app/lib/features/family/presentation/views/child_profile_view.dart:41-45`

```dart
listenWhen: (previous, current) =>
    current.errorMessage != null &&
    previous.errorMessage != current.errorMessage,
listener: (context, state) => showNestToast(context, state.errorMessage!),
```

`_closeOnError` sets `errorMessage` on the `failure` state as well as on a
remove failure, so a load failure renders `_FailureBody`'s raw
`error.toString()` **and** floats the identical raw string in a snackbar over
it. Conversely, because `errorMessage` is never cleared, a second identical
remove failure is silently swallowed (`previous == current`).

Fix: scope the listener to the non-destructive path —
`current.status == FamilyStatus.loaded && current.errorMessage != null && …` —
and/or clear `errorMessage` in `_onLoadRequested` on a successful emission.

### 5. MINOR — the hero `<h1>` has no `Semantics(header: true)`

`app/lib/features/family/presentation/widgets/child_profile_body.dart:116-124`

Every other heading in the app flags itself as a header for VoiceOver/TalkBack:
`add_children_view.dart:196`, `today_loaded_body.dart:375`,
`money_ledger_view.dart:207`, `paywall_view.dart:106`, `welcome_view.dart:235`,
`create_account_view.dart:95`. P15's screen title — the child's name, the
largest text on the route — does not, so a screen-reader user rotating through
gets no page title.

Fix: wrap the name in `Semantics(header: true, child: Text(...))`.

### 6. MINOR — the hero nickname ellipsizes where the design wraps

`app/lib/features/family/presentation/widgets/child_profile_body.dart:122-123`

`.hero h1` in the HTML carries no `white-space: nowrap`, and
`components.css:43` gives bare `h1` `overflow-wrap: anywhere`, so a long
nickname wraps to a second line and grows the hero card. The Flutter code
hard-caps at `maxLines: 1` + ellipsis. This also pins the hero height to the
164 px asserted in `child_profile_view_test.dart:75`, so the divergence is
baked into the geometry proofs.

Fix: drop `maxLines`/ellipsis (or set `maxLines: 2`) and let the hero grow, as
the CSS does. If a stable card height is preferred, that is a deliberate
deviation worth a comment.

### 7. MINOR — `size: 84` is a bare literal

`app/lib/features/family/presentation/widgets/child_profile_body.dart:269`

`.piprow img { width: 84px; height: 84px }` is off the 4 pt grid, and unlike
`minHeight: 48` (which carries an explicit precedent note at `:419-421`) this
one has no justification and no token. The orchestrator's precedent for
sub-grid gaps is to add a named token on `main`
(`NestSpacing.gap5/gap6/gap7/gap9/gap10/gap14`), and RULES §1 forbids this
screen from editing `core/design_system/`.

Fix: file `docs/screens/P15/SHARED_REQUEST.md` asking for a
`NestPip.rowSlot = 84` (or equivalent) token and use it at the call site.

### 8. MINOR — PIN subtitle deviates from the design's pronoun

`app/lib/features/family/presentation/widgets/child_profile_copy.dart:77`

Design: `On · Maya knows her code`. App: `On · Maya knows their code`. The
schema stores no gender, so `their` is the right data-driven call and both
`1_plan.md` §(a).4 and the file header document it. Raised only so the
orchestrator is aware the rendered copy is not character-identical to the PNG.

Fix: none required for this screen. If the copy must match the design, that
needs a gender/pronoun field on `children` — a `SHARED_REQUEST` (schema
change), not a P15 edit.

### 9. MINOR — `test/features/today/**` was edited outside the RULES §1 set, with no `SHARED_REQUEST.md`

`app/test/features/today/today_view_test.dart:541-543`

The swap from `find.text('P15 Child profile')` to `find.byKey(Key('p15-hero'))`
is correct and minimal, and it was unavoidable once the placeholder title was
removed — but RULES §1 restricts this screen to
`app/test/features/family/**` and §2 requires shared work to be requested in
`docs/screens/P15/SHARED_REQUEST.md` (none was filed). The orchestrator's
PROCESS ITEMS rule covers uncommitted work, being behind `main` and merge
order — not cross-feature edits.

Fix: add `docs/screens/P15/SHARED_REQUEST.md` recording the `today_view_test.dart`
anchor swap so the orchestrator ratifies the cross-feature change. No code
change.

### 10. MINOR — no view tests for the loading / failure / toast paths

`app/test/features/family/child_profile_view_test.dart`

`initial`/`loading`, `_FailureBody` + `Try again`, and the remove-failure toast
have no view proofs (P05 has a failure-recovery test; P15 has none). The
`errorMessage` field is covered at the bloc level only.

Fix: three small tests — pump `/child-profile` with a `Stream.error` repo for
the failure body + retry, assert `CircularProgressIndicator` during loading,
and assert the toast appears on a failing `removeChild`.

## Notes for the next stages (not findings)

- **Untracked scratch files.** `app/test/features/family/probe_test.dart` and
  `p15_probe_test.dart` are untracked, self-described as *"NOT the deliverable
  — deleted after use"*, written at 18:09 — four minutes **after**
  `.start_review`, so they are another stage's in-flight work, not part of this
  diff, and per the PROCESS ITEMS rule they are not reported as a finding.
  Their 5 red probes must not be committed; `flutter test` is green (208/208)
  without them. Two of them independently corroborate findings 1 and 2.
- **BOTTOM EDGE / tab bar** are owned by the shared `ParentShell` +
  `NestTabBar` (`app/lib/app/router.dart:25-46`) and are not P15's to edit. If
  the 5_ui stage sees a coloured strip under the tab bar or around the home
  indicator, it is a `SHARED_REQUEST`, not a fix here.
- **`IntrinsicHeight`** on the three stat tiles
  (`child_profile_body.dart:169-185`) buys the CSS-grid equal-height behaviour
  at the cost of one extra layout pass. Negligible at three children; recorded
  so it is a conscious choice.
- 5_ui still owes the `shot.sh` + `compare.py` pass (light and dark) with the
  measured y of the screen title, first control and each card top against the
  design, per the UI VERDICT RULE.

VERDICT: FAIL