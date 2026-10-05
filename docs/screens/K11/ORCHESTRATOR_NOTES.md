
## UPDATE (02:40) — mandatory
- The SHARED_REQUEST (nine design badges in the seed) is being done on branch shared/k11_badges_seed by the orchestrator; it will be merged to main and the loop merges main before the next build. Do not edit seed.dart yourself.
- Badge art: every one of the nine ids must render its own design medal (bins-out bin, biscuit-sitter paw/biscuit, tidy-hero basket, early-bird sun, plant-waterer can) in BOTH earned and locked states, light and dark, matching design/screens/*/K11-badges.png. The generic rosette fallback is only for ids not in the design. Remove the `TODO(K11)` once done.
- (03:04) Fix K11-BUG-2 in the next build: never fall back to a hard-coded 'maya' child. With no active child, use the session's first child in creation order; with no children at all, show the empty state. Fix K11-BUG-1 too: clamp happyDays to 0..7 before drawing the week card.
