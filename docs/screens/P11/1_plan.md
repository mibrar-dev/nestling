# P11 · Approvals — build plan (Stage 1)

Route `/approvals` (parent mode, pushed top-level — NOT inside the tab shell, so no
`NestTabBar`). Sources: `design/html-source/screens/P11-approvals.html`,
`design/screens/light|dark/P11-approvals.png` (1170×2532 @3x, ÷3 = logical px),
DESIGN_SPEC §5 P11, SPACING_SPEC §§1–2/8–10. Canvas 390×844.

## 0. Data reality (DATA OVER MOCKS — builder must follow this, not the PNG numbers)

Seeded pending approvals (`Seed.demo`, pinned to Sat 3 Oct 2026 in tests) are 3 rows,
all created TODAY in Europe/London, from `watchPendingApprovals` (createdAt ASC):

| # | quest | child | coins | created UTC | London wall | design shows |
|---|---|---|---|---|---|---|
| 1 | Empty the dishwasher (`q-dishwasher`) | Maya | 15 | 07:12 | Today 8:12am | same |
| 2 | Lay the table (`q-table`) | Maya | 10 | 07:05 | Today 8:05am | design shows “Leo · Make your bed” here |
| 3 | Make your bed (`q-bed`) | Leo | 5 | 06:58 | Today 7:58am | same |

Consequences:
- Render whatever `watchItems()` returns. NEVER hard-code the design's rows
  (“Tidy your bedroom”, “Yesterday 5:40pm” are mock content — the DB has neither).
- The `.qn` quote lines (“I stacked everything neatly!” etc.) have NO data source:
  `quest_completions` has no message/note column (only id/questId/childId/familyId/
  status/coins/createdAt(+Tz)/decidedAt(+Tz)). Cards therefore render WITHOUT the
  quote row (documented deviation; hard-coding design quotes would be mock data).
  A non-blocking SHARED_REQUEST (§g) covers this.
- No Pip appears on this screen (initial avatars only) — no `PipAvatar` needed.
- Status-bar pixels are ignored (`NestStatusBar` reserves height only).

## 1. Widget tree, top → bottom (exact components + spacing, logical px)

`ApprovalsView` = `Scaffold(backgroundColor: tokens.paper)` with NO `AppBar`:

