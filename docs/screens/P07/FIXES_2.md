# Fix list after iteration 2

## From 3_test.md
# P07 Paywall — test report (Stage 3, iteration 2)

## Summary

The screen now exists. Iteration 1's 63-test contract suite turned red against
a placeholder; after the iteration-2 build (`paywall_view.dart` is 808 lines,
the bloc has the trial/restore events and `PaywallAction`/`PaywallRequest`,
the repository upserts and its copy matches the HTML) **the whole suite is
green**, and this iteration added 8 further tests for the paths the build
introduced.

**One real bug was found and recorded, not patched** (stage 3 may not edit the
screen): on the expired-trial paywall the close button is a no-op — P07-BUG-10.
Per the stage brief, `VERDICT: PASS` requires all tests passing *and* no bugs
found, so this iteration is a FAIL with a green suite.

| Run | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 367 files, 0 changed |
| `flutter analyze` (the 3 committed paywall test files) | **No issues found!** |
| `flutter test test/features/paywall/paywall_bloc_test.dart` | **+25** all passed |
| `flutter test test/features/paywall/paywall_view_test.dart` | **+53 ~1** all passed |
| `flutter test test/features/paywall/p07_bugs_test.dart` (stage 6) | **+14 ~2** all passed |
| `flutter test` (whole app) | **+742 ~3: All tests passed!** |

The 3 skips are all recorded defects with proof tests, by stage convention
(`6_bugs.md`: skipped while the defect is open, unskipped when fixed):
`[P07-BUG-8]` and `[P07-BUG-9]` (shared code, filed in
`docs/screens/P07/SHARED_REQUEST.md`) and `[P07-BUG-10]` (this stage, below).

## Tests added this iteration (all in `paywall_view_test.dart`)

The action events (`PaywallTrialStarted` / `PaywallRestoreRequested`,
`PaywallAction`, `PaywallRequest`, `copyWith(clearError:)`) landed with the
build, so the follow-up deferred in iteration 1 is now covered by
`paywall_bloc_test.dart`'s `PaywallBloc trial and restore actions` group
(working → success, failure + message per request, `startTrial` vs `activate`
delegation). Those tests were verified green, not rewritten. The 8 tests below
are new:

| Test | What it pins |
|---|---|
| `the hero scales down at 320dp` / `390dp` / `430dp` | the hero's fixed 350×148 frame scales as `min(w/350, 1)`: Pip's slot is 96px at 320, 120px at 390 and 430 (never upscaled), and the scene stays inside the 20px gutters |
| `Restore purchases never starts a trial` | the restore handoff writes `active` only — `trial_start` must still be `null`, proving `startTrialNow()` did not run on that path |
| `a failed trial toasts in place and stays on /paywall` | action failure: toast with the reason, no navigation, no `app_state` write, and the same CTA still works on retry (then `/today`, `onboarding_complete`, `trial_start` set) |
| `the CTA is disabled and spinning while the trial is in flight` | `working`: `NestButton.onPressed == null`, `loading == true`, `Restore purchases` loses its tap action, and a second tap never starts a second trial (one tap → one `startTrial()`) |
| `a restore request never shows the trial spinner` | `loading` belongs to the trial pill only — a restore never claims a trial is running |
| `an expired trial sends /today to the paywall` | the `trialExpired` guard (router.dart:90-93) with `subscription_status = 'expired'`: `/today` redirects to `/paywall` and the paywall renders — the only reachable shape of that guard today |
| `[P07-BUG-10] close escapes the expired-trial paywall` | **skipped proof** for the bug below |
| `tapping the plan card changes nothing` (strengthened) | scrolls the card into view first (the old tap never hit it and emitted a hit-test warning), then taps it and asserts the plan stays `selected: true` and nothing navigated |

Supporting changes to the test file only: the fake repository gained
`failTrial` and a `trialGate` `Completer` (to hold the screen in `working`), and
`_useFakePaywallBloc()` re-registers the DI `PaywallBloc` factory so the *whole
app* — router, session, navigation — can be driven by a failing or hanging
repository. `_pumpPaywall` gained a `route` parameter for the guard test.

