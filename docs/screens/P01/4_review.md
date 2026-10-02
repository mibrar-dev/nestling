# P01 Welcome — QA code review (Stage 4, iteration 2)

Scope: `git diff main` (the branch's five commits **plus** six uncommitted
files) = `app/lib/features/onboarding/presentation/views/welcome_view.dart`,
three files under `app/test/features/onboarding/`, and `docs/screens/P01/**`.
No code was edited during this review; one temporary probe test was created,
run and deleted (tree verified clean afterwards).

Mandatory inputs applied: `ORCHESTRATOR_NOTES.md` (both items) and the
orchestrator rules in the stage brief (PipAvatar for Pip, status bar, data over
mocks).

## Verification run by this stage (all first-hand, `app/`)

| Check | Command | Result |
|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed .` | 342 files, 0 changed — clean |
| Analyze | `flutter analyze` | `No issues found!` (3.2s) |
| Feature tests | `flutter test test/features/onboarding` | `+45 ~2: All tests passed!` |
| Full suite | `flutter test` | `+334 ~2: All tests passed!` (0 failed, 2 skipped) |
| Isolation | `git diff main --name-only` | only RULES §1 paths (see below) |
| BUG-2 / BUG-4 reality probe | temporary test, now deleted | see findings 1–2 |

Skips in the branch: exactly two, both in
`app/test/features/onboarding/p01_bugs_test.dart` (`skip: true` at lines 106
and 189). One of them is now unjustified — finding 1.

**The product code is in good shape.** Every iteration-1 finding and both
P01-owned bugs are fixed and pinned by passing tests, the mandatory Pip rule is
implemented and verified, and the suite is green. The single blocker-class item
left is test/doc hygiene around a shared fix that has already landed.

---

## Findings

### 1. MAJOR — BUG-2's proof is left `skip: true` even though its shared fix landed in this branch, and its assertion is now the *inverse* of the shipped contract

**Where:** `app/test/features/onboarding/p01_bugs_test.dart:83-107`
(`skip: true` at :106; stale premise in the header comment at :1-18), and the
same stale claim in `docs/screens/P01/2_build.md:52`,
`docs/screens/P01/3_test.md:77-83` and `docs/screens/P01/SHARED_REQUEST.md:16-21`
("the bottom inset is counted twice", "Blocks: yes for item 2").

main's `763192d` (merged here via `ac1b217`) fixed it:
`nest_chrome.dart:222-225` now returns `SizedBox.shrink()` from
`NestHomeIndicator` unless `NestStatusBar.showMockGlyphs` (gallery only), so the
OS bottom inset is consumed exactly once, by `NestBottomCta`'s `SafeArea`.

I measured the shipped behaviour with a temporary probe (deleted):

```
PROBE baseline inset=0: primary=Rect.fromLTRB(20.0, 672.0, 370.0, 724.0)
PROBE inset=34:        primary=Rect.fromLTRB(20.0, 638.0, 370.0, 690.0)
PROBE delta top = -34.0        (the proof asserts ≈ 0)
```

The defect is gone — with a 34dp inset the CTA block moves up exactly 34dp
(so it is never overlapped by the OS indicator), and on the 390×844 simulator
that is the stage-5 drift closing: primary top 623.3 + 34 ≈ 657.3 vs the
design's 656.7. The proof now fails for the wrong reason: it encodes the
*pre-fix* contract ("the CTA never moves"), so it would fail even though the
product is correct.

**Why this is more than cosmetic:** the only guard on bottom-inset geometry in
the branch is dead; the notes and the SHARED_REQUEST tell the orchestrator a
fixed bug is still open, which invites a second, redundant change to shared
CTA code; and if someone "completes" the fix by deleting the `skip:` marker
they get a red test and a reason to delete the assertion altogether. The stage
brief also forbids shipping skipped tests.

**Concrete fix (P01-owned, ~10 min):** rewrite the invariant to the contract
that now holds and unskip. In `p01_bugs_test.dart:83-107` replace the
`closeTo(baselineTop, 1)` assertion with:

```dart
// The OS inset is counted exactly once: NestBottomCta's SafeArea owns it and
// NestHomeIndicator no longer reserves 34 (main 763192d), so with a 34dp
// inset the whole CTA block moves up by exactly 34 and its bottom edge lands
// 34dp above the screen bottom.
expect(insetTop, closeTo(baselineTop - 34, 1));
expect(tester.getBottomRight(find.text('Made in the UK · No ads, ever')).dy,
    closeTo(844 - 34 - NestSpacing.s4, 1));
