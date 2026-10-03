# P09 — stage 3 · TEST (iteration 2)

Scope: `app/test/features/quests/**` only. No screen code, no shared code and
no `tools/` touched; `flutter clean` never run; no simulator booted, installed
on, screenshotted or driven; no `skip:` added, no test weakened, no
`analysis_options.yaml` change; `google_fonts` appears nowhere.

Iteration 1's 56 tests are still here and still pass against the iteration-2
tree (`5c25db1`), which is itself worth recording: the fixes landed without
breaking a single assertion from the previous round.

## 1. What iteration 2 changed, and what this stage adds

Stage 2 (`2_build.md`) fixed the iteration-1 findings. A test stage's job
after a fix round is to prove the *fix*, not the symptom the bug hunt
reported — so every test below targets the mechanism, and none of them repeats
a stage-6 proof.

| Fix | Where it lives | What this stage proves (beyond `p09_bugs_test.dart`) |
|---|---|---|
| BUG-P09-1 rate from the database | `watchCoinValuePencePerCoin()` + `_pencePerCoin` field | 5p and 2p families; a **live** rate change while the form is open; the rate never scales the coin count; the stored value stays in coins, not pence |
| BUG-P09-2 save guard | `_saving` + `QuestSavePill(onPressed: _canSave && !_saving)` + `clearSaveGuard()` | the pill goes dead **while the write is in flight**; three taps dispatch **one** write; a **failed** write releases the guard so a retry reaches the repository again |
| BUG-P09-3 icon aliases | `_questIcons.aliases` | all six legacy keys map to the right tile and light **exactly one**; the stored key survives a save that did not tap a tile; tapping a *different* tile still rewrites it; the six tiles draw the design glyphs in design order |
| BUG-P09-4 coin bounds | `_coinFloor` / `_coinCeiling` + `_save` clamp | 9999 opens as 9999 and **writes nothing**; `−` walks it back; a 0-coin row shows 0 with `−` inert (no InkWell handler *and* no tap action) and `+` climbing to 1; an in-range row is never rewritten |
| BUG-P09-5 orphan assignee | `_isKnownAssignee` fallback | the dangling id shows as **Anyone**, exactly one pill active, and **Save clears the id**; a *listed* assignee is never hijacked by the fallback |
| review 9 archived rows | `active: initialQuest?.active ?? true` | editing an archived quest changes its title but leaves `active: false`; a new quest is stored active |
| review 5 `detail` | view no longer writes a copy | after changing coins and repeat, the stored `detail` is the repository's recomputation (`Once · 21 coins`) |
| review 11 roster | one `initState` subscription | the roster is **live**: a child inserted on another screen appears, last, in creation order — a latched snapshot would fail here |

## 2. Tests added this iteration (31)

| File | Before → after | New tests |
|---|---|---|
| `quest_editor_coin_rules_test.dart` (**new**) | — → 9 | 5 rate + 4 coin-range |
| `quest_editor_data_integrity_test.dart` (**new**) | — → 18 | 9 icon-alias/glyph, 5 assignee, 4 archived/detail/days |
| `quest_editor_states_test.dart` | 17 → 20 | 3 save-guard (the `_FaultyRepository` grew a `holdWrites` mode) |
| `quest_editor_bloc_test.dart` | 6 → 7 | 1 bloc path: the repository's coin contract surfacing as `editorStatus.failure` |

Nothing else moved. The three fault-injection groups from iteration 1
(`holdGet`, `failFirstWatch`, `failWrites`) are unchanged; `holdWrites` was
added beside them.

### 2.1 `quest_editor_coin_rules_test.dart`

`Seed.demo()` sets the rate to 1, so the seeded screen looks right whether or
not the helper reads the database — the whole bug class is invisible until the
family's row says otherwise, so each test writes `families` (or a corrupt
quest row) straight into Drift. Corrupt rows have to bypass the repository:
`QuestsRepositoryImpl._checkCoins` now rejects out-of-range coins on write *by
design*, which is exactly why the row has to be planted below the data layer.

