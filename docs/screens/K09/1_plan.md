# K09 · My jar — build plan (Stage 1)

Route `/my-jar` (kid mode, `KidJarRoutePaths.jar`), feature `kid_jar`.
Only kid screen that shows £. No bottom bar, no dock, no CTA — scroll +
home indicator only. No Pip on this screen (jar illustration instead).

Copy below is character-exact from `design/html-source/screens/K09-jar.html`
(curly ’, en/em dashes, £, p). Static copy never changes; amounts, goal
figures, weekday and list rows are DB-driven (seed-anchored, tests pinned
Sat 3 Oct 2026 09:41 London).

Seed truth (demo, Maya): owed = 300 + 12 + 40 + 40 + 28 = **420p = £4.20**;
goal “Lego Friends set” 1550/2499 = 62.0% → **“62% there!”**, to-go 949 =
**£9.49**; payoutDay default 6 → **Saturday**. Design PNG numbers agree, so
no conflict. Design list shows 3 example rows; the app renders ALL money-in
rows newest-first (DB wins; UI check excludes DB-driven content).

## (a) Widget tree top→bottom (logical px, 390×844)

```
KidScope (shared kid sky gradient + meadow hills bottom 0, 390×136;
  NEVER paint local hills)
└─ Scaffold (transparent bg, extendBodyBehindAppBar not needed)
   └─ SafeArea(top: false, bottom: true)  // OS draws status bar;
      // NestStatusBar reserves height only (showMockGlyphs=false in app)
      └─ Column
         ├─ NestStatusBar()                                  // h 47, glyphs off
         ├─ TopRow: Padding(0 20 4) Row
         │   ├─ BackBtn 56×56 transparent, chevron NestIcons.back 26px,
         │   │   ink; radius 18; semantics “Back”, tap → pop (see c)
         │   └─ Spacer + NestLockButton(large: true → 56×56, r18,
         │       surface bg, 1px line border, lock glyph ink-2,
         │       semanticLabel ‘Grown-ups’) → /parental-gate
         ├─ Expanded SingleChildScrollView
         │   padding: L/R 20, bottom 32; separators 16 (scroll base rule)
         │   ├─ Title “My jar”: NestBalancedText? NO — single line.
         │   │   Text(kidTitle ink, center). y≈140–174.
         │   │   (.kid-title uses text-wrap:balance in some screens but here
         │   │    it is 2 words on one line; plain Text, maxLines 1.)
         │   ├─ gap 10
         │   ├─ JarArt 186×220 centered (x102–288, y≈192–412):
         │   │   feature-private CustomPaint/SVG transcription of
         │   │   K09-jar.html:48–67 — lilac lid (rect 50,4 100×22 r10,
         │   │   ink 4px outline), glass body (rect 28,24 144×192 r30,
         │   │   #F2FAFF fill light / surface dark, ink 4px outline),
         │   │   coin fill clipped to interior rect (36,40 128×168 r24):
         │   │   fill height = goalFillFraction × 104 anchored bottom
         │   │   (design 62%: rect y104 h104 = full fill zone; scale h by
         │   │   fraction, y = 208 − h). Coins: 8 × #F4B400 circles r12–16
         │   │   with ink 3px outline at design centres (66,128 / 102,118 /
         │   │   134,132 / 82,154 / 120,158 / 100,182 / 58,178 / 144,180);
         │   │   hide coins whose centre is above the fill top (clip).
         │   │   White gloss streak left, lilac “+” sparkle top-right,
         │   │   ground ellipse (groundShadow). Semantics image label:
         │   │   “A glass money jar about {pct}% full of coins”.
         │   ├─ gap 6: Amount NestMoney? NO — kid hero:
         │   │   Text(kidHero 40/44 w900 ink, center, “£4.20” from owedPence;
         │   │   tabular; FittedBox scaleDown for textScale 1.3). y≈418–462.
         │   │   Semantics label “£4.20 coming on Saturday” on the pair.
         │   ├─ gap 2: “coming on Saturday” kidBody 18/26 w700 ink-2 center
         │   │   (“coming on {Weekday}” from summary.nextPayoutDay).
         │   ├─ gap 16: GoalCard (x20–370, coinTint bg, 3px ink border,
         │   │   radius r-l 24, sh-kid shadow, padding 14v/16h):
         │   │   ├─ Row gap10: coin-illustration 34×34 (SvgPicture coin.svg
         │   │   │   as-is, own colours) + “Lego Friends set” 20/26 w900
         │   │   │   Nunito ink, Expanded, maxLines 2 ellipsis (DB title).
         │   │   ├─ gap 12: amounts Row spaceBetween: “£15.50” left /
         │   │   │   “£9.49 to go” right, 17px Nunito w900 ink
         │   │   │   (savedPence / (target−saved) + “ to go”).
         │   │   ├─ gap 6: NestProgress(fraction: saved/target, kid: true,
         │   │   │   semanticLabel “62% of the Lego Friends set saved”).
         │   │   └─ gap 8: caption Row spaceBetween: “of £24.99” /
         │   │       “62% there!” — 15/20 w700 Nunito ink-2
         │   │       (kcap; 15px is per-design, below the 17px kid-body
         │   │       minimum — recorded design exemption, same class as
         │   │       K03’s 15px kidCaption).
         │   │   Hidden entirely when goalTargetPence == 0 (no goal); jar
         │   │   fill then 0.
         │   ├─ gap 16: “What went in” 20/26 w900 Nunito ink, left.
         │   ├─ gap 16: HistoryCard (surface bg, 3px ink border, r-l 24,
         │   │   sh-kid, overflow hidden via ClipRRect; rows newest-first):
         │   │   Row ×N: min-height 60, padding 8v/14h, gap 12;
         │   │   disc 40 circle (tint cycles leafTint/lilacTint/peachTint,
         │   │   glyph 22 ink-tone — see icons); middle Expanded Column:
         │   │   title 17/22 w800 Nunito ink maxLines1 ellipsis +
         │   │   sub 14/18 w700 Nunito ink-2 maxLines1 ellipsis;
         │   │   value 18/22 w900 leafInk nowrap (“+£3.80” / “+12p”).
         │   │   Divider 2px line, inset left 66 (40 disc + 12 gap + 14 pad),
         │   │   between rows only. Rows are display-only (no tap).
         │   └─ gap 16: caption center 15/20 w700 ink-2:
         │       “Mum keeps the real money. This jar just shows how well
         │        you have done.”
         └─ (no bottom bar → meadow runs to the physical edge; owner rule
            satisfied trivially. No NestHomeIndicator widget — OS draws it;
            gallery mock only.)
```

