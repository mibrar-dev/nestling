# P06 Pocket money setup — Stage 6 adversarial bug hunt (iteration 4)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). `ORCHESTRATOR_NOTES.md` exists — every item is verified
below. This stage changed no screen code: only
`app/test/features/pocket_money/p06_bugs_test.dart` and this report.

Method: re-verify every earlier repro against the iteration-4 build, then
attack the new geometry/logic and independently verify all six orchestrator
notes (including shooting seed, chip rects, `NestChipWrap` hit slop, gold coin
tile, option-card line heights).

Suite state: `flutter test test/features/pocket_money/p06_bugs_test.dart` →
**+24 ~1: All tests passed!** The single skip is `P06-BUG-04`, a proof whose
demand the orchestrator superseded (kept for history, comment explains why).
`flutter analyze` on the file → No issues found.

## Open bugs

**None.** No skipped failing repro is outstanding; the one `skip: true` is the
superseded P06-BUG-04.

## Earlier findings — all fixed (unskipped guards in `p06_bugs_test.dart`)

| # | Severity (was) | Iteration-4 state | Guard |
|---|---|---|---|
| 01 | **major** stepper lost rapid taps | fixed (iter 3, `_requestedBase`) | `P06-BUG-01/01b/01c (fixed)` real repo: 2 taps → £4.00, 3 → £4.50, `+−` → £3.00 |
| 02 | minor fast day-tap dropped | fixed (iter 3, `_pendingDay`) | `P06-BUG-02 (fixed)` → Sat; **02b** three rapid taps Sun→Sat→Mon → Mon |
| 03 | minor pill painted ~19dp | fixed (iter 3/4 `_DayPill`) | `P06-BUG-03 (fixed)` → 32 ± 2, label 13px |
| 04 | minor day cells 40.3dp wide | **superseded** by ORCHESTRATOR_NOTES #2 (chips inside the 16px inset) | `P06-BUG-04` skip + comment; replaced by the inset/geometry guard below |
| 05 | minor failed write blanked form | fixed (iter 3, inline error) | `P06-BUG-05 (fixed)` → form + `database is locked`, no Retry |
| 06 | minor stale `errorMessage` | fixed (iter 3, `clearErrorMessage`) | `P06-BUG-06 (fixed)` → null after recovery |
| 07 | minor unknown-child write | fixed (iter 3, early return) | `P06-BUG-07 (fixed)` → no writes |
| 08 | minor day row broke out of card inset (22 vs 36) | fixed (iter 4; row back at 16px) | `P06-BUG-08 (fixed)` → first chip left == label left |
| 09 | minor correction dropped after unrelated re-emission | fixed (iter 4; pending day cleared only on confirmation) | `P06-BUG-09 (fixed)` → writes `[7, 6]` |

## ORCHESTRATOR_NOTES verification (iteration 4)

| Note | Evidence (this stage, independent) |
|---|---|
| 1. Seed `onboarding_kids`; children from the DB in insertion order with their amounts; no view-side defaults | `seed onboarding_kids…` guard: `Seed.onboardingKids` → route renders Maya then Leo, `£3.00`/`£1.50`, both steppers labelled; values come from `children.weekly_base_pence` (seed `_childrenDemo`) |
| 2. Chips inside the card's 16px padding, 32px high, even gaps, all 7 fit at 390 and 320; no chip rect leaves the padded rect | geometry guard at 390/320/430: pills 40.28/30.28 wide × **32.0** high, first left = 36.0 = card inner left, last right = 353.93 ≤ 354.0, gaps all 6.00 ± 0.2 |
| 3. `letterSpacing` 0, no local tracking | P06 uses `NestType.h1` (no tracking), `bodyStrong`, `bodySmall`, `fieldLabel`, `caption`, `money` — none pass `letterSpacing`; no `.copyWith(letterSpacing:)` in the feature |
| 4. Gold coin glyph tile, not a `£` symbol | coin-tile guard: `SvgPicture` with `SvgAssetLoader.assetName == NestlingIllustrations.coin` (`assets/illustrations/coin.svg`) inside the 40×40 `coinTint` Container, wrapped in `ExcludeSemantics` |
| 5. Option cards match the HTML padding/line heights so the settings card lands at the design y | option-card guard: title 16 × `22/16`, sub 15 × `20/15` (HTML `.opt-title 16/22` + `.opt-sub 15/20` + `.opt-text gap:2`); measured card height at 390 (Ahem test font wraps subs to 2 lines, so height itself is font-dependent and asserted structurally) |
| 6. `NestChipWrap` for the chip row; taps 5px above/below a chip | `NestChipWrap` guard: tap 5px above Sun selects Sun, 5px below Mon selects Mon, and a gap tap 1px right of Mon forwards to Mon (44-tall row + ±6px slop) |

## Notes, not bugs

- **BALANCED HEADINGS — blocked on the main merge, not actionable here.**
  The design CSS has `.h1 { text-wrap: balance }`, so P06's H1 will need
  `NestBalancedText` once main's `58b42de` (the shared component
  `nest_balanced_text.dart`) is merged into this branch. It is **not present
  in this worktree** (`grep balanced lib` → nothing; `git merge-base
  --is-ancestor 58b42de HEAD` → false), so the H1 stays a plain `Text` this
  iteration. Hand this to the next build after the merge; until then the
  compare's 2-line break matches the design.
- **320dp × text scale 1.3 day labels ellipsize** (`Mon`/`Wed` are the tight
  ones). At 320 the 13px labels get 30.28px cells; scaled to 16.9px they need
  ~35px. SPACING_SPEC §10.1 explicitly sanctions `maxLines: 1 +
  overflow: ellipsis` for chip text at large scales, and at 1.0 the real Inter
  metrics fit, so this is accepted behaviour — recorded here because §10.3
  alternatively mentions `scaleDown`. No repro filed.

## Attacks that hold (unchanged guards, all green)

- Kid-mode deep link → `/parental-gate`; restart persistence on a file-backed
  DB (mode/day/base + insertion order); 6 children incl.
  “Maximilian-Alexander” at 320 × 1.3; 0 children caption; £0.00/£20.00 exact
  (every pence 0…2000 brute-forced); close-during-write contained; WCAG 4.5:1
  light + dark; two immediate widget `+` taps → £4.00.

## Verdict rationale

All nine findings from iterations 2–3 are fixed and carried as unskipped
regression guards (24 green), the one superseded proof is documented, and all
six orchestrator notes verify independently in tests. No open bug has an
executable repro; the only un-actionable rule (balanced H1) is blocked by the
main merge, not by this screen. Nothing found that a designer or user would
reject.

VERDICT: PASS
