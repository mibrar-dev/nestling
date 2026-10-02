# P03 Create account — QA code review (Stage 4, iteration 3)

Scope reviewed: `git diff main` for P03 — `app/lib/features/auth/**` (view, bloc,
domain, data, glyph widgets) + `app/test/features/auth/**` + `docs/screens/P03/**`.
No code was edited by this stage. Reference set: `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P03 (line 150) and §0.9,
`docs/design/SPACING_SPEC.md` §3, `design/html-source/screens/P03-create-account.html`,
`design/html-source/components.css:129-135`, `ORCHESTRATOR_NOTES.md` (**all items
mandatory**, including the iteration-3 additions), the standing **COPY** rule
(typographic characters exactly), `1_plan.md`, `FIXES_1.md`, `FIXES_2.md`,
`2_build.md`, `3_test.md`, `SHARED_REQUEST.md`.

Evidence gathered by this stage:

- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **132 passed, 1 skipped, 2 failed**; the two
  red are `copy_audit_test.dart` "subtitle" and `p03_bugs_test.dart` `P03-BUG-16`.
- Copy bytes: `od -c` on `create_account_view.dart:116` shows `Y o u ' r e` — a
  straight U+0027. `P03-create-account.html` has `You&rsquo;re` (U+2019).
- Pixel measurement, `design/screens/{light,dark}/P03-create-account.png` vs
  `docs/screens/P03/ui/light.png`: CTA hairline **y=677 design / y=678 app**;
  caption line 1 one sky run x 262–300 (design 258–297) = "Terms", line 2 one run
  x 149–241 (design 150–240) = "Privacy Notice"; subtitle line 1 ends x=330 after
  "Children" (design ends x=368 after "never"); CTA `surface` uniform to y=844.
- Flutter SDK: `rendering/proxy_box.dart:183-192` — `RenderProxyBox.hitTest` only
  descends into children when `size.contains(position)`; `material/input_decorator.dart:419`
  — the framework wraps `errorText` in a `liveRegion`.
- Font pipeline: `pubspec.yaml` declares **no** `fonts:` assets and
  `tokens/typography.dart:20,36` call `GoogleFonts.inter/nunito` (resolved at runtime).
- `git status` touches only `app/lib/features/auth/**`, `app/test/features/auth/**`,
  `docs/screens/P03/**` — RULES §1 respected.

## Iteration-2 findings — all six closed

| # | Iteration-2 finding | Status | Evidence |
|---|---|---|---|
| 1 | BLOCKER — red suite | partly | 7 red proofs → 2; the remaining pair is findings 1–2 below |
| 2 | MAJOR — "Privacy Notice" split | **closed** | U+00A0 label; device line 1 = "Terms" only, line 2 = "Privacy Notice" (matches design within 4dp) |
| 3 | MAJOR — targets not over their words | **closed** | rects measured off the laid-out paragraph; live-resize/scale/theme proofs green |
| 4 | MINOR — targets 44×36 | **closed on paper** | `_targetRect` gives ≥44×44 by construction — but see finding 4 |
| 5 | MINOR — error indented 20dp | **closed** | both fields render the error in the owned gutter row (`:186-191`, `:234-240`) |
| 6 | MINOR — dropped stack trace | **closed** | `on Object catch (error, stackTrace)` + `addError` |

I also audited the four proofs the build **re-anchored** (18dp→20dp caption lines,
`BUG-1a/1b/1d` bounds 64/156/108, `BUG-10b` vertical separation, the `BUG-9/9b`
line-band predicate). They are sound, not weakenings: each new bound still fails the
iteration-1/2 buggy values by a wide margin (64 vs 80, 156 vs 214, 108 vs 140), and
`BUG-10b`'s vertical form still fails the iteration-2 adjacent 88dp block.

## Checked and clean (no finding)

- **Architecture** — `domain/` holds only the entity folder plus the abstract
  repository (enum inlined in `auth_repository.dart:4`); one bloc per screen, created by
  `registerAuth`, provided at the route level; cross-feature navigation uses route-path
  constants only; `package:nestling/...` imports; no use-case classes.
- **RULES §4** — password never persisted; owner row idempotent; `createAccount(name:)`
  legacy alias still documented for the one shared caller.
