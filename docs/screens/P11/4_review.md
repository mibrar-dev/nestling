# P11 · Approvals — Stage 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` (merge-base `c60016f`) — 14 feature files under
`app/lib/features/approvals/{presentation,domain,data}`, 9 feature test files,
2 out-of-scope test files, 27 notes/PNGs. Reviewed against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P11,
`docs/design/SPACING_SPEC.md`, `design/html-source/screens/P11-approvals.html`,
`design/screens/{light,dark}/P11-approvals.png` (measured directly, ÷3),
`design/html-source/tokens.css` + `components.css`,
`docs/screens/_shared/completion_note_REPORT.md`, and the owner/orchestrator
rules in the stage brief. **No code was edited in this stage. No simulator was
booted, installed on or driven.**

## Verdict summary

**0 blocker · 0 major · 8 minor.** Gates are green on the committed tree
(`flutter analyze` → *No issues found!*, `dart format` → 0 changed,
`flutter test` → **2267 tests, all passed**). The orchestrator's four
`ORCHESTRATOR_NOTES.md` items are all delivered and measured correct. All eight
minors are quality/robustness/consistency items; none blocks the loop.

---

## Findings

### 1. minor — `ApprovalCard` keeps the pressed decision in widget state that a list rebuild can discard, while the bloc already carries it

- `app/lib/features/approvals/presentation/widgets/approval_card.dart:93-104`
  (`_ApprovalCardState._pending`, `_press`), `:218`, `:231`
- `app/lib/features/approvals/presentation/bloc/approvals_state.dart:17`, `:36`
  (`busyActions`)
- `app/lib/features/approvals/presentation/widgets/approvals_loaded_body.dart:71`
  passes only `busy: busyIds.contains(id)`

BUG-P11-4's fix is right in itself (only the tapped pill spins), but it solves
the problem in the wrong place. The bloc publishes the authoritative answer —
`busyActions[completionId] == approve | notYet` — and `ApprovalsView` never
forwards it (`approvals_view.dart:141` passes `state.busyIds` only); the card
re-derives it locally from its own tap. `busyActions` is therefore **write-only
state**: grep finds no reader outside `approvals_bloc.dart` and its own tests.

That is not just duplication. `ApprovalsLoadedBody` uses
`ListView.builder` (`approvals_loaded_body.dart:52`), whose
`SliverChildBuilderDelegate` does **not** carry keys across rebuilds, so when a
sibling row leaves the inbox every following card's element is destroyed and
re-created — `_pending` resets to `null` while `busy` is still `true`, and the
pressed button silently drops its spinner and shows only the disabled state
mid-write. No wrong-button spin is possible (each card owns its own `_pending`),
so the blast radius is a 1-frame visual inconsistency, but the state that fixes
it correctly is already in the bloc and already in the widget tree.

**Fix:** thread it down — `ApprovalsLoadedBody({required Map<int, ApprovalsDecision> busyActions})`,
`ApprovalCard({required ApprovalsDecision? pendingDecision})`, and use
`loading: widget.pendingDecision == ApprovalDecision.approve` /
`== ApprovalDecision.notYet`. `ApprovalCard` then needs no `StatefulWidget`, no
`_pending`, no `_press`, and the `ValueKey('p11_card_$id')` survives a rebuild
with the spinner intact. (If the decision is deliberately *not* in the state,
delete `busyActions` instead — do not keep both.)

### 2. minor — `approvalInitial` splits grapheme clusters

- `app/lib/features/approvals/presentation/widgets/approval_card.dart:51-55`

`trimmed.substring(0, 1)` takes the first UTF-16 code unit. Nicknames are
parent-entered, so a name starting with an emoji, a combining accent or any
astral character renders half a glyph (or `�`) in the `NestAvatar`. The
blank-name guard is correct; only the slicing is wrong. The repo already has the
right answer one feature over: `app/lib/features/pocket_money/
presentation/views/pocket_money_setup_view.dart:684` uses
`child.nickname.characters.first.toUpperCase()`.

**Fix:** `return trimmed.characters.first.toUpperCase();` (identical for ASCII).

