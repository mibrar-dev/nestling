# 6 BUGS — K03b · Kid home all done (iteration 1)

Stage 6 adversarial pass over the all-done state (`/kid-home-done`, and the
same state of `/kid-home` after the last quest), on `SEED=kid_all_done`
(Maya 6/6, light + dark).

Suite: `app/test/features/kid_home/k03b_bugs_test.dart`
— **24 probes run green**, **7 parked proofs fail on demand**:

```
cd app && flutter test --timeout 120s test/features/kid_home/k03b_bugs_test.dart
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-1
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-2
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-3
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-4
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-5
```

Cross-reference: 5_ui.md deviation 1 measured the same +15.3 px shift
(title 469.3→484.7, progress 513.0→528.7, card 1 545.0→560.7); this stage's
parked proofs pin the root causes and the exact target decomposition below.
The 04:52 ORCHESTRATOR_NOTES (D1 no shared edits, ROW ORDER, ROW META) are
mandatory for iteration 2; K03B-BUG-4/5 are their current-code violations.

Design rows used by the geometry proofs (measured from
`design/screens/light/K03b-kid-home-done.png` ÷3 with PIL):
bubble 125…191 (2 lines, 260 wide), pet box top 221 = bubble + 16
(`.scroll > * + *`) + 14 (`.k3-pet` margin), pet block 226
(`.k3-pet { height: 226px }`), chip 464…496 (centre 480), progress 513…529,
card 1 top 545, confetti plate 320×250 at stage top + 4 (= pet top − 10),
nest art 226×226 (SVG `meet` in the 260×226 img) → outline 190×104,
rim 310.4, bowl bottom 413.9, Pip box −16…134 from the pet top.

---

## K03B-BUG-1 — the bubble→pet gap is 14 px where the design is 30 px (Major, feature)

**Symptom.** The hero sits 16 px high (pet box top **205** vs the design
**221**) and, together with K03B-BUG-2, every row below it is **15.4 px low**:
chip centre **495.4** vs 480, progress top **528.4** vs 513, card 1 top
**560.4** vs 545 — a UI-verdict failure at every band.

**Cause.** The design has two stacked gaps between the bubble and the pet:
`.scroll > * + * { margin-top: var(--s4) }` (16) on `.k3-stage`, then
`.k3-pet { margin: 14px auto 0 }` (14, inside the flex stage so the two do not
collapse). `_AllDoneBody` uses a single `SizedBox(height: NestSpacing.gap14)`
(`kid_home_view.dart:870`) — it reproduces the 14 and drops the 16.

**Repro.**
`flutter test --run-skipped --plain-name K03B-BUG-1`
(`K03B-BUG-1: the bubble→pet gap is the design 30 px, not 14` → Actual 14.0;
`K03B-BUG-1: every row below the hero is on the design row` → pet 205 vs 221).

