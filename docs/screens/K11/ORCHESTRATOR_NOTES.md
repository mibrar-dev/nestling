
## UPDATE (02:40) — mandatory
- The SHARED_REQUEST (nine design badges in the seed) is being done on branch shared/k11_badges_seed by the orchestrator; it will be merged to main and the loop merges main before the next build. Do not edit seed.dart yourself.
- Badge art: every one of the nine ids must render its own design medal (bins-out bin, biscuit-sitter paw/biscuit, tidy-hero basket, early-bird sun, plant-waterer can) in BOTH earned and locked states, light and dark, matching design/screens/*/K11-badges.png. The generic rosette fallback is only for ids not in the design. Remove the `TODO(K11)` once done.
- (03:04) Fix K11-BUG-2 in the next build: never fall back to a hard-coded 'maya' child. With no active child, use the session's first child in creation order; with no children at all, show the empty state. Fix K11-BUG-1 too: clamp happyDays to 0..7 before drawing the week card.

## (06:55) Next build — locked medal art (mandatory)
- The HTML's locked `<circle>` has TWO stroke attributes (`stroke="#1E1B3A" … stroke="#6E6A8A"`). HTML parsing keeps the FIRST duplicate attribute, so the design PNG paints the dashed ring in INK (#1E1B3A in light), 3 px, dasharray 5 4. The app paints it with #6E6A8A (too light) — fix to the ink colour.
- The ribbon `<path>` has `opacity=".4"` on the whole element: its fill AND its 3 px ink stroke are both drawn at 40 %. The app's ribbon outline is too dark — apply the 0.4 to fill and stroke together (e.g. `Opacity`/saveLayer), not to the fill only.
- Dark mode: measure the locked ring and ribbon colours from design/screens/dark/K11-badges.png and match them exactly (the dark PNG shows a light ring).
- Verify with a zoomed crop of one locked medal (e.g. Bins out) design vs app, both themes, in 5_ui.md.

## (07:33) Final nit — ribbon group opacity (mandatory, one-line class of fix)
- Measured on app_light_3 vs design at y=1125 px: the ribbon's inner stroke band is (130,128,148) in the app but (165,164,176) in the design. The app composites the 40 % stroke over the 40 % fill separately (`opacity` on the `<path>` is applied per paint by flutter_svg), the browser applies it to the element as a group. Fix: in `lockedMedalSvg` wrap the ribbon in a group — `<g opacity=".4"><path fill="#6E6A8A" stroke="#1E1B3A" …/></g>` with NO opacity on the path — or render the ribbon in an `Opacity(0.4)` layer. Then the inner band must sample (165,164,176) ±3 in light; check dark the same way. Nothing else changes.
