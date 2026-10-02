# P08 · Today (home) — UI check (Stage 5, iteration 1)

Route `/today`, mode parent, seed demo, child maya, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874.
Shots are fresh from current sources (light + dark re-taken this stage; relative `OUT`
paths break `shot.sh` after its internal `cd`, so absolute paths were passed — no repo files touched).

## Shots + diffs

- `bash tools/screens/shot.sh "$PWD/app" /today "$PWD/docs/screens/P08/ui/app_light_1.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo parent maya` → stable frame saved.
- Same with `dark` → `app_dark_1.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P08-today.png docs/screens/P08/ui/app_light_1.png docs/screens/P08/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/P08-today.png docs/screens/P08/ui/app_dark_1.png docs/screens/P08/ui/cmp_dark_1.png`

| Theme | Mean diff | Bands (y-range: diff%) |
|---|---|---|
| Light | **6.67%** | 0–105: 5.62 · 105–211: 6.86 · 211–316: 4.73 · 316–422: **9.36** · 422–527: 4.62 · 527–633: 8.09 · 633–738: 7.63 · 738–844: 6.45 |
| Dark | **6.55%** | 0–105: 5.73 · 105–211: 5.73 · 211–316: 5.41 · 316–422: 8.22 · 422–527: 4.81 · 527–633: 8.29 · 633–738: 7.75 · 738–844: 6.45 |

Both compare sheets + both app shots + both design PNGs were read with the file
reader; HTML source `design/html-source/screens/P08-today.html` and the feature's
view code were read (not edited) to ground each deviation. Crop-zoomed the
dishwasher tile and the Money tab icon (design vs app) before asserting icon choice.

## What matches (verified in the compare sheets)

Greeting "Good morning, Sarah" (1 line, ellipsis-safe); `+` 44 px leaf circle and `S`
avatar position/size; approvals banner geometry (leaf-tint, r24, Review button);
2-up kid cards (names, "4 of 6 quests" / "2 of 4 quests", progress 67 % / 50 %,
coin pills 120 / 45); "Today's quests" + "See all"; "MAYA · 9" group label;
quest-card geometry/typography; meta order coin → repeat → status chip; chip colours
(Needs a look = coin-tint, To do = surface-2, Approved ✓ = leaf-tint); dark-mode
token flips with zero theme branches (banner, cards, pills, chips all correct in dark).

## Deviations (element · design value · app value · fix)

1. **Pip art source (mandatory orchestrator-rule violation).** Rule: P08 must render
   each child's OWN Pip via `PipAvatar` (Maya = Mochi·sunny·stage 3, Leo =
   Bolt·sky·stage 2); never the v1 `pip_stage_*.svg` in product screens. App value:
   `today_loaded_body.dart:110-121` (`pipStageAsset`) + `:486-496`
   (`SvgPicture.asset(..., 72×72)`) renders the generic v1 illustrations for both
   cards. Slot size/position are correct — only the art source is wrong.
   Fix (P08-local): feed `pip_style`/`pip_skin`/`pip_accessory`/`pip_stage` from the
   database into `PipAvatar` in `_KidCard`, keeping the 72×72 centred slot.
2. **Banner subtitle copy.** Design (`P08-today.html:30`, both PNGs): "Maya and Leo
   did brilliantly yesterday" (2 lines). App (`today_loaded_body.dart:385`):
   "Your little birds did brilliantly" (1 line). The shorter subtitle also shifts
   everything below up ~18 px (kid cards start higher in the app shot).
   Fix: build the subtitle from state (names + "did brilliantly yesterday", with a
   0/1/3+-child guard) and use it for the visible text and the semantics label.
3. **Quest-row gaps 8 px, spec says 16 px.** Design/`SPACING_SPEC` §8/plan §a.1:
   16 px card-to-card (8 px only label→first-card). App
   (`today_loaded_body.dart:240`): `SizedBox(height: s2)` before EVERY row.
   Stage 4 measured exactly 8.00 px lost per gap (21.33 px vs 13.33 px incl. shadow);
   the fresh compare confirms it — bands 5–7 carry the drift and the app viewport
   fits an extra half row. Fix: `i == 0 ? s2 : s4` in the row loop, then re-shoot.
