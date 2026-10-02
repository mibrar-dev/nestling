# Fix list after iteration 1

## From 2_build.md
# P08 · Today (home) — build notes (Stage 2, iteration 1)

Implemented exactly per `docs/screens/P08/1_plan.md` (§a–§g).

## Files changed (all RULES §1-legal)

- `app/lib/features/today/domain/entities/today_item.dart` — added
  `repeatRule` (default `''`) and `iconKey` (default `''`) to `TodayItem`.
- `app/lib/features/today/domain/entities/child_day_summary.dart` — added
  `ageYears: int?` and `happyDays` (default `0`).
- `app/lib/features/today/domain/today_repository.dart` — added
  `watchParentName()` and `watchPayoutDay()` (plan §b; payout day drives
  `· Weekly · Sat` meta text, read from `families.payout_day`).
- `app/lib/features/today/data/today_repository_impl.dart` — carries
  `repeatRule`/`iconKey` in `rows()`; summaries carry `ageYears`/`happyDays`
  and sort eldest-first (Maya 9 before Leo 6, then nickname); new streams
  read `members` (owner row, else first by name, else `'Sarah'`) and
  `families` (else `6`). No schema/seed change.
- `app/lib/features/today/data/models/today_item_model.dart` — new fields in
  ctor + `fromJson`/`toJson`.
- `app/lib/features/today/presentation/bloc/today_state.dart` — extended
  state: `summaries`, `pendingCount`, `parentName` (`'Sarah'`),
  `greeting` (day part), `dateLine` (`Sat 3 Oct · Happy week: 4 days` shape,
  via `london_time.dart`), `happyDays`, `payoutDay` (`6`).
- `app/lib/features/today/presentation/bloc/today_bloc.dart` — single
  `emit.forEach` over nested `combineLatest2(watchItems+watchSummaries,
  watchParentName+watchPayoutDay)` (contract-compliant, no re-added events);
  pure `dayPartForHour()` helper. `pendingCount` = `done_pending` rows;
  `happyDays` = max over summaries.
- `app/lib/features/today/presentation/widgets/today_loaded_body.dart` (new)
  — shared `TodayLoadedBody` (+ `TodayFailureBody`, `TodayStatusChip`, icon /
  tint / repeat / Pip / avatar maps). Greeting row, leaf-tint approvals
  banner (hidden when 0), kids 2-up `Expanded` grid, `Today's quests` header,
  `MAYA · 9` group labels, `NestQuestCard(maxLines: 2)` rows with coin pill +
  repeat + status chip in HTML order, `Hand to …` button, P08b empty card.
  Zero theme branches (tokens only). Navigation per plan §c:
  `+`→`/quest-editor`, avatar→`/settings`, Review→`/approvals`, kid
  card→`/child-profile?childId=`, See all→`/quests`, quest
  row→`/quest-editor?questId=`, Hand→`/who-is-playing`.
- `app/lib/features/today/presentation/views/today_view.dart`,
  `today_empty_view.dart` — placeholder replaced; both render the shared body
  (empty card appears when `summaries.isEmpty`, i.e. `Seed.empty()`).
- `app/test/features/today/` (new) — `today_repository_test.dart` (10 rows,
  α-order, latest-completion wins incl. newer `done_pending`/`not_yet`
  inserts, Maya 4/6+120 / Leo 2/4+45, parent `Sarah`, payout `6`, model
  round-trip), `today_bloc_test.dart` (loaded with counts, error→failure,
  empty streams, `dayPartForHour` boundaries), `today_view_test.dart`
  (light content + all navigation taps, dark content, empty card + Browse
  ideas, 320-wide + textScale 1.3 no-overflow + ≥44 taps; every widget test
  ends with `disposeApp`).

## Fix items (plan had no numbered fix list; deviations/decisions)

- Plan test expected the header date `Sat 3 Oct`; the header shows *today*
  (live `DateTime.now` via `london_time`), so tests compute the expected date
  string at runtime instead. Seed-anchor note concerns static content only.
- Group order: DB streams are α-ordered (Leo first); view/summaries use
  eldest-first so Maya leads, matching the design.
- All 10 assigned quests render (design mock shows 5 of 10); scroll handles it.
- Status chip: first built as fixed-height `Container(alignment: center)` —
  screenshots showed it stretching full-width on its own Wrap line, and a
  `Row` variant overflowed at 320/1.3 (nested flex-in-flex). Final: padding-
  sized pill (26px at base scale) as a direct `Wrap` child — one line at 390,
  graceful wrap at 320, zero overflow.
- No `SHARED_REQUEST` needed for the build itself (sofa/plate icons fall back
  to `table`/`questCard` in-feature). One request filed for the stale shared
  router test (see below).

## Verification tails

- `dart format .` → `Formatted 342 files (0 changed)`.
- `flutter analyze` → `No issues found!` (whole app, incl. info lints).
- `flutter test test/features/today` → `All tests passed!` (+22).
- `flutter test` (full) → `+308 -1`; sole failure is the shared
  `test/app/router_redirect_test.dart` (`onboarded parent lands on Today`
  expects the removed placeholder text `P08 Today`). Screen agent may not
  touch shared files (RULES §1) — filed as `SHARED_REQUEST.md` (blocking).
- `shot.sh` light + dark + empty screenshots in `docs/screens/P08/ui/`;
  `compare.py` vs `design/screens/light/P08-today.png` → mean diff 6.66%
  (bands 4.6–9.4%). Residual is content, not spacing: live greeting/date
  (`Good evening / Thu 1 Oct` vs mock `Good morning / Sat 4 Oct`) and all 10
  real quest rows vs the mock's 5. Meta-row geometry, banner, kid cards and
  tab bar align with the design.


## From 3_test.md
# P08 · Today (home) — test notes (Stage 3, iteration 1)

Screen: `P08` · route `/today` (+ `P08b` `/today-empty`) · feature `today` ·
mode parent · seed `Seed.demo()` / `Seed.empty()`.
Scope of this stage: tests only. **No screen code was changed** (three real
bugs were found and are recorded below, per the stage rule).

Files touched (RULES §1): `app/test/features/today/**`,
`docs/screens/P08/**`.

## 1. Tests added — 30 new (feature suite 22 → 52)

### `today_bloc_test.dart` — +6 (every event / state path, 10 total)

| # | Test | Covers |
|---|---|---|
| 1 | `initial state is initial with no data` | `TodayStatus.initial` before any event |
| 2 | `parent name and payout day flow into the loaded state` | repo `watchParentName`/`watchPayoutDay` actually reach the state (previous default `'Sarah'`/`6` masked a regression) |
| 3 | `a second items emission updates the state without a new event` | RULES §4 contract: `emit.forEach` reacts to stream re-emissions, no reload events |
| 4 | `an error after a loaded emission switches to failure` | error path after data (stream error mid-session) |
| 5 | `retry after a failure reloads and reaches loaded` | the view's only retry (`Try again` re-adds `TodayLoadRequested`): loading→failure→loading→loaded |
| 6 | `date line uses the singular "1 day"` (plain test) | header pluralisation — **fails, B2** |

Existing 4 tests (load/error/empty + `dayPartForHour` boundaries) kept.

### `today_repository_test.dart` — +1 (10 total)

- `watchItems re-emits when a completion is inserted` — in-memory Drift DB
  (`Seed.demo`): first emission `to_do`, then insert a `done_pending`
  completion → the same subscription re-emits with `done_pending`. This is
  the live-update contract the bloc and the banner rely on.

### `today_view_test.dart` — +23 (32 total)

States (mock `TodayRepository`; a healthy Drift DB cannot fail):

1. `loading shows the spinner`
2. `failure shows the reason and Try again recovers` — taps `Try again`,
   second load succeeds, full loaded body renders
3. `failure renders in dark theme too`

Navigation — every tap lands on the right route; the four that carry params
are checked against `GoRouterState.uri`:

4. `Review opens approvals` → `/approvals`
5. `plus opens the quest editor without a questId` → `/quest-editor`
6. `quest row opens the editor with its questId` →
   `/quest-editor?questId=q-dishwasher`
7. `hand-off button opens who-is-playing` → `/who-is-playing`
8. `See all opens the quest library` → `/quests`
9. `avatar opens settings` → `/settings` (semantics label `"Sarah's profile"`)
10. `kid card opens the child profile with its childId` →
    `/child-profile?childId=maya`
