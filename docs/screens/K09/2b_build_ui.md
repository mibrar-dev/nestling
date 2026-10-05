# K09 · 2b BUILD (UI chunk, iteration 2)

Scope: `presentation/views/**` + `presentation/widgets/**` for K09, plus the
view/widget tests (`my_jar_view_*.dart`) and the skipped bug proofs referenced
by `FIXES_1.md` (`k09_bugs_test.dart`). The logic builder ran in parallel in
this worktree; `2a_build_logic.md` (iteration 2) carries the CONTRACT CHANGES
this layer codes against — re-read, and matched exactly:

- `JarEntry.iconKey` (`String`, default `''`) → `jarEntryGlyph` renders
  `questIconFor(iconKey, audience: NestAudience.kid)` for quest rows.
- `KidJarSnapshotReceived` / `KidJarStreamFailed` are bloc-internal; the view
  still dispatches only `KidJarLoadRequested` (retry).

## Files changed (UI layer only)

- `presentation/views/my_jar_view.dart` — K09-BUG-2 ink, K09-BUG-6 scroll
  tail, review finding 6 live region.
- `presentation/widgets/jar_goal_card.dart` — K09-BUG-4 `remainingPence`
  clamp.
- `presentation/widgets/jar_history_card.dart` — K09-BUG-3 + 5_ui dev. 1:
  `jarEntryGlyph(type, iconKey)` → `jarPocketMoney` / kid `questIconFor` /
  `gift`; the empty-row disc glyph follows to `jarPocketMoney` (no
  `NestIcons.poundCoin` left anywhere in `kid_jar`).
- `test/features/kid_jar/my_jar_view_test.dart` — the blocked pocket-money /
  gift proof is now live (`K09-BUG-3b`), plus the over-saved `JarGoalCard`
  widget proof (review finding 2 / K09-BUG-4).
- `test/features/kid_jar/my_jar_view_states_test.dart` — asserts the loading
  frame is a live region.
- `test/features/kid_jar/k09_bugs_test.dart` — un-skipped `K09-BUG-4/5/6`
  (all three pass; header updated — no `skip:` remains in the feature).

No `domain/**`, `data/**`, bloc, core, app, another feature or `tools/**`
touched. No `google_fonts`, no `DateTime.now()`, no weakened analysis.

## FIXES_1 disposition (UI/layout/copy items)

| id | item | status |
|---|---|---|
| K09-BUG-2 (minor, mandated) | `coming on Saturday` `ink2` → `ink` (`my_jar_view.dart`) | **FIXED** — both red proofs green |
| K09-BUG-3 (major, mandated) | quest-bonus rows use `questIconFor(key, kid)` off `entry.iconKey` | **FIXED** — the DB-driven proof (`Put the bins out`/`Hoover the stairs`/`Tidy your bedroom`/`Help with the washing`) green |
| K09-BUG-4 (major) | `JarGoalCard.remainingPence` clamped at 0 | **FIXED** — DB proof + widget proof green (repo cap landed in 2a) |
| K09-BUG-5 (minor, latent) | owed floor is 2a's; the un-skipped proof's UI leg now reads `£0.00` | **FIXED upstream** — proof green |
| K09-BUG-6 (minor) | scroll tail is `--s8` only (`SafeArea` already carries the 34 px inset) | **FIXED** — proof measures footer bottom 778 |
| 5_ui dev. 1 | row-1 glyph → `NestIcons.jarPocketMoney` (design coin-slot, `K09-jar.html:85`) | **FIXED** — `K09-BUG-3b` green |
| 5_ui dev. 2 | row-2 glyph → kid bins from `questIconFor` (`questBinsKid` is the design's lidded bin) | **FIXED** — mandatory proof green |
| 5_ui dev. 4 | gift row compared at last → `NestIcons.gift` already draws `:95` exactly | **FIXED** — `K09-BUG-3b` green |
| 4_review 6 (minor) | loading label is a `liveRegion` | **FIXED** — flag asserted |
| ORCHESTRATOR_NOTES `jarPocketMoney`/`jarGift` | swap in `jarEntryGlyph` once on main | **FIXED** — main landed it; gift needs no new asset (shared test) |

## Verification (this stage)

- `dart format` on every file touched → 0 changed.
- `flutter analyze lib/features/kid_jar` + the feature tests → **No issues
  found!**
- `flutter test --timeout 120s` on
  `my_jar_view_test.dart` + `my_jar_view_geometry_test.dart` +
  `my_jar_view_states_test.dart` → **61/61 pass** (includes the ±2 px band
  table with the bundled Nunito, the width × scale × theme matrix, and the
  two previously red K09-BUG-2 proofs).
- `flutter test --timeout 120s test/features/kid_jar/k09_bugs_test.dart` →
  **12/12 pass** (the three formerly skipped proofs now run live).
- No simulator booted, no whole-app test run, no `flutter clean`.

## Owner rules

- **UI VERDICT / ALIGNMENT** — no initial-frame box moved: the geometry suite
  (title 107, jar 151, goal 465, progress 557, heading 634, list 676, 20 px
  gutters at 320/390/430) is green. Only the max-scroll tail changed (744 →
  778, the design's own value), and the `--ink` line.
- **BOTTOM EDGE** — unchanged: K09 has no bar, the shared meadow still runs
  to the physical edge; `SafeArea` only insets content.
- **ICONS** — kid glyphs only: `jarPocketMoney` / kid `questIconFor` / `gift`;
  `poundCoin` is gone from the feature.
- **COPY / LETTER SPACING / BALANCED HEADINGS / KID BACKGROUND / CHILD
  ORDER / CLOCK / IDS** — untouched by this diff; the character-exact copy
  suite stays green.

## LEFT FOR NEXT ITERATION

- `5_ui` re-check: the two history-row glyphs and the `coming on` band are
  the only visually changed pixels in the viewport; the `NestProgress` dark
  gloss band is the shared defect already in `SHARED_REQUEST.md` (do not
  attribute it to K09).
- Review finding 3 (money formatter split across `domain/jar_snapshot.dart`
  and `presentation/widgets/jar_amounts.dart`) is cross-layer and was left
  by both builders; it is a pure refactor (no visual change) and needs either
  a coordinated iteration or a ruling that it may stay.
- The failure frame's art (`NestIcons.jar` at 96 px) is still the K08-shaped
  choice from iteration 1; the design has no error frame. Cosmetic, only if
  the UI check asks for the `JarIllustration` there instead.

VERDICT: PASS
