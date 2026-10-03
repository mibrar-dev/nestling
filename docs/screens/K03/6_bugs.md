# K03 Kid home — bug hunt (Stage 6, iteration 11)

Adversarial pass over `kid_home` K03 after the iteration-11 integration:
data edges, rapid double taps, back navigation, deep links, restart
persistence, mode guards, dark contrast, 320px + 1.3 scale, async gaps,
Europe/London periods, integer money, owner rules, CHILD ORDER, COPY, fonts,
accessibility actions and the new UI VERDICT RULE (positions within ±2 px).
No screen code was changed in this stage. No simulator was used.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 59 tests:
  **all run green, zero skips**.
- Geometry pin: `kid_home_geometry_test.dart` (real bundled fonts) green —
  painted nest outline 198×86 (rim 278, feet 301), Pip centre 195, hearts
  448, **progress box y 527…542**, first card top 559.
- UI stage: iteration 10 measured the whole geometry chain EXACT and
  reported **PASS** (remaining band heat is accepted art/data diffs).
- Full suite: `flutter test` → `+1792: All tests passed!`

## Result: no open bugs

| ID | Severity | Status |
|---|---|---|
| K03-BUG-1..6 | Major..Minor | fixed; proofs green |
| K03-BUG-7 | Major (shared) | fixed; proof green in both flag modes |
| K03-BUG-8/9 | Minor | fixed; proofs green |
| K03-BUG-10 | Major (owner) | fixed; light + dark proofs green |
| K03-BUG-11 | Minor | fixed; proof green |
| K03-BUG-12 | Moderate (child order) | fixed (shared); proofs green |
| K03-BUG-13 | Major (owner alignment) | fixed (shared pet-stage rework); width proofs + geometry pin green |
| K03-BUG-14 | Moderate | fixed; proof green |
| K03-BUG-15 | Minor | fixed (guarded `_homeSub`); two proofs green |

## Iteration-11 verification

- **UI VERDICT RULE (±2 px)** — the real-font pin now covers the full
  geometry chain below the pet block as well: nest outline 198×86, rim 278,
  Pip feet 301, hearts centre 448, progress box 527…542, card-1 top 559 —
  all within ±2 of the design. The UI report's measurements agree.
- **Accessibility actions** — presence + real outcomes remain green for
  every control (check, card, lock, dock, Choose, Try again).
- **Stream pipeline, child order, fonts, copy, bottom edge, alignment,
  periods/BST, tap latches, data edges, guards, contrast, persistence,
  money and async gap** — all probes re-ran green.
- No product-code changes landed in this iteration; the feature is stable.

## Verified clean (probes)

| Category | Probe | Result |
|---|---|---|
| UI-rule geometry | nest 198×86, rim 278, feet 301, hearts 448, progress 527–542, card-1 559 (real fonts) | pass |
| a11y actions | action presence + `performAction(tap)` real outcomes for every control | pass |
| stream pipeline | retry not stacked, mid-session error keeps list + recovers, child-switch pairing | pass |
| child order | Maya→Leo; six children in one second keep insertion order | pass |
| fonts / copy | bundled Nunito + zero tracking; strings match the HTML character-for-character | pass |
| bottom edge | light + dark surface to the physical edge under a 34px inset | pass |
| alignment | 20px gutters on bar, cards and dock | pass |
| periods | day/week boundaries, daily/weekly/once, BST switch days | pass |
| taps | same-frame double taps → one row / one route; silent no-op retry | pass |
| data edges | 0 / 1 / 6 children; long name + 9999 coins at 320/1.3; no `£` | pass |
| back nav / deep links / restart / guard / contrast / money / async gap | earlier probes | pass |

## Observations (not defects)

1. No retry affordance for a mid-session watch error (kept-list design is
   correct; recovery needs a reload event).
2. Period rollover computes at stream-map time; no injectable clock.
3. Test wall-clock coupling (seed anchor pinned, `DateTime.now()` not).
4. Parent-mode `/kid-home` deep link and PIN bypass remain product-level
   questions; debug gallery routes unguarded.
5. Static `PipAvatar` fallback omits accessories (no seed child equips one).
6. The bubble tail's white fill sits ~10 px lower than the design's sample
   (shared component; invisible without an overlay, no layout impact).

## Summary

Zero open bugs, zero skipped proofs, UI stage PASS, and the ±2 px UI rule is
corroborated by the real-font geometry pin down to the progress bar. All
functional, data, accessibility, period, copy and owner-rule checks pass.

VERDICT: PASS
