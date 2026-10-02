# P02 Value tour — test notes (Stage 3, iteration 3, second pass)

Route `/value-tour`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every
router test ends with `disposeApp()`. No screen, bloc, route or design-system
code was changed by this stage.

This pass covers the two **newly added orchestrator rules** (CHILD ORDER,
character-exact COPY) and re-verifies the screen after the iteration-4 build
adopted the **shared `NestNavBar`** for the tour header (shared request 1
landed in batch 1, so the feature-private `_TourNav` and its `p02_skip` key
are gone).

## Tests added this stage

`value_tour_view_test.dart` — 132 → **137 tests** (5 added).

### Orchestrator COPY rule — character-by-character (2)

Font-independent by design: the widget-test font is ~2x wider than real Inter
(a probe measured "Maya · weekly" at 172dp in a 154dp slot, and 7 of the
single-line paragraphs reporting `didExceedMaxLines`), so line fitting cannot
be judged in tests — the device is the authority (see `p02_bugs_test.dart`
P02-BUG-7). Character *identity*, however, is fully testable:

- **Every design character is the typographic code point** — asserts the
  literals carry U+2013 (en dash, `Reading – 20 minutes`), U+2019 (`Today’s`,
  `Pip’s`, `Maya’s`), U+00B7 (`Maya · weekly`, `175 of 250 coins · …`), and
  U+201C/U+201D + U+2014 in the step bodies, plus the *absence* of the ASCII
  fallback for each (`ready-made`'s word-level hyphen excepted), and that the
  step-2 copy has no dash because the design has none.
- **All three pages render exactly the design's characters** — walks the whole
  tour, asserts every card string from `P02-value-tour.html` (`:68-121`) is
  present, then collects **every** rendered string across all three pages and
  rejects any containing an ASCII quote, an ASCII apostrophe or an ellipsis
  (U+2026 can only enter copy through truncation).

### Orchestrator CHILD ORDER ruling (1)

- **Seeded children keep insertion order, not alphabetical** — asserts the
  Drift rows come back `[maya, leo]` (`seed.dart:182`, `:204`) and explicitly
  *not* `[leo, maya]`, so the assertion discriminates the ruling from the
  alternative instead of passing vacuously.

## Bug found (blocking, shared scope — not a screen defect)

**P02 finding: the shared push/pop contract test asserts the retired
placeholder title.**

- **Where:** `app/test/app/router_push_test.dart:91` (`showsTo: 'P02 Value
  tour'`), asserted at `:46`.
- **Repro:** `flutter test test/app/router_push_test.dart` →
  `Expected: true / Actual: <false>` on `push /value-tour from /welcome, pop
  returns`; the other three cases in that file pass.
- **Why:** P02 replaced the foundation placeholder in iteration 1, and no
  design text contains "P02 Value tour" —
  `grep -rn "P02 Value tour" lib/features/onboarding/` matches a doc comment
  only. The real screen renders the tour ("Set quests in seconds"), so the
  shared expectation can never be satisfied by the screen.
- **Scope:** `app/test/app/**` is shared (RULES §1 keeps screen agents to
  `app/test/features/<feature>/**`), so this stage must not edit it, and
  adding the string to the view to satisfy a test would violate the design.
  Already filed by the build stage as `SHARED_REQUEST.md` #4 ("Blocks: yes");
  this stage added independent reproduction evidence to that item. Fix is one
  line — expect real copy, as the same file already does for P01's
  `showsFrom: 'Chores that feel like a game.'`.

Per the stage rules the screen was **not** patched.

## Failures found in my own new tests (test bugs, corrected before gating)

- The first sweep forbade *any* ASCII hyphen, which flagged the body's
  "ready-made" — a word-level hyphen the design itself uses. The rule is now
  precise: hyphen forbidden only when spaced (a dash where – / — belongs),
  and "ready-made" is pinned explicitly.
- Two wrong assertions while writing them: a hard-coded code-point index, a
  duplicated-sub count asserted on pages that do not carry it, and a
  double-advance before the per-page collection loop.

## Re-verified after the shared `NestNavBar` adoption

All previously green coverage still passes against the shared header — 18-combo
width × scale × theme matrix, pager geometry, the three card contents, the 5
bloc states, `Seed.empty`/`Seed.fresh`, the PipAvatar rule, navigation, the
owner-rule pixel proofs (BOTTOM EDGE) and the alignment gutters, plus
`p02_bugs_test.dart`'s 11 proofs with **zero skips**.

One test-authoring consequence is now in the contract file: the Skip action is
shared design-system code, so tests locate it by its `InkWell` inside
`NestNavBar` (size, tap action) and by its semantics label (label, button flag)
rather than the retired `p02_skip` key.

## Results (run by this stage, `app/`)

- `dart format .` — 360 files, 0 changed on final pass.
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **135 passed, 0 failed,
  0 skipped** (every P02-owned and P01-owned test).
- `flutter test` (full suite) — **612 passed, 1 failed, 0 skipped**; the only
  failure is the shared case above (`router_push_test.dart`).

`flutter test` is therefore not all-green, so this stage does not claim PASS.

## Other residual observations (non-blocking)

- The lazy route-level `BlocProvider` (`onboarding_routes.dart:36-40`) still
  runs its load event only on the first read; unchanged since iteration 1 and
  pinned deliberately.
- At 390dp the card head keeps its 180dp chip cap (`_headChip`), which is not
  binding in the real font (~80dp chip) but squeezes the head in the ~2x test
  font. Device behaviour is the UI stage's authority; worth a 320dp device
  look if the QA pass revisits narrow widths.
- Uncommitted build work in the worktree (process item, per the stage rules).

VERDICT: FAIL
