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

VERDICT: FAIL