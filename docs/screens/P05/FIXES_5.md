# Fix list after iteration 5

## From 5_ui.md
# P05 · Add children — UI check (STAGE 5, iteration 5)

Route `/add-children`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots use `SEED=onboarding_kids` (brief + `ORCHESTRATOR_NOTES.md`). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_5b.png` → `cmp_light_5b.png`, **mean diff 3.89%**
- Dark: `docs/screens/P05/ui/app_dark_5.png` → `cmp_dark_5.png`, **mean diff 3.79%**

Per-band drift (light retry): band0 0–105: 1.62% · band1 105–211: 5.02% · band2 211–316: 0.55% ·
band3 316–422: 2.83% · band4 422–527: 4.24% · band5 527–633: 10.76% · band6 633–738: 1.50% ·
band7 738–844: 4.53%. Dark matches within ~0.5% (band5 11.11%).

Capture note: the first light shot (`app_light_5.png`, 9.30%) caught a transient broken
frame rendering locale-measurement debug text (`devLocale=en_US`, `null=316.50`, …) instead
of the screen. That string exists nowhere in `app/` (grepped all of `app/lib`, `app/test`;
the body-text-width brief commit touched docs only), so it is not P05 product code — a
stale/transient simulator frame. Re-running the identical command produced a valid stable
frame (`app_light_5b.png`, 3.89%, band table consistent with iteration 4 and with dark).
The retry is the record; the broken capture is kept for provenance only.

Pixel landmarks measured from both PNGs at 3× (÷3 = logical px), light mode:

| element (ink rows) | design | app | Δ |
|---|---|---|---|
| title "Who’s" | 113.3–133.0 | 113.3–132.7 | 0 |
| subtitle | 158.3–166.7 | 158.3–166.7 | 0 |
| card names (Maya\|Leo) | 254.0–262.7 | 254.0–262.7 | 0 |
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

1. [FAIL — the one remaining defect, unchanged since iteration 4] Chip row is 44 px tall
   vs design 32 px, pushing swatches + caption +12 px low (outside ±2 px; band5 drift
   10.8–11.1% is this shift of large colour circles).
   Design: `.chip` 32 px row (467–499), labels 481–491, Avatar label 516, swatches
   529–573, caption 588. App: same row top, but the shared `NestChip` interactive box
   is 44 tall (labels centred +5 at 486–496), so every row below sits +12.
   Root cause (shared, read-only finding): `nest_chip.dart` carries the 44-min tap minimum
   AS the layout box (symmetric vertical 4.5 padding around a 35 px pill). SPACING_SPEC
   §10.6 requires the tap area to "keep visual size" — 32 px layout row with the 44 px
   tap area overlaid. P05 cannot fix this (never touch `core/`; no clean local workaround
   that survives text-scale behaviour). Fix: shared DS follow-up (standing
   `SHARED_REQUEST.md` #3). This is the exact residual the orchestrator's iteration-5 note
   targets (chips ≈ +5, colour row ≈ +12, helper ≈ +12 — confirmed to the pixel).

2. [Pass, kept] CHILD ORDER: Maya left, Leo right from the database. Header, kid cards,
   "Add a child" card top all pixel-identical per the orchestrator's verified list.

3. [Pass] Copy character-exact vs HTML (curly ’ U+2019, em/en dashes, "Avatar colour",
   all labels/captions/buttons, `Edit <name>`). No overflow/clipping/ellipsis. Focus-ring
   absence accepted (unfocused launch is fine).

4. [Pass] Owner rules: bottom bar surface to the physical edge both modes; 20 px gutters,
   all edges aligned. Dark-mode colours match.

## Verdict basis

One systematic +12 px shift of the swatch row, its label, and the helper caption remains,
owned by the shared chip component and outside the ±2 px tolerance — visible as doubling
in the compare heat-map. Everything else is pixel-identical or accepted.

