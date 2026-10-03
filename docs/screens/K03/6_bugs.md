# K03 Kid home — bug hunt (Stage 6, iteration 8)

Adversarial pass over `kid_home` K03 after the iteration-8 integration (shared
pet-stage fix, guarded load subscription, meadow gradient, speech bubble):
data edges, rapid double taps, back navigation, deep links, restart
persistence, mode guards, dark contrast, 320px + 1.3 scale, async gaps,
Europe/London periods, integer money, owner rules, CHILD ORDER, COPY, fonts
and the reworked stream pipeline. No screen code was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 53 tests:
  **all run green, zero skips** (first time in the loop).
- Independent geometry pin: `kid_home_geometry_test.dart` (real bundled
  fonts) runs un-skipped and passes — slot 20…370, nest/Pip centre 195,
  hearts 448±2, first card 559±2.
- Full suite: `flutter test` → `+1361: All tests passed!`

## Result: no open bugs

Every bug found across the eight iterations is fixed and re-verified:

| ID | Severity | Area | Status |
|---|---|---|---|
| K03-BUG-1..6 | Major..Minor | duplicate completions, celebration-before-save, swallowed failures, "done today" periods, router guard, stacked routes | fixed; proofs green |
| K03-BUG-7 | Major | `DISABLE_ANIMATIONS=1` parse | fixed (shared); proof green in both modes |
| K03-BUG-8/9 | Minor | celebration swallow, lock route stacking | fixed; proofs green |
| K03-BUG-10 | Major (owner) | bottom edge surface | fixed; light + dark proofs green |
| K03-BUG-11 | Minor | silent no-op latch | fixed; proof green |
| K03-BUG-12 | Moderate | child order | fixed (shared); proofs green |
| K03-BUG-13 | Major (owner) | pet slot off-centre / clipped | **fixed (shared `shared/pet_stage_explicit`)**; three width proofs + geometry pin green |
| K03-BUG-14 | Moderate | pet block height 276 → 236 | **fixed**; proof green |
| K03-BUG-15 | Minor | "Try again" stacked live subscriptions | **fixed** (guarded `_homeSub`, cancel-before-reload, release on error/close); two proofs green |

## New probes added this stage (passing)

1. **Mid-session stream error** — after a loaded state, an error keeps the
   list (`status` stays `loaded`) and releases the subscription; a fresh
   `KidHomeLoadRequested` re-subscribes and recovers. This pins the
   iteration-8 review-finding-6 behaviour so it cannot regress silently.
2. **Child switch consistency** — with the real Drift repository, switching
   `active_child_id` from Maya to Leo never pairs a child with the previous
   child's items (every emitted state's quest ids end with the paired child
   id); Leo's own list arrives.

## Verified clean (probes)

| Category | Probe | Result |
|---|---|---|
| pet geometry | centring at 320/390/430, 236 px slot height, real-font pin (centre 195, hearts 448, card 559) | pass |
| stream pipeline | retry not stacked, mid-session error keeps list + recovers, child-switch pairing | pass |
| iteration-7 UI | balanced title at the 20 px edge, per-quest tile tints, dock labels never wrap | pass |
| child order | Maya→Leo; six children in one second keep insertion order | pass |
| fonts / copy | bundled Nunito + zero tracking; strings match the HTML character-for-character | pass |
| bottom edge | light + dark surface to the physical edge under a 34px inset | pass |
| alignment | 20px gutters on bar, cards and dock | pass |
| periods | day/week boundaries, daily/weekly/once, BST switch days | pass |
| taps | same-frame double taps → one row / one route; silent no-op retry | pass |
| data edges | 0 / 1 / 6 children; long name + 9999 coins at 320/1.3; no `£` | pass |
| back nav / deep links / restart / guard / contrast / money / async gap | earlier probes | pass |

## Observations (not defects)

1. **No retry affordance for a mid-session watch error.** The design keeps
   the last list (correct), but the loaded screen has no control to
   re-subscribe; recovery needs a fresh load event (restart or navigation).
   A silent reconnect on transient Drift errors would close the loop; the
   error is not user-visible today.
2. Period rollover computes at stream-map time (no injectable clock).
3. Test wall-clock coupling: the seed anchor is pinned, `DateTime.now()` is
   not.
4. Parent-mode `/kid-home` deep link and PIN bypass remain product-level
   questions; debug gallery routes unguarded.
5. Static `PipAvatar` fallback omits accessories (no seed child equips one).
6. The iteration-7 UI report (FAIL, pet geometry + dark meadow) predates the
   iteration-8 shared fix; the geometry pin now passes and the meadow
   gradient landed, so a fresh UI capture should confirm. UI-owned, not a
   bug finding here.

## Summary

Zero open bugs, zero skipped proofs: the functional, data, accessibility,
period, copy and owner-rule suites all pass, and the last major (pet-slot
geometry) is fixed by the shared component with both the widget proofs and
the real-font geometry pin. The remaining items are observations and the
pending UI re-capture.

VERDICT: PASS
