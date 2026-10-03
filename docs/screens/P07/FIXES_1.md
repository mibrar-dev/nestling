# Fix list after iteration 1

## From 2_build.md
# P07 Paywall — build report (Stage 2, iteration 1)

## Files changed

None. No tracked file was modified and no new file was created in this
iteration (`git status --porcelain` shows only the loop's own untracked
`.brief_build*` / `.start_build` marker files). In particular these were
left untouched:

- `app/lib/features/paywall/presentation/views/paywall_view.dart` — still the
  placeholder scaffold (`P07 Paywall` app bar + raw `ListTile` list).
- `app/lib/features/paywall/presentation/bloc/paywall_{event,state,bloc}.dart`
  — still load-only (`PaywallLoadRequested`, no `PaywallTrialStarted` /
  `PaywallRestoreRequested`, no `action` state).
- `app/lib/features/paywall/presentation/widgets/paywall_placeholder_card.dart`
  — still present.
- `app/test/features/paywall/**` — still does not exist.
- `docs/screens/P07/SHARED_REQUEST.md` — not filed (nothing to request yet).

## Fix items (per docs/screens/P07/1_plan.md §a–g)

Iteration 1 is the first build, so there are no prior-stage fix items to
close; the plan items themselves are the work, and none was implemented:

1. Widget tree (nav / hero / title / benefits / plan / timeline / family
   note / `NestBottomCta` + legal row) — NOT BUILT. Only investigation
   reads were done (plan, HTML source, SPACING_SPEC, design-system tokens,
   `welcome_view.dart` hero-scale precedent, `PipAvatar` API,
   `AppSession`, routes, `test_scope.dart`).
2. BLoC action events + `PaywallAction` state + repository wiring — NOT BUILT.
3. Navigation (close → `/pocket-money-setup`, trial/restore → session
   writes → `/today`, Terms/Privacy toast placeholders) — NOT WIRED.
4. Empty / loading / error states — NOT BUILT.
5. Accessibility contract — NOT BUILT.
6. Feature tests (`paywall_bloc_test.dart`, `paywall_view_test.dart`) —
   NOT WRITTEN.
7. `SHARED_REQUEST.md` — nothing filed.

Two findings from investigation are recorded here so iteration 2 does not
re-derive them:

- `AppSession` is registered in GetIt (`app/lib/app/di.dart`) but is NOT
  provided as an ancestor `Provider` in `app/lib/app/app.dart`, so the
  plan's `context.read<AppSession>()` would throw at runtime. Iteration 2
  must use `GetIt.instance<AppSession>()` (read-only) in the
  `BlocListener` success path and document the deviation.
- Trial vs restore need different session writes (`startTrialNow()` must NOT
  run on the restore path — it would regress an `active` subscription), so
  the `success` state must carry which request succeeded (e.g. a
  `PaywallRequest{trial, restore}` field alongside the plan's
  `PaywallAction{idle, working, success, failure}`).

## Analyze / test tails

`dart format .`, `flutter analyze`, and `flutter test` were NOT run in this
iteration — there was no code change to format, analyze, or test, so there
are no tails to paste. The placeholder view, load-only bloc, and missing
feature tests from the foundation remain exactly as found.

## Verdict basis

Stage 2 requires: placeholder replaced, BLoC + navigation wired, light +
dark with no overflow at 320 dp / text scale 1.3, `flutter analyze` printing
`No issues found!`, and `flutter test` all passing. None of these holds —
no implementation exists to verify. The next iteration must implement
1_plan.md §§a–g in full, then format/analyze/test.


## From 3_test.md
# P07 Paywall — test report (Stage 3, iteration 1)

## Summary

The P07 test suite is written and runs, but it cannot pass: **the screen was
never built.** `app/lib/features/paywall/presentation/views/paywall_view.dart`
is still the foundation placeholder from the base branch, and the bloc still
only loads. Stage 2 (build, iteration 1) implemented nothing — `2_build.md`
says so itself and returned `VERDICT: FAIL`.

63 tests were added (18 bloc/repository + 45 widget). 20 pass, 43 fail. Every
failure is either "the screen does not exist yet" (42 widget tests) or a real
copy defect in the paywall repository (1 test). Per the stage brief, nothing in
`lib/` was patched — the defects are recorded below for the build stage.

| Run | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 366 files, 0 changed |
| `flutter analyze` | **No issues found!** |
| `flutter test` (whole app) | **+665 −43** (baseline before this stage: +645 −0) |
| `flutter test test/features/paywall/` | **+20 −43** |

## Files added (feature tests only — nothing outside RULES §1)

- `app/test/features/paywall/paywall_bloc_test.dart` — 18 tests
- `app/test/features/paywall/paywall_view_test.dart` — 45 tests

Both use the shared scope (`setUpTestScope`, `pumpAppRoute`, `disposeApp`,
`currentPath` from `app/test/test_scope.dart`), an in-memory Drift DB via
`AppDatabase.memory()`, and `Seed.demo` / `Seed.empty` / `Seed.fresh`. Every
widget test that pumps the app ends with `disposeApp(tester)`.

## Tests added

### `paywall_bloc_test.dart` (18 — 17 pass, 1 fail)

| Group | Covers |
|---|---|
| `PaywallState` | `copyWith` field-by-field, equality/hashCode |
| `PaywallBloc` | initial state; `blocTest` load on the real Drift repository; a live multi-emission stream; an empty stream; a stream error; a retry while the first stream is still pending |
| `PaywallRepository` (in-memory Drift) | the single annual plan under demo/empty/fresh; the plan detail's caption copy; `watchSubscription` for all three seeds (`active` / `trial` / `trial` with no start date); `startTrial()` writes status + UTC start + `Europe/London`; `activate()` writes `active` and does not move the trial start; `watchSubscription` re-emits on change |

