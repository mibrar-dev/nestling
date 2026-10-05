TASK — demo seed badges match the K11 design (shared/k11_badges_seed)

In `app/lib/core/data/seed.dart`, `_badgesDemo` must insert EXACTLY these nine badges, in THIS order (ids / titles, copy char-exact, `×` is U+00D7):
1. first-quest / First quest
2. bed-maker-7 / Bed maker ×7
3. kind-helper / Kind helper
4. bookworm / Bookworm
5. bins-out / Bins out
6. biscuit-sitter / Biscuit sitter
7. tidy-hero / Tidy hero
8. early-bird / Early bird
9. plant-waterer / Plant waterer
Remove `tidy-champion`, `super-saver`, `pet-friend` (nothing else in app/lib uses them; grep to confirm). The earned rows stay EXACTLY as they are (Maya: first-quest, bed-maker-7, kind-helper, bookworm; Leo: first-quest), same timestamps.
Do NOT touch any other seed table, the schema, or any feature code. Update only tests that assert the old badge ids/titles/count (8 → 9); grep `app/test` for `badge` to find them.
Run: `cd app && flutter analyze` (No issues found) and `flutter test --timeout 120s` (all green). Commit on this branch.
Write docs/screens/_shared/k11_badges_seed_REPORT.md: the diff summary, tests changed, full-suite result. End with `VERDICT: PASS` or `VERDICT: FAIL`.
