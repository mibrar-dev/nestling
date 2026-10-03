# P11 · Approvals — Stage 2 INTEGRATE (iteration 2)

Job: make the two parallel halves (`2a_build_logic.md` + `2b_build_ui.md`)
compile and pass together after the iteration-1 bug hunt. No redesign.

**Outcome: the halves integrated clean — no fix was required.** Both halves
re-ran `dart format` / `flutter analyze` / `flutter test` in their own windows
and the merged tree was green on my first run, so I changed no code. What
follows is the independent verification I ran instead of taking the two notes
at face value.

## Summary of the two halves (FIXES_1 round)

**2a — logic (`domain` / `data` / `bloc`).** Additive contract only: no event
removed or renamed, no state field removed.

1. `Approval` / `ApprovalModel` gain optional `String? kidNote` (default
   null) from `quest_completions.kid_note` (schema v6) — orchestrator item 1,
   data half.
2. New `enum ApprovalsDecision { approve, notYet }` + state field
   `busyActions: Map<int, ApprovalsDecision>` so the card can spin **only the
   pressed pill** (BUG-P11-4). `busyIds` kept and kept in sync.
3. **BUG-P11-1 (major)** — `approve()` is now one transaction whose UPDATE
   claims the row (`WHERE id = ? AND status = 'done_pending'`); 0 rows changed
   returns before touching the ledger (K03-BUG-1 precedent). `approveAll()`
   inherits it. Plus a bloc-side absorb so a same-frame double-tap dispatches
   one write even against an instant repo stub.
4. **BUG-P11-2 (major)** — `markNotYet()` only matches `done_pending` rows, so
   a racing "Not yet" can no longer overwrite an approval while the
   `quest_bonus` row survives.
5. Absorb guards keyed on a private `_decided` set (pruned as rows leave the
   inbox; failures never enter it, so retry still works).

**2b — UI (`presentation/views` + `presentation/widgets`).**

1. **Orchestrator item 1** — the `.qn` quote line renders from `Approval.kidNote`
   (`Padding(top: 10)` + `“$kidNote”`, `bodyStrong(ink).copyWith(fontSize: 17,
   height: 24/17)`), as a **sibling of `.hd`** so it starts at x 36 level with
   the avatar (not indented under `.who` at x 90) — matching the PNG ink start
   at 37.3. NULL/whitespace note ⇒ no line and no gap.
   2b also **measured** rather than guessed the face: CSS sets no
   `font-family` on `.qn`, so it inherits `--font-ui`. Design quote ink spans
   246.7 px; Inter w700 @17 advances 249.2 (≈247 ink), Nunito @17 advances
   232.4 — 14 px short. Inter it is, cross-validated on `.who`
   (228.33 design vs 229.99 Inter). This corrects the bug stage's Nunito guess.
2. **Orchestrator item 3** — new P11-private `ApprovalsBottomCta`: same surface
   fill, 1 px `line` top border, 20 px gutters and 16 px above the pill as the
   shared `NestBottomCta`, but it lifts its content by
   `MediaQuery.padding.bottom + NestSpacing.s6` so the pill lands on the
   design's 734–786 (centre 760) while the surface still runs to the physical
   edge (OWNER bottom-edge rule).
3. **BUG-P11-4** — `ApprovalCard` is now a `StatefulWidget` holding
   `ApprovalDecision? _pending` set before dispatch, so `loading: busy &&
   _pending == <that button>`; both buttons still disable while busy.
4. **BUG-P11-3** — `approvalDayLabel` builds both calendar dates with
   `DateTime.utc(y, m, d)`; `DateTime(y, m, d)` is *local* midnight, so the
   29→30 Mar 2026 London span is 23 h and `inDays` truncated it to 0.
5. **Orchestrator item 4** — real-font geometry test pins both card heights
   (172 with quote / 138 NULL) and both button-row offsets (+108 / +74).

The two builders overlapped on `p11_bugs_test.dart` and briefly on
`approvals_view_geometry_test.dart`; 2b states both were merged, not clobbered,
and the test counts corroborate it (131 approvals tests, 0 skipped — the 9
bug proofs that 6_bugs left behind `skip: true` are all live now).

## FIXES_1 items

| id | severity | done by | status |
|---|---|---|---|
| BUG-P11-1 rapid repeat decisions double-credit `quest_bonus` | major | 2a (DB CAS + bloc absorb) | **DONE** — 4 proofs pass un-skipped |
| BUG-P11-2 "Not yet" overwrites an approved decision | major | 2a (guarded UPDATE + CAS) | **DONE** — 2 proofs pass un-skipped |
| BUG-P11-3 BST spring-forward mislabels the day | minor | 2b (`DateTime.utc` date-only diff) | **DONE** — 2 proofs pass un-skipped |
| BUG-P11-4 both card pills spin, not just the tapped one | minor | 2a (`busyActions`) + 2b (card widget) | **DONE** — 1 proof passes un-skipped |
| ORCH 1 · child quotes from `kid_note` | mandate | 2a (data) + 2b (render) | **DONE** |
| ORCH 2 · pending set from the DB | mandate | — | **confirmed, no change** (DATA OVER MOCKS: Maya dishwasher 8:12 / table 8:05 / Leo bed 7:58) |
| ORCH 3 · "Approve all (N)" pill 8 px low | mandate | 2b | **DONE on this screen** — 734–786, centre 760, surface to the edge. Shared component still 8 px low for every other screen: `SHARED_REQUEST.md` §3 stays open |
| ORCH 4 · card geometry with AND without a quote | mandate | 2b | **DONE** — 172 / 138 pinned in real fonts |

