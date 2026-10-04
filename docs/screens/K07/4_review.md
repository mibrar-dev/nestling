# K07 · Pip evolves — stage 4 QA code review (iteration 2)

Reviewed: `git diff main...HEAD` (13 `lib` files, 6 test files, 1 changed
foundation-owned test) against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 K07 (`docs/DESIGN_SPEC.md:202`),
`docs/design/SPACING_SPEC.md`, `app/lib/core/design_system/`, `1_plan.md`,
`6_bugs.md`, `ORCHESTRATOR_NOTES.md` and the orchestrator rulings.

**No simulator was booted, installed on, driven or screenshotted** (only stage 5
may). Nothing was edited. No image was attached to this reply.

Iteration-2 delta actually reviewed: `git diff 8272593 34abefa -- app/`
(19 files, +807/−206) — the per-stream state machine, the sparkle parser, the
stage slot, the copy table and the bug-proof un-skips. The rest of
`main...HEAD` is iteration 1, re-checked where this iteration touched it.

## Verdict summary

| # | Severity | Finding |
|---|---|---|
| 1 | **MINOR** | `toLoading()` drops **both** streams' arrival flags, but a retry only re-subscribes the stream that died — the still-live sibling keeps its data while its `*Status` reports `loading` until an unrelated table change re-emits it. |
| 2 | **MINOR** | `evolutionSub(0)` renders **“Because you helped 0 times”** on a celebration screen — a reachable kid-facing string (`/pip-evolution` on a child with no counted completions) with no zero branch. |
| 3 | **MINOR** | `pip_evolution_sparks_test.dart:12` sends the reader to `pip_evolution_sparks_bug_test.dart`, a file that does not exist; the silhouette proof is `k07_sparkles_bug_test.dart`. |

**No blocker. No major.** Every iteration-1 major (1, 2, 3) and every
corrective note (D1/D2/D3) is closed in code and proven. `VERDICT: PASS`.

## Gates re-run by this stage (no simulator)

| Gate | Result |
|---|---|
| `dart format --set-exit-if-changed .` | **clean** — 642 files, 0 changed |
| `flutter analyze` | 4 diagnostics, **all in one untracked in-flight file** (see *Gate risk* below); `app/lib/**` clean, `app/test/**` clean apart from that file |
| `flutter test --timeout 120s test/features/pip` | **406 tests, all passed**, `00:25`, 0 skips (the `skip: true` hits in `grep` are all inside comments) |

RULES §7.1 is therefore satisfied for everything this branch owns. I did not run
`flutter clean`, did not run interactive `flutter run`, did not weaken
`analysis_options` (unchanged in the diff), and did not touch
`app/lib/core/**`, `app/lib/app/**`, another feature or `tools/screens/**`:

```
$ git diff --stat main...HEAD -- app/analysis_options.yaml app/lib/core app/lib/app tools/
(empty)
```

## `ORCHESTRATOR_NOTES.md` — all three mandatory items

| Item | Ruling | Verified in code |
|---|---|---|
| **D2** sparkles | fix as the UI check says: the exact HTML 4-point path at the 4 spots, token fills, ink 3 px stroke | **Delivered.** `pip_evolution_sparks.dart:193-202` hands **every** vertex, the `M` pair included, to one `Path.addPolygon` (the old `moveTo` before `addPolygon` was discarded by `_addLeadingPoint`, so each star painted as a flat-topped 7-gon). The four `d` strings are byte-exact against `K07-evolution.html:36-39`; fills resolve through `_Spark.colorOf` → `tokens.lilac/success/coin/peach/sky`; `strokeWidth = 3` on `tokens.ink`; `strokeJoin = round`. Proof un-skipped and green in `k07_sparkles_bug_test.dart` (mechanism + raster + symmetry). |
| **D3** bubble tail | ACCEPT the CSS 18×9, shared `NestSpeechBubble` follows `.speech::after` | Nothing owed. The view uses the shared bubble (`pip_evolution_view.dart:358-363`), no local re-implementation. |
| **D1** Fledgling copy wrap | ACCEPT (DB truth) | Correctly DB-driven: `evolutionTitle(stage)` builds from the DB stage, so demo Maya reads “Pip grew into a Fledgling!” and the stack sits 34 px lower than the stage-4 PNG. No hard-coded `25`/`250`/`4` anywhere. |

## Iteration-1 findings — disposition (all 12)