### `paywall_view_test.dart` (45 — 3 pass, 42 fail)

| Group | Tests | Covers |
|---|---|---|
| the design's copy | 5 | hero/title/benefits/plan card; timeline + family note after scrolling; `NestBottomCta` + CTA + caption + 3 legal links + 2 `·` separators; character-by-character punctuation (U+2019, U+2014, U+00A3, U+00B7, no ASCII apostrophe/quote/ellipsis/spaced hyphen, no repository caption variant); the design's type scale (h1 28 Nunito, benefits 15 Inter, plan title 18, sub 15, tag 13, `.h3` 18, `.tl-title` 15, note 15, caption 13) |
| Pip v2 (orchestrator) | 1 | no `pip_stage_*.svg`; exactly one `PipAvatar(mochi, sunny, stage 4, inNest: true)`; the design's `alt` label on a 120×120 slot |
| widths / themes / scales | 14 | 12-combination matrix (light+dark × 320/390/430 × scale 1.0/1.3): `NestBottomCta`, CTA and legal links present, `takeException()` null; plus both themes reading benefits/timeline in full |
| alignment & tap targets | 7 | 20px gutters on both cards at 3 widths; centred title; plan text column shares one left edge; timeline steps in document order on one left edge; close 44×44, CTA ≥52, legal links ≥44×44, no kid controls |
| bottom edge (owner rule) | 4 | light + dark: `NestBottomCta` reaches y = 844 with and without a 34px home-indicator inset, and the painted pixel on the last row is the bar's `surface` token (no page-tint or meadow strip) |
| loading / empty / failure | 5 | `initial` and `loading` show a progress indicator; an empty plan list is **not** an empty state; `failure` shows “Something went wrong” + a Retry that re-adds the load event |
| navigation & handoff | 5 | close → `/pocket-money-setup`; **Start free trial** → `onboarding_complete = true`, `subscription_status = 'trial'`, `trial_start` written, → `/today`; **Restore purchases** → `'active'` (never downgraded to trial) + onboarding complete → `/today`; Terms/Privacy answer in place and stay on `/paywall`; tapping the plan card does nothing |
| accessibility | 2 | nav label `Subscription`, close label + button + tap action, legal links labelled buttons, plan announced `selected: true`; decorative nest/coins/ticks carry no label, benefits are labelled rows |
| seeds (DATA OVER MOCKS) | 1 | demo / empty / fresh render an identical screen: the design's copy is there, `James` is there, `Maya`/`Leo` are not |
| route wiring | 2 | the route's bloc loads the annual plan; `/paywall` is reachable while onboarding is incomplete |

## Bugs found

### P07-BUG-1 — blocker — the paywall screen does not exist

**File:** `app/lib/features/paywall/presentation/views/paywall_view.dart:9-42`
(`AppBar('P07 Paywall')` at :12, `Text(state.errorMessage ?? 'Something went
wrong')` at :21, `Text('No items yet')` at :25, `ListTile` list at :31).

**Repro:** `cd app && flutter test test/features/paywall/` → 42 of 45 widget
tests fail. Pump `/paywall` at 390×844 light and the screen shows an app bar
titled “P07 Paywall” and one `ListTile` whose title is the repository plan
string. None of `1_plan.md` §a exists: no `NestStatusBar`, no hero (`PipAvatar`,
nest, coins), no `Try Nestling free for 14 days`, no 4 benefit rows, no plan
card, no timeline, no family note, no `NestBottomCta`, no
`Start free trial`, no caption, no `Restore purchases` / `Terms` / `Privacy`.
The design PNG (`design/screens/light/P07-paywall.png`) shows all of them.

**Rule impact:** orchestrator PIP (no `PipAvatar` anywhere), ALIGNMENT, BOTTOM
EDGE and COPY are all unimplemented.

### P07-BUG-2 — major — no trial or restore path exists, so ORCHESTRATOR_NOTES 1 cannot hold

**Files:** `presentation/bloc/paywall_event.dart:10` (only
`PaywallLoadRequested`), `presentation/bloc/paywall_bloc.dart:9` (only the
`_onLoadRequested` handler), `presentation/bloc/paywall_state.dart:4,13`
(`PaywallStatus` only; no `action` field).

**Repro:** the events `PaywallTrialStarted` / `PaywallRestoreRequested` and the
`PaywallAction {idle, working, success, failure}` state do not compile —
referencing them from a test would break the whole test target. Observed from
the outside: pump `/paywall` on `Seed.fresh`, tap `Start free trial` → the
control does not exist; no `app_state` write, no `AppSession.startTrialNow()` /
`completeOnboarding()`, no navigation to `/today`. Consequently P07 is a dead
end: onboarding cannot be completed from the last step.

**Fix shape (from `1_plan.md` §b + `2_build.md`):** add both events, an
`action` field plus the “which request succeeded” discriminator (trial vs
restore need different session writes), and wire `GetIt.instance<AppSession>()`
→ `startTrialNow()` + `completeOnboarding()` → `go('/today')` for trial, and
`setSubscription('active')` + `completeOnboarding()` → `/today` for restore.

### P07-BUG-3 — minor — the plan's caption copy drops the article “the”

**File:** `app/lib/features/paywall/data/paywall_repository_impl.dart:52-54`

```
detail: 'Just £2.50 a month, billed yearly. '
        '£29.99/year after 14-day trial. Cancel anytime in Settings.',
```

The design's `.caption`
(`design/html-source/screens/P07-paywall.html:105`, and `1_plan.md`) is
`£29.99/year after **the** 14-day trial. Cancel anytime in Settings.`
Orchestrator COPY rule: the HTML is the source of truth.

