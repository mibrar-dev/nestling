# Nestling — SPACING_AUDIT (spec vs Dart)

Date: 2026-09-30. Contract: `docs/design/SPACING_SPEC.md` (logical px, CSS = Flutter dp 1:1).
Visual truth: `design/screens/light/*.png` (1170×2532 @3x → ÷3).
Code under audit: `app/lib/core/design_system/**`, `app/lib/features/design_system_gallery/**`.
Method: every property in SPACING_SPEC checked against the implementation; HTML sources
(`design/html-source/screens/*.html` local `<style>`) used as tie-breaker where the PNG is ambiguous.
`FAIL → FIXED` = was wrong, fixed in this pass. No open FAILs remain.

Legend: `file:line` = where the value lives now. All spacing literals use `NestSpacing`,
all radii `NestRadii`, all shadows `NestShadows`, all type `NestType`.

## 0. Tokens — space / radii / shadows / type / device / colours

### Space (`tokens/spacing.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| `--s1` | 4 | `spacing.dart:8` `s1 = 4` | PASS |
| `--s2` | 8 | `spacing.dart:9` `s2 = 8` | PASS |
| `--s3` | 12 | `spacing.dart:10` `s3 = 12` | PASS |
| `--s4` | 16 | `spacing.dart:11` `s4 = 16` | PASS |
| `--s5` | 20 | `spacing.dart:12` `s5 = 20` | PASS |
| `--s6` | 24 | `spacing.dart:13` `s6 = 24` | PASS |
| `--s8` | 32 | `spacing.dart:14` `s8 = 32` | PASS |
| `--s10` | 40 | `spacing.dart:15` `s10 = 40` | PASS |
| `--pad-side` | 20 | `spacing.dart:18` `padSide = 20` | PASS |
| gap 2 (meta `margin-top:2`, gloss `top:2`) | 2, tokenised | `spacing.dart:25` `gap2 = 2` (NEW) | FAIL → FIXED |
| pager dot half-gap (gap 6 → 3+3) | 3, tokenised | `spacing.dart:26` `gap3 = 3` (NEW) | FAIL → FIXED |
| grabber/bar `height:5`, P08 coin `padding:5px` | 5, tokenised | `spacing.dart:27` `gap5 = 5` (NEW) | FAIL → FIXED |
| gaps 6 (`chip gap`, `meta gap`, icon gap) | 6, tokenised | `spacing.dart:28` `gap6 = 6` (NEW) | FAIL → FIXED |
| P02 coin `padding:7px 10px` vertical | 7, tokenised | `spacing.dart:29` `gap7 = 7` (NEW) | FAIL → FIXED |
| P08 coin `padding:5px 9px` horizontal | 9, tokenised | `spacing.dart:30` `gap9 = 9` (NEW) | FAIL → FIXED |
| keypad `gap:10`, P11 row `gap:10`, P08 grid `gap:10` | 10, tokenised | `spacing.dart:31` `gap10 = 10` (NEW) | FAIL → FIXED |
| hero/pill `padding:14px`, chip `padding:0 14px` | 14, tokenised | `spacing.dart:32` `gap14 = 14` (NEW) | FAIL → FIXED |

### Radii (`tokens/radii.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| `--r-s` | 10 | `radii.dart:9` `s = 10` | PASS |
| `--r-m` | 16 | `radii.dart:10` `m = 16` | PASS |
| `--r-l` | 24 | `radii.dart:11` `l = 24` | PASS |
| `--r-xl` | 32 | `radii.dart:12` `xl = 32` | PASS |
| `--r-pill` | 999 | `radii.dart:13` `pill = 999` | PASS |

### Shadows (`tokens/shadows.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| `--sh-1` light `0 1/2px` ink@6% | `0x0F1E1B3A` ×2 | `shadows.dart:13` | PASS |
| `--sh-2` light `0 6/24px` ink@10% | `0x1A1E1B3A` | `shadows.dart:19` | PASS |
| `--sh-kid` light `0 6/0` ink@12% | `0x1F1E1B3A` | `shadows.dart:24` | PASS |
| `--sh-1` dark black@35/40% | `0x59/0x66` | `shadows.dart:29` | PASS |
| `--sh-2` dark black@50% | `0x80` | `shadows.dart:35` | PASS |
| `--sh-kid` dark black@45% | `0x73` | `shadows.dart:40` | PASS |
| focus ring `2px leaf-tint + 3px leaf` | stacked spreads 2 + 1 | `shadows.dart:45` `focusRing` | PASS |