| # | Was | Now |
|---|---|---|
| 1 | MAJOR sparkle tip | **fixed** — parser above; proof live |
| 2 | MAJOR `loaded` from either stream → “Oh no! Pip got lost.” on 5/5 cold opens | **fixed** — per-stream slots; `PipState.nestStatus` / `evolutionStatus` (`pip_state.dart:78-84`), both views switch on their own (`pip_evolution_view.dart:84`, `pip_nest_view.dart:75`) |
| 3 | MAJOR analyze/format red | **fixed** — format clean; only an untracked in-flight file remains (gate risk, below) |
| 4 | MINOR K07 opens K06's stream | **superseded** — the second stream is now load-bearing for the per-stream status; re-checked, still one bloc per feature (ARCHITECTURE `docs/ARCHITECTURE.md:85`) |
| 5 | MINOR empty bar with a 3 px rule | **fixed** — `_EvolutionBar` builds the rule only when a CTA exists (`pip_evolution_view.dart:~404`), the surface box stays so the BOTTOM EDGE rule is untouched |
| 6 | MINOR two apostrophe styles | **fixed** — ASCII `'` throughout, with the byte-level reason in the copy header |
| 7 | MINOR stage-1 copy self-contradiction, `Shh...` | **fixed** — `'Psst… Pip is still an Egg!'` (single `…`) |
| 8 | MINOR stat labels outside the copy module | **fixed** — `evolutionStatQuestsLabel/CoinsLabel/StagesLabel` |
| 9 | MINOR dark sparkle fills | **token re-theme stands** (tokens-only rule wins); still **owed an explicit orchestrator ruling** — not a code finding either way |
| 10 | MINOR write-only `errorMessage` | **folded in** — kept, documented as diagnostic-only, never rendered on a kid screen |
| 11 | MINOR per-paint path re-parse | **fixed** — `_Spark.path` cache (`pip_evolution_sparks.dart:63-79`) |
| 12 | MINOR 320 px overlap | **fixed** — `FittedBox(scaleDown, bottomRight)` only when `maxWidth < 350`; a no-op at 390 (`pip_evolution_stage.dart:105-124`) |

## What was checked and found sound

- **Architecture** — feature-first intact. Domain gains exactly one Equatable
  entity + one abstract `watchEvolution()`; the Drift mapping and the private
  `_switchMap` stay in `data/pip_repository_impl.dart:79-111`. No use-case
  classes, no new folders, `package:nestling/...` imports only, no presentation
  code in `domain/` (`pipStageName` correctly lives in
  `presentation/widgets/pip_look.dart`). One bloc per feature, provided at the
  route (`pip_routes.dart:33-40`, unchanged, `GetIt` factory → a fresh bloc per
  route entry); `pip_di.dart` and `app/lib/app/**` untouched.
- **RULES §1 scope** — the diff touches only
  `app/lib/features/pip/{domain,data,presentation}/**`,
  `app/test/features/pip/**` and `docs/screens/K07/**`.
- **Tokens only** — `rg` over `lib/features/pip` finds **zero** hex literals in
  code (the hex strings are all inside comments citing the HTML), zero
  `letterSpacing` writes, no `google_fonts`/`GoogleFonts`, no `DateTime.now()`,
  no `print`/`debugPrint`, no `£` (kid screens show coins), no network symbol.
  Every geometry constant that claims to be a token was re-checked against
  `tokens/spacing.dart`: `gap2`=2 ✓, `s1`=4 ✓, `s2`=8 ✓, `s3`=12 ✓, `s4`=16 ✓,
  `s6`=24 ✓, `s8`=32 ✓, `padSide`=20 ✓, `gap6`=6 ✓, `gap10`=10 ✓ — so
  `.k7-old { left: 2px }`, `{ bottom: 4px }`, `.k7-arrow { left: 76px, bottom: 24px }`
  and `.k7-new { right: 6px }` are transcribed correctly, not mis-aliased.
  The two CSS-only sizes (`.k7-stats b` 30/34, `span` 14/18,
  `K07-evolution.html:29-30`) are applied at the call site on top of
  `NestType.kidTitle` / `kidCaption` exactly as the LETTER SPACING ruling
  prescribes, with the source line cited.
