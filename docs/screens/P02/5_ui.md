# P02 Value tour — Stage 5 UI check (iteration 1)

Route `/value-tour`, seed `fresh`, mode `parent`, child `maya`, simulator
604697A9-11DA-462F-9837-396E9CA2493A (390×844). No `ORCHESTRATOR_NOTES.md`
exists; orchestrator stage-prompt rules apply (Pip = `PipAvatar` mochi/sunny,
status-bar differences ignored, bottom-edge owner rule enforced).

Shots: `docs/screens/P02/ui/app_light_1.png`, `app_dark_1.png`
(stable-frame wait timed out on both — see item 6).
Compares: `cmp_light_1.png`, `cmp_dark_1.png`.

## Mean diff

- Light: **6.50%** (bands: 0: 2.14, 1: 7.94, 2: 6.03, 3: 9.37, 4: 5.10,
  5: 7.01, 6: 10.60, 7: 3.80). Band 0 is the OS status bar (ignored per
  orchestrator rule).
- Dark: **6.41%** (bands: 0: 2.09, 1: 7.84, 2: 6.49, 3: 8.99, 4: 4.61,
  5: 7.42, 6: 11.09, 7: 2.70). Same pattern as light.

Dark-mode token colours sampled identical to design (bg #15131F, card
#1F1C2E, CTA leaf, CTA strip surface to the physical edge). All layout
deviations below apply to both themes.

## What matches (checked, no action)

Gutters/card geometry in x (card left x=20, right x=330, peek card at
x=342 in both); dots (18 h, 22 px active leaf pill, centred); Next button
(y 742–792, geometry and leaf identical both themes); progress 4/6 +
caption copy; chips (`Sat 4 Oct`); icon glyphs + tile tints
(sky/coin/lilac/peach); dashed `New quest` row style (15 w600 ink2, 1.5 px
dashed line, r16); CTA side padding 20; no overflow/clipping; bottom edge
is bar-surface colour to the screen edge (design PNG shows paper there,
but the owner bottom-edge rule overrides the PNG — app is correct).

## Deviations (all measured in logical px, design ÷ 3)

1. Quest-row titles ellipsised (MAJOR). Element: card-1 preview rows.
   Design value: full names on one line — `Empty the dishwasher`,
   `Put the bins out`, `Reading – 20 minutes`, `Tidy your bedroom`
   (15 px semibold, fits the ~174 px text slot). App value: `Empty th…`,
   `Put the bi…`, `Reading –…`, `Tidy your…` — all four titles truncated
   with ellipsis. Fix: shrink the row's fixed costs to the design values
   (tile 36 r12, row gap 8, small coin pill, 15 px title — shared
   `NestListRow` currently spends ~20 px more per row via 40 tile / 12
   gaps / larger pill / 16 px title) or file a SHARED_REQUEST for a
   compact preview-row variant; do not fork shared components locally.

2. Card 1 is 68 px too tall; below-card composition cramped (MAJOR).
   Element: pager card + dots/title/body block. Design value: card
   310×400 (top y≈107, bottom y≈507), dots y≈534–540, step title
   y≈584–604, body y≈634–668, body-to-button gap ≈74 px. App value: card
   top y≈99, white card region runs to y≈567 (≈468 tall), dots y≈594–600,
   title y≈644–664, body y≈690–722, body-to-button gap ≈20 px. Row pitch
   is ≈72 px vs design 50 px (`NestListRow` compact min-height/padding
   wins over the design's 38 px rows). The code comment on `_pagerBaseH`
   (468) documents this trade-off, but the visible result — title/body
   jammed against the CTA — is a designer-reject. Fix: make card-1
   content fit 400 px (compact rows per item 1, or per-row fixed 38 px
   preview layout), restore pager base to 400, keeping cards 2–3 on
   `Spacer`.

3. Step-body punctuation (MINOR). Element: step-1 body copy. Design value:
   `Pick from 40+ ready-made jobs like “Put the bins out” — or make your
   own.` (curly quotes, em dash). App value:
   `Pick from 40+ ready-made jobs like 'Put the bins out' or make your
   own.` (straight quotes, no dash; matches DESIGN_SPEC §5 P02 and the
   repo strings, conflicts with the HTML/PNG). Fix: orchestrator to rule
   which source wins; if the PNG wins, update repo strings + view const.

4. Tour nav 8 px too short (MINOR). Element: Skip bar. Design value:
   compact nav totals 60 px (44 content + 4 top + 12 bottom padding), card
   top y≈107. App value: `SizedBox` 52 px, card top y≈99. Fix: give
   `_TourNav` the spec paddings (total 60) instead of a fixed 52 box.

5. Chip height +3 px (COSMETIC). Element: `Sat 4 Oct` chip. Design value:
   32 px. App value: ~35 px (1.5 px border folds into the `Container` decoration padding, as the code comment notes). Fix: accept
   as shared-component drift or pick up the shared fix; not a reject alone.

6. Frames never stabilise under `DISABLE_ANIMATIONS=1` (MAJOR, motion
   rule). Both `shot.sh` runs exited `WARNING — frame never stabilised in
   25 s`. RULES §6 requires a still frame when animations are disabled.
   Prime suspect: `PipAvatar` Rive instances on the eagerly-built adjacent
   pager card keep ticking (4 avatars once page 2 builds). Fix: verify
   `PipAvatar` renders its SVG still frame when `kDisableAnimations` /
   `MediaQuery.disableAnimations` is set, so screenshots are
   deterministic.

## Coverage gap (not a failure)

Iteration 1 captures step 1 only. Cards 2–3 (Pip nest, jar) and steps
2–3 copy/CTA (`Continue`) were verified in widget tests but not
pixel-compared; capture pages 2–3 in the next iteration.

VERDICT: FAIL
