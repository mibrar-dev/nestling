# P08b · Today empty — QA code review (Stage 4, iteration 1)

Scope: `git diff main...HEAD` on branch `screen/P08b` (5 app files + docs),
reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md` (§1 scope,
§4 data contract, §7 done criteria), `docs/DESIGN_SPEC.md` §5 P08b,
`docs/design/SPACING_SPEC.md` §2/§3/§5, `design/html-source/screens/P08b-today-empty.html`
+ `components.css`/`tokens.css`, the design system as used, the loop's
orchestrator rules (PIP, COPY, CHILD ORDER, BOTTOM EDGE, CLOCK, FONTS,
LETTER SPACING, a11y actions), and `docs/screens/P08b/ORCHESTRATOR_NOTES.md`.

Iteration 1 delta: one bloc line, four UI widgets (`_EmptyGreeting` new,
`_EmptyCard` rewritten, `_TipCard` new, `emptyMessageSuffix` new), a view
doc-comment, and two test files. No code was edited by this stage.

## Gates re-run independently on `main...HEAD`

```
dart format --set-exit-if-changed lib/features/today test/features/today/{today_bloc_test,today_view_test}.dart   → 17 files, 0 changed, exit 0
flutter analyze                                    → No issues found!, exit 0
flutter test --timeout 120s test/features/today/today_bloc_test.dart \
    test/features/today/today_repository_test.dart → +35: All tests passed!
flutter test --timeout 120s test/features/today/today_view_test.dart \
    test/features/today/today_semantics_tap_test.dart \
    test/features/today/p08_bugs_test.dart         → +77: All tests passed!
grep added lines for Colors./Color(0x/fontFamily/google → none
grep added lines for ignore:/skip:                    → none
```

Independent PNG measurement (design vs app screenshot, logical px):
title ink top **53 → 61**, empty-card top **121 → 129** — confirms the UI
stage's numbers below. Underline pixel scan: design sky `(37,99,214)` light /
`(127,169,255)` dark vs app ink `(30,27,58)` / near-white.

**Result: 0 blockers, 4 majors, 4 minors. VERDICT: FAIL.**

---

## Findings

### 1. MAJOR — the empty-state date line shows “Happy week: 4 days” instead of “A fresh nest” on the mandated seed

`app/lib/features/today/presentation/bloc/today_bloc.dart:65-66`

```dart
dateLine:
    '${formatLondonDay(now)} · ${summaries.isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}',
```

The view's empty branch is `state.items.isEmpty || state.summaries.isEmpty`
(`today_loaded_body.dart:264`), but the suffix is gated on `summaries.isEmpty`
only. With `Seed.newFamily` — the seed every P08b UI check uses
(ORCHESTRATOR_NOTES (03:25)) — there are children (summaries non-empty) and no
quests (items empty), so the P08b card renders while the date line reads
`Sat 3 Oct · Happy week: 4 days` (both PNGs and HTML line 13 say `A fresh
nest`). Reproduced in the stage-5 screenshots:
`docs/screens/P08b/ui/app_light_1.png` reads “Mon 5 Oct · Happy week: 4 days”.

Fix: use the same predicate in the bloc:

```dart
final isEmpty = items.isEmpty || summaries.isEmpty;
// … '${formatLondonDay(now)} · ${isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}'
```

P08 cannot move (its demo seed always has items). Add the missing
`blocTest` case (items empty + summaries non-empty) and a `Seed.newFamily`
widget assertion.

### 2. MAJOR — the whole empty body sits 8 px too low; a uniform vertical shift the UI-verdict rule fails

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:763-764`

```dart
return Padding(
  padding: const EdgeInsets.only(top: NestSpacing.s2),
```

The 8 px `padding-top` belongs to **P08's** screen-local rule
(`P08-today.html:3`, `.greet{padding-top:8px}`); P08b's `<style>` block styles
only `.greet h1` and `.greet .date` and has **no** padding. The design formula
is `121 = 47 + 34 + 2 + 22 + 16` (card top), and the populated P08 greeting
already keeps its own padding in `_Greeting`. Measured (design → app):
greeting h1 box top `0 → 8` (scroll-relative), empty-card top `121 → 129`,
tip card also +8; the tab bar is exact so this is body-only. Fix: drop the
top padding from `_EmptyGreeting` only.

### 3. MAJOR — the new message names children in age order, violating the mandatory CHILD ORDER ruling

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:279`
(`_EmptyCard(names: state.summaries.map((s) => s.nickname).toList())`) and the
doc comment at `:794-797`, fed by the re-sort at
`app/lib/features/today/data/today_repository_impl.dart:84-89`:

```dart
// Eldest first (Maya 9 before Leo 6 in the demo), then nickname.
..sort((a, b) { … age desc, then nickname … });
```

`watchChildren` is documented creation order (`createdAt`, then `rowid`) — the
schema comment says “Roster order is creation order everywhere (CHILD ORDER
ruling)” — but `watchSummaries` overrides it by age, with an alphabetical
tiebreak. For a family whose second child is older, the copy reads in age
order; equal ages fall back alphabetically (both forbidden). For the two seeds
in play (Maya 9 added before Leo 6) the order happens to coincide, which is
why it was not caught earlier.

Fix (inside the today feature, RULES §1): drop the `..sort(...)` so
`kids.map(...)` preserves `watchChildren` creation order; update the stale
“Eldest first” comments at `today_repository_impl.dart:84` and
`today_repository_test.dart:306`. Demo/new-family rendering does not move.

### 4. MAJOR (a11y) — the greeting is clipped, not wrapped, at large text scales

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:771-776`
(`maxLines: 1`, `overflow: TextOverflow.ellipsis`)

P08b's `.greet h1` carries **no** `white-space: nowrap` (that is P08's rule,
`P08-today.html:5`); `components.css:43` gives `h1 { overflow-wrap: anywhere }`
so the design wraps. At 320 px width or 1.3× text scale on 390 px,
“Good morning, Sarah” exceeds one line and paints “Good morning, Sa…” — the
parent's name is lost for large-text users. Fix: allow two lines (keep the
ellipsis as a last resort) or render with `NestBalancedText`; copy and
`NestType.h1` unchanged.