```

then delete the `skip: true` marker and the "BUG-2: bottom safe inset +
NestHomeIndicator double-counted" comment. Verify with
`flutter test test/features/onboarding/p01_bugs_test.dart --plain-name 'BUG-2'`
(passes) and re-run the full suite. Then correct `3_test.md:77-83` and
`SHARED_REQUEST.md:16-21` to record BUG-2 as **fixed on main** (with the
measured −34 evidence) so the orchestrator does not touch
`core/design_system/components/nest_bottom_cta.dart` again.

### 2. MINOR — SHARED_REQUEST item 2 is stale after `763192d`; the real remaining gap is narrower (and is still a genuine product bug)

**Where:** `docs/screens/P01/SHARED_REQUEST.md:22-27` (says
"`AppSession._write` … only UPDATE[s] it"), `docs/screens/P01/3_test.md:84-89`.

`AppSession._write` now upserts (`app/lib/core/data/app_session.dart:61-72`,
plus a new shared regression test `app/test/core/app_session_fresh_install_test.dart`).
My probe shows what is *still* broken:

```
PROBE before:                        onboardingComplete=false
PROBE after repo.completeOnboarding: onboardingComplete=false
PROBE app_state row after repo write: null
PROBE after session.completeOnboarding: onboardingComplete=true
```

So the surviving defect is that the **feature repositories write directly**:
`features/onboarding/data/onboarding_repository_impl.dart:24-28`
(`completeOnboarding`) and `features/paywall/data/paywall_repository_impl.dart`
(`startTrial` / `activate`) still `UPDATE … WHERE id = 1` with no
insert-if-missing, and nothing bootstraps row 1 at DB open.

**Fix:** narrow item 2 to exactly that (drop the `AppSession._write` clause),
and state the two acceptable resolutions: insert-if-missing in
`MigrationStrategy.beforeOpen` (preferred — fixes every writer at once), or an
upsert in each repository. Keep it in SHARED_REQUEST rather than fixing it
here: the root cause is `core/data`, the same defect exists in the paywall
feature (outside §1), and patching only P01's repository would leave two
divergent write paths. The proof in `p01_bugs_test.dart:157-190` correctly
stays skipped until then.

### 3. MINOR — BUG-4 is still product-blocking for the onboarding flow (shared, correctly deferred, but it is the last thing between P01 and a working first launch)

**Where:** same code as finding 2. Consequence: on a release first launch (no
`SEED` flag) the user completes onboarding, the write affects 0 rows, and the
router sends them back to `/welcome` on every restart — P01 is the screen that
loops.

Not a P01 defect: P01 never calls `completeOnboarding()` (plan §b — completion
belongs to P06/P07), and the fix is shared. The skip at
`p01_bugs_test.dart:189` is legitimate on the brief's "never skip tests" rule
because it asserts shared behaviour outside §1, is committed with a repro, and
is tracked in SHARED_REQUEST. **Requirement:** whoever lands the shared fix must
unskip it in the same change (and it should then pass). Keep the loop from
re-litigating this each iteration — it is filed, not forgotten.

### 4. MINOR — `NestHomeIndicator()` in the P01 column is now a no-op, so the design's fixed 34pt bottom band exists only when the OS reports an inset

**Where:** `welcome_view.dart:48`.

With the shared fix, that child is `SizedBox.shrink()` in the app. On a
home-indicator device the 34pt band comes from `SafeArea` (correct, and it
matches the design). On an inset-0 device (390pt Android with gesture nav,
iPhone SE-class) the CTA block sits flush with the screen edge — 34pt lower
than the design's band, because `NestBottomCta` has no
`max(viewPadding.bottom, NestDevice.homeH)` floor the way `NestStatusBar` has
`max(viewPadding.top, NestDevice.statusH)`. Keeping the widget is harmless and
self-documenting, so no P01 code change is required.

**Fix (shared, low priority):** add the symmetric floor in
`nest_bottom_cta.dart` — `padding: EdgeInsets.only(bottom: max(inset, NestDevice.homeH))`
— or accept the divergence as part of the orchestrator's "the OS draws the
chrome" rule and say so in the design spec. Either way, **stage 5 must re-run
`shot.sh` + `compare.py` on a 390×844 simulator (real 34pt inset)**: the
existing `ui/*.png` were captured before `763192d` and before the
`PipAvatar` swap, so bands 4–7 of the filed comparison are stale.

### 5. MINOR — the mandatory Pip rule is met through `PipAvatar` defaults rather than explicit arguments

**Where:** `welcome_view.dart:148` —
`const PipAvatar(style: PipStyle.mochi, stage: 2)`.

`ORCHESTRATOR_NOTES.md` item 1 mandates `style: mochi, skin: sunny, stage: 2`
with an idle mood. The defaults are exactly `sunny` / `idle` / `none`
(`pip_avatar.dart:234-236`) and `welcome_view_test.dart:276-279` pins the four
resolved values, so behaviour is correct today — this is robustness, not a
defect: a future change to `PipAvatar`'s default skin would silently change
the brand Pip on the app's first screen, and only that widget test would catch
it (a product test failing for a DS default is a confusing signal).

**Fix:** pass `skin: PipSkin.sunny, mood: PipMood.idle` explicitly (still
`const`), and keep the comment at :146-147.

### 6. INFO — P01's hero Pip now animates where the design PNG is static

`PipAvatar` runs the Rive idle loop on a normal launch (the fallback SVG is
for reduced motion / missing runtime). RULES §6 is satisfied inside the widget
(`reduceMotion = MediaQuery.disableAnimations || kDisableAnimations` →
approved idle still frame, `pip_avatar.dart:389-391, 433-435`), so
`shot.sh` runs with `DISABLE_ANIMATIONS=1` and the comparison is unaffected.
No action; do not read a live first frame in stage 5 as drift.

### 7. INFO — carried cosmetics from iteration 1

`Positioned(width/height: 40/34/36)` duplicates the `_SceneCoin(size: …)` and
`SvgPicture` dimensions (`welcome_view.dart:151-180`); `welcome_view.dart:5`
still imports `flutter_svg` for the nest and coins (correct — only Pip moved
off SVG). Both are harmless.

---

## Iteration-1 findings — disposition (all resolved)

| # | Finding | Status |
|---|---|---|
| 1 | blocker: scene cropped below 390dp | **fixed** — `OverflowBox` lays the Stack out at full 350×388 and only paint scales (`welcome_view.dart:98-111`); pinned by `welcome_view_test.dart:582` (`size == Size(350, 388)`, so it cannot be masked by `Clip.none`) and `p01_bugs_test.dart:62-81` |
| 2 | major: fictional shared-suite failure | **fixed** — request superseded; `router_redirect_test.dart` is route-location based and green |
| 3 | minor: coin shadow clipped | **fixed** — `Stack(clipBehavior: Clip.none)` (`welcome_view.dart:111`), proof at `p01_bugs_test.dart:192-210` |
| 4 | minor: first-frame SVGs never pre-cached | filed as SHARED_REQUEST item 3 (non-blocking) |
| 5 | minor: `350` hard-coded | **fixed** — `_frameW` / `_frameH` with a source comment (`welcome_view.dart:86-90`) |
| 6 | minor: dead `BlocBuilder` + wrong doc claim | **fixed** — subscription removed; the doc comment now states the route owns the bloc (`:11-17`) |
| 7 | minor: heading flag unasserted | **fixed** — `welcome_view_test.dart:512` |
| 8 | minor: Google-Fonts CDN fetch | filed as SHARED_REQUEST item 3 |
| 9 | minor: cross-feature `auth_routes` import | kept deliberately (plan §c) |
| 10 | minor: redundant `backgroundColor` | **fixed** — removed; theme owns it |
| 11 | info: 430dp scene left-aligned | kept (matches `.scene { width: 350px }`) |
| — | stage-6 process finding 0: stale `9:41` | **fixed** — `welcome_view_test.dart:154-158` now asserts the mock clock is absent and the 47dp reserve is exact |

## What passed

- **Architecture (docs/ARCHITECTURE.md):** feature-first shape intact; the view
  stays at `features/onboarding/presentation/views/welcome_view.dart`; no bloc
  subscription, no domain/data edits, no use-case classes; `OnboardingBloc`
  remains owned by the route-level `BlocProvider`
  (`onboarding_routes.dart:30-37`) and its `emit.forEach` subscription is
  closed with the route. Navigation uses route constants, not literals.
- **Isolation (docs/screens/RULES.md):** `git diff main --name-only` lists only
  `features/onboarding/presentation/**`, `app/test/features/onboarding/**`
  (3 files) and `docs/screens/P01/**`. `app/lib/core/**`, `app/lib/app/**`,
  `tools/**` and every other test directory are untouched — the shared fixes
  arrived via merges of `main` (`71d2400`, `763192d`, both verified as
  ancestors of `main`), not as edits in this worktree. No `analysis_options`
  weakening, no deleted or renamed tests.
- **ORCHESTRATOR_NOTES (mandatory, both items):** item 1 — `PipAvatar` replaces
  the v1 `pip_stage_2.svg` in the same 168×168 slot at (91,120) with Mochi/sunny
  stage 2 idle, the v1 asset is asserted absent, the still-frame SVG renders
  under reduced motion, and the HTML alt text is preserved
  (`welcome_view_test.dart:258-305`). Item 2 — status-bar differences treated
  as harness artefacts; the stale `9:41` assertion is gone.
- **Design system:** every colour, font, spacing and device value still resolves
  through `context.nest` / `context.nestText` / `NestSpacing` / `NestType` /
  `NestDevice` / `NestlingIllustrations` / `PipAvatar`; no hex literals, no
  hand-built `TextStyle`, no re-implemented components (`NestStatusBar`,
  `NestBottomCta`, `NestButton` primary + ghost, `NestHomeIndicator`).
- **Spec parity (DESIGN_SPEC §5 P01, DESIGN_SPEC.md:146):** every element
  present, in order, with character-exact UK copy ("Chores that feel like a
  game." / "…want to finish — and keeps pocket money fair and tidy." /
  "Made in the UK · No ads, ever"). The only deliberate divergence is the Pip
  asset, which the orchestrator rules override.
- **Accessibility:** heading is the first semantic node and its `isHeader` flag
  is pinned; decorative nest/coins and chrome excluded; the HTML alt text is
  exposed on the Pip; both CTAs are full-width 52dp ≥ `NestDevice.tapParent`
  with `isButton`; no overflow across {light, dark} × {320, 390, 430}dp ×
  {1.0, 1.3} text scale.
- **Performance:** `const` throughout the static subtree; no `setState`, no
  timers, no rebuild storms; the Rive file is loaded once per style through the
  widget's shared loader and falls back to a still frame when the native
  decoder is absent; no stream is created by the view.
- **Error handling:** identical brand content for `initial`, `loading`,
  `loaded` (empty and populated) and `failure` — a repository error cannot
  blank the screen.
- **Children's Code:** no child data, no analytics, ads, tracking or
  identifiers on the screen; P01 is parent-only and main's `71d2400` now gates
  the whole onboarding flow in kid mode, with a passing proof
  (`p01_bugs_test.dart:109-155`) that `/welcome` and `/value-tour` both land
  on `/parental-gate`. The Pip shown is the mandated onboarding default
  (Mochi/sunny), not another family's data.

## For iteration 2 (one focused pass, no product change)

1. **Finding 1** — rewrite the BUG-2 proof to the "inset counted exactly once"
   invariant (assertions above), delete its `skip: true`, and correct
   `3_test.md:77-83` + `SHARED_REQUEST.md:16-21` to record BUG-2 as fixed on
   `main` (with the measured −34dp evidence).
2. **Finding 2** — narrow SHARED_REQUEST item 2 to the repository writers +
   the missing insert-if-missing bootstrap (drop the `AppSession._write`
   clause, now fixed by `763192d`).
3. **Finding 5** — pass `skin: PipSkin.sunny, mood: PipMood.idle` explicitly
   at `welcome_view.dart:148`.
4. Gate: `dart format .`, `flutter analyze` → `No issues found!`,
   `flutter test` → `+335` with **exactly one** remaining skip (the BUG-4
   shared proof). No other changes; do not re-open the resolved findings.
5. Re-run stage 5 (`shot.sh` + `compare.py`, light and dark) — the filed
   `ui/*.png` predate both the `763192d` inset fix and the `PipAvatar` swap, so
   the band table must be regenerated before this screen can be called
   visually done (finding 4).

VERDICT: FAIL