## Bugs found

### P07-BUG-10 — major (latent today, trap once P07-BUG-8 lands) — the close button cannot leave the expired-trial paywall

**Where:** `app/lib/features/paywall/presentation/views/paywall_view.dart:27-34`

```dart
void _onBack(BuildContext context) {
  if (!context.mounted) return;
  if (context.canPop()) {
    context.pop();                       // ← line 30
  } else {
    context.go(PocketMoneyRoutePaths.setup);
  }
}
```

With the router's expired-trial guard (`app/lib/app/router.dart:90-93`,
`onboarded && session.trialExpired && location != '/paywall' → '/paywall'`),
`/today` is *redirected* to `/paywall`. A GoRouter redirect replaces the target
but leaves `/today` on the navigation history, so `context.canPop()` is **true**
here — unlike the onboarding case the `else` branch was written for. Tapping X
therefore pops to `/today`, the guard immediately redirects back to `/paywall`,
and the screen is a trap: the parent can never dismiss the paywall. Only
starting a trial or restoring purchases gets them out.

**Repro:**
```
cd app
flutter test test/features/paywall/paywall_view_test.dart \
  --run-skipped --plain-name 'P07-BUG-10'
```
→ `Expected: not '/paywall' / Actual: '/paywall'`.

Device-equivalent: onboard a family, let the trial lapse, open `/today` (the
app redirects to the paywall), press the X — nothing happens, forever.

**Severity and reachability:** latent today, because nothing in `app/lib` ever
writes `subscription_status = 'expired'` (P07-BUG-8, shared, filed in
`SHARED_REQUEST.md`). The moment that shared fix lands, this becomes a
blocker for the expired-trial user. Flagged here so the two are fixed
together.

**Suggested fix (build stage — not applied by stage 3):** make the target
explicit rather than history-dependent, e.g. pop only when the popped route is
actually dismissible, or `context.go(PocketMoneyRoutePaths.setup)` whenever the
session reports `trialExpired` (the `else` branch already lands somewhere
legal). A test that asserts *which* destination an expired-trial parent should
see is a product decision for the orchestrator; the proof test only requires
"X leaves the paywall".

## Carried over from iteration 1 (all now green, nothing outstanding)

- The screen surface: hero, `PipAvatar(mochi, sunny, stage 4, inNest)` on the
  120px slot, h1, 4 benefits, plan card, timeline, family note,
  `NestBottomCta` + caption + legal row.
- Copy character-by-character against `P07-paywall.html`, including the caption
  article “the” (P07-BUG-3) and the plan tag (P07-BUG-5) — the build fixed both
  at the repository source.
- Light + dark, 320/390/430, text scale 1.0 and 1.3, no overflow.
- 20px gutters on cards, scroll and bar; the bottom edge reaching the physical
  screen edge with the bar's own surface (painted-pixel proof, both themes,
  including a 34px home-indicator inset).
- Semantics labels on every control, ≥44dp parent targets, no kid controls.
- `initial` / `loading` / `loaded` / `failure` + Retry, and an empty plan list
  that is never an empty state.
- ORCHESTRATOR_NOTES 1: trial → `startTrialNow()` + `completeOnboarding()` →
  `/today`; restore → `active` + `completeOnboarding()` → `/today`; close →
  `/pocket-money-setup`.
- Identical screen under `Seed.demo` / `empty` / `fresh`, with no seeded child
  names leaking (DATA OVER MOCKS).

## Notes for the next stage

1. **Open shared findings.** `[P07-BUG-8]` (the trial never expires) and
   `[P07-BUG-9]` (kid-mode guard order) live in `core/` and `app/` — filed in
   `docs/screens/P07/SHARED_REQUEST.md`, out of this worktree's edit scope.
   Their proofs stay skipped until the orchestrator lands them; P07-BUG-10
   becomes reachable at that moment.
