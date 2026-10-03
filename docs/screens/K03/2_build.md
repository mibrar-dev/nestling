# K03 Kid home — build notes (Stage 2 INTEGRATE, iteration 9)

Two builders worked in parallel on `kid_home`. This stage is the integrator: it
confirmed the merged tree compiles and passes, verified the delivered work
rather than trusting the reports, and checked the screen against the new
ACCESSIBILITY ACTIONS rule.

**Gate: PASS** — `dart format .` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → *`+1544: All tests passed!`*

Still **zero skipped tests** (third iteration running). The shared batch
`shared/semantics_tap` landed before this build
(`191be8f`, "every interactive design-system component exposes
`SemanticsAction.tap`"), which is what the new orchestrator rule needed.

## 1. The halves as delivered

### 2a — logic (`2a_build_logic.md`)

No code changes this pass, and that is the correct outcome: `ORCHESTRATOR_NOTES`
UPDATE 09:52 said *"Only fix the non-pet items in FIXES_8.md this pass"*, and
the logic layer had none. 2a filed **SHARED_REQUEST #16** with the two shared
causes — the `BoxFit.fill` nest stretch and the shared card's 6 px shadow
padding — each with exact numbers and an explicit "no K03-side fix exists"
statement. `kid_home_bloc_test.dart` 31/31; no state/event shape changes, so
**no contract changes** for the UI half.

### 2b — UI (`2b_build_ui.md`)

Two FIXES_8 items closed in the view plus one new shape proof:

- **Card rhythm (finding 2)** — re-measured the design to confirm the 12 px
  target (`.k3-quests { gap: 12px }`, card 1 ink 559…646, card 2 top 659), then
  compensated for the shared card's 6 px `kidShadow` reserve by taking it out
  of the column spacing: `spacing: NestSpacing.s3 - _kQuestCardShadowRoom`.
  Card 1 does not move (the reserve is *under* it), card 2's top returns to
  **659** and its peek above the dock to **60 px**.
- **`844` hard-coded (finding 5)** — `gradeSpan` is now
  `NestDevice.height * (1 - 0.62)`; numerically identical (320.7 px), so the
  dark meadow is untouched. Same substitution in the view test.
- **New shape proof** — `_questCardPainted(i)` measures the all-side-ink
  bordered container *inside* the card. The old assertion measured the widget
  rect, which includes the reserve, so it read 12 and stayed green while the
  painted rects sat 18 apart. This is exactly the trap the UI CHECK MEASURES
  SHAPES rule warns about, found and fixed in the test itself.

The pet-block findings (1 and 3) and the meadow painter (4) were left alone,
as instructed.

## 2. Integration work done here

No breakage: the tree arrived green and stayed green. Two things I checked
rather than assumed, because neither builder was asked to.

### The halves disagreed on finding 2 — resolved against the orchestrator

2a filed the card rhythm as a shared cause and wrote *"No local compensation
(would double-correct once core lands)"*. 2b compensated locally anyway, with a
documented revert rule (delete the constant, put `NestSpacing.s3` back).

`ORCHESTRATOR_NOTES` UPDATE 09:52 settles it: the card rhythm is a **non-pet**
item and this pass was told to fix the non-pet items. 2b's read matches the
instruction; 2a's was the more conservative one. Both are defensible, so I
changed nothing — but the divergence is recorded here so the next reviewer does
not read the local subtraction as an unrequested workaround. The risk is
genuinely bounded: one constant plus one subtraction, and SHARED_REQUEST #16(b)
carries the revert rule. A `shadowPadding` parameter on the shared card would
let K03 pass `EdgeInsets.zero` instead of compensating at all.

### ACCESSIBILITY ACTIONS rule — compliant, but unpinned

The new rule requires every interactive element to expose
`SemanticsAction.tap`, and forbids `Semantics(excludeSemantics: true)` around a
control without `onTap:`. I verified both halves empirically with a throwaway
probe (run, then deleted):

| node | `hasAction(tap)` | label |
|---|---|---|
| `NestLockButton` | **true** | `Grown-ups` |
| quest card 1 | **true** | `Empty the dishwasher, Waiting for Mum's thumbs-up` |
| dock buttons 1–3 | **true** | `Pip` / `Shop` / `My jar` |
| `NestPetStage` | false | (correct — not interactive) |
| `KidStatusChip` | false | (correct — display-only) |

12 tap-capable nodes in the tree, and `performAction`-equivalent tapping of
dock #2 really navigated to `/reward-shop`. The two `excludeSemantics: true`
wrappers in the view (the greeting column, the hearts row) are **both
non-interactive**, so the rule's conditional clause is not triggered.

**Gap worth naming:** K03 has **zero** `hasAction(SemanticsAction.tap)`
assertions in its tests. The behaviour is correct, but nothing pins it — a
future change that drops an `onTap` would go unnoticed. That is the next test
stage's file to write, not something to bolt on mid-integration, so I left it.

## 3. FIXES_8 items

| # | Item | Status |
|---|---|---|
| 1 | [major] nest stretched to 66 % vertical scale, ~26 px low | **LEFT (shared)** — `BoxFit.fill` + the mandated 236×156 call; the arithmetic is closed. SHARED_REQUEST #16(a). `ORCHESTRATOR_NOTES` 09:52 forbids local adjustment while `shared/pet_stage_seat` lands |
| 2 | [minor] card rhythm 18 px vs the design's 12 px | **DONE** (2b) — compensated, painted-rect proof added. See §2 for the 2a/2b divergence |
| 3 | [minor] geometry pin measures the box, not the painted outline | **LEFT (pet-gated)** — the suggested fix is a `NestPetStage` call change (`visibleNestWidth: 198`) plus a `kid_home_geometry_test.dart` edit; 09:52 says not to change the call until the shared branch's report allows it |
| 4 | [minor] feature-local meadow band | **CARRIED, deliberately** — the review itself says keep the local band and the `TODO` (within 1 level of both PNGs); blocker is SHARED_REQUEST #6's two missing `KidScope` gradient stops |
| 5 | [minor] `844` hard-coded twice | **DONE** (2b) — `NestDevice.height` in the painter and the test |
| 6 | [minor] `switchMapStream` in `domain/` | **CARRIED** — shared/architecture, SHARED_REQUEST #14 |

From `5_ui.md`: the speech-bubble tail (10 px low) is **accepted and
recorded**, not worked around — `NestSpeechBubble` takes only `text`, the tail
is painted inside the shared component, and it has no layout effect (bubble
body 36 vs 37 px, x/w identical, every row below exact).

### Housekeeping from the review's stage-5 note

`ui/app_dark_8b.png` (the bright-mint non-K03 render) is **gone** — no
untracked files remain in `docs/screens/K03/ui/`.

## 4. Verification (in `app/`, this stage)

```
$ dart format .
Formatted 408 files (0 changed) in 1.08 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.9s)

$ flutter test test/features/kid_home
00:04 +162: All tests passed!

$ flutter test
00:49 +1544: All tests passed!
```

- RULES §1 respected: only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**`, `docs/screens/K03/**`. This stage itself
  changed **no code** — only this note (the a11y probe was run and deleted).
- No simulator booted, installed on or captured (SIMULATORS rule: only the
  UI-check stage may, and only `BC440E48-B3A3-43BC-971B-0EF5DB621874`).
- No `google_fonts`/`GoogleFonts`, no `// ignore:` suppression, no
  `skip:` marker anywhere in the feature.
- `analysis_options.yaml` untouched; no test weakened to get green.

## 5. Handover

Nothing outstanding in K03's scope. Carried for other owners:

- **SHARED_REQUEST #16(a)** — `PipNestFallback` art-box/aspect independence;
  `BoxFit.fill` into the 236×156 stage squashes the bowl to 0.661 vertical and
  drops its widest row 26 px. Waiting on `shared/pet_stage_seat`. K03's
  `NestPetStage` call stays byte-identical to the mandate until that report
  says otherwise.
- **SHARED_REQUEST #16(b)** — shared `NestKidQuestCard` needs a `shadowPadding`
  parameter so K03 can drop the local `_kQuestCardShadowRoom` compensation.
- **SHARED_REQUEST #6** — the two missing `KidScope` gradient stops (flat 62 %
  horizon line, horizon→meadow grade) that block deleting `_MeadowPainter`.
- **SHARED_REQUEST #14** — `switchMapStream` belongs in
  `core/data/stream_combine.dart`; adoption is mechanical.
- **New test gap** — no `hasAction(SemanticsAction.tap)` assertion pins any K03
  control yet. Behaviour verified correct this iteration; the test stage should
  pin it, including that `performAction(tap)` changes real state.

One judgement call flagged for the next reviewer: the view writes the reserve as
a bare `_kQuestCardShadowRoom = 6` and subtracts it, while the companion test
uses the `NestSpacing.gap6` token that already exists. The constant is
documented and matches the file's pattern for design-cited numbers, so I left
it — but it sits close enough to a token that a reviewer may reasonably want
`NestSpacing.gap6` there instead.

Next real step is the UI check: with card 2's top border and peek both moved,
stage 5 should re-measure card 2 (expect top **659**, peek **60 px**) and the
band-6 heat should drop. The painted 198 px nest outline still needs a capture
once `shared/pet_stage_seat` lands.

VERDICT: PASS