```
Scaffold (paper bg)
└── Column (no tab bar; route is top-level — router.dart:152 spreads
    approvalsRoutes OUTSIDE the StatefulShellRoute)
    ├── NestStatusBar()                                  // reserves 47
    ├── NestNavBar(
    │     compact: true,                                // min-h 52, padding 4/12/12 → 60 rendered
    │     title: 'Waiting for you (N)',                 // N = items.length, dynamic
    │     onBack: pop-or-today, backSemanticLabel: 'Back to Today')
    │     // trailing: 44px empty spacer (NestNavBar compact default)
    ├── Expanded(
    │   └── ListView (padding: L/R NestSpacing.padSide=20, bottom 16 — P11
    │       override of the 32 base, per .scroll{padding-bottom:16px};
    │       separators SizedBox(height: 16))
    │       ├── helper banner (index 0, only when items non-empty):
    │       │   Container(decoration: leafTint bg, NestRadii.allM=16,
    │       │     padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    │       │     child: Text(
    │       │       '\u201cNot yet\u201d sends a kind note \u2014 no coins are taken away.',
    │       │       // exact codepoints: U+201C U+201D, em dash U+2014
    │       │       style: NestType.body(color: leafInk).copyWith(fontSize: 14, height: 20/14)))
    │       │   // body() is 16/24 w400 Inter; the 14/20 override carries the
    │       │   // design value (same copyWith-value precedent as today line 582).
    │       ├── ApprovalCard × N (SizedBox 16 between each):
    │       │   NestCard(variant: standard)              // surface, r-l 24, sh-1, padding 16
    │       │   └── Column(crossAxisAlignment: start, mainAxisSize: min)
    │       │       ├── Row(gap 10, crossAxisAlignment: center)
    │       │       │   ├── NestAvatar(initial: 'M'/'L' = childName[0].toUpperCase(),
    │       │       │   │     size: s44, color: lilac→lilac/peach→peach/sky→sky/
    │       │       │   │     leaf→leaf/coin→coin else neutral;
    │       │       │   │     copy the avatarColorFor switch from
    │       │       │   │     today_loaded_body.dart:187 into a feature-private
    │       │       │   │     top-level function in approval_card.dart)
    │       │       │   └── Expanded(Column(start, min):
    │       │       │         ├── Text('$childName · $questTitle',
    │       │       │         │     // middle dot U+00B7 with spaces, exactly as HTML
    │       │       │         │     style: NestType.bodyStrong(color: ink)
    │       │       │         │       .copyWith(height: 22/16),
    │       │       │         │     // .who inline style 16/22 w700 Inter
    │       │       │         │     maxLines: 1, overflow: ellipsis, softWrap: false)
    │       │       │         └── Padding(padding-top: 2, child: Text.rich(
    │       │       │               TextSpan(children: [
    │       │       │                 TextSpan(text: '$dayLabel $timeLabel · '),
    │       │       │                 // e.g. 'Today 8:12am · ' (see §3 time rule)
    │       │       │                 TextSpan(text: '$coins coins',
    │       │       │                   style: caption.copyWith(fontWeight: w700,
    │       │       │                     fontFeatures: [FontFeature.tabularFigures()])),
    │       │       │                 // .tm 13/18 ink-2; .money span adds w700+tnum
    │       │       │               ]),
    │       │       │               style: NestType.caption(color: ink2),
    │       │       │               maxLines: 1, overflow: ellipsis, softWrap: false)))
    │       │       ├── SizedBox(height: 14)            // .row margin-top:14
    │       │       └── Row(gap: 10):                   // NOT 12 — .appr .row gap:10
    │       │           ├── Expanded(NestButton.secondary label 'Not yet',
    │       │           │     minHeight: 48, fontSize: 15, horizontalPadding: 12,
    │       │           │     onPressed: null while this id ∈ busyIds else add NotYet;
    │       │           │     loading: true only if THIS button was tapped)
    │       │           └── Expanded(NestButton.primary label 'Approve', same
    │       │               geometry, adds ApprovalsApproveRequested(id))
    │       └── (empty case) Center(NestEmptyState(  // new copy, no design art:
    │             title: 'All caught up',
    │             message: 'When your children finish a quest, it will appear '
    │               'here for your thumbs-up.'))
    └── NestBottomCta (only when items non-empty; surface runs to the physical
        edge per the component — satisfies the OWNER bottom-edge rule)
        └── NestButton.primary('Approve all (N)', minHeight: 52,
              onPressed: null while approveAllBusy else ApproveAllRequested,
              loading: approveAllBusy)
```

Semantics (ACCESSIBILITY ACTIONS compliant): the non-interactive `.hd` block
(avatar + name + time) is wrapped in `Semantics(container: true,
excludeSemantics: true, label: '$childName, $questTitle, $dayLabel $timeLabel,
$coins coins')` — one announcement for the row content. The wrapper contains NO
interactive elements (the two buttons sit OUTSIDE it in the card Column), so no
`onTap` is required on it, and each button keeps its own focusable/tappable node
with a real `SemanticsAction.tap` (NestButton). Never wrap the whole card
(including buttons) in `excludeSemantics` — that would hide the buttons'
tap actions. Tests must assert `hasAction(SemanticsAction.tap)` for back,
Not yet, Approve, Approve-all and Try-again, and that `performAction(tap)`
changes the real DB/state.
Loading: `Center(CircularProgressIndicator(color: tokens.leaf))` (today pattern).
Failure: centered `Text(errorMessage)` + `NestButton.secondary('Try again')`
→ adds `ApprovalsLoadRequested`.
Action errors (approve/not-yet/approve-all throws): emit `actionError`; view
shows `SnackBar(content: Text(actionError), backgroundColor: tokens.danger)`
via ScaffoldMessenger on state change (BlocListener, fire once per non-null
value then bloc clears it with `ApprovalsActionErrorConsumed`). Not in the
design — error path only.

Letter-spacing: add NOTHING (design CSS sets none; NestType defaults 0).
No `text-wrap: balance` anywhere in P11 CSS → no `NestBalancedText`.
No chip rows → no `NestChipWrap`. No `google_fonts` anywhere.

Expected-y positions (logical px, from CSS box model — UI check must verify
each within ±2 px; a uniform vertical shift is a FAIL):
status-bar 0–47 · nav compact 47–107 (4 + 44 + 12) · helper banner top 107,
height 64 (12 + 2×20 + 12) → 107–171 · gap 16 → card 1 top 187, height 138
(16 + 44 + 14 + 48 + 16) → 187–325 · gap 16 → card 2 top 341 → 341–479 ·
gap 16 → card 3 top 495 → 495–633 · scroll bottom padding 16 ·
bottom-cta (surface to physical edge): 16 + 52 + 16 = 84 + safe-area inset.
NOTE: card height 138 EXCLUDES the design's `.qn` quote row (omitted per §0 —
no data source), so design-PNG card bottoms will differ by exactly the quote
block (~10 + 24); tops and all other rects must still match ±2 px.

