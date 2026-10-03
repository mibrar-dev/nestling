# P09 — stage 6 · FIND BUGS (iteration 2)

Tree: `5c25db1` (“P09: checkpoint after build (iteration 2)”) + the new proofs
below. No screen code was changed — the brief forbids fixing here.

Adversarial area sweep (iteration 2): the five iteration-1 bugs re-verified,
then new probes over the changed code — data edge cases (0 / 1 / 6 children,
emoji-leading and long UK names, £0.00 / £999.99 / 9999 coins), rapid double
taps on every popping control, back navigation and deep links, Drift restart
persistence, the parent/kid guard (with query strings), dark-mode contrast,
320 dp × text scale 1.3, async gaps, Europe/London wall-clock storage and
integer-pence money.

All proofs live in `app/test/features/quests/p09_bugs_test.dart`. Iteration-2
bug proofs are `skip: true` (bug id in the group name) so the suite stays
green; run them with `--run-skipped` to see them fail. Every probe in the
“attacks that hold” group runs unskipped.

## Iteration-1 findings — all FIXED, proofs unskipped and green

| id | what was wrong | iteration-2 fix (where) |
|---|---|---|
| BUG-P09-1 | payout helper hard-coded 1p/coin | view streams `watchCoinValuePencePerCoin()` (`quests_repository_impl.dart:26`, view `:405`) |
| BUG-P09-2 | double-tap Save created the quest twice | local `_saving` guard + pill disabled while saving (`:362`, `:458-465`, `:663`) |
| BUG-P09-3 | non-picker icon showed no selected tile | `_questIcons.aliases` covers every seeded key (`:257-280`) |
| BUG-P09-4 | out-of-range coins unreachable after a tap | `_coinFloor`/`_coinCeiling` grow to the stored value (`:328-333`, `:787-792`) |
| BUG-P09-5 | removed child left an orphaned assignee | roster-unknown assignee falls back to `Anyone` (`:367-384`) |

All five proofs now run unskipped in the suite (5 of the 18 passing tests in
the file). No regression.

## Summary — iteration 2

| id | severity | one-liner | failing test (group › test) |
|---|---|---|---|
| BUG-P09-8 | **major** | an emoji-leading child nickname makes the editor throw `ArgumentError: string is not well-formed UTF-16` while painting the avatar (the screen fails to paint) | `BUG-P09-8 — an emoji-leading nickname breaks the avatar initial` › `the initial is the full first grapheme, not a lone surrogate` **and** `painting the lone surrogate throws a UTF-16 error` |
| BUG-P09-6 | minor | an out-of-range reward is shown at face value (9999 / `= 9999p`, or 0 / `= 0p`) but silently clamped on save (writes 100 / 1) | `BUG-P09-6 — an out-of-range reward is shown at face value, saved clamped` › `the screen says 9999 / 9999p and the write says 100` **and** `a 0-coin quest is shown as 0 / 0p and saved as 1` |
| BUG-P09-7 | minor | tapping the alias-highlighted tile (Dishes for `plate`) is visually a no-op but rewrites the stored icon key to the tile key | `BUG-P09-7 — tapping the alias-highlighted tile rewrites the stored key` › `q-table (plate) saves dishwasher after a no-op-looking tap` |

---

## BUG-P09-8 — major — an emoji-leading nickname breaks the editor paint

**Where:** `_initial` (`quest_editor_view.dart:738-740`) —
`nickname.substring(0, 1).toUpperCase()` — fed to `NestAvatar.initial`
(`:724`).

**Why it is wrong:** `String.substring` slices UTF-16 code units, not
graphemes. A nickname beginning with an astral-plane character (`😀`, flags,
most emoji) has a surrogate pair at index 0, so `substring(0, 1)` returns the
lone high surrogate. P05 accepts any non-empty nickname up to 24 UTF-16 units
(`family_bloc.dart:66-71`, no input formatter), so this is reachable from the
app’s own add-child flow. Flutter’s paragraph builder then rejects the
malformed string — the editor fails to paint:

```
ArgumentError: Invalid argument(s): string is not well-formed UTF-16
  at _NativeParagraphBuilder.addText
```

Not a font/rendering artifact: `addText` validates well-formedness, so it
throws in release too, not just debug.

**Repro:**
```dart
// child nickname '😀 Sam' inserted directly (P05's own rules allow it)
await pumpAppRoute(tester, QuestsRoutePaths.editor);
final avatars = tester.widgetList<NestAvatar>(find.byType(NestAvatar));
expect(avatars.last.initial, '😀');          // actual: lone surrogate '\uD83D'
expect(tester.takeException(), isNull);      // actual: ArgumentError above
```
Two skipped tests prove each half: the initial is `'\uD83D'` (renders `�`),
and the pump throws the UTF-16 `ArgumentError`.

**Suggested fix:** take the first grapheme, not the first code unit —
`nickname.characters.first.toUpperCase()` (`characters` is exported by
`package:flutter/foundation.dart`, already imported via Material), with the
existing `isEmpty → '?'` fallback. Add a unit test for `😀`, a flag emoji and
a combining-mark name.

## BUG-P09-6 — minor — out-of-range reward shown at face value, saved clamped

