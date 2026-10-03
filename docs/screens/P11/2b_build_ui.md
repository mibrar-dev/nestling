# P11 · Approvals — Stage 2b build UI (iteration 1)

UI layer only: `presentation/views/**`, `presentation/widgets/**`, and the
view/widget tests. Re-read `2a_build_logic.md` before finishing — **CONTRACT
CHANGES: none**, so the bloc surface used here is exactly `1_plan.md` §2.

## Files written

- `app/lib/features/approvals/presentation/views/approvals_view.dart`
  (rewrite — was the `AppBar` placeholder)
- `app/lib/features/approvals/presentation/widgets/approvals_loaded_body.dart`
  (new)
- `app/lib/features/approvals/presentation/widgets/approval_card.dart` (new)
- `app/lib/features/approvals/presentation/widgets/approval_time.dart` (new)
- DELETED `presentation/widgets/approvals_placeholder_card.dart` (plan §7;
  unreferenced)
- `app/test/features/approvals/approvals_view_test.dart` (new, 11 tests)
- `app/test/features/approvals/approval_card_widget_test.dart` (new, 16 tests)

Nothing outside `presentation/views`, `presentation/widgets`,
`test/features/approvals` and `docs/screens/P11` was touched. No bloc, entity,
model or repository edit.

## Layout, component by component (per `1_plan.md` §1 + the HTML source)

```
Scaffold(backgroundColor: tokens.paper)          no AppBar, no NestTabBar
└ BlocListener<ApprovalsBloc>                     actionError → SnackBar once
  └ BlocBuilder → Column
    ├ NestStatusBar()                             47 reserved (OS draws glyphs)
    ├ NestNavBar(compact, 'Waiting for you (N)',  52 min + 4/12/12 padding
    │   onBack: pop-or-go('/today'), 'Back to Today')
    ├ Expanded
    │  ├ initial/loading  Center(CircularProgressIndicator(leaf))
    │  ├ failure         Text + NestButton.secondary('Try again')
    │  └ loaded          ApprovalsLoadedBody
    │      ListView(padding: 20 / 20 / 16 — P11 override of the 32 base)
    │        index 0  ApprovalsHelperBanner  (leaf-tint, r-m 16, pad 12/14, 14/20)
    │        index 1+ ApprovalCard, `EdgeInsets.only(top: 16)` between each
    └ NestBottomCta  (only when items.isNotEmpty)
        NestButton.primary('Approve all (N)')
```

Card (HTML `.appr` → `NestCard` standard: surface, r-l 24, sh-1, pad 16):

