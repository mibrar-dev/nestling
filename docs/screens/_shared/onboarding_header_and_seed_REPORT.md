# Shared fix — onboarding header + onboarding_kids seed

Branch: `shared/onboarding_header_and_seed` (from `main`).
Scope: shared only (`core/design_system`, `app/launch*`, `docs`, `test`).
No `features/*/presentation` screen code touched.

## A) Onboarding header 16 px high — root cause + fix

Investigated `design/html-source/screens/P04-privacy.html` +
`P05-add-children.html` vs `app/lib/core/design_system/components/nest_nav_bar.dart`
(`NestNavBar.compact`, the back-row used by every pushed onboarding screen)
and `nest_chrome.dart` (`NestStatusBar`).

Design (border-box, `components.css` + `tokens.css`):

- `.status-bar` = 47 high.
- `.nav-bar.compact` = min-height 52, padding `4px 12px 12px`; the 44 px
  `.nav-back` button stretches it to 4 + 44 + 12 = **60 high**.
- Chevron bbox (measured `design/screens/light/P04-privacy.png` @390x844):
  x 29.3–37.3, y 65.3–80.3, centre **y 72.8 ≈ 73**.
- Title cap top (first dark row, same PNG): **y 112.3**; line-box top
  47 + 60 = **107** (5 px Nunito bearing).

Old Flutter `NestNavBar.compact`:

- `ConstrainedBox(minHeight: 44)` + horizontal-only padding → bar **44 high**
  (16 short). Chevron centre 47 + 22 = **68.5** (measured in
  `P04 …/ui/app_light_1.png` and `P05 …/ui/app_light_1.png`: bbox y 62–75,
  centre **68.5**, 4 px high ≈ the reported “≈5 px high”).
- Title line-box 47 + 44 = **91**; cap **97** (measured), 15–16 px high —
  the reported “title cap top y≈192 vs design y≈208” (sheet coords =
  panel 84 + logical; logical 91/97 vs 107/112).
- Same offset on P04 and P05 ⇒ shared cause confirmed.
- `NestStatusBar` (`max(viewPadding.top, 47)`) is **not** the cause: iPhone 16e
  (604697A9-11DA-462F-9837-396E9CA2493A, 390x844, 1170x2532 @3x) reports top
  inset 47, so it reserves 47 = design. No change there.
- Secondary bug in the same builder: `title == null` returned `Spacer()`
  inside `Expanded` → `ParentDataWidget` crash (the `title: ''` workaround +
  TODOs on P03/P04/P05). Empty string rendered an empty `Text`.

Fix (`nest_nav_bar.dart`, compact branch only):

- `minHeight: 52` (spec) + `padding: fromLTRB(12, 4, 12, 12)` (s3/s1/s3/s3)
  → rendered 4 + 44 + 12 = **60**, chevron centre 47 + 4 + 22 = **73**,
  title line-box **107**, cap **≈112**.
- `title == null || title.isEmpty` → `SizedBox.shrink()` (no crash,
  back-only row identical for both; backward-compatible with `''`).
- Non-compact bar untouched.

Before (old shared code, reproduced
`compare.py design/screens/light/P04-privacy.png …/P04/…/app_light_1.png`):

- P04 mean **7.52%** — band 0 (0–105) **2.73%**, band 1 (105–211) **13.18%**,
  band 2 (211–316) **6.97%**.
- P05 mean **6.61%** — band 0 **2.79%**, band 1 **11.88%**, band 2 **3.82%**.
- Geometry: chevron 68.5 (4 high), title cap 97 (15 high).

After (fixed shared code):

- Widget geometry (`onboarding_header_test`, 390x844): status **47**, nav
  **60**, chevron centre **73.0 ± 1.5** (design 72.8), title line-box
  **107.0 ± 1.5** (design 107), cap ≈112 (design 112.3).
- Full-screen `shot.sh` on **this** worktree cannot show P04/P05 header
  improvement: `/privacy` + `/add-children` here are still foundation
  placeholders (real UI lives on `screen/P04` + `screen/P05`, merged after).
  Placeholder comparisons kept for the record
  (`docs/screens/_shared/header_p04_cmp.png` mean 10.22%,
  `header_p05_cmp.png` mean 8.96%) — they prove the routes boot, not spacing.
  Real P04/P05 will pick the fix up on merge; band 1 (≈13%→low single digits)
  and band 0 (≈2.7%→≈1%, status ignored per owner rules) must drop there,
  bands 3–7 unchanged (no other layout touched).