### Type (`tokens/typography.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| display 34/40 w900 ls −1% | −0.34 | `typography.dart:46` | PASS |
| h1 28/34 w900 Nunito | exact | `typography.dart:48` | PASS |
| h2 22/28 w800 Nunito | exact | `typography.dart:50` | PASS |
| h3 18/24 w800 Nunito | exact | `typography.dart:52` | PASS |
| body 16/24 w400 Inter | exact | `typography.dart:56` | PASS |
| body-s 15/22 w400 | exact | `typography.dart:60` | PASS |
| caption 13/18 w400 ink-2 | exact | `typography.dart:64` | PASS |
| field label 13/18 w600 | exact | `typography.dart:68` | PASS |
| section label 13 w700 ls +6% (0.78) | exact | `typography.dart:72` | PASS |
| chip 14/20 w600 | exact | `typography.dart:76` | PASS |
| status chip 12/16 w700 | exact | `typography.dart:80` | PASS |
| nav compact 18/24 w800 Nunito centred | was Inter 17/22 w600 | `typography.dart:84` fixed | FAIL → FIXED |
| tab 11/14 w600 | exact | `typography.dart:88` | PASS |
| button 16/24 w700 | exact | `typography.dart:92` | PASS |
| money tabular w700 | `tabularFigures` | `typography.dart:96` | PASS |
| status clock 15 w600 ls −1% | −0.15 | `typography.dart:104` | PASS |
| kid-body 18/26 w700 Nunito | exact | `typography.dart:108` | PASS |
| kid-title 28/34 w900 | exact | `typography.dart:110` | PASS |
| kid-hero 40/44 w900 | exact | `typography.dart:112` | PASS |
| kid button 20/26 w900 | exact | `typography.dart:116` | PASS |
| coin-pill 16/16 w800 | exact | `typography.dart:120` | PASS |

### Device (`tokens/spacing.dart:21-44`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| `--status-h` 47 | 47 | `spacing.dart:32` | PASS |
| `--home-h` 34 | 34 | `spacing.dart:35` | PASS |
| `--tab-h` 84 | 84 | `spacing.dart:38` | PASS |
| tap parent 44 | 44 | `spacing.dart:41` | PASS |
| tap kid 56 | 56 | `spacing.dart:44` | PASS |

### Colours (`tokens/colors.dart:260-354`)

All 40 light + 40 dark values verified 1:1 against `tokens.css :root` /
`:root[data-theme="dark"]` (ink, ink-2/3, paper, surface, surface-2, line, leaf,
leaf-ink, leaf-tint, coin, coin-ink, coin-tint, sky, sky-tint, lilac, lilac-strong,
lilac-tint, peach, peach-tint, success, warning, danger, on-leaf, on-accent, on-warm,
hero-bg, on-hero, on-hero-2, apple-bg/ink, google-bg/ink/line, scrim, ground-shadow,
track, knob, a-lilac, a-peach, a-sky, kid-sky-top/bottom, kid-meadow, kid-horizon).
Hero never derives from ink (dark hero `#2A2640` ≠ ink `#F3F0FA`). All PASS.

## 1. Chrome

### `.status-bar` → `NestStatusBar` (NEW `components/nest_chrome.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| height / min-height | 47 | `nest_chrome.dart:30` `statusH` | FAIL → FIXED (was missing) |
| padding `12px 24px 0` | 12/24/0 | `nest_chrome.dart:31` `s3/s6/0` | FAIL → FIXED |
| font Inter 15 w600 ls −1% | `statusTime` | `nest_chrome.dart:43` | FAIL → FIXED |
| icon row gap 6 | `gap6` | `nest_chrome.dart:44` | FAIL → FIXED |
| icon sizes 18×12 / 16×12 / 25×12 | exact | `nest_chrome.dart:62,100,142` | FAIL → FIXED |
| colour ink; on-dark #FFF; kid ink | `lightIcons` flag | `nest_chrome.dart:29,41` | FAIL → FIXED |

