# K05 Quest complete — 4 QA code review (iteration 1)

Scope: `git diff main...HEAD` (merge-base `7115369`) — 4 lib files, 6 test
files, this screen's notes. No code edited by this stage.

## Files reviewed

| File | Δ |
|---|---|
| `app/lib/features/kid_home/presentation/views/quest_complete_view.dart` | +648 (placeholder replaced) |
| `app/lib/features/kid_home/domain/entities/kid_growth.dart` | new, 30 |
| `app/lib/features/kid_home/domain/entities/kid_child.dart` | +8 (`pipTotalCoins`) |
| `app/lib/features/kid_home/data/kid_home_repository_impl.dart` | +1 (map `pipTotalCoins`) |
| `app/test/features/kid_home/quest_complete_view_test.dart` | new, 799 |
| `app/test/features/kid_home/quest_complete_geometry_test.dart` | new, 270 |
| `k03_bugs_test.dart`, `kid_home_view_test.dart`, `kid_home_bloc_test.dart`, `kid_home_repository_test.dart` | placeholder→route + `pipTotalCoins` coverage |

## Evidence gathered (no simulator used — stage 5 owns that)

- `flutter analyze` → **No issues found!** (full `app/`).
- `dart format --output=none --set-exit-if-changed lib/features/kid_home
  test/features/kid_home` → 48 files, **0 changed**.
- `flutter test --timeout 120s test/features/kid_home` → **All tests passed
  (594, 3 skipped)** — the whole feature, not just the K05 files.
- Edit set is clean against RULES §1: every path is
  `app/lib/features/kid_home/{data,domain,presentation}/**`,
  `app/test/features/kid_home/**` or `docs/screens/K05/**`.
  `analysis_options`, `app/lib/core/**`, `app/lib/app/**` and
  `tools/screens/**` are untouched (`grep -c` → 0).
- Cross-feature **domain** import census over all `lib/features/*/domain/**`:
  exactly one file imports another feature's domain — this screen's new
  `kid_growth.dart` (finding 4).

## What passed (checked, no finding)

