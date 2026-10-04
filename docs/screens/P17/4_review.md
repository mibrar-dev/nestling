# P17 Parental gate — QA code review (stage 4, iteration 4)

Scope: `git diff main...HEAD` for `screen/P17` (14 non-docs files + `docs/screens/P17/**`),
reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P17
(line 160) + the kid rules (line 186), the P17 HTML source, the shared design system in
`app/lib/core/design_system/`, and every owner/orchestrator rule in the stage brief
(`ORCHESTRATOR_NOTES.md` items 1–7 and 11 are mandatory). No code was edited.

The iteration-4 builders changed the view only (2b: card centring, single caption owner,
`Try again` 44→56, a real `Back to Pip` escape while loading, P17-BUG-1 un-skipped), and
`2a` changed nothing in `app/`. Findings 3, 4 and 6 of the iteration-3 review are therefore
closed and I re-reviewed the whole diff rather than only the delta.

## Verified independently this iteration

| Check | Result |
|---|---|
| `flutter analyze` (whole app) | 10 issues — **all 10 in `test/features/parental_gate/p17_probe_iter4_test.dart`**, an *untracked* scratch file from the concurrently-running bugs stage (undocumented `// ignore: avoid_print`, unused import). **Every committed file analyzes clean.** The probe has since been deleted by that stage. |
| `dart format --output=none --set-exit-if-changed lib/features/parental_gate test/features/parental_gate test/core/family_time_test.dart` | clean for all committed files (the same untracked probe was the only "changed" file, now deleted) |
| `flutter test` — bloc + geometry + repository + states (4 of 6 feature files; the 2 the concurrent bugs stage was editing were excluded) | **+75: All tests passed!** |
| `flutter test` on a temp copy of **main's** `app/test/core/family_time_test.dart` | **+22: All tests passed!** → the out-of-scope edit in finding 1 is obsolete (evidence below) |
| Diff path audit | 12 of 14 non-docs paths are inside §1; **2 are not**: `app/test/core/family_time_test.dart` and `docs/screens/_shared/family_time_test_fix_REPORT.md` (finding 1). `app/lib/core/**`, `app/lib/app/**`, `tools/**`, `pubspec.*`, `analysis_options.yaml` untouched. |
| `5_ui.md` (iteration 4, concurrent stage) | mean diff **1.37 % light / 1.44 % dark**; card top 66.0/66.0, bottom 777.7/777.7, x24 w342/342, title 164.0/164.0, keypad rows 344/426/508/590.3 all Δ0, cancel +1.7 — every ORCHESTRATOR_NOTES band inside ±2 px |