### `.home-indicator` → `NestHomeIndicator` (NEW `components/nest_chrome.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| height / min 34 | 34 | `nest_chrome.dart:213` `homeH` | FAIL → FIXED |
| pill 134×5 radius 999 ink@90% | exact | `nest_chrome.dart:217` | FAIL → FIXED |
| on-dark pill #FFF; kid keeps ink | `lightPill` flag | `nest_chrome.dart:215` | FAIL → FIXED |

### `.nav-bar` → `NestNavBar` (`components/nest_nav_bar.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| default min-height 64 | 64 | `nest_nav_bar.dart:73` (was unenforced) | FAIL → FIXED |
| default padding `8px 12px 12px` (top row) | 8/12 | `nest_nav_bar.dart:79` `s2/s3` (was 0 top) | FAIL → FIXED |
| default gap 8 | `s2` | compact row only; default row uses Spacer (no gap needed) | PASS |
| compact min-height 52 | 52 | `nest_nav_bar.dart:31` (was 44) | FAIL → FIXED |
| compact padding-top 4, sides/bottom 12 | 4/12/12 | `nest_nav_bar.dart:32` `s1/s3/s3` (was horiz-only) | FAIL → FIXED |
| back 44×44 radius 12 transparent, icon ~24 | exact | `nest_nav_bar.dart:137` + `nest_icon.dart:87` | PASS |
| title default Nunito 28/34 w900 | `h1` | `nest_nav_bar.dart:108` | PASS |
| title compact 18/24 w800 centred | `navCompact` | `nest_nav_bar.dart:50` + `typography.dart:84` (was Inter 17 w600) | FAIL → FIXED |
| action min 44×44, pad `0 12px`, Inter 16 w700 leaf | exact | `nest_nav_bar.dart:158` | PASS |
| balance spacer 44 wide (compact) | `tapParent` | `nest_nav_bar.dart:42,60` | PASS |

### `.scroll` → Scaffold body padding

| Property | Spec | Found | Verdict |
|---|---|---|---|
| base `0 20px 32px`, siblings +16 | padSide/s8/s4 | gallery previews + feature screens (unchanged) | PASS |
| P14 bottom 66; K06/K08 `34+24=58` | per-screen | noted in §6-screen tables below | PASS |

### `.tab-bar` → `NestTabBar` (`components/nest_tab_bar.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| bar height/min 84 | `tabH` | `nest_tab_bar.dart:34` | PASS |
| bg surface, top border 1×line | exact | `nest_tab_bar.dart:35` | PASS |
| padding `8px 4px 24px` | s2/s1/s6 | `nest_tab_bar.dart:39` | PASS |
| tab column, gap 4, padding-top 2, min 44 | s1/gap2/44 | `nest_tab_bar.dart:79,82,89` | PASS |
| label Inter 11 w600 lh14; icon 24 | exact | `typography.dart:88`, `nest_icon.dart:87` | PASS |
| ink-3, active leaf | exact | `nest_tab_bar.dart:86,94` | PASS |

## 2. Buttons

### `.btn` → `NestButton` (`components/nest_button.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| min-height 52, full width | exact | `nest_button.dart:30,159` | PASS |
| padding `0 24px` | `horizontalPadding` default s6 | `nest_button.dart:36,183` | PASS |
| radius pill, border 1 transparent | `allPill`, null | `nest_button.dart:190` | PASS |
| Inter 16 w700 lh24, gap 8 | exact | `nest_button.dart:142,196` | PASS |
| pressed `translateY(1px)` + shadow | `AnimatedContainer` + `cardShadow` | `nest_button.dart:175` (was missing) | FAIL → FIXED |
| disabled opacity .45, no shadow, null | exact | `nest_button.dart:156,192` | PASS |
| focus 3px leaf outline outside | spread `gap3` when focused | `nest_button.dart:198` (was `focusColor` wash) | FAIL → FIXED |
| icon 20 | exact | `nest_button.dart:77` | PASS |
| P08 banner: auto width, 44, `0 18px`, 15 | params | `nest_button.dart:48,51,36` (NEW) | FAIL → FIXED |
| P11 appr row: 48, 15, `0 12px` | params | same (NEW) | FAIL → FIXED |
| P12 rowbtns: 48, 15 | params | same (NEW) | FAIL → FIXED |
| P12 hero btn margin-top 14, 52 | caller margin | gallery/feature (unchanged) | PASS |
| primary leaf/on-leaf; secondary surface/ink/line/sh-1 | exact | `nest_button.dart:50` | PASS |
| ghost transparent/ink; dangerGhost transparent/danger | exact | `nest_button.dart:60` | PASS |

