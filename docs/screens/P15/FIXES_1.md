# Fix list after iteration 1

## From 3_test.md
# P15 · Child profile — Stage 3 TEST (iteration 1)

Route `/child-profile` · feature `family` · parent mode · designs
`design/screens/{light,dark}/P15-child-profile.png`.
Tree: branch `screen/P15` at `586a9d2` (+ main through `abf2a96`).

Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md`, `2a_build_logic.md`, `2b_build_ui.md`, and
**`docs/screens/P15/ORCHESTRATOR_NOTES.md` (18:15, appeared mid-stage)** —
every item is actioned below. No `SHARED_REQUEST` existed when this stage
started; one is filed now (`docs/screens/P15/SHARED_REQUEST.md`).

**No simulator was booted, installed on, driven or screenshotted** (stage 3
must not). No `flutter clean`. No production file was touched: the diff is
`app/test/features/family/**` plus `docs/screens/P15/**` only.

---

## 1. Tests added

60 new tests: 3 new files (51 tests) + 12 added to the 2 existing P15 files.
All run against the in-memory Drift database (`AppDatabase.memory()` via
`test_scope.dart:setUpTestScope`) seeded with `Seed.demo()` or `Seed.empty()`;
`flutter_test_config.dart` pins the seed anchor to Sat 3 Oct 2026. Every widget
test that pumps the app ends with `disposeApp(tester)` (RULES §7).

### `child_profile_copy_test.dart` — NEW, 20 tests (19 green + 1 red)

The branches the seeded demo never renders, checked character by character
against `design/html-source/screens/P15-child-profile.html`:

* stage names 1–4; `Age 7–9` (U+2013 EN DASH from the DB hyphen) and `Age 13+`
  (no hyphen to convert); no ASCII `-` in the band;
* the growth caption rounds the same fraction the bar is drawn from
  (`175 of 250 · 70%`, `249 of 250 · 100%`), clamping at both ends and
  `evolveAtCoins <= 0` never producing NaN;
* the spoken label takes "an" for stage 1 (`Robin's Pip, an egg`);
* PIN row **off** state (`Off · No code set yet`) — the demo's Maya has a PIN,
  Leo's row is only reachable after a removal;
* the quests subtitle's third clause (`· 1 one-off`) which the demo family
  never triggers;
* money formatting for 0 and odd pence (`£1.55 a week · Owed £0.05`);
* `Change ›` is U+203A and never U+00BB;
* **repository** (real DB): a `once` quest lands in the one-off bucket, an
  unknown repeat rule (`fortnightly`) counts as one-off rather than being
  dropped, another child's quest is not counted, an inactive quest is not
  counted.

### `child_profile_states_test.dart` — NEW, 11 tests (10 green + 1 red)

The three branches `child_profile_view_test.dart` cannot reach, driven
through the **real router + real `ParentShell`** by swapping the repository in
GetIt before the pump (`approvals_view_states_test.dart:_useRepository`
precedent):

* `initial`/`loading`: never-emitting streams keep the spinner up, nothing
  from the loaded tree leaks behind it, token-coloured in dark mode too, and
  the first emission replaces it;
* `failure`: the reason is shown, `Try again` is a ≥44 px control in both
  themes, and tapping it builds a **fresh** subscription (attempt counter
  proves the retry, not a cached stream);
* `Seed.empty()` (RULES §4, the P08b story — onboarded parent, no children):
  the route survives, `No children yet` + its copy render, the CTA is ≥44 px
  and navigates to `/add-children`, and the art is the onboarding Pip
  (mochi · sunny · stage 1) — never a `pip_stage_*.svg`.

### `child_profile_theme_size_test.dart` — NEW, 17 tests (16 green + 1 red)

The size/theme/a11y matrix this stage is required to cover, with the bundled
Inter/Nunito faces loaded (without them Flutter's test font is far wider than
Inter and every paragraph looks ellipsised — the same reason
`child_profile_view_test.dart` loads them):

* **light + dark**: every band fill is `tokens.surface` and never `tokens.ink`,
  the page behind is `tokens.paper`, the type is `ink`/`ink2`/`ink3` — tokens
  only, no literal colours;
* the five measured bands (hero 47/164, stats 227/82, Pip 325/116, list
  457/180, danger 653/80) do not move in dark mode;
* **widths 320 / 390 / 430 × text scale 1.0 / 1.3** (6 cases): no overflow or
  build error, 20 px gutters on every band (OWNER ALIGNMENT), the stat grid
  stays `1fr 1fr 1fr` with a 10 gap at every width, and every control still
  clears the 44 px parent floor;
* the danger card is reachable by scrolling at 320 × 1.3, and the shell clamps
  the scaler (a 2.0 system setting renders exactly like 1.3);
* **accessibility**: every `isImage` node on screen (Pip art, three list-row
  icons, four tab-bar icons) carries a non-empty label in both themes — the
  "icon buttons have labels" contract, checked on the semantics tree itself
  (the `renderViews`-walk idiom from `p14_test_support.dart`);
* rows are kid-grade 60 px tall, the danger button 48;
* `performAction(SemanticsAction.tap)` on the danger row really opens the
  confirm modal, and both modal buttons expose `tap` at ≥44 px;
* ORCHESTRATOR item 1: **no list-row paragraph is ellipsised at 390** — the red
  proof for P15-BUG-5.

### `child_profile_bloc_test.dart` — +7 tests (20 green + 1 red)

* an error on `watchProfile` ALONE is still a failure (P15's stream is a
  separate combine branch, `family_bloc.dart:33-37`);
* a second load after a failure recovers (status → loaded, profile back);
* P05's `FamilyDraftChanged` + `FamilyAddChildRequested` run against the same
  bloc and must leave the P15 profile untouched;
* real DB: `watchProfile` follows an `activeChildId` switch **mid-stream**
  (maya → leo on one subscription);
* real DB: `questsThisWeek` obeys the PERIODS ruling — an in-period approval
  counts, one from three days ago does not, and a `not_yet` never counts;
* real DB: the stale-message proof (P15-BUG-3).

### `child_profile_view_test.dart` — +5 tests (15 green + 2 red)

* `performAction(tap)` on the **PIN** row pushes `/kid-pin` (the money row was
  already covered);
* the `?childId=` deep-link group: `?childId=leo` must show Leo (red),
  tapping Leo on `/today` must land on Leo's profile (red), an agreeing
  `?childId=maya` works (green), an unknown `childId` falls back to the
  roster's first child without crashing (green).

`add_children_test.dart`, `p05_bugs_test.dart`, `p05_view_metrics_test.dart`
were not modified and stay green (135 tests).

---

## 2. Gates (run in `app/`)

```
$ dart format .
Formatted 492 files (0 changed) in 1.32 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.6s)

$ flutter test test/features/family
00:06 +215 ~6 -6: Some tests failed.          # ~6 = stage 6's skipped proofs
```

Per file:

| File | Result |
|---|---|
| `child_profile_bloc_test.dart` | **+20 −1** (red = P15-BUG-3) |
| `child_profile_copy_test.dart` | **+19 −1** (red = P15-BUG-4) |
| `child_profile_states_test.dart` | **+10 −1** (red = P15-BUG-2) |
| `child_profile_theme_size_test.dart` | **+16 −1** (red = P15-BUG-5) |
| `child_profile_view_test.dart` | **+15 −2** (both red = P15-BUG-1) |
| `add_children_test.dart` / `p05_bugs_test.dart` / `p05_view_metrics_test.dart` | +119 / +12 / +4, all green |
| `p15_bugs_test.dart` (stage 6, concurrent) | 6 skipped by its author |

Whole suite:

```
$ flutter test
01:08 +2477 ~7 -6: Some tests failed.
```

All **6 red tests are the bug repros listed below** — they were written to
fail, they were not left failing by accident, and no test was skipped,
deleted or weakened to reach a green run. The 7 `~` skips are pre-existing
(not mine). `flutter analyze` is clean; no `analysis_options.yaml` change; no
`google_fonts` import anywhere in the feature or its tests.

---

## 3. Bugs found

Five bugs, each with an un-skipped red proof. **The screen was not patched**
(stage 3 rule): every fix below belongs to the next build stage.

### P15-BUG-1 — major — the `?childId=` deep link is ignored

`app/lib/features/family/family_routes.dart:31-41` builds `ChildProfileView`
without reading `state.uri`, and
`app/lib/features/family/data/family_repository_impl.dart:156-167`
(`_selectProfileChild`) resolves the selection from
`app_state.active_child_id`, which only the `CHILD` launch flag ever writes
(`app/lib/launch.dart:58` — the sole `setActiveChild` call site).

**Repro (user path).** `/today` → tap **Leo's** kid card
(`today_loaded_body.dart:557` navigates to
`?childId=leo`) → `/child-profile` renders **Maya**: "Maya", "Age 7–9 · Pip is
a Fledgling", "Remove Maya from family". Same for P05's "Edit Leo" pencil
(`kid_card_grid.dart:130`) and for the bare deep link
`/child-profile?childId=leo`. Demo seed `active_child_id` is `'maya'`.

**Proof.** `child_profile_view_test.dart` → group *P15 honours the ?childId
deep link from Today (BUG P15-BUG-1)*, two red tests (direct deep link; the
Today tap end-to-end). **Wrong-child data, including the destructive Remove
action** — that is why it is major.

**Fix direction (P15-local).** Read `state.uri.queryParameters['childId']` in
`childProfileRoute` and persist it through `AppSession.setActiveChild` before
the first `FamilyLoadRequested` (or pass it as the bloc's initial selection);
`_selectProfileChild` already falls back to the first-created child, so no
validation is needed. No P05/P08 change required.

### P15-BUG-2 — minor — a load failure is reported twice

`app/lib/features/family/presentation/views/child_profile_view.dart:41-45`
toasts **any** new `errorMessage`, including the one the load failure itself
sets, while `_FailureBody` (`:93-124`) prints the same string at the same
moment. The parent reads "Exception: offline" from a toast **and** from the
failure block. P12 sets the precedent this deviates from
(`app/lib/features/pocket_money/presentation/views/money_ledger_view.dart:64-67`):
its toast is armed only for `status == loaded`, i.e. for ACTION errors, never
for the failure the body already shows.

**Repro.** `/child-profile` with a repository whose `watchProfile` errors →
two `Text('Exception: offline')` nodes (body + toast).

**Proof.** `child_profile_states_test.dart` → *BUG P15-BUG-2: a load failure is
reported once, not twice* (red: "Found 2 widgets"). The neighbouring tests
that assert the screen's behaviour use `findsWidgets` and say why.

### P15-BUG-3 — minor — a recovered load keeps the dead failure message

`app/lib/features/family/presentation/bloc/family_state.dart:89` uses
`errorMessage ?? this.errorMessage`, so `copyWith` cannot express null (the
sentinel pattern is applied to `nicknameError`, `lastSavedNickname` and
`profile` in the same file but not to `errorMessage`), and
`family_bloc.dart:38-45` (`onData`) never clears it. P12 hit exactly this and
fixed it — `pocket_money_state.dart:48-58` has a `clearErrorMessage` flag
("copyWith cannot express null otherwise", *P06-BUG-06*) and
`pocket_money_bloc.dart:81-86` passes it on **every** successful emission.

**Repro.** Load fails (`Exception: offline`) → `Try again` → status becomes
`loaded` and the profile is back, but `state.errorMessage` is still
`'Exception: offline'`.

**Proof.** `child_profile_bloc_test.dart` → *BUG P15-BUG-3: a recovered load
drops the dead failure message* (red). The green sibling test
("a second load after a failure recovers") uses predicates so it proves
*recovery* and stays independent of the message hygiene.

**Impact.** The view only toasts when `errorMessage` *changes*
(`child_profile_view.dart:41-44`), so the same failure a second time is
silent. Stage 6 proved the same root on the remove path (its P15-BUG-3).

### P15-BUG-4 — minor — a stage-1 Pip reads "Pip is a Egg"

`app/lib/features/family/presentation/widgets/child_profile_copy.dart:48-50`
hard-codes the article: `'Pip is a ${pipStageName(stage)}'`. Stage 1 is the
DEFAULT — `app/lib/core/data/app_database.dart:82`
(`pipStage … withDefault(Constant(1))`) and `addChild`
(`family_repository_impl.dart:262-284`) never overrides it — so **every child
added through P05** renders "Age 7–9 · Pip is a Egg". The same file already
knows the rule for the spoken label (`pipStagePhrase` → "an egg",
`child_profile_copy.dart:119-124`); the visible line simply never had a
stage-1 case.

**Repro.** Add a child on `/add-children` → open their profile → hero sub-line
reads "Pip is a Egg".

**Proof.** `child_profile_copy_test.dart` → *BUG P15-BUG-4: a stage-1 Pip reads
"an Egg"* (red).

### P15-BUG-5 — major (shared) — every list-row subtitle is ellipsised

`app/lib/core/design_system/components/nest_list_row.dart:74` and `:97` lay
the row out as `[tile 40, gap, Expanded(main), gap, Flexible(tail)]`. Flutter
gives each flex child an **equal** share of the free space, so the trailing
reserves half the row however small its text is, and `.list-main` gets half of
what is left. The design's CSS is the opposite
(`design/html-source/components.css:116-119`: `.list-main { flex: 1 }`,
`.list-trail { flex-shrink: 0 }`).

Measured at 390, text scale 1.0, with the bundled faces loaded
(`RenderParagraph.size.width` vs the paragraph's own `TextPainter` width):

| row | main column gets | subtitle needs | cut |
|---|---|---|---|
| Kid PIN | 129.0 px | 171.2 px — `On · Maya knows their code` | **42.2 px, ellipsised** |
| Quests | 129.0 px | 162.1 px — `6 active · 4 daily, 2 weekly` | **33.1 px, ellipsised** |
| Pocket money | 129.0 px | 169.2 px — `£3.00 a week · Owed £4.20` | **40.2 px, ellipsised** |
| PIN trailing `Change ›` | 129.0 px reserved | 70.7 px intrinsic | 58.3 px wasted |

The design would give `.list-main` ≈187 px, which fits every subtitle. The
same sweep at the other widths/scales (all with `didExceedMaxLines == true`):

| width / scale | main column | PIN sub cut | Quests sub cut | Money sub cut | title cut |
|---|---|---|---|---|---|
| 320 × 1.0 | 94.0 px | 77.2 px | 68.1 px | 75.2 px | `Pocket money` −15.7 px |
| 320 × 1.3 | 94.0 px | 77.2 px | 68.1 px | 75.2 px | `Pocket money` −15.7 px |
| 390 × 1.0 | 129.0 px | 42.2 px | 33.1 px | 40.2 px | — |
| 390 × 1.3 | 129.0 px | 42.2 px | 33.1 px | 40.2 px | `Pocket money` −19.3 px |
| 430 × 1.0 | 149.0 px | 22.2 px | 13.1 px | 20.2 px | — |
| 430 × 1.3 | 149.0 px | 22.2 px | 13.1 px | 20.2 px | — |

So all three subtitles are truncated on **every** width and both permitted
scales (13–77 px of the design's copy never renders), and the row *title* is
truncated too at 320 (and at 390 × 1.3).

**Repro.** `/child-profile` at 390 → the three subtitles are cut (the PIN one
reads "On · Maya knows thei…").

**Proof.** `child_profile_theme_size_test.dart` → *no list-row paragraph is
ellipsised at 390* (red; `RenderParagraph.didExceedMaxLines == true`), which is
exactly the check ORCHESTRATOR item 1 asked for.

**Ownership.** The fix is in `core/design_system/**`, which RULES §1 forbids
this screen from editing → filed as `SHARED_REQUEST.md` §1 (one line: take the
trailing out of the flex distribution). It is major because it truncates copy
on every width, and it also explains most of the UI stage's 1.21 % drift.

---

## 4. ORCHESTRATOR_NOTES.md (18:15) — every item actioned

1. **Subtitles in full, trailing takes only its intrinsic width.** Tested at
   390 — RED. That is P15-BUG-5 above; the one-line shared fix is requested in
   `SHARED_REQUEST.md` §1. The trailing-width half of the assertion
   (`Change ›` == its intrinsic 70.71 px) passes; only the starved main column
   fails.
2. **Row icons.** Confirmed by measurement, not by eye: the Quests row passes
   `leadingAsset: NestIcons.check` (`child_profile_body.dart:375`) — a bare
   tick, while the design draws circle (r 9) + check — and the Pocket money
   row passes `NestIcons.poundCoin` (`:387`), a tinted line £ in a circle,
   while the design uses the coloured `assets/illustrations/coin.svg`. No
   combined check-circle asset exists in `NestIcons`, so per the note's own
   instruction the asset + a `NestListRow` escape hatch are requested in
   `SHARED_REQUEST.md` §2 (with the design's SVG inline). No test can express
   this yet — the constant does not exist — which is why it is a request
   rather than a red proof.
3. **Pronoun "their"** — kept; not a finding (per the note).
4. **DB quest counts** — not findings (per the note).

`5_ui.md` independently FAILed on the same item 1 and the same two icon
deviations; its band measurements (±2 px) are consistent with the geometry
assertions in `child_profile_view_test.dart`.

---

## 5. Checked and found sound

* `Seed.empty()` → empty state, copy, CTA, `/add-children` navigation, and the
  onboarding Pip (mochi · sunny · stage 1) — no `pip_stage_*.svg` anywhere.
* Maya → Leo → empty selection fall-through after removals, in ADDED order
  (CHILD ORDER ruling), each with **its own** Pip (bolt · sky · stage 2).
* Every tap target: rows 60 (≥ the 56 kid floor), danger 48, modal buttons 48,
  empty CTA ≥44 — in both themes and at text scale 1.3.
* Every interactive node exposes `SemanticsAction.tap`, is a button, and
  `performAction(tap)` drives the real navigation / the real modal / the real
  `FamilyRemoveChildRequested` → DB write.
* Copy is character-exact against the HTML source, including U+2013, U+00B7,
  U+203A and U+00A3; no ASCII `-` in the age band; no `google_fonts`;
  `NestType` letterSpacing untouched.
* No overflow at 320 / 390 / 430 × 1.0 / 1.3, in light and dark; 20 px gutters
  on every band at every width.

**Observation (not a finding).** Each `NestListRow` exposes two semantics nodes
(the row's `Semantics(button:, onTap:)` wrapper plus the inner `InkWell`'s own
merged node), so VoiceOver lands on the row twice. It comes from the shared
component's `Material`/`InkWell` pairing, affects every screen that uses
`NestListRow`, and does not block P15 — noted for the orchestrator, not filed.

---

## 6. Verdict

All gates that a test stage owns are clean (`dart format` 0 changed,
`flutter analyze` **No issues found**, 2477 tests pass) and no test was
weakened — but the suite is deliberately red in six places, because the screen
has **five real bugs**, one of them major-and-shared (P15-BUG-5) and one
wrong-child-data major (P15-BUG-1). The brief's PASS bar is "all tests pass and
no bugs were found".


## From 4_review.md
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


## From 5_ui.md
# P15 · Child profile — Stage 5 (UI check) — iteration 1

Route `/child-profile` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844) · `CHILD=maya`, `SEED=demo`, parent mode.

## Captures

- `ui/app_light_1.png` ← `shot.sh $PWD/app /child-profile … light demo parent maya` (absolute OUT path; the bare-relative OUT in the brief resolves under `app/` after the script's `cd`, so `cp` fails)
- `ui/app_dark_1.png` ← same with `dark`
- `ui/cmp_light_1.png`, `ui/cmp_dark_1.png` ← `compare.py` sheets (design | app | diff)

## Mean diff

- Light: **1.21%** (bands: 0: 1.65, 1: 0.11, 2: 0.68, 3: 1.84, 4: 1.24, 5: 1.37, 6: 0.30, 7: 2.50)
- Dark: **1.13%** (bands: 0: 1.61, 1: 0.11, 2: 0.63, 3: 1.28, 4: 1.14, 5: 1.39, 6: 0.26, 7: 2.61)
- Band 0 ≈ status-bar time/glyphs (ignored per STATUS BAR ruling; OS draws them: design `9:41`, app `18:08`/`18:09`). Band 7 ≈ home-indicator pill present in design PNG, absent in `simctl` captures (OS-drawn; no coloured strip under the tab bar in either theme — BOTTOM EDGE passes: below-tab area is tab-bar `surface` to the physical edge, light and dark).

## Expected deltas (rulings — not deviations)

- Stats value `18` → `4`; quests breakdown `3 daily, 3 weekly` → `4 daily, 2 weekly`: DATA OVER MOCKS, DB wins (matches `1_plan.md` §(b) demo numbers).
- Pip art: v1 `pip_stage_3.svg` (green wings) → `PipAvatar` Mochi·sunny·stage 3 in the same 84×84 slot: PIP ruling.
- Kid PIN subtitle pronoun `her` → `their`: builder-documented adaptation (schema has no gender; see deviation 4).

## Measured y (logical px, 390×844; design vs app, light)

Card tops via paper→surface scan at x=195 and x=60: hero **47 vs 47**, stats **227 vs 227**, Pip card **325 vs 325**, list **457 vs 457**, danger card **653 vs 653**; danger bottom/tab top **727 vs 727**. Title `Maya` ink rows **151–163 vs 151–163**. No uniform shift; every band edge within ±2 px.

## Deviations

1. **List subtitles ellipsized early (all 3 rows; light + dark) — overflow/clipping failure.** Design renders full strings; app cuts ~40–60 logical px early with `…`: `On · Maya knows t…` (design `On · Maya knows her code`, rightmost ink x 239 → 195), `6 active · 4 daily, 2…` (design `6 active · 3 daily, 3 weekly`, 237 → 198), `£3.00 a week · Ow…` (design `£3.00 a week · Owed £4.20`, 252 → 190). Even the narrow-`›` rows clip, so `list-main` is starved, not just the `Change ›` row. Fix: give the title/sub column the design's full remaining width (flex `list-main`, trailing shrink-0 with design padding only) so each subtitle fits on one line at 390 px; re-screenshot both themes.
2. **Quests row icon glyph differs.** Design tile: circle outline (r≈9) with small check inside (HTML `circle` + `check` path). App tile: plain large check, no circle (verified in @3x tile crop). Fix: use the circled-check asset (`NestIcons` entry matching the design) for the Quests row.
3. **Pocket money row icon glyph differs.** Design tile: gold coin with leaf emboss (`coin.svg`). App tile: `£` glyph in a circle (`poundCoin`). Fix: use the coin asset for the Pocket money row.
4. **Kid PIN subtitle pronoun** (design `Maya knows her code`, app `Maya knows their code` — full string unreadable in-shot due to deviation 1, per `2b_build_ui.md` copy asserts). Builder-intentional (no gender in schema); needs design sign-off, listed here for the record.
5. **Dark-mode check:** colours flip per tokens (surface/paper/ink, danger → light red, tiles tinted correctly); same three deviations (1–3) reproduce in dark; no strip under tab bar; alignment/gutters identical to light.

Alignment/owner rules otherwise pass: 20 px gutters everywhere, card/tab-bar edges share x=20/370, radii/shadows/progress (70%) match, hero avatar/stat tiles/Pip title/captions/danger button copy exact.


## From 6_bugs.md
# P15 · Child profile — bug hunt (Stage 6, iteration 1)

Route `/child-profile` (`FamilyRoutePaths.childProfile`) · feature `family` ·
parent mode · designs `design/screens/{light,dark}/P15-child-profile.png` ·
tree tested: iteration-1 checkpoint **`586a9d2`** ("P15: checkpoint after
build (iteration 1)"), main merged through `abf2a96`.

Sources re-read for this pass: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md`, `2a_build_logic.md`, `2b_build_ui.md`; the built screen
(`child_profile_view.dart`, `child_profile_body.dart`,
`child_profile_copy.dart`, `family_bloc.dart`, `family_repository_impl.dart`,
`family_routes.dart`) and the family test suite. The iteration-1 test /
review / UI stages ran concurrently with this stage; their notes and
`ORCHESTRATOR_NOTES.md` (18:15) are cross-checked below.

Method: every hypothesis was probed against the real tree first (widget /
repository / bloc probes with real in-memory Drift and bundled fonts); the
red ones were then written as skipped proofs in
`app/test/features/family/p15_bugs_test.dart` with their bug id, so this
stage adds no red to the suite (the test stage's own red repros are separate).

**Result: 5 bugs owned by this stage — 4 major (1, 6, 7, 8) and 1 minor (3).**
The parallel test stage independently found the same P15-BUG-1 plus three more
(P15-BUG-2/4/5) and the UI stage FAILed on `ORCHESTRATOR_NOTES.md` item 1.
**VERDICT: FAIL** (the brief's PASS bar is "no major bugs").

| Id | Severity | Summary | Failing proof |
|---|---|---|---|
| P15-BUG-1 | **major** | `/child-profile?childId=` is ignored: P05 "Edit Leo" and P08 Today's Leo card open **Maya's** profile (also test stage P15-BUG-1, review finding 1) | `P15-BUG-1a`, `P15-BUG-1b` |
| P15-BUG-6 | **major** | Removing a child deletes only the `children` row — pending approvals, completions, ledger, quests, wardrobe, badges, goals survive | `P15-BUG-6` |
| P15-BUG-7 | **major** | Removing the active child leaves `app_state.active_child_id` pointing at the deleted row (review finding 2) | `P15-BUG-7` |
| P15-BUG-8 | **major** | `watchProfile` period math uses the wall clock, not the pinned seed anchor — demo numbers/suite break on 2026-10-04 (review finding 3) | `P15-BUG-8` |
| P15-BUG-3 | minor | A second identical remove failure is suppressed as a duplicate state — no fresh toast (same root as test stage P15-BUG-3) | `P15-BUG-3` |

Ids 1–5 belong to the test stage's repros (its un-skipped red proofs in
`child_profile_view_test.dart`, `child_profile_bloc_test.dart`,
`child_profile_states_test.dart`, `child_profile_copy_test.dart`,
`child_profile_theme_size_test.dart` and `SHARED_REQUEST.md` §1); 6–8 are the
bugs this stage found that the test stage did not cover.

---

## P15-BUG-1 — major — the `childId` query parameter is ignored

**Repro (user path).** Open P05 `/add-children` → tap the pencil on **Leo's**
card (or P08 `/today` → tap **Leo's** kid card). P15 opens showing **Maya**:
hero "Maya", "Age 7–9 · Pip is a Fledgling", "Remove Maya from family". Deep
link `/child-profile?childId=leo` does the same.

**Evidence.**

* `family_routes.dart:31-41` builds `ChildProfileView` without reading
  `state.uri.queryParameters['childId']`.
* `family_repository_impl.dart:93,119` selects `app_state.activeChildId`
  (demo seed: `'maya'`).
* `kid_card_grid.dart:130` (P05) and `today_loaded_body.dart:557` (P08) both
  navigate with `?childId=${child.id}`; nothing calls
  `AppSession.setActiveChild` on those paths (`grep setActiveChild` → only
  `launch.dart:58`).
* Probe on `586a9d2`: `/child-profile?childId=leo` → `profile.child.id ==
  'maya'`; P05 Edit Leo → `'maya'`.

**Failing tests.** `p15_bugs_test.dart` → `P15-BUG-1a`
(`/child-profile?childId=leo must show Leo`), `P15-BUG-1b`
(`P05's Edit Leo pencil must open Leo's profile`). Both RED on `586a9d2`.
The test stage's `P15-BUG-1` group proves the same via the Today tap.

**Suggested fix.** Make the route honour the selector: in `childProfileRoute`,
read `state.uri.queryParameters['childId']`, validate it against the family's
children and persist it through `AppSession.setActiveChild` **before** the
first `FamilyLoadRequested` (a small stateful wrapper around
`ChildProfileView`: `initState` → `await session.setActiveChild(param)` →
`add(FamilyLoadRequested)`), or pass the id into `FamilyBloc` as an initial
selection override. `_selectProfileChild` already falls back to the
first-created child for unknown ids, so validation is optional. This fixes
both entry points without touching P05/P08.

**Impact.** Any "open this child" affordance in the app shows another child's
data — including the remove action and the Pip slot. Wrong-child personal
data class.

---

## P15-BUG-6 — major — `removeChild` orphans every dependent row

**Repro.** `/child-profile` → "Remove Maya from family" → Remove → confirm.
Maya's two pending approvals (`q-dishwasher`, `q-table`) are still in the
database; P11 `/approvals` then renders them as `Child · …` rows
(`approvals_repository_impl.dart:44,51` fall back to `'Child'`/lilac when the
child row is gone). Her six quests stay active and listed in P10; her ledger,
wardrobe, badges and goal stay behind.

**Evidence.** `family_repository_impl.dart:304-306` deletes only
`children`. Probe (real demo DB, `repo.removeChild('maya')`) on `586a9d2`:

| Table | Rows still referencing `maya` |
|---|---|
| `quest_completions` | 7 (2 × `done_pending`, 2 × `approved`, 3 × `to_do`) |
| `ledger_entries` | 11 |
| `quests` (`assignee_child_id`) | 6 |
| `pip_wardrobe` | 4 |
| `earned_badges` | 4 |
| `savings_goals` | 1 |
| `reward_redemptions` | 0 (none seeded) |

The confirm modal promises "They will lose their quests, coins and Pip. This
cannot be undone." (`child_profile_copy.dart`), so the rows must go with the
child. (The schema's `references(Children, #id)` are declarative only —
`beforeOpen` never enables `PRAGMA foreign_keys`, so nothing cascades.)

**Failing test.** `P15-BUG-6` (`removing a child deletes their dependent
rows`) asserts all seven tables are empty for the removed child. RED on
`586a9d2`.

**Suggested fix.** One transaction in `FamilyRepositoryImpl.removeChild`:
delete `quest_completions`, `ledger_entries`, `savings_goals`,
`reward_redemptions`, `earned_badges`, `pip_wardrobe` rows for the child and
the child's assigned `quests` (unassigning family-wide quests is the
alternative if their history must survive), then the `children` row — plus
the P15-BUG-7 selection move below.

**Impact.** User-visible data retention after an explicit, irreversible-looking
delete; P11's inbox shows rows for a child who no longer exists.

---

## P15-BUG-7 — major — `active_child_id` keeps the deleted child

**Repro.** `/child-profile` → remove Maya → confirm → read `app_state`.
`active_child_id` is still `'maya'`.

**Evidence.** Probe on `586a9d2` (UI remove flow, real DB):
`state.activeChildId == 'maya'` after the removal; P15 itself falls through
to Leo via `_selectProfileChild`, which is why the screen looks fine. But
every kid-mode repository resolves `state?.activeChildId ?? 'maya'`
(`pip_repository_impl.dart:25`, `kid_shop_repository_impl.dart:22`,
`kid_jar_repository_impl.dart:24`, `badges_repository_impl.dart:20`; the
review lists six call sites) — with the stale id they keep watching the
deleted child (and, because of P15-BUG-6, her ledger rows are still there for
K09 to render).

**Failing test.** `P15-BUG-7` (`the confirm-remove clears the stale
active_child_id`) — RED on `586a9d2`.

**Suggested fix.** In the same transaction as P15-BUG-6: if
`app_state.active_child_id == childId`, set it to the first remaining child in
creation order (matching the P15 fallback) or NULL when the family is empty.

**Impact.** Cross-screen wrong-child data after a removal; the persisted
session disagrees with the UI's own selection.

---

## P15-BUG-8 — major — period math is wall-clock bound, not anchor-aware

**Repro.** `Seed.anchorOverride = DateTime.utc(2020)`; `Seed.demo(db)`;
`FamilyRepositoryImpl(db).watchProfile().first` → `questsThisWeek == 0`, but
the seed's own story day is now 2020-01-01, whose "done today" daily
completions must count → 4.

**Evidence.** `family_repository_impl.dart:102` uses
`DateTime.now().toUtc()` for `countsForCurrentPeriod`. `flutter_test_config`
pins `Seed.anchorOverride = 2026-10-03`, so on the real date 2026-10-04 the
demo's daily completions (10-03) stop counting: `child_profile_bloc_test.dart`
("selects the activeChildId child with the demo numbers", expects
`questsThisWeek == 4`) fails with no code change — and so does this stage's
`P15-BUG-8` proof. The established pattern already exists:
`today_repository_impl.dart:15-26` takes an injectable clock defaulting to
`Seed.anchorOverride ?? DateTime.now().toUtc()`. (Secondary effect: a screen
left open across London midnight keeps yesterday's counts until the next DB
write, because nothing re-evaluates `now`.)

**Failing test.** `P15-BUG-8` (`demo numbers must follow the pinned seed
anchor`) — RED on `586a9d2` (actual 0, expected 4).

**Suggested fix.** Mirror `TodayRepositoryImpl`:

```dart
FamilyRepositoryImpl({required AppDatabase db, DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;
static DateTime _defaultClock() =>
    Seed.anchorOverride?.toUtc() ?? DateTime.now().toUtc();
```

and use `_clock()` at `family_repository_impl.dart:102`.

**Impact.** Test-integrity major: the loop's required green suite breaks from
2026-10-04; production demo data is unaffected because the seed anchors to
today.

---

## P15-BUG-3 — minor — repeat identical remove failure is silent

**Repro.** With a repository whose `removeChild` throws (DB failure path),
dispatch `FamilyRemoveChildRequested` twice. The first emits
`errorMessage: 'Exception: offline'`; the second computes an identical
`FamilyState`, which Equatable suppresses, so `BlocListener.listenWhen`
(`previous.errorMessage != current.errorMessage`) never fires again — the
user retries, it fails, and no toast appears.

**Evidence.** Bloc probe with a throwing mock on `586a9d2`: two failures,
`1` error state observed. The test stage's `P15-BUG-3` proves the same root
from the load-recovery side (`FamilyState.copyWith` cannot clear
`errorMessage`); this proof covers the remove path.

**Failing test.** `P15-BUG-3` (`a repeated remove failure raises a fresh
toast`) — RED on `586a9d2`.

**Suggested fix.** Clear the signal when the toast is shown (view adds a
`FamilyErrorShown` event that nulls `errorMessage`) or add a monotonically
increasing failure token to the state and listen on it.

**Impact.** Missing feedback on a repeated failure — minor, DB-failure path.

---

## Parallel stages — cross-check (all landed while this stage ran)

* **`4_review.md`** independently found the same three majors: finding 1 =
  P15-BUG-1, finding 2 = P15-BUG-7 (+ orphan cleanup, P15-BUG-6), finding 3 =
  P15-BUG-8. Its minors 4–10 (duplicate failure toast, missing header
  semantics, hero wrap, bare `size: 84`, pronoun, today-test scope, missing
  view-state tests) are tracked there and are not duplicated here; its
  finding 4 overlaps the test stage's P15-BUG-2/3.
* **Test stage red proofs at this snapshot** (`flutter test
  test/features/family` → `+215 ~6 -6` at ~18:47 BST): `P15-BUG-1a/b`
  (deep link, view), `P15-BUG-2` (load failure reported twice, states),
  `P15-BUG-3` (recovered load keeps the dead message, bloc), `P15-BUG-4`
  (stage-1 Pip reads "an Egg", copy), and `P15-BUG-5` (`NestListRow`
  ellipsises the three subtitles, theme/size — orchestrator item 1). The test
  stage's files were still changing while this document was written (an
  earlier snapshot also had two red icon/image-label accessibility proofs in
  `child_profile_theme_size_test.dart`, light + dark, since resolved by that
  stage's own edits); the counts above are a snapshot. Its `3_test.md` was
  not yet written when this snapshot was taken.
* **`5_ui.md`** measured every band within ±2 px (hero 47, stats 227, Pip 325,
  list 457, danger 653; no uniform shift) but FAILed on orchestrator item 1
  (subtitles ellipsised ~40–60 px early on all three rows) and deviations 2/3
  (plain check instead of circled check; `£` glyph instead of the coin
  illustration).
* **`SHARED_REQUEST.md`** already carries the two shared blockers: §1
  `NestListRow` starves the main column (`Flexible` trailing reserves half the
  row; the CSS is `.list-main { flex: 1 } .list-trail { flex-shrink: 0 }`) —
  orchestrator item 1 — and §2 the missing circled-check icon + coin
  illustration — orchestrator items 2/3. RULES §1 forbids the screen from
  editing `core/design_system/**`, so these are correctly requests, not
  screen fixes.
* **`ORCHESTRATOR_NOTES.md` (18:15) verification:** item 1 — still failing at
  this snapshot, proven by the test stage's `no list-row paragraph is
  ellipsised at 390` (RED) and `SHARED_REQUEST.md` §1; items 2/3 — still
  failing (plain `NestIcons.check`, `NestIcons.poundCoin`), assets requested in
  `SHARED_REQUEST.md` §2; item 4 — the pronoun "their" and the DB quest counts
  are **not** reported as findings anywhere in this document.

## Verified sound (adversarial probes on `586a9d2`, all green)

| Probe | Result |
|---|---|
| 0 children — `Seed.empty()` deep link | `No children yet` + copy + CTA → `/add-children` ✓ |
| Empty state at 320 × textScale 1.3 | no overflow exception ✓ |
| 1 child (after Maya's removal) | selection falls to Leo; screen, Pip and copy correct ✓ |
| 6 children, `active_child_id` = 6th | 6th child's profile renders, no exception ✓ |
| Long UK name (`Maximilian-Alexander`) + £999.99 owed + 9999 coins + 9999 Pip coins at 320 × 1.3 | no overflow; ellipsis holds; danger button wraps and grows ✓ |
| Empty quest/ledger lists | `0 active · 0 daily, 0 weekly`, `Owed £0.00`, `0 of 250 · 0%` ✓ |
| Rapid double tap on `Remove …` | one dialog only (second tap hits the barrier) ✓ |
| Confirm-remove double tap | idempotent `DELETE … WHERE id` — one removal ✓ |
| System back from `/kid-pin` push | returns to the profile with state intact ✓ |
| Restart (re-pump the app on the same DB) | removal persisted; Leo shown ✓ |
| Kid-mode deep link `/child-profile` | redirected to `/parental-gate` ✓ |
| Dark mode pump | renders, no exception; tokens only ✓ |
| Dialog buttons / empty CTA semantics | `SemanticsAction.tap` present; performAction drives the real effect ✓ |
| Delayed `removeChild` failure after `bloc.close()` | no unhandled emit-after-close error ✓ |
| Money rounding | `_owedPence` is an exact replica of P12 `summarise` (pence, payout-instant tie included); `moneyPounds` = 2 dp ✓ |
| Copy / fonts / letter spacing | U+2013/U+00B7/U+203A checked; no `google_fonts` in feature or tests; `NestType` letterSpacing 0 ✓ |
| Simulator policy | no simulator was booted, installed on, screenshotted or driven in this stage ✓ |

## Gates (run in `app/` on `586a9d2` + this stage's test file)

```
$ dart format test/features/family/p15_bugs_test.dart
Formatted 1 file (0 changed) in 0.01 seconds.

$ flutter analyze
No issues found! (ran in 7.4s)

$ flutter test --no-pub test/features/family/p15_bugs_test.dart
00:00 +0 ~6: All tests skipped.

$ flutter test --no-pub test/features/family        # snapshot ~18:47 BST
00:12 +215 ~6 -6: Some tests failed.
```

The six `~` are this stage's skipped proofs. The six `-6` are the **test
stage's un-skipped bug repros** (listed under "Parallel stages") — the open
bugs themselves, expected at iteration 1 and fixed by the next build; they
are not caused by this stage's file. `flutter analyze` is clean and this
stage added no red.

No production file was changed by this stage: the only additions are
`app/test/features/family/p15_bugs_test.dart` (all six proofs `skip:`-marked
with their bug ids) and this document.

