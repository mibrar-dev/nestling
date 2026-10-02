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

VERDICT: FAIL