# P03 Create account — build report (Stage 2, iteration 8 · INTEGRATE)

Route `/create-account` · feature `auth` · parent mode. This stage merged the
two parallel builders — `2a_build_logic.md` (logic) and `2b_build_ui.md` (UI) —
and made the combined tree compile and pass. No redesign; no contract
reconciliation was needed.

## Summary of 2a (logic)

Zero changes, re-verified by reading: the layer already matches `1_plan.md` —
`AuthProvider` + `createAccount({email, name})` (documented legacy alias for the
one shared caller outside RULES §1) + `createAccountSocial`, the Drift impl
(idempotent owner row, password never persisted — RULES §4), the bloc
(dirty-gated validation, `canSubmit`, `on Object catch` + `addError`,
in-flight guards) and DI/routes (`/create-account` + `AuthLoadRequested`).

**Contract changes: none**, so the halves could not have drifted on a state,
event or member name.

## Summary of 2b (UI) — P03-BUG-24 and the arbitration

- **The h1 now renders with `NestBalancedText`** (`textAlign: TextAlign.left`,
  `maxLines: 3`, same copy and `NestType.h1` token), and the hand-calibrated
  `_headlineMaxWidth = 240` constant and its comment are **deleted** — the
  pattern the BALANCED HEADINGS rule exists to replace. Nothing else in the
  view or widgets changed.
- One stale expectation in `typography_test.dart` updated (see below); it sits
  outside 2b's named `view`/`widget` scope, which 2b declared rather than
  leaving the suite red.

**The arbitration, verified here rather than taken on trust.** Stage 3 and the
bug stage both predicted the two orchestrator halves were mutually exclusive:
that with the cap deleted a 350 dp column balances to `Create your family` /
`account`, which would break the design. 2b measured otherwise, and the tree
now proves it: `the balanced headline keeps the design break and gutter` pumps
**the real screen** (no cap) and asserts the design's exact split
`['Create your', 'family account']`, both lines' ink widths against the design
PNG, and the 20 px gutter. The component first takes the minimum line count at
full width (2) and then binary-searches the *narrowest* width that still holds
2 lines — the design's 197.68 dp. So the cap was a no-op that merely capped
the search, and dropping it reproduces the design break by itself. The headline
band is still pinned transitively: `the form block starts at the design band`
and the design-fonts band proof (email field top 443.00, password 535.00) only
hold if everything above kept its position.

The one red test after the swap, `the headline is not a per-glyph column at text
scale 1.3`, was a stale recording of the *deleted cap's* three-line orphan, not
a collapse: at 1.3 the 350 dp column still holds two lines, so the clamped line
count falls out of the `maxLines: 3` clamp and the search converges on a real
width. 2b updated that one expectation to the post-migration two-line result and
left the two guards that carry the meaning (box > 150 dp, every line > 100 dp)
untouched, so a regression into a per-glyph column still fails.

## What this stage changed (smallest possible, comments and docs only)

1. **`p03_bugs_test.dart` — the stale cap prose 2b flagged.** The file header's
   `P03-BUG-24` entry and the proof's header block both still said "OPEN", still
   described the removed `ConstrainedBox(maxWidth: 240)`, and still instructed
   a future stage to "KEEP the 240 dp cap". Rewritten to record the resolved
   arbitration (fixed iteration 8, cap deleted, balanced search supplies the
   narrowing) and to point at the green guards that prove it. Left to stand,
   the next test/review/bugs stage would have re-filed BUG-24 and tried to
   restore the constant — the same oscillation the doc-level adjudication in
   iteration 7 stopped for §5/§8.