Shadows: sh-kid = 6px solid offset ink@12% (dark: black@45) — add
bottom margin/padding so shadows are not clipped in the scroll.
Borders 3px ink on both cards + jar glass (dark: ink = #F3F0FA token).

## Icons (kid audience)

Row glyphs mirror the design exactly: pocket-money rows → `NestIcons.money`
(pound-coin circle); quest-bonus rows → `questIconFor(questIconKey,
audience: kid)` where stored (bins → questBins); gift rows → `NestIcons.gift`.
The HTML’s three example rows use money-disc / bins-flask-ish / gift-box;
map by entry type: weekly_base & payout → money; quest_bonus → quest icon
for the quest’s icon key when known else bins glyph; gift → gift. Disc tints:
leafTint/leafInk, lilacTint/ink, peachTint/ink cycling by index (design shows
leaf, lilac, peach). Size 22 in 40 disc. Never hard-code colours.

## (b) BLoC + repository (Drift, existing repo)

State `KidJarState` extends (keep status/items/errorMessage):
`childId, owedPence, goalTitle, goalSavedPence, goalTargetPence,
nextPayoutDay`. No new events — `KidJarLoadRequested` only (read-only
screen; Retry re-adds it; emit.forEach cancels the prior subscription).

Repository addition (allowed: feature domain/data):
- new entity `JarSnapshot {childId, items, summary: JarSummary}` in
  `domain/entities/jar_snapshot.dart` (Equatable).
- `Stream<JarSnapshot> watchJar()` on `KidJarRepository` + impl:
  `watchAppState → activeChildId ?? 'maya'` then `asyncExpand` to
  `combineLatest2(_entriesFor(child), _summaryFor(child))`
  (reuse existing `_entries`/`watchSummary` bodies refactored to take
  childId; `stream_combine.dart` combinators already imported).
- Row filter for the K09 list (NOT the P12 ledger): keep types
  `{weekly_base, quest_bonus, gift}` only (money IN); drop payout/spend/
  savings_move. Newest-first (watchLedger is date-desc already).
- Row mapping: weekly_base → title “Pocket money”, sub relative-day
  (“This {W}” if London date ≥ current London week start else “Last {W}”
  via `londonWeekStartUtc`/`toFamilyZone`); quest_bonus → title = note,
  sub “Quest bonus”; gift → title = note before “ (”, sub “From {name}”
  parsed from “(added by {name})”, fallback “Gift”.
- Summary: unchanged `watchSummary` math (owed = base+quests since last
  payout break; goal = child’s first goal; weekday from setting.payoutDay
  default 6). Amount format helper (feature-private):
  `formatJarAmount(pence)`: positive → “+£3.80” if ≥100 else “+12p”;
  (negatives never reach the list; helper still handles “−£2.00” with U+2212
  for safety).

Bloc: `on<KidJarLoadRequested>` → `emit(loading)` then
`emit.forEach(watchJar(), onData: loaded(items, snapshot…),
onError: failure)`. App code uses `clock.now()`/`appNowUtc()` only —
never `DateTime.now()`.

## (c) Interactions → navigation (route constants)

- Back (top-left 56×56): `context.pop()` → kid home `/kid-home`
  (`KidHomeRoutePaths.home`; import path constants only — never edit
  another feature). Semantics tap required.
- Lock (top-right `NestLockButton` large, label ‘Grown-ups’):
  `context.push(ParentalGateRoutePaths.gate)` = `/parental-gate`.
- History rows, jar, goal card, captions: no navigation, no tap.
- No buttons/CTA/dock/sheet on this screen.

## (d) Empty / loading / error

- Loading: KidScope + centered `CircularProgressIndicator` (leaf) under
  the top row; keeps sky/meadow so no flash.
- Error: kid-friendly “Oh no! Something went wrong.” kidBody + white
  `NestKidButton`-style retry? K09 design has no buttons — use text
  button “Try again” (leaf, 44px tap) re-adding KidJarLoadRequested.
- Empty ledger: HistoryCard shows one row “Nothing here yet” /
  “Finish a quest to fill your jar” with money glyph, no value.
- No goal (target 0): goal card hidden; jar fill 0; amount + “coming on…”
  still show; progress semantics omitted.
- Zero owed: amount “£0.00”, sub unchanged.

## (e) Accessibility

- Tap targets: back 56×56, lock 56×56 (kid ≥56 ✓). Rows display-only —
  plain text, must NOT claim tap (no Semantics button, no hasAction tap).
- Every Semantics(excludeSemantics: true) wrapper passes its onTap
  (back/lock) so VoiceOver/TalkBack can activate; tests assert
  `hasAction(SemanticsAction.tap)` + `performAction` navigates.
- Headers: title is `header: true`; amount+when merged into one label;
  progress exposes value “62 percent” + design label.
- Text scale clamp 1.0–1.3 (app-wide); hero amount in FittedBox(scaleDown,
  single line); row title/sub maxLines 1 ellipsis; value softWrap false in
  Flexible? value is trailing fixed — wrap Row middle in Expanded so value
  never pushes out at 1.3.
- Width 320: content 280; goal amounts row + captions use Flexible +
  ellipsis; jar 186 fixed centered (fits); cards full-bleed to gutters
  (x20 w280), aligned edges — owner alignment rule.
- Contrast: leafInk-on-surface and ink-2 captions meet ≥4.5:1 both themes
  via tokens (never hard-code).
- No red anywhere (kid rule); no timers/streaks/loss framing.

## (f) Test plan (`app/test/features/kid_jar/`, `--timeout 120s`, pinned
Sat 3 Oct 2026 via `test/flutter_test_config.dart`; end pumped tests with
`disposeApp(tester)`; no `google_fonts`; no `DateTime.now()`)

1. `kid_jar_bloc_test.dart`: load → loading→loaded; Maya snapshot:
   owedPence 420, goal “Lego Friends set” 1550/2499, nextPayoutDay
   “Saturday”; items exclude payout/spend/savings_move, newest-first,
   first item weekly_base 300.
2. `kid_jar_repository_test.dart` (demo seed): watchJar first emission
   matches the above; Leo snapshot owed 210 (150+35+25), no goal →
   goalTargetPence 0; empty-seed → items empty, owed 0.
3. `my_jar_view_test.dart` (demo, CHILD=maya): finds “My jar”, “£4.20”,
   “coming on Saturday”, “Lego Friends set”, “£15.50”, “£9.49 to go”,
   “of £24.99”, “62% there!”, “What went in”, “Pocket money”,
   “Put the bins out”, “Birthday money”, “+12p”, “+£10.00”, caption
   “Mum keeps the real money…”; back tap pops; lock tap pushes
   `/parental-gate`; every control has tap action and performAction works;
   dark mode pumps.
4. `my_jar_geometry_test.dart`: top-row y≈63–119, title y≈140–174, jar
   186×220 centered, goal card x20 w350, progress fraction 0.62±0.01,
   divider inset 66±2, gutters 20 both sides, no overflow at width 320 /
   textScale 1.3.
5. `my_jar_copy_parity_test.dart`: static copy char-by-char vs HTML
   (curly/£/p/…); jar semantics label; progress label.

## (g) SHARED_REQUEST

None. All work is inside `app/lib/features/kid_jar/**`,
`app/test/features/kid_jar/**`, `docs/screens/K09/**`. Route paths
(`/kid-home`, `/parental-gate`) are read-only constants from other
features. Tokens/components used (KidScope, NestLockButton, NestProgress,
NestIcon/questIconFor, spacing/typography/colors) already exist on main.

VERDICT: PASS