**Repro:** `cd app && flutter test test/features/paywall/paywall_bloc_test.dart`
→ “the plan detail carries the design's caption verbatim” fails. The string is
already on screen today (the placeholder renders `detail` as the `ListTile`
subtitle) and the widget test
`find.textContaining('after 14-day trial') → findsNothing` fails for the same
reason.

**Note for the fix:** `docs/DESIGN_SPEC.md:158` paraphrases the caption *without*
“the”. The HTML wins; do not “fix” the test to match DESIGN_SPEC.

### P07-BUG-4 — minor — the repository's plan detail omits the design's plan tag

**File:** `app/lib/features/paywall/data/paywall_repository_impl.dart:49-56`

The card has three strings in the design — title, sub
(`Just £2.50 a month, billed yearly`) and tag
(`One price, the whole family`, `P07-paywall.html:87`). `detail` concatenates
the sub with the caption and drops the tag, so the plan card would have no data
source for it.

**Repro:** `flutter test test/features/paywall/paywall_view_test.dart` → the
copy group requires `One price, the whole family` on screen.

`1_plan.md` §d allows the view to render static spec copy, so this is not fatal
on its own — but it leaves the plan card with two sources of truth. Either carry
the tag in `detail` or keep it static and say so in the plan.

### P07-BUG-5 — minor (latent) — the repository writes are UPDATE-only, not upserts

**File:** `app/lib/features/paywall/data/paywall_repository_impl.dart:36-45`
(`startTrial`) and `:47-56` (`activate`) — both do
`update(appState)..where(id = 1)` with no insert fallback, unlike
`AppSession._write` (`core/data/app_session.dart:70-79`), which upserts.

Not reachable today (all three seeds insert the `app_state` row), but it is the
exact defect class of P01 BUG-4: if `app_state` is ever empty, the trial/restore
write silently affects 0 rows and the parent is navigated to `/today` with no
subscription recorded. Recommend the upsert pattern here too.

## Observations (not bugs — constraints for the next iteration)

1. **`AppSession` is not a Provider ancestor.** `app/lib/app/app.dart:46-52`
   provides only `AppModeController` and `ThemeModeController`; `AppSession` is
   reachable through GetIt only. `1_plan.md` §b's `context.read<AppSession>()`
   would throw `ProviderNotFoundException` at runtime — use
   `GetIt.instance<AppSession>()` (already flagged in `2_build.md`). The tests
   written here are agnostic: they assert the *effect* by reading `app_state`
   through Drift, so either wiring passes.
2. **Event-level unit tests are deferred, deliberately.** `PaywallTrialStarted`
   / `PaywallRestoreRequested` do not exist; naming them in a test file makes the
   whole test target fail to compile, which would hide all 20 currently-green
   tests behind one compile error. The trial and restore paths are covered from
   the widget side instead (tap → assert `app_state` → assert route). When the
   events land, add to `paywall_bloc_test.dart`: `blocTest` for
   `PaywallTrialStarted` (working → success on `startTrial()`, failure with
   `errorMessage` when the repository throws) and for `PaywallRestoreRequested`
   (`activate()`), plus `PaywallAction` transitions in the state group.
3. **Widget-test font width.** The test font is far wider than Inter
   (P02-BUG-7), so at 320dp + 1.3× the h1 and the CTA caption genuinely
   ellipsize. The matrix tests therefore assert “no exception”, not “full text
   visible”, and no test asserts a real line count.
4. **No shared change is needed**, so no `SHARED_REQUEST.md` is filed: every
   failing test can be satisfied inside `app/lib/features/paywall/**`.

## Green baseline to preserve

The 20 passing tests are the contract the build must not break: the
`PaywallStatus` machine (initial → loading → loaded | failure), live/empty/error
streams, the Drift repository's `startTrial`/`activate` writes and
`watchSubscription` (demo `active`, empty `trial`, fresh `trial` with no start
date, `Europe/London` zone), the route's bloc wiring, and the `initial` /
`loading` progress states.

## Verdict basis

Stage 3 requires all tests to pass with no bugs found. 43 tests fail and five
defects are recorded — one of them a blocker (the screen is not implemented) —
so this iteration cannot pass. The build stage must implement `1_plan.md`
§§a–g; the failing tests are the checklist, and re-running
`flutter test test/features/paywall/` is the proof.


## From 4_review.md
# P07 Paywall — QA code review (Stage 4, iteration 1)

Scope reviewed: `git diff main...HEAD` (docs/screens/P07/plan files only), the
current state of `app/lib/features/paywall/**`, the new tests in
`app/test/features/paywall/**`, and the stage reports `1_plan.md`,
`2_build.md`, `3_test.md`, plus mandatory `ORCHESTRATOR_NOTES.md`.

**Headline: the screen was not built in this iteration.** Stage 2 returned
`VERDICT: FAIL` with no implementation; Stage 3 added a 63-test suite of which
43 fail. There is effectively no P07 code to approve.

## Findings

1. **Blocker — P07 paywall screen is not implemented.**
   `app/lib/features/paywall/presentation/views/paywall_view.dart:9-42` is still
   the foundation placeholder (`AppBar('P07 Paywall')` at :12,
   `Text('No items yet')` at :25, `ListTile` list at :31). `git diff main...HEAD`
   contains zero changes under `app/lib/`. None of the required surface exists:
   `NestStatusBar`, hero Pip, title "Try Nestling free for 14 days", 4 benefit
   rows, plan card, trial timeline, family note, `NestBottomCta`, "Start free
   trial" CTA + caption, Restore/Terms/Privacy row, close X.
   *Fix:* implement `docs/screens/P07/1_plan.md` §§a–g in full; rerun
   `flutter test test/features/paywall/` as proof.