11. P08b: `/today-empty` shows the quiet-nest card; `Add a quest` →
    `/quest-editor`; `Browse ideas` (existing test) → `/quests`

Live data:

12. `approving every pending quest hides the banner` — update all
    `done_pending` completions to `approved` in the Drift DB → stream
    re-emission → banner disappears, rows keep `Approved ✓`, rest unchanged.

Accessibility:

13. `icon buttons, cards and rows expose semantics labels` — `New quest`,
    `"Sarah's profile"`, `See all quests`, kid card
    `Maya, 4 of 6 quests, 120 coins`, quest row
    `Empty the dishwasher, 15 coins, Needs a look`, banner live-region text;
    Pip art + per-child progress labels asserted on the declared `Semantics`
    widgets (they merge into the card node).
14. `parent tap targets are at least 44 high` — `+` (44), avatar (44),
    `Review` (44), `See all` (44), quest row (≥56 by content), `Hand to …`
    (52). See §4 for why ≥56 kid targets do not apply to P08.

Copy (two tests here + the bloc test #6):

15. `one pending approval reads "1 quest" (singular)` — **fails, B1**
16. `banner subtitle names the children` — **fails, B3**

Size matrix (12 tests), light + dark × widths 320/390/430 × text scale
1.0/1.3, all with `Seed.demo`: greeting, banner, kid cards, `MAYA · 9`,
scroll through every row to `Hand to Maya or Leo`, `takeException()` null
(no `RenderFlex overflowed`), `disposeApp` on every widget test.

## 2. Results

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | `342 files (0 changed)` |
| `flutter analyze` | `No issues found!` |
| `flutter test test/features/today` | **49 passed, 3 failed** (the 3 failures are the bug-proving tests below; nothing else is red) |
| `flutter test` (full app) | **+336 −3**; only the same 3 failures |
| Shared suite | `router_redirect_test.dart` was red in Stage 2; fixed on `main` (`2f723db`) and merged into this branch (`5c0267e`) — verified green, `SHARED_REQUEST.md` §1 marked resolved |

## 3. Bugs found (do NOT patch in this stage — fix in the next build)

### B1 — banner says "1 quests waiting…" (major, user-visible copy)

- File: `app/lib/features/today/presentation/widgets/today_loaded_body.dart:378`
  (visible text) and `:361` (Semantics label — same string, same bug).
- Repro: `flutter test test/features/today/today_view_test.dart --plain-name 'one pending approval reads'`
  (test approves all but one pending completion, then renders `/today`):
  expected `'1 quest waiting for your thumbs-up'`, actual
  `'1 quests waiting for your thumbs-up'`.
- Reachable in normal use: a parent approving 3 pending quests one at a time
  passes through `pendingCount == 1`.
- Suggested fix: `pendingCount == 1 ? '1 quest waiting for your thumbs-up' : '$pendingCount quests waiting for your thumbs-up'`
  in both places.

### B2 — header says "Happy week: 1 days" (major, user-visible copy)

- File: `app/lib/features/today/presentation/bloc/today_bloc.dart:59`
  (`'${formatLondonDay(...)} · Happy week: $happyDays days'`).
- Repro: `flutter test test/features/today/today_bloc_test.dart --plain-name 'date line uses the singular'`
  expected `'Fri 2 Oct · Happy week: 1 day'`, actual
  `'Fri 2 Oct · Happy week: 1 days'` (repo returns `happyDays == 1`).
- Suggested fix: pluralise — `'Happy week: $happyDays day${happyDays == 1 ? '' : 's'}'`.

### B3 — banner subtitle differs from the design (minor, design fidelity)

- File: `today_loaded_body.dart:385` — hard-coded
  `'Your little birds did brilliantly'`.
- Design: `design/screens/light/P08-today.png`,
  `design/screens/dark/P08-today.png` and
  `design/html-source/screens/P08-today.html:30` all show
  **"Maya and Leo did brilliantly yesterday"**.
- Repro: `flutter test test/features/today/today_view_test.dart --plain-name 'banner subtitle names the children'`
  expected `'Maya and Leo did brilliantly yesterday'`, actual
  `'Your little birds did brilliantly'`.
- Suggested fix: build the line from `state.summaries` nicknames
  (`'Maya and Leo'`, single child `'Maya'`, 3+ `'Maya, Leo and Sam'`) — the
  banner only renders when pending quests (and therefore summaries) exist.

### B4 — duplicated semantics announcements (minor, a11y)

A `Semantics(label: …)` wrapper whose child repeats the same text/labels gets
merged by Flutter into one node carrying **both**, so a screen reader reads
everything twice. Semantics dump from `/today` (Seed.demo):

- (a) feature, `_ApprovalsBanner` (`today_loaded_body.dart:359-361`):
  banner node label =
  `"3 quests waiting for your thumbs-up\n3 quests waiting for your
  thumbs-up\nYour little birds did brilliantly\nReview"`.
  Fix: keep `liveRegion: true`, drop the duplicate explicit label (or wrap
  the text column in `ExcludeSemantics`).
- (b) shared components `NestCard` (`nest_card.dart:60-65`) and
  `NestQuestCard` (`nest_quest_card.dart:107-111`) — quest row node label =
  `"Empty the dishwasher, 15 coins, Needs a look\nEmpty the dishwasher\n
  15 coins\n· Weekly · Sat\nNeeds a look"`, kid card adds its children
  again. Not fixable from feature code → filed as
  `docs/screens/P08/SHARED_REQUEST.md` §2 (`excludeSemantics: true`).

## 4. Scope notes / deliberate non-findings

- **P08b visual polish is left to the P08b loop.** `Seed.empty()` renders the
  shared body with the DESIGN_SPEC §5 P08b title/message/CTAs, but the P08b
  design PNG/HTML differ further (header `"Sat 4 Oct · A fresh nest"` at 28px
  with no header actions, the longer message *"… Maya and Leo will see it
  straight away."*, `Browse ideas` as an underlined link, and a
  *"Tip for new nests"* card). This stage's design references are P08
  light/dark and P08b is a separate screen ID/loop — recorded here so P08b's
  plan picks it up rather than failing P08 for it.
- `1 of 1 quests` on a kid card is left as-is: the *"X of Y quests"* idiom
  reads acceptably (unlike B1).
- Kid-mode ≥56px tap targets do not apply to P08: `/today` is parent mode and
  the shell redirects kid mode to P17 (covered by the shared router tests).
- Loading/error widget tests drive `TodayView` with a mock `TodayRepository`
  because an in-memory Drift DB can never fail; all other tests use the
  in-memory DB with `Seed.demo` / `Seed.empty`.
- Tests never await `TodayBloc.close()`: `emit.forEach` holds the long-lived
  watch streams (as in the app), so the close future only resolves when a
  source ends — commented in the two state tests that create blocs directly.
- Minor state hygiene (not a bug, not user-visible): after a successful retry
  the stale `errorMessage` survives in `TodayState` (the failure UI keys off
  `status`, so nothing renders it).


## From 4_review.md
# P08 · Today (home) — QA code review (Stage 4, iteration 1)

Route `/today` (+ `/today-empty`), feature `today`, mode parent, seed `demo`/`empty`.
Reviewed: working-tree diff vs `main` (9 modified + 1 new lib file + 3 new test files),
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P08,
`docs/design/SPACING_SPEC.md`, `app/lib/core/design_system/**`,
`design/html-source/screens/P08-today.html`, `design/screens/light/P08-today.png`,
and the shots in `docs/screens/P08/ui/`. No code was edited.

## What I ran

| Check | Result |
|---|---|
| `flutter test test/features/today` | **49 passed, 3 failed** (see B1) |
| `dart format --set-exit-if-changed` / `analysis_options.yaml` vs `main` | unchanged, not weakened |
| Files touched vs `main` | all inside RULES §1 (`features/today/**`, `test/features/today/**`, `docs/screens/P08/**`) |
| Design-vs-app pixel measurement (`design/screens/light/P08-today.png` vs `docs/screens/P08/ui/today-light.png`, ÷3) | quest-row gap **8.00 px** narrower than the design; everything above the quest list sits 14–18 px high |

## Findings

### B1 — blocker — the screen's own suite is red (RULES §7.1)

`flutter test test/features/today` → `+49 −3`. `flutter test` cannot be green, so the
screen cannot be signed off. The three failures are the copy defects B3/B4/B5 below
(reported by Stage 3 and still unfixed); they are not flaky and not test bugs.

- `test/features/today/today_bloc_test.dart` — *date line uses the singular "1 day" …*
- `test/features/today/today_view_test.dart` — *one pending approval reads "1 quest" (singular)*
- `test/features/today/today_view_test.dart` — *banner subtitle names the children*

**Fix:** apply B3/B4/B5, then re-run `flutter test` (full app) green. Note that
`today_view_test.dart:60-62` (`_expectedDateLine`) hard-codes `'$happyDays days'` and must
be pluralised in step with B4, otherwise the content tests will fail the other way.

---

### B2 — major — quest rows are separated by 8 px, the spec and the plan say 16 px

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:240`

```dart
for (final item in mine) {
  children
    ..add(const SizedBox(height: NestSpacing.s2))   // 8 — applied to EVERY row
    ..add(_QuestRow(item: item, payoutDay: state.payoutDay));
}
```

- `SPACING_SPEC` §8: *"Base rhythm: siblings in `.scroll` separated by **16** (`> * + *`)"*
  and *"Card-to-card vertical: 16 default"*. `components.css:66` is the same rule; the
  only 8 px on this screen is `.qgroup { margin: 16px 0 -8px }`, i.e. **label → first row**.
- `1_plan.md` §a.1: *"separators `SizedBox(height: NestSpacing.s4=16)` between children,
  EXCEPT group-label→first-card gap = 8"*. The build deviated from its own plan.
- Measured: first quest card bottom → second quest card top = **21.33 px** in the design
  vs **13.33 px** in the app → exactly **8.00 px** lost per gap (both numbers carry the
  same +5.33 px card-shadow bias, so the delta is exact). With the demo seed that is
  3 gaps × 8 px = **24 px** of accumulated drift, and everything below the list
  (`LEO · 6`, Leo's rows, the hand-off button) lands 24 px high.

**Fix** (feature-local, RULES-legal):

```dart
for (var i = 0; i < mine.length; i++) {
  children
    ..add(SizedBox(height: i == 0 ? NestSpacing.s2 : NestSpacing.s4))
    ..add(_QuestRow(item: mine[i], payoutDay: state.payoutDay));
}
```

Then re-shoot light + dark and re-run `compare.py`; expect the band table below
"Today's quests" to close.

---

### B3 — major — banner subtitle is the wrong copy, and hard-coded

`today_loaded_body.dart:385` → `'Your little birds did brilliantly'`

`P08-today.html:30`, `design/screens/light/P08-today.png`,
`design/screens/dark/P08-today.png` all read **"Maya and Leo did brilliantly yesterday"**.
Two problems:

1. Copy is not the design copy (the brief requires copy exactly). It also wraps to 1 line
   instead of the design's 2, which is why the whole page below the banner renders ~18 px
   high in the app screenshot (measured: design kid cards start at y 258, app at y 244).
2. It names nobody, so it happens to be safe for other families — but the *design* copy is
   name-dependent, and hard-coding it means a family with one child ("…and Leo…") or five
   would still be told about "little birds". The next person to "fix" the string to the
   design copy inline would ship `"Maya and Leo"` to every family.

**Fix:** build it from state, one helper next to `todayRepeatText` /
`todayStatusLabel`, and use it for the visible `Text` *and* the `Semantics` label:

```dart
String todayBannerSubtitle(List<ChildDaySummary> kids) {
  final names = kids.map((k) => k.nickname).toList();
  final who = switch (names.length) {
    0 => 'Your nestlings',
    1 => names.first,
    2 => '${names[0]} and ${names[1]}',
    _ => '${names.take(names.length - 1).join(', ')} and ${names.last}',
  };
  return '$who did brilliantly yesterday';
}
```

The banner only renders when `pendingCount > 0`, which implies summaries exist, so the
`0` branch is only a guard.

---

### B4 — major — "1 quests waiting for your thumbs-up"

`today_loaded_body.dart:361` (semantics label) and `:378` (visible text) both interpolate
`$pendingCount` into the plural noun. A parent approving three pending quests one at a
time passes through `pendingCount == 1` and sees "1 quests …". The design and
`DESIGN_SPEC` §5 P08 fix the string at 3, so the mock never shows the defect.

**Fix:** one local helper used by both sites so they cannot drift again
(`todayPendingLabel(int n) => n == 1 ? '1 quest waiting for your thumbs-up' : '$n quests waiting for your thumbs-up'`).

---

### B5 — major — "Happy week: 1 days"

`app/lib/features/today/presentation/bloc/today_bloc.dart:59`

```dart
dateLine: '${formatLondonDay(DateTime.now().toUtc())} · Happy week: $happyDays days',
```

`happyDays` is the max over the children's `children.happy_days`, so a family with a
single happy day this week renders "Happy week: 1 days".

**Fix:** `'${formatLondonDay(DateTime.now().toUtc())} · Happy week: '
'happyDays${happyDays == 1 ? '' : 's'}'`
(plus the matching test helper, see B1). Consider whether `0` should read
"Happy week: 0 days" or drop the clause entirely — the demo path (`Seed.empty()`, no
children) currently shows "Happy week: 0 days" in the header, which means nothing to a
parent with no children yet (see B13 for the P08b header).

---

### B6 — major — the kids grid is N-up with no cap: 3+ children collapse the cards

`today_loaded_body.dart:410-424`

```dart
final cards = summaries.map(_KidCard.new).toList();
if (cards.length == 1) return cards.single;
return Row(spacing: NestSpacing.gap10, children: [for (final c in cards) Expanded(child: c)]);
```

`DESIGN_SPEC` §5 P08 and `SPACING_SPEC` §8 both specify a **2-up** grid (170 + 170, gap
10). `watchSummaries()` returns one card per child and nothing caps that at two —
P05's flow is "Add a child" / "+ Add another child", so three children is an ordinary
state, not an edge case. At three children each card is `(350 − 20) / 3 = 110 px`, and the
card's `avatar(32) + gap(8) + Expanded(column)` leaves ~42 px for the name, so "Maya"
ellipsises to "May…" and "4 of 6 quests" to "4 o…" — the one number the card exists to
show. At four it is worse. Nothing overflows (so no test catches it), the home screen is
just broken.

**Fix:** chunk into pairs and keep the design's 2-up grid:

```dart
final rows = <Widget>[];
for (var i = 0; i < cards.length; i += 2) {
  final pair = cards.skip(i).take(2).toList();
  rows.add(Row(
    spacing: NestSpacing.gap10,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [for (final c in pair) Expanded(child: c)],
  ));
}
return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: NestSpacing.gap10, children: rows);
```

Add a widget test with three `ChildDaySummary`s asserting the kid names are still found
and `takeException()` is null. (Note `1_plan.md` §e only covered the 320 px *width*
case via `Expanded`, which is why this slipped through.)

---

### B7 — major — `context.go` to top-level routes destroys the back stack

`today_loaded_body.dart:401` (Review → `/approvals`), `:319` and `:667` (`+` and
`Browse`/`Add a quest` → `/quest-editor`), `:584` (quest row → `/quest-editor?questId=…`)

`/today` lives in a `StatefulShellRoute` branch (`app/lib/app/router.dart`), but
`/approvals`, `/quest-editor` and `/today-empty` are top-level routes. `go` **replaces**
the whole page stack, so those screens are pushed onto nothing:

- `DESIGN_SPEC` §5 **P11** specifies *"nav back 'Today'"* and **P09** *"nav back | New
  quest | Save"* / *"Cancel"*. With `go` there is no `/today` page to return to, so
  `context.pop()` in those screens pops the last remaining route — i.e. the Android
  back button / iOS swipe-back exits the app instead of going home.
- The same applies to hardware back on the quest editor, which is a *sheet* over Today.

`1_plan.md` §c prescribed `go` for everything, so the plan needs correcting too, not just
the code. The existing navigation tests only assert the resulting `GoRouterState.uri`,
so they pass either way — which is why this was not caught.

**Fix** in `today_loaded_body.dart`: use `context.push(...)` for the pushed screens
(`/approvals`, `/quest-editor`, with and without `questId`), and keep `context.go(...)`
only for the two genuine destination switches — `/settings` and `/child-profile?childId=`
(both are shell branches, so `go` is the correct tab switch, matching P15's
"Family tab active") and `/who-is-playing` (a mode switch, not a page). Add a note to
`SHARED_REQUEST.md` so the P09/P11/P15 loops know those routes are reached by `push` and
must return with `context.pop()`.

---

### B8 — major — the dark screenshot predates the last source change (RULES §7.2)

`docs/screens/P08/ui/today-dark.png` mtime **2026-10-01 23:47:48**;
`today_loaded_body.dart` mtime **2026-10-01 23:50:14**; `today-light.png` 23:50:55;
`today-empty.png` 23:51:43. The dark shot is 2 m 26 s older than the final edit — it is
the only dark artifact in the notes and it was taken *before* the status-chip rework that
`2_build.md` describes.

It is visibly the pre-fix render: the "Needs a look" / "Approved ✓" chips are
**full-width bars with centred text**, which the current `TodayStatusChip`
(`today_loaded_body.dart:154-185`, no `alignment`, no fixed height) cannot produce —
the current code left-aligns a content-sized pill, and the light shot taken after the
edit shows exactly that. So the dark evidence in `3_test.md` §3 ("contrast eyeball via
shot.sh compare") and the claim that the chip fix was verified in both themes rest on an
image of code that no longer exists, and a real dark-mode regression in that widget would
be invisible.

**Fix:** re-run `tools/screens/shot.sh` for `/today` in **both** light and dark (and
`/today-empty`), confirm each PNG is newer than the sources it renders, and re-read them
before claiming dark is verified. Worth a loop-level guard: fail the stage if any
`docs/screens/<ID>/ui/*.png` is older than the feature sources.

---

### B9 — minor — the greeting renders Nunito 800 with no tracking; the spec says 900 / −0.01em

`today_loaded_body.dart:288-290` — `NestType.h2(color: tokens.ink).copyWith(fontSize: 22, height: 28 / 22)`.
`NestType.h2` is `_nunito(22, 28, FontWeight.w800)` with no `letterSpacing`
(`core/design_system/tokens/typography.dart:48-51`), but `P08-today.html:5` and
`SPACING_SPEC` §8 both specify `font-weight: 900; letter-spacing: -.01em`. This is the
most prominent text on the screen. `1_plan.md` §a.2 *described* 900/−1% but its
parenthetical prescribed the `h2` token, which is not that style.

**Fix:** `.copyWith(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w900, letterSpacing: -0.22)`
(the token path is kept; only the two design-specified overrides are added).

---

### B10 — minor — the banner's semantics label duplicates everything inside it

`today_loaded_body.dart:360-361` — `Semantics(liveRegion: true, label: '$pendingCount quests …')`
wraps a `Container` whose children repeat that exact string plus the subtitle and the
"Review" button. Flutter merges the explicit label with the descendants, so the announced
node is (per the Stage 3 semantics dump):

```
3 quests waiting for your thumbs-up
3 quests waiting for your thumbs-up
Your little birds did brilliantly
Review
```

**Fix:** keep `liveRegion: true`, drop the explicit `label:` and let the children
announce once — or keep the label and wrap only the text column in `ExcludeSemantics`.
Do **not** add `excludeSemantics: true` to the outer `Semantics`: that would also silence
the "Review" button. The same defect in the shared `NestCard` / `NestQuestCard` is
correctly filed as `SHARED_REQUEST.md` §2 and is not fixable from here.

---

### B11 — minor — quest rows are ordered alphabetically, the design orders them by status

`data/today_repository_impl.dart:108-109` sorts each child's quests with
`a.title.compareTo(b.title)`. The design shows Maya's rows as
*"Empty the dishwasher" (Needs a look) → "Reading – 20 minutes" (To do) → "Put the bins
out" (Approved ✓)*, and Leo's as *"Make your bed" (Needs a look) → "Feed Biscuit the cat"
(To do)* — i.e. `done_pending` → `to_do` → `approved` (the status rank is consistent
across both groups and is not alphabetical or reverse-alphabetical). The app renders
Empty the dishwasher → Hoover the stairs → Lay the table (α), which scatters the
"Needs a look" rows through the list and contradicts a screen whose banner exists to
surface them.

`1_plan.md` §f endorsed α-sort without checking it against the mock, and neither the
repository nor the view test pins the order.

**Fix:** sort in `rows()` by `(statusRank, title)` with
`done_pending → 0, to_do → 1, not_yet → 2, approved → 3`, and add a repository test that
asserts the rendered order for `Seed.demo()`. If the orchestrator decides the mock order
was arbitrary, say so in `DESIGN_SPEC` §5 and close this as a doc fix — but the current
state (code and spec disagreeing, silently) is the worst of the three.

---

### B12 — minor — `NestSectionLabel` re-implemented by hand

`today_loaded_body.dart:566` — `Text(label, style: NestType.sectionLabel(color: tokens.ink2))`
with a manual `.toUpperCase()` at `:564-565`. `NestSectionLabel`
(`core/design_system/components/nest_section_label.dart`) exists, is exported by the
barrel, and renders the identical style plus `Semantics(header: true)`,
`maxLines: 1` and `overflow: ellipsis`. RULES/the brief say components are reused, never
re-implemented; the only visual difference here is nil, so the hand-rolled copy buys
nothing and costs the `header` role that screen-reader users use to jump between the
"MAYA · 9" / "LEO · 6" groups.

**Fix:** `return const NestSectionLabel(label: label)` — with the local `label` string
still built from `ageYears` (the component upper-cases internally, so pass the
mixed-case `'$name · $age'`).

---

### B13 — minor — dead, duplicated status copy in the data layer

`data/today_repository_impl.dart:121` still writes
`detail: '${kid.nickname} · ${_statusLabel(status)}'` and `:136-147` keeps
`_statusLabel`, but no presentation code reads `TodayItem.detail` any more (grep: only
the entity, the model round-trip and this line). The view has its own
`todayStatusLabel` (`today_loaded_body.dart:110-121`) with **different** strings
("waiting for thumbs-up" vs "Needs a look"). Two sources of truth for the same copy, one
of them dead.

**Fix:** either drop `detail` + `_statusLabel` from the feature's `domain/`+`data/`
(RULES-legal, and `TodayItemModel` goes with it), or have the view read `item.detail` and
delete `todayStatusLabel`. Prefer the former — the view needs a label *and* a chip
colour, so the status enum belongs in one mapper, not a pre-rendered sentence.

---

### B14 — minor — "Try again" leaves the previous subscription alive if the stream does not close

`app/lib/features/today/presentation/bloc/today_bloc.dart:29-66` — `emit.forEach` with an
`onError` handler. In `bloc` 9.2.1, `Emitter.forEach` delegates to `onEach`, which
listens with **`cancelOnError: false`** when `onError != null` and only cancels via
`onDone`. A Drift-backed `watch()` stream that errors without closing therefore leaves
the first `forEach` subscribed; the next `TodayLoadRequested` (the "Try again" button,
`today_loaded_body.dart:709`) starts a *second* concurrent `forEach`, so each retry
leaks one more full set of repository watchers and every DB write re-runs them all.

The test masks this: `_MockTodayRepository` returns
`Stream<List<TodayItem>>.error(...)` (`test/features/today/today_view_test.dart:400`),
which closes immediately, so `onDone` fires and the handler completes. A real
`combineLatest` stream (`core/data/stream_combine.dart` forwards with
`controller.addError`, which does not close the controller) does not.

**Fix:** make the error terminal on the stream before it reaches the bloc, e.g.
transform the combined stream so the first error is forwarded *and* the stream closes
(`StreamTransformer.fromHandlers(handleError: (e, s, sink) { sink.addError(e, s); sink.close(); })`).
Then add a test whose error stream stays open (e.g. a `StreamController` that
`addError`s without `close()`) and assert the repository's `watchItems` is called once
per load, not once per retry.

---

### B15 — minor — raw `error.toString()` is shown to a parent

`today_bloc.dart:64-67` puts `error.toString()` into `TodayState.errorMessage`, and
`TodayFailureBody` (`today_loaded_body.dart:682-716`) renders it verbatim, so a
`Bad state: No element` or a Drift stack fragment is the user-facing failure copy. The
tests even assert on it (`find.textContaining('offline')`).

**Fix:** keep the raw message in the state for logs/tests, and render a fixed, kind
string in the view (e.g. "We couldn't load today's quests. Your data is safe — try
again."). If the tests want the cause, assert on `state.errorMessage`, not on the widget.

---

### B16 — minor — the banner title's line break cannot match the design

`P08-today.html:11` uses `text-wrap: balance`, which the design has no Flutter mapping
for (SPACING_SPEC §9.2 covers only `softWrap`). The app breaks as
"3 quests waiting for your / thumbs-up" against the design's
"3 quests waiting / for your thumbs-up", so the banner is ~1 line-height taller than the
mock. `1_plan.md` §a.3 acknowledged the substitution; recording it here so it is not
re-litigated each iteration. No action beyond a note unless the design system grows a
balanced-text helper.

---

### B17 — minor — the `liveRegion` banner re-announces on every unrelated emission

`today_loaded_body.dart:360`. The banner is inside a `BlocBuilder` fed by four combined
watch streams, so inserting a completion, a coin change or a child edit re-emits the
state and re-announces the same sentence even though the pending count has not changed.
**Fix:** gate the live region on the count changing — wrap the banner in
`Semantics(liveRegion: true)` only when `pendingCount` differs from the previous build
(`didUpdateWidget` on a stateful wrapper), or drop `liveRegion` and rely on the
heading/`header` semantics the rest of the screen already provides.

---

### B18 — minor — quest meta `runSpacing` is 4 px, the design's `gap` is 6 px

`core/design_system/components/nest_quest_card.dart:80` uses
`runSpacing: NestSpacing.s1` (4) where `components.css:178` sets
`.quest-meta { gap: 6px }` (both axes). Invisible at 390 px (the meta row fits on one
line) but visible whenever it wraps at 320 px / 1.3× text — exactly the case the size
matrix tests cover. Shared component, so this belongs in `SHARED_REQUEST.md` (new §3)
rather than in P08's code; the screen agent may not edit `core/`.

---

### B19 — minor — a design/seed conflict on repeat rules was never filed (RULES §4)

The design shows `· Daily` for "Empty the dishwasher" and "Reading – 20 minutes", but
every seeded quest defaults to `repeat = 'weekly'`
(`core/data/seed.dart:181`), so the app renders `· Weekly · Sat` on all of them — which
is also why the status chip is pushed much wider than the design's
(measured: 75.7 px vs 73.0 px of pill, and the whole meta row is ~40 px longer). The
code is right to render the DB value; RULES §4 says a design/DB disagreement must be
filed as a SHARED_REQUEST and the seed must not be forked, and `SHARED_REQUEST.md` has
no such entry.

**Fix:** add a §3 to `SHARED_REQUEST.md`: seed `q-dishwasher` and `q-reading` (and
`q-bed`/`q-biscuit` per P08's Leo rows) with `repeat: 'daily'` to match the design, or
state that the design's `· Daily` is illustrative. Then re-shoot — the meta row and chip
widths will match the design better and the quest-row band drift will be easier to read.

---

### B20 — minor — hand-off copy for 3+ children

`today_loaded_body.dart:625-631` — `_ => 'Hand to ${names[0]} and friends'`. The design
only defines the 2-child string, and this one is wrong for a family of three or more
("Hand to Maya and friends" when the button is a picker for Maya, Leo *and* Sam).
**Fix:** `'$first${names.length > 2 ? ' and ${names.length - 1} others' : ' or $second'}'`,
or keep it honest with "Hand to the nest" once the design grows a 3-child case.

---

### B21 — minor — P08b empty-card content is inset 36 px, the design says 20 px

`today_loaded_body.dart:648-651` wraps `NestEmptyState` in
`NestCard(padding: fromLTRB(20, 28, 20, 28))`, and `NestEmptyState` adds its own
`horizontal: NestSpacing.s4` (`nest_empty_state.dart:22-25`) → 36 px of inset. Measured in
`ui/today-empty.png`: the "Add a quest" button spans x 54.8 → 335.2 logical, i.e. 34.8 px
inside a card whose edge is at 20. The design's `.empty-card` wants 20 (SPACING_SPEC §5).
`1_plan.md` §d predicted "net matches within 4px" — the arithmetic was 20 + 16.
**Fix:** pass a zero-horizontal `Padding` override, or build the P08b card from
`NestCard` + `Text`/`NestButton` directly instead of nesting `NestEmptyState`. P08b has
its own loop (Stage 3 §4 lists further P08b divergences) — file this to that loop rather
than fixing it here.

---

### B22 — minor (doc, no code) — `DESIGN_SPEC` §5 P08 asks for a floating pill the design does not have

`DESIGN_SPEC` §5 P08: *"Floating primary '+ New quest' pill above tab bar at right (must
not cover content: add bottom padding)"*. `P08-today.html:29` puts the 44 px leaf `+`
**in the greeting row** and has no `.fab`; `design/screens/light/P08-today.png` shows no
floating pill; the code follows the design (and the `+` in the header is a 44 px leaf
circle with `sh-1`, exactly the mock). The design system does have an unused
`NestFab` (`components/nest_fab.dart`) and `components.css:76` has a
`.screen:has(.fab) .scroll` rule, so the §5 text is probably stale.

**Fix (orchestrator, not P08):** correct `DESIGN_SPEC` §5 P08 to describe the header `+`,
so the P08b loop and any future re-run do not "fix" a non-existent gap. Flag it in
`SHARED_REQUEST.md` §4 so it is batched once.

---

## Checks that passed (no findings)

- **RULES §1 file scope** — only `app/lib/features/today/**`,
  `app/test/features/today/**`, `docs/screens/P08/**`. No `core/`, no `app/`, no other
  feature, no `tools/screens/`. `analysis_options.yaml` byte-identical to `main`.
- **ARCHITECTURE** — feature-first; `domain/` holds only entities + the abstract
  `TodayRepository` (now 4 stream getters, no concrete types); `data/` holds the model
  + impl; one bloc with a single `TodayLoadRequested` and
  `initial/loading/loaded/failure`; `TodayBloc` is still a GetIt **factory** closed by
  `BlocProvider`; DI and routes untouched; no use-case classes, no new folders, every
  import `package:nestling/…`. `Seed.familyId` in queries matches every other feature's
  repository — house pattern, not a finding.
- **No schema/migration/seed fork** — every new field is read from existing tables
  (`members.role`, `families.payout_day`, `children.age_years`, `children.happy_days`,
  `quests.repeat_rule`, `quests.icon`). Correct per RULES §4.
- **Design-system usage** — no hard-coded colour literals (`tokens.leafTint`,
  `tokens.coinInk`, `tokens.aPeach`, …), no magic numbers where a token exists
  (`NestSpacing.*`, `NestRadii.*`, `NestDevice.tapParent`, `NestAvatarSize.s32`,
  `NestCoinPillSize.xSmall`), no hard-coded font family or size outside the two
  design-specified overrides the design system itself sanctions. Components reused:
  `NestCard`, `NestQuestCard`, `NestButton`, `NestIconButton`, `NestAvatar`, `NestIcon`,
  `NestProgress`, `NestCoinPill`, `NestEmptyState`, `NestType.*` (only B12 re-implements
  one). Local `Container`s are limited to the two variants the system does not ship
  (leaf-tint banner, 26 px status chip) and are documented as such.
- **DESIGN_SPEC §5 P08 element coverage** — tab bar (from `ParentShell`, not
  re-added), greeting + date + `+` + `S` avatar, leaf-tint approvals banner with
  "Review", 2-up kid cards with Pip art / "4 of 6 quests" / progress / coin pill,
  "Today's quests" + "See all", per-child `MAYA · 9` groups, quest rows in HTML order
  (coin → repeat → status), hand-off button. Copy is en-GB throughout ("colour/practice"
  class words absent; "thumbs-up", "quest", "nest" all UK usage). No US spellings found.
- **Dark theme** — zero theme branches in feature code; every colour goes through
  `context.nest`; the banner's leaf-ink-on-leaf-tint pair flips correctly (see the
  dark shot). Contrast: the smallest text is the 12 px w700 status chip, per the
  design's own contrast audit.
- **Motion (RULES §6)** — no `Timer`, `AnimationController`, Rive or Lottie; Pip is a
  static SVG; nothing to gate on `kDisableAnimations`.
- **Children's Code** — no analytics, ads, tracking or network calls anywhere in the
  feature; data comes from the on-device Drift DB only; no child identifier, nickname or
  photo leaves the app; `/today` is in the router's `parentOnly` set so kid mode is
  redirected to the parental gate before this view can render; coins only, never `£`; no
  red, no nagging, no urgency, no loss-framing copy. Nothing to file.
- **Performance** — `BlocBuilder` + Equatable props mean identical states never rebuild;
  all separators/`SizedBox` are `const`; no per-frame work, no `setState` in build, no
  `IntrinsicHeight`/`shrinkWrap` lists; the list is short enough that `ListView(children:)`
  is fine; blocs are GetIt factories, so `emit.forEach` is cancelled and
  `stream_combine`'s `onCancel` releases the Drift subscriptions when the route is
  popped. One non-blocking smell worth logging: `watchSummaries()` re-subscribes
  `watchItems()` internally (`data/today_repository_impl.dart:38`) and the bloc subscribes
  both, so one home screen opens ~9 Drift watchers (quests, completions, children ×2,
  members, families) that all re-run on every write. A single
  `Stream<TodayDay> watchTodayDay()` on the repository would collapse that to one set.

## Required before this screen can pass

1. B1 — green `flutter test` (full app), which means B3, B4, B5 + the
   `_expectedDateLine` helper.
2. B2 — 16 px between quest rows, re-shot and re-compared.
3. B3/B4/B5 — banner + header copy from state, pluralised.
4. B6 — 2-up kids grid that survives 3+ children, with a test.
5. B7 — `push` for `/approvals` and `/quest-editor`; SHARED_REQUEST note for P09/P11/P15.
6. B8 — re-shoot light **and** dark **and** `/today-empty` from the final sources.

B9-B22 are minor and may ride along in the same iteration, but B10 (banner semantics),
B12 (`NestSectionLabel`), B13 (dead `detail`) and B16 should not be left to a later
screen, since they are all in P08's own files.


## From 5_ui.md
# P08 · Today (home) — UI check (Stage 5, iteration 1)

Route `/today`, mode parent, seed demo, child maya, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874.
Shots are fresh from current sources (light + dark re-taken this stage; relative `OUT`
paths break `shot.sh` after its internal `cd`, so absolute paths were passed — no repo files touched).

## Shots + diffs

- `bash tools/screens/shot.sh "$PWD/app" /today "$PWD/docs/screens/P08/ui/app_light_1.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo parent maya` → stable frame saved.
- Same with `dark` → `app_dark_1.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P08-today.png docs/screens/P08/ui/app_light_1.png docs/screens/P08/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/P08-today.png docs/screens/P08/ui/app_dark_1.png docs/screens/P08/ui/cmp_dark_1.png`

| Theme | Mean diff | Bands (y-range: diff%) |
|---|---|---|
| Light | **6.67%** | 0–105: 5.62 · 105–211: 6.86 · 211–316: 4.73 · 316–422: **9.36** · 422–527: 4.62 · 527–633: 8.09 · 633–738: 7.63 · 738–844: 6.45 |
| Dark | **6.55%** | 0–105: 5.73 · 105–211: 5.73 · 211–316: 5.41 · 316–422: 8.22 · 422–527: 4.81 · 527–633: 8.29 · 633–738: 7.75 · 738–844: 6.45 |

Both compare sheets + both app shots + both design PNGs were read with the file
reader; HTML source `design/html-source/screens/P08-today.html` and the feature's
view code were read (not edited) to ground each deviation. Crop-zoomed the
dishwasher tile and the Money tab icon (design vs app) before asserting icon choice.

## What matches (verified in the compare sheets)

Greeting "Good morning, Sarah" (1 line, ellipsis-safe); `+` 44 px leaf circle and `S`
avatar position/size; approvals banner geometry (leaf-tint, r24, Review button);
2-up kid cards (names, "4 of 6 quests" / "2 of 4 quests", progress 67 % / 50 %,
coin pills 120 / 45); "Today's quests" + "See all"; "MAYA · 9" group label;
quest-card geometry/typography; meta order coin → repeat → status chip; chip colours
(Needs a look = coin-tint, To do = surface-2, Approved ✓ = leaf-tint); dark-mode
token flips with zero theme branches (banner, cards, pills, chips all correct in dark).

## Deviations (element · design value · app value · fix)

1. **Pip art source (mandatory orchestrator-rule violation).** Rule: P08 must render
   each child's OWN Pip via `PipAvatar` (Maya = Mochi·sunny·stage 3, Leo =
   Bolt·sky·stage 2); never the v1 `pip_stage_*.svg` in product screens. App value:
   `today_loaded_body.dart:110-121` (`pipStageAsset`) + `:486-496`
   (`SvgPicture.asset(..., 72×72)`) renders the generic v1 illustrations for both
   cards. Slot size/position are correct — only the art source is wrong.
   Fix (P08-local): feed `pip_style`/`pip_skin`/`pip_accessory`/`pip_stage` from the
   database into `PipAvatar` in `_KidCard`, keeping the 72×72 centred slot.
2. **Banner subtitle copy.** Design (`P08-today.html:30`, both PNGs): "Maya and Leo
   did brilliantly yesterday" (2 lines). App (`today_loaded_body.dart:385`):
   "Your little birds did brilliantly" (1 line). The shorter subtitle also shifts
   everything below up ~18 px (kid cards start higher in the app shot).
   Fix: build the subtitle from state (names + "did brilliantly yesterday", with a
   0/1/3+-child guard) and use it for the visible text and the semantics label.
3. **Quest-row gaps 8 px, spec says 16 px.** Design/`SPACING_SPEC` §8/plan §a.1:
   16 px card-to-card (8 px only label→first-card). App
   (`today_loaded_body.dart:240`): `SizedBox(height: s2)` before EVERY row.
   Stage 4 measured exactly 8.00 px lost per gap (21.33 px vs 13.33 px incl. shadow);
   the fresh compare confirms it — bands 5–7 carry the drift and the app viewport
   fits an extra half row. Fix: `i == 0 ? s2 : s4` in the row loop, then re-shoot.
4. **Quest order: alphabetical, design orders by status.** Design Maya rows:
   "Empty the dishwasher" (Needs a look) → "Reading – 20 minutes" (To do) →
   "Put the bins out" (Approved ✓); Leo likewise pending-first. App
   (`today_repository_impl.dart:108-109`, α-sort): "Empty the dishwasher" →
   "Hoover the stairs" (Approved ✓) → "Lay the table", scattering Needs-a-look rows.
   Fix: sort `rows()` by (statusRank: done_pending 0, to_do 1, not_yet 2, approved 3;
   then title) + repository order test. Note `1_plan.md` §f endorsed α-sort, so the
   plan needs the same correction.
5. **Latent pluralisation copy (not visible at demo values, same root cause as 2).**
   `today_loaded_body.dart:361/378` interpolate "N quests…" (renders "1 quests…"
   at N=1); `today_bloc.dart:59` renders "Happy week: 1 days". Fix with
   `todayPendingLabel` / conditional plural helpers + the test helper in step.
6. **Greeting weight/tracking (minor).** Design/HTML/SPACING_SPEC §8: Nunito 900,
   ls −1 % (−0.22 px at 22 px). App: `NestType.h2` = Nunito 800, no tracking
   (title shows heat doubling in both compare sheets). Fix: `.copyWith(
   fontWeight: w900, letterSpacing: -0.22)` on the existing token style.
7. **Dishwasher tile glyph (minor, needs design sign-off).** Crop-zoomed: the mock
   draws a padlock/bag-like glyph; the app draws the design-system dishwasher
   appliance (`NestIcons.dishwasher`, per plan §a.8). A padlock on a dishwasher
   quest reads as a mock placeholder error, so the appliance is arguably correct —
   but it is a visible PNG deviation. Fix: designer confirms which glyph wins; if
   the mock wins, the icon asset (shared) must change, not P08.

## Expected / data-driven differences (not defects, no P08 fix)

- **Status bar** (9:41 + mock glyphs vs real 01:05/01:15): OS-drawn; ignored per rules.
- **Date line** "Sat 4 Oct" vs "Fri 2 Oct": live Europe/London date; today is
  Fri 2 Oct 2026. "Happy week: 4 days" matches in both. Correct behaviour.
- **Repeat labels** "· Daily" vs "· Weekly · Sat": every seeded quest defaults to
  `repeat = 'weekly'` (`core/data/seed.dart:181`); the app correctly renders the DB
  value per DATA OVER MOCKS. The design/seed disagreement was never filed as a
  SHARED_REQUEST (Stage 4 B19) — that filing (or a seed decision) is still owed,
  but P08 must not fork the seed.
- **Meta-row width**: follows from the repeat-label difference above; will close
  once the seed decision lands.
- **Banner title wrap** ("…waiting for your / thumbs-up" vs "…waiting / for your…"):
  `text-wrap: balance` has no Flutter mapping (Stage 4 B16); accepted substitution.

## Shared chrome (out of P08 scope, flagged for the orchestrator)

- **Money tab icon**: crop-zoomed — design is a plain credit-card glyph, the app
  (ParentShell, `app/lib/app/`, RULES-shared) renders a banknote-with-circle glyph.
  Today/Quests/Family tabs match. Needs a shared decision, not a P08 edit.

## Dark mode

Same deviation set mirrored; no dark-specific defects. Banner leaf-ink-on-leaf-tint,
kid cards, coin pills, chips and progress all flip correctly through tokens.

## Coverage limit

Viewport shots cover the above-fold only (through Maya row 2–3). Leo's group,
"Put the bins out" / "Make your bed" / "Feed Biscuit the cat" rows and the
"Hand to Maya or Leo" button are below the fold and unverified by these shots.


## From 6_bugs.md
# P08 · Today (home) — bug hunt (Stage 6, iteration 1)

Route `/today` (+ `/today-empty` · P08b), feature `today`, mode parent,
seed `demo`/`empty`. **No screen code was changed.** Added
`app/test/features/today/p08_bugs_test.dart` — 11 proofs, every one
`skip`-marked with its bug id so the suite stays green until the fixes land
(run them with
`flutter test --run-skipped test/features/today/p08_bugs_test.dart` — all 11
fail against iteration-1 code, by design).

Method: read the feature, the shared data layer, the router and the design
references, then probed every edge class in the brief with throwaway Drift
tests; each finding below is reproduced by a committed failing test.

New findings: **P08-B01 … P08-B10** (7 major, 3 minor) + the carried-over
list. The screen cannot pass: `VERDICT: FAIL`.

## New findings (this stage)

### P08-B01 — kid mode can deep-link into `/today-empty` without the parental gate — MAJOR

- **Where:** `app/lib/app/router.dart` (shared) — the `parentOnly` list has
  `/today` but not `/today-empty`; the matcher only expands `/today/…`, so a
  kid-mode deep link to the P08b route renders the full parent Today body.
- **Repro:** `flutter test --run-skipped test/features/today/p08_bugs_test.dart
  --plain-name '[P08-B01]'` → expected `/parental-gate`, actual
  `/today-empty`.
- **Failing test:** `[P08-B01] kid mode cannot deep-link into /today-empty`.
- **Fix:** add `/today-empty` to `parentOnly` (or match on route names rather
  than path prefixes). Shared file → `SHARED_REQUEST.md` §3.

### P08-B02 — kid cards render v1 `pip_stage_*.svg`, not each child's PipAvatar — MAJOR

- **Where:** `today_loaded_body.dart` (`pipStageAsset`, `_KidCard`'s
  `SvgPicture.asset`); `ChildDaySummary` has no pip style/skin/accessory
  fields at all. Violates the mandatory orchestrator rule (products screens
  must use `PipAvatar` with the child's `pip_style / pip_skin /
  pip_accessory / pip_stage`).
- **Repro:** `--run-skipped … --plain-name '[P08-B02]'` → expected 2
  `PipAvatar` (Maya = mochi · sunny · stage 3, Leo = bolt · sky · stage 2),
  actual 0 (two v1 stage SVGs).
- **Failing test:** `[P08-B02] kid cards render each child's own PipAvatar`.
- **Fix (feature-local):** extend `ChildDaySummary` + `watchSummaries()` with
  `pipStyle`/`pipSkin`/`pipAccessory` from `children`, render
  `PipAvatar(style/stage/skin/accessory)` in the same 72×72 centred slot.
  Clamp `stage` to 1..4 (`PipAvatar` asserts) — the DB column has no check.

### P08-B03 — P08b empty card still uses the v1 egg SVG — MAJOR

- **Where:** `today_loaded_body.dart` `_EmptyCard` —
  `SvgPicture.asset(NestlingIllustrations.pipStage1)`. Same mandatory rule:
  never use the v1 `pip_stage_*.svg` in product screens.
- **Repro:** `--run-skipped … --plain-name '[P08-B03]'` with `Seed.empty` →
  expected 1 `PipAvatar` (mochi · sunny · stage 1), actual 0.
- **Failing test:** `[P08-B03] P08b empty state uses PipAvatar (mochi/sunny/1)`.
- **Fix:** `PipAvatar(style: PipStyle.mochi, skin: PipSkin.sunny, stage: 1)`
  at the design's 140×140.

### P08-B04 — children with no assigned quests are invisible on Today — MAJOR

- **Where:** `today_repository_impl.dart` `watchSummaries()` — cards are built
  from `byChild`, a map built from *items*. A child with zero active assigned
  quests (the ordinary state right after P05 "Add a child") never appears in
  `summaries`, so no card, no `NAME · age` group, no hand-off name.
- **Repro:** `--run-skipped … --plain-name '[P08-B04]'` — insert child `Sam`
  with no quests, pump `/today` → expected `find.text('Sam')`, actual none
  (probe measured 0).
- **Failing test:** `[P08-B04] a child with no assigned quests still gets a
  card`.
- **Fix:** build summaries from `watchChildren(familyId)` (all children) and
  attach `done`/`total` from the items; agree the 0-quest copy with design
  ("0 of 0 quests" vs "No quests yet").

### P08-B05 — kids grid is N-up: 3+ children collapse, 5+ children overflow — MAJOR

- **Where:** `today_loaded_body.dart` `_KidsGrid` — one `Row` of `Expanded`
  cards for any child count.
- **Evidence (probes + proofs):**
  - 3 children → all cards on one row: 3 × 110 px; "4 of 6 quests" ellipsises
    to "4 o…" (the number the card exists to show). Distinct card rows: 1 vs
    the design's 2.
  - 6 children → one row of ~50 px cards; each card's interior is 22 px while
    avatar (32) + gap (8) = 40 → **`A RenderFlex overflowed by 18 pixels on
    the right.`** (6 exceptions in one pump).
- **Repro:** `--run-skipped … --plain-name '[P08-B05]'` (two tests).
- **Failing tests:** `[P08-B05] three children keep the 2-up kids grid`,
  `[P08-B05] six children keep the 2-up grid with no overflow`.
- **Fix:** chunk into pairs (Stage 4 B6 snippet) so `.kids` stays the design's
  2 × 170 + gap 10 grid; add the two tests above to the suite.

### P08-B06 — approvals banner undercounts family-wide pending approvals — MAJOR

- **Where:** `today_bloc.dart` `pendingCount = items.where(done_pending)`.
  `items` only contains quests assigned to a child, but P11 (`watchPending
  Approvals(familyId)`) lists every `done_pending` completion — including
  "Anyone" quests. The banner count disagrees with the screen `Review` opens.
- **Repro:** `--run-skipped … --plain-name '[P08-B06]'` — insert a
  `done_pending` completion for the unassigned quest `q-living`, pump
  `/today` → banner expected "4 quests waiting for your thumbs-up", actual
  "3 quests waiting for your thumbs-up".
- **Failing test:** `[P08-B06] banner counts family-wide pending approvals`.
- **Fix:** add `Stream<int> watchPendingCount()` to the repository (COUNT of
  `done_pending` completions for `Seed.familyId`) and use it for
  `pendingCount`; keep `items` for the rows. Do not derive it from per-child
  items (see P08-B04).

### P08-B07 — system back from Review exits the app instead of returning to Today — MAJOR

- **Where:** `today_loaded_body.dart` — Review uses `context.go('/approvals')`;
  `/approvals` is a top-level route and `go` **replaces** the stack, so there
  is nothing to pop. Same for `/quest-editor` (+`?questId`) and P08b's CTAs.
- **Repro:** `--run-skipped … --plain-name '[P08-B07]'` — tap Review, then
  `tester.binding.handlePopRoute()` → expected `true` + `/today`, actual
  `false` and the path stays `/approvals` (probe: Android back / iOS
  swipe-back would exit the app).
- **Failing test:** `[P08-B07] system back from approvals returns to Today`.
- **Fix:** `context.push` for `/approvals` and `/quest-editor` (with and
  without `questId`); keep `go` for shell destinations (`/settings`,
  `/child-profile?childId=`) and the mode switch (`/who-is-playing`). Note in
  `SHARED_REQUEST.md` so P09/P11 return with `context.pop()`.

### P08-B08 — retry after a stream error leaks the failed load's watchers — MINOR

- **Where:** `today_bloc.dart` `emit.forEach(combineLatest2…)` +
  `core/data/stream_combine.dart` (`controller.addError` without close). The
  errored handler never completes, so its subscriptions stay; every "Try
  again" adds another full set of live Drift watchers.
- **Repro:** `--run-skipped … --plain-name '[P08-B08]'` — error an open
  stream, tap Try again → `watchItems` called twice (ok) but the first
  subscription never cancelled: cancels 0, expected 1.
- **Failing test:** `[P08-B08] retry releases the failed load's watchers`.
- **Fix (feature-local):** make the first error terminal before `emit.forEach`
  (`StreamTransformer.fromHandlers`: `sink.addError(e, s); sink.close();`) —
  then the handler completes and cancels; or cancel in `onError`.

### P08-B09 — a single child's card stretches to 350 px, not the design's 170 px column — MINOR

- **Where:** `today_loaded_body.dart` `_KidsGrid` — `if (cards.length == 1)
  return cards.single;`.
- **Repro:** `--run-skipped … --plain-name '[P08-B09]'` — delete Leo, measure
  the remaining kid card → 350.0 px; design `.kids
  {grid-template-columns:170px 170px}` (≤ 175 expected); probe measured
  350.0.
- **Failing test:** `[P08-B09] a single child keeps the 2-up grid card width`.
- **Fix:** pair-chunking alone does not cover the odd count — put the lone
  card in a 2-up row (`Row` + `Expanded` + `Spacer`/`SizedBox(width:170)`).
  If a full-width single card is deliberate, document it in SPACING_SPEC §8
  and close this as a doc deviation instead.

### P08-B10 — quest rows are α-sorted; the design orders pending-first — MINOR

- **Where:** `today_repository_impl.dart` `rows()` — `..sort((a, b) =>
  a.title.compareTo(b.title))`.
- **Repro:** `--run-skipped … --plain-name '[P08-B10]'` — Maya's order is
  `Empty the dishwasher → Hoover the stairs → Lay the table …`; design order
  is done_pending → to_do → approved, which scatters the "Needs a look" rows
  the banner exists to surface.
- **Failing test:** `[P08-B10] quest rows are ordered pending-first like the
  design`.
- **Fix:** sort by `(statusRank, title)` with `done_pending` 0, `to_do` 1,
  `not_yet` 2, `approved` 3, and update `today_repository_test.dart`'s
  α-order assertion in step.

## Carried over from earlier stages (still open)

| Ref | Sev | Item | Where / evidence |
|---|---|---|---|
| C1 | major | Banner "N quests…" + header "Happy week: N days" are not pluralised ("1 quests", "1 days") | `today_loaded_body.dart:361/378`, `today_bloc.dart:59`; 2 suite reds (3_test B1/B2, 4_review B4/B5) |
| C2 | major | Banner subtitle is hard-coded "Your little birds did brilliantly" instead of "Maya and Leo did brilliantly yesterday" built from state | `today_loaded_body.dart:385`; 1 suite red (4_review B3) |
| C3 | major | Quest-row gap is 8 px on every row; spec/plan say 16 px (8 only label→first) | `today_loaded_body.dart:240`; 4_review B2 / 5_ui §3 |
| C4 | minor | Greeting renders Nunito 800, design 900 / −0.22 tracking | `today_loaded_body.dart:288`; 4_review B9 / 5_ui §6 |
| C5 | minor | Banner `Semantics(liveRegion, label:)` duplicates its children in the announced node | `today_loaded_body.dart:359-361`; 3_test B4a / 4_review B10 |
| C6 | minor | `NestSectionLabel` exists but group labels are hand-rolled (loses `header: true`) | `today_loaded_body.dart:566`; 4_review B12 |
| C7 | minor | Dead `TodayItem.detail` + `_statusLabel` (second source of status copy) | `today_repository_impl.dart:121/136`; 4_review B13 |
| C8 | minor | Raw `error.toString()` rendered to the parent | `today_bloc.dart:66` / `today_loaded_body.dart:698`; 4_review B15 |
| C9 | minor | `text-wrap: balance` banner wrap cannot match the mock — accepted substitution, note only | 4_review B16 |
| C10 | minor | `liveRegion` banner re-announces on unrelated stream emissions | `today_loaded_body.dart:360`; 4_review B17 |
| C11 | minor | P08b divergences beyond this screen ID's design refs (header "A fresh nest", long message, "Browse ideas" as a link, "Tip for new nests" card) | 3_test §4; 4_review B21 covers the 36 px inset |
| C12 | minor | Hand-off copy for 3+ children ("Hand to Maya and friends") | `today_loaded_body.dart:630`; 4_review B20 |
| C13 | shared | `NestCard`/`NestQuestCard` semantics duplication + 4 px vs 6 px runSpacing | `SHARED_REQUEST.md` §2; 4_review B18 |
| C14 | doc | DESIGN_SPEC §5 P08 still describes a floating "+ New quest" pill the design does not have | 4_review B22 |
| C15 | test debt | `today_repository_test.dart` asserts `q-dishwasher` repeat `'weekly'`, but the mid-iteration seed merge `e94d063` made it `'daily'` (DATA OVER MOCKS: the DB is right). One suite red — update the expectation (and keep `q-bins`/`q-hoover` `weekly`) in the fix stage. | 4th suite red |

## Checked, no bug found

- **Rapid double taps** — `+`, `Review`, quest rows, Hand: `go` is
  idempotent, one editor page, no exception (probe).
- **State after restart (Drift persistence)** — approve everything, dispose
  the app, relaunch: banner stays hidden, "Approved ✓" persists (probe).
- **Timezone Europe/London / BST** — `toLondon` boundaries (last Sunday
  March/Oct, 01:00 UTC) are correct; P08 renders the live date (Fri 2 Oct
  2026, not the mock's Sat 4 Oct — expected).
- **Long UK names** ("Maximilian-Alexander") at 320 px / 1.3× — no overflow
  (name ellipsises per plan §e).
- **Coins edges** — 9999 coins (kid card + quest pill) and 0-coin quests
  render at 320 / 1.3×; P08 never shows £, so £0.00/£999.99 and integer-pence
  rounding do not apply here.
- **Dark-mode contrast** (computed WCAG ratios): ink/surface 16.5/14.8,
  ink2/paper 8.3/10.8, leaf link/paper 4.6/8.7, coin chip 7.0/9.6, leaf chip
  7.1/8.5, banner subtitle (85 % alpha) 5.0/6.6 — all ≥ 4.5 in both themes.
- **Empty seed at 320 px / 1.3×** — no overflow.
- **Async gaps / emit after close** — bloc 9.2.1 cancels the `forEach`
  subscription when the bloc closes, so P08 has no post-close emission path.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → `344 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test` (full) → **+337 −4 ~11**. The −4: C1 ×2, C2 ×1 and C15 ×1
  (the stale seed assertion); the ~11 are this stage's skipped proofs. None
  of the four is caused by this stage (all four reproduce on the unmodified
  working tree).

## Verdict

Seven new major bugs (B01–B07) — a guard bypass, a mandatory Pip-rule
violation on both surfaces, invisible children, a collapsed/overflowing kids
grid, an approvals count that lies, and back navigation that exits the app —
plus B08–B10 and the 15 carried items. No PASS is possible.

