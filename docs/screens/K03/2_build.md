# K03 Kid home — build notes (Stage 2 INTEGRATE, iteration 10)

Two builders worked in parallel on `kid_home`. This stage is the integrator: it
confirmed the merged tree compiles and passes, verified the delivered work, and
checked one cross-screen consequence the builders were not looking at.

**Gate: PASS** — `dart format .` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → *`+1579: All tests passed!`*

Still **zero skipped tests** (fourth iteration running).

## 1. The halves as delivered

### 2a — logic (`2a_build_logic.md`)

No code changes, and that is correct: FIXES_9 holds only the Stage-5 UI check,
whose two deviations are both shared-component with do-not-touch-locally
instructions. 2a verified `grep skip:` clean, confirmed K03-BUG-1…15 all run
un-skipped, and reported 31/31 on the bloc suite. No contract changes, so
nothing for the UI half to consume.

### 2b — UI (`2b_build_ui.md`)

`shared/pet_stage_seat` (`7ef13cc`) is on main, so 2b adopted it — **one
number changed**: `_kNestBoxHeight: 156 → 188`, keeping `nestWidth: 236` and
`fixedPipHeight: 152`. I verified the resulting call is byte-for-byte the
mandated one: `nestW=236, nestH=188, pipH=152`, `stage.nestWidth=236,
nestHeight=188`. The pet block stays the design's 236 px slot
(16.6 + 188 + 31.4), so nothing below it moved and `_kStageToHearts` stayed at
10.75 — no second lever needed.

Two review findings closed as well:

- **Finding 2** — `_kQuestCardShadowRoom` was the one bare `6` left in the
  view; it is now `NestSpacing.gap6`, same value, same revert rule. That was
  the judgement call I flagged at the end of iteration 9, now resolved.
- **Finding 4** — the geometry pin measured the `SvgPicture` **box**, so a
  drift in `PipNestFallback.visibleNestRatio` would have passed silently. The
  pin now asserts the painted outline (`width × ratio ≈ 198`,
  `height × 110/240 ≈ 86`) plus rim 278 / bottom 364 / Pip's feet 301. 2b
  deliberately did **not** switch the call to `visibleNestWidth: 198` as the
  finding suggested, because `ORCHESTRATOR_NOTES` 10:14 mandates keeping
  `nestWidth: 236` and the two are equivalent by construction — and met the
  finding's intent on the assertion side, which is where the drift could occur.
  That is the right call: it satisfies the intent without violating the
  mandate.

`kid_home_view_test.dart`'s explicit-size pin moved with the geometry
(`236×188`, `fallback.nestH == 188`); that was the single test the value
change broke. FIXES_9 deviation 2 (speech-bubble tail) was filed as new
**SHARED_REQUEST #17** with measured numbers, correctly not worked around.

## 2. Integration work done here

No breakage — the tree arrived green and stayed green. Two things I checked
that neither half was asked to.

### Stale geometry comments in `k03_bugs_test.dart`

2b updated the view, `kid_home_view_test.dart` and `kid_home_geometry_test.dart`
for the 156 → 188 change, but **`k03_bugs_test.dart` still documented
`nestHeight: 156` in three places** (the BUG-13 fix note, the BUG-13 box, and
the BUG-14 fix note). A reader would have concluded the shipped call was 156.
Corrected to 188, with the BUG-14 note recording that
`shared/pet_stage_seat` raised it from 156. This is the same class of defect I
fixed in iteration 8, recurring because the value changed in a file the UI
builder did not own. `grep -rn 156` over the feature now returns only the two
deliberate history references.

### Quest order now diverges from the app-wide convention — needs a ruling

A shared batch landed this iteration: `72ac38d Merge shared/shared_batch4: …
**quests in creation order (schema v4)**`. K03's repository re-sorts quests by
title locally (`kid_home_repository_impl.dart:73`,
`..sort((a, b) => a.title.compareTo(b.title))`), so **K03 is now the only screen
that orders quests alphabetically**.

I verified the rendered order rather than inferring it (throwaway probe, run
then deleted): K03 paints

```
Empty the dishwasher · Hoover the stairs · Lay the table ·
Put the bins out · Reading – 20 minutes · Tidy your bedroom
```

whereas the seed inserts Maya's quests as dishwasher → reading → bins → tidy →
hoover, and the shared convention is now that creation order.

