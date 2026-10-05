# 6 BUGS — K03b · Kid home all done (iteration 3)

Stage 6 re-audit after the iteration-3 build (f0717b1). The iteration-2 major
(K03B-BUG-6) verifies fixed, and the new money path it introduced is probed
end to end. No major bugs remain.

Suite: `app/test/features/kid_home/k03b_bugs_test.dart`
— **40 probes run green**, **2 parked proofs fail on demand** (both minor):

```
cd app && flutter test --timeout 120s test/features/kid_home/k03b_bugs_test.dart
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-2
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-7
```

## Resolved in iteration 3

### K03B-BUG-6 — a “Needs my approval OFF” quest still landed in the approvals queue (was Major)

Fixed by `KidHomeRepository.completeQuest`: a quest with
`needsApproval == false` now completes terminally — status `approved`
(+ `decidedAt`/`decidedAtTz`) with a `quest_bonus` ledger credit in the same
transaction, mirroring the approvals `approve` path; the flip is a
compare-and-set (`WHERE id + status IN (to_do, not_yet)`) so a racing retry
credits exactly once. Proof `K03B-BUG-6` is un-skipped and green, plus five
new money-path probes:

| Probe | Result |
|---|---|
| terminal completion: 1 approved row + 1 `quest_bonus` credit, `amountPence` 15 (integer pence), note = quest title | green |
| racing double completion: 1 row, 1 credit | green |
| second completion in the same period (weekly): no extra credit, still 1 approved row | green |
| approval quest unchanged: `done_pending`, no credit, present in the P11 queue | green |
| the terminal credit + approved status survive a database reopen | green |

## Open (minor, non-blocking)

### K03B-BUG-7 — turning “Needs my approval” off after a pending completion leaves it in the queue (Minor)

**Symptom.** A completion created while the quest needed approval stays
`done_pending` when the parent later switches the quest to no-approval. The
kid row then shows the `+N` chip (“no approval needed”, ROW META done +
no-approval) while the parent’s P11 queue still asks for a thumbs-up for the
same completion — the two screens disagree.

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-7` →
`Expected: empty / Actual: WhereIterable<Approval>:[…]`.

**Suggested fix (orchestrator decision, small).** Either auto-approve
in-period `done_pending` completions when P09 saves `needsApproval: false`
(crediting once, approvals shape), or keep the kid row on “Waiting for Mum”
for a completion that is still pending. Not reachable in the demo seed
(all quests need approval and nothing flips the flag).

### K03B-BUG-2 (latent, shared) — `explicitGeometry` still adds `_explicitBleed` to `slotHeight` (Minor)

Unchanged from iteration 2: the shared unit form (`slotHeight` without
`pipBottom`) returns 257.4 instead of the slot. No screen uses that form
(K03b/K06 pass `pipBottom`, K03 passes no `slotHeight`); parked per the
06:44 orchestrator ruling (core-owned, D1). Not a failure.

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
| money | 0 coins renders `0`; no `£`; terminal credits are integer pence, once per completion/period, restart-safe |
| row meta matrix | approved+approval ×3, waiting+approval ×2, done+no-approval `+15` with no chip |
| model round-trip | `KidQuestModel.needsApproval` true default, false round-trip, legacy JSON → true |
| confetti plate | 320×250 at bubble bottom + 20 (stage top + 4) — the D1 absolute layer |
| rapid double tap | Visit Pip double tap lands on one `/pip`; terminal quest racing taps credit once |
| deep link / back | `/kid-home-done` deep link; card → detail → back to the live state |
| restart | file-DB reopen keeps Maya 6/6 and the terminal credit |
| dark mode | all-done renders dark; `leafInk`/`onAccent` pairs ≥ 4.5:1 |
| bottom edge (owner rule) | bar surface reaches the physical edge, light + dark |
| a11y actions | Visit Pip tap action + `performAction` opens `/pip`; cards one node; decorative checks no tap |
| mode guard | kid mode reaches `/kid-home-done`; `/approvals` → gate |
| overflow | full scroll at 320 px / 1.3 raises nothing |
| async/close | every pumped test ends with `disposeApp`; no pending timers |

## Regression

K03 did not move: `k03_bugs_test.dart`, `kid_home_view_test.dart`,
`kid_home_geometry_test.dart` and `kid_home_repository_test.dart` re-run
green after the terminal-completion change (175 passed, 2 parked).

## Iteration history

- **iter 1** — 5 bugs: gap 14 vs 30, shared slotHeight, nest 236×188,
  done-row meta, alphabetical order.
- **iter 2** — all five fixed/worked around; new major BUG-6 (no-approval
  quests still required approval).
- **iter 3** — BUG-6 fixed and money-probed; only minor BUG-7 (edge) and the
  latent shared BUG-2 remain.

VERDICT: PASS