Owner-rule sweep (all clean, no finding): PIP from the DB via `PipAvatar`
(`style/skin/accessory/stage` per child; the no-child fallback is
`PipAvatar(style: mochi, stage: 3)`, whose default `skin` is `sunny` — the onboarding
analogue), never a `pip_stage_*.svg`; CHILD ORDER (`db.watchChildren` in DB order, fallback
`kids.first`, never alphabetical); no `google_fonts`/`GoogleFonts` in `lib` **or tests**; no
`letterSpacing` added (P17's CSS sets none — `NestType` defaults stand); no
`NestBalancedText` (P17 uses `.h2/.h3/.body-s/.caption`, all excluded by the rule, and the
backdrop greeting is `.kb-hi`, not `.h1`); no `subscription_status` write; **no
`DateTime.now()` anywhere in `features/parental_gate/lib`**; BOTTOM EDGE n/a (no bar) with
the scrim + shared `KidScope` meadow full-bleed and pinned (`states_test.dart:283`); ALIGNMENT
— card x24 w342, no stray gutters; copy is character-exact against the HTML source
(`Grown-ups only`, `Type the answer in numbers:`, `Back to Pip`,
`This keeps settings and purchases safe.`, `Parental gate`, `Number pad`, `Delete`), UK
spelling, no curly punctuation invented on this screen; Children's Code — no network, ads,
analytics, `print()` or telemetry in the feature, no child data leaves the device, coins only
(never £), and a wrong answer is announced politely (`That wasn’t right — try again`, curly
U+2019) with no red/danger styling.

Accessibility re-check against the framework source (`rendering/object.dart:5703`
`shouldFormSemanticsNode`, `paragraph.dart:1233` where `RenderParagraph` is a boundary): the
modal's `Semantics(explicitChildNodes: true)` propagates `explicitChildNodes` down through
every non-annotated ancestor (`object.dart:5809-5815`), so the digits group, the `Number pad`
group and all 11 key nodes each form their **own** semantics node — the state label
`Answer, n of m entered` really is announced, and the `find.bySemanticsLabel` assertions in
the suite are not passing on a merged node. Every control (10 digits + delete + `Back to Pip`
+ `Try again`) exposes `SemanticsAction.tap` and the tests both assert `hasAction` and
`performAction` a real state/navigation change; the `excludeSemantics: true` wrapper is a
display-only group, so no `onTap:` passthrough is owed. The decorative lock tile emits no
semantics (`NestIcon` passes `semanticsLabel: null` → no node), matching the HTML's
`aria-hidden="true"`; the dimmed backdrop is `ExcludeSemantics`d like the HTML's
`aria-hidden` `.kid-bg`.

## Findings

1. **major** — out-of-§1 shared-file edit, and it is now **provably obsolete**.
   `app/test/core/family_time_test.dart` (+54/−8) and
   `docs/screens/_shared/family_time_test_fix_REPORT.md` (new, 100 lines) are in the diff;
   neither path is inside `app/lib/features/parental_gate/**`,
   `app/test/features/parental_gate/**` or `docs/screens/P17/**`, and neither is cited in
   `SHARED_REQUEST.md`. This has been carried for three iterations — the iteration-3 review
   rated it *minor* on the grounds that the repair was genuinely needed. **That is no longer
   true, and this review has the proof.**
   - The repair was made on a branch whose base predates main's `72b703b`
     ("Pin one app clock to the seed story day") — `git merge-base --is-ancestor 72b703b
     48978d4` → **not an ancestor**. `72b703b` is on `main`
     (`git diff main...HEAD -- app/lib/core/data/app_clock.dart` is empty) and makes
     `appNowUtc()` return the **seed anchor instant** whenever `Seed.anchorOverride` is set,
     which `test/flutter_test_config.dart` always sets. So `completeQuest` now
     *deterministically* takes the in-place branch and main's `.single` assertion holds again,
     on any real date.
   - Proven, not argued: `git show main:app/test/core/family_time_test.dart` into a scratch
     copy and `flutter test` it on this tree → **`+22: All tests passed!`**, including
     `kid_home completions are stamped with the family zone` (scratch copy deleted).
   Fix (restore compliance, keep the suite green):
   ```bash
   git checkout main -- app/test/core/family_time_test.dart
   git rm docs/screens/_shared/family_time_test_fix_REPORT.md   # or move it to docs/screens/P17/
   cd app && flutter test test/core/family_time_test.dart        # expect +22
   ```
   The report's *content* (the `.single`-over-seeded-rows trap for future shared tests) is
   worth keeping — relocate it under `docs/screens/P17/` so the knowledge stays inside §1.

2. **minor** — `parental_gate_view.dart:46` and `:67`: `Navigator.of(context).canPop()` is the
   **only** such call in the app — the other seven feature views (`create_account_view.dart:49`,
   `approvals_view.dart:69`, `privacy_consent_view.dart:48`, `paywall_view.dart:29`,
   `rewards_view.dart:43`, `payout_view.dart:181`) use go_router's `context.canPop()`, which
   also honours `PopScope` registrations and the router's own stack knowledge. On the gate this
   decides *pop back to the kid screen* vs *`go` to `/today`*, i.e. the whole unlock path.
   Fix: `final canPop = context.canPop();` in both helpers.

3. **minor** — `parental_gate_view.dart:533`: the typed digit renders with
   `NestType.h1` = **28/34**, but the CSS is `.digit { font-size:28px; line-height:1 }`
   (`P17-parental-gate.html:24`). In the fixed 64 px box the design's line box is 28 and the
   app's is 34, so the glyph sits **3 px** lower than the design — over the owner's ±2 px
   band. The design system already has the precedent for a `lh 1` case
   (`NestType.coinPill()` — "Nunito 16 w800 lh 1"), and the letter-spacing rule's
   call-site `copyWith` route applies here. The `5_ui` check could not see it (the shot had no
   digit typed, so the design's filled "4" had nothing to compare against).
   Fix: `Text(entered[i], style: NestType.h1(color: tokens.ink).copyWith(height: 1))`, then
   re-shoot with one digit typed and re-measure.

4. **minor** — `parental_gate_view.dart:317-319`: the `.gate-note { margin-top: 10px }` gap is
   spelled `NestSpacing.s2 + NestSpacing.gap2` (= 8 + 2 = 10) while `NestSpacing.gap10 = 10`
   exists and `NestKeypad` uses it for the same CSS 10 px. Two tokens added to reach one
   documented value is exactly the "tokens only" smell the spacing scale exists to prevent.
   Fix: `height: NestSpacing.gap10` (and the `reason:` string in
   `parental_gate_states_test.dart:225` still reads correctly).

5. **minor** — `parental_gate_view.dart:83` and `:170`: `current.items != previous.items`
   compares `List` by **identity**, so every Drift re-emission (any `settings` write, and
   `watchItems` builds a fresh list per event) fires the `BlocListener` and rebuilds the inner
   `BlocBuilder` even when the content is unchanged. Harmless today (the listener body is
   idempotent and `_didPassThrough` guards the navigation) but it is exactly the
   "no rebuild storms" rule in miniature.
   Fix: `listEquals(current.items, previous.items)` in both predicates
   (`import 'package:flutter/foundation.dart';`).

6. **minor** — `parental_gate_view.dart:55` and `:61`:
   `unawaited(session.setAppMode('parent').then((_) => session.refresh()))` has no error
   path. `AppModeController.selectMode` has already flipped the in-memory mode, so a failed
   DB write leaves the session on `kid`: the next launch routes the child straight back to
   the gate with no explanation, and the rejection surfaces as an unhandled async error
   (which would also fail any future test that stubs the write).
   Fix: `.then((_) => session.refresh(), onError: (Object e, StackTrace s) { ... })` — log via
   `debugPrint` in debug and still `session.refresh()` so memory and storage re-converge.

7. **minor** — `data/models/parental_gate_challenge_model.dart` is dead weight: nothing in
   `lib` imports it; its only reference is its own round-trip group in
   `parental_gate_repository_test.dart:83-93`. P17 owns the file, so unlike the repo-wide
   scaffold it can just go. Fix: delete the model and its test group, or wire the model into
   `ParentalGateRepositoryImpl`'s serialisation so it earns its place.

8. **minor** — magic numbers with no token, all copied verbatim from the P17 CSS:
   `28` (`.kid-bg` side padding, `:408`), `26` (`.kb-pet` margin, `:430`), `52`/`26` (lock
   tile + icon, `:492-493`/`:499`), `56`/`64`/`3`/`2` (digits, `:521-522`, `:535-537`),
   `200` (Pip slot, `:433`/`:439`). `NestSpacing` covers 2/3/5/6/7/9/10/14 and the 4-pt scale
   but not 26/28/52/56/64, and adding them to `core/design_system/tokens/spacing.dart` is a
   shared edit a screen agent may not make. Two of them (26, 28) are part of the kid header
   block (`.kid-bg/.kb-top/.kb-pet`) that K01/K03/K04/K05 all draw, so they are genuinely
   shared metrics.
   Fix: file a `SHARED_REQUEST` for `gap26`/`gap28` (and a `.lock-tile`/`.digit` metrics
   holder like the existing `NestPager`) rather than letting each kid screen invent its own
   literals. Nothing here changes a measured band; the numbers are correct.

## Notes (not findings, and why)

- **View reads the database directly** (carried from iteration 3 as finding 2, still the only
  view in the app that does it — `rg` for `GetIt.instance<AppDatabase>` under
  `features/*/presentation/` matches `parental_gate_view.dart` alone).
  `parental_gate_view.dart:361-367` resolves `AppSession` + `AppDatabase` from `GetIt` and
  runs its own `db.watchChildren(Seed.familyId)` `StreamBuilder`, mapping
  `pip_style/skin/accessory` into `PipAvatar` in the view; `AppSession`/`AppModeController` in
  a view *is* precedented (`paywall_view.dart`), `AppDatabase` is not. I am keeping this at
  minor rather than major because `1_plan.md` §(b) — a MUST-FOLLOW input — mandates "no new
  repository methods", so a fix requires amending the plan first, and because it is dimmed,
  `ExcludeSemantics`d scenery. The real fix if the orchestrator wants it: add
  `Stream<ParentalGateChild?> watchActiveChild()` to the abstract repository (impl in
  `data/`, keeping the active-child-then-first-in-DB-order resolution there), fold it into
  `ParentalGateBloc` state, bind the view to state — and, on `main`, extract K03's inline kid
  header into a shared widget so P17/K01/K03/K04/K05 stop drawing it four times.
- **Retry stacks a live `emit.forEach` subscription** (carried, iteration-3 finding 5).
  `_onLoadRequested` never returns and bloc's default transformer is concurrent, so each
  `Try again` opens a second Drift subscription whose `onError` can still flip the card back
  to `failure` after a successful retry. Unreachable without a DB error, so no test can hit
  it today. Fix stays a private `int _loadGeneration` guard in the bloc (no dependency
  needed; `bloc_concurrency` is not in `pubspec.yaml`).
- **`parental_gate_placeholder_card.dart` is unreferenced** — but so are 14 byte-identical
  copies across other features (the repo-wide v1 scaffold). Deleting only P17's would make
  this feature the odd one out; leave it (see finding 7 for the file that *does* deserve to go).
- **An open gate keeps its question across London midnight** — `watchItems()` re-emits only
  on a `settings` write, so nothing re-keys the challenge at 00:00. Low impact for a
  seconds-long interaction; no test pins it. Unchanged since iteration 2.
- **Iteration-4 UI measurement**: all 11 ORCHESTRATOR_NOTES geometry pins plus the scrim
  `(0,0)→edge` barrier pin are green in the committed suite, and `5_ui` reports every design
  band within ±2 px in both themes — the visual state of this screen is good.

## Verdict

One **major** (finding 1: an out-of-§1 edit to a shared core test plus a report in
`docs/screens/_shared/`, now proven obsolete by main's `72b703b` clock pin and by re-running
main's own file: `+22 All tests passed!`). Its fix is a `git checkout main --` on one file, a
`git rm` on the report and one re-run of the core suite — after which the diff is entirely
inside §1 and the branch needs no orchestrator action at all. Everything else on this screen
is minor or informational: the feature suite is green, `flutter analyze` is clean for every
committed file, the design-system components are reused (no local re-implementation of the
keypad, modal, pill, avatar or Pip), the accessibility contract is met and verified against
the framework's own node-forming rules, and the UI matches the design band for band.

VERDICT: FAIL