## 2. BLoC + repository

Repository (exists, Drift-backed — NO changes needed except none; keep
`getItems/watchItems/approve/markNotYet/approveAll` as-is):
- `watchItems()` streams `done_pending` completions oldest-first.
- `approve(id)` → status `approved` + `quest_bonus` ledger row (coins → jar).
- `markNotYet(id)` → status `not_yet`, no coins move.
- `approveAll()` → approve each pending.

Entity change (allowed: `domain/**`): add `createdAtTz` to `Approval`
(required `String createdAtTz`, default `'Europe/London'` NOT allowed on const
equatable — make it required and update `ApprovalModel.fromJson/toJson` +
existing constructor call sites; only the repo constructs it). Populate from
`QuestCompletion.createdAtTz` in `ApprovalsRepositoryImpl.watchItems`
(currently dropped — the view needs it for zone-correct labels). Keep the
`detail` field untouched (still populated; view does not use it).

Bloc (`approvals_bloc.dart`, same `emit.forEach` stream pattern):
- Events: `ApprovalsLoadRequested` (exists),
  `ApprovalsApproveRequested(completionId: int)`,
  `ApprovalsNotYetRequested(completionId: int)`,
  `ApprovalsApproveAllRequested()`, `ApprovalsActionErrorConsumed()`.
- State: add `busyIds: Set<int> = const {}` (default `const <int>{}`),
  `approveAllBusy: bool = false`, `actionError: String? = null`.
  In `onData` of the items stream: sort a COPY `createdAt` descending (newest
  first — matches design order; foundation stream order is oldest-first and
  lives in shared core code we must not touch), preserve `busyIds`/`approveAllBusy`,
  clear nothing else.
- `_onApprove`: `busyIds + {id}` → `await repository.approve(id)` (row vanishes
  via the stream) → remove id in finally; on throw: remove id + set actionError.
- `_onNotYet`: same with `repository.markNotYet(id)`.
- `_onApproveAll`: `approveAllBusy = true` → `await repository.approveAll()` →
  false in finally; on throw set actionError. (Stream emits empty → empty state.)
- No re-added load events (RULES §4).

## 3. Interactions + navigation

| Element | Action | Destination / effect |
|---|---|---|
| Nav back chevron | tap | `context.canPop() ? context.pop() : context.go('/today')` (returns to Today, which pushed here via `Review` → `context.push(ApprovalsRoutePaths.approvals)`). Literal `'/today'` = `TodayRoutePaths.today`; do NOT import today's routes file (keep the feature decoupled — one literal with this comment). |
| Not yet (per card) | tap | `ApprovalsNotYetRequested(id)`; card leaves the inbox via stream; kind note is implicit (no coins move — helper banner says so) |
| Approve (per card) | tap | `ApprovalsApproveRequested(id)`; ledger `quest_bonus` written; card leaves inbox |
| Approve all (N) | tap | `ApprovalsApproveAllRequested()`; inbox → empty state |
| Try again (failure) | tap | `ApprovalsLoadRequested()` |

