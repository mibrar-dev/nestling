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

VERDICT: FAIL