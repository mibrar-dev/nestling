# K04 — Stage 2 build, integration (iteration 4)

Scope: make the combined 2a (logic) + 2b (UI) result compile, analyze clean and
pass the full suite. **No `lib/**` change was needed at all this stage** — the
mandated work was the ICONS regression guard, which is test work. I closed the
one item both builders explicitly handed to the integrator.

Inputs: `2a_build_logic.md` (iter 4), `2b_build_ui.md` (iter 4 section),
`1_plan.md`, `FIXES_3.md`, `3_test.md` (iter 3), `6_bugs.md`, `5_ui.md`,
`ORCHESTRATOR_NOTES.md` (14:28 + 15:08 + **16:38**), `SHARED_REQUEST.md`,
`RULES.md`.

Iteration 3 closed `ui=PASS` but `test=FAIL` for two reasons: K04-BUG-5 was open
behind a `skip: true`, and the ICONS audience regression guard the test stage
owed was never written (`3_test.md` stated plainly that it delivered 0 new
cases).

## What landed

### From 2a (logic) — `kid_home_repository_test.dart` only, no `lib/`

No logic-layer change and **no CONTRACT CHANGES**, so 2b coded against a contract
that landed intact — no merge adaptation. 2a added a `K04 ICONS audience guard —
data premise` group (2 cases) pinning what the logic layer owns: the database
actually serves the icon keys the guard reasons about (`bed`/`dishwasher`/`book`
present, every stored key in `questIconKeys`), and `questIconFor` splits the
audiences on exactly those keys. Read from the DB, no seed value hard-coded.

### From 2b (UI) — `quest_detail_view_icon_audience_test.dart` (new, 4 cases)

`app/lib/**` untouched: iteration 3 already landed
`questIconFor(raw, audience: NestAudience.kid)` in `quest_detail_view.dart:85`,
and the ruling on the only open UI item (K04-BUG-5) is *accept*, which is a
no-op for the view. The new file closes the hole `FIXES_3` identified — that the
old K04-BUG-3 proof hard-codes four ids → four assets and would still pass if
`_iconFor` were reverted to `audience: parent` **and the list edited in step**:

1. reads the live rows and pushes `/quest-detail` for **every** seeded quest,
   asserting the rendered 64 px `NestIcon.assetName` equals
   `questIconFor(item.icon, audience: kid)`, and for divergent keys that it is
   **not** the parent asset. It asserts its own premise (the rows must cover
   `bed`/`dishwasher`/`book`) so the "≠ parent" arm cannot pass vacuously.
2. proves the glyph is **column-driven, not id-driven** — a fake repo with two
   same-title rows differing only in `icon` must swap the hero glyph.
3. asserts the divergence premise against the shared table itself (kid ≠ parent
   for `bed`/`dishwasher`/`book`/`reading`; identical for
   `bins`/`hoover`/`plate`/`paw`/`bag`).
4. records the K04-BUG-5 acceptance.