- **Component reuse** — `NestStatusBar`, `NestHomeIndicator`, `NestLockButton`
  (default `large: true` → 56 px, matching `.lock-btn.lg`; its own
  `Semantics(onTap:)`), `NestKidButton`, `NestSpeechBubble`, `NestBalancedText`,
  `NestIcon.arrowRight`, `NestKidStarsPainter`, `PipAvatar`, `NestType.*`,
  `NestRadii.*`, `NestSpacing.*`. The style/skin/accessory mappers and the stage
  names are K06's `pip_look.dart` helpers, not a second copy. The radial glow is
  the one thing a `BoxDecoration` genuinely cannot express (CSS's explicit
  `118% 62%` radii), so the translate/scale + unit-circle shader is correct and
  documented.
- **BALANCED HEADINGS** — `.kid-title` carries `text-wrap: balance`, so the hero
  is `NestBalancedText` (`pip_evolution_view.dart:341-346`); the `.kid-body`
  sub, the bubble and `.kcap` correctly do not.
- **PIP rule** — both slots render the **child's own** Pip from
  `pip_style`/`pip_skin`/`pip_accessory` at the DB stage
  (`pip_evolution_stage.dart:100-107`); no `pip-stage-*.svg` anywhere in `lib/`;
  the loading/failure/no-child cards use `PipAvatar(mochi, sunny)` when no child
  is known, per the orchestrator's no-child rule.
- **KID BACKGROUND** — deviation from the generic `KidScope` rule re-verified
  against the source: `K07-evolution.html:16` replaces `.screen.kid`'s
  background with `--kid-stars` + the lilac `radial-gradient(118% 62% at 50% 36%)`,
  the K07 body has **no `.meadow` element** (lines 7-9 are dead boilerplate) and
  both PNGs show no sky and no hills. The shared stars painter is reused in dark
  only; no local hills are painted anywhere. Correct, and filed in writing
  (`SHARED_REQUEST.md` §1) — the orchestrator still needs to **record the
  exception** so a later iteration does not “fix” it back to `KidScope`.
- **BOTTOM EDGE / ALIGNMENT (owner rules)** — `_EvolutionBar` puts the surface
  `Container` **outside** `SafeArea(top: false)`, so the surface reaches the
  physical edge and the 34 px inset sits inside it: no glow strip under the bar
  and no tint around the home indicator, in either theme. One 20 px gutter for
  the lock row, the scroll column, the three cards (x 20/140/260, right edge
  370) and the CTA; the bar and the cards share their edges.
- **Copy** — every string is byte-checked against `K07-evolution.html:55-66`,
  including the trap: the source writes a **literal ASCII `0x27`** in `Pip's`
  (line 57), and the code matches it. Stage-4 strings are byte-identical
  (55/57/59-61/63/66); the other stages are parallel kid-tone lines with no
  HTML source. `…` is the single ellipsis character. UK spelling, no red, no
  nagging. Numbers come from the DB (`questsDone`, `questsFinishedCount`,
  `profile.totalCoins`, `profile.stage`) — nothing hard-coded.
- **K07-BUG-3 split** — the sub-line counts *completions* (“helped N **times**”)
  and the card counts *distinct quests* (“N **quests done**”), so a re-completable
  daily cannot read as two quests and the two sentences cannot contradict each
  other. The PERIODS helpers are correctly **not** used (a lifetime milestone);
  no clock is read.