4. **Quest order: alphabetical, design orders by status.** Design Maya rows:
   "Empty the dishwasher" (Needs a look) → "Reading – 20 minutes" (To do) →
   "Put the bins out" (Approved ✓); Leo likewise pending-first. App
   (`today_repository_impl.dart:108-109`, α-sort): "Empty the dishwasher" →
   "Hoover the stairs" (Approved ✓) → "Lay the table", scattering Needs-a-look rows.
   Fix: sort `rows()` by (statusRank: done_pending 0, to_do 1, not_yet 2, approved 3;
   then title) + repository order test. Note `1_plan.md` §f endorsed α-sort, so the
   plan needs the same correction.
5. **Latent pluralisation copy (not visible at demo values, same root cause as 2).**
   `today_loaded_body.dart:361/378` interpolate "N quests…" (renders "1 quests…"
   at N=1); `today_bloc.dart:59` renders "Happy week: 1 days". Fix with
   `todayPendingLabel` / conditional plural helpers + the test helper in step.
6. **Greeting weight/tracking (minor).** Design/HTML/SPACING_SPEC §8: Nunito 900,
   ls −1 % (−0.22 px at 22 px). App: `NestType.h2` = Nunito 800, no tracking
   (title shows heat doubling in both compare sheets). Fix: `.copyWith(
   fontWeight: w900, letterSpacing: -0.22)` on the existing token style.
7. **Dishwasher tile glyph (minor, needs design sign-off).** Crop-zoomed: the mock
   draws a padlock/bag-like glyph; the app draws the design-system dishwasher
   appliance (`NestIcons.dishwasher`, per plan §a.8). A padlock on a dishwasher
   quest reads as a mock placeholder error, so the appliance is arguably correct —
   but it is a visible PNG deviation. Fix: designer confirms which glyph wins; if
   the mock wins, the icon asset (shared) must change, not P08.

## Expected / data-driven differences (not defects, no P08 fix)

- **Status bar** (9:41 + mock glyphs vs real 01:05/01:15): OS-drawn; ignored per rules.
- **Date line** "Sat 4 Oct" vs "Fri 2 Oct": live Europe/London date; today is
  Fri 2 Oct 2026. "Happy week: 4 days" matches in both. Correct behaviour.
- **Repeat labels** "· Daily" vs "· Weekly · Sat": every seeded quest defaults to
  `repeat = 'weekly'` (`core/data/seed.dart:181`); the app correctly renders the DB
  value per DATA OVER MOCKS. The design/seed disagreement was never filed as a
  SHARED_REQUEST (Stage 4 B19) — that filing (or a seed decision) is still owed,
  but P08 must not fork the seed.
- **Meta-row width**: follows from the repeat-label difference above; will close
  once the seed decision lands.
- **Banner title wrap** ("…waiting for your / thumbs-up" vs "…waiting / for your…"):
  `text-wrap: balance` has no Flutter mapping (Stage 4 B16); accepted substitution.

## Shared chrome (out of P08 scope, flagged for the orchestrator)

- **Money tab icon**: crop-zoomed — design is a plain credit-card glyph, the app
  (ParentShell, `app/lib/app/`, RULES-shared) renders a banknote-with-circle glyph.
  Today/Quests/Family tabs match. Needs a shared decision, not a P08 edit.

## Dark mode

Same deviation set mirrored; no dark-specific defects. Banner leaf-ink-on-leaf-tint,
kid cards, coin pills, chips and progress all flip correctly through tokens.

## Coverage limit

Viewport shots cover the above-fold only (through Maya row 2–3). Leo's group,
"Put the bins out" / "Make your bed" / "Feed Biscuit the cat" rows and the
"Hand to Maya or Leo" button are below the fold and unverified by these shots.

VERDICT: FAIL
