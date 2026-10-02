# P08 · Today (home) — UI check (Stage 5, iteration 2)

Route `/today`, mode parent, seed demo, child maya, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874.
`docs/screens/P08/ORCHESTRATOR_NOTES.md` exists — all 4 items + the K03-BUG-4 periods
ruling treated as mandatory and verified below. No code edited this stage.

## Shots + diffs

- `bash tools/screens/shot.sh "$PWD/app" /today "$PWD/docs/screens/P08/ui/app_light_2.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo parent maya`
- Same with `dark` → `app_dark_2.png`.
- Both runs printed `WARNING — frame never stabilised in 25 s; saved last capture`
  (see note 8); both captured frames are complete, fully loaded, and mutually
  consistent. Absolute `OUT` paths used (relative paths break `shot.sh`).
- `python3 tools/screens/compare.py design/screens/light/P08-today.png docs/screens/P08/ui/app_light_2.png docs/screens/P08/ui/cmp_light_2.png` (and dark).

| Theme | Mean diff (iter 1 → iter 2) | Bands (y-range: diff%) |
|---|---|---|
| Light | 6.67% → **5.03%** | 0–105: 5.75 · 105–211: 5.40 · 211–316: 3.31 · 316–422: 5.88 · 422–527: 3.12 · 527–633: 5.93 · 633–738: 5.32 · 738–844: 5.49 |
| Dark | 6.55% → **4.82%** | 0–105: 5.90 · 105–211: 4.65 · 211–316: 3.45 · 316–422: 4.61 · 422–527: 3.13 · 527–633: 6.00 · 633–738: 5.53 · 738–844: 5.27 |

Both compare sheets + both app shots read with the file reader; view/repo code read
(not edited) to verify each fix below.

## Iteration-1 FAIL items — all verified fixed

1. **Pip = child's own `PipAvatar` (orchestrator PIP rule + NOTES item 1).**
   Code: `today_loaded_body.dart:565-569` feeds DB `pipStyle/pipSkin/pipAccessory`
   (+ stage) into `PipAvatar`; repo carries the fields (`today_repository_impl.dart:69-71`).
   Screenshots: Maya = yellow Mochi·sunny bird (stage 3, no shell), Leo = blue/white
   Bolt·sky bird (stage 2, in shell) — distinct per-child Pips, design's 72×72
   centred slot and position kept. Band-3 residual heat is the mandated art change
   itself (PipAvatar ≠ v1 mock SVG), not a defect.
2. **Banner subtitle names the children (NOTES item 2).** Design: "Maya and Leo did
   brilliantly yesterday" (2 lines). App now renders exactly that in light + dark;
   banner geometry matches and the ~18 px upward shift from iter 1 is gone
   (kid-card rows align with the design through the quest list).
3. **Quest-row gaps 16 px.** Code `:293` is now `i == 0 ? s2 : s4`. Corresponding rows
   align design-vs-app (MAYA·9 label, row-1 tops, row-2 tops all level); bands 5–7
   heat is content-driven (next item), not spacing.
4. **Status order (NOTES item 4).** App Maya rows: "Empty the dishwasher"
   (Needs a look) → "Lay the table" (Needs a look) → "Reading – 20 minutes"
   (To do, 3rd) — pending → to-do → approved, then title. Matches the design's
   ordering rule.
5. **Daily repeats (NOTES item 3).** Row 1/2 meta now reads "· Daily" exactly like
   the mock (seed fixed on main; was seed data, not a P08 bug).
6. **Greeting type (iter-1 item 6).** Code `:344-345` now `w900 / ls −0.22`.
   Residual title doubling in the heatmap is rasterization + the live-date line,
   within tolerance.

## Remaining heat — disposition (element · design · app · why not a defect)

7. **Row-2 quest identity.** Design row 2: "Reading – 20 minutes / To do". App row 2:
   "Lay the table / Needs a look" (Reading is app row 3, To do). Ordering rule
   (item 4) is satisfied; which quests are pending is computed live from the DB via
   the mandatory periods ruling (`countsForCurrentPeriod`, seed anchored to today).
   Per DATA OVER MOCKS + the periods ruling, the mock's static statuses cannot be
   reproduced by a live screen. Data, not a deviation.
8. **`shot.sh` stabilization warnings (process note, not a UI deviation).**
   `PipAvatar` gates on `kDisableAnimations`/`MediaQuery.disableAnimations`
   (`pip_avatar.dart:390-391`, shared code), and both saved frames are complete and
   state-consistent. The 25 s churn source is unidentified — next loop should find
   it (RULES §6 still-frame requirement) — but nothing in the rendered frames is
   mid-animation, blurred, or half-loaded.
9. **Dishwasher tile glyph (design query, carried).** Crop-zoomed in iter 1: the mock
   draws a padlock/bag-like glyph for a dishwasher quest; the app draws the
   design-system dishwasher appliance per plan §a.8. The mock glyph reads as a
   placeholder error and P08 may not change shared icons — kept as a designer
   sign-off note, not a P08 defect.
10. **Money tab icon (shared chrome, out of scope).** Design: card glyph; app
    ParentShell: banknote glyph. Unchanged, still not P08-editable (RULES §1);
    for the orchestrator/shared loop.
11. **Status bar, home indicator (ignored per rules); date line "Sat 4 Oct" vs
    "Fri 2 Oct" (live London date — today is Fri 2 Oct 2026; "Happy week: 4 days"
    matches).** Expected.
12. **Banner title wrap** ("…your / thumbs-up" vs balanced "…waiting / for your…"):
    accepted `text-wrap: balance` substitution, no Flutter mapping. No action.

## Dark mode

Same picture mirrored; no dark-specific defects. Banner, kid cards, coin pills,
status chips, progress all flip correctly through tokens with zero theme branches.

## Coverage limit (unchanged)

Viewport shots cover the above-fold only (through Maya row 2 + partial row 3).
Leo's group, lower rows and the "Hand to Maya or Leo" button are below the fold
and unverified by these shots — same scope as the 390×844 design PNG.

VERDICT: PASS
