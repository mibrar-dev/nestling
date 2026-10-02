# Shared requests — P02 value tour

## 1. Compact nav-bar wide action

Need: `NestNavBar` compact mode traps `trailing`/`actionLabel` in a fixed 44px-wide slot, so a text
action like 'Skip' (Inter 16 w700, ~40px + 24px padding) ellipsises instead of fitting. P02's tour header
(HTML `.nav-bar.compact` with `.fill` + `.nav-gap` spacers and a right-aligned 'Skip') needs a
content-sized trailing slot. Suggested: size the compact trailing slot to its content (or add a wide-action
mode) while keeping the 44px minimum tap box and centred-title behaviour.

Files: `app/lib/core/design_system/components/nest_nav_bar.dart` (compact branch, ~lines 42–81).

Blocks: no — P02 ships a feature-private `_TourNav` (60px spec bar: 4 top + 44 content + 12 bottom,
right-aligned Skip built on the shared Material/InkWell action pattern with a 44-min tap target)
behind a `TODO(P02)` comment and will adopt the shared fix when it lands.

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
Blocks: no.

## 3. Design tokens for the pager metrics

Need: tokens for the P02 pager geometry that has no entry in `spacing.dart`: `.pg-stage` 52,
`.pg-pet` 158, `.pg-line` min-height 32, and the `.pv-add` dashed-row metrics (1.5px dash,
6px dash / 4px gap, r-m 16). The screen currently carries these as documented `static const`s
with their CSS sources (accepted interim per the review).

Files: `app/lib/core/design_system/tokens/spacing.dart` (and `radii.dart` if the set grows).

Blocks: no.