### LEFT for the next iteration

1. **Stage 5 (`5_ui`) owns the screenshots** — `shot.sh` for `/approvals` in
   light + dark on `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`, then `compare.py`.
   Expected app positions are in `2b_build_ui.md`; the two intentional deltas
   from the PNG are the seeded third card being the real `Leo · Make your bed`
   at top 529 (the mock row "Tidy your bedroom" sits at 563) and card 2 having
   no quote because its seeded note is NULL. **No simulator was booted,
   installed on, screenshotted or driven in this stage.**
2. **`SHARED_REQUEST.md` §3 — shared `NestBottomCta` bottom pad.** Still open;
   the shared component is 8 px low for every other screen.
   *Integrator flag, not a blocker:* `ApprovalsBottomCta` is a local
   re-implementation of a shared component, which the owner "never
   re-implement components" rule discourages. It is the right call here —
   RULES.md §1 forbids a screen agent from editing `core/`, the copy is
   tokens-only, and both halves documented it with the swap-back condition
   (one import + one class name once the shared component adopts the 24 px
   pad). Flagged so the orchestrator treats §3 as a real cleanup, not just a
   nicety. I did not redesign it.

## Independent verification (I did not take the notes' word for it)

| claim | how I checked it | result |
|---|---|---|
| `kidNote` reaches the card | `grep kidNote` in repo impl (`:56`) and card (`:122`, `:194-202`) — present, with curly quotes, NULL/blank guarded | confirmed |
| BUG-P11-3 arithmetic | `approval_time.dart:41-42` builds both dates with `DateTime.utc` | confirmed |
| CTA is 8 px low in the *shared* component | shared `nest_bottom_cta.dart` uses `SafeArea(vertical: NestSpacing.s4)` = 16 → at a 34 px inset the pill bottom is 844−50 = 794 (top 742); the local one pads `inset + 24` → 786 (top 734) | confirmed, arithmetic matches the design exactly |
| 2b's "`SafeArea(minimum: 24)` would be a no-op" | `SafeArea` resolves `max(inset, minimum)`; at inset 34, `max(34, 24) = 34`, so it cannot lift the content | confirmed |
| tokens only, no hard-coded sizes/colours | `Color(0x…)` in `lib/features/approvals`: 0. `bottomInset + NestSpacing.s6` where `s6 == 24` (spacing.dart:13) — the "24" is a token, not a literal | confirmed |
| bottom edge | geometry test asserts the pill at 734–786 under `FakeViewPadding(bottom: 34*3)` **and** that the surface owns the 58 px below it | confirmed |
| `google_fonts` | 0 hits in `lib/features/approvals` + `test/features/approvals` | confirmed |
| nothing skipped to go green | `grep "skip: true" test/` → **one** hit repo-wide, `test/features/pocket_money/p12_bugs_test.dart:320`, another feature and pre-existing (present at iteration 1 too). Approvals dir: 131 run, 0 skipped | confirmed |
| my iteration-1 `today`-test fix survived the pre-build main merge | both files still carry `expect(pushedPath(tester), '/approvals')`; the only remaining `P11 Approvals` strings repo-wide are the two rationale **comments** I added | confirmed |

## Gates (run in this worktree, `app/`)

```
$ dart format .
Formatted 470 files (0 changed) in 1.19 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.6s)

$ flutter test test/features/approvals
00:13 +131: All tests passed!

$ flutter test
00:48 +2267 ~1: All tests passed!
```

The single `~1` is the pre-existing `p12_bugs_test.dart:320` skip above, not a
P11 test and not something I introduced.

## Code changed by this stage

**None.** Integration breakages found: 0. Mismatched BLoC states/events: 0
(2a's additions were additive and 2b read only `kidNote` and `busyIds`).
Imports/renamed members: 0. Failing tests from the merge: 0. The
`zz_scratch_probe_test.dart` scratch file 2a flagged mid-iteration is gone, and
`_busy()` is consumed, so no `unused_element` warning survives — confirmed by
the clean `flutter analyze`.

---

# Appendix — iteration 1 record (superseded, kept for history)

Two halves built P11 from `1_plan.md`: 2a the non-UI layer (entity
`createdAtTz`, repo population, the 4 plan events + `busyIds` /
`approveAllBusy` / `actionError`, 18 tests); 2b re-verified the existing view
layer against the plan/HTML/PNG and added the geometry + semantics suites. They
did not collide, but the full suite was red on two P08-owned tests that
anchored on the deleted placeholder `AppBar('P11 Approvals')`. Fixed with the
swap already prescribed by `_shared/router_push_test_fix_REPORT.md`
(`find.text(<placeholder>)` → the shared `pushedPath(tester)` helper), proved
non-vacuous by a negative control, and filed for the orchestrator as a second
section of `SHARED_REQUEST.md` so `main` carries the same 4 lines. Gates then:
`dart format .` → 470 files 0 changed · `flutter analyze` → **No issues
found!** · `flutter test` → `00:39 +2187 ~1: All tests passed!`

VERDICT: PASS