# K03 Kid home — bug hunt (Stage 6, iteration 10)

Adversarial pass over `kid_home` K03 after the shared pet-seating fix and the
iteration-10 integration: data edges, rapid double taps, back navigation,
deep links, restart persistence, mode guards, dark contrast, 320px + 1.3
scale, async gaps, Europe/London periods, integer money, owner rules, CHILD
ORDER, COPY, fonts and accessibility actions. No screen code was changed in
this stage. No simulator was used (SIMULATORS rule).

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 59 tests:
  **all run green, zero skips** (fifth iteration running).
- Geometry pin: `kid_home_geometry_test.dart` (real bundled fonts) green —
  painted nest outline 198×86, rim 278, Pip feet 301, hearts 448, card-1 559.
- Full suite: `flutter test` → `+1579: All tests passed!`

## Result: no open bugs

| ID | Severity | Status |
|---|---|---|
| K03-BUG-1..6 | Major..Minor | fixed; proofs green |
| K03-BUG-7 | Major (shared) | fixed; proof green in both flag modes |
| K03-BUG-8/9 | Minor | fixed; proofs green |
| K03-BUG-10 | Major (owner) | fixed; light + dark proofs green |
| K03-BUG-11 | Minor | fixed; proof green |
| K03-BUG-12 | Moderate (child order) | fixed (shared); proofs green |
| K03-BUG-13 | Major (owner alignment) | fixed (shared pet-stage rework); three width proofs + geometry pin green |
| K03-BUG-14 | Moderate | fixed; proof green |
| K03-BUG-15 | Minor | fixed (guarded `_homeSub`); two proofs green |

## Iteration-10 verification

- **Pet seating** (`shared/pet_stage_seat` + `_kNestBoxHeight: 188`): all K03
  pet proofs still pass — centring at 320/390/430, 236 px slot height — and
  the real-font pin asserts the painted outline and seating (rim 278, feet
  301, hearts 448, card-1 559).
- **Quest order**: the shared quest list is creation order (schema v4) while
  K03 keeps its documented alphabetical repository order; per the
  orchestrator note (09:52: "Quest order and '4 done today' come from the
  database — not findings") this is recorded, not raised.
- **Accessibility actions** (iteration-9 rule) remain fully proven: presence
  and real outcomes for check, card body, lock, dock, Choose and Try again.
- Everything else re-ran green: periods/BST, taps, data edges, guards,
  contrast, persistence, money, async gap, fonts, copy, bottom edge and
  alignment probes.

## Verified clean (probes)

| Category | Probe | Result |
|---|---|---|
| pet geometry | centring 320/390/430, 236 px slot, real-font painted-outline pin | pass |
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
6. Quest order (creation vs K03 alphabetical) is recorded per the orchestrator
   note; a UI re-capture should confirm the remaining visual targets.

## Summary

Zero open bugs, zero skipped proofs; the iteration-10 pet-seating change is
verified by the widget proofs and the real-font geometry pin, and all
functional, data, accessibility, period, copy and owner-rule checks pass.

VERDICT: PASS
