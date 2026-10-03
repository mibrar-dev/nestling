# Nestling — SPACING_SPEC (pixel-for-pixel, logical px @390×844)

Sources: `design/html-source/tokens.css`, `design/html-source/components.css` (200 lines, complete),
30 screen files in `design/html-source/screens/*.html` incl. each file's local `<style>`.
Canvas: `.screen` = **390w × 844h**, `overflow:hidden`, `flex-direction:column`.
PNG renders at `design/screens/light|dark/*.png` are 1170×2532 = **@3x** (divide by 3 = logical px).

All numbers below are **logical px** (CSS px = Flutter dp 1:1).

## 0. Token resolution (light → dark)

Fonts: `--font-ui: Inter, system-ui` (parent UI) · `--font-display: Nunito, system-ui` (headings + ALL kid text).
Kid rule: `.screen.kid .body/.caption` switch to Nunito; `.screen.kid .body` = 18/26 w700.

| Token | Light | Dark |
|---|---|---|
| `--ink` | #1E1B3A | #F3F0FA |
| `--ink-2` | #4A4668 | #C9C4DC |
| `--ink-3` | #6E6A8A | #A09AB9 |
| `--paper` | #FBF7F0 | #15131F |
| `--surface` | #FFFFFF | #1F1C2E |
| `--surface-2` | #F3EEE5 | #2A2640 |
| `--line` | #E7E0D4 | #363150 |
| `--leaf` | #17804F | #3CC98A |
| `--leaf-ink` | #0B5C38 | #8EE6BC |
| `--leaf-tint` | #E3F5EC | #173A2B |
| `--coin` | #F4B400 | #F4B400 |
| `--coin-ink` | #6B4E00 | #FFD86B |
| `--coin-tint` | #FFF4D1 | #3A2F10 |
| `--sky` | #2563D6 | #7FA9FF |
| `--sky-tint` | #E6EFFE | #1A2A4A |
| `--lilac` | #7C6CF2 | #A89BFF |
| `--lilac-strong` | #6A58E8 | #A89BFF |
| `--lilac-tint` | #EEEBFF | #2B2550 |
| `--peach` | #FF8A5B | #FF9E78 |
| `--peach-tint` | #FFEDE4 | #3E261D |
| `--success` | #1F9D63 | #3CC98A |
| `--warning` | #C97800 | #F0A83A |
| `--danger` | #C93A3A | #FF7A7A |
| `--on-leaf` | #FFFFFF | #0E1A14 |
| `--on-accent` | #FFFFFF | #14121F |
| `--on-warm` | #1E1B3A | #1E1B3A (unchanged) |
| `--hero-bg` | #1E1B3A | #2A2640 |
| `--on-hero` | #FFFFFF | #F3F0FA |
| `--on-hero-2` | #C9C4DC | #C9C4DC (unchanged) |
| `--apple-bg/ink` | #000000/#FFFFFF | #FFFFFF/#000000 |
| `--google-bg/ink/line` | #FFFFFF/#1E1B3A/#E7E0D4 | #131314/#E3E3E3/#8E918F |
| `--scrim` | rgba(30,27,58,.45) | rgba(0,0,0,.62) |
| `--ground-shadow` | rgba(30,27,58,.12) | rgba(0,0,0,.45) |
| `--track` | #D9D3C6 | #453F63 |
| `--knob` | #FFFFFF | #FFFFFF |
| `--a-lilac/a-peach/a-sky` | #3F35A8/#B44A1F/#1E4FA3 | #CDC4FF/#FFB795/#A9C6FF |
| `--kid-sky-top/bottom` | #CFE6FF/#F2FAFF | #1B2150/#2C3572 |
| `--kid-meadow/horizon` | #BFE8B0/#EAF7E2 | #1E4A3A/#253359 |
| `--pet-glow` | none | radial white@10% (circle 110px at 50% 45%, transparent 70%) |

