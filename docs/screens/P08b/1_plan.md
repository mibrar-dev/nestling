# P08b · Today empty — build plan (Stage 1)

Route `/today-empty` · parent mode · seed `Seed.empty()` (onboarded parent Sarah, no children, no quests).
Sources: `design/html-source/screens/P08b-today-empty.html` (copy of record),
`design/screens/light|dark/P08b-today-empty.png` (1170×2532 @3x, ÷3 = logical px),
DESIGN_SPEC §5 P08b, SPACING_SPEC, orchestrator rules in the loop brief.

## 0. Measured design geometry (logical px, from HTML box model)

- Canvas 390×844. Status bar 47 (OS-drawn; `NestStatusBar` reserves height only — ignore in checks).
- `.scroll`: padding `0 20 32`, siblings `margin-top: 16`.
- `.greet`: `padding-top: 8`. `h1` Nunito 900 28/34 ink (`Good morning, Sarah`);
  `.date` 15/22 w500 ink-2, `margin-top: 2` (`Sat 4 Oct · A fresh nest`).
  Computed: title top ≈ 55, date ≈ 89–111. **No `+` button, no avatar** (unlike P08).
- `.empty-card`: surface, r-24, sh-1, padding `28 20`, column gap 8, centred.
  `img` 140×140 (Pip stage-1 egg). `h2` Nunito 800 22/28 (`Your nest is quiet`).
  `p` 15/22 ink-2, max-width 260 (`Add your first quest and Pip will start to hatch. Maya and Leo will see it straight away.`).
  8 px spacer, `.btn-primary` full-width 52 (`Add a quest`), `.linkrow a`
  sky 15 w600, min-height 44, centred (`Browse ideas`, underlined in PNG).
  Computed: card top ≈ 127; art ≈ 155–295; title ≈ 303–331; message ≈ 339–405
  (3 lines); button ≈ 421–473; link ≈ 473–517; card bottom ≈ 545.
- `.card.inset`: surface-2, no shadow, r-24, padding 16 (base card padding; no local
  override). `body-s` 600 (`Tip for new nests`) + `.caption` 13/18 ink-2
  (`Start with two daily quests each — “Make your bed” and “Reading – 20 minutes” work beautifully.`
  — em dash –, curly quotes “ ”, en dash – inside; copy bytes exactly).
  Computed: tip top ≈ 561.
- `.tab-bar`: 84 high (8 top, 24 home reserve), 4 tabs, Today active leaf.
  Surface colour runs to the physical edge (owner rule; shell owns this).
- Dark: identical geometry; card surface dark, inset surface-2 dark, egg art unchanged.

## (a) Widget tree (tokens only — never hard-code colours/sizes)

`TodayEmptyView` (Scaffold; chrome/tab bar from shell after shared move, §g):
`SafeArea` → `BlocBuilder<TodayBloc, TodayState>`:
- initial/loading → `Center(CircularProgressIndicator(color: tokens.leaf))` (reuse as-is).
- failure → existing `TodayFailureBody` (reuse as-is).
- loaded → NEW `TodayEmptyLoadedBody` (do NOT reuse P08 `_Greeting`/`_EmptyCard`):
  - `ListView(padding: EdgeInsets.fromLTRB(padSide=20, 0, padSide=20, s8=32))`, children:
    1. `_EmptyGreeting` — `Padding(top: s2=8)` → `Column(start, min)`:
       `Semantics(header: true, child: Text('$greeting, $parentName', style: NestType.h1(ink)))`
       (h1 = 28/34 w900, letterSpacing 0 — NO copyWith tracking);
       `Padding(top: gap2, child: Text(dateLine, style: NestType.bodySmall(ink2).copyWith(fontWeight: w500)))`
       (15/22; NO letterSpacing override). maxLines 1 + ellipsis each.
       Text-only: no `NestIconButton`, no avatar (differs from P08 HTML which has none).
    2. `SizedBox(s4=16)`.
    3. `_EmptyCard` — `NestCard(variant: standard, padding: EdgeInsets.fromLTRB(padSide, 28, padSide, 28))`
       (28 = `s8 - s1`; NestCard default radius allL=24, standard shadow — matches r-l/sh-1).
       Child `Column(min, center, gap8)` — NOT `NestEmptyState` (its title is h3 18px not h2 22px,
       its art box is 160 not 140, and its 24/16 inset padding would double-pad to 52/36):
       - `Semantics(image: true, label: 'Pip the bird as a speckled egg', child: ExcludeSemantics(child: PipAvatar(style: mochi, skin: sunny, stage: 1, size: 140)))`
         (no-child screen → mochi·sunny per orchestrator P01–P07 rule extended to the childless
         empty state; `inNest: false`; never v1 `pip_stage_*.svg`).
       - `Text('Your nest is quiet', style: NestType.h2(ink), centered)` (22/28 w800).
       - `ConstrainedBox(maxWidth: 260, child: Text(<full two-sentence message>, style: NestType.bodySmall(ink2), centered, maxLines 5))`.
       - `SizedBox(s2=8)`.
       - `_PushOnce(location: QuestsRoutePaths.editor, builder: → NestButton(label: 'Add a quest', onPressed: push))`
         (primary: full-width, 52, pill, 16 w700).
       - link row: `Semantics(button: true, label: 'Browse ideas', excludeSemantics: true, onTap: go)` +
         `InkWell(onTap: go, child: Padding(vertical: 11, child: Text('Browse ideas', style: NestType.bodySmallStrong(sky).copyWith(decoration: underline), centered)))`
         (15/22 w600 sky underlined; 22 + 11×2 = 44 min tap height; centred full-width row).
    4. `SizedBox(s4=16)`.
    5. Tip — `NestCard(variant: NestCardVariant.inset)` (default padding 16, radius 24, no shadow)
       → `Column(start, min, spacing: s1=4)`:
       `Text('Tip for new nests', style: NestType.bodySmallStrong(ink))`,
       `Text(<tip body>, style: NestType.caption(ink2), softWrap true, maxLines 4)`.