| HTML | Flutter |
|---|---|
| `.hd` flex row gap 10 | `Row(spacing: gap10)` |
| `.avatar.s44.a-lilac` | `NestAvatar(size: s44)` + feature-private `approvalAvatarColor()` (switch copied from P08's `today_loaded_body.dart`, which is private to that feature) |
| `.who` 16/22 w700 truncate | `NestType.bodyStrong(ink).copyWith(height: 22/16)`, `maxLines: 1`, `softWrap: false` |
| `.tm` 13/18 ink-2, margin-top 2 | `Padding(top: gap2)` + `Text.rich` |
| `.money` w700 + tnum | second `TextSpan` with `fontWeight: w700`, `FontFeature.tabularFigures()` |
| `.row` gap 10, margin-top 14 | `SizedBox(gap14)` + `Row(spacing: gap10)`, two `Expanded` |
| `.row .btn` min-h 48 / 15 / pad 12 | `NestButton(minHeight: 48, fontSize: 15, horizontalPadding: s3)` |
| `.bottom-cta .btn` min-h 52 | `NestButton` default 52 |

`gap10`/`gap14` come from `NestSpacing` (tokens only — no literals). Colours
are `context.nest.*` only; no hex anywhere in the feature.

## Owner / orchestrator rules applied

- **DATA OVER MOCKS** — the card renders whatever `state.items` holds. The
  design's `Tidy your bedroom` / `Yesterday 5:40pm` rows are NOT hard-coded;
  the view test asserts the seeded rows instead
  (`Maya · Empty the dishwasher / Today 8:12am / 15 coins`,
  `Maya · Lay the table / Today 8:05am / 10 coins`,
  `Leo · Make your bed / Today 7:58am / 5 coins`).
- **BOTTOM EDGE** — `NestBottomCta` paints `surface` to the physical edge and
  is removed entirely when the inbox empties, so there is no coloured strip
  under a bar or around the home indicator in either theme. Covered by
  `bottom CTA surface runs to the physical screen edge`, which asserts
  `cta.left == screen.left`, `cta.right == screen.right`,
  `cta.bottom == screen.bottom` and the bar's own fill == `tokens.surface`.
- **ALIGNMENT** — 20px side gutters on the list and on the CTA (both
  `NestSpacing.padSide`); cards, banner and CTA share the same edges.
- **CHILD ORDER** — nothing to sort here: the bloc already emits newest-first
  (dishwasher, table, bed), and the children come out of `watchChildren` in
  creation order.
- **COPY** — helper banner is byte-exact from the HTML: `“Not yet” sends a
  kind note — no coins are taken away.` (U+201C / U+201D / em dash U+2014),
  asserted against the exported `approvalsHelperCopy` and against explicit
  “no straight quote / no double hyphen” checks. Card copy uses U+00B7 with
  single spaces (`Maya · Empty the dishwasher`, `Today 8:12am · 15 coins`).
- **LETTER SPACING** — nothing added. P11's CSS sets no `letter-spacing`;
  `NestType` already defaults to 0, so no `copyWith(letterSpacing:)` and no
  screen-wide tracking override is needed (unlike P04).
- **PIP** — no `PipAvatar` on this screen: the design shows initial avatars
  only (`M` / `L`), and no Pip appears in the PNGs. Asserted by
  `no Pip renders on this screen (initials only)`.
- **STATUS BAR** — `NestStatusBar()` only; glyph differences ignored.
- **BALANCED HEADINGS / CHIP ROWS / TRIAL / FONTS** — none apply: P11's CSS
  has no `text-wrap: balance`, no chips, no subscription state, and no
  `google_fonts` import anywhere in the feature or its tests.
- **UI CHECK MEASURES SHAPES** — the view tests assert `BoxDecoration`s, not
  just text: the banner is a `leafTint` box with `NestRadii.allM`, and there
  are exactly three `surface` boxes with `NestRadii.allL` (one per card), in
  light and dark. The card test measures the two pills: height 48, equal
  widths, exactly a 10px gap, and the label centred inside its pill.

## Owner-rule deviations from the plan text (both intentional)

1. **Card semantics scope.** `1_plan.md` §1 says wrap the whole card in
   `Semantics(container: true, label: …)` *without* `excludeSemantics`. Done
   literally, Flutter merges the child `Text` nodes into that container
   (verified by dumping the semantics tree), so the announcement becomes
   `Maya, … 15 coins / Maya · Empty the dishwasher / Today 8:12am · 15
   coins` — a duplicated read. The label now wraps only the `.hd` block with
   `excludeSemantics: true`; the button row sits outside it, so both buttons
   keep their own focusable node. Result: one clean row announcement + two
   button nodes, which is what the plan was trying to achieve.
2. **List separators.** `.scroll > * + * { margin-top: 16 }` is a CSS margin
   collapse, which `ListView.builder` has no equivalent for (SPACING_SPEC §10.5:
   use explicit separators). The loaded body therefore renders every item
   after the banner with `EdgeInsets.only(top: 16)` rather than a
   `ListView.separated`, so the banner stays flush with the scroll's 0 top
   padding and every gap is exactly 16 — asserted in both the view and the
   loaded-body tests.

## Notable implementation decisions

- **Time labels** (`approval_time.dart`): `approvalDayLabel` converts both
  instants into the **stored** zone (`createdAtTz`) before comparing
  wall-clock calendar days, so `Today` rolls over at the family's midnight,
  not UTC's. `approvalTimeLabel` delegates to `formatTime`, keeping the
  noon/midnight edges in one place. `familyZoneId` is an optional pass-through
  (plan §3: the bloc does not stream it) — when supplied and different from
  the stored zone, `formatDay`/`formatTime` name the zone.
- **Navigation** — `onBack` is `context.canPop() ? context.pop() : context.go('/today')`
  with `'/today'` inlined and a comment (the plan forbids importing today's
  routes file). The view test asserts `pushedPath` goes `/approvals` →
  `/today`.
- **Busy state** — `busyIds.contains(id)` disables AND spins both buttons on
  that card only, so a second tap cannot double-write. `approveAllBusy` does
  the same for the CTA.
- **Action errors** — `BlocListener` with `listenWhen` on a changed non-null
  `actionError`, one SnackBar per value (`tokens.danger` background), then
  `ApprovalsActionErrorConsumed()` so a rebuild cannot re-fire it. Not in the
  design; error path only.
- **Empty state** — `NestEmptyState(title: 'All caught up', message: …)` with
  no artwork (P11 has no empty-state design, and inventing art would need a
  shared asset).

## Tests (mine)

`app/test/features/approvals/approvals_view_test.dart` — 11 tests, all via
`pumpAppRoute('/approvals')` over the seeded in-memory DB, light + dark:
title/helper/three cards, character-exact copy, shape assertions in both
themes, bottom-edge assertion, per-card approve, per-card "Not yet", draining
the inbox to `All caught up`, back → `/today`, 320px @ textScale 1.3, and the
CTA busy lock. Every test ends with `disposeApp(tester)`.

`app/test/features/approvals/approval_card_widget_test.dart` — 16 tests:
`approvalDayLabel` (`Today` / `Yesterday` / `Mon 21 Sep` / London-vs-UTC
midnight boundary / Dubai already-next-day / unknown-zone fallback),
`approvalTimeLabel` (`8:12am`, `7:58am`, `12:05pm`, `12:00am`, `5:40pm`),
`approvalAvatarColor`, and the card itself (initial + name·quest + time·coins
+ both labels, 48-high equal pills 10px apart, busy swallows taps, one
semantics node + two button nodes, no Pip, 320px @ 1.3), plus the loaded
body's 16px rhythm and its empty state.

Plan §6.3 asked for `approval_time_test.dart`; that name contains neither
`view` nor `widget`, so the time coverage lives in
`approval_card_widget_test.dart` rather than colliding with the logic
builder's file set.

**Verification run**
- `dart format` clean.
- `flutter analyze lib/features/approvals test/features/approvals` →
  **No issues found!** (no ignores, no suppressions added).
- `flutter test test/features/approvals` → **45/45 pass** (my 27 + the logic
  builder's 18). Whole-app `flutter test` and simulators left to the
  integrator, per the stage rules; no simulator was booted.

## Finding for the integrator / logic builder (non-blocking)

`ApprovalsRepositoryImpl.approveAll()` starts with `await watchItems().first`.
Under `testWidgets`' fake-async zone a Drift query stream never delivers its
first event, so **any widget test that drives "Approve all" through the bloc
hangs forever** (reproduced: 20s of pumped fake time, button still
`loading: true`, no exception, no SnackBar). Verified it is not a repository
bug: the same call completes in a plain `test` (real async), where
`approvals_repository_test.dart` already asserts the 3-row drain.

Consequences, both handled here:
- `approvals_view_test.dart` reaches the empty state by tapping the three
  per-card `Approve` buttons (which do work under fake async), and
- the CTA's busy/disabled contract is covered deterministically with a stub
  `ApprovalsRepository` whose `approveAll` returns a `Completer` — no Drift,
  no hang.

If the orchestrator wants "Approve all" covered end-to-end at the route
level, the options are (a) an `ApprovalsRepository` method that lists the
pending ids without a stream, or (b) a `fakeAsync`-friendly test. Not a UI
blocker, so not filed as a SHARED_REQUEST.

## LEFT FOR NEXT ITERATION

- Screenshot/compare against `design/screens/{light,dark}/P11-approvals.png`
  (stage `5_ui`, simulator) — not run here.
- The `.qn` quote row stays omitted pending
  `docs/screens/P11/SHARED_REQUEST.md` (`quest_completions` has no message
  column). If the orchestrator adds `note TEXT DEFAULT ''` + seed values,
  `ApprovalCard` needs a `note` field and one 17/24 w700 line at
  `margin-top: 10` between `.hd` and the 14px button row.
- Cards are currently ~24px shorter than the design each (no quote line), so
  the first design band-drift review will show that as intentional; confirm it
  is accepted rather than "fixed" by hard-coding the mock quotes.
