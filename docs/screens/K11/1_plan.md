# K11 · My badges — build plan (stage 1)

Route `/badges` (feature `badges`, kid mode). Sources: `design/html-source/screens/K11-badges.html`,
`design/screens/light|dark/K11-badges.png` (1170×2532 = 390×844 @3x, all numbers below logical px),
DESIGN_SPEC §5 K11, SPACING_SPEC §§7–8/10–11. No `ORCHESTRATOR_NOTES.md` exists. No Pip on this
screen (PIP rule N/A). No coins/£ anywhere (jar-only rule holds).

## 0. Measured geometry (light PNG, verified against the HTML — builder treats HTML as exact)

- Status reserve `0…47` → `NestStatusBar` (OS draws glyphs; ignore in UI checks).
- `.krow-top` `47…107`: `Padding(20, 0, 20, 4)`; back button left (transparent 56 box,
  chevron glyph y 66…84, centre 75 = box centre ✓); lock box WHITE y 47…103 (`NestLockButton`
  large → 56×56, r18, right edge x370 = 390−20 ✓).
- Scroll starts `107`, side padding 20, bottom padding 32 (K11 has no `.scroll` override → base 32).
- Title `My badges`: `kidTitle` (Nunito 900, 28/34, ink), line box `107…141` (glyphs 113…138 ✓).
  `.kid-title` is a balanced heading → `NestBalancedText` (single line here, rule still applies).
- Subtitle `.kcap` (Nunito 700, 15/20, ink-2): line box `157…177` (16 gap after title = `.scroll`
  sibling rule ✓). Copy: `Four shiny ones already. Pip is very impressed.`
- Grid `.k11-grid` top border `193…195` (16 gap ✓): 3 columns, gap 12, gutters 20 →
  col w = (350−24)/3 = **108.67** (measured outer 106…108 incl. 3 px borders ✓). NEVER fixed 108.67
  in code: `Expanded` × 3 with 12 gaps (SPACING_SPEC §10.2, `(W−40−24)/3`; 85.3 at 320 wide).
- Rows: R1 `193…341` (h≈148), R2 `353…503`, R3 `515…665`. Row gap 12, grid→week gap 16
  (665→683 ✓).
- Badge cell `.k11-b`: surface, **3 px ink border**, r-l 24, `sh-kid` (6 px solid offset → add
  bottom clearance so shadows are not clipped), padding `10px 4px`, column, gap 4, centred.
  Medal 60×60. Name Nunito 800 15/19 centred, min-h 38 (two-line names: `Bed maker ×7`,
  `Plant waterer`). Sub Nunito 800 14/18: earned = leaf-ink `Got it!`, todo = ink-2 `Keep going!`.
  `.todo`: **dashed** 3 px ink-2 border, NO shadow. Cell content height: 10+60+4+38+4+18+10 = 144
  + 6 border = 150 ≈ measured 148 ✓.
- Week card `.k11-week` `683…829` (h≈146): surface, 3 px ink, r-l 24, sh-kid, padding `14px 12px`.
  7 days, gap 4: dot 38 circle, 3 px ink border; filled = leaf bg + on-leaf check 22 px;
  empty = surface + ink-2 ring glyph; letter below (Nunito 800 14/18, gap 4): single letters
  `M T W T F S S`. Why-text centred, margin-top 12, `.kcap` style, 2 lines:
  `4 happy days this week — Pip hasn’t stopped singing.` (em dash U+2014, ’ U+2019).
- Content ends 829 + 32 = 861 > 844 → slight (17 px) scroll. No bottom bar → meadow runs to the
  physical edge (`KidScope` defaults: height 136, bottom 0). BOTTOM EDGE rule holds trivially.
- Dark: same geometry; surfaces/cards/borders flip per tokens; dots and medals keep own colours.

## (a) Widget tree (top → bottom, tokens only — no hard-coded colours/sizes)

