# K04 Quest detail — Stage 3 test (iteration 4)

Scope: close the ICONS-rule coverage I owed from iteration 3, re-verify, and
report bugs. Inputs: `ORCHESTRATOR_NOTES.md` (14:28 / 15:08 / 16:38),
`6_bugs.md` (iteration 3), `RULES.md`.
**No simulator was booted, installed on or driven** (stage 5 only).

## Verdict: PASS

Both halves of the brief's bar now hold, and this time neither is propped up by a
skip:

- **All tests pass** — `flutter analyze` clean, **3721** suite tests green, K04
  alone at **76** cases.
- **No open bug** — K04-BUG-5 was closed by orchestrator ruling at 16:38 (accept
  the shared kid glyph at stroke 2), its proof rewritten live and passing, and
  `5_ui.md` is now `VERDICT: PASS`. Iteration 3's two blockers are both gone.

K04's skip inventory is **zero** skips of its own (`~3`–`~4` suite-wide are
other screens' and pre-existing).

## Tests added this iteration — 7 cases, all new

`app/test/features/kid_home/quest_detail_icon_audience_test.dart` (NEW). This is
exactly the guard iteration 3 designed and failed to write. It exists because the
existing K04-BUG-3 proof hard-codes four quest ids and four assets, which cannot
catch the failure that actually happened: a silent revert to `audience: parent`
with the hard-coded list edited in step.

**Layer 1 — the audience table (pure, 3 cases).** Walks `questIconKeys`, the
shared list of every icon the demo seed can write, and asserts kid/parent diverge
for *exactly* `{bed, dishwasher, book}` and agree for every other key. This
catches both directions of drift: a shared key quietly switched to a kid asset,
and a parent-only key given one. Plus: unknown keys fall back to `questCard` for
both audiences, and the three kid assets are genuinely different files from their
parent namesakes — the rule's basis has to be a real asset swap, not a naming
difference pointing at one file.

**Layer 2 — the rendered tile, against the real seeded DB (3 cases).** For each of
Maya's seeded quests the `icon` key is read **from the database** (DATA OVER
MOCKS — a seed change cannot desync the proof), the detail route is pushed, and
the painted 64 px tile glyph must equal `questIconFor(icon, audience: kid)`; for
the three divergent keys it must additionally **not** equal the parent glyph.
That last assertion is the one the hard-coded list could not make. The sweep also
self-checks that Maya really owns a quest for each divergent key, so the test
cannot quietly stop covering them. A companion case proves the tile follows the
**icon column** rather than the quest id (two quests, same title and coins,
`bed` vs `book`, render different glyphs), and the direct-launch `q-tidy`
fallback path honours the audience rule too.

**Layer 3 — the guard bites (1 case).** Runs the same screen with the kid glyph
and with `questIconFor('bed', audience: parent)` and requires the two assets to
**differ**. Without this, layers 1–2 could pass for the wrong reason — e.g. if
the tile ignored the icon key entirely and some unrelated assertion happened to
hold. Deliberately done without patching the screen, which RULES §1 forbids.

## Results (real runs)

```
$ dart format test/features/kid_home/
$ flutter analyze
No issues found! (ran in 4.0s)

$ flutter test --timeout 120s test/features/kid_home/quest_detail_icon_audience_test.dart
00:01 +7: All tests passed!

$ flutter test --timeout 120s test/features/kid_home
00:14 +559 ~3: All tests passed!

$ flutter test --timeout 120s
01:36 +3721 ~4: All tests passed!
```

`analysis_options.yaml` untouched; no test skipped, weakened or deleted; the
screen was not modified — the only file I wrote is the new test. Nothing outside
`app/test/features/kid_home/**` and `docs/screens/K04/**` was touched.

## Bugs found

**None.** Iteration 3's outstanding items both closed, and neither closed at my
expense or by weakening anything:

- **K04-BUG-5 — CLOSED AS ACCEPTED (orchestrator ruling 16:38).** The 2-vs-1.8
  stroke conflict is resolved by accepting the shared kid glyph at 2 ("one
  consistent kid set; invisible at 64 px"). I verified the shipped asset still
  reads `stroke-width="2"` and that the rewritten proof runs live and green
  (the skipped 1.8 expectation is gone). No screen change was needed, which is
  the correct outcome for a shared-asset conflict.
- **K04-BUG-4 — stays fixed**, its proof live and un-skipped.

Not a bug, recorded so nobody re-opens it: I verified the ICONS-rule screen
assertion is genuinely load-bearing by checking the parent and kid `bed` assets
resolve to different files, so a future revert is caught by assertion rather than
by a code review noticing.

## Coverage now in place for K04 (76 cases, 5 files)

| file | cases | covers |
|---|---|---|
| `quest_detail_icon_audience_test.dart` | 7 | ICONS audience rule — table invariant, real-DB sweep, column-driven, guard-bites (new this iteration) |
| `quest_detail_view_test.dart` | 28 | copy + reward + steps + semantics actions, completion channel, all four routes, loading/failure/missing/no-child, `Seed.empty` on the real repo, non-loaded states at 320 px @ 1.3× in both themes |
| `quest_detail_matrix_test.dart` | 19 | `{light,dark} × {320,390,430} × {1.0,1.3}`: overflow, 20 px gutters at every width (ALIGNMENT), bottom-edge rule structurally and geometrically in both modes |
| `quest_detail_touch_targets_test.dart` | 10 | ≥56/≥44 as a rule at 6 cells + edge-reachability probes |
| `quest_detail_bloc_test.dart` | 9 | every K04 event/state path, the load guard, retry-after-failure, `stepsFor` incl. the real seeded DB |
| `quest_detail_geometry_test.dart` | 3 | light-390 rect pins vs the design PNG (owned by iteration 2) |

Every mandated dimension in the brief now has coverage: bloc paths, both themes,
all three widths, both text scales, empty/loading/error, every tap's destination,
semantics on icon buttons, and tap targets.

## Not findings / process

Per the orchestrator rules these are not reported as blockers: the uncommitted
stage 4/5/6 artefacts in the worktree (`5_ui.md`, `6_bugs.md`, `ui/*.png`) and
merge order. `quest_detail_copy_parity_test.dart` remains intentionally absent —
copy parity is a group inside the view test, so no coverage is lost and creating
it now would be pure churn.

VERDICT: PASS
