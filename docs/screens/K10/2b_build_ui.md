# K10 Payout day — 2b build UI (iteration 1, first pass)

Screen: `/payout-day` (`KidJarRoutePaths.payoutDay`), kid mode, light + dark.
Scope: `app/lib/features/kid_jar/presentation/views/**` and
`presentation/widgets/**`, plus the K10 view/geometry tests in
`app/test/features/kid_jar/`. No simulator was booted, installed on or driven
(only `5_ui` may use a simulator). No whole-app `flutter test` run.

## Contract used (from 1_plan.md + live sources, re-read before finishing)

- `KidJarState.payout: PayoutCelebration?` (null = no payout yet) +
  `copyWithPayout`; `KidJarPayoutRequested` replaces
  `KidJarLoadRequested` on `payoutDayRoute`; the bloc holds the guarded
  `_payoutSub` (cancel-before-reload, K09-BUG-1 shape). Contract confirmed
  against the files (`state`, `event`, `bloc`, `routes`, entity): matches
  the plan; no CONTRACT CHANGES section is needed from my side.
- `PayoutCelebration` fields consumed: `nickname`, `paidPence`,
  `movedPence?`, `goalTitle`, `goalSavedPence`, `goalTargetPence`,
  `pipStyle/pipSkin/pipAccessory/pipStage`, plus its `goalFraction`,
  `goalRemainingPence`, `goalPercent` helpers.
- Demo seed renders: `Mum marked £3.80 as paid`, `£5.50 went into your Lego
  Friends set`, `Lego Friends set` £15.50 / £9.49 to go / 62% there!, pip
  mochi/sunny/none/3 (DATA OVER MOCKS — mock's £4.20/£1.00/66% not used).

## What I built

- `presentation/views/payout_day_view.dart` — full K10 screen: `KidScope` →
  status bar → `.krow-top` (back `NestIconButton` 56/26 transparent,
  `_GateLockButton` with the double-tap guard → `parental-gate`) → Expanded
  scroll (title via `NestBalancedText` + `FittedBox(scaleDown)`,
  `PayoutJarRain`, two `PayoutNote`s, `PayoutFundCard`, `_PayoutPip`) +
  the fixed `.kid-bar` (`Container` surface + 3 px ink top border > SafeArea
  > `NestKidButton` `Thanks Mum!` leaf; surface runs to the physical edge,
  bar top at 721 on device — 89 tall in the inset-less test and 123 with
  the real home inset). Loading / failure (`Oh no!…` + `Try again` →
  `KidJarPayoutRequested`) / empty (`No payout yet` + `Back home`) frames
  per plan §d. `movedPence == null` → note 2 hidden, 16 px rhythm kept.
- `presentation/widgets/payout_jar_rain.dart` — the `K10:40-74` raining-jar
  SVG transcribed as a fixed-palette `CustomPainter` on the 180×270 box
  (200×300 viewBox letter-boxed at scale 0.9); ground ellipse uses
  `tokens.groundShadow`; everything else keeps the SVG's own colours in
  both themes, like `JarIllustration`.
- `presentation/widgets/payout_note.dart` — `.k10-note`: surface, 3 px ink
  border, r16, `sh-kid`, 10/12 padding, 40 px disc + one merged spoken
  sentence (`title. subtitle` via `excludeSemantics` Semantics).
- `presentation/widgets/payout_fund_card.dart` — `.k10-fund`: coinTint,
  3 px border, r24, `sh-kid`, 14/16 padding; h2 20/26 w900, amts 17/23 w900,
  `NestProgress(kid: true, semanticLabel: '{p}% of the {goal} saved')`,
  captions `of £…` / `{p}% there!` at kidCaption. Feature-private — K09's
  `JarGoalCard` untouched.
- `presentation/widgets/pip_look.dart` — the three 10-line pip-look switches
  copied feature-privately (no import of kid_home/pip per RULES §1).
- Note 2's disc glyph is a feature-private 22 px `CustomPaint` of the
  design's circle+arrow (`K10:80`) — no `NestIcons` glyph matches it.

## Tests (all passing, `--timeout 120s`)

`test/features/kid_jar/payout_day_view_test.dart` — seeded content copy,
recorded payout re-render from the same rows, `PipAvatar` carry of
mochi/sunny/none/stage-3/happy/72, `Thanks Mum!` → `/kid-home`, back →
home fallback, lock → `/parental-gate`, tap-action semantics
(`hasAction(SemanticsAction.tap)` + `performAction` drives the real
routes and the reload), null-payout empty state, stream-error failure and
`Try again` recovery.
`payout_day_view_geometry_test.dart` — back/lock rects, title 107/34,
rain box 105/141/180/270, note 1 20/427/350/66, note 2 20/509/350/88
(see deviation), fund 20/613/350/143, progress 39/695/312/16, captions
719/20, bar runs to 844 in light AND dark, gutters 20 at 320/390/430.
`my_jar_view_states_test.dart` — added the missing `watchLatestPayout`
stub so the K09 fake compiles against the extended repository (its file is
in my ownership by name).

## Deviations / known items

1. **Note 2 is 88 px tall with the DB's strings, not the mock's 66**:
   `£5.50 went into your Lego Friends set` wraps to two lines at 17/22 w800
   inside the 276 px text column — the CSS card grows with content, and the
   design mock shows the shorter `£1.00 went into your Lego fund`, one line.
   Consequence: `PayoutFundCard` top is 613 on the seeded DB instead of the
   mock's 591; note 2 / fund / Pip row shift by +22. The layout follows the
   same CSS box model; geometry test records the real bands.
2. K09's `k09_bugs_test.dart` fake `_CountingJarRepository` is still missing
   `watchLatestPayout` — its file name carries no `view`/`widget`, so the
   logic builder owns that fix (analysis error existed pre-my-note; flagging,
   not editing).

## Left for next iteration

- Nothing UI-side. The logic builder's 2a file does **not** exist yet as I
  write this; contract matched what I coded against. If the integrator hits
  a residual K10-only mismatch (e.g. the note-2 wrap in scenario 3's
  copy check), it belongs to that deviation.

VERDICT: PASS