- 5p/coin → `= 75p at payout` for 15 coins (and no `= 15p` anywhere).
- A rate change **while the editor is open** (write `families`, pump) → the
  helper follows: `= 60p at payout`. This is the stream path; a value latched
  in `build` would fail here.
- The rate never scales the stepper: the value stays `15`, the helper becomes
  `= 60p`.
- The rate multiplies after a stepper move: 16 coins at 2p → `= 32p at payout`.
- Saving stores **coins**, not pence (15 coins at 5p → row `coins == 15`).
- 9999 opens as `9999` / `= 9999p at payout` and the row is still 9999 after
  the open (no write).
- `−` walks 9999 → 9998 with the helper following.
- 0 opens as `0` / `= 0p at payout`, `−` is inert for the finger (no InkWell
  handler) *and* for VoiceOver (no `SemanticsAction.tap`), `+` climbs to 1.
- An in-range row (20 coins) survives open → Save unchanged.

### 2.2 `quest_editor_data_integrity_test.dart`

One test per legacy icon key (`sofa`→Bed, `plate`→Dishes, `bins`/`shirt`/`bag`
→Bins, `leaf`→Paw), each asserting the mapped tile is selected **and** that
exactly one tile is selected — a radiogroup with two highlighted tiles is
worse than none. Plus: the stored key survives a save without a tap; a tap on a
*different* tile rewrites it; the six tiles' `label` and `icon` match the
design's order and glyphs (`NestIcons.basket` for Dishes, per 2b's
ORCHESTRATOR_NOTES 17:57 item 1 answer).

Assignee: a dangling `assigneeChildId` (no FK column, so the id really can
survive a deleted child) shows as Anyone, exactly one pill active, and Save
stores `null`; a listed assignee (`leo`) is untouched by the fallback, so the
fix cannot over-fire; a new quest still defaults to Maya (creation order, never
alphabetical); and the roster subscription is **live** — inserting
`Annabella` while the form is open appends her pill before Anyone.

Archived/detail: an archived quest (`active: false`) can be edited without
being resurrected; a new quest is stored active; `detail` is the repository's
recomputation; switching a weekly quest to Once clears the stored day CSV.

### 2.3 Save guard (in `quest_editor_states_test.dart`)

`_FaultyRepository.holdWrites` parks each write on a `Completer` the test
releases, which is the editor's in-flight state:

- **pill dead while in flight**: `onPressed == null`, one dispatch, no
  navigation; release → `/quests`.
- **three taps, one dispatch**: `written.length == 1`, and after the release
  exactly one row titled `Hoover the stairs` exists.
- **a failed write releases the guard**: `clearSaveGuard()` runs before the
  toast, so the pill is live again and a second tap reaches the repository
  (`written.length == 2`). Without that release the editor would be stuck with
  a dead Save and no way out — the failure mode this test exists for.

### 2.4 One more bloc path

`quest_editor_bloc_test.dart`: a repository that throws
`ArgumentError.value(9999, 'coins', 'Quest coins must be 1..100')` must surface
as `editorStatus.failure` + an `editorError` containing the message. The view
clamps before dispatching, so this is the last line of defence — and it is the
only new wiring the iteration-2 interface addition introduced.

## 3. Results

```
$ dart format --set-exit-if-changed .
Formatted 494 files (0 changed) in 3.94 seconds.          (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.7s)

$ flutter test test/features/quests/
00:52 +367 ~5: All tests passed!

$ flutter test
04:25 +2562 ~6: All tests passed!
```

The `~6` skips are stage 6's parked bug proofs (BUG-P09-6/7/8 in
`p09_bugs_test.dart`, `skip: true` until their fix lands) plus the
pre-existing repo skip in `test/features/pocket_money/p12_bugs_test.dart:320`.
Nothing this stage skips.

Process note, not a finding: at 18:52 one feature run reported
`p09_bugs_test.dart BUG-P09-1` red while stage 6 was rewriting that file
(its mtime moved under the run). Re-run afterwards: green. The loop owns merge
and file ordering.

