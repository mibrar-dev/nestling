# Fix list after iteration 5

## From 3_test.md
# P03 Create account — test notes (Stage 3, iteration 5)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**One real bug remains open**: P03-BUG-16 (an invalid input paints no
`danger` border). The iteration-5 build closed everything else — both bugs I
reported, including the a11y regression — and I verified each fix on the
simulator and with new proofs. What is left is a single **shared-blocked**
defect: the screen cannot have both the design's red border and the live
region the error needs, because the shared `NestTextField` only offers one
or the other.

I have **un-skipped** that proof rather than leave it skipped: a skipped
proof is not evidence, the standing rule for this stage is never to skip a
test, and the premise the skip rested on is stale (§5 of the shared request
already records that the change it was waiting for landed). So `flutter test`
is red by design: **1** proof fails, everything else passes (790 green, **0
skipped**).

## The iteration-5 fixes, verified

- **BUG-21 (MAJOR, the empty live region) — fixed properly.** Walking the
  whole semantics tree after a rejected submit now shows
  `live=true label="Enter a valid email address"` and
  `live=true label="Use at least 8 characters"`, each exactly once, with no
  duplicate node: the message rides on the `Semantics` wrapper and the inner
  `Text` stays excluded. The BUG-20 proof was extended to assert the *label*
  as well as the flag, which closes the hole the regression went through.
- **BUG-6 (MINOR, shared) — fixed by the shared batch, un-skipped.** The CTA
  is now a single `Create account` node. That was the suite's last skip, so
  the feature suite now runs with **zero** skipped tests.
- **Review finding 5 (`_verifyTotal` capped for the widget's lifetime) —
  fixed.** Five consecutive resizes (320 → 430 → 390 → 390 → 320) leave both
  link targets on their words; before the fix the verification chain would
  have been exhausted after ~3 relayouts.
- **Layout is unchanged**: compare.py mean diff **4.65%** (was 4.66%), CTA
  surface top 678 (design 677), submit button 694–745.7 exactly, both
  caption lines exact, bottom-edge owner rule holds (surface to y=844). The
  shared component change did not shift anything, because P03 hands it
  `errorText: null` and owns the helper row.

## Tests added this stage

`copy_audit_test.dart` 15 → **16** (1 added, green) — *"five consecutive
resizes keep both targets on their words"*: the regression guard for the
re-armed verification chain.

`p03_bugs_test.dart` — BUG-16 un-skipped (now red) and the file header
rewritten to state the suite's real status (it still described skip-marked
open proofs; there are none). No new proofs were needed: BUG-21 and BUG-6 are
already pinned by the build's own (now green) proofs, which I re-verified
against the semantics tree rather than taking on trust.

Coverage is otherwise complete and unchanged: `auth_bloc_test.dart` (45),
`create_account_view_test.dart` (48) and `seeded_submit_test.dart` (7) cover
every bloc event/state path, the 320/390/430 × 1.0/1.3 matrix in both
themes, all five bloc statuses, both seeds, every tap target and route, the
44 dp rule and the bottom-edge rule. I found no new gap.

Feature total: 142 → **145** (144 green, 0 skipped, 1 red).

## Bugs found

### P03-BUG-16 (MINOR, still open — now provably local, blocked only on §8)

An invalid input keeps the resting `line` border. Measured on the current
tree: the only opaque borders painted anywhere on the screen are `ff000000`
and `ff000000`/`ffe7e0d4` (= `tokens.line`) — **no `tokens.danger` border is
painted at all**. The design marks the input itself:
`.field input[aria-invalid="true"] { border-color: var(--danger) }`
(`design/html-source/components.css:135`, `docs/design/SPACING_SPEC.md` §3).

What changed since I first reported it (iteration 3): the shared batch
`7eaa1f7` landed **both** halves of what was missing — `NestTextField` now
renders `errorText` as a gutter-aligned row (`nest_text_field.dart:197-206`)
*and* forces the danger border when `errorText != null` (`:160-172`), and
pinned both in `shared_batch1_test.dart`. So passing `errorText` no longer
re-opens P03-BUG-11; the screen's owned gutter rows are now redundant with
the component's.