2b also reported a hang it introduced and fixed — awaiting a real Drift stream
inside `testWidgets` deadlocked at the 120 s timeout; fixed with exactly one
`tester.runAsync` cycle and `GoRouter.pop()` instead of tapping back (a finder
must not disambiguate K04's back button from the home screen mid-transition).
Per the brief, a test that can hang is a bug, so calling that out is right.

## FIXES — every item, done or left

### DONE

- **ICONS audience regression guard (mandated, 16:38) — delivered by 2b, then
  verified independently by me.** 2b reported a mutation test; I re-ran it rather
  than take it on trust — flipped `_iconFor` to `audience: parent`, ran the
  guard, reverted:
  ```
  Expected: 'assets/icons/ic_quest_dishes_kid.svg'
    Actual: 'assets/icons/ic_quest_dishes.svg'
  q-dishwasher (icon "dishwasher") must render the kid asset
  Expected: 'assets/icons/ic_quest_bed_kid.svg'
    Actual: 'assets/icons/ic_quest_bed.svg'
  ```
  Both failing cases fire, with the asset name in the message — exactly the
  5_ui Major mix-up. `git diff --stat lib/` was empty again after the revert, so
  no mutation residue.
- **K04-BUG-5 — CLOSED AS ACCEPTED (mine; both builders handed it over).**
  `ORCHESTRATOR_NOTES` 16:38 is mandatory: *"ACCEPT the shared kid glyph at 2
  (one consistent kid set; invisible at 64 px). Close the proof as accepted. Do
  not ship a variant."* The parked proof at `k04_bugs_test.dart:383` asserted
  `stroke-width="1.8"`, so un-skipping it unchanged would have failed *by the
  ruling itself* — 2b correctly declined to edit it (outside its declared
  `view`/`widget` test slice) and named the exact fix. I applied it:
  - the K04 tile path data assertions are **kept** (`M2 18v-7`,
    `M22 18v-4a3 3 0 0 0-3-3h-9v3`) — the headboard/pillow/legs drawing must
    survive the acceptance;
  - `html` still must contain the design's lone `1.8`, so the design's real
    value stays **recorded** rather than erased;
  - the shipped asset must now contain `stroke-width="2"` **and must NOT**
    contain `1.8` — a mixed 1.8/2 file would break K03 and hide the difference,
    so this is strictly stronger than the old single assertion;
  - `skip: true` removed; header comment rewritten to cite the ruling, so the
    acceptance is recorded rather than silently re-litigated by the next agent.
- **K04 now has ZERO skipped tests** — for the first time in this loop. All six
  proofs run in the default suite (BUG-1 unit + widget, BUG-2, BUG-3, BUG-4,
  BUG-5). This was the specific reason `3_test.md` returned FAIL: a green suite
  that partly consisted of a skipped test whose body failed. The 4 repo-wide
  skips are K01 ×1, K03 ×2, P12 ×1 — other screens, none mine.
- **Format.** `dart format .` → 580 files, **0 changed**.

### LEFT — needs the orchestrator

- **`SHARED_REQUEST.md` is still unresolved.** `git diff main` shows
  `nest_balanced_text.dart` still differs from `main` by 22 insertions: the
  K04-BUG-1 fix (invisible over-cap heading) is committed on this branch but
  **not upstreamed**. Flagged in iterations 2, 3 and now 4. Two parts remain
  shared work: the component fix, and — per `6_bugs.md` — the permanent
  regression test that belongs **next to the component**, not in a screen file.
- **Stage-5 UI re-check** is not owed as a *new* capture — iteration 3 closed
  `ui=PASS` — but nothing in `kid_home/` changed since, and the K04-BUG-5
  acceptance is a documented ~0.5 px hero-stroke delta that stage 5 may wish to
  record against its measured mean diff.
- **K03's `_iconFor`** carries the same mapping this screen just cleaned up. The
  audience helper is now the single source for both, so this is informational
  rather than outstanding — noted only so the orchestrator knows K04 no longer
  needs a parallel fix.

### LEFT — accepted deviations, unchanged

- Steps render unticked on arrival (`1_plan.md` §d; `5_ui.md` deviation 2).
- Bottom edge: no meadow strip under the bar — owner rule overrides the dark
  design PNG (`5_ui.md` deviation 4); matrix test pins `bottom == 844`
  structurally.
- Pip art is `PipAvatar` from Maya's DB row, not the v1 `pip-stage-3.svg`
  (`5_ui.md` deviation 3).
- The cheer Pip + speech bubble merge into one semantics node; both strings are
  the HTML's verbatim copy and the announcement is correct. Splitting them needs
  a shared-component change.

### NOT FINDINGS (per orchestrator rule)

- Uncommitted work, branch position, merge order — loop/orchestrator state. Note
  the branch is **not** behind main this round: `git diff main` on the K04
  feature/test files is empty apart from the documented shared-file item.
- `5_ui.md`'s note that stage 2b "must not run the whole-app suite" is a stage
  rule for the builders; the integrator's brief requires it, and it was run.

## Orchestrator-rule audit (re-verified on the merged tree)

| rule | result |
|---|---|
| **ICONS** | `_iconFor` → `questIconFor(raw, audience: NestAudience.kid)`; no local icon table; guard proven to bite by mutation. Remaining `NestIcons.*` uses are chrome (back chevron, check glyph ×2). |
| no `google_fonts` / `GoogleFonts.*` | clean |
| no `DateTime.now()` in feature | clean |
| no `subscription_status` write | clean |
| no hard-coded `Color(0x…)` | clean — tokens only |
| PIP rule | `PipAvatar` from the child's DB row; no `pip_stage_*.svg` |
| BALANCED HEADINGS | title `NestBalancedText`, `maxLines: 3`, `overflow: ellipsis` |
| bottom edge / alignment | in-flow bar over `SafeArea(top:false)`; matrix pins gutters at 320/390/430 in both themes |
| accessibility | every control exposes `SemanticsAction.tap`; step rows pass `onTap:` on the wrapper because they also `excludeSemantics` |
| copy | unchanged this iteration; char-by-char vs HTML verified in iteration 1 |
| **no test skipped / weakened / deleted** | the one edit re-purposed a skipped proof against the mandated accepted value and strengthened it (added a negative assertion); nothing was deleted |
| RULES §1 scope | `kid_home` tests + `docs/screens/K04/**` only. No `lib/`, no `core/**`, no `assets/**`. |
| `analysis_options.yaml` | untouched, no ignores |
| simulators | none booted |

## Tails

```
$ dart format .
Formatted 580 files (0 changed) in 2.41 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 8.8s)

$ flutter test --timeout 120s
01:28 +3714 ~4: All tests passed!

$ flutter test --timeout 120s test/features/kid_home
00:14 +552 ~3: All tests passed!

$ flutter test --timeout 120s test/features/kid_home/k04_bugs_test.dart
00:02 +15: All tests passed!        # 0 skips — all six bug proofs live
```

The 4 whole-suite skips are K01/K03/P12 parked proofs (other screens). The Drift
"AppDatabase multiple times" warning is pre-existing harness noise. Full-suite
wall clock 1 min 28 s. `dart format`/`flutter analyze` were re-run after the
mutation revert to confirm no residue.

## Verdict

`dart format` changed nothing, `flutter analyze` printed **No issues found!**
with no ignores, and the **full 3714-test suite passed**. The ICONS audience
guard the test stage owed is delivered and I verified independently that it
fails on the exact regression it exists to catch. The mandatory K04-BUG-5
acceptance is closed as a live pinning test rather than a skip, so **K04 now has
zero skipped tests** — the green suite no longer hides anything, which was the
reason `3_test.md` returned FAIL last round.

One item remains genuinely open and is not mine to land: the `SHARED_REQUEST.md`
upstream of the `NestBalancedText` fix, plus its component-level regression test.

VERDICT: PASS