- Gutters: every block spans x 20–370 at 390 px (owner alignment rule).

## (b) BLoC / repository (Drift via existing repo — no new tables, no new events)

- Events: `TodayLoadRequested` only (route already dispatches it). No new event.
- Streams (existing `TodayRepository`, unchanged): `watchItems()`, `watchSummaries()`,
  `watchParentName()` (→ `Sarah` from `Seed.empty()` members), `watchPayoutDay()`, `watchPendingCount()`.
  Empty state derives from `state.summaries.isEmpty` — no repo change.
- ONE bloc change (`today_bloc.dart`): when `summaries.isEmpty`, dateLine suffix is the static
  design string, not the happy-week count:
  `dateLine = '${formatLondonDay(now)} · ${summaries.isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}'`
  (middle dot U+00B7 as now). Safe for P08: demo seed never has empty summaries.
  Greeting day-part via existing `dayPartForHour(toLondon(now).hour)`; clock via `appNowUtc()`
  (never `DateTime.now`). Period scoping N/A (no quests); `countsForCurrentPeriod` untouched.
- P08/P08b share `today/` (same feature): gate every P08b difference behind `summaries.isEmpty`
  or new private widgets; the demo-seed (P08) render path must be byte-identical.

## (c) Interactions → routes

| Control | Action | Destination |
|---|---|---|
| `Add a quest` | `push` (guarded `_PushOnce`) | `QuestsRoutePaths.editor` = `/quest-editor`, NO query (new-quest mode) |
| `Browse ideas` | `go` | `QuestsRoutePaths.library` = `/quests` |
| System back from editor | pop | returns to `/today-empty` |
| Tab bar (shell) | `goBranch` | Today/Quests/Money/Family (shell-owned, not this feature) |

All tap targets ≥ 44 (primary 52; link row 44; greeting has no buttons by design).

## (d) States

- Empty (Seed.empty): §a tree. Banner, kids grid, quest groups, hand-off button are ABSENT
  (summaries empty ⇒ not built). `pendingCount` is 0; no approvals UI.
- Loading: leaf spinner (existing).
- Failure: `TodayFailureBody` fixed kind copy + `Try again` → re-adds `TodayLoadRequested` (existing; raw error stays in state, never on screen).
- Non-empty DB on `/today-empty` (e.g. demo seed): falls back to the P08 loaded body (existing
  `TodayLoadedBody` non-empty branch) — keep that behaviour.

## (e) Accessibility

- Greeting is a `header` semantics node; Pip art is `image` with label
  `Pip the bird as a speckled egg` (ExcludeSemantics on the avatar itself; non-interactive ⇒ no tap action).
- Both actions are real buttons with tap actions: `NestButton` (Add a quest) and the
  `Semantics(button, excludeSemantics, onTap:)` link wrapper (Browse ideas) — tests assert
  `hasAction(SemanticsAction.tap)` and that `performAction(tap)` navigates.
- No `Semantics(excludeSemantics: true)` wrapper without `onTap:` anywhere.
- Width 320 + textScale 1.3: title/message/tip wrap (no `softWrap: false` except the link label,
  which is short); message `maxWidth: 260` centres; card keeps 20 px gutters; no horizontal overflow.
- Contrast from tokens (ink on surface, ink-2 15px body, sky link 15 w600) in both themes.

## (f) Test plan (extend `app/test/features/today/`, run with `--timeout 120s`, end pumped tests with `disposeApp`)

Update the `P08b Today empty` group in `today_view_test.dart` (current tests enshrine two bugs):
1. Full-copy test (`/today-empty`, empty seed): `Your nest is quiet` + TWO-sentence message
   `Add your first quest and Pip will start to hatch. Maya and Leo will see it straight away.`
   (fix existing assertion of the truncated sentence) + tip title/body exact copy (curly quotes/em dash).
2. Greeting: `Good morning, Sarah`-style greeting present; `New quest` (+) and `Sarah's profile`
   avatar ABSENT; dateLine ends `A fresh nest` (pinned clock ⇒ `Sat 3 Oct · A fresh nest`).
3. Nav: `Add a quest` → `/quest-editor` with empty query; `Browse ideas` → `/quests`.
4. Dark: same copy renders (empty seed, `ThemeMode.dark`).
5. Pip: exactly one `PipAvatar(mochi, sunny, stage 1)`, size 140; no `pip_stage` SVG anywhere.
6. Sizes: 320 px + 1.3×, scroll through tip; no exception; link height ≥ 44.
7. Semantics-tap (`today_semantics_tap_test.dart` style): both actions `hasAction(tap)` and
   `performAction(tap)` changes route. Art node has NO tap action.
8. Alignment: card left/right x = 20/370; greeting dx = 20 (mirror of the P08 gutter test).
9. Bottom edge: tab-bar surface reaches the physical edge — blocked until §g lands; assert via
   `/today` + empty seed meanwhile (shell present there).
- No `google_fonts` imports in code or tests. No `DateTime.now()` in code.

## (g) SHARED_REQUEST

File `docs/screens/P08b/SHARED_REQUEST.md`: move `todayEmptyRoute` (`/today-empty`) into the
Today `StatefulShellBranch` in `app/lib/app/router.dart` so the design's tab bar (Today active)
renders and the owner bottom-edge rule holds. Currently top-level ⇒ no `NestTabBar` on
`/today-empty`. Blocks pixel-perfect UI check: yes (body work proceeds regardless).

VERDICT: PASS