Two facts that make this worth a ruling rather than a shrug:

1. The design's K03 PNG shows card 2 as **"Reading – 20 minutes"** — which
   matches *creation* order, not alphabetical (alphabetical puts "Hoover the
   stairs" second). So the new shared convention would actually agree with the
   design where K03's current order disagrees.
2. `1_plan.md` §(a) is explicit and unchanged: *"in repo order (alphabetical —
   visual order differs from PNG sample order; data order wins, do NOT
   re-sort)"*.

**I changed nothing.** No orchestrator rule covers quest order (the CHILD
ORDER ruling is about children, and both child proofs still pass), and
`1_plan.md` forbids re-sorting — so this is an orchestrator decision, not an
integration fix. It is recorded here rather than buried because it is a
cross-screen consistency question with a design-favourable answer for one
option.

## 3. FIXES_9 items

FIXES_9 holds only the Stage-5 UI check, two deviations:

| # | Item | Status |
|---|---|---|
| 1 | Pip seat + nest proportions (squashed 198×72 nest, 41 px low, Pip on the rim) | **DONE** — `shared/pet_stage_seat` landed; 2b adopted it (one number) and extended the real-font pins. 2b also re-measured the *design* side with PIL rather than trusting the note (ink rows 276–278 / 300–302 at the centre column), confirming the fix lands on the design's own rows |
| 2 | speech-bubble tail interior ~10 px short | **LEFT (shared)** — `_TailPainter` lives in `core/design_system/components/nest_pet_stage.dart`; filed as SHARED_REQUEST #17 with measured numbers (design white y 152→174 vs app 152→164) and a no-API-change request. Cosmetic: body identical, nothing downstream moves |

`5_ui` recorded everything else as exact or an accepted override, so no other
UI item was open.

### Skipped tests

**None.** `+1579` with no `~N`; `grep -rn "skip:"` over the feature's tests is
clean. K03-BUG-1…15 all run un-skipped, and the real-font geometry pin passes.

## 4. Verification (in `app/`, this stage)

```
$ dart format .
Formatted 412 files (0 changed) in 0.98 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.7s)

$ flutter test test/features/kid_home
00:05 +175: All tests passed!

$ flutter test
00:27 +1579: All tests passed!
```

- RULES §1 respected: only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**`, `docs/screens/K03/**`. This stage changed
  **comments only** in `k03_bugs_test.dart` plus this note (both probes were
  run and deleted). No product code touched.
- No simulator booted, installed on or captured (SIMULATORS rule: only the
  UI-check stage may, and only `BC440E48-B3A3-43BC-971B-0EF5DB621874`).
- No `google_fonts`/`GoogleFonts`, no `// ignore:` suppression, no `skip:`
  marker in the feature.
- `analysis_options.yaml` untouched; no test weakened to get green.

## 5. Handover

Nothing in K03's scope is outstanding. Carried for other owners:

- **SHARED_REQUEST #17** — `NestSpeechBubble`'s tail interior; shared component,
  cosmetic, blocks nothing.
- **SHARED_REQUEST #6** — the two missing `KidScope` gradient stops (flat 62 %
  horizon line, horizon→meadow grade) that block deleting `_MeadowPainter`.
- **SHARED_REQUEST #16(b)** — a `shadowPadding` parameter on the shared quest
  card; when it lands, delete `_kQuestCardShadowRoom` and put `NestSpacing.s3`
  straight back in the quest column.
- **SHARED_REQUEST #14** — `switchMapStream` belongs in
  `core/data/stream_combine.dart`; adoption is mechanical.
- **New test gap (unchanged)** — no `hasAction(SemanticsAction.tap)` assertion
  pins any K03 control yet. Behaviour was verified correct in iteration 9
  (lock, quest card and all three dock buttons all expose it); the test stage
  should pin it, including that `performAction(tap)` changes real state.
- **Orchestrator ruling wanted** — quest order: keep K03's documented
  alphabetical sort, or adopt the app-wide creation order that the design's
  card 2 actually agrees with (§2).

Next real step is the UI check: the pet block changed shape this iteration, so
stage 5 should confirm on device that the nest sits at 278…364 with Pip inside
the bowl, and bands 2–3 should drop. The bubble tail is cosmetic and will not
move any row.

VERDICT: PASS