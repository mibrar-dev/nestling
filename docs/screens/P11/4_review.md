# P11 · Approvals — Stage 4 QA code review (iteration 1)

Scope: `git diff main...HEAD` (5 commits, 9 feature files + 5 feature test files
+ 2 out-of-scope test files + notes). Reviewed against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P11,
`design/html-source/screens/P11-approvals.html`, both design PNGs, and the
orchestrator rules in the stage brief. **No code was edited in this stage.**

## Verdict summary

**0 blocker · 0 major · 8 minor.** The screen is architecturally sound,
tokens-only, copy-exact, accessible and green. The minor findings are
quality/robustness items plus one orchestrator-resolved ownership item; none of
them blocks the loop.

---

## Findings

### 1. minor — out-of-scope edits to a P08-owned test directory (RULES §1)

- `app/test/features/today/p08_bugs_test.dart:260-264` (+ the local
  `currentUri` helper deleted at `:41-43`)
- `app/test/features/today/today_view_test.dart:212-218`

RULES §1 allows a screen agent `app/test/features/<feature>/**` only; the
`today/` tree belongs to P08, whose loop is running at the same time on the same
two files. The edit itself is correct — it swaps `find.text('P11 Approvals')`
(the foundation placeholder title P11 legitimately deleted) for the shared
`pushedPath(tester)` helper, exactly as
`docs/screens/_shared/router_push_test_fix_REPORT.md` prescribes — and it is
disclosed in `SHARED_REQUEST.md` §2 and `2_build.md` FIXES 1, with a negative
control proving the assertion is live.

**Not fixable by reverting:** putting the placeholder title back breaks
DESIGN_SPEC §5 P11, so reverting turns the suite red. Rated minor (not major)
because it is an ownership/process item the orchestrator owns — the stage rules
say merge order and orchestrator-handled process items are not findings, and no
`lib/` behaviour is affected.

**Fix (orchestrator):** land the same 4-line swap on `main` (or accept it from
`screen/P11`) before `screen/P08` merges, then rebase. No change on this branch.

### 2. minor — raw `error.toString()` reaches the parent on both error paths

- `app/lib/features/approvals/presentation/views/approvals_view.dart:119`
  (`Text(state.errorMessage ?? 'Something went wrong')`)
- `app/lib/features/approvals/presentation/views/approvals_view.dart:43-45`
  (SnackBar `Text(message)` where `message == state.actionError`)

The bloc stores `error.toString()` (`approvals_bloc.dart:44-49`, `:60-68`), so
a `Bad state: No element` or a Drift fragment is what a parent reads. This is
the same defect P08's own review filed as **B15** (`docs/screens/P08/FIXES_1.md:622`),
fixed there by rendering a fixed, kind string while the raw message stays in
state for logs/tests. Severity mirrors B15 (minor) — error path only, off-design.

**Fix:** render a fixed line, e.g. "We couldn't load the approvals. Your data is
safe — please try again."; assert `state.errorMessage` in bloc tests (already
done in `approvals_bloc_test.dart:105-109`, `:160-171`) rather than on the
widget.

### 3. minor — hand-rolled error SnackBar instead of the shared toast

- `app/lib/features/approvals/presentation/views/approvals_view.dart:39-49`

The design system already owns this: `showNestToast` / `NestToast`
(`app/lib/core/design_system/components/nest_toast.dart:39`), used by
`kid_home_view.dart:201`, `money_ledger_view.dart:74`, `paywall_view.dart:69`.
The P11 version (a) invents a style that exists nowhere in the design system
(`backgroundColor: tokens.danger` + `NestType.bodySmall(onLeaf)` — contrast is
fine, 5.0:1 light / fine dark, this is not a contrast bug), (b) drops
`Semantics(liveRegion: true)`, so an alert is not announced to VoiceOver, and
(c) with `SnackBarBehavior.floating` and **no margin** it renders at the very
bottom of the Scaffold — i.e. on top of / behind the `NestBottomCta` panel.
`showNestToast` sets `margin: … homeH + s4` precisely to clear that bar.

**Fix:** replace the block with `showNestToast(context, message)`.

### 4. minor — stale comment contradicting the fixed repository code

- `app/test/features/approvals/approvals_view_test.dart:289-293`

The comment still states "`ApprovalsRepositoryImpl.approveAll` awaits
`watchItems().first` … so the real button can be exercised only here". Iteration
1 replaced that with a one-shot `select().get()` (`approvals_repository_impl.dart:113-128`)
precisely because the stream form hung under fake async, so the real CTA *is*
now drivable end to end (`approvals_view_test.dart:235-253` proves it). The test
itself is fine — it wants a gated stub.

**Fix:** rewrite the comment to "gated stub so the in-flight state can be
asserted" and drop the fake-async claim.

### 5. minor — `Today`/`Yesterday` can be off by one day across a DST transition in the device's local zone

- `app/lib/features/approvals/presentation/widgets/approval_time.dart:36-38`