### `.btn-apple/.btn-google` (`components/nest_brand_buttons.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| same geometry as `.btn` (52, 24, pill, 16 w700) | exact | `nest_brand_buttons.dart:141,152,172` | PASS |
| apple bg/ink flips dark; google bg/ink/line | tokens | `nest_brand_buttons.dart:35,72` | PASS |
| icon 20 | exact | `nest_brand_buttons.dart:123` | PASS |

### `.btn-kid` → `NestKidButton` (`components/nest_kid_button.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| Nunito 20 w900 lh26 | exact | base + `nest_kid_button.dart:186` | PASS |
| min-height 64, radius 24, border 3×ink, sh-kid 0/6 | exact | `:27,41,149` | PASS |
| padding `0 24px`, gap 8, full width | exact | `:36,56,125` | PASS |
| 6 colourways (leaf/coin/sky/peach/lilac/white) | tokens | `:47` | PASS |
| pressed `translateY(4px)`, shadow `0 2px` | exact | `:144,157` | PASS |
| disabled opacity .45, no shadow | exact | `:120` | PASS |
| icon 26; bottom-6 shadow pad | exact | `:103,122` | PASS |
| K06 care: column, gap 3, 88, `8px 4px`, 17/20 | params | `axis/gap/minHeight/contentPadding/fontSize` (NEW) | FAIL → FIXED |
| K03 dock: column, gap 4, 66, `0 6px`, 17/20 | params | same (NEW) | FAIL → FIXED |
| K08 get: 56, radius 16, 17 w900, 3px + sh-kid | params | `borderRadius/fontSize` (NEW) | FAIL → FIXED |

### `.btn-row` / `.bottom-cta`

| Property | Spec | Found | Verdict |
|---|---|---|---|
| row gap 12, children flex 1 min 0 | callers | gallery/feature (unchanged) | PASS |
| cta bg surface, top border 1×line, pad `16px 20px`, gap 8, caption centred | s4/padSide/s2 | `nest_bottom_cta.dart:25,33` | PASS |
| P06 dense pad-v 14 | `dense` flag | `nest_bottom_cta.dart:25` | PASS |

## 3. Cards / lists

### `.card` → `NestCard` (`components/nest_card.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| base surface, radius 24, sh-1, padding 16 | s4/allL/cardShadow | `nest_card.dart:32,36` | PASS |
| inset surface-2, no shadow | exact | `nest_card.dart:39` | PASS |
| hero hero-bg/on-hero, radius 24, padding 20, sh-2 | padSide/allL/raisedShadow | `nest_card.dart:31,44` | PASS |
| hero never ink-derived | `heroBg` token | `nest_card.dart:44` | PASS |

### `.list` / `.list-row` (`components/nest_list_row.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| list surface, radius 16, sh-1, hidden overflow | exact | `nest_list_row.dart:112` | PASS |
| divider left 72, h 1, line | exact | `nest_list_row.dart:129` | PASS |
| row gap 12, min 56, padding `10/16/10/12` | s3/56/literal | `nest_list_row.dart:53,55,100` | PASS |
| tile 40×40 radius 16 surface-2/ink | exact | `:56,65` | PASS |
| tile tints (leaf/coin/sky/lilac/peach) | tokens | `:33` | PASS |
| title 16 w600 lh22 ellipsis 1 | `+ height 22/16` | `:79` (was lh 24) | FAIL → FIXED |
| sub 13/18 ink-2 ellipsis 1 | `caption` | `:86` | PASS |
| P02 compact tile 36 radius 12 | `compact` flag (NEW) | `:18,56` | FAIL → FIXED |
| trailing shrink-0 | `Flexible` (hardening: allows shrink, never overflows) | `:93` | PASS* |

