# K03 Kid home — Stage 3 (TEST), iteration 13

Scope: `kid_home` / `/kid-home`, kid mode. Tests in
`app/test/features/kid_home/` (`kid_home_view_test.dart`,
`kid_home_bloc_test.dart`, `kid_home_geometry_test.dart`,
`kid_home_repository_test.dart`, `k03_bugs_test.dart`).
Per RULES §1 this stage only touched `app/test/features/kid_home/**` and
`docs/screens/K03/**` — **no screen code was patched, and no new bug was found,
so there is nothing new to record as a defect**.

**No simulator was booted, installed on or captured** (SIMULATORS rule: only the
UI-check stage may, and only `BC440E48-…`). The UI-check stage had already run
this iteration before me (`5_ui.md`, `VERDICT: PASS`); I read its report but
took no screenshots of my own.

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → **546 files, 0 changed**.
- `flutter analyze` → **No issues found!** (`analysis_options.yaml` untouched, no
  new suppressions, no `google_fonts` anywhere in the feature's tests).
- `flutter test` (whole app) → **exit 0, `+3277 ~4`** — 3277 pass, 4 skip, 0
  fail.
- `flutter test test/features/kid_home/` → **exit 0, `+346 ~3`** — 346 pass,
  3 skip, 0 fail (this directory also holds K01's suite).

| File | Iteration 12 | Now | Δ |
| --- | --- | --- | --- |
| `kid_home_view_test.dart` | 89 | **87** | build merged/split some layout pins |
| `kid_home_bloc_test.dart` | 31 | **38** | build added event-path coverage |
| `kid_home_geometry_test.dart` | 7 | **11** | **+4 from this stage** |
| `kid_home_repository_test.dart` | 2 | **2** | — |
| `k03_bugs_test.dart` | 59 (~1) | **59 (~2)** | stage 6 parked K03-BUG-17 (not mine) |

The 3 skips are all parked proofs, not failures: `K03-BUG-16` and
`K03-BUG-17` (both open, both shared/core-owned, added by other stages to
`k03_bugs_test.dart`) and one outside `kid_home`.

## The surface under test this iteration

Two shared changes landed and both are K03's whole delta:

1. **`shared/pet_bubble_gap`** — `NestPetStage` grew `bubbleGap`, and K03 now
   passes the design's own 14 (`.k3-pet { margin: 14px auto 0 }`,
   `K03-kid-home.html` l.24) with `_kStageToHearts` back to `NestSpacing.s4`.
2. **`shared/kid_meadow`** — K03's feature-local in-flow `_MeadowPainter` band
   is **gone**; `KidScope` paints the design's `.screen.kid` gradient
   (`components.css` l.25) and the shared `.meadow` hills sit at the bottom
   exactly where the HTML puts them (`ORCHESTRATOR_NOTES` 15:02 and 02:45).

Change 1 was already pinned by the build's geometry pins (all now exact).
**Change 2 was pinned only structurally** — a widget-tree test can see the four
gradient stops and a missing `_MeadowPainter`, but it cannot see whether the
right pixels are on the glass or whether the grade moves with the content. That
gap is what this stage closed.

## Tests added (this stage)

All four are in `kid_home_geometry_test.dart` (real Inter/Nunito via
`FontLoader`, 390×844 @3x, pixel probes on a `RepaintBoundary`), in a new group
**`K03 — the meadow is the shared screen background (shared/kid_meadow)`**,
light + dark:

**1 + 2. `$theme: the 62% hard stop and the whole run to the dock are painted`**
- Row **522** must still be `kid-sky-bottom` and row **523** `kid-horizon`
  exactly — the stop at 62 % is *hard* in the CSS, so a band that eased into
  the meadow or started its run somewhere else breaks the pair.
- Rows **523, 530, 560, 600, 650, 690, 710, 718** each within ±2/255 of the
  shared grade `kidHorizon → kidMeadow` at `t = (y/844 − 0.62)/0.38`. The
  iteration-12 group proved two of those rows; this proves the **whole run**, so
  "the grade reaches every row" is measured rather than assumed. The dark-mode
  "flat navy" regression (FIXES_8…_10, called out four times) can no longer pass.
- Rows **700, 710, 718** must be well clear of flat `kid-meadow`: the shared
  hills are `bottom: 0`, 136 tall, so their crest at x 10 sits at y ≈ 764 —
  *behind* the dock that starts at 719. If the hills were raised, made taller or
  pulled up in flow, their flat tone would land in the 708…718 window the design
  paints as the run. (Threshold `max(Δgreen, Δblue) > 8`; the real margins are
  Δblue 12…23 and Δgreen 6…10. Red is deliberately not used — dark's run and
  dark's meadow share a red level, 33 vs 30, which would be a false alarm.)

**3 + 4. `$theme: scrolling the quests does not move the meadow`**
- The design's meadow is the **screen's**, so it must not move with the content.
  Pixels at (10, 600) and (10, 700) are sampled, the list is dragged to its end,
  then both rows are sampled again: each must still equal the shared grade, and
  must be unchanged within 1/255.
- Anti-vacuity guards, because "it did not move" is worthless if nothing moved:
  `maxScrollExtent > 200` and the final offset is the clamped end; **and** the
  progress bar — which sits in the *same* scroll column as an in-flow band would
  — is asserted to have moved by exactly `pixels`. So in one frame the content
  travels 474 px while the background rows do not move by a single level. An
  in-flow band cannot pass this: it moves with `pixels`, which is precisely what
  the control measures.

## Results — the shared grade vs the design PNGs

Design values read from `design/screens/{light,dark}/K03-kid-home.png` ÷3 with
PIL at x = 10 (the 20 px gutter, so no card, chip or dock border is in the
sample). "grade" is the token lerp my test pins to ±2:

| row | light grade | light design | dark grade | dark design |
| --- | --- | --- | --- | --- |
| 523 | (234, 247, 226) | (234, 247, 226) | (37, 51, 89) | (37, 51, 89) |
| 530 | (233, 247, 225) | (233, 247, 225) | (37, 51, 88) | (37, 52, 89) |
| 560 | (229, 245, 220) | (229, 246, 221) | (36, 54, 85) | (37, 54, 86) |
| 600 | (224, 243, 214) | (224, 244, 214) | (35, 57, 82) | (36, 57, 82) |
| 650 | (217, 241, 206) | (217, 241, 207) | (34, 60, 77) | (35, 60, 77) |
| 690 | (212, 239, 200) | (212, 240, 200) | (33, 63, 73) | (34, 63, 73) |
| 710 | (209, 238, 197) | (209, 239, 197) | (33, 64, 71) | (33, 65, 71) |
| 718 | (208, 238, 196) | (208, 238, 196) | (33, 65, 70) | (33, 65, 71) |

**Every row agrees with the design within 1 level** (the PNG's own 8-bit
rounding of the CSS lerp), in both themes — the shared background is exact, not
approximate. 5_ui measured the same two anchor rows on the device (light
(223,242,213) vs design (223,243,214) at y 600; dark (34,55,81) vs (35,56,81)),
which agrees.

Rows below 719 are deliberately **not** pinned. The design PNG's own dock ends
at y 809 and rows 810…843 are the hill-front tint under a drawn home pill — the
green strip the **owner rejected** (`ORCHESTRATOR_NOTES`, "OWNER FEEDBACK").
The bottom-edge group proves the app instead paints the dock surface to 844.

## Results — geometry rows at real fonts (390×844, unchanged by this stage)

| row | measured | design | Δ |
| --- | --- | --- | --- |
| speech bubble | 125…169 | 125…169 (`.k3-pet` margin 14) | **0.0** |
| **pet slot box** | **183…419** | **183…419** | **0.0** |
| nest rim | 274.0 | 278 | −4 (shared, #18(b)) |
| Pip feet | 297 | 301 | −4 (shared, #18(b)) |
| hearts row centre | 448.0 | 448 | **0.0** |
| "Today's quests" chip centre | 494 | 494 | 0.0 |
| progress bar | 527…542 | 527…542 | **0.0** |
| card 1 painted top | 559 | 559 | **0.0** |
| cards 2…6 | 12 px painted gaps | `.k3-quests { gap: 12px }` | 0.0 each |
| dock painted top | 719 | ≈720 | −1.0 |

The hero block's rows are now **exact** — `bubbleGap: 14` + `s4` closed the 9 px
the iteration-12 report carried. The only hero deviation left is the 4 px inside
the box (shared `PipNestFallback._explicitBleed`), pinned by the build at 274
and by stage 6 as the open K03-BUG-16.

## Bugs found

**None new.** No test I added or inherited failed, and no K03 code misbehaved.

### Known shared residuals (other stages' findings, not mine)

- **K03-BUG-16** — the nest/Pip sit 4 px high inside the pet box (one private
  constant in `core/`: `PipNestFallback._explicitBleed` 31.4 vs the design's
  27.4). SHARED_REQUEST #18(b). Pinned at the current value by the build's
  geometry pins and at the design's value by the parked proof.
- **K03-BUG-17** (added by stage 6 while I worked) — the nest **bowl** is
  squashed: the HTML draws `nest.svg` at its intrinsic ratio in the 236-tall
  `.k3-pet` box (a ~108 px bowl; `K03-kid-home.html` l.25), the app stretches it
  into the mandated `nestHeight: 188` (`BoxFit.fill`) for 86.2. SHARED_REQUEST
  #18(c). Not a K03 file; K03 may not edit `core/`.
- **Dark pet glow** — a shared component (`shared/pet_glow`), not K03's.

### Housekeeping (not a finding)

The UI-check stage left its scratch probe behind:
`app/test/features/kid_home/_scratch_probe_test.dart` ("TEMPORARY pixel probe
for stage 6 iteration 13. Deleted before commit."), untracked, mtime 13:12. It
duplicated the speech-tail ink measurement that
`kid_home_geometry_test.dart` already pins. It was inside my §1 path and inside
the orchestrator's standing "delete the scratch probe test so analyze is clean"
instruction, so I removed it. No stage code was involved.

## Owner rules re-checked

- **BOTTOM EDGE:** unchanged and green — dock surface painted from 719 to the
  physical edge in both themes (light `#FFFFFF`, dark `#1F1C2E`), with the OS
  inset and with a top inset. My new hill pin additionally proves the *shared
  hills* cannot leak into 700…718 above the dock, which is the one way this
  iteration's change could have produced a green strip.
- **ALIGNMENT:** unaffected by this change (nothing in the dock or gutters
  moved); gutters, card/bar/dock edges, the pet slot's axis at 320/390/430 and
  the 12 px card rhythm all still pass.
- **DATA OVER MOCKS / PERIODS:** quest counts and quest order come from the DB
  ("4 done today", "4 of 6"); the daily/weekly/once and new-period proofs are
  green. No design number is hard-coded anywhere I touched.
- **COPY:** re-verified character-by-character against the HTML source. The file
  contains only two non-ASCII characters (`—` and `·`, both in `<title>`);
  `Let's do some quests!` and `Today's quests` use **straight** apostrophes
  (U+0027), and so does the app. No curly quotes were invented.

## Rule coverage

| Rule | Status on K03 |
| --- | --- |
| KID BACKGROUND | The shared hills and gradient are now pinned on **pixels** in both themes — 8 rows of the run, the 62 % hard stop, and the "hills stay behind the dock" window; structure still pinned in `kid_home_view_test.dart` |
| PIP | `PipAvatar` in every state from the child's own row, seated in the bowl (its row is K03-BUG-16/17's shared residual) |
| UI VERDICT RULE | Every row below the hero within ±2 px at real fonts; the hero block's box is now exact, the 4 px inside it is named and pinned on both sides |
| BOTTOM EDGE / ALIGNMENT | Proven by tests, plus the new no-hill-above-the-dock pin |
| PERIODS + DATA OVER MOCKS | Counts from the DB; new-period proofs green; order pinned as documented |
| COPY | Straight apostrophes confirmed against the source; en dash and middle dot left alone |
| FONTS / LETTER SPACING | No `google_fonts`; every rendered string asserts `letterSpacing == 0` |
| CHIP ROWS (`NestChipWrap`) | Not applicable: K03's chips are the non-interactive `KidStatusChip` |
| UI CHECK MEASURES SHAPES | Painted rects and pixel bytes — the meadow grade, the hill window, the tail, the card/check/chip boxes |
| BALANCED HEADINGS | The only `.kid-title` heading renders through `NestBalancedText` |
| ACCESSIBILITY ACTIONS | Unchanged and green — tap action on every control, real effect on `performAction`, none on non-controls, ≥56 kid / ≥44 parent targets |
| CHILD ORDER | No child list here; pinned at the repository level |
| TRIAL | No test writes `subscription_status` |
| SIMULATORS | None booted by this stage |

## Harness notes (carry forward)

- **Overscroll bounce must be settled before measuring.** Dragging past the end
  of the quest list leaves the content ~15 px further out per 300 px gesture
  while `position.pixels` stays clamped at `maxScrollExtent` (474). A single
  `pump` after each drag samples that mid-flight frame: the progress bar
  measured −107 instead of 53. `pumpAndSettle` lands it on 53.0 exactly
  (527 − 474). This is ordinary iOS bouncing physics, not a defect — but any
  test that measures after a scroll-to-end **must** settle first.
- **Don't hold a `ScrollPosition` across drags.** The lazily-built card column
  can rebuild the scroll view mid-gesture and the captured reference goes stale
  (`pixels` frozen mid-scroll while the content kept moving). Read
  `tester.state<ScrollableState>(list).position` *after* the drags.
- **Choose the discriminating colour channel deliberately.** Dark's graded run
  (33, 64, 72) and dark's flat `kid-meadow` (30, 74, 58) differ by 3 on red —
  an assertion on red there would fail on a correct build. Green and blue
  separate them (6…23 levels).
- Pixel methodology used here: `RepaintBoundary` + `boundary.toImage()` inside
  `tester.runAsync`, read at absolute logical coordinates, sampling x = 10 (the
  gutter). Design truth was read the same way from the PNGs with PIL (÷3). Both
  agree within 1 level.
- The design's arithmetic, for reference: bubble 125 + 44 + 14
  (`.k3-pet { margin: 14px auto 0 }`) = pet box 183…419, then `.scroll > * + *`
  = `s4` 16 → hearts row 435, centre 448, title 494, progress 527…542, card 1
  559. Every one of those is now measured, not approximated.
- Offstage cards have **no semantics node**; scroll a control into view before
  asserting or performing its semantics action. `pushedPath`, not `currentPath`,
  for `push`ed routes. Direct Drift work inside `testWidgets` must run inside
  `tester.runAsync`; never `pumpAndSettle` while a loading spinner is on screen
  (my new scroll test settles only because the loaded screen is already built).
  Seed the DB before pumping the route.

VERDICT: PASS