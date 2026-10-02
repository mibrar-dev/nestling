# P03 Create account — bug hunt (Stage 6, iteration 4)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: worktree `screen/P03` at `3d45950` plus the uncommitted iteration-4
build/test work. **No screen code was changed by this stage** — only
`app/test/features/auth/p03_bugs_test.dart`, `SHARED_REQUEST.md` and this
report. `ORCHESTRATOR_NOTES.md` (all items) and the standing rules (PIP —
vacuous here, status bar, data-over-mocks, bottom edge, alignment, COPY,
CHILD ORDER) were applied. CHILD ORDER is N/A (P03 lists no children).

Executable proofs: `app/test/features/auth/p03_bugs_test.dart` — the two
open-bug proofs are `skip:`-marked with their ids so the suite stays green
(2 skipped). Run
`flutter test test/features/auth/p03_bugs_test.dart --run-skipped` to watch
them fail; un-skip each one with its fix.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1…15 | — | iterations 1–3's bugs | **all fixed**; proofs green |
| P03-BUG-6 | — | `NestButton` announced its label twice | **fixed** by shared batch `7eaa1f7` (inner `Text` excluded); proof un-skipped and green — correction to iteration 3 |
| P03-BUG-16 | minor | an invalid field paints no danger border | **open — UNBLOCKED, not shared-blocked**; proof skipped with the correct reason |
| P03-BUG-17 | minor | subtitle breaks after “Children” instead of “Children never” | open, **shared §6** (font pipeline); no local test possible |
| P03-BUG-18/19/20 | — | target overhang, first-frame/stale measurement, live regions | **fixed** in iteration 4; proofs green |
| P03-BUG-21 | **MAJOR** | the validation error left the semantics tree — the live-region nodes have empty labels | new regression this iteration; proof skipped |

**Corrections to earlier records made this stage.** The shared
`shared_requests_batch1` fix (`7eaa1f7`) is an **ancestor of the pre-build
sync `29162fc`**, so it was present when iteration 4's build ran. It resolved
P03's §2/§4/§5: brand and `NestButton` labels are now single, and
`NestTextField` renders `errorText` as a **gutter-aligned row with the danger
border forced** (its contract tests pass). Iteration 4's build note (“the
shared hasError flag did not land”) is wrong, and my iteration-3 report's
“mutually exclusive” analysis is obsolete: passing `errorText` no longer
re-opens BUG-11. `SHARED_REQUEST.md` §§2/4/5 are marked RESOLVED and a new §8
covers the one remaining component gap (its error row is not a live region).

## P03-BUG-21 (MAJOR, regression introduced this iteration) — the validation message is not in the semantics tree

**Where** `create_account_view.dart:190-201` (email) and `:246-258`
(password):

```dart
Semantics(
  liveRegion: true,
  child: ExcludeSemantics(
    child: Text(state.emailError!, …),
  ),
),
```

`ExcludeSemantics` drops the `Text`'s node, and the wrapper supplies a flag
but **no label**. My own semantics-tree probe after a rejected submit:

```
[Email] [] live=true        ← the error: empty label
[Password] [] live=true     ← the error: empty label
find.bySemanticsLabel('Enter a valid email address') -> 0
find.bySemanticsLabel('Use at least 8 characters')   -> 0
```

So the message is neither announced (the live region is empty) nor reachable
at all — worse than iteration 3's plain labelled `Text`, and worse than
Material's row, which is a live region *with* content. The iteration-3
review's shorthand (“keep the inner `Text` out of semantics so the label is
read once”) omitted the explicit label, and the BUG-20 proof's
`getSemantics(find.text(...))` resolves to the nearest enclosing node, so it
passed while the label was gone.

**Repro** `P03-BUG-21` (asserts each message is findable by semantics label
*and* that the node carrying it is the live region). **Suggested fix** carry
the message on the wrapper:

```dart
Semantics(
  liveRegion: true,
  label: state.emailError!,
  child: ExcludeSemantics(child: Text(state.emailError!, …)),
)
```

(or drop the `ExcludeSemantics` — but then the wrapper merges with the
`Text`, doubling the label the way the legal links used to). This is the
three-line fix the review also asks for.

## P03-BUG-16 (minor, open — unblocked) — an invalid field paints no danger border

**Where** `create_account_view.dart:173-185`/`:210-223` pass
`errorText: null` and render their own error rows, so the input keeps the
resting `line` border. The design marks the input itself:
`.field input[aria-invalid="true"] { border-color: var(--danger) }`
(`components.css:135`, SPACING_SPEC §3). My probe of all borders painted
inside the email field after a rejected submit sees `line` only — no
`danger`.