- **Accessibility** — every interactive node is a shared `onTap`-bearing widget:
  `NestLockButton(semanticLabel: 'Grown-ups')` (the design's `aria-label`),
  `NestKidButton` for CTA / retry / choose. The two `excludeSemantics` nodes are
  non-interactive (the merged stat sentence; the decorative silhouette, arrow
  and sparks — `alt=""` / `aria-hidden`), so no `onTap:` is owed. The new Pip is
  `Semantics(image: true, label: "Maya's Pip, a fledgling")`. Tap targets: lock
  56, CTA ≥ 64. Tests assert `hasAction(SemanticsAction.tap)` per control and
  drive real state (retry re-subscribes, CTA → `/pip`, choose → picker,
  lock → gate) through `performAction`.
- **Performance** — no `Timer`, no `AnimationController` (RULES §6), no reload
  events, no per-frame state. The glow and stars subtrees are `const` and both
  painters key `shouldRepaint` on the tokens they use, so a state change rebuilds
  but does not repaint them. `close()` awaits both cancels and nulls the fields
  (`pip_bloc.dart:191-201`); `_switchMap` cancels the inner subscription per
  outer emission; a stream error releases only its **own** subscription, so
  “Try again” genuinely re-subscribes (pinned by tests for both Dart
  failure-delivery shapes). The one avoidable per-paint allocation (finding 11)
  is gone.
- **Error handling** — no raw exception ever reaches a kid screen: the failure
  cards render their own kind copy (“Oh no! Pip got lost.” / “Let's try again.”)
  and `errorMessage` is documented as diagnostic-only and read by no view. A
  mid-session stream error keeps the loaded screen instead of blanking it
  (`nestSettled` stays true ⇒ `nestStatus` stays `loaded`).
- **Children's Code** — kid mode only: no analytics, no ads, no network, no
  identifiers, no third-party SDK, no `£`, no red, no timers/countdowns, no
  loss framing, nothing logged or transmitted, and the child's only exposure is
  their own nickname in an a11y label. Finding 2's old behaviour (a wrong error
  card on a celebration screen) is exactly the kind of tone bug this code
  forbids, and it is fixed.

## Findings

### 1. MINOR — `toLoading()` clears both arrival flags, but a retry only re-subscribes the stream that died

`app/lib/features/pip/presentation/bloc/pip_state.dart:115-124`
(`PipState.toLoading`) with
`app/lib/features/pip/presentation/bloc/pip_bloc.dart:49-61`
(`_onLoadRequested`).

`toLoading()` rebuilds a `PipState` **without** `nestSettled`,
`evolutionSettled`, `nestError` or `evolutionError`, so both arrival flags fall
to `false` and both error slots are cleared. But `_onLoadRequested` re-subscribes
with `??=`, so a retry after a single-stream failure keeps the **healthy**
subscription alive and only opens a new one for the dead stream:

```dart
if (_nestSub != null && _evolutionSub != null) return;   // :49
emit(state.toLoading());                                 // :50  ← both flags false
_nestSub ??= _repository.watchNest().listen(...);         // :51  ← kept if live
_evolutionSub ??= _repository.watchEvolution().listen(...); // :61 ← kept if live
```

Consequence: for the stream that stays live, `nestStatus`/`evolutionStatus` now
report `loading` (`_streamStatus(false, null)`) while its data is still held in
the state, and that status can only return to `loaded` if the still-open Drift
subscription happens to re-emit — i.e. on some unrelated table write. A stream
that never re-emits leaves that screen on its spinner forever with no retry
affordance (the retry button only exists on the `failure` branch).

Latent today, not user-visible, for two structural reasons: each route builds a
**fresh** `PipBloc` (`pip_routes.dart:33-40`, GetIt factory), so the damage
cannot cross screens; and the retry button is only reachable when the view's
**own** stream is the failed one, which is always the stream that gets
re-subscribed. It is one line away from being visible (any third consumer of the
feature bloc, or a retry affordance on a still-loading state), and the invariant
the new state machine is built on — *settled ⇔ this stream has answered since
the last load* — is simply false for the surviving subscription.

Fix (either): make the reset explicit about what is actually being restarted —

```dart
PipState toLoading({required bool restartingNest, required bool restartingEvolution}) {
  return PipState(
    status: PipStatus.loading,
    nest: nest,
    evolution: evolution,
    nestSettled: restartingNest ? false : nestSettled,
    evolutionSettled: restartingEvolution ? false : evolutionSettled,
    nestError: restartingNest ? null : nestError,
    evolutionError: restartingEvolution ? null : evolutionError,
    errorMessage: errorMessage,
    actionError: actionError,
    actionNonce: actionNonce,
  );
}
```

called as `emit(state.toLoading(restartingNest: _nestSub == null, restartingEvolution: _evolutionSub == null));`
— or, simpler and impossible to get wrong, have `_onLoadRequested` cancel **both**
subscriptions on a fresh load and re-listen both, so “a fresh load re-answers
both streams” (the doc comment) becomes literally true. Add a bloc test that
drives nest-fails-then-retry and asserts `nestStatus` (and, from the evolution
side, `evolutionStatus`) is `loaded` after the retry **with the sibling stream
never re-emitting**.

### 2. MINOR — `evolutionSub(0)` renders “Because you helped 0 times”

`app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart:48-50`.

```dart
String evolutionSub(int questsDone) => questsDone == 1
    ? 'Because you helped 1 time'
    : 'Because you helped $questsDone times';
```

The singular branch exists, the zero branch does not. `questsDone` is the
lifetime count of `done_pending` + `approved` completions
(`pip_repository_impl.dart:88-97`), so `0` is a real state: a family that has
just added a child and opened `/pip-evolution` before the first completion. The
screen then reads “Pip grew into a Hatchling!” above **“Because you helped 0
times”** — a self-contradicting sentence on a celebration screen, which is the
tone the Children's Code rules and the orchestrator's `no nagging` rule exist to
prevent (the same class of defect as iteration-1 finding 7, one branch over).

The route has no in-app entry point yet (`rg 'PipRoutePaths.evolution' lib/`
returns only the route definition), so today it is reachable via
`INITIAL_ROUTE=/pip-evolution` or a deep link rather than by tapping — which is
why this is minor and not major.

Fix: add the zero branch in the same copy table, e.g.

```dart
String evolutionSub(int questsDone) => switch (questsDone) {
  0 => 'Pip is ready for its first adventure',
  1 => 'Because you helped 1 time',
  _ => 'Because you helped $questsDone times',
};
```

There is no HTML source for a zero case, so the exact wording needs the
orchestrator's sign-off before it lands (the pattern and the ASCII convention are
already right); the defect to fix is the missing branch, not the phrasing. A
one-line test for `evolutionSub(0)` / `(1)` / `(4)` belongs beside the existing
copy tests.