The build skip-marked the proof on the premise that this needed a shared
`hasError` flag that "never landed", and its own proof comment says the
opposite ("in fact `7eaa1f7` landed the gutter row + forced danger border, so
the remaining work is local"). The real remaining gap is narrower: the
component's error row is a plain `Text`, not a live region, so switching
today would trade BUG-16 for BUG-20 — dropping the announcement of the
validation message, which is the worse of the two. That half is
SHARED_REQUEST §8, and it is a three-line core change (wrap the shared row
in `Semantics(liveRegion: true)`).

**Path to green**: land §8 in core, then in the screen pass `errorText:` to
both fields and delete the two owned rows (and their `buildWhen` selectors).
That closes BUG-16 and BUG-11 together, and this proof goes green with no
other change. I did not make that change — the brief forbids the test stage
patching the screen.

Repro: `flutter test test/features/auth/p03_bugs_test.dart` — proof
P03-BUG-16 measures the borders painted inside the keyed field before and
after a rejected submit.

## Non-blocking observations

- The trade the screen currently makes is the defensible side of it: a screen
  reader must hear the error, and the message itself is already red, so the
  missing border is a redundant cue rather than the only one. Worth stating
  plainly so this is not mistaken for an oversight.
- The device geometry has a ~4 dp strip where the submit button and the Terms
  target both receive a tap (button 694–745.7, Terms target ≈741.7–785.7).
  Inert today because the links are (`TODO(P03)`); note it where the link
  routes land.
- `_HitTestExpand.extra` is still never read by `hitTest` — the overhang is
  bounded by each target's own 44 dp box, which is correct, but the field and
  its `markNeedsPaint` are dead weight.
- P03-BUG-17 (the subtitle breaks after "Children") stays a shared
  font-pipeline item (SHARED_REQUEST §6); the orchestrator's iteration-5 note
  confirms a shared `shared/body_text_width` fix is in flight, and no local
  test can pin a break the harness font does not produce.
- ORCHESTRATOR_NOTES §3 (filled-state simulator capture) remains the UI
  stage's; the filled state is pinned by the widget test.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 371 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **144 passed, 0 skipped, 1 failed**
  (the single red proof above). Per file: `auth_bloc_test.dart` 45/45,
  `create_account_view_test.dart` 48/48, `copy_audit_test.dart` 16/16,
  `seeded_submit_test.dart` 7/7, `p03_bugs_test.dart` 29 green + 1 red.
- `flutter test` (full suite) → **790 passed, 0 skipped, 1 failed**.
- `shot.sh` light + `compare.py` → `ui/light.png`, `ui/compare-light.png`
  (mean diff 4.65%; bands 0–5 all under 3%; the CTA is pixel-exact).


## From 4_review.md
# P03 Create account — QA code review (Stage 4, iteration 5)

Scope reviewed: `git diff main` for P03 — `app/lib/features/auth/**` (view, bloc,
domain, data, glyphs) + `app/test/features/auth/**` + `docs/screens/P03/**`. No code
was edited by this stage. Reference set: `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P03 (line 150) and §0.9, `docs/design/SPACING_SPEC.md`,
`design/html-source/screens/P03-create-account.html`, `design/html-source/components.css:129-135`,
`ORCHESTRATOR_NOTES.md` (mandatory), the standing COPY rule, `1_plan.md`, `FIXES_1…4`,
`2_build.md`, `3_test.md`, `SHARED_REQUEST.md`.

Evidence gathered by this stage:

- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth/p03_bugs_test.dart --reporter=expanded` → one red
  proof only: `P03-BUG-16 an invalid field paints the danger border [E]`. Everything
  else is green: BUG-15 (curly apostrophe — byte-verified U+2019 on the device capture),
  BUG-18/19/20/21 (hit-test overhang, synchronous mirror, live region + label) all pass.
- I read the iteration-5 shared `NestTextField` (`nest_text_field.dart:120-175`): the
  decoration no longer takes `errorText` (it is forced to `errorBorder` when
  `errorText != null`), the error row is a **gutter-aligned row under the input** with
  `helperText` suppressed on error, and `shared_batch1_test.dart:252-267` pins all three
  behaviours. So §5 is genuinely landed on this branch (merged `7eaa1f7` / `4751c52`),
  including the half the iteration-4 build note said had "not landed".
- Pixel check of `ui/light.png` vs the design: CTA hairline 678 vs 677; submit button
  694–745 in both; caption line 1 one sky run x 262–300 (design 258–297) = "Terms",
  line 2 x 149–241 (design 150–240) = "Privacy Notice"; helper ink 130dp vs 125dp wide
  (the Inter-build width drift, §6, unchanged); `surface` uniform to y=844.
- `git status` touches only `app/lib/features/auth/**`, `app/test/features/auth/**`,
  `docs/screens/P03/**` — RULES §1 respected.

## Iteration-4 findings — all six addressed

| # | Iteration-4 finding | Status |
|---|---|---|
| 1 | BLOCKER — red suite; BUG-11/BUG-16 mutually exclusive | **corrected**: §5 has since landed, so the exclusion no longer holds; one proof still needs a decision — see finding 1 |
| 2 | MAJOR — empty live region (BUG-21) | **closed**: both owned rows now `Semantics(liveRegion: true, label: …)` (`:193-196`, `:251-254`), with the label asserted in proofs |
| 3 | MINOR — dead `extra` field | **closed** (removed) |
| 4 | MINOR — fallback fires after a hit | **rejected by the build with a shaky reason** — see finding 2 |
| 5 | MINOR — `_verifyTotal` lifetime cap | **closed** (reset in `didChangeDependencies`, `:409`) |
| 6 | MINOR — stale §5 disposition | **closed** (reworded to the skip-with-reason outcome) |

I also audited the claims the build note makes that I had not directly verified before:
the `NestTextField` shared half of §5 is genuinely done (see Evidence), the caption
mirror is pinned by equality proofs, `copy_audit_test.dart` is 10/10 green, and the
caption/CTA geometry is unchanged and correct.

## Checked and clean (no finding)

- **Architecture** — `domain/` = entity folder + abstract repository (enum inlined),
  one bloc per screen from `registerAuth`, route-path constants only for cross-feature
  navigation, no use-case classes, `package:nestling/...` only.
- **RULES §4** — password never persisted; owner row idempotent; legacy
  `createAccount(name:)` alias still documented for the one shared caller.
- **RULES §7** — see finding 1: it currently fails only because of the unresolved
  BUG-16 decision; everything else is green.
- **Geometry (measured, device vs design)** — hairline 678 vs 677, submit 694–745 in
  both, caption break and link positions within ~4dp, bottom-edge OWNER rule holds in
  both themes (uniform `surface` to y=844), 20px gutters intact.
- **Design system** — DS components only; `NestBottomCta.caption` avoided; the caption
  line-height override is now token-expressed (`NestSpacing.s5 / 13`) and pinned by
  `P03-BUG-12`; the brand glyphs are still the HTML's own artwork.
- **A11y intent** — headline is the only `header:`; `or`-row, glyphs, shield excluded;
  error rows announced once and labelled once; submit failure announced via
  `sendAnnouncement`; every target ≥44dp at 320/390/430 × 1.0/1.3.
- **Error handling** — both submits `on Object catch` + `addError`; the screen cannot
  strand a spinner.
- **Performance / lifecycle** — brand buttons on `BlocSelector(isSubmitting)`, fields on
  `buildWhen` error selectors, static rows never rebuilt; controllers disposed; the bloc
  subscription is route-scoped; no timers, no animations.
- **Children's Code / privacy** — parent mode only; no analytics, ads, network calls,
  child data, photos or locations; the copy states the privacy position.
- **`ORCHESTRATOR_NOTES` iteration-3 §2** — apostrophe fixed; the break stays a shared
  font-pipeline item (§6), correctly not chased locally.

## Findings

### 1. BLOCKER — the suite is red by exactly one proof, and the loop is oscillating on it

`app/test/features/auth/p03_bugs_test.dart` — `P03-BUG-16 an invalid field paints the
danger border` (un-skipped by Stage 3, iteration 5, per `3_test.md`).

Two stages have now landed on opposite states for the same proof: the iteration-5 build
skip-marked it "until §8 lands", and Stage 3 un-skipped it on the grounds that §5 has
landed. **Both are half right.** The build's reason was wrong (it still claimed the
shared `hasError`/gutter row had "not landed" — it has; I read `nest_text_field.dart` and
the border now defaults to `errorBorder` whenever `errorText != null`, and the shared row
is gutter-aligned). Stage 3's conclusion ("passing `errorText` no longer re-opens
BUG-11") is correct as far as layout goes. But the switch still cannot be made without
deciding `SHARED_REQUEST.md` §8: the shared error row is a **plain `Text`** — no live
region — so passing `errorText` fixes the border and the layout, and silently deletes the
announcement my iteration-3/4 review (and Material's own `InputDecoration`) judged
correct. That is the one open decision, and it is the owner's, not the build's:

- **Decision A (recommended)** — the announcement wins: keep the screen-owned
  live-region rows and **skip `P03-BUG-16` with the explicit reason
  `SHARED_REQUEST.md §8`**, so the guard stays visible, the suite is green, and the
  defect is tracked to its true unblock (three lines in `nest_text_field.dart`).
- **Decision B** — the shared row wins: pass `errorText` to both fields, delete the
  owned rows, and formally close §8 as *won't-fix*. `P03-BUG-16` goes green with the
  same one-line change, but the announcement requirement is dropped — say so in the
  review and do not keep `P03-BUG-20/21` as live-region proofs then.

Either decision unblocks the loop; the current state (red proof + disagreement) does not.

### 2. MINOR — `_HitTestExpand` still lacks a `!hit` gate, so a tap in the submit/caption overlap double-fires

`create_account_view.dart` `_RenderHitTestExpand.hitTest` (`:677-691`). The verification
fallback runs for every point outside the caption stack's rect, with no check of whether
the normal path already claimed the tap. On the device geometry the Terms target's top
(≈741.7) overlaps the submit button's last ~4dp (694–745.7), so a tap there reaches both
the button's `onTap` and the link's `onTap`. Today the link is inert so the effect is
nil, but the moment Terms/Notice routes exist that strip double-activates.

The build rejected the fix on the grounds that "delegating first can never fall through —
the bar background always claims every in-panel tap." Walking the chain shows otherwise:
for an overhang tap every intermediate box bounds-checks the point away (the CTA
`DecoratedBox` contains it, the caption `Stack` does not descend, the gap `SizedBox`
claims nothing), so the normal path returns `hit == false` exactly where the fallback is
needed. Gating the fallback behind `if (!hit && !stackRect.contains(position))` therefore
preserves BUG-18 for overhang taps and removes the 4dp double-fire. Add a `tapAt` proof
for a point inside the submit button asserting the link's `onTap` did not also run (the
harness cannot reproduce the device's overlap strip, but an explicit `onTap` count still
proves the gate).

