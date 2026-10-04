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

VERDICT: FAIL
