# P11 · Approvals — bug hunt (Stage 6, iteration 1)

Route `/approvals` · feature `approvals` · parent mode · seeds `Seed.demo()`
(3 pending) and `Seed.empty()` (0) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. Tree tested: iteration-1 checkpoint
`ba946d7` (`screen/P11`). `ORCHESTRATOR_NOTES.md` (15:31/15:38) is accounted
for in "Orchestrator-mandated items" below; the UI stage's PASS is overruled
there, and this stage's verdict is independent of it. No screen code was
changed by this stage.

Proofs live in `app/test/features/approvals/p11_bugs_test.dart` — **9 tests in
4 skipped groups**, one group per bug id. With the skips ignored
(`flutter test test/features/approvals/p11_bugs_test.dart --run-skipped`) all
nine fail on this tree (`+0 -9`); with the skips in place the feature suite is
green (`+110 ~9`). `skip: true, // BUG-P11-x` is used because this
`flutter_test` version's `testWidgets(skip:)` is `bool?`; the bug id is in the
group name and the inline comment.

| Id | Severity | Area |
|---|---|---|
| BUG-P11-1 | **major** | rapid repeat decisions double-credit `quest_bonus` rows — real money minted twice |
| BUG-P11-2 | **major** | "Not yet" overwrites an already-approved decision and the bonus row stays |
| BUG-P11-3 | minor | BST spring-forward mislabels "Yesterday" as "Today" (and two days back as "Yesterday") |
| BUG-P11-4 | minor | both card buttons show the busy spinner, not just the tapped one |

---

## BUG-P11-1 — major — rapid repeat decisions double-credit quest bonuses

**Where.** `data/approvals_repository_impl.dart`:
`approve()` `:62-96` reads the completion and checks
`status == 'done_pending'` **outside** its `transaction`; `approveAll()`
`:113-128` re-selects the `done_pending` set and calls `approve()` per row with
no claim. Two in-flight calls both pass the read-guard, so both UPDATE the row
and both INSERT a `quest_bonus` ledger row. The bloc cannot prevent it:
bloc 9's default event transformer is the flat-map concurrent transformer
(`Bloc.transformer` in `bloc-9.2.1/lib/src/bloc.dart`), and the busy state only
paints on the next frame — the same same-frame double-tap window already filed
as P10-BUG-1 / P08-B12.

**Repro (repository, deterministic).** Seed `demo`, then
`Future.wait([impl.approve(id), impl.approve(id)])` for the dishwasher
completion → **2** `quest_bonus` rows (id 20 and 21, 15p each), expected 1.
Concurrently `Future.wait([impl.approveAll(), impl.approveAll()])` → **15**
rows / **360p**, expected 12 / 330p: all three pendings credited twice
(dishwasher 15×2, table 10×2, bed 5×2).

**Repro (screen, real DB).** Pump `/approvals` and tap the real
"Approve all (3)" CTA twice before a frame renders → `quest_bonus` total
**345p** (330 + a duplicated 5p+10p), the same screen the parent uses.
With a counting stub, a same-frame double-tap on a card's "Approve" dispatches
**2** write calls.

**Proofs.** `concurrent approve() calls both credit the same completion`;
`concurrent approveAll() calls duplicate bonus rows`;
`same-frame double-tap on "Approve all" duplicates credits`;
`same-frame double-tap on Approve dispatches two writes`.

**Suggested fix.** Make each decision a compare-and-set inside one
transaction, e.g.

```dart
await _db.transaction(() async {
  final changed = await (_db.update(_db.questCompletions)
        ..where((c) => c.id.equals(completionId) & c.status.equals('done_pending')))
      .write(QuestCompletionsCompanion(status: const Value('approved'), ...));
  if (changed == 0) return;                 // someone already decided
  await _db.into(_db.ledgerEntries).insert(...); // credit exactly once
});
```

