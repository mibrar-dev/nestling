# P07 Paywall — test report (Stage 3, iteration 4)

## Summary

Iteration 4's build fixed P07-BUG-13 (the legal-link labels were 13px above the
separators) with a vertical-centring inset and un-skipped its proof, and the
shared `NestType` letterSpacing-0 budget (`main fd92d95`) landed on the branch.
**This stage adds four tests for those two changes and finds no defect.** The
suite is green end to end and the analyzer is clean app-wide:

| Run | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 371 files, 0 changed |
| `flutter analyze` (whole app) | **No issues found!** |
| `flutter test test/features/paywall/paywall_bloc_test.dart` | **+30** all passed |
| `flutter test test/features/paywall/paywall_view_test.dart` | **+63** all passed |
| `flutter test test/features/paywall/p07_bugs_test.dart` (stage 6) | **+18 ~2** all passed |
| `flutter test test/features/paywall/` | **+111 ~2: All tests passed!** |
| `flutter test` (whole app) | **+805 ~2: All tests passed!** |

The only 2 skips are `[P07-BUG-8]` and `[P07-BUG-9]`, both **shared code outside
RULES §1** and both filed in `docs/screens/P07/SHARED_REQUEST.md` (see
Outstanding). Every in-screen bug proof — P07-BUG-1 … 13 — is un-skipped and
green.

## Tests added this iteration (4)

| Test | What it pins |
|---|---|
| `no text on P07 adds letter spacing` | **LETTER SPACING rule (`main fd92d95`)**: every rendered paragraph sweeps at `letterSpacing == 0`. Material's tracking made Inter paint 1–2% wider than the design — the cause of the benefit-4 wrap — so a regression has to fail here. A `inspected > 10` guard keeps the sweep from passing vacuously |
| `benefit 4 is painted in full, at the design’s 15px` | **ORCHESTRATOR_NOTES iteration-4 item 1** (re-measure benefit 4; do NOT shrink the text or edit the copy). The font-independent half is asserted here: 15px (the `.benefit-txt` token, not a fitted size), `didExceedMaxLines == false` (wraps, never truncates), and the box sits on the design's 24px line grid |
| `the title carries no inserted hard break` | **ORCHESTRATOR_NOTES iteration-4 item 3**: the "days" orphan (`text-wrap: balance` has no Flutter equivalent) is accepted, and no hard `\n` may be inserted — the rendered plain text is exactly `Try Nestling free for 14 days` in one paragraph node |
| `the legal row centres both glyph families in one 44px band` | **ORCHESTRATOR_NOTES iteration-4 item 2**: the link target is exactly 44px tall and the `·` separators share its vertical centre (within 0.5px). Complements Stage 6's `[P07-BUG-13]` baseline proof by pinning the *box*, not just the baseline relation |

Supporting: nothing new — these reuse the existing pump, scroll and copy
helpers. No screen code was edited.

## Measurements taken while writing these (all on the widget harness)

- `letterSpacing` = `0.0` on every paragraph sampled (h1, benefits, plan title,
  plan tag, `.h3`, family note) → the rule holds.
- Benefit 4 paints at 48px tall = two 24px lines **in the harness**. That is the
  wide-font artifact documented in iteration 1 (the widget-test font is ~2× the
  bundled Inter, see P02-BUG-7), not a wrap defect: 2b confirmed one line on a
  real device (`ui/app_light_4.png`), and the harness width is why the test
  asserts "painted in full, never shrunk, on the design's grid" rather than a
  line count. A widget test cannot and should not pin "one line at 390".
- Legal row: link `InkWell` 44px tall (`y 732–776`); `·` centre `y = 754.0` and
  `Terms`/`Restore purchases` centre `y = 754.0` → one shared centred band. The
  whole `Wrap` measures 96px tall **in the harness** because the wide font
  forces a second run; on device it is one run.

## Outstanding (shared, not this screen, not this stage's to fix)

Both live outside RULES §1 and are filed in `SHARED_REQUEST.md`; their proofs
stay skipped until the orchestrator lands them (stage convention: skipped while
the defect is open, un-skipped when fixed).

- **P07-BUG-8 (major)** — nothing in `app/lib` writes
  `subscription_status = 'expired'`, so the router's paywall redirect is dead
  code and a trial never lapses. Owner: `core/data/app_session.dart`
  (+ `app/launch.dart`), `SHARED_REQUEST.md` §1. The screen half of this pair is
  already in place (P07-BUG-10's fix), so no close trap will appear when it
  lands.
- **P07-BUG-9 (minor)** — kid mode + onboarding-incomplete deep link to
  `/paywall` lands on `/welcome` instead of `/parental-gate` (guard order).
  Owner: `app/lib/app/router.dart`, `SHARED_REQUEST.md` §2.

Neither can be fixed from this worktree, and neither is a defect in the screen
this stage owns.

## Re-verified clean this iteration

Everything earlier iterations proved still holds: the design surface and its
copy character-by-character against `P07-paywall.html` (including the caption
article "the" and the plan tag), `PipAvatar(mochi, sunny, stage 4, inNest)` on
the design's 120px slot with the hero scaling `min(w/350, 1)` at 320/390/430,
light + dark × 320/390/430 × text scale 1.0/1.3 with no overflow, consistent
20px gutters, the bottom edge reaching the physical screen edge in both themes
(painted-pixel proof, with and without a 34px home-indicator inset), every tap
navigating to the right route (`/pocket-money-setup`, `/today`), the
ORCHESTRATOR_NOTES 1 handoff on both the trial and restore paths (restore never
writes a trial start), the `working` / failure / retry action states, the
expired-trial paywall showing no dead close control and no dangling 44px
spacer, an active subscriber never being downgraded by the trial CTA,
`initial`/`loading`/`loaded`/`failure` + Retry, an empty plan list that is never
an empty state, an identical screen under `Seed.demo`/`empty`/`fresh` with no
seeded child names leaking, and no `google_fonts`/`GoogleFonts.*` in the
feature.

## Verdict basis

All tests pass (`+805 ~2`), `dart format` reports 0 changed across 371 files,
`flutter analyze` reports **No issues found!** app-wide, and the four tests
added here found no defect in the screen. The two remaining skips are shared
code already filed in `SHARED_REQUEST.md` — outside this screen's edit scope and
outside RULES §1, so they are outstanding orchestrator work rather than a
P07 finding. This screen's own defects (P07-BUG-1 … 13) all have un-skipped
green proofs. Stage 3 passes.

VERDICT: PASS