### 3. MINOR — a test header points at a file that does not exist

`app/test/features/pip/pip_evolution_sparks_test.dart:12`.

The header says the silhouette proof “lives with its proof in
`pip_evolution_sparks_bug_test.dart`”. No such file exists; the proof is
`test/features/pip/k07_sparkles_bug_test.dart` (the name the repo convention and
its own header use). Anyone chasing the D2 evidence from this header ends up with
a dead path. Fix: correct the filename in that one comment line. (One line, no
behaviour change — but it is the file that tells the next agent *where the proof
is*, and the other two K07 test headers get it right.)

## Gate risk — not a finding, per the PROCESS rule

`flutter analyze` currently reports **4 diagnostics, all in one file that is not
part of this branch**:

```
app/test/features/pip/pip_evolution_stream_contract_test.dart   (untracked, mtime 22:42)
  error • The name 'NestKidTokens' isn't a type … :543:20
  info  • Unnecessary escape of ''' … :272:9
  info  • Unnecessary escape of ''' … :402:17
  info  • Missing a newline at the end of the file … :544:22
```

It is untracked (`git cat-file -e HEAD:…` → not in HEAD, not in main, not
ignored) and its mtime falls **after** this stage started, i.e. it is another
stage's in-flight work — the same call stage 3 made for
`zz_scratch_sparks_probe_test.dart`, and the same call the PROCESS rule makes:
uncommitted work is the loop's and the orchestrator's, not a blocker/major here.
`app/lib/**` and every committed test file analyse clean, and
`dart format --set-exit-if-changed .` is clean over all 642 files.

For whoever owns the next gate, though: the file sits **inside K07's own RULES §1
area**, so if it is still there when the loop commits it becomes this screen's
problem, and the `NestKidTokens` error must be fixed (or the file deleted) before
any later stage can report `flutter analyze` → *No issues found found*. The
correct type is whatever `context.nest` returns for the kid tokens — the same one
`pip_evolution_sparks.dart:145` uses for `tokens.kidShadow.first.color`.

## Notes for the next stages (not findings)

- **Orchestrator still owes two rulings**, both recorded in
  `2b_build_ui.md:104-110` and `:188-190`: (a) finding 9 — accept the token
  re-theme of the inline-SVG accents in dark, or file a literal-accent token;
  (b) the K07 `KidScope` exception (lilac glow, no meadow) so a later iteration
  does not “fix” it back.
- **Stage 5 (UI)** still owes a `5_ui.md` for iteration 2: D2 has a new build
  and must be re-measured on the painted pixels, and the ±2 px verdict rule
  applies to the same anchors as iteration 1 (title, first control, each card
  top — design vs app). Iteration 1's D1 (+34 px stack shift, orchestrator-accepted
  as DB truth) and D3 (bubble tail, accepted) carry over unchanged.
- **`4_review.md` finding 9 is not a code change** either way: “tokens only,
  never hard-code colours” wins over the PNG export, exactly as for every other
  inline-SVG accent screen.

VERDICT: PASS