- **Orchestrator rules.** PIP: two `PipAvatar`s built from the active child's
  own row (`pipStyleOf/pipSkinOf/pipAccessoryOf`, `stage.clamp(1,4)`,
  `mood: happy`) — no `pip_stage_*.svg`. STATUS BAR: `NestStatusBar` only.
  BOTTOM EDGE: the bar's own `surface` `Container` spans x 0…390 to y 844 with
  `SafeArea(top: false)` **inside** the surface box, so no meadow/sky strip
  shows under it or around the home indicator in either theme (and the dark
  design's green strip is correctly overridden). ALIGNMENT: card, progress bar
  and CTA share x 20…370; pill and bubble share the 195 axis — pinned by two
  tests. BALANCED HEADINGS: `NestBalancedText` on `.kid-hero`, `maxLines: 2`.
  LETTER SPACING: no Material tracking anywhere; the single weight override
  (`h3` → `w900` for `.k5-card-top strong`) touches no tracking. FONTS: bundled
  Nunito/Inter only; a source-level test asserts no `google_fonts`/
  `GoogleFonts`. CLOCK: no `DateTime.now()` (asserted at source level). IDS: no
  id minted (asserted). AVATAR INITIALS: no initials on this screen.
  KID BACKGROUND: `KidScope` only (shared gradient + 390×136 meadow), no local
  hills. K05 has no chips, no icons, one child, and no trial/subscription read.
- **Geometry.** Every `.scroll > *` separator reproduces the HTML's cascade:
  stage 234 → hero gap 4 → hero 44 → 16 → pill 40 → 16 → sub 26 → 16 → bubble
  44 → 16 → card 134, giving design y 343 / 403 / 459 / 501 / 561 with 20 px
  gutters and a bar whose painted CTA lands 15 px under its top border. The
  `_kBarGap = NestSpacing.s1` trick (CSS 10 px bottom air minus the 6 px
  `NestKidButton` shadow room) is the same reasoning as the K03 dock / K04 bar
  and is documented at the constant.
- **Tokens only.** `grep` for `Color(`/`0xFF` in the view returns four
  `Colors.transparent` Scaffold backgrounds and nothing else; every colour,
  radius, shadow, spacing and type size comes from `context.nest`,
  `context.nestKid`, `NestType`, `NestSpacing`, `NestRadii`, `NestDevice`.
  `.k5-card-top strong` correctly resolves to `NestType.h3` (Nunito 18/24),
  not an Inter body style.
- **DESIGN_SPEC §5 K05.** Every element present, nothing extra: burst, Pip,
  hero, coin pill, sub, speech, growth card (mini Pip + headline + count row +
  progress), lock, CTA. Copy verified against the HTML with a `python3`
  containment check; the four dynamic strings render verbatim (asserted), the
  fixed ones are byte-identical, `thumbs-up` keeps U+002D, and a test asserts
  no curly quote / en dash / em dash / ellipsis can appear.
- **DATA OVER MOCKS.** Hero uses `state.child.nickname`; headline/count/
  fraction/percentage/next-stage all derive from `pipTotalCoins`, with
  `evolveAtCoins` taken from `PipProfile` — no design number is hard-coded.
  Coin amount precedence (`extra.coins` → `extra.questId` row → 0) is
  DB-driven, and the period-correctness of the fallback is inherited from
  `watchHome`, which already applies `countsForCurrentPeriod`.
- **Architecture.** Feature-first; view-only change (no new bloc, event or
  state); `pipTotalCoins` is a feature-private domain field mapped in
  `_toChild` and added to `props` (equality covered by a test); DI and routes
  untouched — `/quest-complete` already wires `KidHomeLoadRequested`.
  ARCHITECTURE's "one bloc per feature" and the route table hold.
- **Accessibility.** Every interactive node exposes `SemanticsAction.tap` and
  `performAction` drives real navigation (`/kid-home`, `/parental-gate`); the
  lock has a `_busy` guard so a double tap pushes one gate. Both
  `Semantics(excludeSemantics: true)` wrappers are non-interactive (the Pip
  image and the card's static text), so no `onTap:` is owed under the owner
  rule — `NestProgress` deliberately sits outside the card node so the
  design's own `aria-label` stays a separate announcement. Tap targets: CTA
  64, lock 56×56, Try again / Choose 64.
- **Performance.** No `Timer`/`AnimationController`, so the
  `DISABLE_ANIMATIONS` still frame is the only frame; no new stream is
  subscribed in the view (the bloc owns it and disposes it); `Transform.rotate`
  and the burst SVG are paint-only; the `FittedBox(scaleDown)` keeps the
  320 px plate inside a 320 dp device. `SvgPicture` carries a
  `placeholderBuilder` returning `SizedBox.shrink()`, so the async asset load
  cannot flash a grey box.
- **Error handling.** `initial`/`loading` → shared top row + labelled spinner
  (nothing jumps); `failure` → Pip-lost card whose Try again re-adds
  `KidHomeLoadRequested` and shows the child's own Pip when known; no active
  child → "Who's playing?" → picker; deep link with no resolvable quest still
  celebrates rather than blanking. `_GateLockButton._open` resets `_busy` in a
  `finally` with a `mounted` guard.
- **Children's Code.** No analytics, no ads, no network, no identifiers
  stored or emitted, no logging of child data (`grep` for `print(`/`debugPrint`
  in the diff → none). No shame/timer/locked language; no red/danger token on
  the screen. The only child datum rendered is the nickname, which is the
  design's own copy.

## Findings

No blockers. No majors. Nine minors (one of them low-priority) — none of them
affects the rendered screen, the data path or the accessibility contract, so
none of them blocks.

### 1. minor — deep-link coin fallback can quote the wrong quest
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:105-123`
`_coinsFor` step 3 falls back to "the first quest that is actually done, in
list order", but `watchHome` sorts quests **alphabetically by title**
(`kid_home_repository_impl.dart:71-72`). On a launch with no `extra` the
celebration can therefore attribute a different quest's coins than the one the
child just finished. It is period-correct (`_watchItemsFor` filters with
`countsForCurrentPeriod` first) and it is DB-driven, but it is a guess.
Fix: have the repository surface the newest completion for the child
(`Future<KidQuest?> lastCompletedQuest(String childId)`) and use that instead
of list order; or, if the fallback exists only so `shot.sh` renders the
seed, gate it behind a debug flag so production can only celebrate what the
`extra` names.

### 2. minor — `kid_growth.dart` sits in `domain/entities/` and is the codebase's only cross-feature domain import
`app/lib/features/kid_home/domain/entities/kid_growth.dart:1,13-18`
ARCHITECTURE says `domain/` is "entities + abstract `<feature>_repository.dart`
ONLY". The file holds no entity, and its
`import 'package:nestling/features/pip/domain/entities/pip_profile.dart'` makes
`kid_home`'s domain depend on `pip`'s domain — a first in this codebase
(census in *Evidence*), and `pip` is owned by a different screen loop.
The project's own precedent for pure domain maths is
`app/lib/features/pocket_money/domain/next_payout.dart`, which lives at the
domain root and imports only `core/`. `kidPipCoinsRemaining` /
`kidPipGrowthFraction` also re-implement `PipProfile.coinsToGrow`
(`pip_profile.dart:32`) and `PipNest.growthFraction` (`pip_nest.dart:17-18`).
Fix: move the file to `app/lib/features/kid_home/domain/kid_growth.dart` to
match `next_payout.dart`. If the orchestrator wants zero cross-feature domain
imports, the right move is a SHARED_REQUEST relocating `evolveAtCoins` into
`core/` (it is a cross-screen constant) — that touches `core/**` and is
outside this screen's edit set, so it is not a K05 fix.

### 3. minor — a duplicated, misattached `hide PipMood` comment
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:38-44`
The same two-line comment appears twice: once above the `nest_assets` import
(where `PipMood` is irrelevant) and once above `design_system.dart` (where it
explains the `hide`). Fix: delete the copy at lines 38-39.

### 4. minor — `_kCardPadV` doubles as the Pip's top margin
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:74`
(reused at `:352` for the stage height and `:388` for the Pip margin)
`.k5-pip { margin: 14px 0 2px }` and `.k5-card { padding: 14px 16px }` are
unrelated declarations that happen to share 14; a future edit to the card
padding would silently move Pip. Fix: add
`const double _kPipMarginTop = NestSpacing.gap14;` and use that at `:352`/`:388`,
leaving `_kCardPadV` to the card only.

### 5. minor — the three non-loaded kid states and the lock button are copied into a fourth view
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:154-316`
(`_KidLoading`, `_KidFailure`, `_NoActiveChild`, `_TopBar`) and `:610-634`
(`_GateLockButton`)
K05 is a near-verbatim copy of `kid_home_view.dart:158-334,632-668`,
`quest_detail_view.dart:206-443,851-880` and `kid_pin_view.dart:356-520` — a
4th copy of the three state screens and a 6th `_GateLockButton`. The
duplication predates K05 and K05 followed the established pattern, so it is
not a K05 defect; but each future fix (e.g. the K03 review's child-aware
failure card) now has six landing sites and a missed one is a silent
divergence between kid screens.
Fix: extract `KidLoadingState` / `KidFailureState` / `KidNoChildState` /
`GateLockButton` into
`app/lib/features/kid_home/presentation/widgets/kid_common_states.dart` and
have the six views use it. That file is inside RULES §1, but it edits K02/K03/
K04 view files, so it must land as a single orchestrator batch after all six
`kid_home` screens merge — not inside this screen's loop.

### 6. minor — the geometry test matches literal colours instead of tokens
`app/test/features/kid_home/quest_complete_geometry_test.dart:59,74`
`_barSurface()` matches `0xFFFFFFFF` and `_growthCardSurface()` matches
`0xFFEEEBFF`; `quest_complete_view_test.dart:220-248` resolves the same two
surfaces from `Theme…extension<NestTokens>()`. The literals will silently match
**nothing** if a token changes, and they cannot be reused for the dark
geometry. Fix: resolve both colours from `NestTokens` as the view test does,
and move the two finders into one shared test helper so the two files cannot
drift.

### 7. minor — dead arithmetic hides the bar-height intent
`app/test/features/kid_home/quest_complete_geometry_test.dart:215`
`expect(barSurface.height, 3 + 12 + 64 + 10 + NestDevice.homeH - 34)` reduces
to `89`, because `NestHomeIndicator` returns `SizedBox.shrink()` when
`NestStatusBar.showMockGlyphs` is false (`nest_chrome.dart:225`). The
`+ NestDevice.homeH - 34` terms are a no-op that implies the 34 px inset is
still being added. Fix: assert `89` and put the reason in the `reason:`
string ("border 3 + pad 12 + button 64 + its 6 px shadow room + pad 4; the
mock home indicator collapses to zero, the real inset comes from `SafeArea`").

### 8. minor — the growth percentage is announced twice
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:518-521`
The card node's label ends with `'$percent percent.'`, and `NestProgress` adds
`value: '${…} percent'` on its own node (`nest_progress.dart:66-68`), so
VoiceOver reads "… Next Songbird. 70 percent." then "Pip is 70% of the way to
Songbird, 70 percent". Fix: drop the trailing `'$percent percent.'` from the
card label — the progress node already carries the figure and the design's own
`aria-label` — and keep the headline/count/next collapse.

### 9. minor (low) — `BlocBuilder` without `buildWhen` rebuilds both Pips on any emission
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:131`
Any `KidHomeState` emission rebuilds `_QuestCompleteBody`, including two
`PipAvatar`s (one 218 px, Rive/SVG-backed) and the burst SVG. Emissions are
rare (load, child switch, completion) so this is not a storm, and it matches
K03/K04. Fix if it ever shows up in a profile: add
`buildWhen: (p, c) => p.status != c.status || p.child != c.child ||
p.items != c.items`.

## Verdict

The screen meets the brief: feature-first layering, tokens-only styling,
design-exact geometry, DB-driven data, full accessibility actions, clean
analysis/format/tests, and no file outside RULES §1. All nine findings are
cosmetic, structural or test-hygiene nits that can land in a later iteration —
none is a blocker or a major.

VERDICT: PASS