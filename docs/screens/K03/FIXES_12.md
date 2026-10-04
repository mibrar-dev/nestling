# Fix list after iteration 12

## From 6_bugs.md
# K03 Kid home — bug hunt (Stage 6, iteration 12)

Adversarial pass over `kid_home` K03 after the shared speech-tail fix and the
iteration-12 integration: data edges, rapid double taps, back navigation,
deep links, restart persistence, mode guards, dark contrast, 320px + 1.3
scale, async gaps, Europe/London periods, integer money, owner rules, CHILD
ORDER, COPY, fonts, accessibility actions and the UI VERDICT RULE (±2 px).
No screen code was changed in this stage. No simulator was used.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 60 tests:
  59 run green, 1 skipped (`K03-BUG-16`, open, shared).
- Run the proof:
  `cd app && flutter test --run-skipped --plain-name K03-BUG-16`.
- Full suite: K03's own tests have zero unexpected skips; the only `skip:` in
  `app/test/` is P12's parked proof on `main`.

## Open bug

### K03-BUG-16 — The pet hero art sits ~10 px above the design (Major, shared)

**Severity: Major (UI VERDICT RULE: ±2 px required; a uniform shift is a
FAIL).**
`shared/speech_tail` (`b1137f3`) made the bubble's tail a CSS-style overflow
`::after` — correct in itself — so `NestPetStage`'s laid-out block became
10.25 px shorter. The build restored the **rows below** with
`_kStageToHearts = 21` (documented, sanctioned lever), but the **hero art
itself** (nest + Pip) still sits high, because the shared stage lays the
bubble→pet gap out as `NestSpacing.s2` (8) where the design's `.k3-pet` has
`margin: 14px auto 0`.

Measured at real fonts (390×844), design vs app:

| row | design | app now | delta |
|---|---|---|---|
| nest rim | 278 | 269.0 | −9.0 |
| bowl bottom | 364 | 355.0 | −9.0 |
| Pip head | 199 | ~190 | −9 |
| Pip feet | 301 | ~292 | −9 |
| hearts centre | 448 | 448.0 | 0 |
| progress box | 527…542 | 527…542 | 0 |
| first card top | 559 | 559 | 0 |

The build re-based `kid_home_geometry_test.dart`'s hero pins to the app's
current values (269/355/292/190) with a KNOWN-DEVIATION comment. This stage
holds the **design values** instead, so the defect cannot become permanent:
the proof below fails until the shared gap is fixed.

Failing test (skipped so the suite stays green):
- `K03-BUG-16: the pet hero art sits on the design rows`
  (`Expected within 2 of 278, Actual 269.02`).

Suggested fix (shared, SHARED_REQUEST #18): set the shared `NestPetStage`
bubble→pet gap to the design's 14 px (`NestSpacing.gap14`); the block then
runs 183…419 and every hero row lands on 278/364/301/199. K03 then reverts
`_kStageToHearts` 21 → `NestSpacing.s4` (16) — the constant's own doc comment
already records this revert rule.

## Fixed / verified this iteration

- **Speech tail** (`shared/speech_tail`, `b1137f3`): the tail is now the CSS
  `::after` solid 18×9 ink overflow, addressing the iteration-11 UI deviation
  (`NestSpeechBubble.tailWidth/tailHeight` public; UI re-capture pending).
- **Rows below the hero** stay exact via `_kStageToHearts = 21`: hearts 448,
  progress 527…542, card-1 559, dock 720, meadow rows.
- All earlier bugs 1–15 remain fixed; the a11y action suite, stream
  pipeline, child order, fonts, copy, bottom edge, alignment, periods/BST,
  tap latches, data edges, guards, contrast, persistence, money and async
  gap probes are green.

## Verified clean (probes)

| Category | Probe | Result |
|---|---|---|
| rows below the hero | hearts 448, progress 527–542, card-1 559, dock 720 (real fonts) | pass |
| hero block | design-position proof | **fails — K03-BUG-16** |
| a11y actions | presence + `performAction(tap)` real outcomes for every control | pass |
| stream pipeline | retry not stacked, mid-session error keeps list + recovers, child-switch pairing | pass |
| child order | Maya→Leo; six children in one second keep insertion order | pass |
| fonts / copy | bundled Nunito + zero tracking; strings match the HTML character-for-character | pass |
| bottom edge / alignment | surface to the edge (light+dark); 20px gutters | pass |
| periods / taps / data edges / guards / contrast / persistence / money / async gap | earlier probes | pass |

## Observations (not defects)

1. No retry affordance for a mid-session watch error (kept-list design).
2. Period rollover computes at stream-map time; no injectable clock.
3. Test wall-clock coupling (seed anchor pinned, `DateTime.now()` not).
4. Parent-mode `/kid-home` deep link and PIN bypass remain product-level
   questions; debug gallery routes unguarded.
5. Static `PipAvatar` fallback omits accessories (no seed child equips one).

## Summary

| ID | Severity | Status |
|---|---|---|
| K03-BUG-16 | **Major (UI VERDICT RULE, shared)** | **open — hero art 9–10 px high; SHARED_REQUEST #18** |
| K03-BUG-1..15 | Major..Moderate | fixed; proofs green |

The tail fix and the row-restoration lever are verified, but the hero art is
still off the design by ~9–10 px, so the screen cannot pass the ±2 px UI rule
until the shared bubble→pet gap lands. Held by a failing design-value proof
that cannot silently re-base.

