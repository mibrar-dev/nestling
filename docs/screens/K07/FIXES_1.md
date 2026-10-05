# Fix list after iteration 1

## From 4_review.md
# K07 · QA CODE REVIEW (iteration 1) — stage 4

Scope: `git diff main...HEAD` — 11 lib files in `app/lib/features/pip/**` + 5 test
files in `app/test/features/pip/**`, plus this folder (32 files, +3770/−46).
Reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 K07 (`docs/DESIGN_SPEC.md:202`),
`docs/design/SPACING_SPEC.md`, `design/html-source/screens/K07-evolution.html`,
`design/html-source/components.css` + `tokens.css`, both design PNGs, the design
system in `app/lib/core/design_system/`, and the already-committed UI shots in
`docs/screens/K07/ui/`. **No code was edited** and **no simulator was booted,
installed on or driven** (stage 5 owns `BC440E48-B3A3-43BC-971B-0EF5DB621874`).

## Verdict summary

**3 major, 9 minor, 2 notes.** The two majors are both *visible to a child or a
designer*:

| # | Severity | Summary |
|---|---|---|
| 1 | **MAJOR** | Every sparkle is painted **without its top point** — `Path.moveTo` + `Path.addPolygon` starts a *new* sub-path, so the design's `M` vertex is dropped. The mandatory `ORCHESTRATOR_NOTES` D2 item is therefore **not** delivered (the `d` strings are verbatim; the parsed path is not). |
| 2 | **MAJOR** | `PipStatus.loaded` is published by *either* stream, so `/pip-evolution` shows the failure card “Oh no! Pip got lost.” (with a dead “Try again”) on **5 of 5** cold opens with the shipped repository; `/pip` has the mirror defect. |
| 3 | **MAJOR** | `flutter analyze` and `dart format --set-exit-if-changed` are **red** in the worktree (RULES §7.1). |

## Gates re-run by this stage (no simulator)

```
$ flutter analyze
Analyzing app...
 info • Unnecessary duplication of receiver … test/features/pip/pip_evolution_bloc_test.dart:391:7 • cascade_invocations
1 issue found. (ran in 3.9s)                       <-- RED (finding 3)

$ dart format --output=none --set-exit-if-changed .
Changed test/features/pip/k07_sparkles_bug_test.dart
Formatted 610 files (1 changed) in 1.97 seconds.     <-- RED (finding 3)
```

Test evidence (`--timeout 120s` every run; run in subsets because one combined
7-file invocation never finished inside 15 minutes while three other screen
loops were running their suites on this machine — see “Observation 2”):

```
flutter test test/features/pip/pip_evolution_widget_test.dart      → +24:  All tests passed!
flutter test test/features/pip/pip_evolution_view_test.dart
                   test/features/pip/pip_evolution_repository_test.dart
                   test/features/pip/pip_evolution_bloc_test.dart     → +49 ~1: All other tests passed!
flutter test test/features/pip/pip_evolution_a11y_test.dart
                   test/features/pip/pip_evolution_copy_test.dart
                   test/features/pip/pip_evolution_sparks_test.dart
                   test/features/pip/k07_bugs_test.dart
                   test/features/pip/k07_sparkles_bug_test.dart       → +54 ~6: All other tests passed!
```

The 7 skips are the parked bug proofs (`K07-BUG-1` ×2, `K07-BUG-2`,
`K07-BUG-SPARK-1` ×3, plus one stage-3 pin) — the loop’s convention, and the
right one: findings 1 and 2 are exactly what those parked proofs describe, so
**fixing the code must un-skip them in the same commit** (see each finding).
No test fails. The K07 suite is otherwise substantial and healthy
(≈127 test cases): repository contract, bloc interleavings, real navigation
through VoiceOver actions, both themes, geometry pins at 390×844, the
320/390/430 × text-scale-1.0/1.3 fit matrix, the stage-1 degenerate case, the
320 px stage-slot overlap, and a pixel-rasterised silhouette check of the
sparkles. Every pumped app test ends with `disposeApp(tester)`; the two files
that pump a bare widget tree without the app scope (`pip_evolution_sparks_test.dart`,
`k07_sparkles_bug_test.dart`) open no Drift database, so none is owed.

## ORCHESTRATOR_NOTES.md — all three mandatory items re-checked against the code

- **D2 “sparkles: the exact HTML 4-point path at the 4 spots, token fills, ink
  3 px stroke” — NOT met.** The four `d` strings are verbatim
  (`pip_evolution_sparks.dart:70-89`), the token fills are
  `_SparkFill → tokens.lilac/success/coin/peach/sky`
  (`pip_evolution_sparks.dart:60-66`) and the stroke is `tokens.ink` at
  `EvolutionSparksGeometry.strokeWidth = 3` with round joins
  (`:136-141`). But the *painted geometry* is not the HTML path — finding 1.
  The `d` strings being present is what made the earlier reading “already
  implemented” look true; the pixels say otherwise, and finding 1 carries the
  measurement.
- **D3 bubble tail — accepted (18×9, shared `NestSpeechBubble`), not a
  finding.** Recorded as resolved.
- **D1 the “Fledgling” wrap shifting the stack by +34 px — accepted (DB
  truth).** Re-measured from the committed shots for this review (see the note
  for `5_ui` below); no code action.

## What was checked and found sound

- **RULES §1 file scope** — the diff touches only
  `app/lib/features/pip/{domain,data,presentation}/**`,
  `app/test/features/pip/**` and `docs/screens/K07/**`. No `core/**`, no
  `app/**`, no other feature, no `tools/screens/**`, no `analysis_options`
  change, no schema/seed/DI/route edit.
- **ARCHITECTURE.md** — feature-first shape intact. Domain gains one Equatable
  entity (`pip_evolution.dart`) plus one abstract `watchEvolution()`; the
  mapping and the private `_switchMap` stay in `data/pip_repository_impl.dart`.
  No use-case classes, no new folders, `package:nestling/...` imports only, and
  no `domain/` presentation code (`pipStageName` correctly lives in
  `presentation/widgets/pip_look.dart`, not in the entity). One bloc per
  feature, `PipLoadRequested` unchanged, and `pip_routes.dart` already provides
  the bloc — nothing in `di.dart`/`router.dart` was touched and none was needed.
  The `kid_home_routes.dart` / `parental_gate_routes.dart` route-constant
  imports are the established pattern (and pre-date this diff).
- **Component reuse (no re-implementation)** — `NestStatusBar`,
  `NestHomeIndicator`, `NestLockButton`, `NestKidButton`, `NestSpeechBubble`,
  `NestBalancedText`, `NestType.*`, `NestRadii.*`, `NestSpacing.*`,
  `NestKidStarsPainter`, `NestIcon.arrowRight`, `PipAvatar`. The stage-name
  table and the style/skin/accessory mappers are K06’s existing
  `pip_look.dart` helpers, not a second copy — good call, the two screens
  cannot disagree. Screen geometry lives in four documented
  `abstract final class …Geometry` holders whose constants each cite their
  `K07-evolution.html` line, and every one of them resolves to a token value I
  re-checked (`gap2`=2, `s1`=4, `s2`=8, `s6`=24, `gap6`=6, `s3`=12,
  `gap10`=10, `padSide`=20, `s4`=16, `s8`=32).
- **Tokens only, no hard-coded colours/sizes/fonts** — `rg` over
  `lib/features/pip` finds **zero** hex/`Color(0x…)` literals in code (the only
  hex strings are inside comments citing the HTML), zero `letterSpacing`
  additions (`.kid-title` sets none), no `google_fonts`, no
  `DateTime.now()`, no `print`/`debugPrint`, no `£`, no network/analytics
  symbol anywhere in the feature. The two CSS-only sizes (`.k7-stats b` 30/34,
  `span` 14/18, `K07-evolution.html:29-30`) are applied at the call site
  exactly as the LETTER SPACING ruling prescribes, with the source line cited.
- **Typography matches the CSS, including the trap** — `.k7-hero` is a
  screen-local class that sets only `text-align`/`overflow-wrap`
  (`K07-evolution.html:24`); the type comes from `.kid-title`
  (`components.css:36`) = Nunito 900 **28/34**, which is what `NestType.kidTitle`
  is. (The global `.kid-hero` 40/44 does not apply — no such class on this
  element.) `.kcap` = 15/20 w700 ink-2 = `kidCaption` exactly.
- **BALANCED HEADINGS** — `.kid-title` carries `text-wrap: balance`, so the hero
  uses `NestBalancedText` with the same copy, style and `maxLines`
  (`pip_evolution_view.dart:332`); the `.kid-body` sub, the bubble and `.kcap`
  correctly do **not**.
