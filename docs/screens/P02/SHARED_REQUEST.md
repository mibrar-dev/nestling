# Shared request — P02 compact nav-bar wide action

Need: `NestNavBar` compact mode traps `trailing`/`actionLabel` in a fixed 44px-wide slot, so a text
action like 'Skip' (Inter 16 w700, ~40px + 24px padding) ellipsises instead of fitting. P02's tour header
(HTML `.nav-bar.compact` with `.fill` + `.nav-gap` spacers and a right-aligned 'Skip') needs a
content-sized trailing slot. Suggested: size the compact trailing slot to its content (or add a wide-action
mode) while keeping the 44px minimum tap box and centred-title behaviour.

Files: `app/lib/core/design_system/components/nest_nav_bar.dart` (compact branch, ~lines 42–81).

Blocks: no — P02 ships a feature-private `_TourNav` (52 min-height, right-aligned Skip, 44-min tap target)
behind a `TODO(P02)` comment and will adopt the shared fix when it lands.