### 3. MINOR — the owner still needs to adjudicate `SHARED_REQUEST.md` §5 vs §8 wording

`SHARED_REQUEST.md` §5 now reads that §5 is **RESOLVED** (correct — I verified the
shared row is gutter-aligned, forced to `errorBorder`, helper-suppressed), but the
iteration-5 build note's premise ("the shared row has no live region (§8), so switching
would trade BUG-16 for BUG-20") is recorded there as if §5 were still open, and §8 still
reads "Blocks: no — P03 can fix BUG-21 locally…but not BUG-16 without this." Once the
decision in finding 1 is made, §5's "Consequence for P03" paragraph and §8's "Blocks"
line should say which disposition was chosen, so the next stage does not un-skip/re-skip
the proof a third time. This is the same oscillation as finding 1, at the document level.

## Notes for the next stage

- Decide §8 (finding 1) — that, plus the one-line switch if the owner chooses Decision
  B, is the only blocker. Then 2 (one gate + one `tapAt` proof), then 3.
- Nothing else is owed on this screen this iteration: the layout is within ~1–4dp of the
  design in both themes, the caption break and positions match, the copy audit is 10/10,
  the mirror proofs are exact, and the live-region labels are byte-identical to the
  design's messages.
- `ORCHESTRATOR_NOTES.md` iteration-3 item 3 (filled-state capture on the simulator) is
  still outstanding for the UI stage; the filled *state* is pinned by the widget test.