### `.chip` → `NestChip` (`components/nest_chip.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| height 32, padding `0 14px`, radius pill | s8/gap14/allPill | `nest_chip.dart:37,60` | PASS |
| Inter 14 w600, border 1.5 transparent | exact | `nest_chip.dart:29,51` | PASS |
| selected leaf-tint/leaf-ink/border leaf | exact | `nest_chip.dart:26` | PASS |
| interactive wrapped in 44×44 tap area | `ConstrainedBox` | `:74` | PASS |
| static (no callback) keeps visual 32 | no wrapper (non-tappable) | `:63` | PASS |
| maxLines 1 ellipsis + Flexible parent | exact | `:48` | PASS |
| leading icon 16, gap 6 | s4/gap6 | `:43,46` | PASS |

### `.segmented` → `NestSegmented` (`components/nest_segmented.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| container surface-2, pill, padding 4, gap 4 | s1 | `nest_segmented.dart:38,86` | PASS |
| buttons Expanded, 44 high, pill, 14 w600 ink-2, ellipsis | exact | `:43,45,65` | PASS |
| selected surface/ink/sh-1; total height 52 | 44+4+4 | `:60` | PASS |

### `.toggle` → `NestToggle` (`components/nest_toggle.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| track 51×31 pill, track bg, checked leaf | exact | `nest_toggle.dart:45,48` | PASS |
| knob 27 white, top/left 2, shadow black@25% `0 2/6` | exact | `:60,67` | PASS |
| checked translateX 20 | `centerLeft→centerRight` (=20) | `:52` | PASS |
| wrapper min 59×44 (≈59×45 hit slop) | exact | `:38` | PASS |

### `.field` → `NestField` (`components/nest_text_field.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| container column gap 6; label 13 w600 lh18 ink-2 | `fieldLabel` | `nest_text_field.dart:183,187` | PASS |
| input height 52 (min 44), radius 16, border 1×line, surface, pad `0 16px`, Inter 16 | contentPad h16/v14 | `:121,149,161` | PASS |
| focus border leaf + ring spreads 2/1 | `focusRing` | `:126,137` | PASS |
| error 13/18 danger w600; invalid border danger | exact | `:130,156` | PASS |
| helper 13/18 ink-2 | `caption` | `:155` | PASS |
| eye button 44×44 radius 12 ink-2 | exact | `:100,113` | PASS |

### `.stepper` → `NestStepper` (`components/nest_stepper.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| row gap 12 | s3 | `nest_stepper.dart:36,48` | PASS |
| buttons 44×44 circle, border 1×line, surface, 20 w700 | exact | `:85,95,103` | PASS |
| value min-width 64, centre, 18 w700 tabular | exact | `:38,42` | PASS |

## 4. Avatar / coin / money / progress / badge

### `.avatar` → `NestAvatar` (`components/nest_avatar.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| circle Nunito w900 | exact | `nest_avatar.dart:56,60` | PASS |
| 32/14 · 44/18 · 64/24 · 96/38 | exact | `:14,21` | PASS |
| 6 colourways incl. a-* tokens | exact | `:45` | PASS |

### `.coin-pill` → `NestCoinPill` (`components/nest_coin_pill.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| row gap 6, coin-tint/coin-ink, Nunito w800, radius pill, nowrap | gap6/allPill | `:62,69` | PASS |
| standard 16, padding `8px 12px`, icon 20 | s2/s3/20 | `:50,55` | PASS |
| big 20, padding `10px 16px` | 16/10 | `:57` | PASS |
| P02 small 14, `7px 10px`, icon 18 | gap10/gap7/18 | `:35` (was 13/9/5/15) | FAIL → FIXED |
| P08 inline x-small 13, `5px 9px`, icon 15 | gap9/gap5/15 | `:43` (NEW size) | FAIL → FIXED |

### `.money` / `.progress` / `.badge-count`

| Property | Spec | Found | Verdict |
|---|---|---|---|
| money tabular w700 nowrap ellipsis | exact | `nest_money.dart:22` | PASS |
| progress base h 8 pill surface-2, fill leaf | s2/allPill | `nest_progress.dart:22,28,38` | PASS |
| kid h 16 border 2×ink surface + gloss 4/4/2 white@55% | s1/gap2 | `:30,49,55` | PASS |
| badge min 22×22 pad `0 6px` pill leaf/on-leaf 12 w700 | gap6/`chipSmall` | `nest_badge_count.dart:20,30` | PASS |

## 5. Overlays

