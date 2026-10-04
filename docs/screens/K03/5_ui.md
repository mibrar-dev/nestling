# K03 Kid home — UI check (Stage 5, iteration 13)

Method (simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 only; 390x844):
- `bash tools/screens/shot.sh /…/K03/app /kid-home /…/docs/screens/K03/ui/app_light_13.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo kid maya` -> stable frame saved. Same with `dark` -> app_dark_13.png. Absolute OUT paths used.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_13.png docs/screens/K03/ui/cmp_light_13.png` (and dark). Read both compare sheets plus both app shots and both design PNGs with the file reader. Logical px (PNG/3). Pixel-row measurements below were re-taken from the PNG bytes (ink/gold runs, painted RGB), not copied from prior reports.
- Verdict under the UI VERDICT RULE (±2px every element excl. OS glyphs + DB content; title/first-control/card-top y reported). No code edited this stage.

Results:
- light mean diff: 5.29% — bands: 0: 1.71% · 1: 1.01% · 2: 10.09% · 3: 10.42% · 4: 0.42% · 5: 5.27% · 6: 6.67% · 7: 6.73%
- dark mean diff: 4.44% — bands: 0: 1.72% · 1: 0.79% · 2: 7.83% · 3: 7.69% · 4: 0.38% · 5: 5.50% · 6: 6.14% · 7: 5.42%
- Iteration 13 change worked: band 4 (hearts/title/progress zone) fell 2.75%→0.42% light, 2.57%→0.38% dark (`bubbleGap: 14` + stage→hearts back to s4). No band regressed vs iter12 (light 6.54%, dark 5.61%).

Measured rows, design vs app (logical px, identical unless noted):
- Screen title "Today's quests" text rows: 483..507 both themes, both images (identical).
- First control (lock button zone rows): 125..204 dark-identical; light header name rows design 140..167 vs app 141..167 (1px, font raster, within ±2).
- Speech bubble top border row: y=125 both. Body 125…169 per geometry pin (exact).
- Pet box: 183…419 per pin (exact). Hearts gold rows 442..454 light / 442..455 dark, identical design vs app (centre 448).
- Progress bar borders: top 527, bottom 542, both (identical, x-extent identical).
- Card 1 top: 559 both; card 1 bottom 644..646 both; card 2 top: 659 both; card 2 peeks above dock in both (dock top 719..721 full-width border both).
- Gutters: card left ink border x 20..23, right 367..370, both (20px gutters, cards/dock aligned).
- Bottom edge (owner rule): app paints dock surface to the physical edge — light rgb(255,255,255) at (195,830)/(195,843); dark rgb(31,28,46) (surface) at same rows. No green strip in either theme. PASS, keep.
- Meadow grade: (10,600) design rgb(223,243,214) vs app rgb(223,242,213); (10,700) (210,238,198) vs (209,238,197); dark (10,600) (35,56,81) vs (34,55,81); (10,700) (33,63,72) vs (32,63,71). All within 1 level — shared kid background exact.
- Copy: "Today's quests" straight apostrophe U+0027 matches HTML l.61; "Let's do some quests!" matches; en dash in "Reading – 20 minutes" is the HTML `&ndash;` (that quest is below the fold under DB order). No overflow/clipping/ellipsis faults; radii (cards r24, bubble r18, lock r18), 3px ink borders, kid shadows, icon choice all match; coin pill 120, avatar M, dock Pip/Shop/My jar all present and ordered per design.

Numbered deviations (element, design value, app value, fix):
1. Pet art interior (Pip tuft/crown, nest strokes), bands 2–3 residual ~8–10% — design v1 `pip_stage_3.svg` linework vs app mandated v2 `PipAvatar` (Mochi/sunny/stage 3). Slot geometry is exact (bubble 125…169, box 183…419, centre x 195, hearts 448); the heat is interior drawing, not position. Fix: none — PIP orchestrator rule mandates the v2 art. Not a finding.
2. Nest rim row: design 278 vs app 274 (−4px; bowl bottom 364 vs 360; Pip feet 301 vs 297, head 199 vs ~194). Fix: shared `PipNestFallback._explicitBleed` 31.4→27.4 — SHARED_REQUEST #18(b), pinned by K03-BUG-16 test (`closeTo(274, 0.5)` documents the residual so it can only shrink). K03 may not edit core. Not a K03 finding (per 07:40 ruling: write SHARED_REQUEST and stop).
3. Counts + progress fill: design "3 done today / 3 of 6 done / 50%" vs app "4 done today / 4 of 6 done / 66.7%". Fix: none — database value is correct (DATA OVER MOCKS + PERIODS ruling). Not a finding.
4. Card 2 content: design "Reading – 20 minutes / +10" vs app "Hoover the stairs / Done" (repo alphabetical order). Fix: none — data order wins. Not a finding.
5. Status bar clock: design 9:41 vs app 13:05/13:08 (OS-drawn). Fix: none — STATUS BAR rule. Not a finding.
6. Bottom rows below dock (band 7, ~5–7%): design shows meadow-green strip + drawn home pill to y=843 vs app dock-surface to edge + OS indicator. Fix: none — OWNER bottom-edge rule overrides the PNGs; app is correct. Not a finding.
7. Dark pet glow disc: design soft glow vs app harder lilac disc. Fix: shared `shared/pet_glow` branch — not a K03 finding.

No open K03-actionable deviations. Nothing further needs a shared route for the visual pass.

VERDICT: PASS