- **COPY vs the HTML, byte for byte** — the design writes a **literal ASCII
  `0x27`** apostrophe in `Pip’s` (line 57), and the code matches it
  (`pip_evolution_copy.dart:12-16`, `49-50`). Stage-4 strings are
  byte-identical to lines 55/57/63/66 and 59-61. Demo (Maya, stage 3 from the
  DB) → `Pip grew into a Fledgling!` / `Because you helped 4 times` /
  `Flap, flap! Look at Pip's wings!` / `4 · 175 · 3` / `Meet Fledgling Pip` /
  `Pip still loves a chin scratch.` — DB-driven per DATA OVER MOCKS, and the
  repository count really is `done_pending` + `approved` all time (4 for Maya,
  verified against `Seed.demo`). UK spelling; no red; no nagging.
- **ORCHESTRATOR PIP rule** — both slots render the child’s **own** Pip with
  `PipAvatar` from `pip_style`/`pip_skin`/`pip_accessory` at the DB stage, with
  only the design’s slot geometry kept (`pip_evolution_stage.dart:82-88`); no
  `pip-stage-*.svg` anywhere; the loading/failure/no-child cards use
  `PipAvatar(mochi, sunny)` when no child is known.
- **BOTTOM EDGE (owner rule)** — `_EvolutionBar`
  (`pip_evolution_view.dart:391-427`) puts the surface `Container` **outside**
  the `SafeArea(top: false)`, so the surface runs to the physical edge in both
  themes and the 34 px inset sits inside it. Confirmed in the committed dark
  shot too: no glow strip under the bar, no tint around the home indicator.
- **ALIGNMENT (owner rule)** — one 20 px gutter for the lock row, the scroll
  content, the three stat cards (x 20/140/260, `right == 370`) and the CTA; the
  bar and the cards share the same edges. Nothing is a few px off.
- **Accessibility** — every interactive node is a shared, `onTap`-bearing
  widget: `NestLockButton(semanticLabel: 'Grown-ups')` (the design’s
  `aria-label`), `NestKidButton` for CTA / retry / choose. The two
  `excludeSemantics` nodes are non-interactive (the merged stat sentence; the
  decorative silhouette/arrow/sparks), so no `onTap:` is owed. The new Pip is
  `Semantics(image: true, label: "Maya's Pip, a fledgling")`; the old Pip,
  arrow and sparks are `ExcludeSemantics` (HTML `alt=""` / `aria-hidden`).
  Tests assert `hasAction(SemanticsAction.tap)` on every control and drive the
  real navigation with `performAction` (CTA → `/pip`, lock →
  `/parental-gate`, retry re-subscribes, choose → `/who-is-playing`). Tap
  targets: lock 56, CTA ≥ 64 — all above the kid 56 minimum.
- **Performance** — `BlocBuilder` sits at the screen root, but K07 has no
  per-frame state: no timers, no animation controllers (RULES §6 compliant),
  and nothing re-adds load events. The background/sparks subtrees are `const`
  instances, so a state change does not repaint them; both painters key
  `shouldRepaint` on the tokens they use. `close()` awaits both cancels and
  nulls the fields (`pip_bloc.dart:195-201`); `_switchMap` cancels the inner
  subscription on every outer emission. `watchEvolution()` combines two tables
  and re-emits on any profile/completion/active-child change — no reload events
  needed. The one avoidable per-paint allocation is finding 11.
- **Error handling** — each stream releases only its *own* subscription on
  error, so “Try again” genuinely re-subscribes (pinned by a passing test with
  both Dart failure-delivery shapes), and a mid-session error keeps the loaded
  screen instead of blanking it. The model underneath has one hole — finding 2.
- **Children’s Code** — kid mode only: no analytics, no ads, no network, no
  identifiers, no `£`, no red, no timers or countdowns, no nagging, no loss
  framing, nothing logged and nothing transmitted. Failure copy is kind
  (“Oh no! Pip got lost.” / “Let’s try again.”) and never shows a raw
  exception. Findings 1 and 2 are tone problems here: a wrong sparkle set and a
  wrong error card on a celebration screen.
- **KID BACKGROUND deviation — correct on the evidence, now requested in
  writing.** `1_plan.md` §0 and `SHARED_REQUEST.md` §1 document it and I
  re-checked the claim: `K07-evolution.html:16` replaces `.screen.kid`’s
  background with `--kid-stars` + a lilac `radial-gradient(118% 62% at 50% 36%)`,
  the K07 body contains **no `.meadow` element** (the `.meadow` rules at lines
  7-9 are dead boilerplate), and both PNGs show no sky and no hills. The
  screen paints the CSS ellipse exactly (`_EvolutionGlowPainter` — a
  `RadialGradient` in a `BoxDecoration` genuinely cannot express explicit
  `118% 62%` radii, so the canvas scale trick is the right call) and mounts the
  **shared** `NestKidStarsPainter` in dark only. Not a finding; the orchestrator
  just needs to record the exception so a later iteration does not “fix” it to
  `KidScope`.

## Findings

### 1. MAJOR — every sparkle is painted without its top point (`addPolygon` orphans the `moveTo`)

`app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:168-179`
(specifically the `moveTo` on `:174` and `addPolygon` on `:175`)

```dart
return Path()
  ..moveTo(numbers[0], numbers[1])                       // 174: (32, 30) — the design's TOP POINT
  ..addPolygon(<Offset>[
    for (var i = 2; i + 1 < numbers.length; i += 2)      // 175: starts at the SECOND vertex (37, 44)
      Offset(numbers[i], numbers[i + 1]),
  ], true);
```

`Path.addPolygon` is documented as “**Adds a new sub-path** … If `close` is
true, a final line segment will be added that connects the last point to the
first point” (`$FLUTTER/bin/cache/pkg/sky_engine/lib/ui/painting.dart:3074-3081`).
It starts its **own** contour at `points.first` — it does not continue from the
current point — so the pending `moveTo` is discarded and `close` returns to
`(37, 44)`, not to `(32, 30)`. The design’s first vertex is silently dropped and
each sparkle is painted as a 7-gon with a flat top.

Measured on the committed shots (`docs/screens/K07/ui/app_light_1.png` vs
`design/screens/light/K07-evolution.png`), ink-stroke bounding box per sparkle,
device px (logical ÷ 3):

| sparkle | design | app | delta |
|---|---|---|---|
| 1 lilac (`M32 30 …`) | x 95..216, y **407..528** (122 × 122) | x 95..216, y **449..528** (122 × **80**) | top 42 px (14 logical) missing |
| 2 green | x 935..1056, y 389..510 (122 × 122) | x 935..1056, y 431..510 (122 × 80) | same |
| 3 coin | x 60..174, y 761..882 (115 × 122) | x 60..174, y 803..882 (115 × 80) | same |
| 4 peach | x 1001..1109, y 767..888 (109 × 122) | x 1001..1109, y 809..888 (109 × 80) | same |

The widths are **identical** and the bottom edges are **identical**: the shape
lost exactly its top arm and tip, which is the signature of the dropped vertex
(and the 3 px ink band across the new flat top confirms it is a stroked path
edge, not a canvas clip). The dark shot shows the same defect, and a 4×
zoom of the lilac sparkle puts the design’s sharp 4-point star next to the
app’s flat-topped chevron. This is UI-check item **D2**, which
`ORCHESTRATOR_NOTES.md` makes mandatory — the `d` strings are verbatim but the
painted shape is not, so the item is **not** satisfied.

Fix (one line, screen-local, RULES §1-legal — drop the separate `moveTo` and let
`addPolygon` take the `M` pair as its first point):

```dart
static Path _sparkPath(String d) {
  final numbers = RegExp(r'-?\d+(\.\d+)?')
      .allMatches(d.replaceAll(RegExp('[MZ]'), ' '))
      .map((m) => double.parse(m.group(0)!))
      .toList(growable: false);
  return Path()..addPolygon(<Offset>[
    for (var i = 0; i + 1 < numbers.length; i += 2)
      Offset(numbers[i], numbers[i + 1]),
  ], true);
}
```

This is also the moment to do finding 11 (cache the four `Path`s). Then drop the
three `skip: true` flags in `app/test/features/pip/k07_sparkles_bug_test.dart`
(`:158`, `:269`, `:378`) in the same commit — they are the proof, and the loop’s
convention is that the fix commit un-skips them. After the fix the sparkle tops
move **up** by 14 logical px onto the design’s coordinates, so `5_ui` should
re-measure the sparkle band.

### 2. MAJOR — `loaded` is published by either stream: `/pip-evolution` shows “Oh no! Pip got lost.” on 5 of 5 cold opens, with a dead “Try again”