2. **`p03_bugs_test.dart` — two assertion `reason` strings** that still
   prescribed the deleted constant (`"…must cap below 252 (e.g. maxWidth
   240)"`, `"…instead of the hand-calibrated `_headlineMaxWidth = 240` cap"`).
   Re-worded to state the *constraint* ("the headline column must stay below
   252") without naming a constant that no longer exists. No assertion changed.
3. **`SHARED_REQUEST.md` §10 narrowed** (2b's item 3): still a real `core/`
   defect, but no longer blocking — P03's h1 never enters the collapsed state
   because its full-width minimum line count (2) stays under `maxLines: 3`, even
   at text scale 1.3. The collapse needs a caller whose text needs more lines
   than `maxLines` at every width it offers. The requested fix is unchanged and
   P03's guard is kept as the regression guard for whoever hits it.
4. **`docs/screens/P03/2_build.md`** — this file.

No behaviour, contract or assertion change: the merge compiled and passed before
this stage started, and every comment edit was re-verified with `analyze` (two
lint infos the first wording introduced were fixed before the gates).

## Every FIXES_7 item

| Item | Source | Status |
|---|---|---|
| P03-BUG-24 (MAJOR, mandatory BALANCED HEADINGS rule) — headline must be `NestBalancedText` | 3_test, 4_review #1, 6_bugs | **done** (2b) — proof green, un-skipped, never re-skipped; the `Skip` the bug stage left was already removed by the test stage |
| Orchestrator conflict: keep the 240 dp cap vs delete it | 3_test "one conflict to arbitrate" | **resolved: deleted** — measured, and the design-break guard now runs on the real uncapped screen and is green (see above) |
| Two typography guards + absolute band proofs after the swap | 3_test | **green** — break, ink widths, gutter, 34 dp pitch, 443.00 / 535.00 field tops |
| `the headline is not a per-glyph column at text scale 1.3` | 3_test (collapse guard) | **green** — its third expectation was a recording of the deleted cap's orphan; updated by 2b, guards untouched |
| Review finding 2 — `zz_probe8_test.dart` must not be committed | 4_review | **clear** — verified: no `zz_*` / `*probe*_test.dart` in the feature test dir. `pixel_probe.dart` is kept deliberately: it is a documented raster helper imported by `create_account_view_test.dart` and `p03_bugs_test.dart` (bottom edge, danger border) |
| Review finding 1 / bug-stage knock-on — `P03-BUG-7`'s ≤ 260 bound | 6_bugs (predicted obsolete, ≈ 308) | **left green** (2b) — measured: the balanced box stays under 260 in the harness font, so the proof still guards "constrained, not full-bleed". Weakening or deleting a passing proof was not warranted; only its reason text was re-worded, since it named the deleted cap |
| §10 `NestBalancedText` collapses when `maxLines` clips | 3_test, 2a, 2b | **filed, not patched** (core/, RULES §1) — narrowed in §10 this stage; P03's guard stays green |
| §7 `NestType` legal-caption 13/20 token | 4_review, 6_bugs | **left, open** — orchestrator-owned, non-blocking; `P03-BUG-12` pins the current override |
| Iteration-7 "closed" items: BUG-23 (`_orLabelLineBox`), BUG-16/17/22, bottom edge, gutters, copy audit | 3_test | **green, untouched** — regressions only |
| Filled-state capture (`ORCHESTRATOR_NOTES` iter-3 item 3) | carried | **left for stage 5** — `filled_shot.sh` + `ui/filled-{light,dark}.png` are iteration-6 evidence; the UI check should compare those and confirm the headline band in a fresh capture |

One stale line worth flagging, not edited: 2a's "LEFT FOR NEXT ITERATION" still
says "when SHARED_REQUEST §8/§10 land, the UI stage does the `errorText:`/
headline migrations" — §8 landed in iteration 6 and the headline migration
landed this iteration.

## Rules re-checked on the merged tree

- **BALANCED HEADINGS** — applied to the only balanced heading on the screen
  (`.h1`); the subtitle, helper, note row and CTA label stay plain `Text`,
  pinned by `the body, caption and CTA keep plain Text`.
- **LETTER SPACING** — no tracking; the component takes the style verbatim from
  `NestType.h1` (0 by default), and `every rendered run has zero tracking` walks
  every `RichText` on the screen.
- **TOKENS-ONLY** — the migration removed a hard-coded width and added no
  literal; the one screen-owned number remains `_OrRow._orLabelLineBox = 15.7`.
- **FONTS / COPY / BOTTOM EDGE / ALIGNMENT / CHIP ROWS / CHILD ORDER / PERIODS /
  TRIAL / PIP / DATA OVER MOCKS / STATUS BAR** — unchanged and green (copy audit
  11/11 byte-identical; bottom edge and 20 px gutters keep their raster proofs;
  the rest N/A on this static parent-mode form).
- **SIMULATORS** — none booted, installed on, screenshotted or driven.

## Evidence (app/)

- `dart format --set-exit-if-changed .` → `Formatted 394 files (0 changed) in 0.85 seconds.`
- `flutter analyze` → `No issues found! (ran in 2.5s)` — no ignores, no weakened
  options, no new infos.
- `flutter test test/features/auth` → `00:06 +167: All tests passed!` — 0 skipped.
  Per file: `auth_bloc_test.dart` 45, `copy_audit_test.dart` 16,
  `create_account_view_test.dart` 49, `p03_bugs_test.dart` 33,
  `seeded_submit_test.dart` 7, `typography_test.dart` 17.
- `flutter test` (full suite) → `00:27 +1192: All tests passed!` — 0 failed,
  0 skipped.
- Targeted re-runs after the comment edits: `P03-BUG-24`, `P03-BUG-7`, `the
  balanced headline keeps the design break and gutter` and `the headline is not
  a per-glyph column at text scale 1.3` each pass individually.
- `grep` — zero `_headlineMaxWidth` references left in `lib/` or `test/`; zero
  `skip:` markers in the feature's tests.
- Touched paths only: `app/lib/features/auth/presentation/views/**`,
  `app/test/features/auth/**`, `docs/screens/P03/**` (RULES §1). Nothing shared.

VERDICT: PASS