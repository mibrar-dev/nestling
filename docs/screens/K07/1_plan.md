# K07 · Pip evolves (`/pip-evolution`) — build plan (Stage 1)

Source of truth order: `design/html-source/screens/K07-evolution.html`
(+ `components.css` / `tokens.css`) → light/dark PNGs
(`design/screens/light|dark/K07-evolution.png`, 1170×2532 = 390×844 @3x)
→ this plan. DESIGN_SPEC §5 K07 + SPACING_SPEC confirm; where they
conflict with the K07 HTML, the K07 HTML wins (screen value wins,
SPACING_SPEC §9 principle).

Copy below is byte-checked against the HTML (`python3 -c repr()` per
line). The HTML uses straight ASCII apostrophes (U+0027 `'`) — NOT
curly ’. Never "fix" them to curly quotes.

Route: `PipRoutePaths.evolution` = `/pip-evolution`
(`app/lib/features/pip/pip_routes.dart:14-17`). Mode kid. No tab bar,
no prices in £ (coins only, integer).

## 0. Deliberate deviation from the generic KID BACKGROUND orchestrator rule

The orchestrator boilerplate says every K screen gets `KidScope`
(sky gradient + meadow hills). **K07 must NOT use `KidScope`.**
Evidence:

- K07 HTML line 16 overrides the kid background:
  `.screen.kid { background-color: var(--surface); background-image:
  var(--kid-stars), radial-gradient(118% 62% at 50% 36%,
  var(--lilac-tint) 0%, var(--surface) 58%, var(--lilac-tint) 100%); }`
  — a lilac radial glow on surface, NOT the sky/meadow gradient.
- The K07 body contains NO `.meadow` element (the `.meadow` CSS in the
  `<style>` block is dead boilerplate). Both PNGs show NO hills:
  light = white/lavender glow; dark = dark purple + pinprick stars.
- `KidScope` would paint blue sky + green hills (light) — a guaranteed
  UI-check failure against the K07 PNGs.

So the view paints a screen-local background (own feature,
`presentation/widgets/` — allowed by RULES §1): surface base +
exact-CSS radial glow (`CustomPaint`, §(a).1) + the **shared**
`NestKidStarsPainter` in dark mode only (same pattern as
`KidScope`, `kid_scope.dart:90-95`; no SHARED_REQUEST needed, it is
already exported from the design-system barrel). No local hills are
painted anywhere. The BOTTOM EDGE owner rule still holds: the
`.kid-bar` + home-inset block is one opaque surface box to the
physical edge (§(a).9).

## (a) Widget tree, top → bottom (all tokens, no hard-coded colours/sizes)

Scaffold structure (mirrors the built K03 pattern,
`kid_home_view.dart:350-627`):

```
Scaffold(backgroundColor: Colors.transparent)
└─ Stack                                    // background layer (z 0) + content (z 1)
   ├─ Positioned.fill(child: _EvolutionGlow) // surface + lilac radial, §(a).1; IgnorePointer
   ├─ if (tokens.isDark) Positioned.fill(child: CustomPaint(NestKidStarsPainter)) // IgnorePointer inside? wrap with IgnorePointer
   ├─ Positioned(top: 92, left: 0, right: 0, child: Center(child: _EvolutionSparks)) // 350×250, ExcludeSemantics, IgnorePointer
   └─ Column
      ├─ const NestStatusBar()               // reserves 47 only; OS draws glyphs
      ├─ Padding(0, 20, 0, 2 bottom)         // `.k7-top { padding: 0 20px 2px }`
      │  └─ Row[Spacer, _GateLockButton]     // 56 px lock, top-right
      ├─ Expanded
      │  └─ SingleChildScrollView(padding: 0,20 bottom 32) // `.scroll` base
      │     └─ Column(spacing: 16)           // `.scroll > * + * { margin-top: 16 }`
      │        ├─ _EvolutionStage (250)      // §(a).2
      │        ├─ NestBalancedText title     // `.kid-title.k7-hero`, §(a).3
      │        ├─ Text sub                   // `.kid-body.k7-sub`, §(a).4
      │        ├─ Center > ConstrainedBox(maxWidth 260) > NestSpeechBubble // `.k7-cheer .speech`, §(a).5
      │        │   (+ 9 px tail overflow below bubble — Positioned, sizes nothing)
      │        ├─ Row(spacing: 10) stats     // `.k7-stats`, §(a).6
      │        └─ Text kcap                  // `.kcap`, §(a).7
      └─ Container(surface, top border 3 ink) // `.kid-bar` + bottom-edge owner rule
         └─ SafeArea(top: false)
            └─ Column(min)
               ├─ Padding(12, 20, 20, 10) > NestKidButton lilac CTA // §(a).8
               └─ const NestHomeIndicator()  // shrink in app; SafeArea keeps surface to edge
```