`app/lib/features/pip/presentation/bloc/pip_bloc.dart:43-102`,
`app/lib/features/pip/presentation/bloc/pip_state.dart:60-82`,
`app/lib/features/pip/presentation/views/pip_evolution_view.dart:86-96`,
`app/lib/features/pip/presentation/views/pip_nest_view.dart:81-90`

Before this diff `PipStatus.loaded` had exactly one producer (`watchNest`). It
now has two:

- `_onNestReceived` → `copyWithLoaded` sets `status: loaded` **even when
  `evolution` is still null** (`pip_state.dart:60-68`);
- `_onEvolutionReceived` → `copyWithEvolution` sets `status: loaded` even when
  `nest` is still null (`:74-82`).

So `status` no longer means “this screen’s data is here”, it means “one of the
feature’s two streams said something”, and neither view can tell “my stream has
not emitted yet” from “my stream failed”. `/pip-evolution` infers failure from
the sibling stream (`pip_evolution_view.dart:94-95`):

```dart
final nest = state.nest;
if (nest != null) return _EvolutionFailure(profile: nest.profile);   // line 95
```

That window is the normal first loaded frame, not a corner case:
`PipLoadRequested` subscribes nest-first by construction
(`pip_bloc.dart:51` then `:60`), both streams start from the same
`watchAppState()` emission, and `watchEvolution()` combines two tables while
`watchNest()` combines the profile, the wardrobe rows and the ordered stages.
`6_bugs.md` K07-BUG-1 measured it over the real `PipRepositoryImpl` with the
demo seed: **nest lands first, 5 of 5 cold opens published `loaded` before the
evolution arrived**, and the frame-by-frame probe never caught it only because
the two emissions are 0.41 ms apart in the shipped timing. On a cold database,
a big `quest_completions` table or a busy isolate it paints — an alarming error
card on a celebration screen. If the evolution stream is slow or hung it stays:
the child sits on an error card whose only recovery control is dead, because
`pip_bloc.dart:49` (`if (_nestSub != null && _evolutionSub != null) return;`)
sees both subscriptions as live and drops `PipLoadRequested`.

`/pip` has the mirror defect (`pip_nest_view.dart:89` → `_PipFailure()` on a
pending nest stream), and the cross-guards added for it are exactly what a
per-stream flag makes unnecessary.

Fix (all in `features/pip/**`, in scope for this branch):

1. Track arrival per stream: add `bool nestSettled` / `bool evolutionSettled`
   to `PipState`, set in `copyWithLoaded` / `copyWithEvolution` and in
   `PipNestFailed` / `PipEvolutionFailed`, and carry both through every other
   `copyWith*` helper and `props`. Give each stream its own error slot too
   (finding 10).
2. Gate each view on **its own** stream: spinner while
   `!mySettled && myError == null`, body once my data is present, failure card
   only on my own error. Delete `pip_evolution_view.dart:94-95` and
   `pip_nest_view.dart:89` — with per-stream flags they are both unnecessary
   and wrong.
3. Un-skip the parked proofs in the same commit:
   `app/test/features/pip/pip_evolution_bloc_test.dart:380` (state level) and
   both `K07-BUG-1` proofs in `app/test/features/pip/k07_bugs_test.dart`.

### 3. MAJOR — `flutter analyze` and `dart format` are red

- `app/test/features/pip/pip_evolution_bloc_test.dart:391:7` —
  `info • Unnecessary duplication of receiver. Try using a cascade to avoid the
  duplication • cascade_invocations` (in the parked `K07-BUG-1` test:
  `bloc.add(…)` followed by `repo.nest.add(…)`). Fix: use a cascade
  (`bloc..add(const PipLoadRequested());` then the rest) or reorder so there is
  no repeated receiver.
- `dart format --output=none --set-exit-if-changed .` → `Changed
  test/features/pip/k07_sparkles_bug_test.dart`. Fix: `dart format app` (the
  file was written after the last format pass).

RULES §7.1 requires both clean with no ignores, so neither may ship. Cheap, but
it is a red gate for every later stage.

### 4. MINOR — `/pip-evolution` subscribes to K06’s stream it never renders

`app/lib/features/pip/presentation/bloc/pip_bloc.dart:47-69`

`PipLoadRequested` opens **both** `watchNest()` and `watchEvolution()`, so on the
K07 route the nest stream (child row + wardrobe rows + the ordered-stage
`combineLatest2`) is opened, watched and thrown away — three extra Drift table
watches per screen entry for data no widget on that route reads.
ARCHITECTURE.md mandates exactly one `<Feature>LoadRequested`, which is why the
branch did not change it; `SHARED_REQUEST.md` §2 asks for the ruling. Not a
correctness defect — accepted as-is until the orchestrator rules.

### 5. MINOR — the bottom bar renders empty, with a 3 px ink rule, on the three non-design states

`app/lib/features/pip/presentation/views/pip_evolution_view.dart:391-421`
(border at `:393-401`, empty band at `:414-415`)

On loading / failure / no-child, `stage` is null, so the CTA becomes
`SizedBox(width: double.infinity)` and the bar is a ~53 px surface strip with a
full-width 3 px ink top border and nothing on it — a rule across the screen
that reads as a broken button row. Fix: build the `Border` only when
`stage != null` (keep the surface box: the BOTTOM EDGE rule still needs it), so
the three states get a plain surface band, or mirror K06’s `_PipChrome`, whose
failure card has no bottom bar at all (`pip_nest_view.dart:148-189`).

### 6. MINOR — two apostrophe styles (and two ellipsis styles) in one screen

`app/lib/features/pip/presentation/views/pip_evolution_view.dart:165` and `:214`

`'Loading Pip’s big moment'` uses `’` (U+2019) while `"Let's try again."`
(line 214) and `"Who's playing?"` (`:250`) use ASCII `0x27`, and
`pip_evolution_copy.dart` deliberately uses ASCII throughout because the
design’s byte is ASCII. Both strings are non-design copy (a11y / K03 parity), so
the design is no oracle — but the two styles sit in the same file. Fix: pick one
convention for K07’s non-design copy (ASCII, to match `Pip’s` on the same
screen) or add one line to the `pip_evolution_copy.dart` header saying which and
why.

### 7. MINOR — stage-1 copy contradicts itself, and `Shh...` uses three ASCII dots

`app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart:47`
(speech for stage 1) vs `:34-35` (title pattern)

For a stage-1 child the hero reads `Pip grew into an Egg!` while the bubble says
`Shh... Pip is still growing!` — the screen announces a growth and then denies
it. Reachable: the committed view test drives `pipStage = 1`, and a reset seed
could hold a stage-1 child. Related: the invented `Shh...` uses three ASCII
dots where the COPY ruling’s character for an ellipsis is `…`. Fix: give stage 1
copy that agrees with the title (or suppress the bubble there) and use `Shh… `.

### 8. MINOR — three user-visible stat labels live outside the feature’s copy module

`app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart:82, 90, 98`

`'quests done'`, `'coins grown'` and `'of 4 stages'` are inline literals here,
while `pip_evolution_copy.dart:1-11` states that it is K07’s single copy table
with every string byte-checked against the HTML and cited by line. Fix: move them
into `pip_evolution_copy.dart` (`evolutionStatQuestsLabel()`,
`evolutionStatCoinsLabel()`, `evolutionStatStagesLabel()`) or state in that
module’s header why the stat labels are deliberately widget-local.

### 9. MINOR — dark-mode sparkle fills diverge from the dark PNG (token re-theme, needs a ruling)

`app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:60-66`

Measured centre-of-sparkle colours, dark theme, design vs app:

| fill | design (light **and** dark) | app dark | token dark |
|---|---|---|---|
| lilac | `#7C6CF2` | `#A89BFF` | `colors.lilac` dark |
| success | `#1F9D63` | `#3CC98A` | `colors.success` dark |
| peach | `#FF8A5B` | `#FF9E78` | `colors.peach` dark |
| coin / sky | `#F4B400` / `#3D7FF0` | matches | matches |

The K07 SVG hard-codes those fills inline, so the dark export keeps the light
values; the design system deliberately lightens accents on dark surfaces, and the
“tokens only, never hard-code colours” rule means the screen cannot match the PNG
without violating it. That is an orchestrator/UI-stage call, not a screen fix:
either accept the token re-theme (my recommendation — it is the design system
doing its job, and the same trade applies to every inline-SVG accent on every
screen), or file a SHARED_REQUEST for a literal-accent token. Do **not** hard-code
the hexes here.

### 10. MINOR — `PipState.errorMessage` is write-only in the `pip` feature

`app/lib/features/pip/presentation/bloc/pip_state.dart:88-101`