```
KidScope                                    // shared sky + hills + dark stars; never local hills
└─ Scaffold(backgroundColor: transparent)
   └─ Column
      ├─ NestStatusBar()                    // height 47 reserve
      ├─ Padding(20,0,20,6→4*)              // .krow-top: L/R padSide, bottom 4
      │  └─ Row: NestIconButton(back 26px, transparent bg+border, ink) + Spacer + NestLockButton
      └─ Expanded
         └─ ListView(padding: 20,0,20,32)   // 16 separators (SizedBox s4) between sections
            ├─ NestBalancedText('My badges', kidTitle ink, maxLines 2)
            ├─ Text(subtitleFor(earnedCount), 15/20 w700 ink-2, maxLines 2)   // §c copy table
            ├─ _BadgeGrid (rows of 3: IntrinsicHeight + Row stretch, 12 gaps;  // K08 precedent
            │   odd tail → Expanded(SizedBox.shrink), never Expanded(Spacer))
            │   └─ _BadgeCell × N (static card — NOT a button, see §c)
            │       ├─ SvgPicture.asset(artFor(badge.id), 60×60, ExcludeSemantics)
            │       ├─ Text(name, 15/19 w800 ink centre, min-h 38, maxLines 2)
            │       └─ Text('Got it!' leaf-ink | 'Keep going!' ink-2, 14/18 w800)
            └─ _HappyWeekCard(happyDays)    // surface, 3px ink, r24, sh-kid, pad 14/12
                ├─ LayoutBuilder → 7 × (dot + letter), gap 4; dot = min(38, (w−24)/7) // §e
                └─ Text(whyFor(happyDays), kcap centre, maxLines 3)
```

`*` `.krow-top` bottom padding is 4 (HTML line 14), not 6. Back chevron 26 px / stroke 2.5 has no
token → file-local `const _backIconSize = 26` (K08 precedent). Lock uses `NestLockButton` defaults
(large = 56, r18, 1 px line border). Shim: `sh-kid` bottom offset needs `+6` clearance; week card
needs the same.

