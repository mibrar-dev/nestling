# P03 Create account — QA code review (Stage 4, iteration 7)

Scope reviewed: `git diff main...HEAD` through `520cd82` (iteration-6
INTEGRATE) and `5e70e1a` (iteration-7 checkpoint). Reference set:
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md`
§5 P03 and §0.9, `docs/design/SPACING_SPEC.md` §3,
`design/html-source/screens/P03-create-account.html`, `components.css:129-135`,
`ORCHESTRATOR_NOTES.md` (all mandatory), the standing COPY / FONTS /
LETTER SPACING / CHIP ROWS / BALANCED HEADINGS rules, `1_plan.md`,
`FIXES_1…4`, `2_build.md` (iter-7 INTEGRATE), `3_test.md` (iter-6),
`SHARED_REQUEST.md`.

Evidence gathered by this stage:

- `flutter analyze` → `No issues found! (ran in 2.9s)` — no ignores, no
  weakened options; no `GoogleFonts` string anywhere under
  `app/lib` + `app/test`.
- `flutter test test/features/auth` → **+159: All tests passed!**,
  0 failed, 0 skipped (files: `auth_bloc_test.dart` 20,
  `create_account_view_test.dart` 38, `copy_audit_test.dart` 11,
  `p03_bugs_test.dart` 30, `seeded_submit_test.dart` 7,
  `typography_test.dart` 9, plus 44 harness-unit lines in the new
  builders' files).
- `framework` fonts: `pubspec.yaml:90-108` bundles Inter 400/500/600/700 and
  Nunito 700/800/900 — the same builds that rendered the design; nothing
  from `google_fonts` is referenced.
- Device checks against `ui/filled-light.png` (iteration 6 capture):
  or-row ink band in the app spans 394–399 vs design 393–399; email label
  426–431 vs 424–431; field white starts 449+1 in app vs 449 design; the
  two legal-caption runs sit at x 262–300 / 149–241 vs 258–297 / 150–240.
  A post-BUG-23 capture was owed to the UI stage at the end of iteration 6;
  iteration 7's two proofs are green, so a fresh capture should show the
  form block on the design's own bands — that check belongs to the UI stage.
- `git status` touches only `app/lib/features/auth/**`,
  `app/test/features/auth/**`, `docs/screens/P03/**` — RULES §1 respected.

## Iteration-6 findings — both answered

| # | Finding | Status |
|---|---|---|
| 1 | BLOCKER — red suite, one proof shared-blocked | **closed**: the shared batch-2 merge fixed the component, §5/§8 record Decision B, suite green and skip-free |
| 2 | MINOR — overlap double-fired | **closed** via the gesture-entry gate; BUG-22's proof asserts collection of only the right boxes |

## Verified-correct this iteration

- **BUG-23 (form block 2 dp low) is fixed in code and green-proved.** The or-row label now takes everything from `NestType.caption` and only replaces the line box with
  `NestType.caption(color: tokens.ink2).copyWith(height: _orLabelLineBox / base.fontSize!)`, where `_orLabelLineBox = 15.7` is the single number the design owns (`13px/600` on Inter's natural 1.2077 line box). Both proofs (font-independent + fonts-loaded) pass; the token-derived style was re-integrated from the parallel builder without a behavioural change.
- **BUG-17 (subtitle break) is resolved shared-side**, and the build rightly did not hand-hack the subtitle's size or letter-spacing; the next capture should show it.
- **SHARED_REQUEST §5/§6/§7/§8** now record a single disposition each: §5/§8 RESOLVED (shared row won, live region preserved in the component), §6 RESOLVED (fonts bundled, google_fonts gone), §7 still open (13/20 legalCaption token) but pinned by two proofs.
- **BOTTOM EDGE / ALIGNMENT** now have pixel proofs in both themes (the CTA's surface runs to y=844 in light and dark; no strip) and the or-row fix is the only geometric drift closed this iteration.
- **FONTS / LETTER SPACING / CHIP ROWS / CARRYOVER**: no `google_fonts` import anywhere, `NestType` styles used with only `height`/`color` overrides (tracking is 0 by default), no `NestChip` on this screen, no `NestBalancedText` misuse anywhere (see finding 1).
- **CHILD ORDER / TRIAL / PIP / DATA OVER MOCKS / PERIODS**: N/A for P03.

## Findings

### 1. MAJOR — the h1 still hand-breaks with a `maxWidth` constant, not `NestBalancedText`

`app/lib/features/auth/presentation/views/create_account_view.dart:39-42`
(`_headlineMaxWidth = 240`) and `:101-111` (`Semantics(header: true, child:
ConstrainedBox(maxWidth: _headlineMaxWidth, child: Text('Create your family
account', style: NestType.h1(…), maxLines: 3)))`).

The iteration-7 rule is explicit: where the design CSS uses
`text-wrap: balance` (`.display`, `.h1`, `.kid-title`, `.kid-hero`, any
screen-local `.balance`), render the heading with `NestBalancedText`. P03's
heading is `.h1` — explicitly in scope — and the fix is a swap of the same
copy, style, and `maxLines: 3`, no new constant. The `ConstrainedBox` answer
looks correct today only because it forces the same 2-line break; at the
spec widths the proofs (`P03-BUG-7`, `typography_test.dart`) already see the
same geometry, and `NestBalancedText` is what exists for exactly this
computation. Until the swap, the screen is one width/font-asset change away
from a silent divergence from the design (and any future screen that
copies this cap inherits it).

Concrete fix:

```dart
Semantics(
  header: true,
  child: NestBalancedText(
    'Create your family account',
    style: NestType.h1(color: tokens.ink),
    maxLines: 3,
    textAlign: TextAlign.start,
  ),
),
```

Delete `_headlineMaxWidth` and its comment block; the two proofs should
still pass because the rule already documents the balanced break.

### 2. MINOR — `zz_probe8_test.dart` must not be committed

`app/test/features/auth/zz_probe8_test.dart` — an untracked FontLoader debug
probe left by the test stage (its content is duplicated in
`typography_test.dart`'s own setup and it has never been committed). It is
inside `app/test/features/auth/`, which is an allowed edit path, so the next
stage could accidentally bring it in. Delete it or move it under
`docs/screens/P03/`.

## Checked and clean (no finding)

- **Architecture** — feature-first; `domain/` = abstract repository + entities
  only; one bloc per screen; DI/routes per feature; only route-path constants
  cross feature boundaries; no use-case classes, no `utils` dumping ground.
- **RULES §1 / §4 / §7** — only allowed paths touched (auth feature + its
  test folder + P03 docs); password still never persisted; owner row still
  idempotent; feature tests all green with no skips, `disposeApp(tester)`
  honoured throughout.
- **TOKENS-ONLY** — the view has no hard-coded colours, radii or text sizes;
  the one owned number (`15.7`) is the HTML's computed line box, named and
  documented; the legal caption's 13/20 debt is confined to
  `SHARED_REQUEST.md` §7's open item.
- **A11Y** — filled-state pins (label/eye/enabled CTA) and the error live
  region are green; headline is the only `header:`; brand labels announce
  once each; every interactive box ≥44dp; text-scale 1.3 at 320/390/430
  absorbs overflow via the scroll view with no clip.
- **ERROR HANDLING** — both submit handlers `on Object catch` + `addError`,
  in-flight guards, form stays editable; the failed submit's announcement is
  still sent through the widget tree.
- **CHILDREN'S CODE** — no analytics, no ads, no child data, no photos, no
  location; the privacy note is the first visual element under the fields.
- **PROCESS** — noted, not reported as findings: the 14:06 interruption,
  the loop's own merge, uncommitted work.

VERDICT: FAIL