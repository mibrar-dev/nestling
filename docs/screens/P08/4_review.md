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

VERDICT: FAIL