Space: `--s1:4 --s2:8 --s3:12 --s4:16 --s5:20 --s6:24 --s8:32 --s10:40`, `--pad-side:20`.
Radius: `--r-s:10 --r-m:16 --r-l:24 --r-xl:32 --r-pill:999`.
Shadows: `--sh-1: 0 1px 2px rgba(30,27,58,.06), 0 2px 8px rgba(30,27,58,.06)` ·
`--sh-2: 0 6px 24px rgba(30,27,58,.10)` · `--sh-kid: 0 6px 0 rgba(30,27,58,.12)`.
Dark: `--sh-1: 0 1px 2px rgba(0,0,0,.35), 0 2px 8px rgba(0,0,0,.4)` · `--sh-2: 0 6px 24px rgba(0,0,0,.5)` ·
`--sh-kid: 0 6px 0 rgba(0,0,0,.45)`.
Type: display 34/40 w900 ls −1% · h1 28/34 w900 · h2 22/28 w800 · h3 18/24 w800 ·
body 16/24 w400 · body-s 15/22 · caption 13/18 (ink-2) ·
kid-body 18/26 w700 · kid-title 28/34 w900 · kid-hero 40/44 w900 (all Nunito).
Device: `--status-h:47 --home-h:34 --tab-h:84 --w:390 --h:844`.

## 1. Chrome

### `.status-bar` → NestStatusBar
- height 47 (min-height 47), padding `12px 24px 0`, flex row space-between center, shrink 0.
- font: Inter 15 w600; `.status-time` ls −1%.
- `.status-icons`: row, gap 6, icon sizes 18×12 / 16×12 / 25×12, `currentColor` = ink.
- States: default colour ink; `.on-dark` → #FFFFFF; `.screen.kid` → ink (explicit).
- Flutter: `SizedBox(height:47)`, padding top 12, horizontal 24; time + icon row.

### `.home-indicator` → NestHomeIndicator
- height 34 (min 34), center. `.home-pill`: 134×5, radius 999, bg ink opacity .9.
- `.on-dark .home-pill` → #FFFFFF. Kid keeps ink.
- Flutter: 34-high SafeArea filler, 134×5 pill.

### `.nav-bar` / `.nav-bar.compact` → NestNavBar
- Default: row, align flex-end, gap 8, padding `8px 12px 12px`, min-height 64.
- Compact: min-height 52, align center, padding-top 4 (sides/bottom unchanged).
- `.nav-back`: 44×44 (min 44), radius 12, transparent bg, ink icon ~24px.
- `.nav-title`: flex 1 min-width 0; default Nunito 28/34 w900 wrap-anywhere; compact 18/24 w800 centered.
- `.nav-action`: min 44×44, padding `0 12px`, Inter 16 w700, leaf colour.
- P02/P07 add `.fill{flex:1}` + `.nav-gap{width:44}` spacers; P07 `.nav-back.close` bg surface-2.
- Flutter: 64 (52 compact) bar; 44 tap targets; title Flexible; compact centers title with 44-wide balance spacer.

### `.scroll` → scroll padding
- Base: `flex:1, padding: 0 20px 32px (s8)`, `> * + * margin-top:16 (s4)`.
- Overrides (screen value wins): P12 `padding-bottom:32` (same); P14 `66`; K06/K08 `home-h(34)+s6(24)=58`;
  P09 sheet content uses sheet padding, not scroll.
- Flutter: `ListView(padding: EdgeInsets.fromLTRB(20,0,20,32))`, 16 separator; per-screen bottom override.

### `.tab-bar` + `.tab` → NestTabBar
- Bar: height 84 (min 84), grid 4×1fr, bg surface, top border 1×line, padding `8px 4px 24px` (24 = home reserve).
- Tab: column, gap 4, padding-top 2, min-height 44, Inter 11 w600 lh 14; icon 24×24; ink-3; `.active` leaf.
- Flutter: 84 bar (8 top, 24 bottom), 4 Expanded tabs, 24px icons, 4px icon-label gap.

## 2. Buttons

Base `.btn` (all parent buttons): full-width, inline-flex center, gap 8, min-height 52,
padding `0 24px`, radius pill(999), border 1 transparent, Inter 16 w700 lh 24.
Pressed: `translateY(1px)` → Flutter: translate 0,1 + drop shadow while pressed.
Disabled: **not specified in CSS** → Flutter rule: `opacity .45`, no shadow, `onPressed:null`.
Focus (keyboard): no CSS rule → Flutter: 3px leaf outline (`BorderSide(leaf,3)` outside).

