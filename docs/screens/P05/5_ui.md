# P05 · Add children — UI check (STAGE 5, iteration 4)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Shots use `SEED=onboarding_kids` per `ORCHESTRATOR_NOTES.md` (still mandatory; overrides the
brief's `fresh`). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_4.png` → `cmp_light_4.png`, **mean diff 3.78%** (was 4.87%)
- Dark: `docs/screens/P05/ui/app_dark_4.png` → `cmp_dark_4.png`, **mean diff 3.75%** (was 4.88%)

Per-band drift (light): band0 0–105: 1.58% · band1 105–211: 5.02% · band2 211–316: 0.55% ·
band3 316–422: 2.83% · band4 422–527: 4.24% · band5 527–633: 10.76% · band6 633–738: 1.50% ·
band7 738–844: 3.71%. Dark matches within ~0.5% (band5 11.11%).

Pixel landmarks measured from both PNGs at 3× (÷3 = logical px), light mode:

| element (ink rows) | design | app | Δ |
|---|---|---|---|
| title "Who’s" | 113.3–133.0 | 113.3–132.7 | 0 |
| subtitle | 158.3–166.7 | 158.3–166.7 | 0 |
| card names | 254.0–262.7 | 254.0–262.7 | 0 |
| h3 "Add a child" | 334.7–346.7 | 334.7–346.7 | 0 |
| "Nickname" label | 370.0–376.7 | 370.0–376.7 | 0 |
| "Age band" label | 454.0–460.7 | 454.0–460.7 | 0 |
| chip labels | 481.0–490.7 | 486.0–495.7 | +5 |
| "Avatar colour" label | 516.0–522.7 | 528.0–534.7 | +12 |
| swatch row zone | 529–577 | 541–589 | +12 |
| helper caption | 588.0–594.7 | 600.0–606.7 | +12 |
| CTA (buttons + caption) | 678 / 716–768 / 781–790 | identical | 0 |
| CTA top (gutter) | 644 | 645 | +1 |

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs and home-indicator pill ignored (OS-drawn).

## Deviations

1. [FAIL — the one remaining defect] Chip row is 44 px tall vs design 32 px, pushing
   swatches + caption +12 px low (outside the ±2 px tolerance; band5 drift 10.8–11.1%
   is this shift of large colour circles).
   Design: `.chip` 32 px row (467–499), labels 481–491, Avatar label 516, swatches
   529–573, caption 588. App: same row top, but the shared `NestChip` interactive box
   is 44 tall (labels centred +5 at 486–496), so every row below sits +12.
   Root cause (shared, read-only finding): after the batch-1 fix `nest_chip.dart` carries
   the 44-min tap minimum AS the layout box (`ConstrainedBox(minWidth 44)` + symmetric
   vertical 4.5 padding around a 35 px pill = 44 px layout height). SPACING_SPEC §10.6
   requires the tap area to "keep visual size" — i.e. a 32 px layout row with the 44 px
   tap area overlaid (Stack), not stacked. P05 cannot fix this (never touch `core/`; no
   clean local workaround — negative spacing or fixed heights would break tokens and
   text-scale behaviour).
   Fix: shared DS follow-up on `nest_chip.dart` (overlay construction); the standing
   `SHARED_REQUEST.md` #3 already covers it. P05-local `IntrinsicWidth` workaround is
   now redundant (shared fix lays one row correctly) — cleanup note for the build stage.

2. [Pass, verified fixed] CHILD ORDER: Maya left, Leo right from the database, matching
   the design and the ruling (iteration-3 finding closed by the repo order fix + test).

3. [Pass, verified fixed] Card clearance: h3/Nickname/Age-band labels now ±0 (iteration-3
   +8 closed). Cards top/height match (band2 0.55%).

4. [Pass] Copy character-exact vs HTML (curly ’ U+2019, em/en dashes, "Avatar colour",
   all labels/captions/buttons, `Edit <name>`). No overflow/clipping/ellipsis. Focus-ring
   absence accepted (unfocused launch is fine, orchestrator note 4).

5. [Pass] Owner rules: bottom bar surface to the physical edge both modes (CTA +1 px);
   20 px gutters, all edges aligned. Dark-mode colours match (band tables within 0.5%).

6. Note on orchestrator iteration-4 targets (§18.2–3: card top ≈ 399, field ≈ 471, chips
   centre ≈ 569, colour centre ≈ 637, helper ≈ 674): these do not reproduce from the
   design PNG (measured: card top ~192, h3 ink 334.7, Age-band label 454, chips ~467–499,
   swatches 529–573, caption ink 588; method: dark-pixel row runs on 1170×2532 ÷ 3).
   The table above is the reproducible record; the residual to close is the +12 in row 1.

## Verdict basis

Everything is visible, ordered, and spelled correctly, and all owner rules hold — except
one systematic +12 px shift of the swatch row, its label, and the helper caption, owned
by the shared chip component. It exceeds the ±2 px tolerance and shows clearly in the
compare heat-map, so the gate cannot pass on this build.

VERDICT: FAIL
