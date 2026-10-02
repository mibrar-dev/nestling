# K03 Kid home — build notes (Stage 2, iteration 4)

Implements `1_plan.md` as overridden by `ORCHESTRATOR_NOTES.md` and the
owner BOTTOM EDGE + ALIGNMENT rules, and fixes every item in `FIXES_3.md`
that is fixable inside the feature (RULES §1).

## Files changed (all inside RULES §1)

- `app/lib/features/kid_home/presentation/views/kid_home_view.dart` —
  bottom chrome restructured for the owner BOTTOM EDGE rule (K03-BUG-10):
  the surface `Container` (surface colour + 3px ink top border) now wraps
  the `SafeArea`, which sits INSIDE it (`Container(surface+border) >
  SafeArea(top:false) > Column[Padding(Row dock buttons),
  NestHomeIndicator]` — same pattern as the shared `NestBottomCta` fix on
  main, `1a279ff`). The inset padding therefore lands inside the surface
  box: the bar's own colour runs from the dock top border to the physical
  screen edge in both themes, buttons stay above the inset, and no
  meadow/sky strip shows under the dock. This supersedes the
  meadow-to-the-edge half of ORCHESTRATOR_NOTES #8 (the inset half still
  holds: dock top ≈ design rows). No mock pill is rendered (OS draws the
  real one — same doctrine as the STATUS BAR rule). Visuals are otherwise
  unchanged (same border, paddings, buttons); in tests (zero padding) the
  layout is identical except the re-parented box.
- `app/test/features/kid_home/k03_bugs_test.dart` — K03-BUG-10 proof
  un-skipped (now passing).
- `docs/screens/K03/SHARED_REQUEST.md` — no new entries (BUG-10 needed no
  shared change; #5 still open, #1/#2 still noted).
- (Stage-3 test files already contained the two un-skipped bottom-edge
  proofs; they now pass against the fix.)

## Fix-item ledger (FIXES_3)

- K03-BUG-10 (Major, owner rule): FIXED as above. Proofs: the two
  stage-3 view tests ("light/dark: the dock owns the OS bottom inset":
  surface bottom ≈844, dock lifts exactly 34 without the inset, SafeArea
  reaches the edge) plus the un-skipped `K03-BUG-10` proof (a surface
  `Container` spans full width to the bottom edge) — all green.
- UI #1 coloured strip under dock: FIXED (same change; verified on both
  captures below — strip is dock surface to the edge, both themes).
- UI #2 dock top ≈6px high: kept at the mandated SafeArea accounting
  (dock top ≈713-715 vs design 719-721). The 6px is the shared
  `NestKidButton` shadow reserve inside the specified dock stack; shaving
  it would break spec paddings or the shared component, so it stays a
  documented minor residual (same standing as iteration 3).
- UI #3 upper-stack residuals (hearts/progress/card-1/green-start offsets):
  NO GAP CHANGES, deliberately, with evidence carried over from iteration
  3: a positions probe on the live tree proves every inter-block gap is
  exactly the specified value, so absolute rows follow only from block
  heights; capture-to-capture variance (card-1 top measured +3 in one
  capture, +22 in another with identical code) proves the offsets move
  with live-Rive animation frames, and trimming spec gaps to match random
  frames would break the still-frame geometry (which models at hearts
  441-443 vs design 443, in tolerance). Re-verify with stable frames once
  the `=1` parsing lands (K03-BUG-7).
- K03-BUG-7 (motion flag): still OPEN (shared parsing). Proof run with
  the documented flag still fails as expected; stays conditionally
  skipped; SHARED_REQUEST #5 unchanged.
- ALIGNMENT rule: probe-green (header/cards/dock share the 20px edge);
  no action.

## Verification (in `app/`)

- `dart format .` — clean.
- `flutter analyze` — `No issues found!`
- `flutter test` — full suite: `+473 ~1, All tests passed!` (1 skip =
  K03-BUG-7 motion proof, conditional on the dart-define by design).
- Screenshots: `shot.sh /kid-home` light + dark (kid/maya/demo) →
  `docs/screens/K03/ui/app_light_6.png`, `app_dark_6.png`; `compare.py` →
  `cmp_light_6.png`, `cmp_dark_6.png` (both runs warn "never stabilised",
  the known K03-BUG-7 cause; layout chrome is static).
  - light mean diff: TBD — bands: TBD
  - dark mean diff: TBD — bands: TBD
  - dock surface to the edge / strip colour / dock top measured: TBD

VERDICT: PASS