2. **Blocker — P07 is a dead end; ORCHESTRATOR_NOTES item 1 is violated.**
   `presentation/bloc/paywall_event.dart:10` has only `PaywallLoadRequested`;
   `paywall_bloc.dart:9` has only `_onLoadRequested`; `paywall_state.dart:4,13`
   has no `action` field. There is no trial or restore path, so
   `AppSession.startTrialNow()` / `AppSession.completeOnboarding()` are never
   called and the user cannot reach `/today` — onboarding cannot complete.
   *Fix:* add `PaywallTrialStarted` / `PaywallRestoreRequested` events, an
   action state discriminating trial vs restore (trial must NOT downgrade an
   `active` subscription; restore must NOT call `startTrialNow()`), wire
   `GetIt.instance<AppSession>()`, then navigate to `/today`.

3. **Blocker — feature test suite is red (43 of 63 failing).**
   `app/test/features/paywall/paywall_view_test.dart`: 42 widget tests fail
   against the placeholder view; `paywall_bloc_test.dart`: 1 fails. Per the
   stage brief the *tests themselves* are not patched — they are the contract
   for the build. *Fix:* satisfy them in the build stage; do not weaken them.

4. **Major — plan caption copy drops "the" (COPY rule, HTML wins).**
   `app/lib/features/paywall/data/paywall_repository_impl.dart:52-54` renders
   `£29.99/year after 14-day trial.` The HTML source
   `design/html-source/screens/P07-paywall.html:105` is
   `£29.99/year after the 14-day trial.` (`docs/DESIGN_SPEC.md:158` paraphrases
   without "the" — HTML source wins; do not "fix" the test). *Fix:* insert
   `the ` in the repository string.

5. **Major — plan card's design tag has no data source.**
   `paywall_repository_impl.dart:49-56` concatenates sub + caption into `detail`
   and drops the tag `One price, the whole family`
   (`P07-paywall.html:87`). The copy group in the widget test requires it on
   screen. *Fix:* carry the tag on `PaywallPlan` (or render it statically and
   say so in `1_plan.md` so there is a single source of truth).

6. **Minor — repository writes are UPDATE-only, not upserts.**
   `paywall_repository_impl.dart:36-45` (`startTrial`) and `:47-56`
   (`activate`) use `update(appState)..where(id = 1)` with no insert fallback;
   `AppSession._write` (`core/data/app_session.dart:70-79`) upserts. If
   `app_state` is ever empty the write silently touches 0 rows and the user is
   routed to `/today` with no subscription recorded — the P01 BUG-4 defect
   class. *Fix:* use the same upsert pattern.

7. **Minor (latent) — accessibility/bottom-edge/alignment contracts unmet.**
   The placeholder has no semantic labels (nav label `Subscription`, close
   button label/action, `selected: true` plan card, decorative nest/coins
   unlabelled), and once the real body lands it must verify the OWNER rules:
   painted pixel on the last row equals the `NestBottomCta` surface colour
   (no page-tint/meadow strip under the home indicator), consistent 20 px
   gutters, and `PipAvatar(style: mochi, skin: sunny, stage 4, inNest: true)`
   on the 120×120 hero slot — never `pip_stage_*.svg`.

## Architecture / rules check

- Feature-first layout (`domain` entities + abstract repo, Drift-backed
  `data`, BLoC per screen, routes + DI per feature) matches
  `docs/ARCHITECTURE.md`; the placeholder is scaffolding only.
- Edited paths stay inside RULES §1 (`app/lib/features/paywall/**`,
  `app/test/features/paywall/**`, `docs/screens/P07/**`). No shared files
  touched; no `SHARED_REQUEST.md` filed, and none of the failures requires
  one.
- `2_build.md` correctly records that `AppSession` is provided via GetIt only
  (`app/lib/app/app.dart:46-52` lacks it as a `Provider` ancestor), so the
  plan's `context.read<AppSession>()` would throw — use
  `GetIt.instance<AppSession>()`.
- `flutter analyze` reports no issues and `dart format` is clean per
  `3_test.md`; no hard-coded colours/sizes introduced by this iteration (no
  UI code added).
- Children's Code: no analytics, ads, tracking, or child-data surfaces
  introduced; parent mode only.
- Data-over-mocks / periods / child-order rules: not exercised by current
  code; must hold in the build (annual plan from repository, no hard-coded
  design numbers).

## Verdict basis

Blockers 1–3 stand: the required surface, navigation path, and green test
suite are all absent. This iteration cannot pass; the build stage must
implement `1_plan.md` §§a–g against the existing failing tests, fix findings
4–7, and then stages 3–4 rerun.


## From 5_ui.md
# P07 Paywall — UI check (Stage 5, iteration 1)

Method (iPhone simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390×844):
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_light_1.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light fresh parent maya`
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_dark_1.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark fresh parent maya`
- `python3 tools/screens/compare.py design/screens/light/P07-paywall.png docs/screens/P07/ui/app_light_1.png docs/screens/P07/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/P07-paywall.png docs/screens/P07/ui/app_dark_1.png docs/screens/P07/ui/cmp_dark_1.png`
- Sources: `design/html-source/screens/P07-paywall.html`, `docs/DESIGN_SPEC.md` §5 P07, `docs/design/SPACING_SPEC.md` §§1–2/8/10–11, `docs/screens/P07/1_plan.md`, `docs/screens/P07/ORCHESTRATOR_NOTES.md` (item 1 mandatory).
- Status bar differences ignored per orchestrator STATUS BAR rule (OS draws real bar; `NestStatusBar` reserves height only).

