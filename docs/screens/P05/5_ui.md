# P05 · Add children — UI check (STAGE 5, iteration 3)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Shots use `SEED=onboarding_kids` per `ORCHESTRATOR_NOTES.md` (still mandatory; overrides the
brief's `fresh`). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_3.png` → `cmp_light_3.png`, **mean diff 4.87%** (was 5.51%)
- Dark: `docs/screens/P05/ui/app_dark_3.png` → `cmp_dark_3.png`, **mean diff 4.88%** (was 5.76%)

Per-band drift (light): band0 0–105: 1.54% · band1 105–211: 5.08% · band2 211–316: 2.90% ·
band3 316–422: 4.64% · band4 422–527: 5.88% · band5 527–633: 13.49% · band6 633–738: 1.64% ·
band7 738–844: 3.71%. Dark matches within ~1% (band5 14.56%) — one defect, both modes.

Pixel landmarks measured from both PNGs at 3× (÷3 = logical px), light mode:

| element (ink rows) | design | app | Δ |
|---|---|---|---|
| title "Who's" | 113.3–133.0 | 113.3–132.7 | 0 |
| subtitle | 158.3–166.7 | 158.3–166.7 | 0 |
| card names | 254.0–262.7 | 254.0–262.7 | 0 |
| h3 "Add a child" | 334.7–346.7 | 342.7–354.7 | +8 |
| "Nickname" label | 370.0–376.7 | 378.0–384.7 | +8 |
| "Age band" label | 454.0–460.7 | 462.0–468.7 | +8 |
| chip labels | 481.0–490.7 | 494.0–503.7 | +13 |
| "Avatar colour" label | 516.0–522.7 | 536.0–542.7 | +20 |
| swatch row zone | 529–577 | 549–597 | +20 |
| helper caption | 588.0–594.7 | 608.0–614.7 | +20 |
| CTA ("Add another", Continue, caption) | 678 / 716–768 / 781–790 | identical | 0 |
| CTA top (gutter) | 644 | 645 | +1 |

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs and home-indicator pill ignored (OS-drawn).

## Deviations

1. [FAIL — violates design + mandatory ruling] Card order Leo|Maya, must be Maya|Leo.
   Design: Maya (lilac M, Age 7–9) left, Leo (peach L, Age 4–6) right — and the
   CHILD ORDER ruling mandates creation order (Maya, then Leo) in every screen and
   repository. App (both modes): Leo left, Maya right — the DB still sorts by nickname
   (P05-BUG-3). Whole-card swap; band1 drift (5.1–5.3%) is largely this.
   Fix: shared — order children by creation time/insertion order (`rowid` meanwhile);
   P05 consumes the stream as-is (already noted in `SHARED_REQUEST.md`). Not locally fixable
   without forking the repo order (RULES §4 forbids).

2. [FAIL — systematic offset, designer-visible doubling in compare view] Form region sits
   +8 px low through the field, +13 at chips, +20 at swatches/caption.
   Design → app: h3 +8, Nickname +8, Age-band +8, chips +13, Avatar-colour/swatches/caption +20.
   Everything is still above the CTA (caption ends ~615 < CTA 645) and the CTA itself is
   pixel-identical — but no element below the kid cards is within the ±2 px tolerance.
   Components, from code reading (no code changed): card height 124 vs design ~113
   (the 10 px pencil clearance in `cardH`; content is top-aligned, only height differs →
   explains the +8/+11 passage from cards to form); chip box 44 tall vs design `.chip`
   32 visual (tap area stacked, not overlaid → explains the extra +12 from chips down).
   Fix: P05-local — drop the pencil clearance (design overlays the 44 px edit button with
   zero clearance: avatar spans x 63–107 of 170, button x 125–169, no overlap) to recover
   ~11 px; shared — render the 44-min tap area around a 32 px visual (the standing
   `SHARED_REQUEST.md` #3 follow-up) to recover ~12 px. Together the form lands within ±2.

3. [Pass, verified fixed] GridView safe-area padding (iteration-2 finding): card names now
   254.0–262.7 in both — `padding: EdgeInsets.zero` confirmed working. Header pixel-identical
   (shared 52 px compact nav — do not patch). Chips one row, 7–9 selected, in both modes.

4. [Pass] Copy is character-exact vs the HTML source (COPY ruling): curly ’ (U+2019) in
   "Who’s" (code `\u2019`), em dashes (`\u2014`), en-dash age bands, "Avatar colour",
   "e.g. Ollie", both CTA labels, both captions, `Edit <name>` labels. No overflow,
   clipping, or ellipsis faults.

5. [Pass] Owner rules: `NestBottomCta` surface runs to the physical edge in both modes
   (CTA top 644 vs 645; the design's 34 px cream strip under its CTA is the mock breaking
   the rule — the app is correct). 20 px gutters, head/grid/form/CTA on the same edges,
   nothing visibly misaligned. Dark-mode tokens match (surface cards, leaf-tint selected
   chip, mint Continue, correct swatch fills + peach ring).

6. [Accepted — no action] Nickname field unfocused (design shows the focused state;
   orchestrator note 4: unfocused launch is fine). Swatch caption fully visible above
   the CTA in both modes.

## Verdict basis

Deviation 1 breaks a mandatory orchestrator ruling and mirrors the design's card order
exactly backwards — a designer would reject it. Deviation 2 puts every form element
8–20 px off-spec, plainly visible as doubling in the compare heat-map. Both need a further
pass (one shared, one P05-local + one shared follow-up).

VERDICT: FAIL
