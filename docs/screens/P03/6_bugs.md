# P03 Create account — bug hunt (Stage 6, iteration 5)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: worktree `screen/P03` at `f97d513` plus the uncommitted iteration-5
build/test work. **No screen code was changed by this stage** — only
`app/test/features/auth/p03_bugs_test.dart`, `SHARED_REQUEST.md` and this
report. `ORCHESTRATOR_NOTES.md` (including the 17:22 iteration-5 update) and
the standing rules (PIP — vacuous here, status bar, data-over-mocks, bottom
edge, alignment, COPY, CHILD ORDER — N/A) were applied.

Executable proofs: `app/test/features/auth/p03_bugs_test.dart`. Iterations
1–4's bugs are all fixed and run green as regression guards. Two proofs are
open and `skip:`-marked with their ids so the suite stays green (2 skipped);
run
`flutter test test/features/auth/p03_bugs_test.dart --run-skipped` to watch
them fail; un-skip each with its fix.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1…15 | — | iterations 1–4's bugs | **all fixed**; proofs green |
| P03-BUG-6, 21 | — | `NestButton` doubled label; empty live region | **fixed** (shared `7eaa1f7`; iteration-5 build); proofs green |
| P03-BUG-16 | minor | an invalid field paints no danger border | open — **Decision A**: keep the live-region rows, skip pending SHARED_REQUEST §8 |
| P03-BUG-17 | minor | subtitle breaks after “Children” instead of “Children never” | **shared §6** (orchestrator-owned; `shared/body_text_width` fix in flight) |
| P03-BUG-22 | minor | overhang fallback has no `!hit` gate → button-strip tap double-fires once links go live | new this stage; proof 22, skip-marked |

Iteration-5 fixes were independently re-verified, not taken on trust:
a semantics-tree walk of the current tree shows the two error rows as
`LIVE[Enter a valid email address]` / `LIVE[Use at least 8 characters]`
(exactly one node each, label + live-region flag); `P03-BUG-6`'s CTA node
reads exactly `Create account`; the `extra` dead field is gone and
`_verifyTotal` is re-armed in `didChangeDependencies`.

## P03-BUG-22 (MINOR, latent, new) — a tap in the button/target overlap is delivered twice

**Where** `create_account_view.dart:660-697` (`_RenderHitTestExpand.hitTest`).
The caption-overhang fallback runs for every point outside the caption
Stack's rect, with **no check of whether the normal path already claimed the
tap**. On the device geometry the Terms target's 44dp box overhangs ~12dp
above the caption and overlaps the submit button's last ~4dp, so a tap there
reaches the button's `onTap` **and** the link's `onTap`. The links are inert
in v1 (`TODO(P03)`), so there is no user-visible effect yet — but the moment
the Terms/Notice routes land that strip double-activates.

**Proof** `P03-BUG-22` — harness-synthesised device geometry: the test font
is ~2× wider than Inter, so at 390dp it pushes “Terms” to caption line 2 and
the overlap never occurs; `textScale 0.7` restores the device's line
distribution (the app clamps the scaler at ≥1.0, so this is a proof
synthesis, not a reachable UI state). Measured in that configuration:
button `y 740–792`, Terms target `y 785–829`, caption Stack `y 800–828`; the
overlap point `(339.9, 788.5)` is outside the Stack, and
`tester.hitTestOnBinding` today puts **both** the button and the target's
render object in the hit path. The proof asserts the target must not be in
the path when the button owns the point.

**Suggested fix** gate the fallback: `if (!hit && !stackRect.contains(position))`.
This preserves BUG-18 (at overhang points outside the button the normal path
returns `hit == false` — the bar's `DecoratedBox` does not claim taps — so
the fallback still runs), and removes the double-fire. This settles the
iteration-4/5 disagreement: the review's analysis is right, the build's
“the bar background claims them first” rationale is wrong. A one-line change
plus this proof. Until then the limitation should be recorded where the link
routes land.

## P03-BUG-16 (MINOR, open — Decision A) — an invalid field paints no danger border

