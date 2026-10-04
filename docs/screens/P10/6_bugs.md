# P10 · Quest library — bug hunt (Stage 6, iteration 4 — last pass)

Route `/quests` · feature `quests` · parent mode · seeds `Seed.demo()` (12
active quests) and `Seed.empty()` (0) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. Tree tested: iteration-4 build checkpoint
`60f34fe`, with the shared search-field fix `1db0f8a` (54-high box, centred
hint/text) merged as `686ce06` and `segmented_semantics` `ab1ba06` merged as
`0cdb53c`. `ORCHESTRATOR_NOTES.md` (09:46, 10:00, 12:17, 13:42 — last pass)
re-verified.

**Result: no P10-local bugs remain, and this iteration's adversarial probes
found nothing new.** Every id from iterations 1–3 is fixed and guarded by an
un-skipped green proof; the feature suite is fully green
(**192 passed, 0 failed, 0 skipped**). No screen code was changed by this
stage; `p10_bugs_test.dart` needed no edit (10/10, no skip markers anywhere in
the feature).

| Id | Status | Fixed by / evidence |
|---|---|---|
| BUG-P10-1 | FIXED | `QuestPushOnce` guard; same-frame/cross-frame/triple-tap probes → one editor |
| BUG-P10-2 | FIXED | `CrossAxisAlignment.start`; title/meta at card x+64 |
| BUG-P10-3 | FIXED | search + chips rendered on Ideas only |
| BUG-P10-4 | FIXED | separators between rows; end gap 32 |
| BUG-P10-5 | FIXED | shared `NestTextField.search`; icon 24 at x+16 |
| BUG-P10-6 | FIXED | shared `NestSegmented` 52/44 |
| BUG-P10-7 | FIXED | shared `NestTabBar`; surface 726→844, content at design y |
| BUG-P10-8 | FIXED | `ideas` owned by `QuestsState`; no GetIt probe |
| BUG-P10-9 | FIXED | `Semantics` `onTap` + `container`; a11y actions green |
| BUG-P10-10 | FIXED | shared `ab1ba06` (`excludeSemantics`); a11y suite 20/20 |
| BUG-P10-11 | FIXED | `plate`/`sofa` tints |
| BUG-P10-12 | FIXED | `TextEditingController` in the body; round-trip proof green |
| BUG-P10-13 | CLOSED | assertion rewritten to what P10 owns; naming nuance is shared §8 (below) |
| BUG-P10-14 | FIXED | shared `1db0f8a`; hint centre 200, field 54, pins green at ±1 |

## Measured this iteration (design → app, real fonts, 47/34 insets)

| Element | Design | App | Δ |
|---|---|---|---|
| `.search` ring | 173…227 (54) | 173…227 | 0 |
| hint ink centre | 200.0 | **200.0** | 0 |
| magnifier centre | 200.0 | 200.0 | 0 |
| `All` chip top | 227.0 | 227.0 | 0 |
| card 1 top | 291.0 | 291.0 | 0 |

The former −11 px hint drift and the −2 px cascade below the field are gone
exactly as the 13:42 note demanded; the geometry suite (tightened to ±1 by the
build stage) is green in light and dark.

## Adversarial probes this iteration (all clean)

| Probe | Result |
|---|---|
| Search round-trip with 0 matches (`zzz` → Active → Ideas) | field keeps the query, empty state consistent; clearing restores the list ✓ |
| Text scale 1.3 | hint box 191…222 (31) fully inside the field 183…237; typed text filters (1 row); no exception; the 3.5 px optical offset of the 31 px line box at 1.3 has no design reference and clips nothing ✓ |
| Keyboard inset (bottom 300) | no exception, field stays visible ✓ |
| Empty seed → live DB insert | `Active (1)` from the stream; long title + `9999 coins` row renders; empty state disappears ✓ |
| Same-frame triple tap `+ Add` | one `/quest-editor` push ✓ |
| Scroll to end + double-tap last Active row | one push ✓ |
| Scroll down, back up, filter | 1 row, no exception (the search field is part of the scrolling content, exactly like the design's `.scroll`) ✓ |
| 320 × 1.3, dark mode, long UK names, empty lists | green in the matrix/geometry/states suites |
| Back + deep links, kid gate, restart persistence, async mid-push | unchanged, green |
| Europe/London + BST, money pence, 0/1/6 children | N/A on P10 (no dates, no `£`, no child data) |

No failing proof was needed for this iteration: nothing failed.

## Carried shared items (non-blocking, no P10 red test, not P10-local)

- **`SHARED_REQUEST.md` §8 (major, shared)** — `NestTextField.search` puts the
  `Search quest ideas` label on an inert wrapper node while the editable
  announces the hint. P10's proof asserts the design label is in the tree once
  and typing really filters (both green); the fix lives in `core/`.
- **§5 (shared half)** — `NestChip` still exposes no `tap` action; P10 uses its
  own `QuestFilterChip`, which is fixed, and no P10 test is red on it.
- **§11 (minor, shared)** — the keyboard's Search key has no `onSubmitted`
  passthrough; the design's `<input type="search">` is equally inert.
- **§6 (optional)** — promote `QuestPushOnce` to `core/`; **§7 (informational)**
  — P08 paints `plate` lilac where P10 paints sky.

## Gates at hand-off

- `flutter test test/features/quests` → **192 passed, 0 failed, 0 skipped**.
- `flutter test test/features/quests/p10_bugs_test.dart` → **10/10**.
- `dart format --set-exit-if-changed` on the P10 test files → clean.
- `flutter analyze` → clean for P10-owned files (a whole-app run picked up a
  concurrent stage's temporary `zz_probe_type_test.dart` only).
- No simulator was booted, installed on, screenshotted or driven by this stage.

VERDICT: PASS