2. **`google_fonts` is gone** and none of this feature's `lib/` or `test/` files
   import it or call `GoogleFonts.*` (verified by grep).
3. **Concurrent scratch file.** While this stage ran, the Stage 6 (bugs) agent
   created `app/test/features/paywall/probe_scratch.dart` (its own header says
   it is temporary and deleted before that report lands). It is not
   auto-collected by `flutter test` (no `_test` suffix), so the suite above is
   unaffected; it does currently produce 13 `flutter analyze` infos, all inside
   that one file. Nothing else in the repo has analyze issues. Not deleted here
   — it is another stage's in-flight work.

## Verdict basis

All tests pass (`+742 ~3`), `dart format` is clean and the three committed
paywall test files analyze clean. But stage 3 may only pass when **no bugs are
found**, and P07-BUG-10 is a real defect in the screen's back navigation,
recorded above with a proof test and a repro. The build stage should fix it
(with P07-BUG-8 in mind) and unskip `[P07-BUG-10]`.


## From 5_ui.md
# P07 Paywall — UI check (Stage 5, iteration 2)

Method (iPhone simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390×844):
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_light_2.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light fresh parent maya` → stable frame saved, EXIT 0
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_dark_2.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark fresh parent maya` → stable frame saved, EXIT 0
- `python3 tools/screens/compare.py design/screens/light/P07-paywall.png docs/screens/P07/ui/app_light_2.png docs/screens/P07/ui/cmp_light_2.png`
- `python3 tools/screens/compare.py design/screens/dark/P07-paywall.png docs/screens/P07/ui/app_dark_2.png docs/screens/P07/ui/cmp_dark_2.png`
- Sources: `design/html-source/screens/P07-paywall.html`, `1_plan.md`, SPACING_SPEC §§1–2/8, `ORCHESTRATOR_NOTES.md`. All pixel numbers below are logical px (screenshot ÷ 3). Status-bar text ignored per orchestrator rule.

## Mean diff

- Light: **11.43%** (bands: 0 0–105: 1.63% · 1 105–211: 3.52% · 2 211–316: 7.72% · 3 316–422: 7.37% · 4 422–527: 22.00% · 5 527–633: 16.79% · 6 633–738: 28.69% · 7 738–844: 3.88%)
- Dark: **9.78%** (bands: 0 0–105: 1.58% · 1 105–211: 2.47% · 2 211–316: 7.82% · 3 316–422: 7.65% · 4 422–527: 19.25% · 5 527–633: 14.03% · 6 633–738: 21.72% · 7 738–844: 3.80%)
- Bands 0–3 (nav, hero, title, benefits 1–3) match closely; all drift sits in bands 4–6 (4th benefit, plan card, CTA). The screen is fully built — the failures are two visible layout defects, not missing content.

## Deviations (design value → app value + fix)