### 3. minor — raw `10` where `NestSpacing.gap10` exists (and is used 10 lines below)

- `app/lib/features/approvals/presentation/widgets/approval_card.dart:196`
  (`padding: const EdgeInsets.only(top: 10)`) vs `:140` and `:208`
  (`spacing: NestSpacing.gap10`)

`.qn { margin-top: 10px }` is a design value, and the comment above it is right,
but 10 *is* on the scale: `NestSpacing.gap10 = 10`
(`app/lib/core/design_system/tokens/spacing.dart:31`), documented as covering
"every gap/padding below the 4pt grid". The brief's rule is tokens only, and a
reader of this file now sees both spellings of the same number.

**Fix:** `padding: const EdgeInsets.only(top: NestSpacing.gap10)`.

### 4. minor — raw `error.toString()` is what the parent reads, on both error paths

- `app/lib/features/approvals/presentation/views/approvals_view.dart:121`
  (`Text(state.errorMessage ?? 'Something went wrong')`)
- `app/lib/features/approvals/presentation/views/approvals_view.dart:43-45`
  (SnackBar `Text(message)`, `message == state.actionError`)

The bloc stores `error.toString()` (`approvals_bloc.dart:47-50`, `:78`, `:110`,
`:132`), so `Bad state: No element` or a Drift fragment reaches the UI.
Error path only, off-design; same class as P08's own **B15**
(`docs/screens/P08/FIXES_1.md`). Unchanged from iteration 1.