- **Geometry (measured, device vs design)** — CTA hairline 678 vs 677 (+1dp, was +47);
  caption two lines with the design's break and positions; Apple button, headline,
  helper, note all within 0–2dp (per stage 3's table, consistent with my own scan);
  bottom-edge OWNER rule holds (uniform `surface` to y=844, light and dark); 20px
  gutters and control edges unchanged.
- **Copy** — 8 of the 9 user-facing strings are byte-identical to the HTML and now
  guarded by `copy_audit_test.dart`, including the U+2014 em dash and the single U+00A0.
  Only the subtitle's apostrophe deviates (finding 2).
- **Rebuild scoping** — brand buttons on `BlocSelector(isSubmitting)`, fields on
  `buildWhen` error selectors, the CTA on `canSubmit`; a keystroke no longer rebuilds
  the static rows. Controllers disposed; the `watchItems()` subscription belongs to the
  route-scoped bloc; no timers, no animations.
- **Error handling** — both submits `on Object catch` + `addError`, so a non-`Exception`
  can no longer strand a spinner, and the failure is announced to assistive tech.
- **Children's Code / privacy** — parent-mode only; no analytics, ads, network calls or
  child data; the copy states the privacy position.
- **Test-proof audit** — the iteration-3 proofs measure through `RenderParagraph`
  (`getBoxesForSelection` / `computeLineMetrics`), so they are font-independent, which is
  the right way to pin this screen; `copy_audit_test.dart` transcribes the HTML strings
  with explicit escapes so no invisible character hides in the test either.

## Findings

### 1. BLOCKER — red suite, and two of its proofs cannot both pass inside RULES §1

`app/test/features/auth/copy_audit_test.dart` ("subtitle") and
`app/test/features/auth/p03_bugs_test.dart` (`P03-BUG-16`). RULES §7 requires
`flutter test` → all pass.

The important part for the loop: **`P03-BUG-11` (error on the gutter) and `P03-BUG-16`
(danger border on an invalid input) are mutually exclusive with the shared component as
it stands.** `NestTextField` derives both from one flag — `errorText != null` selects
`errorBorder` (`nest_text_field.dart:128-171`) *and* Material's indented error row.
P03 needs `errorText: null` for the gutter row, so the border is gone; passing
`errorText` restores the border and brings the 20dp indent back. Fixing one proof
regresses the other, so iteration 4 cannot converge on P03 alone.

Resolution (in this order):
1. Orchestrator lands the `NestTextField` fix already filed as `SHARED_REQUEST.md` §5 —
   lay the error out on the gutter **and** drive the danger border from a separate
   `hasError` flag (or `errorBorder` prop). Then both proofs go green.
2. Until it lands, keep the gutter-aligned error (BUG-11, the visible defect) and retire
   the `P03-BUG-16` proof with a comment pointing at `SHARED_REQUEST.md` §5. Do **not**
   pass `errorText` again just to satisfy BUG-16 — that re-opens a major.

Finding 2 (the apostrophe) is a one-character fix and closes the other red proof.

### 2. MAJOR — the subtitle uses a straight apostrophe where the design has U+2019

`app/lib/features/auth/presentation/views/create_account_view.dart:116`.

`"You're the grown-up in charge. "` ships U+0027 (verified byte-wise). The HTML writes
`You&rsquo;re`, `ORCHESTRATOR_NOTES.md` iteration-3 item 2 names this explicitly
("curly apostrophe 'You're' (U+2019) as in the design/HTML"), and the standing COPY rule
requires the design's characters exactly. `copy_audit_test.dart` is red on it.

Stage 3 rated this MINOR; I rate it **MAJOR** because it is an explicitly mandatory
orchestrator item, it violates a standing rule, and it ships red.

Fix: `You\u2019re the grown-up in charge. Children never need an email.` (keep it a
real character, not a hard `\n`; the apostrophe must not be split from its word — a
NBSP after the apostrophe is not needed, only `Privacy Notice` needs one).

### 3. MINOR (blocked on shared) — the subtitle still breaks one word early

`create_account_view.dart:113-117`. `ORCHESTRATOR_NOTES.md` iteration-3 item 2 also asks
for the break `…Children never` / `need an email.`; the device renders `…Children` /
`never need an email.` (my measurement: app line 1 ends x=330, design x=368).

The style is already the design's token (`NestType.body` = Inter 16/24;
`tokens.css:66` `--fs-body: 16px; --lh-body: 24px`, no letter-spacing on either side),
so this is a font-pipeline difference, not a styling bug: I re-measured the app's
Inter as ~4% wider than the design's render ("At least 8 characters" 130dp vs 125dp;
the note row 246dp vs 238dp), and the design's subtitle line 1 uses 348 of the 350dp
content width — 2dp of headroom that a 3–4% wider face cannot fit. It cannot be fixed
in P03 without breaking "tokens only" (no font-size or letter-spacing override, no
wider box). Already filed as `SHARED_REQUEST.md` §6; the orchestrator owns it (pin or
bundle the Inter build the designs were rendered with). **Do not chase it with a local
width or size hack** — that would trade a 4% glyph-width drift for a token violation.

### 4. MINOR (new) — the "44dp" legal targets are only ~32dp *reachable*

`create_account_view.dart:414-418` (`_targetRect`) and `:456-468`
(`Positioned.fromRect`).

`_targetRect` centres a 44dp-tall box on the link's own glyph box, so each target
overhangs the caption block (40dp for the two 20dp lines) by ~4dp at each end. Flutter
only hit-tests a child when the tap is inside the parent's own box
(`rendering/proxy_box.dart:183-192`: `if (size.contains(position))`), and
`Positioned` does not enlarge the parent — so the overhang is inert. Reachable height is
the intersection with the caption block: ≈32dp per target at 390dp, not 44dp. The proofs
(`P03-BUG-13`, `create_account_view_test.dart` a11y group) read
`tester.getSize`/`getRect` of the render box, which reports 44dp and therefore cannot
see this — the same blind spot as iteration 2's finding 4, one level up.