1. **Major — legal row stacks vertically instead of one horizontal row.** Design (HTML `.legal-row`, flex, gap 2): `Restore purchases · Terms · Privacy` on a single centred row; sky link pixels sit on one band at y≈768–774. App: three full-width rows — `Restore purchases` at y≈615, `Terms` at y≈693, `Privacy` at y≈771 — with the `·` separators isolated on their own lines (ink dots at y≈575, ≈622). Root cause in `paywall_view.dart` `_LegalLink`: the chain `ConstrainedBox > Material > InkWell > Padding > Center > Text` sits inside a `Wrap`; `Center` (Align) expands to the Wrap run's full 350 px width, so every link occupies its own run. Fix: drop the expanding inner `Center` so the link sizes to its text (e.g. `InkWell > Padding > Text`), keeping the 44×44 min target from the outer `ConstrainedBox`; all three links + separators then fit one run at 390 dp as in the design.
2. **Major — bottom CTA panel ≈150 px too tall; CTA button 156 px too high.** Design: green CTA button y 646–697 (52 px). App: y 490–541 (52 px, correct size, wrong place). The panel top edge is dragged up by deviation 1's five stacked legal lines. Fix: follows from fixing 1 — with a single-row legal row the panel compacts to the design geometry (button ≈646).
3. **Major (consequence of 1–2) — 4th benefit and plan card hidden behind the CTA at top-of-scroll.** Design shows benefit rows 1–4 (last text band y 481–490) plus the plan card (leaf borders y 521–522 / 625–626) above the CTA. App: scroll content aligns exactly through row 3 (row-3 text band y 448 vs design 447), but row 4 (expected ≈481) is covered by the CTA panel and no plan-card border pixels are detected anywhere above the fold. The widgets exist in normal flow below (code order hero/title/benefits/plan/timeline/note is correct, presence covered by widget tests) — they are purely overlapped. Fix: same as 1; once the CTA compacts, design content bottom (plan border 625, panel top 630) fits exactly as drawn.
4. **Minor — title breaks with orphan “days”.** Design (HTML `class="h1 balance"`, `text-wrap: balance`): `Try Nestling` / `free for 14 days`. App (plain engine wrap, centred, same 2-line height y≈291/297–344): `Try Nestling free for 14` / `days`. No layout shift (identical block height), purely typographic. Fix is constrained: copy tests require the exact single string, so a hard `\n` would break `find.text`; either accept engine wrap or add balance support at the design-system level — do not touch the copy string.
5. **Not a finding — Pip rendering differs from the PNG.** Design shows the v1 `pip_stage_4.svg` songbird (with scarf); app renders `PipAvatar(style: mochi, stage: 4, inNest: true)`. The orchestrator PIP rule mandates `PipAvatar` and forbids v1 SVGs on product screens — the app is correct, the PNG is overridden. Hero geometry otherwise matches (circle/nest/coins positions and sizes align; hero ink rows y 250–280 identical).

## Owner / orchestrator checks

- **BOTTOM EDGE: PASS.** App last row = CTA surface in both themes (light 255,255,255 = surface; dark 31,28,46 = `#1F1C2E` surface). No paper/meadow strip under the bar or home-indicator area. (The design PNGs themselves show a paper strip there — the owner rule overrides the designs, and the app correctly does not reproduce it.)
- **ALIGNMENT: PASS** for visible content — nav, hero, title, benefits 1–3 share the design's 20 px gutters (bands 0–3 ≤ 7.8%, rows align to the pixel: row 3 at 448 vs 447).
- **COPY: PASS** — title, 3 visible benefits (curly ’ intact), CTA, caption (`…after the 14-day trial…` with `the`), links all character-correct vs HTML.
- **DARK COLOURS: PASS** — dark surface panel, leaf-tint ticks, leaf CTA, readable sky links; deviations are the same two layout items, nothing theme-specific.
- **FONTS: PASS** — no `google_fonts`/`GoogleFonts` in the view or feature tests (bundled-asset tokens used).
- **STATUS BAR:** ignored per rule (live time vs `9:41` mock).
- **ORCHESTRATOR_NOTES item 1** (trial/restore session handoff → `/today`) is behavioural, not visual; the CTA exists and the wiring is covered by stage 3/6 tests, not this check.

## Verdict basis

Two designer-visible defects at top-of-scroll in both themes: the legal links stacked as five full-width lines, and the oversized CTA panel swallowing the 4th benefit and the whole plan card. Everything else — nav, hero, title, benefits, CTA button, caption, bottom edge, gutters, dark theme — matches.


## From 6_bugs.md
# P07 Paywall — bug hunt (Stage 6, iteration 2)

Adversarial pass over the now-built P07 feature: `app/lib/features/paywall/**`
(808-line view, action bloc, Drift repository, route), the router guard and
session handoff, and the design sources
(`design/html-source/screens/P07-paywall.html`,
`design/screens/{light,dark}/P07-paywall.png`, `docs/screens/P07/1_plan.md`,
`docs/screens/P07/ORCHESTRATOR_NOTES.md`, `SHARED_REQUEST.md`).

