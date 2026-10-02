# P02 Value tour — build plan (Stage 1)

Route `/value-tour` (feature `onboarding`, parent mode). Sources: `design/html-source/screens/P02-value-tour.html`,
`design/screens/light|dark/P02-value-tour.png` (÷3 = logical px), DESIGN_SPEC §5 P02, SPACING_SPEC §§1–2,5,7,10–11.
No `docs/screens/P02/ORCHESTRATOR_NOTES.md` exists — only the stage-prompt orchestrator rules apply
(Pip = `PipAvatar` mochi/sunny at the design's stage; status bar reserves height only).

Static marketing screen (same pattern as P01 `welcome_view.dart`): three tour cards in a clipped horizontal
pager + dots + per-page title/body + fixed bottom CTA. No new BLoC code, no new repo methods.

## (a) Widget tree, top → bottom (all sizes logical px @390×844, tokens only)

```
Scaffold (bg paper via theme)
└── Column
    ├── NestStatusBar()                                    // reserves 47 (NestDevice.statusH); OS draws glyphs
    ├── _TourNav()  [feature-private, see (g)]             // min-height 52, right-aligned Skip
    ├── SizedBox(height: pagerH)                           // pagerH = 400 × textScale (1.0–1.3, see scale rule)
    │   └── PageView.builder (clipBehavior hardEdge, padEnds false)
    │       controller: PageController(viewportFraction: pitch / viewportW)
    │       itemCount 3, onPageChanged → setState(page)
    │       each page: Padding(right: 12, child: SizedBox(width: cardW, height: pagerH, child: <card>))
    │       PageView padding: left 20                               // card i spans 20+ pitch·i … +cardW
    ├── Expanded → SingleChildScrollView(padding: 20 sides, bottom s8=32)
    │   └── Column(crossAxis start)
    │       ├── SizedBox(22) + NestPagerDots(count: 3, index: page)  // h18; 8 dots, active 22 pill leaf; NOT tappable
    │       ├── SizedBox(30) + Semantics(header) Text(step.title, h1 28/34 w900 ink)
    │       └── SizedBox(12) + Text(step.detail, body 16/24 ink2, wrap)
    ├── NestBottomCta (pad 16 vert / 20 horiz, no caption)
    │   └── page < 2 ? NestButton.primary('Next', key p02_next)
    │                 : NestButton.primary('Continue', key p02_continue)   // min-h 52, full width
    └── NestHomeIndicator()                                // mock only in gallery; shrinks to 0 in app
```

Responsive rules (no hard-coded widths except via these formulas):
- `viewportW` = LayoutBuilder width at the pager. `cardW = min(310, max(240, viewportW - 80))`
  (390 → 310; 320 → 240; 430 → 310). `pitch = cardW + 12`; `fraction = pitch / viewportW`.
  Peek of next card at page 0 = `viewportW - (20 + pitch)` (390 → 48, matches PNG; 320 → 48).
- Text-scale rule: `raw = MediaQuery.textScalerOf(context).scale(100) / 100; ts = raw.clamp(1.0, 1.3);`
  `pagerH = 400 * ts`. (Fixed 400 overflows at 1.3: compact rows grow 56 → ~69 each. Heights of all
  fixed boxes — tiles, chips, progress — stay unscaled; only text line-boxes grow, so ×ts covers it.)

Card 1 — "Today's quests" (`_QuestPreviewCard`, all static consts):
- `NestCard` (surface, r-l 24, sh-1) with padding 16 (override default s4=16 — same value, pass explicitly).
- Head row (`Row`, gap 8): `Expanded(Text("Today's quests", h3 18/24 w800 ink, maxLines 1, ellipsis))` +
  `NestChip(label: 'Sat 4 Oct')` static (h32, 14 w600).
- `SizedBox(14)`; 4 × preview rows, gap 12, each a `NestListRow(compact: true, …)` (36 tile, r12, icon 22;
  title 16 w600 single-line ellipsis — spec HTML uses 15px here, DS component wins, note the 1px drift;
  NO onTap → no button semantics) with `trailing: NestCoinPill.small`:
  1. `leadingAsset: NestIcons.target`, tint sky, title 'Empty the dishwasher', subtitle 'Maya · weekly', pill '15'
  2. `NestIcons.bin`, coin, 'Put the bins out', 'Leo · once', '15'
  3. `NestIcons.bookOpen`, lilac, 'Reading – 20 minutes' (en dash U+2013), 'Maya · daily', '10'
  4. `NestIcons.bed`, peach, 'Tidy your bedroom', 'Maya · weekly', '15'
  Row internals: pv gap 8 — NestListRow uses spacing s3=12 between tile/text/trailing; screen value 8 wins
  in principle but the gap lives inside the shared component → keep 12 (note as accepted drift, no fork).
- `SizedBox(14)` ("pv-foot margin-top 14"); `NestProgress(fraction: 4/6)` (h8, leaf on surface2);
  `SizedBox(6)`; `Text('4 of 6 quests done today', caption 13/18 ink2)`.
- `Spacer()` (pv-add `margin-top: auto`); `_DashedAddRow(icon plus 20 ink2, label 'New quest', 15 w600 ink2)`:
  feature-private, min-h 44, r-m 16 (`NestRadii.allM`), 1.5px dashed `tokens.line` border via local
  `_DashedBorder` CustomPainter, non-interactive (`ExcludeSemantics`).

Card 2 — "Pip's nest" (`_PipPreviewCard`):
- `NestCard` same geometry/padding.
- Head: `Text("Pip's nest", h3…)` + `NestChip(label: 'Fledgling', selected: true)` (leaf-tint).
- `SizedBox(10)`; centered `PipAvatar(style: mochi, skin: sunny, stage: 3)` in 158×158 box
  (`SizedBox.square(158)`; orchestrator rule: onboarding screens use mochi/sunny at the design's stage;
  design shows fledgling = stage 3; mood idle default, accessory none). Semantics label
  'Pip the fledgling bird', image: true. (Rive still frame under `DISABLE_ANIMATIONS=1`; SVG fallback in tests.)
- `Text('Fledgling', h2 22/28 w800 ink)` (HTML `.pv-grow`); `NestProgress(fraction: 0.7)`;
  `Text('175 of 250 coins · Pip evolves at 250', caption ink2)` (HTML `.pv-cap`, mt 6 → `SizedBox(6)`).
- `SizedBox(10)`; stages row (`Row`, spaceBetween, `ExcludeSemantics` — decorative, main Pip has the label):
  3 × 52 circles: `Container(52, circle, bg selected ? leafTint : lilacTint)` each with
  `PipAvatar(style: mochi, skin: sunny, stage: i, size: 40)` for i = 1,2,3, third selected.
  (Never the v1 `pip_stage_*.svg` — orchestrator ban.)
- `Spacer()`; `_DashedAddRow(icon plus, 'Next stage: Songbird')`.

Card 3 — "Maya's jar" (`_JarPreviewCard`):
- `NestCard` same geometry/padding.
- Head: `Text("Maya's jar", h3…)` + `NestChip(label: 'Sat 4 Oct')`.
- `SizedBox(14)`; `NestMoney(amount: 4.2, style: NestType.h1(color: ink))` → '£4.20' (Nunito 28 w900 + tabular);
  `SizedBox(2)`; `Text('coming on Saturday', bodySmall 15/22 ink2)`.
- `SizedBox(16)`; 3 ledger lines (15px ink2 rows, min-h 32, spaceBetween; total row bold ink with top
  hairline `tokens.line`, mt 4 + pt 6): use `NestType.bodySmall` / `bodySmallStrong` + `NestMoney`-style
  tabular `NestType.money` for amounts — static consts matching `Seed.demo` (base £3.00 + quests £1.20):
  'Weekly base' / £3.00 · 'Quests (120 coins)' / +£1.20 · 'Total' / £4.20.
- `Spacer()`; `_DashedAddRow(icon: NestIcons.jar? — HTML uses wallet SVG; closest token icon is
  `NestIcons.money`; use money 24? HTML svg is 24 here → NestIcon(money, 24→ use 20 to match other add-rows;
  keep 20 for consistency, note drift, label 'No bank card needed')`.

Below-pager copy (per page, from view-local const `_kSteps`, mirroring `OnboardingRepositoryImpl._steps`
verbatim so pre-load frames match loaded frames):
1. 'Set quests in seconds' / 'Pick from 40+ ready-made jobs like ‘Put the bins out’ — or make your own.'
   (Use the repo strings exactly: `"Pick from 40+ ready-made jobs like 'Put the bins out' or make your own."`.)
2. 'Pip grows as they help' / 'Every finished quest feeds Pip the bird, from egg to songbird.'
3. 'Pocket money, sorted' / 'No bank card needed — we keep score, you pay your way.'
- No AnimatedSwitcher on step change (plain swap; avoids animation-controller motion under screenshots).

Dark mode: automatic via tokens (surface #1F1C2E, coin-tint dark, leaf #3CC98A dots/button). Coin/Pip art
keep own colours. No extra code.

## (b) BLoC events / states / repository calls

NONE new. `OnboardingBloc` + `OnboardingLoadRequested` + `OnboardingState` (initial/loading/loaded/failure)
and `OnboardingRepository.watchItems()` stay exactly as-is; `onboarding_routes.dart` already provides the
bloc at `/value-tour`. The tour renders identically in all four statuses (P01 precedent: static marketing
copy must never be blocked by data). Titles come from the view-local `_kSteps` const (same strings as the
repo), so the view does not even need `BlocBuilder` — reference `OnboardingBloc` only in tests for the
state matrix. Do NOT add `ValueTourPageChanged` events or index state to the bloc: pager index is ephemeral
UI state owned by the `StatefulWidget` (`int _page` + `PageController`, disposed in `dispose()`).
`Next` uses `controller.nextPage(300ms, easeOut)` — or `jumpToPage` when `kDisableAnimations` /
`MediaQuery.disableAnimations` is set (RULES §6 still-frame rule).

## (c) Interactions → navigation

| Control | Key | Action |
|---|---|---|
| Skip (nav, 44+ tappable, leaf 16 w700) | `p02_skip` | `context.go(AuthRoutePaths.createAccount)` (`/create-account`) |
| Next (pages 0–1, primary 52) | `p02_next` | `nextPage()` (or `jumpToPage` reduced-motion); stays on route |
| Continue (page 2, primary 52) | `p02_continue` | `context.go(AuthRoutePaths.createAccount)` |
| Horizontal swipe on pager | — | `onPageChanged` → dots + title/body update; no route change |
| Pager dots | — | non-interactive indicators (`onDotTapped: null`; HTML dots are plain spans) |
| Cards, dashed add-rows, chips, progress | — | non-interactive previews (no `onTap` anywhere inside cards) |

Back: no back button (P02 is forward-only; system back returns to `/welcome` via the router stack — do not
add one; HTML nav has only the 44px gap spacer on the left).

## (d) Empty / loading / error states

Identical full tour in every bloc status (initial / loading / loaded-empty / loaded-with-items / failure):
copy is static, so there is nothing to skeletonise. Rationale (P01 precedent): marketing screens must render
before/without the stream (`watchItems()` is `Stream.value` — loading is transient). Tests pump the view
with initial/loading/empty/loaded/failure bloc states and assert the same content.

## (e) Accessibility

- One `Semantics(header: true)` per screen: the step title `Text` (HTML `<h1>`). Card heads are plain text.
- Pager wrapped in `Semantics(label: 'Tour preview, step ${_page + 1} of 3', container: true)` (mirrors HTML
  `role=group` aria-label; updates on page change). Dots keep `NestPagerDots`' built-in 'Page X of 3' label.
- Images: Pip slots labelled ('Pip the fledgling bird' + card-2 main; stage dots + card art excluded as
  decorative); icon tiles carry no semantics (NestIcon default); coin pills announce 'N coins' (built-in).
- Buttons expose labels via `NestButton` semantics ('Skip' nav button wrapped in `Semantics(button: true)`).
- Tap targets (parent mode ≥ 44×44): Skip ≥ 44 (explicit `ConstrainedBox(min 44)`); Next/Continue 52 ✓;
  dots/cards/chips non-interactive → exempt. No kid controls (`NestKidButton`, 56 rule N/A).
- Text scale 1.3: `pagerH` scale rule (a) + single-line ellipsis names/subs + wrapping title/body;
  matrix-tested at 320/390/430 × 1.0/1.3 with `takeException() == null`.
- Width 320: `cardW` clamp rule (a); rows use `Flexible` ellipsis (via `NestListRow`); ledger lines ellipsis.
- Contrast from tokens (ink/ink2 on surface ≥ 4.5); leaf-on-leaf focus ring for keyboard (built into
  `NestButton`); no information carried by colour alone (dots pair position + title change).

## (f) Test plan — `app/test/features/onboarding/value_tour_view_test.dart`

Follow `welcome_view_test.dart` patterns exactly (`setUpTestScope`, `pumpAppRoute(tester, '/value-tour')`,
`GoogleFonts.config.allowRuntimeFetching = false`, end every router test with `disposeApp(tester)`):
1. Copy/themes: light renders card-1 rows ('Empty the dishwasher', 'Put the bins out', 'Reading – 20 minutes',
   'Tidy your bedroom'), '4 of 6 quests done today', dots, 'Set quests in seconds', body, 'Next', 'Skip',
   no '9:41' mock text; dark renders same without overflow.
2. Width × scale matrix (320/390/430 × 1.0/1.3 × light/dark): step-1 content present, `takeException()` null.
3. Pip rule: exactly 4 `PipAvatar` (1 main + 3 stage dots), all mochi/sunny, stages [3,1,2,3]; zero v1
   `pip_stage_*.svg` `SvgPicture`s; main fills 158×158 with semantics label.
4. Pager behaviour: tap `p02_next` → page 2 ('Pip grows as they help', dots index 1); tap again → page 3
   ('Pocket money, sorted', CTA becomes `p02_continue` labelled 'Continue'); `swipeLeft` returns.
   Reduced-motion path: pump with `DISABLE_ANIMATIONS` semantics (MediaQuery.disableAnimations) → still advances.
5. Navigation: `p02_skip` → `/create-account`; `p02_continue` (page 3) → `/create-account`;
   `p02_next` on pages 0–1 does NOT change route.
6. Bloc matrix (direct view pump + fake repo): initial/loading/empty/loaded/failure → identical tour content.
7. A11y: header flag on step title; pager group label 'Tour preview, step 1 of 3'; Skip/Next button semantics;
   tap sizes ≥ 44 (Skip) / ≥ 52 (Next); no `NestKidButton`; decorative art excluded.
No changes to `onboarding_bloc_test.dart` (no bloc change). `flutter analyze` clean, `dart format` clean.

## (g) SHARED_REQUEST

Write `docs/screens/P02/SHARED_REQUEST.md` (one item, non-blocking):
`NestNavBar` compact traps the trailing action in a fixed 44px slot (`nest_nav_bar.dart:74-77`), so the
'Skip' text action (≈40px at 16 w700 + 24 padding) ellipsises. Need: compact bar trailing slot that sizes to
its content (e.g. `trailing` outside the 44 `SizedBox`, or a `wideAction` flag). Blocks: no — P02 ships a
feature-private `_TourNav` (52 min-height, right-aligned leaf 16 w700 Skip with 44-min tap box, `TODO(P02)`
comment) and adopts the shared fix when it lands.

Files the builder may touch (RULES §1): `app/lib/features/onboarding/presentation/views/value_tour_view.dart`
(rewrite; may add feature-private widgets in `presentation/widgets/`, e.g. `value_tour_cards.dart`),
`app/test/features/onboarding/value_tour_view_test.dart` (new), `docs/screens/P02/**`.

VERDICT: PASS