Fix (choose):
- make the caption block at least 44dp tall so the targets sit **inside** the parent
  box: `Stack(alignment: Alignment.center)` inside
  `ConstrainedBox(constraints: BoxConstraints(minHeight: NestDevice.tapParent))`.
  Cost: the block grows 40→44dp and the CTA hairline moves from 678 to ~674 (design
  677) — a real trade, so it must be an explicit decision, and it needs a
  `tester.tapAt`-style proof (tap the extreme top/bottom of the target, assert the
  tap lands) rather than a size assertion;
- or, while the links are inert in v1, state the limitation in the doc comment, add a
  `hitTest`-based proof that documents the reachable box, and revisit when the
  Terms/Notice routes land.
  Either way, stop describing the targets as 44dp-tall without qualifying it.

### 5. MINOR (new) — the post-frame measurement can go stale (font swap, first frame)

`create_account_view.dart:356-410` (`_scheduleMeasure`, `_measure`).

The targets' rects are read from the laid-out `RenderParagraph` in a post-frame callback
and re-scheduled only from `initState` and `didChangeDependencies` (MediaQuery size,
text scaler, theme). No font is bundled (`pubspec.yaml` has no `fonts:` section;
`typography.dart:20,36` call `GoogleFonts.inter/nunito`, resolved at runtime), so on a
cold launch the first layout can be laid out with a fallback face: `_measure` then caches
*fallback* metrics, the real Inter arrives on a later frame, the paragraph reflows, and
nothing re-runs the measurement — the targets stay where the fallback put them until some
unrelated dependency changes. The same round-trip also means **no targets exist during
the first frame** (invisible in screenshots, but a screen reader announcing on first paint
would find the links missing).

Fix: make the rects follow layout instead of a one-shot side effect — either re-measure
while the caption is unsettled (chain post-frame callbacks until two consecutive
measurements agree *and* the fonts are resolved, e.g. `GoogleFonts.pendingFonts()` is
empty), or derive the boxes during layout with a small `RenderBox`/`CustomPainter` that
computes them from a `TextPainter` in `performLayout`. Add a proof that a relayout
without a dependency change (a font swap, or any future caption-text change) keeps each
target over its word.

### 6. MINOR — the owned error rows lost the framework's live region and their field association

`create_account_view.dart:186-191` (email) and `:234-240` (password).

Moving the message out of `InputDecoration` (correct for the gutter) also moved it out
of the field's semantics. Material wraps `errorText` in a live region
(`material/input_decorator.dart:419`, `liveRegion: !MediaQuery.supportsAnnounceOf`), so
before this iteration a VoiceOver user heard the validation error the moment the field
went invalid; now the message is an unrelated static text node. The
`SemanticsService.sendAnnouncement` in this screen only fires for `formError` (server
failures), so **client-side validation errors are announced by nothing**.

Fix: wrap each owned error row in a live region so it announces when it appears —
`Semantics(liveRegion: true, child: ExcludeSemantics(child: Text(...)))` (keep the inner
`Text` out of semantics so the label is read once), and keep
`SemanticsService.sendAnnouncement` for `formError` as it is. Add a semantics proof that
the error node carries `SemanticsFlag.isLiveRegion` once a submit is rejected.

### 7. MINOR — `height: 20 / 13` hard-codes the design's link line height

`create_account_view.dart:425` and `:430`. The rule is tokens-only; `20` is
`NestSpacing.s5` and `13` is the caption font size baked into `NestType.caption`, so the
literal hard-codes a type metric the design system owns.

Fix now: express it as `NestSpacing.s5 / 13` with the `.link { line-height: 20px }`
citation kept in the comment, and add a `SHARED_REQUEST.md` item for a proper
`NestType.legalCaption` (13/20 w400 + 13/20 w600 sky) in
`core/design_system/tokens/typography.dart`, after which both `copyWith(height: …)` calls
disappear. Until then the override is legitimate — it is the design's line height and it
is pinned by `P03-BUG-12` — so this is a token-debt item, not a regression.

## Notes for the next stage

- Order: finding 2 (one character) → finding 1's resolution (orchestrator decision, not
  a code change) → findings 4, 5, 6 (all in `_LegalLine` / the owned error rows) →
  finding 7 (token debt + SHARED_REQUEST item).
- Everything else is in good shape: the screen is now within 0–2dp of the design from
  the back chevron to the privacy note, the caption break matches the design, the bottom
  edge and gutters hold in both themes, and the rebuild scoping, error surfacing and
  proof calibration are all sound.
- `ORCHESTRATOR_NOTES.md` iteration-3 item 3 (a filled-state capture on the simulator)
  remains outstanding for the UI stage; the filled *state* is already pinned by
  `create_account_view_test.dart`'s "design filled state" group.

VERDICT: FAIL