`withStreamError` records `error.toString()` and `toFailure` records it too, but
neither view reads it — the only message a pip view consumes is the `actionError`
toast (`pip_nest_view.dart:57-72`). Keeping raw DB text off a kid screen is
right; the field is written from two places and read from none, so the recording
is untested and unverifiable. Fix: fold into finding 2 — one error slot per
stream, which is exactly what a view needs to tell “failed” from “pending”.

### 11. MINOR — the sparkles re-parse their SVG path data on every paint

`app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:146-179`

`_sparkPath` compiles a `RegExp`, replaces `[MZ]`, runs `allMatches`, parses every
number and allocates a fresh `Path` — four times per repaint. The layer is
`const` and repaints only on a theme change, so the cost today is negligible,
but it is avoidable allocation on the render path for static art. Fix: build the
four `Path`s once (a `static final List<Path>` next to `_sparks`) and keep only
the token→colour lookup per paint. Do it in the same commit as finding 1 so the
file is touched once.

### 12. MINOR — at 320 px the grown 240 px Pip covers the “before” Pip and the arrow

`app/lib/features/pip/presentation/widgets/pip_evolution_stage.dart:97-142`

The slot’s three pieces are fixed-size and left/right-anchored:
`oldSize 68` at `left: 2`, `arrowSize 30` at `left: 76`, `newSize 240` at
`right: 6` — 352 px of content in a 280 px slot at a 320 px screen. Measured at
320 px: `arrow 96..126`, `grown Pip 54..294`, `old Pip 22..90` — the arrow sits
entirely inside the grown Pip’s box (−72 px; the design allows −2), so the one
thing the screen exists to show (before → after) is illegible at that width.
Fix: size the grown Pip as `min(240, slotWidth − oldSize − arrowSize − gaps)`,
or wrap the slot content in `FittedBox(fit: BoxFit.scaleDown,
alignment: Alignment.bottomRight)` so the 390 px geometry stays byte-identical
and the ±2 px budget survives. (`6_bugs.md` K07-BUG-2; the parked proof is
`k07_bugs_test.dart`.)

## Notes for the next stages (not findings)

1. **`5_ui` — D1 is exempt, and do not “fix” it.** The design PNGs are drawn at
   stage 4; the seeded active child is stage 3, and
   `"Pip grew into a Fledgling!"` is wider than the 350 px content box at real
   Nunito Black 28 px, so it wraps to two lines exactly as the browser would,
   pushing sub/speech/stats/caption **+34.0 px** below the PNG while the stage
   slot (y 105) and the bar (y 721) stay put. Measured from the committed shots
   (device px ÷ 3): title top design 376.3 / app 376.3 (Δ 0); first control
   (speech bubble) top design 463.0 / app 497.0 (Δ +34); card tops design 540 /
   app 574 (Δ +34, all three); caption design 649.3 / app 683.3 (Δ +34); bar top
   border design 721 / app 721 (Δ 0); CTA fill bbox identical (x 23–366.7,
   y 739–796.7). `ORCHESTRATOR_NOTES` D1 accepts this as DB truth — record the
   exemption, do **not** shrink the heading, add tracking or move the 20 px
   gutter (all three are ruled). Re-measure the sparkle band after finding 1.
2. **`flutter test test/features/pip/` can stall under load.** One combined
   7-file invocation never finished inside 15 minutes while three other screen
   loops ran suites on this machine; the same 7 files, split into two runs,
   finished in ~3 s each. That is machine contention, not a K07 defect (no K07
   test awaits real-async work in the fake-async zone), but the loop should keep
   a wall-clock cap on the directory gate. Not caused by anything in this diff.
3. **Order already logged by earlier stages, unchanged by this review:** nothing
   in the app links to `/pip-evolution` (deep link or `INITIAL_ROUTE` only);
   `4_review.md` finding 2 is now `SHARED_REQUEST.md` §2 and the background
   deviation is `SHARED_REQUEST.md` §1.


## From 5_ui.md
# K07 · Pip evolves (`/pip-evolution`) — UI check, Stage 5 iteration 2

Shots: `tools/screens/shot.sh` on the assigned simulator **BC440E48-B3A3-43BC-971B-0EF5DB621874** ("Nestling QA 2", 390×844), `SEED=demo APP_MODE=kid CHILD=maya THEME=light|dark`, `DISABLE_ANIMATIONS=1` (always injected by `shot.sh`).
Design: `design/screens/light|dark/K07-evolution.png` (1170×2532 = 390×844 @3x).
Copy reference: `design/html-source/screens/K07-evolution.html`.
All logical px below = device px ÷ 3. Bands/shots: `ui/app_{light,dark}_1.png`, `ui/cmp_{light,dark}_1.png`.
**No product code was edited by this stage.** No other simulator was booted, installed on or driven.

## Mean diff

| theme | mean diff | band 0 (0–105) | 1 (105–211) | 2 (211–316) | 3 (316–422) | 4 (422–527) | 5 (527–633) | 6 (633–738) | 7 (738–844) |
|---|---|---|---|---|---|---|---|---|---|
| light | **9.80 %** | 1.71 | 6.47 | 16.48 | 10.55 | 14.24 | 16.80 | 7.06 | 5.07 |
| dark | **8.94 %** | 1.57 | 6.61 | 13.89 | 8.87 | 13.59 | 15.84 | 6.47 | 4.65 |

Bands 1–2 are dominated by Pip art (exempt: DB stage 3 vs design stage 4, mandatory
per the PIP rule). Bands 3–5 carry the +34 px copy shift (D1) and the sparkle
defect (D2). Bands 6–7 measure ≤7 %, i.e. the bar/CTA region is clean.

## Measured matches — design vs app (logical px)

Verified row-by-row / column-by-column on both PNGs, light **and** dark
(structurally identical offsets in the two themes unless noted).

| element | design | app | Δ |
|---|---|---|---|
| lock glyph ink bbox | x 333.0–350.67, y 65.0–84.67 | x 333.0–350.67, y 65.0–84.67 | **0** |
| `.kid-bar` top border (full bleed) | y 721.0–723.7 | y 721.0–723.7 | **0** |
| CTA ink-border rect | x 20.0–369.67, y 736.0–799.67 | x 20.0–369.67, y 736.0–799.67 | **0** |
| CTA face colour | light `#6A58E8`, dark `#A89BFF` | light `#6A58E8`, dark `#A89BFF` | **0** |
| CTA top-left radius ramp (18 rows) | 41.67, 36.67, 34.0, 32.33, 30.67 … | 41.33, 36.67, 34.0, 32.0, 30.67 … | ≤ 0.34 |
| stat-card top-border straight runs | 30.0–120.0 / 150.0–240.0 / 270.0–360.0 | 30.0–119.7 / 150.0–239.7 / 270.0–359.7 | ≤ 0.33 |
| stat-card box height | 83.67 | 83.67 | **0** |
| stat-card top-left radius ramp | 34.0, 30.0, 28.0, 26.67, 25.33 … | 34.0, 30.0, 28.0, 26.67, 25.33 … | ≤ 0.33 |
| stat-card ink runs (inner edge, number, label, inner edge) | 548.0–549.0 / 564.67–586.0 / 599.0–611.0 / 624.67–625.67 | 582.0–583.0 / 599.67–620.67 / 634.33–646.0 / 658.67–659.67 | +34.0 each, **internal offsets and heights identical** (number h 21.33/21.0, label h 12.0/11.67) |
| stat-card label x extent | 20.0–129.67 | 20.0–129.67 | **0** |
| speech-bubble box | x 65.0–324.67, y 463.0–528.0 (h 65.0) | x 65.0–324.67, y 497.0–562.0 (h 65.0) | Δx **0**, Δy +34.0 |
| bubble face colour | light `#FFFFFF`, dark `#1F1C2E` | light `#FFFFFF`, dark `#1F1C2E` | **0** |
| bubble top-left radius ramp (14 rows) | 81.0, 76.67, 74.67, 73.0, 71.67, 70.33 … | 80.67, 76.67, 74.67, 73.0, 71.67, 70.67 … | ≤ 0.67 |
| title, first ink line | y 376.33–402.0 | y 376.33–402.0 | **0** |
| sub ink band | y 427.0–443.0 (h 16) | y 461.0–477.0 (h 16) | +34.0 |
| caption ink band / x extent | y 649.33–662.33, x 98.0–288.0 | y 683.33–696.33, x 98.0–288.0 | Δx **0**, Δy +34.0 |
| `.k7-arrow` paint (`--lilac-strong`) | x 99.67–121.0, y 307.0–324.67 | x 100.0–120.67, y 307.33–324.33 | ≤ 0.33 |
| gold dot, r 7 | x 100.67–111.0, y 111.67–122.0 | identical | **0** |
| sky dot, r 6 (light) | x 283.67–292.0, y 110.67–119.0 | identical | **0** |
| lilac glow (background) | light `#F8F7FF`, dark `#231F3B` | light `#F7F6FE`, dark `#221E3A` | ≤ 1 per channel |
| bottom edge, y 812 → 843 | design PNG shows glow `#EEEBFF` / `#2B2550` | `#FFFFFF` / `#1F1C2E` (uniform, single colour) | **owner-rule override — app is correct** (see below) |