## Mean diff

- Light: **9.92%** (bands: 0 0–105: 3.07% · 1 105–211: 9.54% · 2 211–316: 13.29% · 3 316–422: 6.92% · 4 422–527: 5.05% · 5 527–633: 8.31% · 6 633–738: 28.75% · 7 738–844: 4.56%)
- Dark: **9.44%** (bands: 0 0–105: 3.28% · 1 105–211: 10.66% · 2 211–316: 9.77% · 3 316–422: 7.26% · 4 422–527: 5.22% · 5 527–633: 8.89% · 6 633–738: 25.35% · 7 738–844: 5.12%)
- The low mean is misleading: both sides share large empty paper areas, so background pixels match while **every designed element is missing**. The app under test is still the foundation placeholder (`paywall_view.dart:9-42`: `AppBar('P07 Paywall')` + `ListTile`), consistent with `2_build.md` / `4_review.md` (no implementation in this loop). Band 6 peaks (28.75% light / 25.35% dark) where the design has the plan card + `NestBottomCta` and the app has empty paper.

## Deviations (design value → app value)

1. Nav / close — design: compact nav `minHeight 52`, padding `4,12,12`, 44×44 close button surface-2 radius 12 with 24px X, semantics `Close and go back`, 44-wide balance spacer. App: Material `AppBar` titled `P07 Paywall`, no close control. Fix: build `_PaywallNav` per `1_plan.md` §a.
2. Hero — design: `350×148`, `margin-top 4`; lilac-tint circle 170×170 at (90,−5); nest 150×150 at (100,41); `PipAvatar(style: mochi, skin: sunny, stage: 4)` 120×120 at (115,20) (orchestrator PIP rule for P01–P07, never `pip_stage_*.svg`); 3 coins 30/26/24px at specified positions/rotations with sh-1. App: absent. Fix: build `_PaywallHero` with `PipAvatar` exactly as planned.
3. Title — design: `Try Nestling free for 14 days`, `NestType.h1` (Nunito 28/34 w900) centred, `margin-top 26`, maxLines 3. App: absent (only AppBar `P07 Paywall`). Fix: add title widget.
4. Benefits — design: 4 rows, `margin-top 18`, gap 10; 24×24 leaf-tint tick (`NestIcon(check, 16, leafInk)`, `margin-top −1`) + Inter 15/24 w400 ink text `softWrap/anywhere`; exact copy `Unlimited children & quests` · `Pip’s full evolution & seasonal outfits` (curly ’ U+2019) · `Pocket money ledger & payout day` · `Co-parent sharing, so James sees the same`. App: absent. Fix: build `_BenefitList`.
5. Plan card — design: `margin-top 24`, `NestCard` (radius 24, sh-1, padding 16) + local 2px leaf border; radio 22 selected (`margin-top 10`); title Nunito 800 18/24 `Annual — £29.99/year` (em dash U+2014); sub Inter 15/20 `Just £2.50 a month, billed yearly`; tag Inter 13/18 w600 leaf-ink `One price, the whole family` with `margin-top 4`. App: unstyled `ListTile` (title `Annual — £29.99/year`, subtitle concatenated detail), no card/border/radio/tag/shadow. Fix: build `_PlanCard` per plan.
6. Timeline + family note (below fold) — design/HTML: `What happens next` card (`margin-top 48`, padding 16, 3 `tl-item`s with 24px dots + 2px connectors) + centred note `One subscription covers the whole family.` (`margin-top 20`). App: absent (no scroll body at all). Fix: build `_TimelineCard` + `_FamilyNote`; verify with a scrolled shot.
7. Bottom CTA — design: `NestBottomCta` (surface + top hairline, padding `16/20`, gap 8); `NestButton.primary` 52h `Start free trial` full-width; caption `£29.99/year after the 14-day trial. Cancel anytime in Settings.` (note `the` — HTML wins over DESIGN_SPEC paraphrase); legal row `Restore purchases · Terms · Privacy` (Inter 13 w600 sky, underline offset 2, `·` U+00B7, each min 44×44). App: absent. Fix: wire `NestBottomCta` + CTA + caption + `_LegalRow` per plan.
8. Bottom edge (OWNER RULE) — design/rule: surface colour from the bottom bar runs to the physical edge; no paper/meadow strip under bar or home indicator, light or dark. App: no bottom bar exists, so the rule cannot hold. Fix: add `NestBottomCta` wrapping `SafeArea(top: false)`; never add page-colour padding below it.
9. Alignment (OWNER RULE) — design: consistent 20px side gutters, cards/bars on same edges. App: Material defaults (AppBar + ListTile insets), not 20px gutters. Fix: `ListView(padding: fromLTRB(20,0,20,32))` + shared 20px edges.
10. Colours / radii / shadows / icons / dark mode — design: paper/surface/surface-2, leaf border + leaf-tint ticks/dots, leaf CTA, sky links, r24 cards + pill CTA, sh-1, Lucide-style 2px-stroke icons; dark tokens per SPACING_SPEC §0. App: placeholder Material greys, no cards, no ticks, no CTA, no links. Fix: tokens only, verify both themes.
11. Copy defect (already filed as P07-BUG-3) — design caption `£29.99/year after the 14-day trial.` App `ListTile` detail `£29.99/year after 14-day trial.` (drops `the`). Fix: insert `the` at repository source.
12. Orchestrator mandatory item 1 — trial/Restore must call `AppSession.startTrialNow()` (+ `completeOnboarding()`) / `setSubscription('active')` (+ `completeOnboarding()`) then go `/today`. App: no CTA exists, no events/state (`PaywallTrialStarted`/`PaywallRestoreRequested` absent), so the handoff is unmet. Fix: implement plan §b–c (via `GetIt.instance<AppSession>()`, not `context.read`).
13. Status bar — app shows live `21:08/21:09` vs design mock `9:41`. Not a finding per orchestrator rule; ignored.