`approveAll()` then inherits the same guarantee through `approve()`.
Precedent in-tree: `kid_home_repository_impl.dart:139-196`
(`completeQuest` is explicitly "Idempotent inside one transaction
(K03-BUG-1)"). A sequential event transformer would shrink the window but the
DB CAS is the real fix (and keeps a future multi-bloc/device path safe).

## BUG-P11-2 — major — "Not yet" overwrites an approved decision

**Where.** `markNotYet()` `:99-110` writes `status = 'not_yet'`
unconditionally — no `done_pending` guard, no transaction. `approve()` has a
guard (weak, per BUG-P11-1), but a "Not yet" that starts after (or races) an
approval flips the row back while the `quest_bonus` row stays.

**Repro.** `await impl.approve(id); await impl.markNotYet(id);` → the
completion is `not_yet` **and** the 15p `quest_bonus` row is still there.
On screen, tapping Approve and then "Not yet" in the same frame (both buttons
are still enabled) leaves exactly that inconsistent pair — the child is paid
but the quest is marked "not done", and the parent saw the card disappear
without any of it being visible.

**Proofs.** `markNotYet() after approve() keeps the bonus with not_yet`;
`same-frame Approve then Not yet leaves not_yet + bonus`.

**Suggested fix.** Same CAS shape as BUG-P11-1:
`UPDATE … SET status='not_yet' WHERE id = ? AND status = 'done_pending'`; if
0 rows changed, the decision was already made — no-op.

## BUG-P11-3 — minor — BST spring-forward shifts the day labels

**Where.** `presentation/widgets/approval_time.dart:31-41`: the day distance
is `today.difference(createdDay).inDays` over **local** `DateTime(y, m, d)`
values. On a UK device the spring-forward day (29 Mar 2026, 01:00 GMT →
02:00 BST) makes the 29→30 Mar midnight span 23h, which truncates to
`0` → "Today"; the 28→30 Mar span (47h) truncates to `1` → "Yesterday".

**Repro (host Europe/London).** `approvalDayLabel(created 2026-03-29 18:00 UTC
= 19:00 London, now 2026-03-30 12:00 UTC)` → **"Today"**, expected
"Yesterday"; `created 2026-03-28 18:00 UTC` → **"Yesterday"**, expected
"Sat 28 Mar". (The automated-threshold hours are the same arithmetic; only
the truncation direction changes, which is why the autumn transition does
not reproduce.)

**Proofs.** `a completion from yesterday renders as Today`; `a completion
from two days back renders as Yesterday`.

**Suggested fix.** Do the difference on date-only values built in UTC
(immune to the writer's local DST), e.g.
`DateTime.utc(today.year, today.month, today.day)
 .difference(DateTime.utc(createdDay.year, createdDay.month, createdDay.day))
 .inDays`.

## BUG-P11-4 — minor — the untapped button spins too

**Where.** `presentation/widgets/approval_card.dart:160-181`: both buttons get
`loading: busy` and `onPressed: busy ? null : …`; the state only tracks
`busyIds`, so it cannot know which button was tapped. Plan §1 specifies
"loading: true only if THIS button was tapped".

**Repro.** Tap a card's "Approve" and pump one frame: both the Approve and the
"Not yet" pills are `loading == true` / disabled. The parent sees a decision
they did not make going busy.

**Proof.** `Not yet also loads while only Approve was tapped`.

**Suggested fix.** Track the in-flight action per id (e.g.
`Map<int, ApprovalsDecision> busy`) and pass `loading`/`onPressed` per button;
or relax plan §1 explicitly if the shared busy state is preferred.

---

## Orchestrator-mandated items (ORCHESTRATOR_NOTES.md — every item accounted for)

1. **Child quotes must render from `completions.kid_note` (schema v6).**
   Not yet possible on this tree: `kidNote`/`kid_note` is absent from
   `app/lib/core/data/app_database.dart` and
   `docs/screens/_shared/completion_note_REPORT.md` is not present at
   `ba946d7` — the shared change is not merged into this worktree yet. Next
   build (after the pre-build main merge) must render the note exactly per
   the HTML: one 17/24 w700 Nunito line at `margin-top: 10` between `.hd` and
   the button row, curly quotes from the shared report, and **no line and no
   gap** when the note is NULL. See item 4 for the geometry pin.
2. **Pending set comes from the DB** — confirmed correct (Maya dishwasher
   8:12 / Maya table 8:05 / Leo bed 7:58); not a finding.
3. **CTA position ≈8 px low vs the design.** Measured at `ba946d7`: design
   button y 734–786 (centre 760); app simulator y 742–793 (centre ≈768);
   zero-inset widget test pins 776–828. Cause is the shared
   `NestBottomCta` (SafeArea + vertical 16 → `bottom = safeArea.bottom + 16`);
   filed in `SHARED_REQUEST.md` §3 with the numbers and the requested
   `safeArea.bottom + 24` bottom pad (button 734–786, surface still to the
   edge). P11's `approvals_view_geometry_test.dart` currently pins the old
   position and must change with the component or the deviation stays green.
4. **Card geometry with and without a quote.** Blocked on item 1 landing: the
   real-font geometry test must pin both card heights — 172 (quote block
   10+24=34 present) and 138 (NULL note, current behaviour) — and the
   with-quote button row 34 px lower than today's bare-card anchors. The
   current test pins only the bare 138.

## Checked — no defect found

- **Data edges.** 0 children (`Seed.empty` → "All caught up", no CTA),
  1 child and 6 children (no count branching in the screen), empty inbox
  after approve-all, `0 coins` completions (plain `0 coins` copy).
- **Long UK names / big numbers.** "Maximilian-Alexander" + a long quest title
  + `9999 coins` at 320 px wide, text scale 1.3: no overflow exception; the
  `.who` and `.tm` lines ellipsize as designed.
- **Kid-mode guard.** Deep link `/approvals` with kid mode selected redirects
  to `/parental-gate`; no approvals chrome is built.
- **Restart persistence.** File-backed DB: approve one row, close, reopen →
  2 pending + the new `quest_bonus` row survive; no reseed in the persistence
  path.
- **Async gaps.** `emit` after `bloc.close()` is a safe no-op in bloc 9
  (emitters cancel; verified by closing the bloc mid-`approve`); Approve then
  back in the same frame lands on `/today` with the write committed and no
  exception.
- **Back navigation.** Cold `/approvals` back → `/today` (canPop false) and
  pushed-from-Today back → `/today` (pop); a same-frame double-back does not
  throw or over-pop.
- **Dark mode.** `paper`/`surface`/`leafTint` pairs match the dark PNG tokens
  (5_ui sampling); helper leaf-ink-on-leaf-tint and caption ink-2 contrast are
  the shared token pairs.
- **Text scale / width.** Existing 320 × 1.3 test plus the long-name probe
  above: no overflow.
- **Money / timezone outside BUG-P11-3.** Coins→pence is integer 1:1 (no
  rounding); `12:00am`/`12:05pm` edges and the stored-zone "same local day"
  rule are covered by the existing helper tests.

## Verification run (this stage)

```
$ dart format --output=none --set-exit-if-changed test/features/approvals
Formatted 8 files (0 changed) in 0.03 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test test/features/approvals
00:02 +110 ~9: All tests passed!

$ flutter test test/features/approvals/p11_bugs_test.dart --run-skipped
00:01 +0 -9: Some tests failed.   # every proof fails on ba946d7, as intended
```

No simulator was booted, installed on, screenshotted or driven in this stage
(UI-check stage only).

VERDICT: FAIL