Also confirmed: side gutters 20 everywhere; cards, caption, bubble and CTA share
the same left/right edges; no red/error colour anywhere; no overflow, clipping or
ellipsis (the title's second line, the 2-line bubble and all three labels fit
inside their boxes); no coloured strip anywhere between y 812 and the physical
edge in either theme.

**Bottom edge (owner rule) — PASS.** Sampled every row from y 812 to y 843
across x 5–385: light is a single uniform `#FFFFFF`, dark a single uniform
`#1F1C2E`, i.e. the bar's own surface runs to the physical screen edge and around
the home indicator. The design PNGs put the lilac glow there
(`#EEEBFF` / `#2B2550`) — the owner rule overrides the PNG, and the app is on the
right side of it. (The design's *own* bar interior at y 730–790 is `#FFFFFF` /
`#1F1C2E`, which is what the app paints everywhere.)

## Deviations

### D1 — the whole stack sits +34.0 px low (EXEMPT, orchestrator-accepted — not a finding)

The DB title is `Pip grew into a Fledgling!` (Maya is stage 3), which is one
glyph wider than the design's `Pip grew into a Songbird!` and greedily wraps to
two lines with a 34 px pitch. Everything below the title therefore moves down by
**exactly +34.0 px** and every gap is preserved:

| | design | app | Δ |
|---|---|---|---|
| title ink, line 1 | y 376.33 | y 376.33 | **0** |
| title ink, line 2 | — | y 410.33–436.0 | +34 (the extra line) |
| sub | y 427.0 | y 461.0 | +34.0 |
| speech bubble top | y 463.0 | y 497.0 | +34.0 |
| stat cards top | y 545.0 | y 579.0 | +34.0 |
| caption top | y 649.33 | y 683.33 | +34.0 |
| CTA / bar | y 736.0 / 721.0 | y 736.0 / 721.0 | **0** |

This is DB copy, forbidden from being hard-coded (DATA OVER MOCKS), and
`ORCHESTRATOR_NOTES.md:5` already rules it: *"D1 the Fledgling copy wrap shifting
the stack by 34: ACCEPT (DB truth)."* The screen title itself is **not** shifted
(Δ 0) — only the block below the extra line is — so this is not the "uniform
vertical shift of the whole screen" the UI VERDICT RULE targets. **No fix.**

### D2 — MAJOR — all four sparkles lose the design's top point (NOT FIXED)

Iteration 1's D2 was supposed to be fixed per `ORCHESTRATOR_NOTES.md:3`. It is
still on screen, in both themes, at all four spots.

Measured (light; the dark numbers differ only by fill, not shape):

| sparkle | design bbox (w × h) | app bbox (w × h) | Δ |
|---|---|---|---|
| 1 lilac (top-left) | x 31.3–72.3, y 135.3–176.3 → **41.0 × 41.0** | x 31.3–72.3, y 149.3–176.3 → **41.0 × 27.0** | top **14 px missing** |
| 2 green (top-right) | x 311.3–352.3, y 129.3–170.3 → **41.0 × 41.0** | x 311.3–352.3, y 143.3–170.3 → **41.0 × 27.0** | top **14 px missing** |
| 3 coin (mid-left) | x 20.0–61.7, y 253.3–297.7 → 41.7 × 44.3 | x 20.0–61.7, y 267.3–297.7 → 41.7 × 30.3 | top **14 px missing** |
| 4 peach (mid-right) | x 333.3–369.7, y 255.3–296.3 → **36.3 × 41.0** | x 333.3–369.7, y 269.3–296.3 → **36.3 × 27.0** | top **14 px missing** |

The x extents, the x offsets and the **bottoms** are all identical (Δ ≤ 0.33):
the shapes are bottom-aligned and the horizontal reach is unchanged, because the
vertex being dropped is `(32, 30)` — the top tip, on the shape's centre line. The
design's symmetric 4-point sparkle renders as a flat-topped, single-downward-point
blob: a completely different shape language, in four places, on the screen's
celebration layer. 14 px is far outside the ±2 px budget.

Side by side (design | app, 3× nearest-neighbour, light theme):
`ui/cmp_light_1.png` diff panel bands 1–2; the four crops read
lilac/green/coin/peach, all four wrong in the same way.

**Root cause** — `app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:168-179`
(`_SparksPainter._sparkPath`):

```dart
return Path()
  ..moveTo(numbers[0], numbers[1])          // the sparkle's TOP tip
  ..addPolygon(<Offset>[ /* numbers[2..] */ ], true);
```

`Path.addPolygon` opens its **own** contour (`_addLeadingPoint` consumes the
pending `moveTo` rather than continuing from it), so the `moveTo` point becomes a
stray one-point subpath that is never filled. The design's 8-vertex star is
painted as a 7-vertex polygon with a flat top edge — 14 px shorter, exactly as
measured. The four dots are `<circle>`s and are unaffected (all four measure Δ 0).

**Fix** (screen-local, RULES §1-legal — the painter lives in
`features/pip/presentation/widgets/`): drop the separate `moveTo` and let
`addPolygon` take the `M` pair as its first point.

```dart
return Path()..addPolygon(<Offset>[
  for (var i = 0; i + 1 < numbers.length; i += 2)
    Offset(numbers[i], numbers[i + 1]),
], true);
```

Path only — no new art, no token change, the 390 px positions and the 3 px ink
stroke all stay as they are. **Evidence:** stage 3 already parked this exact
defect as `K07-BUG-SPARK-1` in `app/test/features/pip/k07_sparkles_bug_test.dart`
(same file, same 14 px). Run for this stage:

```
flutter test --timeout 120s --run-skipped test/features/pip/k07_sparkles_bug_test.dart
  → +1 -2: Some tests failed.
      K07-BUG-SPARK-1: the painted sparkle is the design's polygon, tip included   [E]
      K07-BUG-SPARK-1: the silhouette is symmetric about the design's x = 32 axis
                       with a tip at each end                                      [E]
```

### D3 — the speech-bubble tail is 3 px taller than the design PNG (ACCEPTED — not a finding)

Bubble box is exact (h 65.0 both, x identical). The tail below it: design y
528.0–534.33 (**6.33** tall), app y 562.0–571.33 (**9.33** tall), same centre.
`ORCHESTRATOR_NOTES.md:4`: *"D3 bubble tail: ACCEPT the CSS 18×9 (shared
NestSpeechBubble follows `.speech::after`; the PNG export is smaller). Not a
finding."* **No fix.**

## Observations (not findings)

1. **Spark/dot fills in dark mode use dark tokens, the design PNG hard-codes
   hex.** Measured dark: lilac dot design `#7C6CF2` → app `#A89BFF`; green dot
   `#1F9D63` → `#3CC98A`; sky dot `#3D7FF0` → `#7FA9FF`. The `svg.sparks` fills
   are literal hex in the HTML, while the screen maps them to tokens, which the
   global rule ("never hard-code colours — tokens only") and
   `ORCHESTRATOR_NOTES.md:3` ("token fills") both require. Light mode matches the
   PNG exactly (gold `#F4B400`, green `#1F9D63`, lilac `#7C6CF2`). Recorded so a
   later iteration does not "fix" it back to literals.
2. **Pip art differs by mandate.** The grown Pip is Maya's own Mochi/sunny
   **stage 3** from the DB and the "before" silhouette is stage 2
   (`oldStage = stage − 1`), not the design's `pip-stage-4.svg` /
   `pip-stage-3.svg` illustrations — the PIP rule forbids the v1 art in product
   screens. Slot geometry (68 px silhouette at `left 2, bottom 4`; 30 px arrow at
   `left 76, bottom 24`; 240 px Pip at `right 6, bottom 0`) is preserved and the
   arrow measures Δ ≤ 0.33 px.
3. **Copy is DB-driven** and character-for-character matches the HTML's ASCII
   apostrophe byte style (`Pip's`, not `Pip’s`): `Pip grew into a Fledgling!`,
   `Because you helped 4 times`, `Flap, flap! Look at Pip's wings!`,
   `4 quests done`, `175 coins grown`, `3 of 4 stages`, `Meet Fledgling Pip`,
   `Pip still loves a chin scratch.`. Exempt per DATA OVER MOCKS.
