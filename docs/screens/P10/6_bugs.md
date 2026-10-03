# P10 · Quest library — bug hunt (Stage 6, iteration 1)

Route `/quests` · feature `quests` · parent mode · seeds `Seed.demo()` (12
active quests) and `Seed.empty()` (0) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. Tree tested: iteration-1 checkpoint
`de831ed` (`screen/P10`), including the UI stage's `5_ui.md` findings and
`ORCHESTRATOR_NOTES.md` (all items accounted for below).

Proofs live in `app/test/features/quests/p10_bugs_test.dart` — **9 tests in 8
skipped groups**, one group per bug id. With the skips removed all nine fail
on this tree (`flutter test … --reporter compact` → `+0 -9`); with the skips
in place the feature suite is green. The geometry proofs are the real-font
(`FontLoader`, bundled Inter/Nunito) geometry test the notes ask for, pinned
at 390×844. No screen code was changed by this stage.

| Id | Severity | Area | Source |
|---|---|---|---|
| BUG-P10-1 | **major** | same-frame double-tap stacks two `/quest-editor` routes (`+ Add` and Active row) | this stage |
| BUG-P10-2 | **major** | `.trow` title/meta centred; design starts them at card x+64 | 5_ui 1 · notes 1 · review 1 |
| BUG-P10-3 | minor | search + category chips are inert on the Active tab | this stage |
| BUG-P10-4 | minor | end-of-list gap 48 px; design 32 px | this stage |
| BUG-P10-5 | **major** | search prefix icon 48×48 at field x+0; design 24×24 at x+16 (hint at x+50) | 5_ui 2 · notes 2 · review 3 · **shared** |
| BUG-P10-6 | **major** | segmented track/thumb 44/36; design `.segmented` 52/44 | notes 3 · review 4 · **shared** |
| BUG-P10-7 | **major** | tab-bar content 34 px low (icon centre 783; design 748) | 5_ui 5 · notes 5 · **shared** |
| BUG-P10-8 | **major** | view silently degrades to “No ideas found” when the global DI lookup fails | review 2 |

---

## BUG-P10-1 — major — same-frame double-tap stacks two editor routes

Both push sites in `presentation/widgets/quest_library_body.dart` call
`context.push` unguarded: `+ Add` at `:183`, Active row at `:146`.

**Repro.** Tap `+ Add` twice before a frame renders (same-frame double tap) →
two `QuestEditorView` routes (`findsNWidgets(2)` with `skipOffstage: false`);
one `pageBack()` still lands on `/quest-editor`, so the parent must press back
twice. Same on the Active tab by double-tapping the first row. A 50 ms-later
double tap is absorbed by the route transition (matches P08-B12) — only the
same-frame case stacks. **Proofs:** `+ Add pushes two /quest-editor routes`,
`an Active row pushes two /quest-editor routes`.

**Fix.** Copy P08's per-frame guard (`_PushOnce`,
`today/presentation/widgets/today_loaded_body.dart:238-269`) into the quests
layer (no cross-feature import) or promote it to `core/` via a shared request;
route both pushes through it. Un-skip BUG-P10-1.

## BUG-P10-2 — major — `.trow` text block is centred

`quest_idea_row.dart:71-93`: the `Expanded > Column` has no
`crossAxisAlignment`, so title and meta centre instead of starting at the tile
gap. **Proof:** `title and meta left-align to the tile gap` — measured title
offset **101.4 px** (design 64; card x=20, tile 40, gaps 12+12). **Fix:** add
`crossAxisAlignment: CrossAxisAlignment.start` to that `Column`. Un-skip
BUG-P10-2.

## BUG-P10-3 — minor — the Active tab renders controls that do nothing

Search + chip row render on both tabs (`quest_library_body.dart:90-110`) but
the Active branch (`:125-152`) ignores `_query`/`_category`. **Proof:**
`typing in the search field does not narrow the list` — after typing `bins`,
`Empty the dishwasher` is still on screen. **Fix:** hide search + chips on the
Active tab (the table has no category column), or filter the Active title by
the query. Un-skip BUG-P10-3.

## BUG-P10-4 — minor — 16 px extra below the last row

`_rows()` appends `SizedBox(16)` after every row including the last
(`:150` Active, `:169` Ideas) on top of `padding-bottom: 32` (`:56`); the
design's `.scroll > * + *` adds no margin after the last child, so the design
gap is 32. **Proof:** `16 px extra below the last row` — measured 48.0.
**Fix:** emit the separator only between rows. Un-skip BUG-P10-4.

## BUG-P10-5 — major — search prefix icon is 48×48 at x+0 (shared)

`quest_library_body.dart:98` passes a 24 px `NestIcon` as `prefixIcon`;
`NestTextField` forwards it to Material's `InputDecoration.prefixIcon`, whose
default constraints floor the slot at 48 px. The `NestIcon` is stretched to
**48×48 at field x+0** (design: 24×24 at x+16) and the hint starts at x+64
(design x+50), so the chain below is shifted too. **Proof:** `the magnifier
keeps the design slot`. **Fix:** shared — expose `prefixIconConstraints` on
`NestTextField` and keep the slot/alignment such that icon = 24 at x+16, hint
at x+50; see `SHARED_REQUEST.md` §1. Un-skip BUG-P10-5.

## BUG-P10-6 — major — segmented control is 8 px short (shared)