`artFor(id)` (view-local map, design ids first, seed legacy aliases second, ribbon fallback):
`first-quest→badgeFirstQuest`, `bed-maker-7→badgeBedMaker`, `kind-helper→badgeKindHelper`,
`bookworm→badgeBookworm`, `bins-out→badgeBinsOut`, `biscuit-sitter→badgeBiscuitSitter`,
`tidy-hero→badgeTidyHero`, `early-bird→badgeEarlyBird`, `plant-waterer→badgePlantWaterer`,
unknown → `NestIcon(NestIcons.ribbon)` (never a wrong badge's art). Art is per badge id; the earned
state changes ONLY border (solid+shadow vs dashed) + sub copy. (If the earned set ever changes,
newly-earned badges keep their own art — known limitation, no action.)

## (b) BLoC + repository (local Drift, existing repo — K08 `KidShopBloc` guard pattern literally)

State `BadgesState`: `status` (initial/loading/loaded/failure), `childId` ('' until first emission),
`items: List<Badge>`, `happyDays: int` (0…7). `copyWithLoaded(childId, items, happyDays)` clears
stale errors; requests ride through untouched (no request actions on this screen).

Events: `BadgesLoadRequested` (route already adds it), internal `BadgesDataReceived(BadgesData)`,
`BadgesStreamFailed(Object)`. Guarded single subscription (`_sub`; ignore reloads while live,
release on error/close so `Try again` works). Never re-add load events to refresh.

Repository (feature-local additions — RULES §1 allows domain/data edits):
- New entity `BadgesData(childId, items, happyDays)`.
- New `BadgesRepository.watchActiveBadges(): Stream<BadgesData>` impl:
  `watchAppState()` → `activeChildId ?? 'maya'` → `asyncExpand` into
  `combineLatest2(watchShelf(child), watchHappyDays(child), …)` (`stream_combine.dart`, core Dart
  `asyncExpand` only — no new deps). `watchItems()` stays as-is (back-compat).
- `BadgesRepositoryImpl.watchShelf` detail strings become design copy: earned → `Got it!`,
  todo → `Keep going!` (today it says `Earned`; the view must not remap — single source here).
- Ordering: DB insertion order, no sorting (matches design for the 4 earned; see §g for the rest).
- No clock use at all (`happyDays` is a stored count; no period math on this screen). No `newId`.

## (c) Interactions + navigation (route constants only)

| Element | Action | Destination |
|---|---|---|
| Back (56, `Back`) | `canPop ? pop : go(home)` | `KidHomeRoutePaths.home` (`/kid-home`) |
| Lock (56, `Grown-ups`) | `push` with double-tap busy guard (K08 `_GateLockButton` precedent) | `ParentalGateRoutePaths.gate` (`/parental-gate`) |
| Badge cells | NONE — static cards. No detail route exists in the nav map; do NOT add onTap, toast, modal or sheet (invented UI). Semantics: merged static label `<name>, Got it!` / `<name>, Keep going!`, inner SVG excluded. | — |

Copy (character-exact from HTML; `×` = U+00D7, `—` = U+2014, `’` = U+2019):
- Title `My badges`. Earned subs `Got it!`, todo subs `Keep going!` (with `!`).
- Names: `First quest`, `Bed maker ×7`, `Kind helper`, `Bookworm`, `Bins out`, `Biscuit sitter`,
  `Tidy hero`, `Early bird`, `Plant waterer`. Day letters `M T W T F S S` (single letters).
- DB-driven lines (design value when DB matches; Maya demo = 4 earned / 4 happy days):
  subtitle = `Four shiny ones already. Pip is very impressed.`; else `<Word> shiny one(s) already…`
  (`One…Nine`, singular `one` for 1); zero → `No shiny ones yet. Finish a quest to earn your first!`
  (invented kid voice — flagged). Why = `<n> happy day(s) this week — Pip hasn’t stopped singing.`
  (singular for 1); zero → `Let’s make today a happy day!` (invented — flagged).
- Dots: first-N-filled (N = happyDays), no date logic — matches design (M T W T for Maya).

## (d) Empty / loading / error (chrome — status/top-row — stays mounted in every state)

- initial/loading: centred spinner (leaf) with `Semantics(label: 'Loading badges')`.
- failure: `NestEmptyState` (ribbon art 96, ink3) + title `Something went wrong` + `NestKidButton`
  white `Try again` → re-add `BadgesLoadRequested` (guard released the sub on error).
- loaded + `items.isEmpty`: `NestEmptyState` + `No badges yet` / `Finish a quest and your first badge
  will shine here.` (invented — flagged); week card hidden when there are no badges.
  (Demo never hits this; wiped-DB only.)

## (e) Accessibility

- Back + lock expose `SemanticsAction.tap` via their design-system buttons (label `Back` /
  `Grown-ups`); tests `performAction(tap)` must navigate (back → home-or-pop, lock → gate push).
  Badge cells are static → no tap action required; each exposes one merged label, no nested
  semantics (SVG `ExcludeSemantics`, texts inside the merged node).
- Tap targets: 56 back/lock (kid ≥ 56 ✓); nothing else interactive.
- Text scale: app clamps to 1.0–1.3; names allow 2 lines, min-h 38 grows via row stretch (§a).
- Width 320: grid cols 85.3 (medal 60 + 8 padding fits ✓); week dots MUST shrink via LayoutBuilder
  `min(38, (w−24)/7)` → 33 at 320 (fixed 38 overflows: 290 > 256 avail). Day letters 14 px, maxLines 1.
- Contrast: leaf-ink `Got it!` on surface, ink-2 subs — token pairs, both themes.

## (f) Test plan (`app/test/features/badges/`, `flutter test --timeout 120s …`, `disposeApp` after every pump, no `DateTime.now`, no `google_fonts`, no simulator)

1. `badges_repository_test.dart` (seeded in-memory DB): Maya shelf = 8 rows, 4 earned
   (`first-quest, bed-maker-7, kind-helper, bookworm`, detail `Got it!`, rest `Keep going!`);
   Leo = 1 earned; `watchHappyDays` maya 4 / leo 3; `watchActiveBadges` follows `app_state`
   child switch.
2. `badges_bloc_test.dart`: load → loaded(4 earned, happyDays 4); stream error → failure;
   retry after failure reloads (guard release); no event stacking on double load.
3. `badges_view_test.dart`: char-by-char copy (×/—/’), 9-or-DB-count cells in DB order, week dots
   4-on/3-off + letters, back navigates (pop or `/kid-home`), lock pushes `/parental-gate`,
   `hasAction(tap)` + `performAction` drives real navigation, empty/loading/failure surfaces,
   light + dark pump, text-scale 1.3 + width 320 no-overflow.
4. `badges_widget_geometry_test.dart`: col w 108.67 @390, R1 top 193 / week top 683 (±2 px rule
   inputs), dot 38 @390 → 33 @320, paddings 20/12/14/10/4, medal 60, real bundled Nunito metrics.
5. `badges_a11y_test.dart`: merged cell labels, SVG exclusion, spinner label, header semantics.

## (g) SHARED_REQUEST

One file: `docs/screens/K11/SHARED_REQUEST.md` — seed `_badgesDemo` must carry the 9 design badges
(ids/titles/icons/descriptions: `bins-out/Bins out`, `biscuit-sitter/Biscuit sitter`,
`tidy-hero/Tidy hero`, `early-bird/Early bird`, `plant-waterer/Plant waterer`; seed today has 8 with
`tidy-champion/super-saver/pet-friend` instead) so titles, count and order match the design.
**Blocks: no** — the grid renders whatever the DB returns in DB order behind a `TODO(K11)` for the
exact nine; the screen lands correctly for Maya's 4 earned either way. No route/DI/design-system
changes needed. Nothing else shared is touched.

VERDICT: PASS