4. **Tool note, not a screen defect:** `tools/screens/shot.sh` `cd`s into
   `$APP_DIR` before it writes the capture, so the output path must be **absolute**
   or the PNG is silently lost (`cp: …: No such file or directory`). The first
   build of this stage also died on a transient Xcode `rsync_receiver` I/O error
   (other loops building on the same machine); the retry was clean. Worth a note
   in the loop brief, but `tools/screens/**` is out of scope for a screen (RULES §1).
5. Process items (uncommitted work, the branch being behind `main`, merge order)
   are handled by the loop/orchestrator and are **not** reported here.

## Verdict

Layout, gutters, alignment, the bar, the CTA, the stat cards, the speech-bubble
box, every radius ramp, the lock button, the arrow, the four dots, the glow and
the bottom-edge rule all measure within ±2 px (most Δ 0) in **both** themes, and
the title itself is on the design's exact y. The one live, orchestrator-mandated
defect is **D2**: all four sparkles are missing their top point — 14 px short and
a visibly different shape in four places — which iteration 1 already reported and
`ORCHESTRATOR_NOTES.md:3` ordered fixed; it is unchanged on screen, and the
parked `K07-BUG-SPARK-1` proof still fails (2 of 3 tests red). A designer would
reject it. D1 and D3 are accepted by the orchestrator and are not counted.


## From 6_bugs.md
# K07 · Pip evolves (`/pip-evolution`) — Stage 6 bug hunt (iteration 2)

Adversarial pass over K07 as it stands after stage 2 (`2_build.md`), the
iteration-2 `1_plan.md`, and the stage-3/4 test + review work. **This stage
changed no product code** — RULES §1 lets a bug hunt add only
`app/test/features/pip/**` and `docs/screens/K07/**`, and `git status app/lib`
is empty at the end of the stage. No simulator was booted, installed on or
driven (only `5_ui` may touch `BC440E48-B3A3-43BC-971B-0EF5DB621874`; the
screenshots quoted below are the ones `5_ui.md` already captured). No
`flutter clean`, no `analysis_options` change, no skipped gate.

Deliverable: `app/test/features/pip/k07_bugs_test.dart` — **6 skipped failing
proofs** (K07-BUG-1 ×2, K07-BUG-2, K07-BUG-3 ×2, K07-BUG-4) plus **8 tests that
PASS** and pin what the hunt cleared.

Iteration 1's `6_bugs.md` found K07-BUG-1 and K07-BUG-2. Both are **still open**
— the tree's product code is byte-identical to iteration 1's build
(`7a649a7`), so their ids, proofs and severities carry forward unchanged, and
this stage re-measured rather than assumed them. K07-BUG-3 and K07-BUG-4 are
new.

## Verdict summary

| # | Severity | Summary | Proof |
|---|---|---|---|
| K07-BUG-4 | **MAJOR** | Every confetti sparkle silently loses its `M` tip vertex: `Path.moveTo` draws nothing and `addPolygon(close: true)` closes to the polygon's *own* first point, so the design's 4-point sparkle paints as a flat-topped blob. This is the exact cause of `5_ui.md` **D2** — and the plan/template were already correct, which is why the review missed it. | `k07_bugs_test.dart` → `K07-BUG-4: every confetti sparkle loses its \`M\` tip vertex…` (rasterised painter) |
| K07-BUG-1 | **MAJOR** | A *pending* evolution stream is rendered as the load-failure card "Oh no! Pip got lost.", and that card's only recovery control ("Try again") is a no-op while the stream is in flight. Systematic on this route. | `…k07_bugs_test.dart` → `K07-BUG-1: a still-pending evolution stream…` (widget, fake repo) + `K07-BUG-1 (real repository, no fakes)…` (state level, `PipRepositoryImpl`) |
| K07-BUG-3 | minor | The `quests done` stat counts completion **rows**, not quests, so a re-completable daily/weekly quest inflates the milestone (and contradicts the sub-line, which counts the same rows). | `…k07_bugs_test.dart` → `K07-BUG-3: the "quests done" card counts completion ROWS…` (widget) + `K07-BUG-3 (repository, no widget tree)…` |
| K07-BUG-2 | minor | At 320 px the grown 240 px Pip covers the 68 px "before" Pip and the 30 px arrow, so the before → after story is unreadable. | `…k07_bugs_test.dart` → `K07-BUG-2: at 320 px the grown 240 px Pip covers…` |

**VERDICT: FAIL** — two major bugs (K07-BUG-4, K07-BUG-1).

---

## K07-BUG-4 — MAJOR — every sparkle loses its tip vertex (the real cause of `5_ui.md` D2)

**Where** `app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:168-179`
(`_sparkPath`).

**Repro (deterministic, ~1 s)**

1. Pump `PipEvolutionSparks` in light, take its `CustomPaint.painter`, and
   rasterise it at `EvolutionSparksGeometry.artSize` (350×220).
2. Scan the lilac fill in the art's left 100 px — sparkle 1 alone.
3. The painted box is **art rows 46..60 (14 px tall)**, widest at row 48, i.e.
   a shape whose flat top sits at y 46 and whose single point drops to y 60.

The design's `M32 30 37 44 51 49 37 54 32 68 27 54 13 49 27 44Z` is a
symmetric 4-point sparkle: tip (32,30) and base (32,68) are equidistant from the
side points at y = 49. It must paint symmetric about y 49, ~23 px tall after the
3 px ink stroke eats both tips. Measured: **14 px tall, 5 px off-centre**.

`Path.getBounds()` names the cause exactly:

```
SCRATCH buggy bounds: Rect.fromLTRB(13.0, 44.0, 51.0, 68.0)   ← y starts at 44
SCRATCH fixed bounds: Rect.fromLTRB(13.0, 30.0, 51.0, 68.0)   ← y starts at 30
```

`moveTo(numbers[0], numbers[1])` only sets the current point; it **draws
nothing**. `addPolygon(offsets, close: true)` then closes the polygon back to
`offsets.first` — the *second* pair, `(37,44)` — never to the `moveTo` point. So
the tip vertex `(32,30)` is never filled and never stroked, and the top arm of
every sparkle collapses into the flat edge `(27,44) → (37,44)`.

**Why this survived two review rounds.** The `d` strings in `_sparks` are
**byte-exact against `design/html-source/screens/K07-evolution.html` lines
35–46**, `1_plan.md` pins the same template, and `4_review.md` checked the
strings. The defect is in the *parser*, not the data, so every string-level
assertion passed. It was visible in `5_ui.md` D2 as "asymmetric rounded blob
(flat wide top, single downward point)", but that stage concluded the path
template was wrong — which is why `ORCHESTRATOR_NOTES.md` D2 says "fix as the
UI check says" and the path data is in fact already right.

**Affected: all four sparkles, both themes** (the painter is shared), so this is
the screen's confetti, i.e. the thing that makes the celebration read as a
celebration.

**Failing test** — `flutter test --timeout 120s --run-skipped test/features/pip/k07_bugs_test.dart`

```
K07-BUG-4: every confetti sparkle loses its `M` tip vertex, so the design's
4-point sparkle is painted as a flat-topped blob
  Expected: a value greater than or equal to <20>
    Actual: <14>
```

**Suggested fix** (feature-local, RULES §1-legal, 2 lines in
`pip_evolution_sparks.dart`) — drop the `moveTo` and let the polygon own every
vertex, including the tip:

```dart
return Path()
  ..addPolygon(<Offset>[
    for (var i = 0; i + 1 < numbers.length; i += 2)
      Offset(numbers[i], numbers[i + 1]),
  ], true);
```

**Fix verified, then reverted** (this stage may not fix the screen): with the
loop above applied to a scratch copy, the K07-BUG-4 proof goes green
(`00:00 +1: All tests passed!`) and the painted box becomes rows 37..60 with the
widest row on the centre line (asymmetry 5.0 → 0.5). The working tree was then
restored byte-for-byte (`git status app/lib` empty, confirmed after restore), so
the shipped code still fails the proof.

---

## K07-BUG-1 — MAJOR — a still-pending evolution stream is shown as "Oh no! Pip got lost.", and its "Try again" does nothing

*(Unchanged from iteration 1; re-measured against the current tree.)*

**Where**

- `app/lib/features/pip/presentation/views/pip_evolution_view.dart:86-97` —
  `case PipStatus.loaded:` reads `state.evolution`, and when it is null it
  falls through to the sibling stream: `if (nest != null) return
  _EvolutionFailure(...)` (line 95) before `_EvolutionNoChild()` (line 96).
