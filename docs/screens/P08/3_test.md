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

VERDICT: FAIL