**Where** the fields pass `errorText: null` and own their (live-region) error
rows, so the input keeps the resting `line` border. The design marks the
input itself:
`.field input[aria-invalid="true"] { border-color: var(--danger) }`
(`components.css:135`, SPACING_SPEC §3); my probe of all borders painted
inside the invalid email field sees `line` only — no `danger`.

**Why it is not fixed here** the shared `NestTextField` (`7eaa1f7`) now
renders `errorText` as a gutter row **and** forces the danger border, so the
switch is possible — but its row is a plain `Text` **with no live region**,
so passing `errorText` and deleting the owned rows would silently drop the
announcement of the validation message (BUG-20). Both the test and review
stages judge the announcement the higher value; the review's recommended
**Decision A** is: keep the screen-owned live-region rows and this proof
skip-marked pending `SHARED_REQUEST.md` §8 (a ~3-line core change wrapping
the shared row in a live region). When §8 lands: pass `errorText` to both
fields, delete the owned rows and their `buildWhen` selectors, un-skip this
proof — BUG-11 stays green (the shared row is on the gutter).
**Proof** `P03-BUG-16` (skip-marked with this reason). Do not pass
`errorText` while keeping the owned rows — the message would render twice.

## P03-BUG-17 (MINOR, shared §6) — the subtitle breaks one word early

The served Inter build is ~3–4% wider than the design's, so the subtitle
wraps after “Children” (app line 1 ends x≈330) instead of “…Children never”
(design x≈368). The 17:22 orchestrator update reclassifies this as a shared
typography bug with `shared/body_text_width` in flight and forbids a local
size/letter-spacing tweak (token violation). No local test can pin a break
the harness font does not produce. Carried, correctly not chased here.

## Checked — no bug found

- **Copy** — the copy audit is green (all nine strings byte-identical to the
  HTML, including U+2019, U+2014 and the single U+00A0); the filled-state and
  live-relayout proofs are green.
- **Kid-mode guard / deep links** — `APP_MODE=kid` + session kid mode →
  `/parental-gate`; no history → `/value-tour`; back-pops when stacked.
- **Restart / Drift persistence** — one owner row, no rename, password never
  written.
- **Rapid double taps** — the `isSubmitting` guard blocks a second submit.
- **Text scale 1.3 + width 320/390/430** — matrix clean; five consecutive
  resizes keep both targets on their words (new regression guard).
- **Dark-mode contrast** — unchanged token pairs (text ≥4.5:1).
- **0/1/6 children, long UK names, money, timezone/BST, empty lists, CHILD
  ORDER** — N/A on this screen (static form; no money/date logic; members
  stream never displayed; no children listed).
- **Async gaps / lifecycle** — controllers disposed, no timers, the
  verification chain is bounded and re-armed per layout, `emit` after close
  is a no-op; no pending-timer warnings.
- **Geometry / owner rules** — CTA hairline 678 vs the design's 677, submit
  button 694–745 in both, note clearance 39dp, 20px gutters, bottom edge
  uniform `surface` to y=844 in both themes (UI stage PASS).
- **Design-faithful non-finding** — the two legal targets overlap laterally
  when the caption wraps; the HTML's inline hit boxes overlap the same way.

## Suite state at hand-off (`app/`)

- `dart format --set-exit-if-changed .` → `371 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **145 passed, 2 skipped, 0 failed**
  (skips: `P03-BUG-16` Decision A, `P03-BUG-22`).
- `flutter test` (full) → **790 passed, 2 skipped, 0 failed**.
- `--run-skipped` fails exactly the two skipped proofs for the documented
  reasons (no danger border; the target is in the button's hit path).

## Verdict

No major bug remains: the iteration-5 build closed the empty-live-region
regression and the last shared-label defect, and every iteration-1–4 proof
runs green. The two open items are minors — P03-BUG-16, held by Decision A
pending the shared §8 live-region row (one-line switch afterwards), and the
newly proved latent P03-BUG-22 double-fire (one-line `!hit` gate; inert until
the link routes land). P03-BUG-17 is orchestrator-owned shared typography.
This screen is otherwise converged: geometry within ~1–4dp of the design in
both themes, exact copy, clean bottom edge and alignment, and no loose end
in the bloc, persistence, guards or async paths.

VERDICT: PASS