### (a).1 Background glow (screen-local `_EvolutionGlow`)

Exact transcription of HTML line 16. Container `color: tokens.surface`,
plus a `CustomPaint` painter filling the box with an elliptical radial
gradient:

- centre = (50% width, 36% height) → `(195, 304)` at 390×844. Compute
  from the actual box (`size.width * 0.5`, `size.height * 0.36`), never
  literals.
- radii = explicit `118% 62%` → `rx = 1.18 × width`, `ry = 0.62 × height`.
- stops/colours: `0 → tokens.lilacTint`, `0.58 → tokens.surface`,
  `1.0 → tokens.lilacTint`.
- Implementation: save canvas, translate to centre, `scale(rx, ry)`,
  paint the unit circle with a circular `RadialGradient` shader of the
  three stops, restore. (A plain `RadialGradient` in `BoxDecoration`
  cannot draw the CSS ellipse — do not approximate with it.)
- Light resolves to white + `#EEEBFF` glow; dark resolves via dark
  tokens (`surface #1F1C2E`, `lilacTint #2B2550`) — matches the dark PNG.
- Dark-only stars: `if (tokens.isDark)` full-bleed
  `CustomPaint(painter: const NestKidStarsPainter())` (shared,
  `kid_meadow.dart`; positions are the CSS `--kid-stars` pins).
- All background layers `IgnorePointer` (CSS `pointer-events:none`).

### (a).2 `_EvolutionStage` — old → new Pip (250 px slot)

`.k7-stage { height: 250px }` → `SizedBox(height: 250, width: double.infinity)`
with a `Stack(clipBehavior: Clip.none)`:

- Old Pip: `Positioned(left: 2, bottom: 4, width: 68, height: 68)` —
  `PipAvatar(style/skin/accessory of the child, stage: oldStage,
  size: 68)` wrapped in `Opacity(0.24)` + `ColorFiltered`
  (standard grayscale matrix:
  `0.2126,0.7152,0.0722 / ×3 rows, alpha row 0,0,0,1,0`) for
  `opacity:.24 + grayscale(1)`. `ExcludeSemantics` (decorative
  silhouette; the HTML `alt=""`).
- Arrow: `Positioned(left: 76, bottom: 24)` —
  `NestIcon(NestIcons.arrowRight, size: 30, color: tokens.lilacStrong)`
  (CSS `.k7-arrow { color: var(--lilac-strong) }`, svg 30×30).
  `ExcludeSemantics` (`aria-hidden="true"`).
- New Pip: `Positioned(right: 6, bottom: 0, width: 240, height: 240)` —
  `PipAvatar(style/skin/accessory of the child, stage: profile.stage,
  size: 240)` wrapped in
  `Semantics(image: true, label: "{Nickname}'s Pip, {phrase}")`
  (phrase table §(a).10; cf. `profilePipSemanticLabel` in family —
  restated locally, never imported across features).
- `oldStage = max(1, profile.stage - 1)`. Stage-1 edge (degenerate,
  unreachable in demo): hide old Pip + arrow, centre the 240 new Pip
  (`Center` instead of the `Positioned` trio). Title pattern is uniform
  for all stages (§(a).10).
- String→enum mappers are private to the pip feature (same tables as
  `parental_gate_view.dart:458-483`): `mochi` default style,
  `sunny` default skin, `none` default accessory; `bolt/storybook`,
  `sky/berry/mint`, `bow/cap/scarf/glasses` mapped; stage clamped 1..4
  (cf. `kid_home_view.dart:676`).
- ORCHESTRATOR PIP rule: both slots use the child's OWN
  `pip_style/pip_skin/pip_accessory` from the DB (Maya =
  Mochi·sunny·none). Never the v1 `pip-stage-*.svg`. Sizes/positions are
  the design's.

### (a).3 Title — `NestBalancedText` (`.kid-title` uses balance)

- `NestBalancedText(text, style: NestType.kidTitle(color: tokens.ink),
  textAlign: center, maxLines: 4)` — `.kid-title` is in the balanced
  list; `.k7-hero` adds `overflow-wrap:anywhere` (≈ softWrap, keep
  default `softWrap: true`).