- `.btn-primary → NestButton.primary`: bg leaf, fg on-leaf.
- `.btn-secondary → NestButton.secondary`: bg surface, fg ink, border line, shadow sh-1.
- `.btn-ghost → NestButton.ghost`: transparent bg/border, fg ink.
- `.btn-danger-ghost → NestButton.dangerGhost`: transparent, fg danger.
- `.btn-apple → NestAppleButton`: bg apple-bg, fg apple-ink (flips in dark). Same geometry as `.btn`.
- `.btn-google → NestGoogleButton`: bg google-bg, fg google-ink, border 1×google-line. Same geometry.
- Icon size in buttons: 20–24 (P-screens use 20; kid use 26, see below). Min tap 44×44.
- Contextual overrides (screen wins): P08 `.banner .btn` → width auto, min-h 44, padding `0 18px`,
  font 15; P11 `.appr .row .btn` → min-h 48, font 15, padding `0 12px`; P12 `.rowbtns .btn` →
  min-h 48 font 15; P12 `.hero .btn` → margin-top 14, min-h 52. P09 `.save` (sheet) → min 64×44,
  radius 999, bg leaf fg surface, padding `0 18px`, 16 w700. P09 `.cancel` → min 44×44, ink-2 16 w600.
  P13 `.pay .btn-primary` → min-h 52 (same as base).

### `.btn-kid → NestKidButton` (+ colours)
- Base: Nunito 20 w900 lh 26, min-height 64, radius 24 (r-l), border 3×ink, shadow sh-kid
  (`0 6px 0 ink@12%`), padding `0 24px`, gap 8, full width, fg ink.
