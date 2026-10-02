# P01 Welcome — QA code review (Stage 4, iteration 3)

> ## ⚠️ ORCHESTRATOR ACTION REQUIRED (not a screen defect — P01 needs no change)
>
> `ORCHESTRATOR_NOTES.md` item 5 asks the branch to assert "**CTA top identical**
> with bottomInset 0 vs 34". The enforced proof asserts the opposite of
> "identical" — `p01_bugs_test.dart:96` expects `baselineTop - 34` — because
> `NestBottomCta` reserves exactly the OS inset (measured: 672.0 → 638.0, a
> clean −34). The item's *intent* ("i.e. inset counted once") **is** satisfied,
> and design parity is confirmed on the reference device (stage-5 iteration 2:
> primary top 656.7 = design 656.7, band 6 0.39%). "Identical" is reachable only
> with a `max(viewPadding.bottom, NestDevice.homeH)` floor in the shared
> component — already filed as non-blocking `SHARED_REQUEST.md` item 2.
> **Pick one:** (a) amend item 5 to the shipped contract, or (b) land the floor
> and flip the proof to `closeTo(baselineTop, 1)` in the same commit. Neither is
> in P01's RULES §1 scope, so the screen cannot resolve it. Finding 1 below.

Scope: `git diff main` (branch commits + 6 uncommitted files) =
`app/lib/features/onboarding/presentation/views/welcome_view.dart`,
three files under `app/test/features/onboarding/`, `docs/screens/P01/**`.
No code was edited in this stage; one temporary probe test was created, run and
deleted (tree verified clean).

## Verification (first-hand, `app/`)

| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 342 files, 0 changed — clean |
| `flutter analyze` | `No issues found!` (3.2s) |
| `flutter test test/features/onboarding` | all pass, **0 skipped** |
| `flutter test` (full suite) | **`+355: All tests passed!`** — 0 failed, **0 skipped anywhere in the repo** |
| Isolation (`git diff main --name-only`) | only RULES §1 paths (view + 3 feature test files + `docs/screens/P01/**`) |
| Headline-metric probe | temporary, deleted — see finding 2 |

Every bug proof from stage 6 is now **enforced and passing** (`BUG-1`, `BUG-2`,
`BUG-3`, `BUG-3b`, `BUG-4`, `BUG-5`); the last two shared defects (kid-mode
gate, first-install persistence) were fixed on `main` (`71d2400`/`ded8eb9`,
`045d190`) and their proofs rewritten to the shipped contract.

---

## Findings

### 1. MINOR — mandatory note item 5's wording contradicts the enforced BUG-2 proof (owner: orchestrator)

**Where:** `docs/screens/P01/ORCHESTRATOR_NOTES.md:6` (item 5) vs
`app/test/features/onboarding/p01_bugs_test.dart:82-108`
(`expect(insetTop, closeTo(baselineTop - 34, 1))` at :96).

The note says to assert "CTA top **identical** with bottomInset 0 vs 34 … i.e.
inset counted once", and glosses "counted once" as *identical*. Under
`NestBottomCta`'s plain `SafeArea(top: false)` those are not the same thing: a
passthrough inset necessarily moves the block up by the inset (probe: 672.0 at
inset 0, 638.0 at inset 34, exactly −34), and the note's own "identical"
wording is inherited from a misreading of iteration-2 finding 1, which quoted
`baselineTop - 34`.

The enforced proof is the accurate description of the shipped, design-verified
behaviour, and it also pins the two things that matter: the CTA surface ends
34dp above the screen edge with a 34dp inset (:97-100) and the app home
indicator is a no-op (:101-105). I keep this **minor** rather than major
because: the item's stated intent is met, the screen's product state is
verified against the design on the reference device, and the "identical"
variant is not reachable from P01's edit scope — `NestBottomCta` is `core/**`
(RULES §1), and a local `MediaQuery`/`Padding` workaround would re-implement
the safe-area logic the component owns and would double-reserve once the floor
lands.