- Text: `Pip grew into {a/an} {Stage}!` — ASCII `!`, no curly quotes.
  Article rule: `an` iff stage name starts with `E` (Egg), else `a`
  (same rule as family's `pipStageArticle`).
- Demo (Maya, stage 3): `Pip grew into a Fledgling!`

### (a).4 Sub — `Because you helped {n} time(s)`

- `Text(sub, style: NestType.kidBody(color: tokens.ink),
  textAlign: center, maxLines: 2, overflow: ellipsis)` —
  `.kid-body.k7-sub`, centred.
- `n == 1 → 'Because you helped 1 time'`, else
  `'Because you helped $n times'`. `n = evolution.questsDone`
  (lifetime, §(b)). Demo Maya: `Because you helped 4 times`.

### (a).5 Speech — shared `NestSpeechBubble`

- `Center > ConstrainedBox(maxWidth: 260) > NestSpeechBubble(text: speech)`
  (`.k7-cheer` centres; `.speech` max-width 260; the shared widget owns
  padding 8/14, 3 px ink border, r18, tail — `nest_pet_stage.dart:369+`,
  whose docstring names K07 as a user). Do NOT re-implement.
- Per-stage speech (design line verbatim for the design's stage 4;
  parallel kid-tone lines otherwise, ASCII apostrophes, no DB claims):
  - 1: `Shh... Pip is still growing!`
  - 2: `Hello! Pip is out of the egg!`
  - 3: `Flap, flap! Look at Pip's wings!`
  - 4: `Hear that? That is Pip's new song!` (HTML line 57 verbatim)
- The 9 px tail is overflow (`Positioned`, sizes nothing) — the 16 px
  column gap below the bubble starts at the bubble body, as in CSS.

### (a).6 Stats — three bordered cards

`.k7-stats { display:flex; gap:10px }` → `Row(spacing: NestSpacing.gap10)`
(note: `spacing:` param, cf. `kid_home_view.dart:363`), three
`Expanded` cells (`flex:1, min-width:0`):

- Cell: `Container(padding: 12 vertical / 6 horizontal,
  decoration: BoxDecoration(color: tokens.surface,
  borderRadius: NestRadii.allM, border: 3 px tokens.ink,
  boxShadow: [BoxShadow(color: tokens.kidShadow.first.color,
  offset: Offset(0, 6))]))`
  (3 px = kid border, same literal as the K03 dock border,
  `kid_home_view.dart:531`; shadow mirrors `NestKidButton`'s sh-kid).
- Number: `b { Nunito 900, 30/34 }` — no token style exists at 30 px;
  call-site `NestType.kidTitle(color: tokens.ink).copyWith(fontSize: 30,
  height: 34/30)` with a comment citing `K07-evolution.html:29`
  (same call-site pattern as the LETTER SPACING ruling). Centre,
  `maxLines: 1`, `FittedBox(BoxFit.scaleDown)` guard for 320 px /
  text-scale 1.3 (cell ≈ 86 px at 320 — `quests done` label must shrink,
  never overflow).
- Label: `span { Nunito 700, 14/18, ink-2, margin-top 2 }` — call-site
  `NestType.kidCaption(color: tokens.ink2).copyWith(fontSize: 14,
  height: 18/14)` citing `K07-evolution.html:30`. Centre, `maxLines: 2`,
  ellipsis, inside the same scale-down guard.
- Values (DB-driven, §(b)): `{questsDone} / quests done`,
  `{totalCoins} / coins grown`, `{stage} / of 4 stages`.
  Demo Maya: `4`, `175`, `3`.
- Semantics: wrap the row in
  `Semantics(label: '$q quests done, $c coins grown, stage $s of 4',
  excludeSemantics: true)` so VoiceOver announces one clean summary.

### (a).7 Caption — `.kcap`

- `Text('Pip still loves a chin scratch.',
  style: NestType.kidCaption(color: tokens.ink2), textAlign: center)`
  (HTML line 14: 15/20 w700 ink-2 = `kidCaption` exactly; line 63
  verbatim, centred). `maxLines: 3`, ellipsis.

### (a).8 CTA — `.btn-kid.lilac` in `.kid-bar`

- Bar: `.kid-bar { background: surface; border-top: 3px ink;
  padding: 12px 20px 10px }` — the bottom `Container` (§(a) intro);
  inner `Padding(EdgeInsets.fromLTRB(20, 12, 20, 10))`.
- Button: `NestKidButton(label: 'Meet {Stage} Pip',
  color: NestKidButtonColor.lilac, onPressed: …)` — base 64 min-height,
  Nunito 20 w900 defaults; full width; `wrapLabel` default true.
  Label pattern from HTML line 66 (`Meet Songbird Pip`); demo Maya:
  `Meet Fledgling Pip`.
- `NestKidButton` already pads 6 px under the button for the sh-kid
  shadow (SPACING_SPEC §10.6) — keep the CSS 12/20/10 around it.

### (a).9 Bottom edge (owner rule)

The surface `Container` (bar) + `SafeArea(top: false)` + CTA +
`NestHomeIndicator()` is ONE box to the physical edge — identical to
the K03 dock (`kid_home_view.dart:528-622`). No glow/meadow strip under
the bar in either theme. The OS draws the home pill.

### (a).10 Stage-name + phrase tables (feature-private copy helpers)

New `presentation/widgets/pip_evolution_copy.dart` (precedent:
family's `child_profile_copy.dart` — every string documented with its
HTML source):

```dart
String evolutionStageName(int stage) => switch (stage) {
  1 => 'Egg', 2 => 'Hatchling', 4 => 'Songbird', _ => 'Fledgling' };
String evolutionStageArticle(int stage) =>
  evolutionStageName(stage).startsWith('E') ? 'an' : 'a';
String evolutionTitle(int stage) =>
  'Pip grew into ${evolutionStageArticle(stage)} ${evolutionStageName(stage)}!';
String evolutionSub(int questsDone) => questsDone == 1
  ? 'Because you helped 1 time' : 'Because you helped $questsDone times';
String evolutionSpeech(int stage) => switch (stage) { ... §(a).5 ... };
String evolutionCta(int stage) => 'Meet ${evolutionStageName(stage)} Pip';
String evolutionStagePhrase(int stage) => switch (stage) {   // a11y only
  1 => 'an egg', 2 => 'a hatchling', 4 => 'a songbird', _ => 'a fledgling' };
```

Plus the pip string→enum mappers (`_pipStyle/_pipSkin/_pipAccessory`,
same tables as `parental_gate_view.dart:458-483`).

### (a).11 CSS-derived vertical map (390×844, CSS px — builder to confirm with `compare.py` in the UI stage)

`47` status → `47–103` lock (56 + 2 bottom pad = row 58) →
`105–355` stage (250) → `+16` → title (~34/68) → `+16` → sub (26) →
`+16` → speech (~44 + 9 tail overflow) → `+16` → stats (78:
12+34+2+18+12) → `+16` → kcap (20) → scroll bottom pad 32 →
kid-bar ≈ 95 (3 border + 12 + 64 + 6 shadow + 10) → home inset 34.
Content fits without scrolling at 1.0×/390 px; scroll absorbs 320 px /
1.3× growth.

### Sparks (`_EvolutionSparks`, screen-local)

Transcription of the HTML `svg.sparks` (lines 35–46, `viewBox
0 0 350 220`), in a `SizedBox(width: 350, height: 250)` positioned
`top: 92`, centred horizontally (`Positioned(left:0,right:0,top:92)`
+ `Center`; `ClipRect` on the background layer so 350 > 320 px
overflows are clipped exactly like CSS `overflow:hidden`):

- Box 350×220 painted centred in the 350×250 CSS box (SVG `meet`
  letterboxes 15 px top/bottom) → `CustomPaint(size: 350×220)` inside
  `Center` in the 350×250 box.
- 4-point sparkle path template `M32 30 37 44 51 49 37 54 32 68 27 54
  13 49 27 44Z` (36×38 box) placed at the four HTML spots with the four
  HTML fills; 4 circles r 6–7. Stroke `tokens.ink` width 3, round joins.
- Token mapping (never hard-code): sparkle fills `#7C6CF2 → tokens.lilac`,
  `#1F9D63 → tokens.success`, `#F4B400 → tokens.coin`,
  `#FF8A5B → tokens.peach`; circles `#F4B400 → tokens.coin`,
  `#3D7FF0 → tokens.sky`, `#1F9D63 → tokens.success`,
  `#7C6CF2 → tokens.lilac`.
- Static art (screenshots run with `DISABLE_ANIMATIONS=1`); no
  `Timer`/`AnimationController` (RULES §6).

## (b) BLoC + repository (local Drift via the existing repo)

New entity `domain/entities/pip_evolution.dart`:

```dart
class PipEvolution extends Equatable {
  const new({required this.profile, required this.questsDone});
  final PipProfile profile;   // existing entity (child row + growth fields)
  final int questsDone;       // lifetime completions done_pending|approved
  ...
}
```

`PipRepository` += `Stream<PipEvolution?> watchEvolution();`
— follows the active child in `app_state` (cf. `KidHomeRepository.watchHome`;
`switchMap` implemented privately in `PipRepositoryImpl`, same semantics
as kid_home's `switchMapStream`: outer `watchAppState()`, inner
`combineLatest2(watchChild(id), watchCompletionsForChild(id))`
from core `stream_combine.dart`; null when no active child or the child
row is gone). Mapping:

- `profile` from the child row (same fields as existing `watchProfile`:
  style/skin/accessory/stage/totalCoins/coins/happiness).
- `questsDone` = completions with `status == 'done_pending' ||
  status == 'approved'`, **all time** — a lifetime milestone, so the
  PERIODS ruling (`countsForCurrentPeriod`, London day/week) does NOT
  apply; `to_do` and `not_yet` never count. No clock use at all
  (`london_time.dart` not needed; app code never calls `DateTime.now()`).
- Demo expectations: Maya → `{stage 3, totalCoins 175, questsDone 4}`
  (dishwasher + table pending, bins + hoover approved); Leo →
  `{stage 2, totalCoins 60, questsDone 2}`.

`PipBloc` refactor (mirrors `KidHomeBloc` guards — the current
`emit.forEach` on `watchItems` cannot host a second never-closing
stream):

- State += `PipEvolution? evolution` (copyWith + props). `items`
  (wardrobe, for K06) keeps working untouched.
- Events += `PipEvolutionReceived(PipEvolution?)`,
  `PipEvolutionFailed(Object error)` (+ private items-received/failed
  pair replacing the inline `forEach`).
- `PipLoadRequested` starts BOTH subscriptions under separate null-guards
  (live sub ⇒ ignore reload — never re-add load events); errors release
  only their own sub so `Try again` really reloads. `close()` cancels both.
- Mid-session error with an evolution already shown keeps the loaded
  screen (K03 review-finding-6 pattern); only nothing-to-show becomes
  failure.

Route wiring unchanged: `pipEvolutionRoute` already provides `PipBloc`
+ `PipLoadRequested` (`pip_routes.dart:30-39`).

## (c) Interactions + navigation (route constants)

| Control | Action | Destination |
|---|---|---|
| CTA `Meet {Stage} Pip` | `context.go(PipRoutePaths.nest)` (`/pip`, K06) | back to Pip's nest |
| Lock (top-right) | `await context.push(ParentalGateRoutePaths.gate)` (`/parental-gate`) with the `_busy` double-tap guard (`kid_home_view.dart:639-656`) | parental gate modal |
| `Try again` (failure) | re-add `PipLoadRequested` | retry streams |
| `Choose` (no active child) | `context.go(KidHomeRoutePaths.picker)` (`/who-is-playing`) | profile picker |
| Old Pip / new Pip / sparks / stats / speech | none (display only) | — |

`context.go` for screen changes, `context.push` for the gate — the
established convention (`money_ledger_view.dart:384`,
`kid_home_view.dart:646`). Cross-feature *route-constant* imports
(`parental_gate_routes.dart`, `kid_home_routes.dart`) are established
practice (same imports in `kid_home_view.dart`).

## (d) Empty / loading / error states

All three mirror the built K03 states (`kid_home_view.dart:158-333`)
on the glow background (NOT `KidScope`), each with status bar + lock
row + content + surface bottom block:

- Loading: centred `CircularProgressIndicator(color: tokens.leaf)` in
  `Semantics(label: 'Loading Pip’s big moment')` — curly ’ here is
  NEW a11y copy (no HTML source), consistent with the codebase's
  announcement style.
- Failure (`errorMessage ?? 'Something went wrong'`): `Oh no! Pip got
  lost.` (h2) + `Let's try again.` (ASCII `'`, cf. K03) + white
  `NestKidButton('Try again', fullWidth: false)` re-adding
  `PipLoadRequested`; shows the last-known child's Pip (140) when
  available else neutral `PipAvatar(mochi, stage 1)` (K03 pattern).
- No active child (`evolution == null` once loaded): `Who's playing?`
  (h2) + lilac `NestKidButton('Choose', fullWidth: false)` →
  `/who-is-playing`.
- Failure/empty CTA tap targets ≥ 56 (`NestKidButton` min 64).

## (e) Accessibility

- Every interactive element exposes `SemanticsAction.tap`:
  `NestKidButton` + `NestLockButton` already own `onTap` semantics —
  do NOT wrap them in `excludeSemantics` without passing `onTap:`
  (RULES §8). Tests assert `hasAction(tap)` + `performAction(tap)`
  drives real navigation (CTA → `/pip`, lock → gate).
- Lock: `NestLockButton(semanticLabel: 'Grown-ups', …)` — the design
  `aria-label` is `Grown-ups`, not the widget default `Grown-ups only`
  (cf. `kid_home_view.dart:654`).
- New Pip: `Semantics(image: true, label: "Maya's Pip, a fledgling")`;
  old Pip + arrow + sparks: `ExcludeSemantics` (HTML `alt=""` /
  `aria-hidden`). Stats row: single merged label (§(a).6). Speech:
  plain centred text (reads naturally). Title/sub: plain headings/text.
- Tap targets: lock 56×56, CTA ≥ 64 high, failure/empty buttons ≥ 56 —
  all ≥ kid 56 minimum (DESIGN_SPEC §0.9).
- Text scale 1.3: title balances; sub `maxLines: 2`; speech box fixed
  maxWidth 260, grows vertically into the scroll; stat number+label
  under `FittedBox(scaleDown)`; CTA label wraps (`wrapLabel` default).
- Width 320: stage slot is full-bleed-safe (240 Pip right-aligned fits:
  240 + 6 ≤ 280 content); sparks clipped by `ClipRect`; stats
  `(320−40−20)/3 ≈ 86.7` px cells scale down, never overflow.
- No red anywhere; kind failure copy; no timers/countdowns.

## (f) Test plan (`app/test/features/pip/`, new; `--timeout 120s`; end pumped tests with `disposeApp`)

1. `pip_repository_test.dart` — `watchEvolution` on `Seed.demo()`:
   Maya emits `{stage 3, totalCoins 175, coins <wallet>, questsDone 4}`;
   inserting an approved completion re-emits with +1; `to_do`/`not_yet`
   rows never count; null active child → null; unknown child id → null.
2. `pip_bloc_test.dart` — `PipLoadRequested`: loading → loaded with
   evolution; stream error → failure with message; second load while
   live adds no second subscription; `close()` cancels (no stray timers).
3. `pip_evolution_view_test.dart` (light + dark, `pumpAppRoute('/pip-evolution')`):
   finds `Pip grew into a Fledgling!`, `Because you helped 4 times`,
   `4`/`quests done`, `175`/`coins grown`, `3`/`of 4 stages`,
   `Meet Fledgling Pip`, `Pip still loves a chin scratch.`,
   design speech; CTA tap → `currentPath == '/pip'`; lock tap →
   `pushedPath == '/parental-gate'`.
4. `pip_evolution_a11y_test.dart` — every control
   `hasAction(SemanticsAction.tap)`; `performAction(tap)` on CTA/lock
   navigates; stage-1 row renders single Pip without crash
   (update child row `pipStage = 1`, old slot absent).
5. `pip_evolution_responsive_test.dart` — 320 px width + `textScale 1.3`,
   light + dark: no overflow exceptions, CTA still tappable.
6. `pip_evolution_copy_test.dart` — byte-exact copy table (§(a).10 +
   design lines) incl. ASCII `'` in `Pip's`, `1 time` singular.
- No `google_fonts` imports anywhere; no `DateTime.now()`; data only
  from the seeded DB (numbers above are expectations, never literals in
  the view).

## (g) SHARED_REQUEST

None. Everything K07 needs is in-feature (`pip/…`) or already shared:
`PipAvatar`, `NestKidButton`, `NestLockButton`, `NestSpeechBubble`,
`NestBalancedText`, `NestStatusBar`/`NestHomeIndicator`,
`NestKidStarsPainter`, `NestIcon.arrowRight`, `combineLatest2`,
`watchAppState/watchChild/watchCompletionsForChild`, route constants.
No schema, seed, route, DI, or design-system change required.

Background note for the UI stage: the screen background is the
screen-local lilac glow (§0) — do NOT "fix" it towards `KidScope`
sky/meadow. DB-driven content (title stage, counts, CTA stage word,
Pip style/stage) is exempt from ±2 px shape comparison per the UI
VERDICT RULE; the bar, cards, bubble, lock and CTA shapes are not.

VERDICT: PASS