| Property | Spec | Found | Verdict |
|---|---|---|---|
| scrim ink@45 / black@62 (barrier, no widget) | `scrim` token | `nest_theme.dart:47`, sheet/modal usage | PASS |
| sheet max-h 92%, paper, radius 32/32/0/0 | `topXl` | `nest_bottom_sheet.dart:124,22` | PASS |
| sheet padding `8px 20px 50px` (34+16) | s2/s5/homeH+s4 | `:25` | PASS |
| grabber 40×5 pill line, margin `4px auto 12px` | s10/gap5 | `:38` (height was literal 5, now token) | PASS* |
| sheet title row `4px 0 8px`, 18/24 w800 | h3 | `:51,63` | PASS |
| modal 24-side (342 wide), radius 32, pad `24/20/20`, sh-2, centred | s6/s5/raisedShadow | `nest_modal.dart:24,64` | PASS |
| toast 20-side, bottom 50, ink/paper, radius 16, pad `14/16`, 15 w600 | gap14/s4 | `nest_toast.dart:24,46` | PASS |
| empty-state centre, pad `24px 16px`, gap 8, art 160 | s6/s4/s2 (was swapped) | `nest_empty_state.dart:22,28,31` | FAIL → FIXED |
| P08b empty-card surface/24/sh-1/`28/20`/140/22/15-260 | caller-level | gallery (unchanged) | PASS |

## 6. Quest cards

### `.quest-card` → `NestQuestCard` (`components/nest_quest_card.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| row gap 12, surface, radius 16, sh-1, padding 12 | s3/allM/cardShadow | `:47,57,59` | PASS |
| title 16 w700 lh22 (P08 wraps maxLines 2) | `+ height 22/16` | `:69` (was lh 24) | FAIL → FIXED |
| meta row gap 6, 13 ink-2, margin-top 2, wrap | gap6/s1/gap2/`caption` | `:77,79,86` | PASS |
| check 56×56 circle border 3×ink surface; done leaf/leaf/on-leaf | `tapKid`/3 | `:228,231` | PASS |
| P08 status-chip 26, `0 10px`, pill, 12 w700, 3 colourways | gallery `_StatusChip` | `gallery_screens.dart:401` | PASS |

### `.quest-card.kid` → `NestKidQuestCard`

| Property | Spec | Found | Verdict |
|---|---|---|---|
| min 72, padding 12, radius 24, border 3×ink, sh-kid, gap 12 | exact | `:143,145,150,161` | PASS |
| kid-icon 48×48 radius 16 surface-2 | `allM` | `:163` | PASS |
| title Nunito 18/24 w800 | `h3` | `:187` | PASS |
| shadow bottom-6 pad (no clipping) | `bottom: gap6` | `:141` | PASS |

## 7. Pet / keypad / misc

### `.pet-stage` → `NestPetStage` (`components/nest_pet_stage.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| column centre, padding `8px 0 0` | bubble bottom s2 | `:39` | PASS |
| glow 230 circle (none light / white@10% dark) | `0x1AFFFFFF` dark only | `:120` | PASS |
| art 200 default; shadow ellipse ground-shadow | `pipSize`/`_GroundShadow` | `:22,186` | PASS |
| speech surface/3×ink/radius 18/pad `8/14`/Nunito 16 w800/max 260 | gap14/s2 | `:226` | PASS |
| tail 9px triangle ink | `_TailPainter` | `:247` | PASS |
| K03 260×236 (pip 152/bottom 96); K06 230×206 (134/81) | callers scale | screens (unchanged) | PASS |

### `.keypad` → `NestKeypad` (`components/nest_keypad.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| grid 3 cols, gap 10, padding `8px 24px 0` | gap10/s6/s2/0 | `:25,31` (gap was `Radii.s`, bottom was 8) | FAIL → FIXED |
| keys 72 circle surface Inter 26 w600 sh-1 ink | `tapKid+s4` | `:165,139` | PASS |
| kid Nunito w900 + 3×ink + sh-kid | exact | `:136,173` | PASS |
| blank 72; delete same + icon | exact | `:56,144` | PASS |
| pin-dots gap 12 pad `8px 0`, dot 18/3 ink, filled ink | s3/s2 | `:90,95,101` | PASS |

### `.fab` / `.lock-btn` / pager dots