```dart
final createdDay = DateTime(created.year, created.month, created.day); // LOCAL zone
final today     = DateTime(now.year, now.month, now.day);             // LOCAL zone
final daysApart = today.difference(createdDay).inDays;                // 23h → 0
```

`DateTime(y, m, d)` without `isUtc` builds a value in the **device's local**
zone, so the subtraction is an elapsed duration, not a calendar-day count. In
zones whose DST change lands on midnight (America/Santiago, Asia/Beirut, …) the
gap is 23 h or 25 h, `.inDays` truncates, and a completion is labelled `Today`
after local midnight or `Yesterday` on its own day. The in-code comment
("differ by whole days, which keeps the test correct across a DST change") is
true only for zones that never transition at midnight. Europe/London — the
family default — is unaffected, so this is robustness, not a live bug.

**Fix:** compare zone-free calendar keys, e.g.
`final a = DateTime.utc(created.year, created.month, created.day);` (same for
`now`), or `today.difference(createdDay).inDays` on the `yyyyMMdd` integers.

### 6. minor — `approvalInitial` splits grapheme clusters

- `app/lib/features/approvals/presentation/widgets/approval_card.dart:40-44`

`trimmed.substring(0, 1)` takes the first UTF-16 code unit. Nicknames are
parent-entered, so a name starting with an emoji, a combining accent or a
surrogate pair yields half a character (or a replacement glyph) in the avatar.
The empty/blank guard is right; only the slicing is wrong.

**Fix:** `trimmed.characters.first.toUpperCase()` (`package:characters` ships
with Flutter) — same result for ASCII, correct for everything else.

### 7. minor — `approveAll()` re-implements the pending predicate in raw Drift

- `app/lib/features/approvals/data/approvals_repository_impl.dart:118-124`

`familyId == Seed.familyId & status == 'done_pending'` is now written twice: once
in `AppDatabase.watchPendingApprovals` (`core/data/app_database.dart:521-530`)
and once here. If core's definition of "pending" ever widens (e.g. a new status),
Approve all would silently drain a different set than the inbox shows. The fix
in iteration 1 (one-shot `get()` instead of `watchItems().first`) was right and
necessary, but it introduced the duplicate.

**Fix:** add `Future<List<QuestCompletion>> selectPendingApprovals(String familyId)`
next to `watchPendingApprovals` in core and have both call it — that is a
**shared** file, so raise it in `SHARED_REQUEST.md` rather than editing it here.

### 8. minor (doc, stage-5 relevant) — the geometry test misattributes its baselines to the PNG

- `app/test/features/approvals/approvals_view_geometry_test.dart:12-14` and
  `:112` (`const expectedTops = <double>[187, 341, 495];`)

I measured `design/screens/light/P11-approvals.png` directly (÷3, centre column
x=195): helper banner **107–171**, card 1 **187–359**, card 2 **375–547**, card 3
**563–~735** (clipped by the CTA at 718), CTA button **734–786**, paper strip
810–844. So the design card height is **172**, not 138, and the real design card
tops are **187 / 375 / 563** — not 187/341/495. The pinned app values are correct
for the quote-less card; the header comment's claim that they were "measured off
the PNG row/column profile" is wrong, and stage 5 will read it as a licence to
expect 341/495 from the app screenshot.

Cause is the accepted `.qn` deviation (finding note below): the design's quote
row is 10 + 24 = 34 px.

**Fix (doc only):** correct the header comment to "design 187/375/563 minus the
34 px quote block per omitted card".

---

## Accepted deviation (not a finding — do not "fix")

**The design's `.qn` quote rows are not rendered.** `quest_completions` has no
child-message column, so any quote would be hard-coded mock data (DATA OVER
MOCKS), and DESIGN_SPEC §5 P11 does not list quotes among the card contents.
`SHARED_REQUEST.md` §1 asks for `note TEXT DEFAULT ''` + seed values.
Consequence to accept downstream: app card height **138** vs design **172**.

## Verified correct (no finding)

