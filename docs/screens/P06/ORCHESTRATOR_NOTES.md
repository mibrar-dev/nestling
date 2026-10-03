
## UPDATE (04:05, orchestrator QA of cmp_light_3 / cmp_dark_3) — NOT merged, iteration 4 targets
1. SEED: the manifest was wrong. P06 now uses seed `onboarding_kids`: the parent arrives here from P05 after adding children. Shoot with that seed.
   - The Weekly base card must list the family's children from the DB, in the order they were added, with their amounts and steppers: Maya £3.00, Leo £1.50, as in the design.
   - If onboarding_kids children have no weekly amount yet, the default comes from the domain/DB, never hard-coded in the view. Write a SHARED_REQUEST if the seed needs values.
2. PAYOUT DAY CHIPS overflow the card. "Mon" touches the left card border and "Sun" is clipped on the right.
   - Design: the chip row sits inside the card's 16 px padding, aligned with the "Payout day" label (x≈60 of 390 in the design) and ending at the same inset on the right.
   - Chips are 32 px high with even gaps.
   - Make all 7 fit at 390 and 320 widths (tighten the gap, or scroll at 320 only). Add a test that no chip rect leaves the card's padded rect.
3. Text widths: a shared fix (shared/letter_spacing_zero) makes NestType letterSpacing 0, because the design CSS has no tracking. Do not add local tracking.
4. Coin value icon: match the design's gold coin glyph tile, not a £ symbol. Use the existing coin asset in app/assets (NestIcons/coin) if there is one; otherwise write a SHARED_REQUEST.
5. Option cards are ~3–4 px taller than the design each: match the HTML padding and line heights so "Payout day" lands at the design y.
6. (04:31) Payout-day chips: once main contains `NestChipWrap` (shared/chip_wrap_hit_area), use it for the chip row so each chip keeps its 44 px tap target. Test this with taps 5 px above and below a chip.

## UPDATE (05:36) — the UI builder for this iteration hit Fledge's rate limit and did not finish
Integrator: there is no fresh 2b_build_ui report this iteration. YOU must also make the UI fixes in the current FIXES list and the notes above. Check the views on disk: the UI builder may have left partial edits, so keep the correct ones and finish the rest.

## UPDATE (07:22, orchestrator QA of cmp_light_4, 2.22%) — exact targets for iteration 5
Seed, chips and coin icon are now right. What is left is vertical drift INSIDE the payout card. Measured on the 390-wide compare sheet, design → app:
- "Payout day" label: y 524 → 524 ✓
- day-chip row centre: 555 → 561 (+6). The gap from the label to the chips is 6 px too big; match the HTML (label → chip row gap).
- "Weekly base" label: 597 → 609 (+12). The divider above it and the label spacing add another +6; match the HTML section padding.
- Maya row centre 630 → 642, Leo 674 → 686, "Coin value" 735 → 747 (all +12, inherited from the above).
Fix the two spacings so every element lands within ±1 px. Add a geometry test with real fonts (FontLoader, as app/test/features/privacy_consent/privacy_consent_geometry_test.dart does) that pins these y values at 390×844.
- Stepper glyphs: the design's minus is "−" (U+2212), drawn as a full-width bar like the "+". The app renders a short hyphen "-". Use the same icon/glyph source for − and + so they match in weight and width; check the HTML for the exact glyph.
- Also fix every item the test and review stages listed in FIXES_4.md.