No spacing ±2px check is possible — there are no corresponding elements to measure. No overflow/clipping to assess for the same reason. DATA OVER MOCKS / PERIODS / CHILD ORDER: not exercised (P07 shows no DB numbers; copy fixity `James` holds trivially since no child names render).

## Verdict basis

Stage 5 passes only with no visible deviation a designer would reject. The screen is the untouched placeholder: hero, title, benefits, plan card, timeline, family note, CTA, caption, and legal row are all missing in light and dark. The mean diffs (9.92% / 9.44%) confirm wholesale mismatch, peaking at the CTA band.


## From 6_bugs.md
# P07 Paywall — bug hunt (Stage 6, iteration 1)

Adversarial test pass over the P07 feature as it exists on this branch:
`app/lib/features/paywall/**` (placeholder view, load-only bloc, Drift
repository, route), the router guard and session handoff, and the design
sources (`design/html-source/screens/P07-paywall.html`,
`design/screens/{light,dark}/P07-paywall.png`, `docs/DESIGN_SPEC.md:158`,
`docs/screens/P07/1_plan.md`, `docs/screens/P07/ORCHESTRATOR_NOTES.md`).

**Headline: the screen is still the foundation placeholder.** Every designed
element is absent, the trial/restore path does not exist, and the trial the
screen is supposed to start can never expire. The bug-proof tests live in
`app/test/features/paywall/p07_bugs_test.dart`, one group per bug id, all
`skip: true` with the bug id in the test name so the suite stays green while
the defects are open (this SDK's `testWidgets`/`test` `skip` parameter is
`bool?`, so the id lives in the test name rather than the skip string;
`flutter test test/features/paywall/` → `+24 ~12 −43`, the −43 being stage 3's
pre-existing red contract suite).
`flutter test test/features/paywall/p07_bugs_test.dart --run-skipped` fails
all 12 bug tests for exactly the reasons below; the four “verified clean”
baselines in the same file pass.

## Bug summary

| # | Severity | One line | Failing test(s) |
|---|---|---|---|
| 1 | Blocker | The paywall screen does not exist (placeholder only) | `[P07-BUG-1] the design surface renders at /paywall` |
| 2 | Blocker | No trial/restore path; P07 dead-ends onboarding (ORCHESTRATOR_NOTES 1 unmet) | three `[P07-BUG-2]` tests |
| 3 | Major | `NestBottomCta` cannot render the design order (CTA → caption → legal row) | `[P07-BUG-3] CTA, then caption, then legal row — all inside the bottom bar` |
| 4 | Minor | Plan caption drops “the” (`after 14-day trial`) | `[P07-BUG-4] the repository caption is the design’s wording` |
| 5 | Minor | Plan detail is not the design copy (stray full stop, sub+caption merged, tag dropped) | two `[P07-BUG-5]` tests |
| 6 | Minor | `PaywallState.copyWith` cannot clear `errorMessage`; stale error survives a retry | `[P07-BUG-6] errorMessage is cleared when the reload succeeds` |
| 7 | Minor (latent) | Repository trial/restore writes are UPDATE-only, not upserts | `[P07-BUG-7] startTrial records the trial even if the row is missing` |
| 8 | Major (shared) | The 14-day trial never expires — router guard unreachable | `[P07-BUG-8] a trial started 15 days ago must not keep giving access` |
| 9 | Minor (shared) | Kid mode + onboarding-incomplete deep link ends on /welcome, not the gate | `[P07-BUG-9] a kid-mode deep link to /paywall lands on the parental gate` |

---

### P07-BUG-1 — Blocker — the paywall screen is not implemented

**Where:** `app/lib/features/paywall/presentation/views/paywall_view.dart:9-42`
(`AppBar('P07 Paywall')` at :12, `Text('No items yet')` at :25, `ListTile` at
:31).

**Repro:** `cd app && flutter test test/features/paywall/p07_bugs_test.dart
--run-skipped --plain-name '[P07-BUG-1]'` → `Expected: no matching candidates /
Actual: Found 1 widget with text "P07 Paywall"`. Pump `/paywall` at 390×844 and
the screen shows a Material app bar and one `ListTile` whose subtitle is the
repository plan string. The design has: compact nav with the 44×44 close
button, hero (`PipAvatar` mochi/sunny stage 4 in the nest, 3 coins), the h1
`Try Nestling free for 14 days`, the 4 benefit rows, the leaf-bordered annual
plan card (radio, title, sub, tag), the `What happens next` timeline, the
family note, `NestBottomCta` with `Start free trial`, the caption, and the
`Restore purchases · Terms · Privacy` row.

**Rule impact:** orchestrator PIP (no `PipAvatar` anywhere), COPY, ALIGNMENT
and BOTTOM EDGE are all unimplemented; the stage 5 comparison already showed
the whole surface missing in light and dark.

**Suggested fix:** implement `docs/screens/P07/1_plan.md` §a in full
(feature-private widgets; tokens only). The stage 3 widget contract
(`paywall_view_test.dart`) is the checklist.

### P07-BUG-2 — Blocker — no trial/restore path; onboarding cannot complete

**Where:** `presentation/bloc/paywall_event.dart:10` (only
`PaywallLoadRequested`), `paywall_bloc.dart:9` (only `_onLoadRequested`),
`paywall_state.dart:4,13` (no action field). The mandatory orchestrator note
(`docs/screens/P07/ORCHESTRATOR_NOTES.md:1`) requires
`AppSession.startTrialNow()` + `AppSession.completeOnboarding()` before
navigating to Today.

