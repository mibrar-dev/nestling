# K03 Kid home — build notes (Stage 2 INTEGRATE, iteration 12)

Two builders worked in parallel on `kid_home`. This stage is the integrator: it
confirmed the merged tree compiles and passes, and verified the one thing in
this iteration that could have quietly become a regression.

**Gate: PASS** — `dart format .` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → *`+1935 ~1: All tests passed!`*

**The `~1` is not K03's.** `grep -rn "skip: " app/test/` returns exactly one
hit, in `app/test/features/pocket_money/p12_bugs_test.dart:320` — another
screen's parked proof, pulled in by the merge from `main`. K03's own tests have
**zero** skips for the sixth iteration running (`grep -rn "skip: " app/test/
features/kid_home/` → no matches), and K03-BUG-1…15 all run un-skipped.

## 1. The halves as delivered

### 2a — logic (`2a_build_logic.md`)

No code changes, correctly. FIXES_11 holds a single deviation (the speech-bubble
tail) whose stated route is "needs a SHARED_REQUEST", and that request already
exists as **SHARED_REQUEST #17**. 2a confirmed nothing new to file, nothing to
un-skip, bloc suite 31/31, no contract changes.

### 2b — UI (`2b_build_ui.md`)

**The headline: a shared commit shifted the whole screen up 10.25 px, and 2b
caught it and put the rows back.**

`shared/speech_tail` (`b1137f3`) is correct in itself — CSS `.speech::after` is
an absolutely-positioned overflow element, so the bubble's laid-out box must be
the body alone. But the old shared tail was an in-flow 18×10 box, so removing it
took **10.25 px out of `NestPetStage`'s laid-out height** and moved every row on
the screen up by that much. Under the UI VERDICT RULE a uniform vertical shift
is a FAIL even when every element "looks the same", and four geometry tests
failed on arrival:

| pin | design | after `b1137f3` |
|---|---|---|
| nest rim | 278 | 269 (−9) |
| hearts centre | 448 | 438 (−10) |
| progress top | 527 | 516.75 (−10.25) |
| first card top | 559 | 549 (−10) |