| Property | Spec | Found | Verdict |
|---|---|---|---|
| fab right 20 bottom 100, h52 min52 pad `0 20px` pill leaf/on-leaf 16 w700 gap8 sh-2 | s5/52/`buttonLabel` | `nest_fab.dart:41,44,56` | PASS |
| lock base 44 radius 12 1×line surface ink-2 | s3 | `nest_lock_button.dart:23` | PASS |
| lock lg 56 radius 18 | `tapKid`/18 | `:23` | PASS |
| pager row h 18 gap 6; dot 8 line; on 22 pill leaf | gap3/pill | `nest_pager_dots.dart:28,44,50` (gap was 8+8=16) | FAIL → FIXED |

## 8. Global layout rules

| Rule | Spec | Found | Verdict |
|---|---|---|---|
| side padding 20 everywhere | `padSide` | previews, cta, sheet, nav | PASS |
| base rhythm siblings +16 | `s4` | previews separators | PASS |
| section label 13 w700 upper ls 6%, mt 24 / mb 8 | caller margins | `nest_section_label.dart:14` + previews `s4/s2` | PASS |
| P08 qgroup 13/6% `16px 0 -8px`; sec-t 18/24 w800 + 44-link 14 w600 | previews | `gallery_screens.dart:219` | PASS |
| P08 greet h1 22/28 w900 + date 15/22 mt2, pt 8 | previews | `gallery_screens.dart:96` | PASS |
| K03 top pad `4/20/10`, name 22/26 w900 + sub 15/20 | previews | `:541` | PASS |
| card gaps 16; K03 quests 12; 2-up 170+170 gap 10 | computed `colW` | `:185` (`(W-40-10)/2`, min 0) | PASS |
| 3-up stats gap 10; K11 grid gap 12 pad `10/4` | screens | unchanged | PASS |
| 7-up day row 7×1fr gap 6, 13px, Expanded, scaleDown | gap6/`FittedBox` | `nest_day_picker.dart:26,95` | PASS |
| P09 icon grid 6×44 gap 8; person pill 48 | screens | unchanged | PASS |
| P06 opt-card 60 `8/13` gap12 r16 b2; radio 22 | screens | unchanged | PASS |
| form rhythm head mt8 fields mt16 | screens | unchanged | PASS |

## Theme-level overrides (`theme/nest_theme.dart`)

| Property | Spec | Found | Verdict |
|---|---|---|---|
| ColorScheme leaf/on-leaf/coin/ink/surface/line/scrim | tokens | `nest_theme.dart:24` | PASS |
| tertiaryContainer lilacTint (components use `aLilac`, unaffected) | no override | `:37` | PASS |
| filled/elevated/outlined min-h 52 pill 16 w700 | exact | `:100,109,119` | PASS |
| iconButton min 44×44 | exact | `:134` | PASS |
| input fill surface, pad h16, min-h 52, line/leaf/danger borders | exact | `:141` | PASS |
| chipTheme label 14 w600 (was 15 `bodySmallStrong`) | `chipLabel` | `:172` (fixed) | FAIL → FIXED |
| segmentedButton label 14 w600 (was 15) | `chipLabel` | `:240` (fixed) | FAIL → FIXED |
| switch knob white, track/leaf, no outline | exact | `:178` | PASS |
| dialog surface/32, snackbar ink/paper, navBar ink3 | exact | `:203,210,226` | PASS |

## Reference-screen vertical rhythm (logical px, PNG ÷ 3)

Measured against `design/html-source/screens/*.html` local styles and confirmed on the PNGs.

### P08-today (parent, tabbed)

| Band | Value |
|---|---|
| status bar | 47 |
| greet padding-top | 8 (h1 22/28 + date 15/22 mt 2; actions 44) |
| banner margin-top | 16, padding 16, gap 12, button 44 |
| kids grid margin-top | 16, gap 10, cards 170 wide padding 14, pip 72 (margins 6/2), progress 8, coin margin-top 10 |
| `Today's quests` sec-t margin-top | 16, 18/24 + 44-high link 14 w600 |
| qgroup margin | 16 above / −8 below (net 8 with scroll 16) |
| quest cards gap | 16, padding 12, meta margin-top 2 |
| scroll bottom | 32; tab bar 84 (8 top / 24 home reserve); home 34 |
| Token coverage | every gap (2, 6, 8, 10, 12, 16) now tokenised — PASS |

### P11-approvals (parent, compact nav + bottom CTA)