**Repro:** `--run-skipped --plain-name '[P07-BUG-2] Start'` → `tap()` finds 0
widgets with text `Start free trial`. Tapping the (missing) CTA can therefore
never write `app_state`, never call the session, and never reach `/today`; P07
is a dead end and a restart would land back at `/welcome` (the P01 BUG-4
class).

**Tests:** `[P07-BUG-2] Start free trial completes onboarding and lands on
/today` (expects `onboarding_complete=true`, `subscription_status='trial'`,
`trial_start` set with `Europe/London`, path `/today`),
`[P07-BUG-2] Restore purchases activates (never downgrades) and lands on
/today`, and `[P07-BUG-2] a rapid double tap starts one trial and navigates
once` (two taps with no frame between must not double-navigate or throw from a
disposed context).

**Suggested fix:** per `1_plan.md` §b–c: add `PaywallTrialStarted` /
`PaywallRestoreRequested` and a `PaywallAction` discriminator; trial =
`repository.startTrial()` + `session.startTrialNow()` + `completeOnboarding()`;
restore = `repository.activate()` + `session.setSubscription('active')` +
`completeOnboarding()`; then `context.go(TodayRoutePaths.today)`. Use
`GetIt.instance<AppSession>()` (it is **not** a Provider ancestor —
`app/lib/app/app.dart:45-53`), guard the listener with `context.mounted`, and
ignore success while `action == working` so a double tap is a no-op.
Build note: the constant is `PocketMoneyRoutePaths.setup`, not
`.pocketMoneySetup` (`app/lib/features/pocket_money/pocket_money_routes.dart:13`).

### P07-BUG-3 — Major — the bottom bar cannot render the design's order

**Where:** `app/lib/core/design_system/components/nest_bottom_cta.dart:19-48`
renders `child` first and its optional `caption` last; there is no slot after
the caption. `1_plan.md` §a.4 (and `P07-paywall.html:103-113`) require
`Start free trial` → caption → `Restore purchases · Terms · Privacy`, all
inside the bar. A build that follows the plan literally cannot place the legal
row after the caption; a build that passes `child: Column(button, legalRow)`
renders the legal row **above** the caption.

**Repro:** `--run-skipped --plain-name '[P07-BUG-3]'` → fails finding the
elements (nothing built), and the order assertions pin the requirement:
`cta.bottom ≤ caption.top ≤ legal-row.top`, with the links inside
`NestBottomCta`.

**Suggested fix:** build the bar content locally as
`NestBottomCta(child: Column(button, caption, _LegalRow), caption: null)`
using `NestType.caption` for the caption text (screen-private, no core edit),
which keeps the component's `DecoratedBox` + `SafeArea` bottom-edge guarantee.
If a shared footer slot is preferred instead, file a SHARED_REQUEST for
`nest_bottom_cta.dart` — do not re-implement the bar's surface in the feature.

### P07-BUG-4 — Minor — the plan caption drops the article “the”

**Where:** `app/lib/features/paywall/data/paywall_repository_impl.dart:52-54`
→ `'£29.99/year after 14-day trial.'`. The design's `.caption`
(`P07-paywall.html:105`) is `£29.99/year after the 14-day trial. Cancel
anytime in Settings.` — the HTML is the copy source of truth (orchestrator
COPY rule; `DESIGN_SPEC.md:158` paraphrases without “the”, the HTML wins).

**Repro:** `--run-skipped --plain-name '[P07-BUG-4]'` →
`Actual: 'Just £2.50 a month, billed yearly. £29.99/year after 14-day trial.
Cancel anytime in Settings.'` (does not contain `after the 14-day trial`).

**Suggested fix:** insert `the ` at `paywall_repository_impl.dart:54`.

### P07-BUG-5 — Minor — the plan detail is not the design copy

**Where:** `paywall_repository_impl.dart:48-56`. Three defects in one string:

1. the sub gains a full stop the design does not have — HTML `:86` is
   `Just £2.50 a month, billed yearly` (no `.`); the repository writes
   `billed yearly. `;
2. the sub and the CTA caption are concatenated into `detail`, so a consumer
   rendering `detail` as the sub prints the caption too;
3. the card's third line `One price, the whole family` (`P07-paywall.html:87`)
   has no data source at all — `detail` drops it, so the plan card would have
   to hard-code it.

**Repro:** `--run-skipped --plain-name '[P07-BUG-5]'` → both tests fail:
`Expected: not contains 'billed yearly.'` and `Expected: contains 'One price,
the whole family'`.

**Suggested fix:** give `PaywallPlan` a `tag` field (feature-local entity) and
store the sub exactly as the design writes it; keep the caption out of
`detail` or expose it as its own field. If the view renders the three strings
statically per `1_plan.md` §d, still fix `detail` so the data layer cannot
leak wrong copy to a future consumer.

### P07-BUG-6 — Minor — a stale error survives a successful retry

**Where:** `paywall_state.dart:17-27` — `copyWith` can set `errorMessage` but
never reset it to `null`. Sequence: load fails (`errorMessage='Exception:
offline'`) → retry succeeds (`status: loaded`) → the failure message is still
in the state, so any future action-failure toast/UI can surface a stale error.

**Repro:** `--run-skipped --plain-name '[P07-BUG-6]'` →
`Expected: null / Actual: 'Exception: offline'`.

**Suggested fix:** add an explicit clear path — e.g.
`copyWith({bool clearError = false})` or a dedicated
`PaywallState.loaded(...)` constructor used by `_onLoadRequested`'s `onData`
that starts from a clean state.