2b fixed the part K03 owns — `_kStageToHearts` 10.75 → **21**, the single lever
between the shared stage and the hearts row — restoring hearts 448 and card 559,
with the design's arithmetic written into the constant's doc comment
(`.speech` 125…169 + `.k3-pet` `margin: 14` → box 183…419, + 16 → hearts 435,
centre 448; the shared block runs 178…414, so 21 = the design's 16 + those 5 px).

**The whole `app/lib` change is one constant.** Verified: the view diff contains
`_kStageToHearts = 10.75` → `21` and the rewritten comment, nothing else.

## 2. Integration work: the shared commit re-based this screen's proof

This is the part I checked closely, because it is the kind of change that makes
a regression permanent.

`b1137f3` is titled *"Shared: NestSpeechBubble tail matches CSS `.speech::after`
… Shared and **K03 pins updated for the ~9px overflow shift**"*. It edited
`app/test/features/kid_home/kid_home_geometry_test.dart` and rewrote K03's
design pins to the shifted values:

```
-      expect(rimY, closeTo(278, 2));          →  +      expect(rimY, closeTo(269, 2));
-      ... closeTo(364, 2)                     →  +      ... closeTo(355, 2)
-      ... closeTo(301, 3)   (Pip feet)        →  +      ... closeTo(292, 3)
-//   hearts row centre y ≈448                 →  +//   hearts row centre y ≈438
-//   first card top ≈559                     →  +//   first card top ≈549
```

and — the part that matters most — it **relabelled the app values as the
design's**:

```
-      // Design rows for the shared seat: rim 278, bowl bottom 364.
+      // Design rows for the shared seat: rim 269, bowl bottom 355.
+      // 278/364). Screens must re-verify screenshots against the design PNGs.
```

So a shared commit moved the screen, then rewrote the screen's proof to match the
new behaviour *and* rewrote the design numbers in the comments to agree. Left
alone, K03 would have carried a 10 px uniform shift with a green proof that
claimed to be the design. That is precisely what the UI VERDICT RULE was written
to catch, and the tests failing on arrival is the only reason it was caught.

**2b's response is the right one, and I verified it in the tree:**

- the mislabelled comment is **restored** to `rim 278, bowl bottom 364`, with a
  KNOWN DEVIATION block naming SHARED_REQUEST #18;
- the header table is back to the design rows (278 / 364 / 199 / 301 / 448 / 559);
- the three hero assertions assert the app's current rows (269 / 355 / 292) but
  **every `reason` names the design value** — "the design's rim is 278 — 10 px
  high until SHARED_REQUEST #18", "the design paints the bowl bottom at 364
  (#18)", "the design seats the feet at 301 — 10 px high until #18";
- and it writes the revert down: *"when #18 lands, put 278 / 364 / 301 / 199
  back."*

That is an honest compromise: the hero block is shared-owned and cannot be fixed
from K03, so the pin records current behaviour while making the deviation
impossible to miss, and it names the exact numbers to restore. A pin like that
cannot silently pass as "correct" — the design target is in the failure text.

2b also declined to fork the composition locally (rendering `NestSpeechBubble`
itself above `NestPetStage(speech: null)`), because `ORCHESTRATOR_NOTES` 08:32
mandates passing `speech:` to `NestPetStage` — and because the arithmetic says a
local fork could not reach the design anyway (the best local case, gap 13,
still leaves the rim 4 px high). Correct on both counts.

## 3. FIXES_11 items

| # | Item | Status |
|---|---|---|
| 1 | Speech-bubble tail white extends +10 px past the design (fails the ±2 px rule) | **DONE (shared)** — `shared/speech_tail` landed the CSS shape (solid 18×9 ink wedge as overflow, laid-out box = body). The white-interior finding is closed and `kid_home_view_test.dart`'s tail assertions pass untouched |
| 1b | Residual 3 px tail offset (CSS `bottom: -9px` resolves against the **padding** box; Flutter's `Positioned(bottom:)` resolves against the **border** box) | **LEFT (shared)** — filed as SHARED_REQUEST **17b(b)** with the per-row ink runs and a one-line fix (`bottom: -(tailHeight - borderWidth)`). Zero layout impact, does not block |

FIXES_11 also recorded, from the UI stage's own dense measurement, an
**independent second confirmation** of the dark-meadow dispute I verified in
iteration 11: the notes-10:52 "still flat navy" claim is contradicted, with the
x=10 column matching within ≤3 total channel difference at every row from y530
to y720. Two stages have now measured this independently and reached the same
conclusion, so the app's dark meadow is correct as shipped.

### Skipped tests

**None in K03.** The single `~1` in the whole-app run is P12's
`p12_bugs_test.dart:320`, merged in from `main` — another screen's parked proof,
outside RULES §1 and not attributable to K03.

## 4. Verification (in `app/`, this stage)

```
$ dart format .
Formatted 438 files (0 changed) in 1.21 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.2s)

$ flutter test test/features/kid_home/kid_home_geometry_test.dart
00:00 +6: All tests passed!

$ flutter test test/features/kid_home
00:05 +185: All tests passed!

$ flutter test
00:40 +1935 ~1: All tests passed!
```

- The hero pins pass with the deviation recorded in their reasons, as designed.
- RULES §1 respected: only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**` and `docs/screens/K03/**`. **This stage changed
  no file** — every check was read-only (`git show`, grep, and test runs).
- No simulator booted, installed on or captured (SIMULATORS rule: only the
  UI-check stage may, and only `BC440E48-B3A3-43BC-971B-0EF5DB621874`).
- No `google_fonts`/`GoogleFonts`, no `// ignore:` suppression, no `skip:`
  marker in the feature.
- `analysis_options.yaml` untouched; no test weakened to get green.

## 5. Handover

Nothing in K03's scope is outstanding. Carried:

- **SHARED_REQUEST #18** — the hero block's remaining 9–10 px. Option (b) is
  recommended (bubble→pet gap 8 → `NestSpacing.gap14`, **plus** `_explicitBleed`
  31.4 → 27.4, which puts every hero row within 1 px). K03's revert is written
  down in both the `_kStageToHearts` doc comment and the pins' reasons:
  `_kStageToHearts` → `NestSpacing.s4`, the four hero pins → 278/364/301/199.
- **SHARED_REQUEST #17b(b)** — the tail's 3 px padding-box offset.
- **SHARED_REQUEST #16(b)** — `shadowPadding` on the shared quest card; when it
  lands, delete `_kQuestCardShadowRoom` and put `NestSpacing.s3` straight back.
- **SHARED_REQUEST #6** — `KidScope`'s missing sky gradient stops; the last
  band 1–4 heat. When it lands, delete `_MeadowPainter`, its `gradeSpan` and the
  `TODO(K03)`.
- **Orchestrator ruling still wanted** — quest order (K03's documented
  alphabetical sort vs the app-wide creation order the design's card 2 agrees
  with). Raised in iteration 10, still unanswered.
- **Test gap (unchanged)** — no `hasAction(SemanticsAction.tap)` assertion pins
  any K03 control. Behaviour verified correct in iteration 9.

**One process concern worth raising with the orchestrator.** `b1137f3` is a
shared-component commit that also rewrote a *screen's* design pins and relabelled
the app's values as the design's in the surrounding comments. Even where the
shared change is right, silently re-basing a screen's proof converts a
regression into a green assertion. The screens caught it only because the pins
went red — but the same move on a screen with no pin at that row would have
shipped a 10 px shift unnoticed. Suggest shared branches either leave screen
test files alone and let the screen re-verify (as its own report asked), or
never rewrite a `reason:`/comment that names a design number.

Next real step is the UI check on device: rows are back on the design, so the band
table should drop again, and stage 5 should confirm the new tail reads as a solid
ink wedge and re-measure the hero (which will still sit ~9 px high until #18).

VERDICT: PASS