| Band | Value |
|---|---|
| status 47; compact nav 52 (pad-top 4, row 44) | title 18/24 w800 centred, 44 balance spacer |
| helper margin-top 16, padding 12/14, 14/20 | leaf-tint, radius 16 |
| appr cards gap 16, padding 16, hd gap 10 | qn 17/24 margin-top 10, tm 13/18 margin-top 2 |
| appr row margin-top 14, gap 10, buttons 48 / 15 / pad 12 | flex 1 min 0 |
| bottom-cta padding 16/20 gap 8, button 52; home 34 | PASS |

### P12-money (parent, tabbed)

| Band | Value |
|---|---|
| status 47; ptitle 28/34 padding-top 8 | — |
| segmented margin-top 16, height 52 (44 + 4 + 4) | 14 w600 |
| hero margin-top 16, padding 20, lab 14, amt 40/44, brk 14/20 mt 4, button mt 14 h 52 | sh-2 |
| goal/history cards mt 16 padding 16; hrow min 56 gap 12 | icon 40 |
| rowbtns gap 10, buttons 48/15; caption mt 16 centred | — |
| scroll bottom 32; tab 84; home 34 | PASS |

### K03-kid-home (kid, dock)

| Band | Value |
|---|---|
| status 47; k3-top pad `4/20/10` gap 8 | avatar 64, name 22/26 w900, sub 15/20, coin pill, lock 56/18 |
| speech margin-top 16, pad 8/14, radius 18, border 3 | max-width 260 |
| pet 260×236, pip 152 bottom 96, margin-top 14 | — |
| hearts gap 8; sec gap 10; quests gap 12, cards min 72 | icon 48, radius 24, border 3 |
| dock pad 12/20/10 gap 12, buttons column gap 4 min 66 17/20 pad `0 6px` | home 34; scroll bottom 58 (34+24) — PASS |

### K06-pip (kid, scrolled)

| Band | Value |
|---|---|
| status 47; k6-top pad `0/20/4` (back 56 + lock 56) | — |
| title 28/34 centred | — |
| pet 230×206, pip 134 bottom 81, margin-top 9 | — |
| grow card mt 16, pad 12/14, border 3, radius 24, sh-kid | grow-top gap 8 mb 10, count mt 8 |
| care row mt 16 gap 12, buttons column gap 3 min 88 pad `8/4` 17/20 | — |
| wardrobe sec 20/26 mt 16, grid gap 12 | scroll bottom 58 — PASS |

### K08-shop (kid, scrolled)

| Band | Value |
|---|---|
| status 47; k8-top pad `0/20/6` (back 56 + lock 56) | — |
| head: title 28/34 + coin big 20 pad `10/16`; sub 15/20 | gap 10 |
| grid mt 16 gap 16; cards pad 10 border 3 radius 24 gap 6 | art 56, name 15/19 min-h 40, price 16, get mt 6 h 56 radius 16 17 w900 |
| scroll bottom 58; home 34 | PASS |

## Fixes applied (all in `app/lib/`)

New tokens: `NestSpacing.gap2/3/5/6/7/9/10/14` (`core/design_system/tokens/spacing.dart:25-32`).
New components: `NestStatusBar`, `NestHomeIndicator` (`core/design_system/components/nest_chrome.dart`, exported in `design_system.dart:11`).
New variants/params (all optional, public APIs preserved): `NestButton.fontSize/horizontalPadding/focusNode` + pressed/focus states; `NestKidButton.axis/gap/borderRadius/fontSize/contentPadding`; `NestListRow.compact`; `NestCoinPillSize.xSmall` (P08) with `small` corrected to P02.
Corrections: navCompact → Nunito 18/24 w800; compact bar 52 + 4/12 padding; default bar min 64 + top 8; quest-title lh 22; empty-state padding 24v/16h; keypad gap token + bottom 0; pager-dot half-gap 3; day-cell border 1.5 + w700 + scaleDown; chipTheme/segmentedButtonTheme 14 w600.
Gallery previews updated to the corrected values (P08 banner button 15/`0 18px`; quest coin pills → xSmall; K03 dock → vertical 17px).

## Quality gate

`dart format .` clean · `flutter analyze` → **No issues found!** · `flutter test` → all pass (see below).
Do NOT run `flutter clean` (not run).