**Headline: the screen is built and iteration-1 bugs 1–7 are fixed with green
proofs.** Iteration 2 found one **major latent** defect — the close button
cannot leave the expired-trial paywall (P07-BUG-10, found by stage 3 and
independently reproduced here) — plus two new **minor** bugs (P07-BUG-11,
P07-BUG-12). The two shared items from iteration 1 (P07-BUG-8 major,
P07-BUG-9 minor) remain open, filed in `docs/screens/P07/SHARED_REQUEST.md`,
and cannot be fixed under RULES §1. Because P07-BUG-10 is major (it becomes a
blocking trap the moment P07-BUG-8’s expiry fix lands), this iteration cannot
pass.

Proof file: `app/test/features/paywall/p07_bugs_test.dart` — 14 tests
unskipped and green (bugs 1–7 + 4 verified-clean baselines), 5 skipped
(BUG-8/9 shared, BUG-10/11/12 open). `--run-skipped` fails each skipped proof
for the documented reason.

## Iteration-1 ledger

| ID | Iteration-1 finding | Iteration-2 outcome |
|---|---|---|
| P07-BUG-1 | blocker: screen not implemented | **fixed** — full `1_plan.md` §a surface; proof green |
| P07-BUG-2 | blocker: no trial/restore path, onboarding dead end | **fixed** — events + `PaywallAction`/`PaywallRequest`, session writes, `/today`; proofs green |
| P07-BUG-3 | major: `NestBottomCta` cannot render CTA → caption → legal row | **fixed** — local column with `caption: null`; proof green |
| P07-BUG-4 | minor: caption dropped “the” | **fixed** — `detail` now `after the 14-day trial`; proof green |
| P07-BUG-5 | minor: stray full stop, tag missing from data | **fixed** — `detail` carries sub + caption + tag, em-dash joined; proofs green |
| P07-BUG-6 | minor: stale `errorMessage` survived a retry | **fixed** — `copyWith(clearError:)`; proof green |
| P07-BUG-7 | minor (latent): UPDATE-only writes | **fixed** — `_upsert` mirrors `AppSession._write`; proof green |
| P07-BUG-8 | major (shared): the 14-day trial never expires | **open** — nothing writes `'expired'`; `SHARED_REQUEST.md` §1; proof skipped |
| P07-BUG-9 | minor (shared): kid-mode guard order during onboarding | **open** — `router.dart` unchanged; `SHARED_REQUEST.md` §2; proof skipped |

Evidence for the fixes: all ten iteration-1 proofs are unskipped and pass
(`flutter test test/features/paywall/p07_bugs_test.dart` → `+14 ~5`), plus the
feature suites. The four stage-3 test defects the build repaired (impossible
`tops[1] ≈ tops[2]`, CTA height measured on the label text, bool matcher on a
`Tristate`, decorative-label regex that matched the title/Pip) were each
re-verified as legitimate test bugs; intent was preserved, not weakened.

## Iteration-2 findings

### P07-BUG-10 — Major (latent today; blocking trap once P07-BUG-8 lands) — the close button cannot leave the expired-trial paywall

**Found by:** stage 3 (`3_test.md`, proof in `paywall_view_test.dart:1102`);
independently reproduced here with a second proof in `p07_bugs_test.dart`.

**Where:** `paywall_view.dart:27-34` (`_onBack`: `canPop() ? pop() : go(P06)`)
combined with the router’s expired-trial rule (`router.dart:90-93`): when the
trial is expired, **every** location except `/paywall` is redirected back to
`/paywall`. `pop()` lands on `/today` and is bounced; `go(P06)` is bounced
too. The design’s close X (`Close and go back`) is therefore a dead control
for an expired user — they can only subscribe or restore.

**Repro:** `cd app && flutter test
test/features/paywall/p07_bugs_test.dart --run-skipped --plain-name
'[P07-BUG-10] close leaves'` → set `subscription_status='expired'`,
onboarded, pump `/today` (redirects to `/paywall`), tap X →
`Expected: not '/paywall' / Actual: '/paywall'`.