`NestSegmented` is 44 high with 36 px buttons; the HTML `.segmented` is
`padding: 4px` around buttons whose `min-height:44px` beats `height:40px` —
PNG measurement: track 315–470 @3x = **52**, selected pill 44. **Proof:**
`track, thumb and the 16/0/16 chain below it` — measured 44/36 plus the
segmented→search (16), search→chips (0) and chips→card (16) chain. **Fix:**
shared `NestSegmented` track 52 / buttons 44; see `SHARED_REQUEST.md` §2.
Un-skip BUG-P10-6.

## BUG-P10-7 — major — tab-bar content sits 34 px low (shared)

With the device insets (47/34), the app tab bar spans 760–844 with the Today
icon centre at **783**; the design puts the bar block at 726–810 (icon centre
**748**) with the 34 px home strip below it, and the owner rule wants the
surface to run to the edge. **Proof:** `Today icon centre matches the design
bar top`. **Fix:** shared `NestTabBar`/`ParentShell` content position; see
`SHARED_REQUEST.md` §3. Un-skip BUG-P10-7.

## BUG-P10-8 — major — the view silently loses its ideas when DI fails

`quest_library_view.dart:69,85-92`: `_ideaTemplates()` probes
`GetIt.instance.isRegistered` on every build and falls back to `const []`, so
a DI-order/build failure swaps 10 templates for “No ideas found” instead of
failing loudly (review finding 2). **Proof:** `a lost repository renders the
empty Ideas state` — after unregistering the repository and forcing a stream
rebuild, all `+ Add` rows disappear. **Fix:** put `ideas` in `QuestsState`
(populated by the bloc from `_repository.ideas()`); the view stops importing
`get_it`. Un-skip BUG-P10-8.

---

## ORCHESTRATOR_NOTES coverage

| Note | Handled by |
|---|---|
| 1 — `.trow` text at card x+64 | BUG-P10-2 (proof: real-font geometry) |
| 2 — search icon 24 at x+16, hint x+50, field height | BUG-P10-5 (icon + position; outer field measures 52 vs design ≈54 — within the ±2 band once the chain is fixed) |
| 3 — segmented track/buttons | BUG-P10-6 (track 52, buttons 44) |
| 4 — chips centre / first card top follow 2–3 | BUG-P10-6 proof also pins the 16/0/16 chain; absolute y then follows |
| 5 — tab bar content at design top, surface to edge | BUG-P10-7 + `SHARED_REQUEST.md` §3 |
| 6 — cards continue under the bar like the design | derivative of 2–5: once the content moves down 10 and the bar top rises to 726, the 6th card peeks 15 px exactly as the design (no separate assertion) |
| Real-font geometry test | `setUpAll(_loadBundledFonts)` + the three geometry proofs |

## Probed, no bug found (brief's hunt list)

| Area | Result |
|---|---|
| Rapid double taps | Cross-frame (50 ms) absorbed → 1 editor; same-frame stacks (BUG-P10-1). |
| Back navigation / deep links | Editor → back → `/quests` ✓; `/quests` and `/quests/` both match ✓. |
| Restart / Drift persistence | Re-pumping against the same DB keeps `Active (12)`; a file-backed DB closed and reopened returns the same 12 actives. |
| Parent/kid guard | Kid mode + `/quests` → `/parental-gate` ✓. |
| Dark mode | All P10 text pairs ≥ 4.5:1 (ink/ink2/ink3 on surface; leafInk on leafTint; sky on skyTint; aPeach on peachTint); tiles stay tinted. |
| Text scale 1.3 + width 320 | No overflow/exception; chips scroll (Kitchen off-screen at 320×1.3 is expected). |
| Long UK names / 9999 coins | Long title ellipsizes; `Daily · 9999 coins` renders; `Active (13)` follows a DB insert (DATA OVER MOCKS). |
| Empty lists | `Seed.empty()` → `Active (0)` + `No active quests` / `Add one from Ideas.`; no-match → `No ideas found`. |
| Async gaps | Disposing mid-push leaves no exception; Drift's deferred stream-close drains. |
| Europe/London + BST | N/A — no dates/times and no completion-status logic on P10 (period rule N/A). |
| Money rounding / integer pence | N/A — coins only, no `£`. |
| 0/1/6 children, £0.00/£999.99 | N/A — no child or money data on this screen. |

Carried (not counted): missing `.chipscroll` right-edge fade (plan §a allows);
Active order is title-sorted (review finding 10 — orchestrator question, filed
in `SHARED_REQUEST.md` §5); `?idea=` opens the P09 placeholder blank
(documented `TODO(P10)`, same feature, P09 not built).

## Gates at hand-off

- `flutter analyze test/features/quests/p10_bugs_test.dart lib/features/quests`
  → **No issues found**; a whole-app analyze was also clean when re-run with
  no foreign temp files in the tree. (The concurrently-running TEST stage
  repeatedly leaves `zz_probe*_test.dart` probes in `test/features/quests/`;
  they are not P10 screen findings and were left untouched.)
- `dart format --set-exit-if-changed` on the new test file → clean.
- `flutter test test/features/quests` → **41 owned tests pass, 9 skipped
  (bug proofs), 0 failed**.
- Unskipped proof run → **`+0 -9`**: every bug above fails on this tree.

VERDICT: FAIL