**Where:** `_save` writes `coins: _coins.clamp(_minCoins, _maxCoins)`
(`quest_editor_view.dart:478`) while the stepper and the helper render the
raw `_coins` (`:773`, `:784`).

**Why it is wrong:** the editor deliberately shows a corrupt stored value as
stored (BUG-P09-4 fix: the stepper can reach it), but the write silently
repairs it. The screen promises one number and stores another: a 9999-coin
quest shows `9999` and `= 9999p at payout`, and Save writes **100**; a
0-coin quest shows `0` / `= 0p` and writes **1**. The repository’s own
comment says a corrupt value should “fail loudly instead of being silently
rewritten” (`quests_repository_impl.dart:92-96`) — the view clamp means that
path is unreachable from the editor, and the parent is never told the reward
changed.

**Repro:** insert `coins: 9999` (or `0`), open `?id=…`, Save without touching
the reward; `getQuest` returns `100` (or `1`), while the screen showed the
original.

**Suggested fix:** make the mismatch impossible instead of silent — when
`_coins` is outside 1..100, disable Save and show a live-region caption (the
same pattern as `Pick at least one day`), e.g. `Coins must be 1–100`, so the
parent explicitly steps it into range; keep the widened stepper bounds so the
repair is always reachable. (Alternative: don’t clamp and let the repo’s
validation surface the toast — but then an untouched corrupt row cannot be
saved at all.)

## BUG-P09-7 — minor — tapping the alias-highlighted tile rewrites the key

**Where:** the tile call site (`quest_editor_view.dart:677-678`) —
`selected: selected == option.key || option.aliases.contains(selected)` with
`onTap: () => setState(() => _icon = option.key)`.

**Why it is wrong:** for a quest stored as `plate`, the Dishes tile is
highlighted through the alias, so it already looks selected; tapping it is
visually a no-op, yet it rewrites `_icon` to `dishwasher`. Save then stores
the normalised key and the library/today glyph changes — the parent cannot
see that their tap changed anything. Same for `bins`→`bin` (a seeded quest,
`q-bins`), `bag`/`shirt`→`bin`, `leaf`→`paw`, `sofa`→`bed`. A radio that is
already checked is normally inert.

**Repro:** open `?id=q-table` (icon `plate`); assert the Dishes tile is
selected; tap it; Save; `getQuest('q-table').icon` is `dishwasher`
(expected `plate`).

**Suggested fix:** ignore the tap when the tile is already the visual
selection — compute `isSelected` first and only `setState(_icon = option.key)`
when `!isSelected` — so an alias-highlighted tile keeps the stored key unless
the parent picks a *different* tile.

---

## Attacks that hold (probes, unskipped — 13 tests)

- **Rapid double taps:** double-tap `Delete quest` → one confirm modal;
  double-tap `Due by` → one option sheet; double-tap `Cancel`, a due-sheet
  row and `Keep it` never pops a second route (all swallowed by the
  route/modal transition). Double-tap **Save** is now guarded (iteration-1
  proof runs green).
- **Restart persistence:** save → dispose the app → new `NestlingApp` over
  the same Drift DB → the quest is on the library’s Active tab.
- **Parent/kid guard:** kid mode + `/quest-editor` (plain **and** with
  `?id=`) lands on `/parental-gate`; the editor never builds.
- **320 dp × text scale 1.3**, new and edit mode: no overflow/exception.
- **One-child family:** the new quest defaults to that child.
- **Six children with long names** (`Maximilian-Alexander`,
  `Annabella-Rose`, `Cassandra-Jane`, `Fitzwilliam`) at 320 × 1.3: pills wrap,
  creation order preserved, `Anyone` last.
- **Dark mode:** the Save pill’s `--surface` on `--leaf` pair keeps ≥ 4.5:1
  contrast.
- **Back navigation:** a quest pushed from Today (`?questId=`) → Cancel
  returns to `/today`.
- **Zone/BST:** with the family moved to `Asia/Dubai`, the due time is still
  stored as the wall-clock string `17:00` (`dueLabel` `Before tea (5pm)`).
- **A11y actions:** all three due-sheet rows expose `SemanticsAction.tap` and
  `performAction(tap)` moves the real due label (and the saved `HH:MM`);
  `Keep it` / `Delete` expose tap and `Keep it` keeps the Drift row.
- The 0-child / `Seed.empty`, unknown-id, blank-title and weekly-no-days edges
  stay covered by the existing feature suites (green).

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:29 +18 ~5: All tests passed!        # 13 probes + 5 fixed iteration-1 proofs
$ flutter test test/features/quests/p09_bugs_test.dart --run-skipped
00:12 +18 -5: Some tests failed        # the five iteration-2 proofs fail as documented
$ flutter test
01:48 +2563 ~6: All tests passed!      # whole app; ~6 = 5 new proofs + P12-BUG-05
```

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (`quest_editor_coin_rules_test.dart`,
`quest_editor_data_integrity_test.dart`, `quest_editor_states_test.dart`,
`5_ui.md`, UI PNGs). It was left untouched; at the time of writing those
files’ two `flutter analyze` infos are theirs, not this stage’s.

VERDICT: FAIL