**Failing tests:** `[P07-BUG-10] close leaves the expired-trial paywall (no
bounce)` (`p07_bugs_test.dart`, `skip: true`) and stage 3’s
`[P07-BUG-10] close escapes the expired-trial paywall (no /today bounce)`
(`paywall_view_test.dart`, `skip: true`).

**Why latent:** nothing in `app/lib` writes `'expired'` (P07-BUG-8), so the
state is unreachable in today’s product — but the moment the shared expiry
fix lands, every expired parent hits this trap. The two must be fixed
together.

**Suggested fix (screen-local option):** for `session.trialExpired` the
paywall is a hard gate, so the onboarding close affordance must not pretend
to work — omit the close tile (and its 44px balance spacer) when
`GetIt.instance<AppSession>().trialExpired`, or render it disabled with a
correct label. **Orchestrator option:** relax the router guard to allow a
specific escape (e.g. `/settings`) so X can `go` there. A test asserting
*where* an expired parent should land is a product decision; the proofs only
require “X leaves `/paywall`”.

### P07-BUG-11 — Minor — the legal separators are announced

**Where:** `paywall_view.dart:747` and `:753` render the two `·` separators
as plain `Text('·', …)`. The design marks them `aria-hidden="true"`
(`P07-paywall.html:108,110`), and the two links carry their own labels — the
dots must not become separate semantics nodes.

**Repro:** `--run-skipped --plain-name '[P07-BUG-11]'` → `Expected: no
matching candidates / Actual: Found 2 widgets with a semantics label named
"·"`. A screen reader announces “middle dot” between `Restore purchases`,
`Terms` and `Privacy`.

**Failing test:** `[P07-BUG-11] the · separators stay out of semantics`
(`skip: true`).

**Suggested fix:** wrap both separator `Text` widgets in `ExcludeSemantics`
(or `Semantics(excludeSemantics: true, …)`) — one line each, screen-local.

### P07-BUG-12 — Minor — Start free trial downgrades an active subscriber

**Where:** `paywall_view.dart:41-55` (`_onActionSuccess` trial branch always
calls `session.startTrialNow()`), after the bloc already ran
`repository.startTrial()` (`paywall_bloc.dart:50` →
`paywall_repository_impl.dart:30-39`). `/paywall` stays reachable for an
onboarded app (`router.dart` `parentOnly` list), and `Seed.demo` is an
`active` family, so the screen can be shown to a paying subscriber. Tapping
`Start free trial` overwrites `subscription_status: 'active'` with `'trial'`
and moves `trial_start`. The restore path deliberately refuses this
(“Restore purchases never starts a trial”); the trial path has no equivalent
guard.

**Repro:** `--run-skipped --plain-name '[P07-BUG-12]'` on `Seed.demo` →
`Expected: 'active' / Actual: 'trial'` (and the seeded `trial_start` is
replaced by now).

**Failing test:** `[P07-BUG-12] an active subscription is not replaced by a
trial` (`skip: true`).

**Suggested fix:** guard the trial action on the current subscription — e.g.
the bloc watches `repository.watchSubscription()` and treats an `active`
subscription as “already subscribed” (skip `startTrial()`, emit success), or
the view skips `startTrialNow()` when `session.subscriptionStatus == 'active'`
— then complete onboarding and go to `/today` as today. Note:
`paywall_bloc_test.dart` pins repository-level “trial wins by design”; the
guard belongs at the action layer, so that pin can stay as the raw repository
contract. The orchestrator may also rule that a deep-linked paid user should
be redirected off `/paywall` entirely — either way the CTA must not regress a
paid subscription.

## Carried open items (shared, filed — not fixable under RULES §1)