- `app/lib/features/pip/presentation/bloc/pip_bloc.dart:51-68` — the load
  subscribes to the NEST stream first (line 51) and the evolution stream second
  (line 60); line 49's guard `if (_nestSub != null && _evolutionSub != null)
  return;` is what makes the card's retry a no-op.
- `app/lib/features/pip/presentation/bloc/pip_state.dart:60-68` —
  `copyWithLoaded` publishes `PipStatus.loaded` with `evolution == null`.

**Repro (deterministic, 2 s)**

1. Register a repository whose `watchNest()` is the real one and whose
   `watchEvolution()` is an open, silent stream (no value, no error).
2. Pump `/pip-evolution`.
3. The screen shows **"Oh no! Pip got lost." / "Let's try again." /
   `Try again`** with no Pip, no title, no CTA — while the only thing true of
   the screen is that its data is still in flight.
4. Tap `Try again`: `evolutionCalls` stays at 1. The bloc guard sees both
   subscriptions as live and drops the event, so the kid's only way out of the
   card does nothing.

**Failing tests** (two, so the fake cannot be blamed for the timing)

```
K07-BUG-1: a still-pending evolution stream renders the load-failure card…
  Actual: _TextWidgetFinder:<Found 1 widget with text "Oh no! Pip got lost.": […

K07-BUG-1 (real repository, no fakes): the bloc publishes a "loaded" state with
a nest but no evolution, which /pip-evolution renders as "Oh no! Pip got lost."
  5 of 5 cold opens published `loaded` before the evolution arrived
```

The second proof runs five cold opens against the shipped `PipRepositoryImpl`
with the demo seed and no widget tree: **5 of 5**, not a race. `PipLoadRequested`
subscribes nest-first by construction (`pip_bloc.dart:51` then `:60`) and both
streams start from the same `watchAppState()` emission, so the ordering is
structural.

**Visible impact.** In the shipped timing the two emissions are fractions of a
millisecond apart, so they usually coalesce into one painted frame. But the false
state is real on *every* cold open, and it becomes visible whenever the second
query is slower than a frame: a cold database, a big `quest_completions` table,
a busy isolate. The persisted form is worse — if `watchEvolution()` is slow or
hung, the child sits on an alarming error card with a **dead** "Try again" and
no way out except the parental gate.

**Suggested fix** (feature-local, RULES §1-legal; identical to iteration 1's
and to `4_review.md` finding 1). Give each stream its own arrival flag in
`PipState` (e.g. `nestSettled` / `evolutionSettled`, set in `copyWithLoaded` /
`copyWithEvolution` and both `…Failed` handlers, carried through the other
`copyWith*` helpers and `props`), and let each view gate on **its own** stream:

```dart
case PipStatus.loaded:
  final evolution = state.evolution;
  if (evolution != null) return _EvolutionBody(evolution: evolution);
  // nest != null only proves K06's stream spoke; it says nothing about ours.
  return const _EvolutionNoChild();          // ← delete the line-95 branch
```

with the loading branch keyed on `!evolutionSettled && errorMessage == null`, so
a pending screen shows the spinner and a failed one shows the card. Second,
independent hardening: `_onLoadRequested`'s guard should ignore a repeat load
while the *pending* card is showing, or the retry button should not be offered
until its own stream has settled.

---

## K07-BUG-3 — minor — "quests done" counts completion rows, not quests

**New this iteration.**

**Where**

- `app/lib/features/pip/data/pip_repository_impl.dart:96-99` —
  `questsDone = completions.where((c) => c.status == 'done_pending' ||
  c.status == 'approved').length` — a row count, with no `distinct` on
  `questId`.
- `app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart:39-41` —
  `evolutionSub` renders the same number as "Because you helped N times".

**Repro (deterministic, 2 s)** — the demo seed has Maya with 4 **distinct**
quests done (`q-dishwasher` + `q-table` pending, `q-bins` + `q-hoover`
approved). Insert one more `approved` completion for `q-bins` — legal, and
routine: a `daily`/`weekly` quest is re-completable, and nothing in the schema
forbids a second row for the same `(questId, childId)`.

```
K07-BUG-3 (repository, no widget tree): watchEvolution reports 5 for 4 distinct
quests after one quest is completed twice
  Expected: <4>
    Actual: <5>
  5 completion rows cover only 4 distinct quests (q-dishwasher, q-table,
  q-bins, q-hoover), so "quests done" counted rows, not quests
```

The widget proof reads the painted card: the number under `k07-stat-quests` is
`'5'` where `'4'` is correct, while the sub-line correctly reads "Because you
helped 5 times".

**Why it matters on this screen specifically.** K07 is a *milestone* screen: the
stat card is the number that goes with Pip's stage, and the card's own label is
`quests done`. A child who completes one daily quest for a month reads
"30 quests done" for one quest. Worse, the two numbers on the screen then
disagree — the card says 30 quests, the sub-line says 30 times, and the child can
see that they are not the same claim.

**Suggested fix** (feature-local): count distinct quests for the card, keeping
the row count for the sub-line, since "helped N times" is honestly per
completion:

```dart
final counted = completions
    .where((c) => c.status == 'done_pending' || c.status == 'approved');
final questsDone = counted.length;                 // the sub-line ("times")
final questsFinished = counted.map((c) => c.questId).toSet().length;  // the card
```

which needs one more field on `PipEvolution` (or the card fed a second value).
If the product really wants the row count everywhere, then the card's label is
what must change — but that label is the design's (`K07-evolution.html:61`), so
the count is the cheaper side to fix. `1_plan.md` §(b) chose rows deliberately
("a lifetime milestone"), so this needs the plan's author to confirm which of the
two sentences the number is meant to be; either way the two must not contradict
each other.

---

## K07-BUG-2 — minor — at 320 px the grown Pip covers the "before" Pip and the arrow

*(Unchanged from iteration 1; re-measured.)*

**Where** `app/lib/features/pip/presentation/widgets/pip_evolution_stage.dart:97-142`
(`.k7-stage` slot) with `EvolutionStageGeometry`: `oldSize 68` at `left: 2`,
`arrowSize 30` at `left: 76`, `newSize 240` at `right: 6`.

**Repro** pump `/pip-evolution` on a 320×844 surface (a supported width —
`docs/design/SPACING_SPEC.md:369` plans 320 layouts) and measure the three boxes:

```
arrow 96.0..126.0     grown Pip 54.0..294.0     old Pip 22.0..90.0
newRect.left - arrowRect.right = -72   (the design allows -2)
```

The slot needs `2 + 68 + 6 + 30 + 6 + 240 = 352` px and only has 280, so the
fixed-size grown Pip slides 72 px left over the arrow and 36 px over the old
Pip. The arrow and the faded "before" silhouette are painted underneath the
grown Pip — the one thing the screen exists to show (before → after) is
illegible at that width.

**Failing test** — `k07_bugs_test.dart` → `K07-BUG-2: at 320 px the grown 240 px
Pip covers the 68 px old Pip and the 30 px arrow…`

```
Expected: a value greater than or equal to <-2.0>
  Actual: <-72.0>
   at 320 the arrow sits entirely inside the grown Pip's box
   (arrow 96.0..126.0, Pip 54.0..294.0)
```

**Suggested fix** (feature-local, no shared change): make the slot's three
pieces scale with the available width instead of being fixed — e.g. wrap the
slot content in a `FittedBox(fit: BoxFit.scaleDown, alignment: bottomRight)` or
size the grown Pip as `min(240, slotWidth - oldSize - arrowSize - gaps)` while
keeping the 390 px geometry byte-identical (the UI check measured 240/68/30 and
the ±2 px budget must survive). A cheaper acceptable alternative: below ~352 px
of slot width drop the old-Pip silhouette and centre the grown Pip, the way the
stage-1 branch already does.

---

## Investigated and cleared (no bug — recorded so it is not re-reported)

1. **A synchronously failing stream leaves the failure card's retry dead.**
   Hypothesis: `_evolutionSub ??= …listen(onError: …)` runs the handler *before*
   the assignment, so a stream that errors inside `listen()` leaves a dead
   subscription and `pip_bloc.dart:49` blocks every later retry.
   **Disproved by measurement**: Dart delivers `Stream.error` in a microtask,
   *after* `listen()` returns, so the handler sees the real subscription and
   clears the field. Both failure-delivery shapes Dart offers (`Stream.error` and
   `addError` on a controller) are pinned by a PASSING test, `cleared: after a
   REAL stream failure "Try again" really re-subscribes (both Dart
   failure-delivery shapes)`. (Only a `StreamController.sync` whose `onListen`
   pushes the error could break the guard; no repository in the app builds one.)
2. **Data edge cases — all clean.** 0 children / `activeChildId = null`
   ("Who's playing?" + `Choose` → `/who-is-playing`, no retry button), a ghost
   `activeChildId` (same card), 1 child, **6 children** (the screen follows the
   ACTIVE child only — with four extra rows inserted, Maya still renders
   `stage 3, quests 4`), `pip_stage` 0 and 5 (clamped to 1..4, no `PipAvatar`
   assert), 0 and 1 completions (`Because you helped 0 times` / `… 1 time`
   singular), 9999 coins, and a 19-character name (`Maximilian-Alexander`) at
   320 px / text scale 1.3 / dark — no overflow, no exception, `9999` intact in
   the merged stat sentence.
3. **A child picked AFTER the no-child card live-updates into the celebration.**
   New this iteration and worth pinning: `active_child_id` going null → `'leo'`
   must take the screen from "Who's playing?" to `Pip grew into a Hatchling!` /
   `Because you helped 2 times` / `Meet Hatchling Pip` with **no reload and no
   dead end**. PASSING (`control: the no-child card live-updates…`), so the
   `_switchMap` + `combineLatest2` chain in `watchEvolution` is correct in both
   directions.
4. **Switching the active child Maya → Leo retitles the whole screen.**
   Also new this iteration. A live switch must move the hero, the sub-line, the
   coins, the CTA and the Pip's VoiceOver image label together
   (`Maya's Pip, a fledgling` → `Leo's Pip, a hatchling`), with no stale frame
   and no exception. PASSING (`control: switching the active child Maya -> Leo…`).
5. **Rapid taps — clean.** Double-tap CTA navigates to `/pip` once; double-tap
   lock opens `/parental-gate` once and popping it returns to `/pip-evolution`
   with the CTA still working; double-tap retry re-subscribes once.
6. **Restart / Drift persistence — clean.** Writing a new `pip_stage` and
   `pip_total_coins` and re-reading yields `{questsDone 4, stage 4, coins 260}`
   — nothing on this screen is cached in memory, so nothing is lost across a
   restart. (Iteration 1 additionally proved the file-backed reopen path.)
7. **Kid-mode guard — correct, including the trial path.** A cold deep link to
   `/pip-evolution` in kid mode with an aged `trial` row lands on
   `/parental-gate` (`router.dart:127-132`); measured
   `trialExpired=true → path=/parental-gate`. `/pip-evolution` is not on the
   `parentOnly` list, so a parent may inspect it (intended). No bypass found.
8. **Dark-mode contrast — clean.** Every text pair on the screen clears 4.5:1
   (measured iteration 1: light — title/sub/number `ink` on `surface` 16.50,
   caption + stat label `ink2` 8.87, CTA `onAccent` on `lilacStrong` **5.03**,
   the worst pair on the screen; dark — ink 14.76, `ink2` 9.82, CTA 7.74).
9. **Async gaps — clean.** A bloc closed while both streams are live tolerates a
   late `addError` on both subscriptions with no `StateError`. New this
   iteration: a DB write committed while the whole app is torn down mid-load
   throws nothing (`control: a late stream emission after the app is torn down
   throws nothing`) — no add-after-close, no emit-after-close.
10. **Timezone / money rounding — not applicable.** K07 reads no clock at all
    (`watchEvolution` counts rows; `pip_evolution_copy.dart` says so
    explicitly) and shows no `£` (the jar screens own money). Its only numbers
    are lifetime integer counts, so there is nothing to round. The PERIODS
    ruling (`countsForCurrentPeriod`) does not apply to a lifetime milestone;
    the seed's Maya completions (2 `done_pending` + 2 `approved`, all inside the
    current London week) give 4 either way, so the screen's demo numbers are
    period-independent and the BST change cannot move them.

## Test-harness note (not a product bug, but it cost this stage time)

A Drift **write issued while the app is pumped** inside `tester.runAsync`
deadlocks this harness when the written table is one a live watch is sitting on:
measured on an `INSERT` into `quest_completions` with `watchCompletionsForChild`
live, hanging at the `await`, with `--timeout` unable to fire because the await
is inside the fake-async zone. Iteration 1 hit the same wall on `db.delete`
inside a pumped test. K07-BUG-3's widget proof therefore writes **before** the
first pump, and its second proof is a plain real-async `test` with no widget
tree. This is a harness constraint, recorded here so the next stage does not
re-derive it — it is not a K07 defect.

## Observations (not findings)

1. **Nothing in the app links to `/pip-evolution`.** `PipRoutePaths.evolution`
   has no call site outside `pip_routes.dart`; the only ways in are a deep link
   or `--dart-define=INITIAL_ROUTE`. `1_plan.md` §(c) does not require an
   inbound link (K07 is a "moment" screen and the CTA *leaves* to `/pip`), so
   this is not a screen defect — but if the intended flow is "K06 celebrates a
   stage-up by opening K07", that entry point does not exist yet and belongs to
   the K06/flow owner.
2. **The three non-design states still paint an empty bottom bar** (review
   finding 8, accepted): `_EvolutionBar()` with `stage: null` renders the band
   with its 3 px ink rule and no CTA. K07-BUG-1's false-failure frame is one of
   the frames that shows it.
3. **The two apostrophe styles in the announcements** (review finding 5) still
   hold: `'Loading Pip’s big moment'` uses a curly ’ where every other string in
   the screen uses the ASCII `'` that the HTML source writes.
4. **The design's `#3D7FF0` sparkle dot is not a token** (`3_test.md`
   observation 1) — unchanged; still the screen painting `tokens.sky`.
