# P07 Paywall — Stage 2b UI chunk (iteration 4)

Scope: UI layer only — `app/lib/features/paywall/presentation/views/**`,
`presentation/widgets/**`, and view/widget tests in
`app/test/features/paywall/`. The 2a report records no contract change
this iteration; view code still consumes the iteration-3 bloc/seams.

## FIXES_3 items landed

1. **P07-BUG-13 (legal-link labels top-aligned)** — root cause: the
   iteration-3 `softWrap:false` link Text is given its parent chain's
   constraints; the `ConstrainedBox` min-height forces the
   `RenderParagraph` to 44px tall and a paragraph paints its line at the
   **top** of its box, 13px above the centred `·` separators. Fix in
   `_LegalLink`: an inner `Padding` with
   `vertical: (NestDevice.tapParent - 18) / 2` (13) lifts the single 13/18
   line to the geometric centre of its 44px target. The maths tracks the
   1.3 × text-scale case too: centre-of-text is always half the box. The
   skipped proof (baseline equality between `Terms` and `·`) is un-skipped
   and green; the coordinator's baseline sample now reads ≈ 25.25 from the
   box top for both glyph families.
2. **5_ui iteration-3 deviation 2 (`·` separators dropped)** — resolved as
   a consequence: with both glyph families centred in the same 44px band,
   they share one baseline. The device shot confirms it (the dots no longer
   hang below the link row).
3. **ORCHESTRATOR_NOTES: iteration-4 update** — item 1 (benefit-4 wrap):
   not a code change on my side; budget merged fd92d95 set
   `NestType.letterSpacing = 0` which restores HTML-matched advance widths.
   Verified: the fresh pair of light/dark shots now render
   `Co-parent sharing, so James sees the same` on one line, and the plan
   card's tag line `One price, the whole family` is fully visible above the
   CTA panel — the deviation is gone.
   Item 2 (same 44px centred box for separators): covered by the
   BUG-13 centring — the powered box stays 44px (Wrap runs height) and the
   baseline proof holds.
   Item 3 (title orphan “days”): accepted, no hard break (copy pin).

## Files changed

- `app/lib/features/paywall/presentation/views/paywall_view.dart` —
  `_LegalLink` gains the vertical-centring inset on its inner `Padding`
  (the only view edit this iteration).
- `app/test/features/paywall/p07_bugs_test.dart` —
  `[P07-BUG-13] the legal links share the separators’ baseline`
  un-skipped (green).

## Verification (this chunk)

- `flutter analyze lib/features/paywall` → `No issues found!`
- `flutter test test/features/paywall/` → `+107 ~2` all passed
  (the 2 skips are the shared BUG-8/9 proofs; `SHARED_REQUEST.md`).
- `dart format` clean (15 files, 0 changed).
- Real-device light + dark shots
  (`docs/screens/P07/ui/app_light_4.png`, `app_dark_4.png`): legal row on
  one line with `·` separators on the link baseline, benefit 4 on one
  line, plan card & tag fully above the CTA panel, bottom edge still
  runs to the physical edge in both themes.
- `compare.py` vs the design PNGs: light **2.56%**, dark **2.48%** mean
  diff (iteration 3: 5.48% / 5.28%). Remaining drift is the hero Pip
  artwork (intentional `PipAvatar` override) plus font-advance rounding.

## LEFT FOR NEXT ITERATION

- None in the UI layer. The remaining skips are the shared-code findings
  (BUG-8 expired-trial evaluation, BUG-9 kid-mode guard ordering) in
  `SHARED_REQUEST.md` — fixable only by the shared-code owners.

VERDICT: PASS
