# P04 · Privacy consent — UI check (STAGE 5, iteration 1)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_1.png`, `docs/screens/P04/ui/app_dark_1.png`
(`shot.sh` with absolute OUT path — relative OUT breaks because the script `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_1.png`, `docs/screens/P04/ui/cmp_dark_1.png`.

## Mean diff

- Light: **7.52%** — bands: 0 (0–105) 2.73% · 1 (105–211) 13.18% · 2 (211–316) 6.97% ·
  3 (316–422) 12.39% · 4 (422–527) 9.74% · 5 (527–633) 9.79% · 6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **8.12%** — bands: 0 (0–105) 2.74% · 1 (105–211) 16.45% · 2 (211–316) 9.25% ·
  3 (316–422) 12.03% · 4 (422–527) 9.69% · 5 (527–633) 10.78% · 6 (633–738) 0.39% · 7 (738–844) 3.55%

Band 6 (~blank paper in both) ≈ 0.4% confirms the pipeline is aligned; drift concentrates in
bands 1–5 (content block). Status-bar glyphs (mock `9:41` vs OS clock `11:43`/`11:44`) are
ignored per orchestrator STATUS BAR rule; the bottom-edge strip difference is the OWNER-rule
override (app correct, see deviation 4 — not a failure).

## Verified matching (no action)

- Presence/order/copy: nav back chevron, H1 `Your family’s privacy`, sub
  `Exactly what we store — and nothing else.`, 84 px shield, 4 promise rows in order with
  exact titles/subs, opt card (`Optional: help improve Nestling` / `Share anonymous crash
  reports.` / `No names, no photos.`), toggle OFF, primary `Continue`, underlined sky
  `Read the full Privacy Notice`. No overflow, no clipping, no ellipsis anywhere; rows wrap.
- Geometry that matches: 20 px side gutters throughout; 40 px tiles, r12; divider indent 72;
  opt card 13 v / 16 h; toggle 51×31 in 44 px box; full-width pill CTA bottom-anchored at the
  same y as the design; footnote centred.
- Light-mode colours/radii/shadows match; no Pip on this screen so the PIP rule is N/A.

## Deviations

1. Scroll content sits ~16 px too high (all elements, both themes).
   Design value: compact nav bar 60 px tall (`.nav-bar.compact`: min-height 52 + padding
   4/12/12 around the 44 px back button) → scroll starts at y = 47 + 60 = 107; H1 at y 113–138.
   App value: `NestNavBar` compact resolves to 44 px → scroll starts at y = 91; H1 at y 97–122.
   Uniform −16 px for every content element; CTA unaffected (bottom-anchored). This is what
   bands 1 (13.18%/16.45%) and 3 (12.39%/12.03%) are measuring.
   Fix (shared, `app/lib/core/design_system/components/nest_nav_bar.dart` — off limits to P04):
   compact bar → `minHeight: 52` with padding 4 top / 12 sides / 12 bottom. File as SHARED_REQUEST
   item (not yet filed — `4_review.md` finding 2).
2. Row-4 tile has no trash-can glyph (both themes — blank peach tile).
   Design value: peach tile with 24 px trash-can line glyph.
   App value: empty peach 40×40 tile.
   Fix (shared, already filed as SHARED_REQUEST item 1): add `assets/icons/ic_trash.svg` +
   `NestIcons.trash`; P04 row 4 picks it up. A designer would reject the blank tile.
3. Dark-mode shield disc renders light (dark theme only).
   Design value: disc `#1A2A4A` (probed patch at (160, 215–228)).
   App value: disc `#E6EFFE` (same patch) — `privacy_shield.svg` bakes the light hex.
   Fix (shared, already filed as SHARED_REQUEST item 2): themed shield asset; do not hand-edit
   core assets from P04.
4. Bottom-edge strip below the CTA differs from the PNG — NOT a failure (owner override).
   Design value: cream `#FBF7F0` (light) / near-black (dark) strip with the home indicator
   outside the CTA panel.
   App value: CTA surface colour runs to the physical edge (white light / surface dark).
   Per the OWNER BOTTOM-EDGE rule the app is the intended behaviour; do not "fix" toward the PNG.

No fix is applicable inside P04 scope (RULES §1): deviations 1–3 are all shared
design-system/asset causes. No code edited in this stage.

VERDICT: FAIL