**Suggested fix.** After the bubble use `SizedBox(height: NestSpacing.s4)`
and put the `.k3-pet` margin back as 14 px of top padding around the pet/Stack
(or a single 30 px gap with the confetti moved to pet top − 10). Keep the
confetti plate at 320×250 (see K03B-BUG-2's interaction note). Do not touch
the not-done branch.

**Exact target decomposition (why “stage ≈ 248.6” is a trap).** The design's
bubble-bottom→title-box distance is exactly 272 px = 16 (`.scroll > * + *`) +
14 (`.k3-pet` margin) + 226 (`.k3-pet` height) + 16 (`.k3-sec` margin):
190.7 + 272 = 462.7 box top, and the measured title glyph top 469.3 is
462.7 + 6.6 (Nunito 28/34 cap offset — the app's own glyph sits 6.6 below its
box top today). 5_ui's “block ≈ 248.6” comes from reading the glyph top as a
box top under the current 14 px gap; hard-coding a 248.6 px stage under that
structure would land the title glyph at ≈ 475.9 — still ~6.6 px low. Fix the
gap and the block is the design's 226.

## K03B-BUG-2 — `PipNestFallback.explicitGeometry` ignores `slotHeight` (Major, shared/core)

**Symptom.** K03b's pet block is **257.4 px** instead of the design's **226**
(`.k3-pet { height: 226px }`), i.e. the shared `_explicitBleed` 31.4 is added
on top of the slot.

**Cause.** `app/lib/core/design_system/motion/pip_rive.dart`
(`explicitGeometry`, ~line 677): the `if (slotHeight != null)` branch sets
`stageH = effectiveSlotH`, but the final `return` recomputes
`stageH: nestTop + nestH + _explicitBleed` (38 + 188 + 31.4 = 257.4). The
`pipBottom` early-return correctly returns the variable, which is why K06
(206) is unaffected; K03 passes no `slotHeight` and is unaffected too. Only
K03b (slotHeight without pipBottom) is bitten.

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-2`
(`K03B-BUG-2: the slotHeight pet block is the design 226 px` →
unit `stageH` 257.4, widget height 257.4).

**Suggested fix (shared).** In `explicitGeometry`, return the `stageH`
variable in the final return as well (it already holds `effectiveSlotH` when
`slotHeight != null`). File as a SHARED_REQUEST: the screen may not edit
`core/**` (ORCHESTRATOR_NOTES 04:52 D1 explicitly forbids touching
`pip_rive.dart` from this branch — a feature-side height correction at the
call site is the alternative; the required block height and the exact row
decomposition are in K03B-BUG-1).

**Interaction.** Today the extra 31.4 px is what gives the confetti plate its
250 px of room, so the plate paints 320×250 (top 209 vs design 211.3). Fixing
this alone shrinks the plate to 284×222 — K03B-BUG-1/2/3 must land together,
and the plate needs an explicit 250 px height plus `Stack(clipBehavior:
Clip.none)` so the CSS overflow (14 px past the stage) is reproduced instead
of scale-down.

## K03B-BUG-3 — the nest art is K03's 236×188 box, not the design's 226×226 (Major, feature)

**Symptom.** The celebration nest is 8.4 px too wide and 17.3 px too flat:
bowl outline **198.6×86.2** vs the design **190.2×103.5**; rim **317.4** vs
310.4; bowl bottom **403.6** vs 413.9; Pip centre **285.6** vs 280.3.
A screenshot band check cannot pass this.

**Cause.** `_AllDoneBody` passes K03's transcribed numbers
(`nestWidth: 236, nestHeight: 188`, `BoxFit.fill`) but K03b's `.k3-pet` is
260×**226** tall, so the browser's SVG `meet` draws a **226×226** art
(letterboxed 17 px each side). K03's numbers paint K03's 236-tall design, not
this one.

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-3`
(`K03B-BUG-3: the nest art is the design 226×226 (outline 190×104)` →
width 236 vs 226).

**Suggested fix.** Add all-done-local constants `226/226` (do **not** change
`_kNestBoxWidth/_kNestBoxHeight` — `_KidPetStage` shares them and K03 must not
move): `nestWidth: 226, nestHeight: 226, fixedPipHeight: 152, slotHeight: 226`.
With K03B-BUG-1/2 fixed this lands the art at pet top 0, rim 310.5, bowl
bottom 414, feet 333.5 and Pip box −18.3…133.7 (design −16…134) — all within
2 px.

## K03B-BUG-4 — the done-row meta is missing “Mum said yes!” and the +N chip (Major, feature, mandated)

**Symptom.** `_QuestCard` renders `Done` for every `approved` row and never a
coin chip. The 04:52 ORCHESTRATOR_NOTES ROW META (and the K03b HTML) require:
waiting → “Waiting for Mum” (current app OK), approved-and-needed-approval →
“Mum said yes!”, done-and-no-approval → the `+N` coin chip. The
`kid_all_done` seed makes all six `done_pending`, so the UI-check seed hides
this; a real parent approval (or a no-approval quest) exposes it.

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-4`:
`…says “Mum said yes!”` (app shows `Done`) and
`…shows its +N coin chip` (app shows `Done`, no `+15`).

**Suggested fix.** Branch the meta on the completion status + the quest's
`needsApproval` flag (`app/lib/features/kid_home/data/kid_home_repository_impl.dart`
does not surface `needsApproval` on `KidQuest` yet — add it to the entity/model
in this feature and use it in `_QuestCard`). Keep K03's demo rows
(`Waiting for Mum` / `+10` / `+15`) unchanged and re-run K03's geometry pin.

## K03B-BUG-5 — the quest list is alphabetical, the owner rule says creation order (Major, feature, owner rule)

**Symptom.** The all-done list renders dishwasher, hoover, lay-the-table,
bins, reading, tidy; the design and the 04:52 ROW ORDER rule say creation
order: dishwasher, reading, bins, tidy, hoover, table. The repository re-sorts
by title (`kid_home_repository_impl.dart:74`).

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-5` — the card
titles list starts `['Empty the dishwasher', 'Hoover the stairs', …]` instead
of `[… 'Reading – 20 minutes', 'Put the bins out', …]`.

**Suggested fix.** Drop the title sort and keep `watchActiveQuests`' creation
order (`created_at`, then id); prove K03's demo rows still match the K03
design (its UI check pinned card 1 only, but the seed's first card is
dishwasher in both orders).

---

## Checked clean (probes kept green in the plain run)

| Area | Evidence |
|---|---|
| all-done truth table | empty/partial/`not_yet` → false; approved+pending → true (`allDone` probe) |
| live flip K03→K03b | completing the last two quests on `/kid-home` shows “All done!” + “6 of 6 done” + Visit Pip |
| live flip K03b→K03 | a completion flipped to `to_do` in the DB flips the screen back to “5 done today” + dock |
| period expiry | next London day: daily completions reset, weekly survive → “2 done today”, no all-done (anchor-shift probe); direct `countsForCurrentPeriod` probes for London midnight and Mon–Sun weeks |
| BST fall-back | 00:30 BST Sun 25 Oct counts at 04:00 GMT; not on Mon 26 Oct |
| 0 children | `/kid-home-done` → “Who’s playing?”, no bar |
| 0 quests | “No quests today”, never all-done |
| 1 quest | “1 of 1 done”, Visit Pip |
| 6 children | extra children don’t change Maya’s all-done state |
| long name + 9999 coins | “Maximilian-Alexander” + 9999 at 320 px / textScale 1.3, no overflow |
| money | 0 coins renders `0`; kid screens never show `£`; coins are ints end-to-end |
| rapid double tap | double-tapping Visit Pip lands on one `/pip`; cards/checks keep their K03 latches; lock latch K03-tested |
| deep link / back | `/kid-home-done` deep link renders the state; card → `/quest-detail` → back returns to the live all-done screen |
| restart | file-DB reopen keeps Maya 6/6 (all completions persist) |
| dark mode | all-done renders in dark; `leafInk`/`onAccent` pairs ≥ 4.5:1 on sky, leaf-tint and lilac |
| bottom edge (owner rule) | the bar’s surface reaches the physical edge in light and dark (34 px inset) |
| a11y actions | Visit Pip `hasAction(tap)` + `performAction(tap)` opens `/pip`; each done card is one tappable node; decorative checks expose no tap |
| mode guard | kid mode reaches `/kid-home-done`; `/approvals` still redirects to the gate |
| overflow | scrolling the whole all-done list at 320 px / 1.3 raises nothing |
| async/close | every pumped test ends with `disposeApp`; no pending-timer teardown failures |

## Observations (not findings)

- The bubble matches the design (260 wide, 2-line box, measured 65…325);
  the wrap point matches the design’s “You did everything today! Pip /
  is so proud.” within Flutter-vs-browser shaping tolerance. The design’s
  start alignment (line 2 at the left edge) is fixed on main by
  `shared/speech_align` (ORCHESTRATOR_NOTES 04:52 D2) — not this branch.
- The all-done state itself (getter, route, header, semantics, live flips,
  period expiry) held up under every edge probe; the bugs above are layout
  transcription errors in the new all-done body, one shared slot-height
  contract bug, and two mandated row-content/order rules the current code
  does not implement.

VERDICT: FAIL
