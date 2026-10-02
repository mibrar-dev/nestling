# Shared requests — P02 value tour

## 1. Compact nav-bar wide action — DONE (landed in batch 1, adopted)

The shared compact trailing slot is now content-sized with a 44 minimum, so
P02 retires its feature-private `_TourNav` and uses `NestNavBar(compact:
true, actionLabel: 'Skip', onAction: …)` plus an 8px outer pad that keeps
Skip on the 20px owner gutter (design nav inset is 12px).

Files: was `app/lib/core/design_system/components/nest_nav_bar.dart`.

Blocks: no.

## 2. Compact preview-row variant — WITHDRAWN (solved locally)

The P02-only `ValueTourPreviewRow` now covers the `.pv-row` metrics
permanently (38dp rows composed from shared `NestIcon`/`NestCoinPill`/tokens,
plus a `FittedBox(scaleDown)` title slot so design names render in full at
390dp under any font rendering — ORCHESTRATOR_NOTES 3). No shared change is
needed for this screen anymore; keeping this note only as provenance. A
shared compact-row variant remains desirable for the design system in general
but nothing on P02 blocks on it.

Files: none (was: `app/lib/core/design_system/components/nest_list_row.dart`).

Blocks: no.

## 3. Design tokens for the pager metrics — DONE (landed in batch 1, adopted)

`NestPager` (`stage` 52, `pet` 158, `lineMinHeight` 32, `addDashWidth` 1.5,
`addDashLength` 6, `addDashGap` 4, `addMinHeight` 44) covers every pager
metric; P02's private consts are retired except the 40px stage-dot art
(which has no token).

Files: was `app/lib/core/design_system/tokens/spacing.dart`.

Blocks: no.

## 4. Shared push/pop contract expects the P02 placeholder title — DONE
(orchestrator rewrote the shared test)

The orchestrator replaced the view-string assertions with router-location
assertions (`GoRouter.state.uri` before/after push/pop), so the contract no
longer depends on placeholder titles and passes with the implemented screen.
No screen change was needed.

Files: was `app/test/app/router_push_test.dart`.

Blocks: no.

## 5. Chip border-box (1.5px border inflates every chip by 3px)

Need: `NestChip` draws its 1.5px `Border.all` OUTSIDE the 32px content box
(`Container` folds decoration border into effective padding), so every chip
measures 35px instead of the spec 32. Measured consequences on P02: card-1's
first tile sits at y173 vs the design's y170 (+3 through the card body), and
card 2 only fits the restored 400dp pager because `.pg-stages` was shaved
from the spec 10 to 9 (`value_tour_view.dart` stages gap, `NestSpacing.gap9`).
Suggested: border-box the chip (reserve the 1.5px border inside a 32px box,
or inset the border), then P02 restores `NestSpacing.gap10` on card 2.

Files: `app/lib/core/design_system/components/nest_chip.dart` (static
branch, ~lines 26-33).

Blocks: no — P02 absorbs the +3 locally (documented `gap9`); restoring
`gap10` waits for the shared fix.
