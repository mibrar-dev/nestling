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

## 2. Compact preview-row variant (matches `.pv-row`)

Need: a compact list-row variant at the P02 pager metrics — no vertical row padding, title 15/20
w600 single-line ellipsis, subtitle 13/18 single-line ellipsis, internal gap 8, 36px tile (r12,
icon 22) with the small coin pill — so a row measures 38dp like the design's `.pv-row`
(`design/html-source/screens/P02-value-tour.html:29-33`, SPACING_SPEC §7). `NestListRow`
(even `compact: true`) is 60dp: 20px of row padding plus 22px/18px title/subtitle lines, which
overflows the spec-fixed 400dp pager and truncates every preview title on device
(`docs/screens/P02/ui/app_light_1.png`, P02-BUG-1/BUG-2).

Files: `app/lib/core/design_system/components/nest_list_row.dart` (`compact` branch, ~lines 31-32).

Blocks: no — P02 ships feature-private `ValueTourPreviewRow`
(`app/lib/features/onboarding/presentation/widgets/value_tour_preview_row.dart`, P02-only, built
from shared `NestIcon`/`NestCoinPill`/tokens at the `.pv-row` metrics) and will retire it for the
shared variant when it lands.

## 3. Design tokens for the pager metrics

Need: tokens for the P02 pager geometry that has no entry in `spacing.dart`: `.pg-stage` 52,
`.pg-pet` 158, `.pg-line` min-height 32, and the `.pv-add` dashed-row metrics (1.5px dash,
6px dash / 4px gap, r-m 16). The screen currently carries these as documented `static const`s
with their CSS sources (accepted interim per the review).

Files: `app/lib/core/design_system/tokens/spacing.dart` (and `radii.dart` if the set grows).

Blocks: no.