**What changed** shared batch `7eaa1f7` made `NestTextField` render
`errorText` as a gutter-aligned row **and** force the danger border (pinned
by its own tests: “error aligns with the label gutter”, “error border still
turns danger”, “error replaces the helper”). `P03-BUG-11` no longer blocks
this, so the fix is local: **pass `errorText` to both fields and delete the
screen-owned error rows**. Do not pass `errorText` while keeping the owned
rows (the message would render twice).

**One caveat (why the proof is still skipped):** the component's error row
is a plain `Text` with no live region, so switching to it would trade
BUG-16 for BUG-20 unless `SHARED_REQUEST.md` §8 lands (make the shared row
announce). Recommended order for iteration 5: fix BUG-21 (above), then
either land §8 and switch (closes 16/20/21 together) or keep BUG-16 skipped
and accept the border gap for v1. **Proof** `P03-BUG-16` (skip-marked with
this reasoning).

## P03-BUG-17 (minor, shared §6) — the subtitle breaks one word early

Carried from iteration 3 and unchanged: the served Inter build is ~3–4%
wider than the design's, so the subtitle wraps after “Children” (app line 1
ends x≈330) instead of “…Children never” (design x≈368). The style is
already the design token (`NestType.body` 16/24, no letter-spacing), so the
UI stage's “localised style-metrics fix” is not available without a
token-rule violation; the review agrees this stays with SHARED_REQUEST §6
(pin/bundle the design's Inter build). No local test can pin a break the
harness font does not produce.

## Carried from review (iteration 4) — no local proof possible

- **`_HitTestExpand.extra` is dead** (`:290`, `:644-673`): `hitTest` never
  reads it, yet `updateRenderObject` assigns it and calls
  `markNeedsPaint()` — a pointless repaint per bar rebuild, and the number
  is unrelated to the caption line height it nominally mirrors. Fix: delete
  the field, setter, `markNeedsPaint` and the `extra:` argument.
- **The overhang pass fires even when the normal path already hit**
  (`_RenderHitTestExpand.hitTest`): a tap in the device-only ~4dp strip where
  the Terms target overlaps the submit button is delivered to both. Inert
  today (links are no-ops), a double activation once the routes land. Fix:
  `if (!hit && !stackRect.contains(position)) { … }`; add a `tapAt` proof
  when the strip becomes reachable in the harness.
- **`_verifyTotal` is a lifetime cap** (`:498-502`): after 12 schedules the
  font-swap safety net is permanently off for that `State`. The synchronous
  layout measurement still runs on every rebuild, so the impact is latent.
  Fix: reset `_verifyTotal = 0` in `didChangeDependencies` alongside
  `_verifyLeft`.

## Checked — no bug found

- **COPY** — the copy audit is green (15/15): the subtitle now carries
  U+2019 (byte-verified by the test and review stages), the note U+2014 and
  “Privacy Notice” the single blessed U+00A0; all nine strings are
  byte-identical to the HTML.
- **Kid-mode guard** — `APP_MODE=kid` + session kid mode → `/parental-gate`.
- **Restart / Drift persistence** — one owner row, no rename, password never
  written.
- **Back / deep links** — no history → `/value-tour`; back-pops when a route
  is stacked; the form renders on all three seeds.
- **Rapid double taps** — the `isSubmitting` guard blocks a second submit.
- **Text scale 1.3 + width 320/390/430** — matrix clean; targets survive
  live resize/scale/theme changes and equal the real paragraph boxes.
- **Dark-mode contrast** — unchanged tokens (text ≥4.5:1; lilac decorative).
- **0/1/6 children, long UK names, money, timezone/BST, empty lists** — N/A
  on this screen (static form; no money/date logic; members stream never
  displayed).
- **Geometry / owner rules** — CTA hairline 678 vs the design's 677, submit
  button 694–745 in both, note clearance 39dp; bottom edge uniform `surface`
  to y=844 in both themes; 20px gutters hold.
- **Design-faithful non-finding** — the two legal targets overlap laterally
  when the caption wraps; the HTML's inline hit boxes overlap the same way.

## Suite state at hand-off (`app/`)

- `dart format --set-exit-if-changed .` → `359 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **143 passed, 2 skipped, 0 failed**
  (the skips are `P03-BUG-16` and `P03-BUG-21`; `P03-BUG-6` is now green).
- `flutter test` (full) → **670 passed, 2 skipped, 0 failed**.
- `--run-skipped` fails both skipped proofs for the documented reasons.

## Verdict

One MAJOR regression remains open (P03-BUG-21: the empty live region — a
three-line fix), plus P03-BUG-16 (now unblocked locally, coupled to
SHARED_REQUEST §8) and the shared font-pipeline item P03-BUG-17. The rest of
the screen is converged: geometry within 1–4dp, exact copy, green proof
suite, and the iteration-4 mechanisms (`_HitTestExpand`, synchronous
measurement) are sound but carry the three review hardening items above.

VERDICT: FAIL
