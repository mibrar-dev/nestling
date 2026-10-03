# K03 Kid home — bug hunt (Stage 6, iteration 9)

Adversarial pass over `kid_home` K03 after the shared semantics-tap batch and
the iteration-9 integration: data edges, rapid double taps, back navigation,
deep links, restart persistence, mode guards, dark contrast, 320px + 1.3
scale, async gaps, Europe/London periods, integer money, owner rules, CHILD
ORDER, COPY, fonts, and the new ACCESSIBILITY ACTIONS rule. No screen code
was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 59 tests:
  **all run green, zero skips**.
- Only the UI-check stage may use a simulator (SIMULATORS rule); this stage
  used none.

## Result: no open bugs

| ID | Severity | Status |
|---|---|---|
| K03-BUG-1..6 | Major..Minor | fixed; proofs green |
| K03-BUG-7 | Major (shared) | fixed; proof green in both flag modes |
| K03-BUG-8/9 | Minor | fixed; proofs green |
| K03-BUG-10 | Major (owner) | fixed; light + dark proofs green |
| K03-BUG-11 | Minor | fixed; proof green |
| K03-BUG-12 | Moderate (child order) | fixed (shared); proofs green |
| K03-BUG-13 | Major (owner alignment) | fixed (shared pet-stage rework); three width proofs + real-font geometry pin green |
| K03-BUG-14 | Moderate | fixed; proof green |
| K03-BUG-15 | Minor | fixed (guarded `_homeSub`); two proofs green |

## New this iteration: ACCESSIBILITY ACTIONS

The shared `semantics_tap` batch gives every interactive design-system
component a `SemanticsAction.tap` on the node that announces its label. K03
is fully covered by new adversarial probes:

- **Action presence** on every control: to-do check (`Mark done`), quest card
  body, lock (`Grown-ups`), dock `Pip`/`Shop`/`My jar`, empty-state `Choose`,
  failure `Try again` — asserted via
  `getSemantics(...).getSemanticsData().hasAction(SemanticsAction.tap)`.
- **Real outcomes via `performAction(tap)`**:
  - the check flips the `q-reading` row to `done_pending` in Drift and opens
    K05 (`K05 Quest complete`);
  - the card body opens K04 (`/quest-detail`);
  - the lock opens the parental gate;
  - `Choose` navigates to `/who-is-playing`.
- K03's two `Semantics(excludeSemantics: true)` sites (the header name/sub
  and the hearts row) are display-only, not controls — no `onTap` required.
  No violation found.

One test-side note (not a product defect): the to-do cards sit below the fold
and their semantics nodes are pruned from the tree until scrolled into view;
the probes call `ensureVisible` first. The concurrent stage-3 test in
`kid_home_view_test.dart` currently fails for exactly that reason and is
expected to be corrected there.

## Verified clean (probes)

| Category | Probe | Result |
|---|---|---|
| a11y actions | presence + performAction outcomes for every control | pass |
| pet geometry | centring at 320/390/430, 236 px slot, real-font pin (centre 195, hearts 448, card 559) | pass |
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

1. No retry affordance for a mid-session watch error (the kept-list design is
   correct; recovery needs a reload event).
2. Period rollover computes at stream-map time; no injectable clock.
3. Test wall-clock coupling (seed anchor pinned, `DateTime.now()` not).
4. Parent-mode `/kid-home` deep link and PIN bypass remain product-level
   questions; debug gallery routes unguarded.
5. Static `PipAvatar` fallback omits accessories (no seed child equips one).
6. A fresh UI capture should confirm the post-iteration-8 pet geometry and
   dark meadow on device (UI-owned).

## Summary

Zero open bugs, zero skipped proofs, and the new accessibility-action rule is
fully satisfied and independently proven (presence + real outcomes). The
remaining items are observations and the pending UI re-capture.

VERDICT: PASS