- No-regression checks on this worktree (routes implemented here):
  P01 `/welcome` (no nav) mean **2.96%** — bands 0 **1.58%**, 1 **0.68%**;
  P08 `/today` (SafeArea + tabs, no compact nav) mean **5.22%** —
  bands 0 **5.81%**, 1 **5.40%**, 2 **3.31%** (merged main was 5.0%; +0.22%
  is simulator-frame noise; both shots warned “frame never stabilised”).
  Sheets: `header_p01_cmp.png`, `header_p08_cmp.png`.

## B) `SEED=onboarding_kids` for P05

- `Seed.onboardingKids(db)` (`app/lib/core/data/seed.dart`): `clearAll` +
  `_family` + Sarah-only member + `_childrenDemo` (Maya 7–9 lilac 9 y 120
  coins mochi/sunny/stage 3 + Leo 4–6 peach 6 y 45 coins bolt/sky/stage 2,
  exactly as `demo`, incl. pinHash) + `_settingsDemo`, no quests/completions/
  ledger/goals/rewards/badges/wardrobe; `app_state(onboardingComplete: false,
  appMode: parent)`.
- `LaunchFlags.isSupportedSeed` (`app/lib/app/launch_flags.dart`) now includes
  `onboarding_kids`; `hasSeed` delegates to it. `applyLaunchFlags`
  (`app/lib/app/launch.dart`) handles the new case.
- `docs/screens/SCREENS.tsv` P05 col 7 `fresh` → `onboarding_kids` (tabs only).
- Verified end-to-end: `shot.sh … /add-children … light onboarding_kids …`
  boots and saves a frame (placeholder shows seeded roster path works).

## Files changed

- `app/lib/core/design_system/components/nest_nav_bar.dart` — compact
  minHeight 52 + 4/12/12 padding (60 rendered); null/empty title → shrink
  (crash fix).
- `app/lib/core/data/seed.dart` — `Seed.onboardingKids` + header comment.
- `app/lib/app/launch_flags.dart` — `isSupportedSeed` (+ `onboarding_kids`).
- `app/lib/app/launch.dart` — `onboarding_kids` switch arm + comment.
- `docs/screens/SCREENS.tsv` — P05 seed `onboarding_kids`.
- `app/test/design_system/chrome_test.dart` — compact heights 52/60; 2 new
  compact tests.
- `app/test/design_system/onboarding_header_test.dart` — NEW: chevron y 73,
  title y 107.
- `app/test/core/data/seed_test.dart` — NEW `Seed.onboardingKids` group
  (2 tests).
- `app/test/app/launch_flags_test.dart` — NEW `isSupportedSeed` (2 tests).
- `docs/screens/_shared/header_p0{1,4,5,8}_cmp.png` — verification sheets.
- This report.

## Tests added

- `onboarding compact header status 47 + nav 60 puts the chevron at y 73`
- `onboarding compact header title line-box starts at y 107`
- `NestNavBar compact back-only bar is 60 high`
- `NestNavBar compact null and empty titles render the same`
- `Seed.onboardingKids Maya + Leo exactly as demo, onboarding incomplete`
- `Seed.onboardingKids no quests, ledger, goals, rewards or badges`
- `LaunchFlags.isSupportedSeed supports demo, empty, fresh and onboarding_kids`
- `LaunchFlags.isSupportedSeed rejects unknown and empty seeds`
- Updated: `NestNavBar large and compact geometries`,
  `compact action stays on the title line` (60, not 44).

Checks: `cd app && dart format . && flutter analyze` → **No issues found!**;
`flutter test` → **487 passed** (incl. the 8 above).

## Follow-up screens must do

- P03/P04/P05 (any compact user): replace `title: ''` with `title: null`
  (or omit) and drop the TODO(`P0X`) nested-Spacer comments; behaviour is
  identical but null is now the canonical back-only row.
- P05: UI-check uses `SEED=onboarding_kids` (already in `SCREENS.tsv`);
  no view change needed.
- After merging `main`: re-run `shot.sh` + `compare.py` for P03–P07;
  expect bands 0–2 to drop (band 1 ≈13%→low single digits), bands 3–7 flat.
  P01/P08 need nothing (no compact nav).

VERDICT: PASS
