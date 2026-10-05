# Shared request — K11 seed badges

Need: `Seed._badgesDemo` must carry the nine design badges so the K11 shelf's
titles, count and order match `design/screens/light/K11-badges.png`:
`first-quest / First quest`, `bed-maker-7 / Bed maker ×7`,
`kind-helper / Kind helper`, `bookworm / Bookworm`, `bins-out / Bins out`,
`biscuit-sitter / Biscuit sitter`, `tidy-hero / Tidy hero`,
`early-bird / Early bird`, `plant-waterer / Plant waterer` (in that order,
icons/descriptions from the design). Today the seed has 8 rows and uses
`tidy-champion`, `super-saver`, `pet-friend` instead of `bins-out`,
`biscuit-sitter`, `plant-waterer`. Maya's earned set stays exactly
`first-quest, bed-maker-7, kind-helper, bookworm` (4 earned — the design's
row 1 + Bookworm).

The K11 grid renders whatever the database returns in DB order, so the
screen lands correctly either way; the seed fix is what makes the demo match
the design's remaining five tiles exactly.

Files: `app/lib/core/data/seed.dart` (`_badgesDemo`).

Blocks: no — the view layer builds against the shelf contract as-is behind a
`TODO(K11)` in `badges_view.dart`; no schema or design-system change needed.