Time labels (feature-private pure function `approvalDayLabel` in new
`presentation/widgets/approval_time.dart`, unit-testable):
```dart
String approvalDayLabel({required DateTime createdAtUtc, required String storedZoneId, required DateTime nowUtc, String? familyZoneId});
String approvalTimeLabel({required DateTime createdAtUtc, required String storedZoneId, String? familyZoneId}); // formatTime wrapper
```
Day rule (all evaluated with `family_time.dart`): local-day equality in the
STORED zone via `toFamilyZone`: same day → `Today`; one day before → `Yesterday`;
else `formatDay(utc, storedZoneId, familyZoneId: familyZoneId)`. Time part is
`formatTime` (`8:12am` style). Repository streams the CURRENT family zone id
(`watchFamilyZoneId`) — extend the `combineLatest4` mapping to pass it through?
Simpler: view reads family zone via existing `watchFamilyZoneId`? That adds a
second stream to the bloc. DECISION: bloc subscribes to the existing items stream
only; the time helper takes `familyZoneId: null` (stored-zone rendering, which is
correct while the family hasn't moved zones) — document, no extra stream.

## 4. Empty / loading / error states

- Loading/initial: centered leaf spinner (above).
- Loaded + empty: `NestEmptyState` “All caught up” (above; also the post-approve-all landing).
- Failure: message + Try again (above). Action errors: SnackBar (above).
- Seed `empty()` (no children) → items empty → same empty state (title/message are
  child-agnostic, so no special-casing).

## 5. Accessibility

- Tap targets: nav back 44, card buttons 48 high (≥44 parent minimum ✓), bottom
  CTA 52, Try again 52. No 32px chips on this screen.
- Semantics labels: back “Back to Today”; per-card container label (§1); buttons
  keep their text labels; busy buttons expose `enabled: false` + loading spinner.
- Text scale 1.3 + width 320: title + tm lines `maxLines: 1, ellipsis,
  softWrap: false`; button labels short (“Not yet”/“Approve”) fit 119px cells at
  320 (content 280 − card padding 32 − gap 10 = 119 each); helper text wraps
  (no maxLines). Verify in tests at `textScaler 1.3`, 320×844.
- Contrast: leaf-ink on leaf-tint, ink-2 on paper/surface, on-leaf on leaf —
  all design-system pairs, both themes (dark verified against dark PNG).

## 6. Test plan (new dir `app/test/features/approvals/`; no `google_fonts`
imports; every pumped-app test ends with `disposeApp(tester)`)

1. `approvals_repository_test.dart` (real in-memory DB via `setUpTestScope`,
   pinned Sat 3 Oct 2026): `watchItems` emits exactly 3 pending with
   questTitles {Empty the dishwasher, Lay the table, Make your bed},
   children {Maya, Maya, Leo} (creation order), coins {15, 10, 5};
   `approve()` removes the row from pending AND inserts a `quest_bonus` ledger
   entry with matching pence + quest note; `markNotYet()` removes from pending
   with status `not_yet` and writes NO ledger row; `approveAll()` drains all 3
   (ledger gains 3 bonus rows totalling 30p).
2. `approvals_bloc_test.dart` (`bloc_test` + mocktail repo): load →
   `[loading, loaded(3 sorted newest-first: dishwasher, table, bed)]`;
   approve event calls `repository.approve(id)` and toggles `busyIds`;
   repository throw → `actionError` set, busy cleared.
3. `approval_time_test.dart`: pure helper — 07:12 UTC Oct 3 → `Today`;
   Oct 2 16:40 UTC → `Yesterday`; Sep 21 → `Sun 21 Sep`; time `8:12am`,
   `7:58am`, `12:05pm` noon edge, `12:00am` midnight edge.
4. `approvals_view_test.dart` (`pumpAppRoute('/approvals')`, light + dark):
   title `Waiting for you (3)`; helper copy byte-exact incl. `“ ” —`;
   three cards with `Maya · Empty the dishwasher / Today 8:12am / 15 coins`
   (DB values, NOT design mocks); tapping first `Approve` removes its card
   (title becomes `(2)`); `Approve all (2)` → empty state `All caught up`;
   back chevron returns to `/today` (`currentPath`); 320-wide + textScaler 1.3
   pumps without overflow exceptions; no `Timer still pending` (disposeApp).

## 7. Files to touch + SHARED_REQUEST

Touch ONLY (RULES §1):
- `app/lib/features/approvals/presentation/views/approvals_view.dart` (rewrite)
- `app/lib/features/approvals/presentation/widgets/approvals_loaded_body.dart` (new)
- `app/lib/features/approvals/presentation/widgets/approval_card.dart` (new)
- `app/lib/features/approvals/presentation/widgets/approval_time.dart` (new)
- `app/lib/features/approvals/presentation/bloc/approvals_{event,state,bloc}.dart` (extend)
- `app/lib/features/approvals/domain/entities/approval.dart` + `data/models/approval_model.dart` (add `createdAtTz`)
- `app/lib/features/approvals/data/approvals_repository_impl.dart` (populate `createdAtTz`; sort stays in bloc)
- DELETE `presentation/widgets/approvals_placeholder_card.dart` (placeholder, unused)
- `app/test/features/approvals/**` (4 new files above)
- `docs/screens/P11/**` (this plan + later stage notes)

SHARED_REQUEST (non-blocking — build lands without it): file
`docs/screens/P11/SHARED_REQUEST.md` — “P11 quote rows have no data source:
`quest_completions` carries no child message column, so the design's `.qn`
quote lines are omitted; if the owners want them, add `note TEXT DEFAULT ''`
to `quest_completions` (+ seed values) and P11 will render it. Blocks: no.”

VERDICT: PASS