### 5. MINOR — the “Browse ideas” row is 46 px; the design's is 44

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:865-866`
(`Padding(vertical: NestSpacing.s3)` = 12 + 22 + 12)

`.linkrow a { min-height: 44px }`, so the design card is exactly 434 tall
(121 → 555); the app's link row adds 2 px, drifting the card bottom to 556 on
top of finding 2. Fix without a magic number: replace the vertical padding
with `ConstrainedBox(minHeight: NestDevice.tapParent)` around the centred
22 px glyph (44 exactly, tap floor kept).

### 6. MINOR — the tip card adds a 4 px gap the design does not have

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:896`
(`spacing: NestSpacing.s1`)

`tokens.css:201` is `* { margin: 0 }`, so the `.body-s` and `.caption` boxes
**touch**: 16 + 22 + 36 + 16 = 90, which is exactly what the PNG shows
(571 → 661, pixel-verified). The app's tip card is 94 tall. Fix: drop the
`spacing` on `_TipCard`'s column.

### 7. MINOR — the “Browse ideas” underline paints ink, not sky

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:869-870`

```dart
style: NestType.bodySmallStrong(color: tokens.sky)
    .copyWith(decoration: TextDecoration.underline),
```

`decorationColor` is null, so the engine falls back to the ambient ink: pixel
scan shows the app underline at ink `(30,27,58)` light / near-white dark while
the design PNG's underline row is solid sky `(37,99,214)` / `(127,169,255)` —
zero dark pixels in the design. Fix: add `decorationColor: tokens.sky` (the
same pattern already used at `create_account_view.dart:545-546`).

### 8. MINOR — committed regression coverage does not pin three of the fixed behaviours

`app/test/features/today/today_view_test.dart:896-897` asserts only
`link.height >= 22` (the glyph box) — not the 44 px tap row, the underline
colour, the `new_family` date line, or a `performAction(SemanticsAction.tap)`
for the two P08b controls (loop rule: every control's tap action must be
proven; plan §f items 7–8). The 320/1.3 test also never asserts the tap area.
Fix: land assertions for findings 1, 5 and 7 together with their fixes and add
the two semantics-action proofs for `Add a quest` / `Browse ideas`.

---

## Verified correct (not findings)

- **Scope (RULES §1)**: only `app/lib/features/today/presentation/**`,
  `app/test/features/today/**`, `docs/screens/P08b/**` touched. No `core/`,
  no `app/`, no router/seed edits (the shell move and `Seed.newFamily` landed
  on main, merged at `eac2f66`).
- **Architecture**: domain untouched (entities + abstract repo only); one bloc
  line changed; DI factory and per-feature routes unchanged; no new folders.
- **Design-system usage**: zero added literal colours/sizes/fonts (grep-verified);
  `NestCard` (standard + inset), `NestButton`, `PipAvatar`, `Semantics`,
  `NestSpacing`/`NestType` reused. `NestEmptyState` deliberately not reused —
  its h3 title (18 vs the design's 22), 160 art box (vs 140) and 24/16 insets
  (vs 28/20) genuinely differ from `.empty-card` (SPACING_SPEC §5), so this is
  a screen-specific variant, not a re-implementation.
- **PIP rule**: `PipAvatar(style: mochi, stage: 1, size: 140)`; `skin`
  defaults to `PipSkin.sunny` → satisfies the childless/onboarding rule; no v1
  `pip_stage_*` SVG; design size/position kept.
- **Copy**: tip body and message byte-exact vs HTML (em dash U+2014, curly
  quotes U+201C/U+201D, en dash U+2013, middle dot U+00B7), verified bytewise;
  UK spelling throughout; the two-sentence message is DB-derived (no hard-coded
  names).
- **One empty state**: `/today` and `/today-empty` share `TodayLoadedBody`
  (orchestrator item 1); no `TodayEmptyLoadedBody`; empty greeting has no `+`
  and no avatar (confirmed in both screenshots).
- **A11y**: both controls expose tap (`NestButton` Semantics + the link's
  `Semantics(button, excludeSemantics, onTap:)` mirror); Pip art is an
  `image` node labelled exactly like the HTML `alt` (“Pip the bird as a
  speckled egg”) with no tap action; greeting is a `header`.
- **Performance / streams**: widgets stay stateless, `const` used; no new
  streams, timers or controllers; bloc disposal unchanged; no rebuild storm.
- **Error handling**: loading/failure paths untouched; retry re-adds only
  `TodayLoadRequested`; raw error never on screen.
- **Children's Code**: no analytics/ads/tracking added; nickname only, no
  child data leaves the device.
- **Bottom edge / shell**: tab-bar surface runs to the physical edge in both
  themes; design PNG's old tint strip is overridden by the owner rule; tab bar
  top exact (727) in the stage-5 measurements.
- **Clock/fonts/letter-spacing**: no `DateTime.now()`; no `google_fonts`; no
  new `letterSpacing` (dateLine correctly tracking-free).

VERDICT: FAIL
