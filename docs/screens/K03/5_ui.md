# K03 Kid home — UI check (Stage 5, iteration 1)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_1.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_1.png` (1170x2532). Same with `dark` -> `app_dark_1.png`.
- NOTE: both runs printed `WARNING — frame never stabilised in 25 s` and exited 1; the saved last-capture frames are still usable. Also NOTE: `shot.sh` does `cd "$APP_DIR"`, so a relative `<out>` resolves under `app/`; absolute OUT paths were used.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_1.png docs/screens/K03/ui/cmp_light_1.png` (and dark).

Results:
- light mean diff: 11.74% — bands: 0 (0-105) 2.73% · 1 (105-211) 5.56% · 2 (211-316) 11.17% · 3 (316-422) 4.96% · 4 (422-527) 12.53% · 5 (527-633) 22.74% · 6 (633-738) 25.27% · 7 (738-844) 8.97%
- dark mean diff: 10.89% — bands: 0: 2.71% · 1: 5.04% · 2: 9.47% · 3: 4.74% · 4: 13.00% · 5: 20.22% · 6: 23.50% · 7: 8.52%
- Read: `cmp_light_1.png`, `cmp_dark_1.png` (design | app | diff). All logical px (PNG/3). Tolerance ±2px.

Accepted (per `1_plan.md` §g + `SHARED_REQUEST.md`, NOT deviations):
- A1 counts copy: design "3 done today" / "3 of 6 done" / 50% bar vs app "4 done today" / "4 of 6 done" / ~66.7% bar. Demo DB yields done=4 (bins+hoover approved, dishwasher+table done_pending); live counts win, no seed fork (RULES §4).
- A2 quest icon tiles: design tints per quest (sky-tint dishwasher, lilac-tint reading) vs app `surface2` for all. Known `NestKidQuestCard` limitation, SHARED_REQUEST #1 filed, non-blocking. Measured light tile: design (230,239,254) vs app (243,238,229).

Deviations (design value → app value + fix):
1. Meadow/background band missing behind lower content (major, both themes). Design light: pale green from y≈524 to y≈717 at x=10 (e.g. (231,246,222) at y=550) behind progress bar + quest cards; home strip green. App light: sky blue at same rows ((230,244,255) at y=550); green only below the dock (e.g. (191,232,176) at y=830). Dark: design teal band behind progress/cards vs app navy. Fix: reconcile `KidScope` meadow hill (spec 390x136 pinned bottom) with the PNG green band (524-717, ~194px); check scroll transparency over the hill, hill height/offset, and the baked `hill-front` colour (SPACING §9.14).
2. Pet-stage → hearts vertical gap ~30px too tall (major). Yellow-heart rows at x=30: design y 443-452 vs app y 471-485; section-title dark text: design y≈490+ vs app y≈520+ (≈30px shift, bands 2/4/5/6). Consequence: design shows 2nd card ("Reading – 20 minutes", +10 pill, check top) while app shows only its top edge. Fix: match HTML `.k3-pet` (260x236, pip 152 at bottom 96, margin 14 top) + `NestPetStage` bottom padding so hearts sit ≈30px higher.
3. Pip/nest scale + position drift (moderate). Diff heat-map shows a strong red outline around Pip + nest in both themes; app Pip renders larger/higher than the PNG 152px pip on the 260x236 nest. Fix: check `NestPetStage` still-frame (`DISABLE_ANIMATIONS=1` SVG path) geometry/scale vs HTML `.k3-pet .pip`/`.nest`.
4. Dark pet glow mismatch (minor). App dark shows a lighter-navy circle behind Pip/nest (≈230px glow, SPACING §7 `white@10%`); design dark PNG is flat navy with no circle. App follows the spec, PNG omits it — flag for orchestrator to rule which wins; listed as a deviation vs the PNG either way.
5. Filled-hearts stroke (minor). HTML l.57: filled hearts `fill coin + 2px ink-2 stroke`, 26px, gap 8; empty `surface-2/ink-3`. App filled hearts render solid coin with little/no visible outline and look larger (15 rows vs 10 in the scan). Fix: match the 2px `ink-2` stroke on filled hearts.
6. Quest-card title size (minor, pre-declared). HTML/SPACING: Nunito 18/24 w800; app renders ≈1px smaller (≈17/22 per `1_plan.md` §f). Shared-component token; builder cannot fix locally — noted.
7. Dock icons glyph + light-theme fg (minor). HTML: 24px outline set (speech-bubble Pip, bag, jar); app: `NestIcons.pipFace/bag/jar` at 26px (plan accepts 26) — recognisable but different drawings. In light, design Pip/My-jar icons read white on coloured buttons while the app's read dark. Fix: verify `NestKidButton` IconTheme fg (`on-accent`/`on-leaf`) in light theme.
8. Status-bar double render (capture artifact, informational, band 0 ≈2.7%). Native simulator time ("00:39"/"00:42") + status icons overlap the mock `NestStatusBar` "9:41". Harness artifact of `simctl screenshot`, not app code; excluded from verdict.

Otherwise correct: header (`k3-top` pad 4/20/10, s64 lilac avatar, 22/26 w900 name, 15/20 sub, 120 coin pill, 56 r18 lock), speech bubble (surface, 3px ink border, r18, tail), "Today's quests" 28/34 + `kchip` style, kid progress (h16, 2px ink border, leaf fill + gloss), card geometry (min-h 72, pad 12, r24, 3px ink border, kid shadow, 56 checks, "Waiting for Mum" chip), dock layout (surface, 3px top border, pad 12/20/10, 3x min-h 66 17/20 buttons; dark token colours correct), home pill (134x5), no horizontal overflow, no bad ellipsis, coins-only (no £), dark-mode tokens correct elsewhere.

Iteration-2 fixes (local): #1 meadow band, #2 pet→hearts gap, #3 Pip scale, #5 heart stroke, #7 dock icon fg. Shared/pre-declared: tile tint + title size (filed/noted).

VERDICT: FAIL