## 4. Bugs found

### P09-TEST-2 — major — an emoji-leading nickname crashes the editor

- File: `app/lib/features/quests/presentation/views/quest_editor_view.dart:738-739`
  ```dart
  static String _initial(String nickname) {
    return nickname.isEmpty ? '?' : nickname.substring(0, 1).toUpperCase();
  }
  ```
  `substring(0, 1)` splits the surrogate pair of an astral-plane first
  character, so the pill is painted with a lone surrogate.
- Repro: any child whose nickname starts with an emoji (`😀 Sam`). Insert such
  a row into `children` (`nickname: '😀 Sam'`), open `/quest-editor`, and the
  screen throws while painting the assignee pill. Measured in a throwaway probe
  on the current tree: `ArgumentError: Invalid argument(s): string is not
  well-formed UTF-16`. The whole screen fails to render — no form, no error
  state, nothing recoverable but a restart.
- Reachability: P05 allows any non-empty nickname up to 24 UTF-16 units, emoji
  included, so a parent can create this row from the app itself.
- Status: stage 6 filed the same defect concurrently as **BUG-P09-8** (proof
  `p09_bugs_test.dart:336`, `skip: true`); my probe was an independent
  reproduction, not a second report. The fix is the first grapheme
  (`characters.first`, or guard the code-unit length) — I did not patch it.
- **This is why the stage verdict is FAIL.**

### P09-TEST-1 — carried over from iteration 1 (still open)

The shared `NestStepper` renders its minus as U+002D while both designs print
U+2212 (`nest_stepper.dart:32`; `SHARED_REQUEST.md` §5, advisory, unresolved
on `main`). `quest_editor_copy_test.dart` still excludes the glyph from its
set-equality audit and says so in the file header, so the audit stays green
while the request is open.

### Constrained by stage 6's open findings (deliberate, not a bug in my tests)

Stage 6 filed **BUG-P09-6** (an out-of-range reward is shown at face value —
`9999`, `= 9999p` — but silently clamped to 100 on save) against the same rows
my coin-range tests read. I removed the two assertions that pinned the clamp
so this suite does not break the moment the fix lands. What remains is what
survives either answer: *opening* the editor writes nothing, and the parent can
walk the value back into range with `−`/`+`. The save-time decision (store what
was shown, or block the save with a visible reason) belongs to
`p09_bugs_test.dart`. **BUG-P09-7** (tapping an alias-highlighted tile rewrites
the stored key) does not conflict with my tests: mine tap a *different* tile
and assert that still rewrites.

## 5. Notes for the next stages

- **Flip points when the fixes land:** `quest_editor_copy_test.dart` gains
  `−` in `kGlyphs` when `SHARED_REQUEST.md` §5 resolves;
  `p09_bugs_test.dart` un-skips BUG-P09-6/7/8; and if BUG-P09-6's fix changes
  what the editor *shows* for an out-of-range row, the display assertions in
  `quest_editor_coin_rules_test.dart` ('a 9999-coin quest opens showing 9999',
  'a 0-coin quest shows 0') move with it — they are the only two assertions
  that describe the current tree rather than an invariant.
- **Deliberately untested:** review finding 7 (`buildWhen` keeps the form from
  rebuilding on `items` emissions) is a performance property with no observable
  contract; a build-count probe would be brittle without proving anything a
  parent can see.
- **Observation, unreachable from the app's own navigation:**
  `QuestEditorView.didChangeDependencies` fetches `?id=` once
  (`if (_loadedQuest != null) return`), so navigating straight from
  `/quest-editor?id=a` to `/quest-editor?id=b` on the same `State` would keep
  showing quest `a`. Every in-app path pushes a new page instead, so this is
  not reachable today; it is noted so a future "switch to another quest from
  this screen" affordance does not inherit it silently.
- Every widget test here ends with `disposeApp(tester)`, and every semantics
  handle is disposed **inside** the test body.

VERDICT: FAIL