1. **P07-BUG-8 — major (shared):** the 14-day trial never expires; nothing in
   `app/lib` writes `subscription_status = 'expired'`, so the router’s
   `trialExpired → /paywall` redirect is dead code. Filed in
   `SHARED_REQUEST.md` §1 (owner: `core/data/app_session.dart` +
   `app/launch.dart`; suggested fix computes expiry from `trialStart + 14`
   London calendar days). Proof `[P07-BUG-8]` stays `skip: true`. **Fix
   together with P07-BUG-10** — landing expiry without the close fix traps
   every expired parent.
2. **P07-BUG-9 — minor (shared):** kid-mode + onboarding-incomplete deep link
   to `/paywall` ends on `/welcome` instead of `/parental-gate` (guard
   ordering in `app/lib/app/router.dart`). Filed in `SHARED_REQUEST.md` §2.
   Proof `[P07-BUG-9]` stays `skip: true`.

## Verified clean this iteration

- **Bugs 1–7 proofs:** unskipped and green (see ledger).
- **Rapid double taps:** trial same-frame double tap → one `startTrial` call,
  one navigation; restore same-frame double tap → one `activate` call; close
  double tap → one pop. (Bloc `working` guard + disabled CTA; probes run and
  deleted.)
- **Close during an in-flight trial:** pops to `/pocket-money-setup`, no
  exception, and the completed request never navigates to `/today` (the
  listener is gone; bloc 9 cancels the emitter, so no emit-after-close throw).
- **Load error + trial:** error body with `Retry` and the CTA both render; a
  trial tapped from the failure state still completes and lands on `/today`.
- **Deep links / back (non-expired):** `/paywall` reachable with `Seed.fresh`
  and stays open for an onboarded app; close → `/pocket-money-setup`; kid
  mode (onboarded) → `/parental-gate`.
- **Restart persistence:** trial handoff survives a fresh `AppSession` over
  the same DB (onboarded, `trial`, `trial_start`, `Europe/London`); restore
  survives as onboarded + `active`.
- **Text scale 1.3 × width 320 × dark:** no overflow/exception (CTA present);
  the stage-3 12-combination matrix covers the rest.
- **Dark-mode contrast (tokens, computed):** sky on surface 7.14:1 dark /
  5.48:1 light, leafInk on leafTint 8.47:1 / 7.12:1, ink2 on surface
  9.82:1 — all ≥ 4.5:1 for the 13 px links.
- **FONTS rule:** no `google_fonts`/`GoogleFonts` anywhere in the feature or
  its tests (grep clean; nothing to delete).
- **Money rounding / integer pence and child-data edge cases:** not applicable
  — P07 does no arithmetic and renders no child or money data (static plan,
  fixed `James` copy; demo/empty/fresh render identically per the stage-3
  seed test).
- **Owner rules:** bottom edge and 20 px gutters are pinned by the stage-3
  pixel/geometry tests and the stage-5 compare (separate stage).

## Verification (run this stage, `app/`)

- `flutter test test/features/paywall/p07_bugs_test.dart` → **+14 ~5**.
- `flutter test test/features/paywall/` → **+92 ~6** (stage-3’s own skip
  included; only the shared/open proofs skipped).
- `flutter analyze` → `No issues found!`; `dart format` → 0 changed.
- Full `flutter test` → **+742 ~6, all pass** (6 skips: the 5 open proofs in
  this file + stage 3’s P07-BUG-10 proof).
- The three new proofs (BUG-10/11/12) fail exactly as documented with
  `--run-skipped`; the scratch probe files used for the hunt were deleted.
- No screen code touched; only `app/test/features/paywall/p07_bugs_test.dart`
  and this file.

## Verdict basis

Iteration-1 blockers/majors are fixed with green proofs and the two new minor
findings have failing skip-marked proofs, but P07-BUG-10 is a real defect in
the screen’s back navigation: on the expired-trial paywall the close control
can never work while the router forces every location back to `/paywall`. It
is latent only because P07-BUG-8 is unfixed; the two must be fixed together,
and the screen should not ship a dead X into the expiry release. Per the
stage rule — PASS only if no major bugs — this iteration fails.

