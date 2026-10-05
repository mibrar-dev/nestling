# Fix list after iteration 2

## From 6_bugs.md
# 6 BUGS — K03b · Kid home all done (iteration 2)

Stage 6 re-audit after the iteration-2 build (fdddd17). All four iteration-1
geometry/row bugs verify fixed by their now-un-skipped proofs; one new major
data-flow bug is open.

Suite: `app/test/features/kid_home/k03b_bugs_test.dart`
— **34 probes run green**, **2 parked proofs fail on demand**:

```
cd app && flutter test --timeout 120s test/features/kid_home/k03b_bugs_test.dart
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-2
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-6
```

## Resolved in iteration 2 (proofs now run un-skipped and pass)

| Bug | Fix verified | Proofs |
|---|---|---|
| K03B-BUG-1 bubble→pet gap 14 vs 30 | `SizedBox(s4=16)` + `Padding(top: gap14)`; pet top 221, chip centre 480, progress 513, card 1 545 — all within ±2 | `K03B-BUG-1` (×2) |
| K03B-BUG-2 pet block 257.4 vs 226 | feature-side per D1: `pipBottom: 92` takes the `explicitGeometry` early return that honours `slotHeight`; the composed block is 226.0 | `the all-done pet block is the design 226 px` |
| K03B-BUG-3 nest art 236×188 vs 226×226 | local `_kAllDoneNestBoxWidth/Height = 226/226`; outline 190.2×103.5, rim 310.4, bowl bottom 413.9, Pip centre 280.3 — within ±2 | `K03B-BUG-3` |
| K03B-BUG-4 done-row meta | `_QuestCard` branches on status + `needsApproval`: approved+approval → “Mum said yes!”, done+no-approval → `+N` chip, waiting+approval → “Waiting for Mum” | `K03B-BUG-4` (×2), `the done-row meta matrix matches ROW META` |
| K03B-BUG-5 alphabetical order | repository no longer title-sorts; creation order (dishwasher, reading, bins, tidy, hoover, table) | `K03B-BUG-5` |

K03 did not move: `k03_bugs_test.dart`, `kid_home_view_test.dart` and
`kid_home_geometry_test.dart` re-run green after the meta/order changes.

## Open

### K03B-BUG-6 — a “Needs my approval OFF” quest still lands in the approvals queue (Major, feature data flow)

**Symptom.** P09 lets a parent turn “Needs my approval” off
(`quest_editor_view.dart:1059`, default ON). When the kid completes such a
quest, the kid row correctly shows its `+N` coin chip (ROW META done +
no-approval), but the completion is still written `done_pending`
(`kid_home_repository_impl.dart` `completeQuest` hard-codes it), so the parent
gets a redundant approvals row and the coins are only credited if the parent
approves — for a quest that was explicitly set to need no approval. The ROW
META third case is unreachable in production without the parent approving
first.

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-6` →
`Expected: empty / Actual: WhereIterable<Approval>:[…]` — the completed
no-approval quest is in the P11 approvals queue.

**Suggested fix (orchestrator decision).** Make the completion terminal for
no-approval quests: `completeQuest` writes `approved` (+ `decidedAt`) and
credits the ledger for `needsApproval == false`, mirroring the approvals
`approve` path (integer pence, one transaction), or have the approvals
repository exclude + auto-approve those rows. Either way keep the kid row
unchanged and re-run the K03/K03b suites.

## Parked, latent (not a screen bug)

### K03B-BUG-2 (latent, shared) — `explicitGeometry` still adds `_explicitBleed` to `slotHeight`

The shared unit form (`slotHeight` without `pipBottom`) still returns
`nestTop + nestH + _explicitBleed` = **257.4** instead of the slot
(`motion/pip_rive.dart`, final return; the `stageH = effectiveSlotH` local is
dead code). No screen uses that form now (K03b and K06 pass `pipBottom`, K03
passes no `slotHeight`), so this is a latent shared contract quirk the
orchestrator owns (D1 forbids touching `core/**` from this branch). Kept
parked: `K03B-BUG-2 (latent, shared)`. **Minor.**

## Checked clean (probes green in the plain run)

| Area | Evidence |
|---|---|
| all-done truth table | empty/partial/`not_yet` → false; approved+pending → true |
| live flip K03→K03b | completing the last two quests on `/kid-home` shows the celebration |
| live flip K03b→K03 | a completion flipped to `to_do` flips back to “5 done today” + dock |
| period expiry | next London day resets daily, keeps weekly → “2 done today”; London-midnight + Mon–Sun direct probes |
| BST fall-back | 00:30 BST Sun 25 Oct counts at 04:00 GMT; not on Mon 26 Oct |
| 0 children / 0 quests / 1 quest | picker / “No quests today” / “1 of 1 done” |
| 6 children | extra children don’t change the all-done state |
| long name + 9999 coins | “Maximilian-Alexander” + 9999 at 320 px / 1.3, no overflow |
| money | 0 coins renders `0`; no `£`; integer coins end-to-end |
| row meta matrix | approved+approval ×3, waiting+approval ×2, done+no-approval `+15` with no chip |
| model round-trip | `KidQuestModel.needsApproval` true default, false round-trip, legacy JSON → true |
| confetti plate | 320×250 at bubble bottom + 20 (stage top + 4) — the D1 absolute layer |
| rapid double tap | Visit Pip double tap lands on one `/pip` |
| deep link / back | `/kid-home-done` deep link; card → detail → back to the live state |
| restart | file-DB reopen keeps Maya 6/6 |
| dark mode | all-done renders dark; `leafInk`/`onAccent` pairs ≥ 4.5:1 |
| bottom edge (owner rule) | bar surface reaches the physical edge, light + dark |
| a11y actions | Visit Pip tap action + `performAction` opens `/pip`; cards one node; decorative checks no tap |
| mode guard | kid mode reaches `/kid-home-done`; `/approvals` → gate |
| overflow | full scroll at 320 px / 1.3 raises nothing |
| async/close | every pumped test ends with `disposeApp`; no pending timers |

## Observations (not findings)

- The bubble is the design’s 260-wide, 2-line box; start alignment landed on
  main via `shared/speech_align`.
- The `kid_all_done` seed keeps every quest `needsApproval = true`, so the
  UI-check state shows six “Waiting for Mum” rows while the PNG shows
  “Mum said yes!” + `+N` pills — DB-driven meta per DATA OVER MOCKS / ROW
  META (the design’s per-row state is reachable with different DB rows, as
  the meta-matrix probe shows). Seed edits are orchestrator-owned.