| Area | Evidence |
|---|---|
| Architecture | Feature-first; `domain/` = entity + abstract repo only; one bloc; DI + routes untouched (they already used `registerFactory`, so every push gets a fresh bloc — no closed-bloc reuse); `/approvals` stays top-level outside the shell, no `NestTabBar`. |
| DESIGN_SPEC §5 P11 | nav back → `/today`; `Waiting for you (N)` and `Approve all (N)` are **DB-driven**, not the designs' `(3)`; `Not yet` (secondary) + `Approve` (primary), equal width; helper line present. UK spelling throughout. |
| Copy, character-by-character | `'“Not yet” sends a kind note — no coins are taken away.'` matches the HTML with U+201C/U+201D/em dash U+2014 (exported as `approvalsHelperCopy`, asserted in `approvals_view_test.dart:112-126`); card line uses `·` (U+00B7) with single spaces; back label `Back to Today` = the HTML `aria-label`. |
| Design-system reuse | `NestStatusBar/NestNavBar(compact)/NestCard/NestAvatar/NestButton×3/NestBottomCta/NestEmptyState`; `0` `Color(0x…)`, `0` `Colors.*`, `0` hard-coded paddings. The only literals are the design CSS's own sizes: `fontSize: 14` (`.helper`), `fontSize: 15` (`.appr .row .btn`), `minHeight: 48` — all named in `NestButton`'s own doc comment as the P11 call. Radii/typography/spacing all via `NestRadii`/`NestType`/`NestSpacing`. |
| Typography | `.who` = `bodyStrong.copyWith(height: 22/16)`; `.tm` = `caption` + w700/tnum money span; `.helper` = `body.copyWith(fontSize: 14, height: 20/14)`. Letter-spacing untouched (NestType defaults 0; P11 CSS sets none). No `text-wrap: balance` in P11 → no `NestBalancedText` needed. |
| Fonts / Pip / chips | `0` hits for `google_fonts` / `GoogleFonts` in the feature and its tests; no Pip on this screen (initial avatars only, asserted); no chip rows → `NestChipWrap` N/A; no `subscription_status` write. |
| Bottom edge | `NestBottomCta` paints `surface` to the physical edge and is removed when the inbox empties (no bar over the empty state) — asserted `cta.bottom == screen.bottom` and the fill `== tokens.surface` (`approvals_view_test.dart:180-204`). |
| Data over mocks | Nothing hard-coded: rows come from `watchPendingApprovals`, sorted newest-first in the bloc on a **copy** (`approvals_bloc.dart:29-33`); `busyIds`/`approveAllBusy` survive stream emissions; counts follow the DB after each write. |
| Accessibility | Back, both row buttons, CTA and Try again each expose `SemanticsAction.tap`, and `performAction(tap)` is proven to change **real** state/DB (`approvals_view_test.dart:330-484`); the `excludeSemantics: true` wrapper on `.hd` contains no interactive child (buttons sit outside it) and needs no `onTap` — per RULES §8 and the brief's rule; card summary label proven not to swallow the button labels (`approval_card_widget_test.dart:310-335`). |
| Performance | `BlocBuilder` rebuilds 4 chrome children + a lazy `ListView.builder`; `const` where possible; `NestButton` owns/disposes its `FocusNode`; the `emit.forEach` subscription is cancelled by the bloc on close (bloc 9 `Emitter.cancel`), and events are concurrent by default so the long-lived `forEach` handler never blocks approve/not-yet. |
| Error handling | `ApprovalsActionErrorConsumed` + `listenWhen` shows each failure once (same message twice in a row still fires, because the field is cleared in between); `emit` after close is a no-op in bloc 9, so a pop mid-write cannot throw. |
| Children's Code | `/approvals` is in the router's `parentOnly` list, so kid mode is redirected to the parental gate; no analytics, ads, network calls or child-data logging in the diff; nicknames render locally only. |
| Tests | 57 approvals tests pass (`flutter test test/features/approvals`); real-DB repository tests for approve / not-yet / approveAll incl. ledger side effects and no-op on unknown id; DST + noon/midnight + moved-family + unknown-zone cases for the time helper; 320 px @ text-scale 1.3 with no overflow. |

## Gates re-run in this worktree

```
$ dart format --output=none --set-exit-if-changed .
Formatted 464 files (0 changed) in 1.25 seconds.          → clean

$ flutter analyze
No issues found! (ran in 3.4s)                              → clean, no ignores

$ flutter test test/features/approvals
00:01 +57: All tests passed!
```

No simulator was booted, installed on, or driven in this stage.

## Stage 5 handoff (measure against these, not the values in the test header)

| Element | Design (measured off the light PNG ÷3) | App expectation | Delta |
|---|---|---|---|
| Helper banner | 107–171 (h 64) | 107–171 | 0 |
| Card 1 top / height | 187 / 172 | 187 / 138 | 0 / −34 (quote row) |
| Card 2 top | 375 | 341 | **−34 (accepted)** |
| Card 3 top | 563 | 495 | **−68 (accepted)** |
| Card 1 avatar / row buttons | avatar 203–247 at x 36; pills 295–343 (48 high), gap 10 | same rects | 0 |
| CTA pill | 734–786 | 776–828 with no bottom inset; 760–812 with a 34 px home-indicator inset | **owner bottom-edge override** — the design's 810–844 paper strip must be surface, so the pill sits lower than the PNG on purpose |
| Card 3 → CTA | design clips card 3 at the CTA (718) | app leaves a paper gap (card 3 ends 633) | consequence of the quote deviation |

Report the measured y of the title, the first control and each card top, design
vs app, as the UI VERDICT RULE requires — the two −34/−68 card-top deltas are the
documented `.qn` deviation (accepted, `SHARED_REQUEST.md` §1), not a layout
regression, and the CTA shift is the owner bottom-edge ruling.
VERDICT: PASS