**Fix:** render a fixed kind line ("We couldn't load the approvals. Your data is
safe — please try again.") and keep the raw message in state for logs; assert
`state.errorMessage` in bloc tests (already done in `approvals_bloc_test.dart`).

### 5. minor — hand-rolled error SnackBar instead of the shared toast

- `app/lib/features/approvals/presentation/views/approvals_view.dart:39-49`

The design system owns this: `showNestToast` / `NestToast`
(`app/lib/core/design_system/components/nest_toast.dart:39`), used by
`kid_home_view.dart`, `money_ledger_view.dart`, `paywall_view.dart`. The P11
version invents a style that exists nowhere in the design system
(`backgroundColor: tokens.danger` + `NestType.bodySmall(onLeaf)` — contrast is
fine, 5.0:1 light and fine dark, **this is not a contrast bug**), drops
`Semantics(liveRegion: true)` so an alert is never announced to VoiceOver, and
with `SnackBarBehavior.floating` and no margin lands on top of the
`ApprovalsBottomCta` panel (which owns the bottom ~127 px). Unchanged from
iteration 1.

**Fix:** `showNestToast(context, message)`, and give it a bottom margin of the
panel height (`NestDevice.homeH + NestSpacing.s6 + 52 + NestSpacing.s4`) so it
clears the CTA rather than covering the "Approve all" button.

### 6. minor — stale comment asserting the fake-async bug that iteration 1 fixed

- `app/test/features/approvals/approvals_view_test.dart:290-294`

The comment still says `ApprovalsRepositoryImpl.approveAll` "awaits
`watchItems().first`, and a Drift query stream never delivers its first event
inside `testWidgets`' fake-async zone — so the real button can be exercised only
here". Iteration 1 replaced that with a one-shot `select().get()`
(`approvals_repository_impl.dart:128-143`), so the claim is false twice over: the
CTA *is* drivable end-to-end against the real repository now, and a stub is used
here only so the in-flight state can be asserted.

**Fix:** rewrite to "stubbed so the in-flight `approveAllBusy` state can be
asserted" and drop the fake-async claim.

### 7. minor — `approveAll()` re-implements the "pending" predicate; the shared fix was never raised

- `app/lib/features/approvals/data/approvals_repository_impl.dart:133-139`

`familyId == Seed.familyId & status == 'done_pending'` is now written twice — in
`AppDatabase.watchPendingApprovals` (`core/data/app_database.dart`) and here.
If core's definition of "pending" ever widens, **Approve all would silently
drain a different set than the inbox shows** — the one place where that
divergence moves money. The one-shot `get()` was the right fix for the
fake-async hang, but it introduced the duplication, and iteration 1's note said
to raise the shared `selectPendingApprovals(familyId)` helper in
`SHARED_REQUEST.md` — which is not in the file's three current sections.

**Fix:** add `Future<List<QuestCompletion>> selectPendingApprovals(String familyId)`
next to `watchPendingApprovals` in core and call it from both. That is a shared
file (RULES §1), so add it as a fourth section to `SHARED_REQUEST.md` — do not
edit core from this branch. Blocks: no.

### 8. minor — `ApprovalsBottomCta` duplicates the shared `NestBottomCta`

- `app/lib/features/approvals/presentation/widgets/approvals_bottom_cta.dart`
  (new file) vs `app/lib/core/design_system/components/nest_bottom_cta.dart`

Same surface fill, same 1 px top `line`, same 20 px gutters, same 16 px above the
pill — the only delta is `EdgeInsets.only(bottom: inset + NestSpacing.s6)` where
the shared component uses `SafeArea` + `vertical: 16`, which is the 8 px
`ORCHESTRATOR_NOTES.md` item 3 asked to close. The brief's design-system rule
says "never re-implement components", and a second copy of a bottom-bar panel is
exactly the drift that rule exists to prevent: when core adopts the 24 px pad,
nothing fails — P11's pinned geometry tests keep passing against the *old*
rects, so the two components diverge silently.

Rated **minor, not major**, because the orchestrator's own note prescribes this
outcome ("Match NestBottomCta's position to the design … If the cause is shared
NestBottomCta, write SHARED_REQUEST.md with numbers"), RULES §1 forbids touching
`core/`, and `SHARED_REQUEST.md` §3 already carries the exact requested numbers
and the one-import/one-class swap-back path. Blocking would contradict a
mandatory orchestrator item.

**Fix:** add `// TODO(P11): delete this file and restore NestBottomCta when the
shared component takes `inset + 24` (SHARED_REQUEST.md §3)` so it is greppable,
and keep the pinned design rects in one place so the divergence is at least
visible in the test file. Nothing else to change on this branch.

---

## Verified correct (no finding)

| Area | Evidence |
|---|---|
| Architecture | Feature-first; `domain/` = entity + abstract repo only; one bloc per screen; `approvals_di.dart` / `approvals_routes.dart` untouched and already correct (`registerFactory` for the bloc ⇒ every push gets a fresh instance, no closed-bloc reuse; `BlocProvider` at the route level). Feature imports resolve to `core/{data,design_system}` + its own feature only — no cross-feature import (`'/today'` is inlined with a comment on purpose). `/approvals` stays top-level outside the shell, so no `NestTabBar`. |
| Design-system reuse | `NestStatusBar`, `NestNavBar(compact)`, `NestCard`, `NestAvatar`, `NestButton` ×4, `NestEmptyState`, `NestCard`/`NestRadii`/`NestType`/`NestSpacing` throughout. `grep` for `Color(0x`, `Colors.`, `#RRGGBB`, `google_fonts`, `GoogleFonts` in `lib/features/approvals/**` → **0 hits**. Every size is a `NestSpacing`/`NestRadii`/`NestDevice` token or a design-CSS value named in `NestButton`'s own doc comment (`fontSize: 15` + `horizontalPadding: 12` + `minHeight: 48` = "the P11 approval rows" call). Only exception: finding 3. |
| Design fidelity — measured off the PNGs (÷3) | Design: banner **107–171**, cards **187–359 / 375–547 / 563–**, CTA panel top **718**, pill **734–786**, paper strip 810–844. App (`ui/app_light_2.png`, iteration 2): banner **107–171**, cards **187–359 / 375–513 / 529–701**, CTA pill **734–786**. Horizontal profiles are pixel-identical to the design at y 200 / 300 / 340 / 760 (card 20–370, "Not yet" 36–195, "Approve" 205–364, CTA 20–370). Font family verified from `tokens.css:203` (`body { font-family: var(--font-ui) }` = Inter): `.who`, `.qn`, `.tm`, `.helper` and `.btn` are Inter, `.avatar` and `.nav-title` are Nunito — which is exactly what `NestType.bodyStrong` / `NestButton` / `NestAvatar` / `NestType.navCompact` resolve to. |
| ORCHESTRATOR_NOTES 1 — quotes | `Approval.kidNote` / `QuestCompletions.kidNote` carried through model + entity + repository; rendered as `“$kidNote”` (U+201C/U+201D added at render time, per `completion_note_REPORT.md`); a NULL note renders **no line and no gap** (`approval_card.dart:194`). Verified in `ui/app_light_2.png`: Maya's dishwasher card and Leo's bed card carry the quotes, Maya's table card (seeded NULL) does not. Pinned by `approvals_quote_test.dart` (4 tests, real seeded DB, real fonts). |
| ORCHESTRATOR_NOTES 2 — pending set | Maya dishwasher 8:12, Maya table 8:05, Leo bed 7:58, straight from `watchPendingApprovals`. Not a finding, correctly treated as DATA OVER MOCKS. |
| ORCHESTRATOR_NOTES 3 — CTA | Pill measured at **734–786**, centre **760** = the design's rect, at the design's 34 px home inset; the `--line` pixel sits at 718 as drawn. Surface-to-edge fill preserved (below). |
| ORCHESTRATOR_NOTES 4 — card geometry | Both heights pinned in real-font tests: quoted **172**, NULL **138**, difference 34, tops **187 / 375 / 529** — the app's third card is 34 px above the design's 563 because the design's third row is the illustrative "Tidy your bedroom" and the seeded one is a quoted bed card. Correct under DATA OVER MOCKS, and explained in the test header. |
| Bottom edge (owner) | Light: `786–844` is `(255,255,255)` = `tokens.surface`, no paper strip, no tint around the home indicator. Dark: `788–844` is `(31,28,46)` = `tokens.surface`. Identical to the design's pill geometry while replacing the design's paper strip, which is exactly the owner override. |
| Alignment (owner) | Every element resolves to the same edges: 20 px side gutters on the scroll and the CTA, card 20–370, nav bar 12 px per `components.css:58`. Measured above, deltas 0. |
| Copy, character by character | `'“Not yet” sends a kind note — no coins are taken away.'` = U+201C, U+201D, U+2014, matching `P11-approvals.html:16` byte for byte (exported as `approvalsHelperCopy`, asserted in `approvals_view_test.dart`). Card line uses U+00B7 with single spaces; quotes use U+201C/U+201D; back label `Back to Today` = the HTML `aria-label`. Counts in `Waiting for you (N)` / `Approve all (N)` are `items.length`, never the design's literal `(3)`. UK spelling throughout; no US spellings introduced. |
| Typography rules | `NestType` styles default to `letterSpacing: 0` and nothing adds tracking; P11's CSS sets none, so no call-site `copyWith(letterSpacing:)` is required (contrast with P12/K02). No `text-wrap: balance` anywhere in `P11-approvals.html` or `tokens.css` for these classes, so `NestBalancedText` is correctly absent. No chips on this screen, so `NestChipWrap` is N/A. No Pip on this screen (initial avatars only). |
| Accessibility | Every interactive node exposes `SemanticsAction.tap`: back chevron (shared `_NavBackButton`), both card buttons, the CTA, Try again — asserted at `approvals_view_test.dart:341/373/397/421/466/472` and `approvals_view_states_test.dart:239/893/919/965`, with `performAction(SemanticsAction.tap)` proven to change real state/DB. The `excludeSemantics: true` wrapper on `.hd` (`approval_card.dart:133`) contains **no** interactive child (both buttons are siblings, below it), so per RULES §8 no `onTap` is required on it — and `approval_card_widget_test.dart` proves it does not swallow the button labels. Disabled buttons report `hasAction(tap) == false` while busy (`approvals_view_states_test.dart:1056`). Tap targets: back 44, card buttons 48, CTA 52, Try again 52. |
| Performance | `ListView.builder` keeps the card list lazy; `const` used where the values allow (`ApprovalsHelperBanner`, `ApprovalsEmptyState`, `SizedBox`s, all four events); no `Timer`/`AnimationController` owned by the feature; `NestButton` disposes its `FocusNode`. Bloc subscriptions are `emit.forEach`, cancelled by the bloc on close (verified against bloc 9.2.1 `emitter.dart:135` — `if (!_isCanceled) _emit(state)`, so the `finally` emits in `_onApprove`/`_onNotYet`/`_onApproveAll` are a silent no-op after a pop mid-write, not an assertion failure). Default concurrent transformer, so the long-lived `forEach` handler never blocks a decision. |
| Error handling | Load failure → message + Try again (re-adds `ApprovalsLoadRequested`, the documented retry path for a dead stream). Action failure → `actionError` + `ApprovalsActionErrorConsumed` with `listenWhen` so each message shows once even if two failures carry identical text. `clearActionError: true` because `actionError: null` means "leave unchanged" (`approvals_state.dart:64`). Two paths to check — see findings 4 and 5. |
| Money correctness | `approve()` claims the row **inside one transaction** (`status = 'approved' WHERE status = 'done_pending'`, `approvals_repository_impl.dart:71-105`) and returns before touching the ledger when `claimed == 0`, so two racing calls credit exactly once; `markNotYet()` is guarded by the same predicate and can never overwrite a decided row; `approveAll()` loops the same CAS so it cannot double-credit. `amountPence: completion.coins` is the schema's own rate (`families.coinValuePencePerCoin = 1`, `core/data/seed.dart:150`; `amountPence` is signed pence per `app_database.dart:160`). BUG-P11-1/2 closed. |
| Date/time | `approvalDayLabel` builds both calendar keys with `DateTime.utc(y, m, d)` (`approval_time.dart:41-43`), so the day comparison is whole days in any host zone — BUG-P11-3 closed (London's spring-forward day would otherwise truncate to 0). Time comes from the shared `formatTime` (noon/midnight edges in one place); day labels render in the row's **stored** zone per the `family_time.dart` contract, with the optional family-zone suffix. |
| Children's Code | `/approvals` is in the router's `parentOnly` list (`router.dart:93`), so kid mode is redirected to the parental gate before the view builds. No analytics, no ads, no network, no logging of child data anywhere in the diff; `familyZoneId` is never written by P11 (the write happens in `approve()`/`markNotYet()` via the existing `AppDatabase` contract, using the stored family zone, not a subscription flag). |
| Scope (RULES §1) | Every changed file is inside `app/lib/features/approvals/{presentation,domain,data}`, `app/test/features/approvals/**`, or `docs/screens/P11/**`. `app/lib/core/**`, `app/lib/app/**`, `analysis_options.yaml` and `pubspec.yaml` are **untouched** (`git diff main...HEAD --stat -- app/lib/core app/lib/app analysis_options.yaml app/pubspec.yaml` → empty). The only exception is the two P08-owned test files (see below). |
| Tests | 235 test declarations across 9 files, none `skip`ped (`p11_bugs_test.dart:5` records that the iteration-1 skips were removed by the test stage). Real in-memory DB for repository/quote/geometry tests, mocktail for bloc paths, real bundled Inter/Nunito loaded via `FontLoader` in every geometry test so a wrap cannot silently shift y. `disposeApp(tester)` at the end of every pumped-app test. |

## Out-of-scope edits — disclosed, not counted as a finding

`app/test/features/today/p08_bugs_test.dart` and
`app/test/features/today/today_view_test.dart` (4 lines each) belong to P08
(RULES §1). Landing the real P11 view retired the foundation placeholder's
`AppBar('P11 Approvals')`, which those two tests used as an anchor, so they
failed on this branch. The edit swaps `find.text(<placeholder title>)` for the
shared `pushedPath(tester)` helper exactly as
`docs/screens/_shared/router_push_test_fix_REPORT.md` prescribes, and it is
disclosed in `SHARED_REQUEST.md` §2. The orchestrator owns landing it on `main`;
per the stage rules this is a merge-order/process item, not a defect.

## Process observations (not findings — uncommitted work, per the stage rules)

Recorded only so the loop is not surprised; none of it is in `main...HEAD`.
While this review ran, a concurrent stage was writing into the worktree
(`git status` showed `approvals_bloc_paths_test.dart` modified at 16:57 plus two
untracked probe files, `p11_probe2_test.dart` / `zz_probe_absorb_test.dart`).
Against that **uncommitted** working tree, `flutter analyze` reports 7 issues
and 3 tests fail. The committed tree, which is what this review covers, is green
(`No issues found!` / 2267 passing). Diagnosis, so it can be fixed in the stage
that owns it — all three are test-harness bugs, not product bugs:

1. `approvals_bloc_paths_test.dart:197` — `verify(() => repo.approve(1)).called(1)`
   is issued twice (`:191` and `:197`). mocktail's `verify` only counts calls
   made since the previous verification of the same matcher, so the second one
   sees 0. Use `verifyNever(() => repo.approve(1))` after the absorb, or drop
   the first verify.
2. `approvals_bloc_paths_test.dart:302` — `verify(...).called(2)` after a
   `called(1)` on the same matcher at `:289`; for the same reason it sees 1 new
   call. Expect `.called(1)` for the post-prune call, or `clearInteractions`
   before it.
3. `approvals_bloc_paths_test.dart:250` — subscription race: the `catch` emit
   (`actionError`) and the `finally` emit (`busyIds` cleared) are queued back to
   back, so `firstWhere((s) => s.actionError != null)` resumes *after* the
   cleared state has already been delivered and `firstWhere((s) => s.busyIds.isEmpty)`
   then waits forever (30 s timeout). Subscribe before the add, or assert
   `bloc.state` after `await pumpEventQueue()`.
4. `cascade_invocations` info at `approvals_bloc_paths_test.dart:220` — same
   file; RULES §7 requires `flutter analyze` → *No issues found!* with no
   ignores, so this must go before the next commit.
5. The two untracked probe files (`p11_probe2_test.dart`,
   `zz_probe_absorb_test.dart`) carry 6 of the 7 lint issues and must be deleted
   or promoted into a real, committed test before the branch is green.

## Gates re-run in this worktree

Run against `git archive HEAD` extracted to a scratch directory, so the moving
working tree could not influence the result, and with no simulator involved.

```
$ dart format --output=none --set-exit-if-changed .
Formatted 470 files (0 changed) in 1.21 seconds.          → clean

$ flutter analyze
No issues found! (ran in 3.9s)                             → clean, no ignores

$ flutter test
01:51 +2267 ~1: All tests passed!
```

## Stage 5 handoff (design-measured vs app-measured, both in logical px)

Measured from `design/screens/light/P11-approvals.png` and
`docs/screens/P11/ui/app_light_2.png`, centre column x = 195, ÷3.

| Element | Design | App (iteration 2) | Delta |
|---|---|---|---|
| Screen title `Waiting for you (3)` | baseline inside nav 47–107, 24-high box at 61 | identical (nav 47–107, title top 61) | 0 |
| First control (helper banner) | 107–171, h 64, 20–370 | 107–171, h 64, 20–370 | 0 |
| Card 1 top / height | 187 / 172 | 187 / 172 | 0 / 0 |
| Card 2 top / height | 375 / 172 | 375 / **138** (seeded NULL note) | 0 / **−34 by data** |
| Card 3 top / height | 563 / 172 | 529 / 172 | **−34 by data** / 0 |
| Card 1 avatar / button row | avatar x 36, 44 high at y 203; pills 36–195 / 205–364, 48 high at y 295 | same rects | 0 |
| CTA panel top | 718 (1 px `--line`) | 718 | 0 |
| CTA pill | 734–786 (h 52, 20–370) | 734–786 (h 52, 20–370) | 0 |
| Surface below the bar | design 810–844 is `paper` | 786–844 is `surface` | **owner override** (BOTTOM EDGE) |
| Dark bottom edge | — | 788–844 = `surface` (31,28,46) | owner rule satisfied |

The two −34 deltas are the DATA-OVER-MOCKS consequence of the seeded NULL note
on `q-table`, not a layout regression; the CTA surface is the owner BOTTOM-EDGE
override. Everything else is inside ±2 px and there is no uniform vertical
shift: the title, the banner and card 1 all land on the design's y exactly.
VERDICT: PASS