- Colours: `.leaf` bg leaf/fg on-leaf; `.coin` bg coin/fg on-warm(#1E1B3A both themes);
  `.sky` bg sky/fg on-accent; `.peach` bg peach/fg on-warm; `.lilac` bg lilac-strong/fg on-accent;
  `.white` bg surface/fg ink.
- Pressed: `translateY(4px)`, shadow `0 2px 0 ink@12%`.
- Disabled: unspecified → opacity .45, shadow none.
- Icon: 24–26px (K03b uses 26). Min tap 64 high (exceeds 44).
- Screen extensions: K06 `.k6-care .btn-kid` → column, gap 3, min-h 88, padding `8px 4px`,
  font 17/20; K03 `.k3-dock .btn-kid` → column, gap 4, min-h 66, font 17/20, padding `0 6px`;
  K08 `.k8-get` → min-h 56, radius 16, font 17 w900, same 3px border + sh-kid, `.off` → bg surface-2/fg ink-2.

### `.btn-row`
- Row, gap 12, children `flex:1 min-width:0`.

### `.bottom-cta → NestBottomCta`
- bg surface, top border 1×line, padding `16px 20px`, column gap 8, shrink 0; `.caption` centered.
- P06 override: padding-top/bottom 14 (screen wins).
- Flutter: bottom bar with SafeArea bottom, 16/20 padding (14 vertical on P06-type forms).

## 3. Cards / lists

### `.card → NestCard` / `.inset` / `.hero`
- Base: bg surface, radius 24, shadow sh-1, padding 16, min-width 0.
- `.inset`: bg surface-2, no shadow.
- `.hero` (P12 `.hero`): bg hero-bg, fg on-hero, radius 24, padding 20, shadow sh-2;
  `.lab` 14 w600 on-hero-2; `.amt` Nunito 40/44 w900 ls −1%; `.brk` 14/20 on-hero-2 margin-top 4;
  inner `.btn` margin-top 14 min-h 52. NOTE: never derive hero fill from ink (dark hero #2A2640 ≠ ink).
- Screen cards with same geometry: P05 `.form-card` padding 14; P15 `.hero` center padding `20px 16px`.

### `.list` / `.list-row` → NestList
- List: bg surface, radius 16, shadow sh-1, overflow hidden.
- Row: flex, gap 12, min-height 56, padding `10px 16px 10px 12px`; divider `::before`
  left 72 right 0 top 0 height 1 bg line (starts after 40px tile + 12 gap + 12 left pad + 8).
- `.icon-tile`: 40×40 radius 16 (r-m) bg surface-2 fg ink, shrink 0; tints:
  leaf→leaf-tint/leaf-ink, coin→coin-tint/coin-ink, sky→sky-tint/sky,
  lilac→lilac-tint/lilac, peach→peach-tint/a-peach.
- `.list-main{flex:1 min-width:0}`; `.list-title` 16 w600 lh 22 nowrap ellipsis;
  `.list-sub` 13/18 ink-2 nowrap ellipsis; `.list-trail` shrink 0, gap 6, ink-3 w600.
- P04 override (screen wins): rows padding-top/bottom 7; title/sub wrap normal (multi-line).
- P02 small variant: tile 36 radius 12, inner svg 22; coin-pill 14px (see §5).

### `.chip` / `.selected` / day chip → NestChip
- Base: inline-flex center, height 32, padding `0 14px`, radius pill, bg surface-2,
  Inter 14 w600, border 1.5 transparent, nowrap.
- Selected: bg leaf-tint, fg leaf-ink, border-color leaf.
- `.chip-row`: flex wrap gap 8.
- Day variants: `.day-chip/.chip-day` → min 44×44, padding `0 12px`;
  P06 `.chip.day` → padding 0, center, font 13 (7-col grid, see §10);
  P09 `.day` → 44×44 radius 12 border 1.5 line, 14 w700 ink-2; `.sel` → bg hero-bg/fg on-hero/border hero-bg;
  P10 `.chipscroll .chip` → min-height 44, shrink 0 (scrollable filter row, edge padding 20, fade mask).
- Tap target: base 32 high is below 44 → Flutter must wrap in 44-min tap area
  (P10 already does; elsewhere add `ConstrainedBox(minHeight:44)` or padding).
- Overflow rule: maxLines 1, ellipsis; parent Flexible (see §11).

### `.segmented → NestSegmented`
- Container: flex, bg surface-2, radius pill, padding 4, gap 4.
- Button: flex 1 min-width 0, **height 40 BUT min-height 44** (CSS conflict — rendered height 44;
  use 44), border 0 transparent bg, radius pill, 14 w600 ink-2, nowrap ellipsis.
- Selected (`[aria-selected=true]/.selected`): bg surface, fg ink, shadow sh-1.
- Flutter: height 52 total (44 + 4 + 4); buttons Expanded, 44 high.

### `.toggle → NestToggle`
- iOS switch: 51×31, radius 999, bg track, no border; `:checked` → leaf.
- Knob `::after`: 27×27 white circle at top 2 left 2, shadow `0 2px 6px black@25%`;
  checked → translateX(20).
- Hit slop `::before`: −4 horizontal, −7 vertical (≈59×45 area).
- P04 technique (screen wins for sizing): `.opt-tap .toggle` height 44 with
  `background-clip:content-box` + padding `6.5px 0`, knob top 8.5 — visual track stays 51×31,
  input box is 44 tall. Flutter: `Switch` 51×31 inside 44-min GestureDetector; do NOT stretch the track.
- Min tap 44 (via wrapper).

### `.field` (label/input/helper/error/focus) → NestField
- Container column gap 6. Label 13 w600 lh 18 ink-2.
- Input: height 52 (min 44), radius 16, border 1×line, bg surface, padding `0 16px`, Inter 16.
- Focus: border leaf + ring `0 0 0 2px leaf-tint, 0 0 0 3px leaf` → Flutter FocusNode → border leaf 1
  + outer glow (two stacked BoxShadows: leaf-tint blur 0 spread 2; leaf blur 0 spread 3 — approximate
  with `boxShadow:[BoxShadow(color:leafTint,spreadRadius:2),BoxShadow(color:leaf,spreadRadius:1)]`).
- Error: text 13/18 danger w600; input `[aria-invalid=true]` border danger.
- Helper: 13/18 ink-2.
- P03 `.pw-wrap input` padding-right 52 (eye button 44×44 at right 2, radius 12, ink-2).

### `.stepper → NestStepper`
- Row gap 12. Buttons 44×44 circle, border 1×line, bg surface, 20 w700.
- Value: min-width 64, center, 18 w700.
- Min tap 44.

## 4. Avatar / coin / money / progress / badge

### `.avatar → NestAvatar`
- Circle, Nunito w900, shrink 0; s32: 32/14 · s44: 44/18 · s64: 64/24 · s96: 96/38.
- Colours: default surface-2/ink; a-lilac lilac-tint/a-lilac; a-peach peach-tint/a-peach;
  a-sky sky-tint/a-sky; a-leaf leaf-tint/leaf-ink; a-coin coin-tint/coin-ink.
- Overlap `.assignees .avatar` margin-left −8, border 2×surface.

### `.coin-pill → NestCoinPill`
- Row gap 6, bg coin-tint fg coin-ink, Nunito 16 w800 lh 1, padding `8px 12px`, radius pill, nowrap.
- Icon 20×20. `.big` → 20px font, padding `10px 16px`.
- P02 small contextual: 14px, padding `7px 10px`, icon 18 (screen wins inside pager rows).

### `.money → NestMoney`
- tabular-nums (tnum), w700, nowrap. Sizes contextual: K09 `.k9-amt .money` 40/44.

### `.progress` / `.progress.kid → NestProgress`
- Base: height 8, radius pill, bg surface-2; fill leaf full-height radius pill.
- Kid: height 16, border 2×ink, bg surface; fill leaf + gloss `::after`
  (top 2 left/right 4, height 4, radius 999, white@55%).
- Widths are inline (`style="width:66%"`) — Flutter takes 0..1 fraction.

### `.badge-count → NestBadgeCount`
- min-width 22, height 22, padding `0 6px`, radius 999, bg leaf fg on-leaf, 12 w700.

## 5. Overlays

### `.scrim → NestScrim`
- absolute inset 0, z 20, bg scrim (light ink@45 / dark black@62).

### `.sheet → NestSheet` + grabber
- absolute left/right/bottom 0, max-height 92%, bg paper, radius `32 32 0 0`,
  padding `8px 20px calc(34+16)=50px bottom`, z 30, column, scrollable.
- Grabber `::before`: 40×5 radius 999 bg line, margin `4px auto 12px`.
- P09 `.sheet-top`: row space-between, padding `4px 0 8px`; title Nunito 18/24 w800.
- P13 `.pay` variant: max-height 88%, same grabber/padding (screen wins on max-height).

### `.modal → NestModal`
- absolute left/right 24 (width 342), top 50% translateY(−50%), bg surface,
  radius 32, padding `24px 20px 20px`, z 30, shadow sh-2, center text.

### `.toast → NestToast`
- absolute left/right 20, bottom `34+16=50`, bg ink fg paper, radius 16,
  padding `14px 16px`, 15 w600, z 40, center.

### `.empty-state → NestEmptyState`
- center, padding `24px 16px`, column gap 8; `.art` 160×160 (img 160).
- P08b `.empty-card`: bg surface radius 24 shadow sh-1 padding `28px 20px` gap 8;
  img 140; h2 Nunito 22/28 w800; p 15/22 ink-2 max-width 260.

## 6. Quest cards

### `.quest-card → NestQuestCard` (parent)
- Row center gap 12, bg surface radius 16 shadow sh-1 padding 12, min-width 0.
- `.quest-main{flex:1 min-width:0}`; `.quest-title` 16 w700 lh 22 ellipsis
  (base single-line; P08 overrides to balance/wrap — see conflicts);
  `.quest-meta` row gap 6, 13 ink-2 margin-top 2, wrap.
- `.quest-check`: 56×56 (min 56) circle, border 3×ink, bg surface;
  `.done` → bg leaf, border leaf, fg on-leaf.
- P08 `.status-chip`: height 26 padding `0 10px` radius 999 12 w700 nowrap;
  st-wait coin-tint/coin-ink, st-todo surface-2/ink-2, st-done leaf-tint/leaf-ink.

### `.quest-card.kid → NestKidQuestCard`
- min-height 72, padding 12, radius 24, border 3×ink, shadow sh-kid, gap 12.
- `.kid-icon` 48×48 radius 16 bg surface-2 shrink 0.
- Title Nunito 18/24 w800.
- K04 `.k4-step`: min-h 60, gap 12, padding `0 14px`; divider 2×line;
  `.k4-dot` 40 circle border 3 ink; `.on` bg leaf fg on-leaf; text Nunito 18/24 w800.

## 7. Pet / keypad / misc

### `.pet-stage → NestPetStage`
- Column center, padding `8px 0 0`, position relative.
- Glow `::before`: 230×230 circle at 50%/42%, bg pet-glow (none light / white@10% dark).
- Art img/svg 200×200. `.pet-shadow`: 140×18 ellipse bg ground-shadow margin-top −10.
- `.speech`: bg surface border 3×ink radius 18 padding `8px 14px` Nunito 16 w800 max-width 260
  wrap-anywhere; tail `::after` 9px triangle (border-top ink).
- Kid sizes: K03 pet 260×236 (pip 152, bottom 96); K06 230×206 (pip 134, bottom 81);
  P17 200×200; K05 pip 218 rotated −8° margin `14px 0 2px`.

### `.keypad → NestKeypad`
- Grid 3 cols, gap 10, padding `8px 24px 0`, justify-items center.
- Keys: 72×72 (min 72) circle, border 0, bg surface, Inter 26 w600, shadow sh-1, fg ink.
- Kid: Nunito w900, border 3×ink, shadow sh-kid.
- Blank cell 72×72. Delete key same size (P17 centers icon).
- `.pin-dots`: row gap 12 center padding `8px 0`; dot 18 circle border 3 ink bg surface;
  `.filled` bg ink.
- P17 `.digit`: 56×64 radius 16 border 2 line bg surface-2 Nunito 28 w900;
  `.filled` bg surface border ink; `.empty::after` 3×24 leaf caret.
- P17 `.gate .keypad` margin-top 16; digits row gap 12 margin-top 16; `.cancel` min-h 56 margin-top 12.

### `.fab → NestFab`
- absolute right 20 bottom `tab-h(84)+16=100`, height 52 min-width 52, padding `0 20px`,
  radius pill, bg leaf fg on-leaf, Inter 16 w700, gap 8, shadow sh-2, z 10.
- Screens with fab add scroll padding-bottom `52+32=84`.

### `.btn-apple/.btn-google` — see §2. P03 rhythm: apple margin-top 24, google 12, or-row 16, fields 16.

### `.lock-btn` / `.lock-btn.lg → NestLockButton`
- Base: 44×44 (min 44) radius 12 border 1×line bg surface fg ink-2 center.
- `.lg` (all kid screens + K10/K11/K08/K02): 56×56 radius 18 (screen extension, wins).
- P17 `.lock-tile`: 52×52 radius 16 bg lilac-tint fg lilac.
- P13 `.check`: 48×48 radius 14 border 2 leaf bg leaf fg surface; `.off` bg surface border line fg transparent.
- P08 `.newquest`: 44 circle bg leaf fg surface shadow sh-1; `.avatar-btn` 44 circle.

### Pager dots → NestPagerDots (P02)
- Row center gap 6 height 18; `.dot` 8 circle bg line; `.on` width 22 radius pill bg leaf.
- Pager cards (P02): wrapper 390×400; card 310×400 absolute (c1 left 20, c2 342, c3 664),
  bg surface radius 24 shadow sh-1 padding 16 column. Rhythm: dots margin-top 22, title 30, body 12.

## 8. Global layout rules

- Side padding: **20** everywhere (`--pad-side`, `.scroll`, `.bottom-cta`, `.sheet`).
- Base rhythm: siblings in `.scroll` separated by **16** (`> * + *`).
- Section label (P16 `.sect`): 13 w700 uppercase ls +6% ink-2; margin-top **24** above, **8** below
  (`.scroll > .sect{margin-top:24} .sect + *{margin-top:8}`).
- P08 groups: `.qgroup` 13 w700 uppercase ls 6% margin `16px 0 -8px`; `.sec-t` Nunito 18/24 w800
  with 44-high leaf link 14 w600.
- Header heights: P08 `.greet` (no nav-bar) — h1 Nunito 22/28 w900 + date 15/22 ink-2 margin-top 2,
  padding-top 8; K03 `.k3-top` padding `4px 20px 10px`, name Nunito 22/26 w900 + sub 15/20.
- Card-to-card vertical: 16 default (`.scroll` rule); K03 `.k3-quests` gap 12; P06 `.opt-list` gap 8;
  P07 `.benefits` gap 10; P02 `.pg-rows` gap 12 / `.pg-rows` margin-top 14.
- 2-up grid (P05 `.kid-grid`, P08 `.kids`): columns **170 + 170**, gap **10** → 170×2+10 = 350 = 390−40 ✓.
  P08 card: width 170, radius 24, shadow sh-1, padding 14; pip img 72 margin `6px auto 2px`;
  name Nunito 17/22 w800; sub 13/18. P05 card: padding `12px 10px 10px`, name 18/24, age 13/18 margin-top 4.
- 3-up grids: P15 `.stats` 3×1fr gap 10 (each ≈106.7); K11 `.k11-grid` 3×1fr gap 12 (each ≈108.7);
  K11 cell padding `10px 4px` radius 24 border 3 ink sh-kid, medal 60, name 15/19 min-h 38, sub 14/18.
- 7-up day row (P06): 7×1fr gap 6 → each ≈45.7 wide; chip 13px centered (tight — see risks).
- P09 icon grid: 6×44 gap 8 space-between; `.ic` 44 radius 14 border 1.5 line; `.sel` border leaf bg leaf-tint fg leaf-ink.
- P09 person pill: height 48 padding `4px 14px 4px 4px` radius 999 border 1.5 line; `.sel` leaf border/tint.
- P06 opt-card: min-h 60 padding `8px 13px` gap 12 radius 16 border 2 line sh-1; `.on` border leaf bg leaf-tint;
  radio 22 circle border 2 ink-3; `.on` border leaf bg leaf + inset `0 0 0 4px leaf-tint`.
- Form rhythm (P03/P05): head p margin-top 8; fields margin-top 16 (P05 form-card fields 10, lbl 8, chips 4, swatches 4, note 6).
- P01 scene: 350×388 block; circle 320 at left 15 top 44; nest 264 at 43/104; pip 168 at 91/120;
  coins 40/34/36 on rim, min frame clearance 21.

## 9. Conflicts (screen value wins in Flutter)

1. `.segmented button` height 40 vs min-height 44 (components.css self-conflict) → use **44**.
2. `.quest-title` base nowrap ellipsis vs P08 `.quest-title{text-wrap:balance}` (wraps) → P08 cards wrap (maxLines 2, balance≈soft-wrap).
3. `.list-row` base pad-v 10 vs P04 7 → P04 uses 7.
4. `.list-title/.list-sub` base nowrap vs P04 normal wrap → P04 wraps.
5. `.chip` base h32 vs P10 `.chipscroll .chip` min-h 44 → filter chips are 44.
6. `.chip` font 14 vs P06 `.chip.day` 13 + padding 0 → day cells 13.
7. `.toggle` h31 vs P04 `.opt-tap .toggle` h44 (content-box trick, visual track unchanged) → keep 51×31 track, 44 tap box.
8. `.bottom-cta` pad-v 16 vs P06 14 → P06 uses 14.
9. `.btn` base min-h 52/pad 24/font 16 vs P08 banner (auto/44/18/15), P11 appr row (48/12/15), P12 rowbtns 48/15 → per-context values above.
10. `.coin-pill` base 16/20px icon vs P02 rows 14/18px icon → pager rows use small.
11. `.icon-tile` base 40/r16 vs P02 rows 36/r12 → pager rows use small.
12. `.scroll` bottom 32 vs P14 66, K06/K08 58 → per-screen bottoms.
13. `.scroll > * + *` 16 vs explicit larger (P16 sect 24, P02 dots 22/title 30, P03 apple 24) → explicit wins.
14. `color-mix()` in meadow `.hill-front` (kid screens) — no Flutter equivalent; bake: light #CCE9C2-ish
    (meadow 80% + surface), dark #243B41-ish; verify against PNG.
15. No `:disabled`, no text-button pressed opacity, no focus ring for buttons/tabs in CSS → unspecified (rules in §2/§10).

## 10. Common failure risks (Flutter rules)

1. Chip text overflow at large text scale → `Flexible` + `maxLines:1, overflow:ellipsis`; filter rows use horizontal `SingleChildScrollView`; clamp app `textScaler` to **1.0–1.3**.
2. 2-up 170px cards at 320px-wide devices (350 content < 320−40=280) → compute columns from width:
   `colW = (W − 40 − gap) / 2`, min 0; use `GridView`/`Wrap`, never fixed 170 except at W=390.
3. 7-up day row (≈45.7/cell at 390, less at 320) → cells `Expanded`, font 13, short labels (Mon..Sun single-line, scaleDown), min-height 44.
4. Long UK names (quest titles, child names) → title `Flexible`, maxLines 1 + ellipsis (parent) / 2 + wrap (P08 balance cards); `overflow-wrap:anywhere` ≈ `softWrap` + break long words; avatars/coin-pills outside Flexible with fixed size.
5. `.scroll > * + *` margin collapse vs Flutter separators → use `SizedBox(16)` separators, but replace with explicit 24/22/30 where screens specify.
6. 44px tap targets (chips h32, tabs, icon buttons) → wrap in `ConstrainedBox(minHeight:44, minWidth:44)` / `InkWell` with padding; keep visual size.
7. Kid 3px borders + sh-kid (6px solid offset) → total footprint +9px bottom; add `margin-bottom:6` equivalent (padding) so shadows aren't clipped in scrolls; dark sh-kid is black@45.
8. Hero colours: never `ink` for hero fill (dark hero #2A2640 vs ink #F3F0FA) — use dedicated hero tokens.
9. Apple/Google buttons flip in dark (apple white bg/black text; google #131314/#E3E3E3/border #8E918F) — test both themes.
10. Toggle: keep 51×31 track; 44 tap area via parent detector (P04 pattern), knob 27 translate 20.
11. `white-space:nowrap` elements (coin-pill, money, status-chip, kchip) → `softWrap:false` + ellipsis parent; coin-pill min content can force overflow — put in Flexible/Scroll.
12. PNG ÷ 3: compare Flutter screenshots at 390×844 logical against PNG/3, not raw 1170×2532.

## 11. Widget map (CSS → Flutter)

status-bar→NestStatusBar · home-indicator→NestHomeIndicator · nav-bar→NestNavBar ·
scroll→(Scaffold body padding) · tab-bar/tab→NestTabBar · fab→NestFab ·
btn/btn-primary/btn-secondary/btn-ghost/btn-danger-ghost→NestButton(.primary/.secondary/.ghost/.dangerGhost) ·
btn-apple→NestAppleButton · btn-google→NestGoogleButton · btn-kid→NestKidButton ·
btn-row→(Row gap 12, Expanded) · bottom-cta→NestBottomCta ·
card/inset/hero→NestCard(.inset/.hero) · list/list-row→NestList · chip→NestChip ·
segmented→NestSegmented · toggle→NestToggle · field→NestField · stepper→NestStepper ·
avatar→NestAvatar · coin-pill→NestCoinPill · money→NestMoney · progress/kid→NestProgress ·
badge-count→NestBadgeCount · scrim→NestScrim · sheet→NestSheet · modal→NestModal ·
toast→NestToast · empty-state→NestEmptyState · quest-card→NestQuestCard ·
quest-card.kid→NestKidQuestCard · pet-stage→NestPetStage · keypad→NestKeypad ·
lock-btn(.lg)→NestLockButton(.lg) · pager dots→NestPagerDots.