### P07-BUG-7 — Minor (latent) — repository writes are UPDATE-only

**Where:** `paywall_repository_impl.dart:30-39` (`startTrial`) and `:41-46`
(`activate`) do `update(appState)..where(id = 1)` with no insert fallback.
`AppSession._write` (`core/data/app_session.dart:67-76`) upserts because a
real first install has no seeded row (P01 BUG-4). Today
`AppDatabase.migration.beforeOpen` (`app_database.dart:341-367`) guarantees the
row, so this is not reachable through normal seeding — but the repository is
one schema/launch path away from the same silent no-op: 0 rows written, yet
the user is navigated to `/today` with no subscription recorded.

**Repro:** `--run-skipped --plain-name '[P07-BUG-7]'` — delete the row, call
`startTrial()` → `Expected: not null / Actual: <null>` (no row written).

**Suggested fix:** mirror `AppSession._write`: after `write(companion)` returns
0, insert `companion.copyWith(id: Value(1))`.

### P07-BUG-8 — Major (shared) — the 14-day trial never expires

**Where:** nothing in `app/lib` ever writes `subscription_status = 'expired'`
(`grep -rn "'expired'" app/lib` → only the readers
`core/data/app_session.dart:27` and
`features/paywall/domain/entities/subscription_status.dart:10`). The router's
guard `router.dart:90-93` (`onboarded && session.trialExpired → /paywall`) is
therefore dead code: a trial started by P07 (or seeded `trial` with a
`trial_start`) keeps full access forever, and the paywall never returns. The
design is explicit: `Day 14 — £29.99 billed — cancel any time`.

**Repro:** `--run-skipped --plain-name '[P07-BUG-8]'` — start a trial, backdate
`trial_start` 15 days, pump `/today` → `Expected: '/paywall' / Actual:
'/today'`.

**Suggested fix (shared, needs SHARED_REQUEST):** make expiry real — compute
`trialExpired` from `trialStart + 14 calendar days` in the family zone using
`london_time.dart` (a UTC `+ Duration(days: 14)` is wrong across the October
BST→GMT change and is the timezone trap for this screen), or persist
`'expired'` at launch; then the existing router redirect works. Owner:
`core/data/app_session.dart` + `app/launch.dart`.

### P07-BUG-9 — Minor (shared) — kid-mode guard order during onboarding

**Where:** `app/lib/app/router.dart:83-118`. For a kid-mode app that is **not
yet onboarded**, `/paywall` redirects to the parental gate, but the gate
location is then re-evaluated by the onboarding rule (`!onboarded && !in
_onboardingLocations` → `/welcome`), and `/welcome` is itself parent-only, so
the chain terminates on `/welcome` (P01's parent marketing screen) instead of
the gate. Onboarded kid mode is correct (`/paywall` → `/parental-gate`).

**Repro:** `--run-skipped --plain-name '[P07-BUG-9]'` → `Expected:
'/parental-gate' / Actual: '/welcome'`.

**Suggested fix (shared):** evaluate the kid-mode branch before the onboarding
branch, or exempt `ParentalGateRoutePaths.gate` from the onboarding redirect.
Low reachability (APP_MODE=kid during onboarding), hence minor.

---

## Verified clean (not bugs)

- **Deep links, parent mode:** `/paywall` is reachable with `Seed.fresh`
  (onboarding incomplete) and stays open for an onboarded demo app; the close
  target `/pocket-money-setup` is an onboarding location, so both entry paths
  are consistent. Baselines in `p07_bugs_test.dart`.
- **Kid-mode guard (onboarded):** `/paywall` → `/parental-gate`; no parent-only
  bypass in the realistic combination.
- **Restart persistence:** after `startTrialNow()` + `completeOnboarding()`, a
  fresh `AppSession` over the same database reads onboarding complete, status
  `trial`, `trial_start` set, zone `Europe/London` — the data layer would
  survive a restart once BUG-2 writes through it.
- **Dark-mode contrast (tokens, computed):** dark sky `#7FA9FF` on surface
  `#1F1C2E` = 7.14:1, dark leafInk `#8EE6BC` on leafTint `#173A2B` = 8.47:1,
  ink2 on surface = 9.82:1, separators 6.19:1; light sky `#2563D6` on surface
  `#FFFFFF` = 5.48:1, leafInk on leafTint = 7.12:1 — all ≥ 4.5:1 for the 13px
  links.
- **Money rounding / integer pence:** P07 does no arithmetic — the £29.99 and
  £2.50 strings are static copy and the screen reads no ledger rows, so
  pence-rounding and BST money bugs are not applicable here.
- **Data edge cases (0/1/6 children, long names, £0.00, 9999 coins):** not
  applicable — P07 renders no child or money data (plan list is static, one
  entry); the stage 3 suite pins demo/empty/fresh to an identical screen and
  forbids `Maya`/`Leo` leaking in.
- **Rapid double tap:** no implementation exists to double-fire (BUG-2); the
  contract test in BUG-2's group pins single navigation + no disposed-context
  throw for when it lands.
- **Status bar, `NestStatusBar` height-only, text-scale 1.3 / width 320,
  bottom-edge pixels, 20px gutters:** all are stage 3/5 contracts and cannot
  be independently re-verified while the surface is absent (BUG-1).

## Verdict basis

P07-BUG-1 and P07-BUG-2 are blockers: the screen does not exist and its only
purpose — starting the trial and finishing onboarding — is unimplemented.
P07-BUG-3 is a major build trap in the design-system API, and P07-BUG-8 is a
major product hole (a trial that never ends). The minor findings (4–7, 9) are
real and each has a failing proof test. “No major bugs” does not hold.

