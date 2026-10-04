# P09 — stage 6 · FIND BUGS (iteration 6)

Tree: `dfc7011` (“P09: checkpoint after build (iteration 6)”, unique-ids
migration + toggle re-centring) + the verification below. No screen code was
changed — the brief forbids fixing here.

Adversarial area sweep (iteration 6): the fourteen earlier proofs re-run,
then new probes over the iteration-6 changes — `newId('q')` uuid ids (IDS
rule), the re-centred approval toggle (`LayoutBuilder`, P09-TEST-9), the
clock pinning — and the usual edge set: 0 / 1 / 6 children, emoji-leading and
long UK names, £0.00 / £999.99 / 9999 coins, rapid double taps, back
navigation and deep links (including the new uuid id format), Drift restart
persistence, the parent/kid guard, dark-mode contrast, 320 dp × text scale
1.3, async gaps, Europe/London wall-clock storage and integer-pence money.

**No new bugs found this iteration.** All fourteen findings from iterations
1–5 are fixed, and every proof now runs unskipped: the file has **32 passing
tests, 0 skips** (19 proofs + 13 probes).

## All findings — fixed and proven

| id | what was wrong | fix | proof |
|---|---|---|---|
| BUG-P09-1 | payout helper hard-coded 1p/coin | streams `watchCoinValuePencePerCoin()` | green |
| BUG-P09-2 | double-tap Save created the quest twice | `_saving` guard + pill disabled | green |
| BUG-P09-3 | non-picker icon showed no selected tile | aliases cover every seeded key | green |
| BUG-P09-4 | out-of-range coins unreachable | bounds widen to the stored value | green |
| BUG-P09-5 | removed child left an orphaned assignee | roster-unknown falls back to `Anyone` | green |
| BUG-P09-6 | out-of-range reward silently clamped | Save blocked + live-region caption | green |
| BUG-P09-7 | alias tile tap rewrote the stored key | selected tile’s tap is inert | green |
| BUG-P09-8 | emoji nickname threw a UTF-16 paint error | `_initial` takes the first grapheme | green |
| BUG-P09-9 | card 68 / track 307,618.5 after batch 5 | uniform padding + no Transform | green |
| BUG-P09-10 | 59×44 hit slop clipped by the 40-high row | Stack-overlaid toggle, full-slop stack | green |
| BUG-P09-11 | 9999 needed 9899 taps to repair | first step jumps to the boundary | green |
| BUG-P09-12 | legacy glyphs on four tiles | `questBed/questDishes/questHoover/questBins` | green |
| BUG-P09-13 | debug range guard leaked raw assert text | `_checkCoins` throws `ArgumentError` only | green |
| BUG-P09-14 | clock-derived id collided under the pinned clock | `newId('q')` (uuid v4, IDS rule) | green |

## Iteration-6 verification (measured at HEAD)

* **Unique ids (BUG-P09-14 / IDS rule).** A create mints
  `q-<uuid v4>` (`newId('q')`, `core/data/ids.dart`; e.g.
  `q-1341e444-faff-475b-a897-cba5e8429068`). Two creates in one session both
  persist (the rewritten proof: plain editor create, then P10 `+ Add` create —
  both rows exist, the editor closes after each). A scratch probe also
  confirmed a deep link with the new uuid id
  (`/quest-editor?id=q-1341e444-…`) opens edit mode with the stored title and
  the `Delete quest` affordance.
* **Toggle centring (P09-TEST-9).** At 390×1.0 / 390×1.3 / 320×1.0 / 320×1.3
  the track is centred on the card by layout (centre delta **0.00** at every
  metric; right gap 16.00), and the 59×44 hit area works at every metric
  (taps 5 px above, 5 px below and 2 px right of the track all flip it).
  The 1.0 rect remains the design’s `303 / 620.5 / 51 / 31`.
* **Clock pinning.** The whole-app suite is fully green again; the
  iteration-4 real-date-rollover failures are gone.
* **Everything else** (13 unskipped probes): double-tap Delete/Due-by/Cancel/
  due-row/Keep-it; restart persistence; kid-mode guard plain + `?id=`;
  320 dp × 1.3 new + edit; one-child default; six children with long names;
  dark-mode Save-pill contrast; Today → Cancel → Today; Dubai wall-clock due
  time; due-sheet and delete-modal `performAction(tap)`.

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:04 +32: All tests passed!           # 19 proofs + 13 probes, 0 skips
$ flutter test test/features/quests
00:27 +418: All tests passed!
$ flutter test
03:03 +3129 ~2: All tests passed!
```

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (briefs, review/UI notes, a toggle hit-area test
being expanded). One whole-app run raced a mid-write edit of
`quest_editor_toggle_hit_area_test.dart` and reported a transient load
failure; the file passes standalone (+7) and the settled tree-wide run is
green. Not a P09 finding.

VERDICT: PASS