5. **`flutter test test/features/pip/` can stall.** Iteration 1 recorded 7
   minutes of no progress inside `pip_buy_result_test.dart` while running the
   whole directory (alone that file is green in 3 s); `--timeout` cannot fire on
   a test awaiting inside the fake-async zone. This stage therefore ran the ten
   K07-related files explicitly (138 pass, 10 skipped) rather than the
   directory. Not caused by, and not fixable from, K07's screen.

## Gates

```
cd app
dart format test/features/pip/k07_bugs_test.dart            → 1 file, no change
flutter analyze test/features/pip/k07_bugs_test.dart          → No issues found!
flutter analyze test/features/pip/                           → No issues found!

flutter test --timeout 90s test/features/pip/k07_bugs_test.dart
  → +8 ~6: All tests passed!        (8 controls green, 6 proofs parked)

flutter test --timeout 90s --run-skipped test/features/pip/k07_bugs_test.dart
  → +8 -6:  exactly the six proofs fail, none hangs:
      K07-BUG-1 (widget)                      → "Oh no! Pip got lost." found
      K07-BUG-1 (real repository, no fakes)   → 5 of 5 cold opens
      K07-BUG-2 (320 px)                      → Expected >= -2.0, Actual -72.0
      K07-BUG-3 (widget)                      → Expected '4', Actual '5'
      K07-BUG-3 (repository, no widget tree)   → Expected <4>, Actual <5>
      K07-BUG-4 (rasterised sparkle)           → Expected >= 20, Actual 14

# the ten K07-related files together, stage-3/4 suites included:
flutter test --timeout 120s test/features/pip/pip_evolution_*.dart \
  test/features/pip/k07_*.dart
  → +138 ~10: All tests passed!
```

Every gate ran with a per-test timeout (`--timeout 90s` / `120s`); no run was
waited on for more than ten minutes and none hung. The stage-3/4 K07 suites
(`pip_evolution_*_test.dart`, `k07_sparkles_bug_test.dart`) were read and run
but **not edited** by this stage.

Scratch probes (`zz_scratch_sparks_probe_test.dart`, `zz_probe_more_test.dart`)
were exploratory and are **deleted**; every number they produced is either quoted
above or pinned by a permanent test in `k07_bugs_test.dart`.

`SHARED_REQUEST.md` stays as filed (iteration 1). All four fixes are in-feature
(`pip_evolution_view.dart`, `pip_bloc.dart`, `pip_state.dart`,
`pip_evolution_stage.dart`, `pip_evolution_sparks.dart`,
`pip_repository_impl.dart`, `pip_evolution.dart`), which RULES §1 puts in this
branch's scope.

## Verdict

Two major bugs. **K07-BUG-4** is the screen's confetti: all four sparkles paint
as flat-topped blobs in both themes because `_sparkPath` drops each path's `M`
tip vertex — the path *data* was already correct, which is exactly why the
review passed it and `5_ui.md` D2 could only report the symptom; the fix is two
lines and is verified green. **K07-BUG-1** puts a false "Oh no! Pip got lost."
card with a dead "Try again" on the celebration screen's systematic cold-open
path (5/5 cold opens with the shipped repository). K07-BUG-3 (rows counted as
quests) and K07-BUG-2 (320 px overlap) are minor and independent.