**Concrete fix (orchestrator, one line):** amend item 5 to "assert the shipped
contract: with a 34dp inset the CTA block moves up exactly 34 and its surface
ends 34dp above the screen edge", or land `max(viewPadding.bottom,
NestDevice.homeH)` in `nest_bottom_cta.dart` (symmetric with `NestStatusBar`'s
`max(viewPadding.top, NestDevice.statusH)`, which `SHARED_REQUEST.md` item 2
already asks for) and change :96 to `closeTo(baselineTop, 1)` in the same
commit. If the floor lands, also drop finding 4 below.

### 2. MINOR — the headline-break test is vacuous; the design break is only verifiable with real fonts

**Where:** `app/test/features/onboarding/welcome_view_test.dart:194-212`,
assertion at :209.

`expect(headlineSize.width, lessThanOrEqualTo(300.0 + 0.001))` re-asserts the
`ConstrainedBox`'s own width, so it passes for *any* cap value — including one
that fails to force the design's break. It cannot detect the regression it
names. The reason is environmental, and I measured it: in `flutter test` the
display style resolves to `Nunito_900` → the monospace test fallback, ~33.7pt
per glyph, i.e. "Chores that feel" measures 538.6 and the full headline 976.1 —
roughly 2.2× real Nunito, where "Chores that feel" is ≈250pt. A widget test
therefore cannot measure the design's line break at all.

**Concrete fix:** stop pretending the assertion guards the break. Either
(a) delete :209 and state in the test's comment that the break is owned by the
stage-5 band check (`band 4`), or (b) make it metric-conditional once fonts are
bundled (SHARED_REQUEST item 1 — with Inter/Nunito as real assets the fallback
disappears and a `TextPainter`-based assertion becomes valid:
`expect(_width('Chores that feel like'), greaterThan(300))` **and**
`expect(_width('Chores that feel'), lessThanOrEqualTo(300))`).
Note the 12 width × scale × theme tests remain a valid, in fact *conservative*,
overflow gate — the test font is far wider than Nunito, so wrapping there is
harder than in the app.

### 3. MINOR — `1_plan.md` still prescribes the uncapped headline

**Where:** `docs/screens/P01/1_plan.md:44-45` (and §a generally).

The plan specifies a bare `Text(... style: context.nestText.display)` with
`softWrap: true` and no measure cap, which `ORCHESTRATOR_NOTES.md` item 3
mandates away (`welcome_view.dart:236-237`). A later agent reading the plan
first could "restore" the plan and silently reintroduce the deviation the
orchestrator explicitly asked to be fixed.

**Concrete fix:** add one line to `1_plan.md` §a: "superseded by
`ORCHESTRATOR_NOTES.md` item 3 — the headline is wrapped in
`ConstrainedBox(maxWidth: 300)` to reproduce the HTML's `text-wrap: balance`
break; never a hard `\n`."

### 4. MINOR — `2_build.md` misstates the final state of the branch

**Where:** `docs/screens/P01/2_build.md:26-28` and `:53-56`.

It records "BUG-4 — stays skipped, still reproduces, filed" and
"353 passed, 1 skipped". Both were true when written and are now wrong:
`045d190` (`beforeOpen` insert-if-missing) landed, `p01_bugs_test.dart:157-…`
was rewritten to the shipped contract and un-skipped, and the suite is
`+355: All tests passed!` with **zero** skips. `3_test.md` and
`SHARED_REQUEST.md` are already correct and consistent, so only the build note
is stale.

**Concrete fix:** update those lines to "BUG-4 — fixed on main (`045d190`);
proof rewritten and enforced, passing" and "`+355: All tests passed!`, 0
skipped".

### 5. RETRACTED — explicit `skin`/`mood` on `PipAvatar` (iteration-2 finding 5): the decline was correct

I asked for `PipAvatar(style: mochi, skin: sunny, mood: idle, stage: 2)`. The
build stage declined and documented why; I verified both claims and **my
finding was wrong**:

- `skin: PipSkin.sunny` equals the parameter default
  (`pip_avatar.dart:235`), and `avoid_redundant_argument_values` is enabled
  through `include: package:very_good_analysis/analysis_options.yaml`
  (`app/analysis_options.yaml:1`; the rule is listed in
  `very_good_analysis-11.0.0/lib/analysis_options.10.2.0.yaml:45`), so the
  argument would fail `flutter analyze` — a RULES §7.1 gate.
- `PipMood` is declared twice: `pip_avatar.dart:43` and `pip_rive.dart:50`,
  and the DS barrel exports `pip_rive.dart`
  (`design_system.dart:35`) while the view imports `pip_avatar.dart`
  directly (`welcome_view.dart:7`) — an unqualified `PipMood.idle` is an
  ambiguous reference, i.e. a compile error.

Keeping the defaults is correct, the rationale is now in the code
(`welcome_view.dart:146-152`), and the resolved values are pinned by
`welcome_view_test.dart:276-279` (style/skin/mood/stage) plus the still-frame
and slot geometry. No change. (The underlying barrel collision is a shared
naming wart worth a `hide`/`show` or a prefix in the barrel — out of scope,
non-blocking, not filed since it does not affect behaviour.)

### 6. INFO — mandatory note 3 is implemented but not yet visually confirmed

`ConstrainedBox(maxWidth: 300)` (`welcome_view.dart:236-237`) landed *after* the
filed UI comparison, so `ui/cmp_*_2.png` (light 3.41%, dark 3.31%, band 4 ≈
5.8% — the headline break) still shows the pre-fix render. The next stage-5 run
is the gate for the one item the orchestrator called "the ONLY design item
left": the headline must read `Chores that feel` / `like a game.` at 390dp and
band 4 should collapse. Everything else is already exact (CTA block 656.7 =
656.7, body bottom 595.0 vs 593.3, bands 1/3 ≤ 0.70%).

### 7. INFO — `_headlineW = 300` is an emulation constant

Flutter has no `text-wrap: balance`, which is what produced the design's
balanced break in the HTML; a measure cap is the standard workaround and the
note sanctioned ≈300. No design token exists for a text measure, the value is a
named constant with a provenance comment (`welcome_view.dart:223-227`), and it
never hard-codes a colour, font or spacing token. Once fonts are bundled
(SHARED_REQUEST item 1) the cap can be re-derived from real metrics instead of
being tuned.

### 8. INFO — carried, no action

Rive idle loop vs the static design PNG (§6 compliant by construction inside
`PipAvatar`; `shot.sh` always passes `DISABLE_ANIMATIONS=1`); `Positioned`
width/height duplicating `_SceneCoin(size: …)`; `NestHomeIndicator()` now a
no-op in the app (correct for the reference device — see finding 1 for the
inset-0 case).

---

## What passed

- **Architecture (docs/ARCHITECTURE.md):** feature-first shape intact; the view
  stays at `features/onboarding/presentation/views/welcome_view.dart`; no bloc
  subscription, no `domain/`/`data/` edits, no use-case classes; `OnboardingBloc`
  remains owned by the route-level `BlocProvider`
  (`onboarding_routes.dart:30-37`) and its `emit.forEach` subscription is
  closed with the route; navigation via route constants only.
- **Isolation (docs/screens/RULES.md):** `git diff main --name-only` =
  `features/onboarding/presentation/**`, `app/test/features/onboarding/**`
  (3 files), `docs/screens/P01/**`. Nothing in `app/lib/core/**`,
  `app/lib/app/**`, `tools/**` or any other test directory. Every shared fix
  arrived through merges of `main` (`71d2400`, `763192d`, `ded8eb9`, `e94d063`,
  `045d190` — all verified ancestors of `main`), not as worktree edits. No
  `analysis_options` change, no test deleted, renamed, weakened or skipped.
- **Design system:** every colour, font, spacing and device value resolves
  through `context.nest` / `context.nestText` / `NestSpacing` / `NestType` /
  `NestDevice` / `NestlingIllustrations` / `PipAvatar`; zero hex literals, no
  hand-built `TextStyle`, no re-implemented component (`NestStatusBar`,
  `NestBottomCta`, `NestButton` primary + ghost, `NestHomeIndicator`,
  `PipAvatar` all reused).
- **Spec parity (DESIGN_SPEC §5 P01, `DESIGN_SPEC.md:146`):** every element
  present and ordered, copy character-exact and UK ("Chores that feel like a
  game." / "…want to finish — and keeps pocket money fair and tidy." /
  "Made in the UK · No ads, ever"). The one divergence is the Pip asset, which
  the orchestrator rules mandate.
- **ORCHESTRATOR_NOTES:** item 1 — `PipAvatar` in the unchanged 168×168 @ (91,120)
  slot, v1 SVG asserted absent, idle still frame under reduced motion, HTML alt
  text preserved. Item 2 — status-bar differences ignored, stale `9:41`
  assertion gone. Item 3 — cap implemented (`:236-237`), pending visual
  confirmation (finding 6). Item 4 — home pill / frame instability not chased,
  correctly. Item 5 — proof un-skipped and enforced; wording conflict is finding 1.
- **Accessibility:** single heading with `isHeader` pinned; decorative nest,
  coins and chrome excluded from semantics; the HTML alt text exposed on the
  Pip; both CTAs full-width 52dp ≥ `NestDevice.tapParent` with `isButton` and
  no icon-only or kid controls; no overflow across
  {light, dark} × {320, 390, 430}dp × {1.0, 1.3} scale.
- **Performance:** `const` throughout the static subtree; no `setState`, no
  timers, no rebuild storms; the narrow-width fix is a paint transform with a
  fixed 350×388 layout; the Rive file is loaded once per style behind an FFI
  capability gate and degrades to a still frame; no stream is created or
  retained by the view.
- **Error handling:** identical brand content for `initial`, `loading`,
  `loaded` (empty and populated) and `failure`; a repository error can never
  blank the screen.
- **Children's Code:** no child data, analytics, ads, tracking or identifiers;
  P01 is parent-only and the whole onboarding flow is now gated in kid mode,
  with two enforced proofs that `/welcome` and `/value-tour` both land on
  `/parental-gate`; the Pip shown is the mandated onboarding default
  (Mochi/sunny), not another family's data.

## Remaining work

Screen: **none** — code, tests (0 skips, 355 green), isolation and docs are
complete. Two cheap follow-ups for whoever picks this up: findings 2 and 4
(vacuous assertion; stale build note), and finding 1 for the orchestrator
(note amendment **or** the shared floor). Stage 5 must re-run `shot.sh` +
`compare.py` (light and dark) to close finding 6 — the last open design item.

VERDICT: PASS
