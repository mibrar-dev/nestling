# P15 · Child profile — Stage 2b BUILD (UI chunk, iteration 2)

Scope owned and touched: `app/lib/features/family/presentation/views/**`,
`presentation/widgets/**`, and `app/test/features/family/child_profile_view_test.dart`.
No `domain/`, `data/`, `bloc/` or `core/` file was edited by this stage (the
parallel logic builder's files are in the diff but are its own).

Re-read before finishing: `1_plan.md`, `ORCHESTRATOR_NOTES.md`,
`2a_build_logic.md` (**CONTRACT CHANGES: none** — every public name matches the
plan, so no code had to bend to the logic), `FIXES_1.md`, `SHARED_REQUEST.md`.
No simulator was booted, installed on, driven or screenshotted; the design
PNGs were read with the file reader only.

## What was already in place (iteration 1)

The band geometry was right: hero 47/164, stats 227/82, Pip card 325/116, list
457/180, danger 653/80 (`child_profile_view_test.dart`, measured from
`design/screens/light/P15-child-profile.png ÷ 3`). All of that still passes
unchanged — every card top and height is byte-identical after this stage, so
there is no uniform shift for the UI stage to call out.

## FIXES_1 items closed

| Item | Severity | Fix |
|---|---|---|
| ORCHESTRATOR item 1 / P15-BUG-5 — every list subtitle ellipsised | major | see §1 below |
| ORCHESTRATOR item 2 / 5_ui deviation 2 — Quests tile showed a bare tick | major | see §2 |
| 5_ui deviation 3 — Pocket money tile showed `£`, not the coin | major | see §2 |
| Review 5 — hero `<h1>` had no `Semantics(header: true)` | minor | `child_profile_body.dart` `_HeroCard` |
| Review 6 — hero nickname ellipsised where the design wraps | minor | `maxLines: 3` (was 1), hero still 164 for a one-line name |
| Review 7 — `size: 84` bare literal | minor | `SHARED_REQUEST.md` §3 (`NestPip.rowSlot`), citing comment left in place |
| Review 4 / P15-BUG-2 — a load failure reported twice (body + snackbar) | minor | `child_profile_view.dart`: the `BlocListener` is scoped to `status == loaded` |
| P15-BUG-4 — a stage-1 Pip read "Pip is a Egg" | minor | `child_profile_copy.dart`: `pipStageArticle(stage)` → `an Egg` |
| Review 10 — no view proof for the remove-failure toast | minor | new test in `child_profile_view_test.dart` |

Reviewed and deliberately NOT changed:

* **Review 8 / ORCHESTRATOR item 3 — "Maya knows *their* code".** Kept; the
  schema has no gender and the orchestrator ruled it correct.
* **ORCHESTRATOR item 4 — quest counts.** `4` quests this week and
  `4 daily, 2 weekly` come from the DB (DATA OVER MOCKS); the design's `18` and
  `3 daily, 3 weekly` are mocks.
* **P15-BUG-3 (repeat identical remove failure).** Root cause is
  `FamilyState.copyWith` not clearing `errorMessage` — a bloc concern. The
  logic builder has since fixed it (`child_profile_bloc_test.dart` P15-BUG-3 is
  green), so nothing was needed here.

### 1. ORCHESTRATOR item 1 — subtitles in full (P15-BUG-5)

`NestListRow` lays out `[tile, gap, Expanded(main), gap, Flexible(trail)]`.
Flutter splits the free space **equally** between the two flex children, so
the trailing reserved half the row however narrow it was and the title/sub
column got 129 px where the design's CSS gives ≈187 px
(`components.css:116-119`: `.list-main { flex: 1; min-width: 0 }`,
`.list-trail { flex-shrink: 0 }`). All three subtitles were cut on every width
and both text scales.

The one-line fix belongs in `core/design_system/**` (RULES §1), so this stage
shipped a **P15-local stopgap** rather than leaving a known UI failure in place:
`presentation/widgets/child_profile_row.dart` transcribes the design's
`.list-row` on top of the shared pieces only — `NestList` (card + 72 px
dividers), `NestIcon`, `NestType`, `NestSpacing`, `NestTileTint`,
`Material`/`InkWell`, and the same `Semantics(button:, enabled:, label:,
onTap:)` contract `NestListRow` publishes. No colour or spacing literal of its
own; the trail is simply shrink-wrapped instead of flexed.

Verified: `child_profile_theme_size_test.dart` → *no list-row paragraph is
ellipsised at 390* (three `didExceedMaxLines == false` per row, so `title`,
`subtitle` and `trailing` alike) and `Change ›` == its intrinsic 70.71 px —
both proofs green now, and they were the ones the test stage left red.

`SHARED_REQUEST.md` §1 records the ask and says to delete this file once the
shared row lands; the geometry assertions are identical either way, so the swap
is a no-op for the suite.

### 2. ORCHESTRATOR item 2 — the two row icons

* **Quests → `NestIcons.quests`.** No new asset was needed after all:
  `assets/icons/ic_quests.svg` *is* the design's glyph — `<circle cx="12" cy="12"
  r="9"/><path d="M8.5 12.5 11 15l4.5-5.5"/>`, 24 viewBox, `currentColor`,
  stroke 2 — which is what the design's Quests tile draws (verified against the
  PNG). `SHARED_REQUEST.md` §2a is downgraded to "an alias would be nice".
* **Pocket money → `SvgPicture.asset(NestlingIllustrations.coin, 24)`.** The
  design's tile holds the COLOURED `assets/illustrations/coin.svg` (gold coin,
  leaf emboss); `NestIcon` tints with `BlendMode.srcIn`, which is why the
  `£`-in-a-circle `poundCoin` looked wrong. Illustrations keep their own
  colours, so a bare `SvgPicture` is the correct rendering — hence the
  `leadingWidget`-style escape hatch in `ProfileRow` (`leading` is a
  `Widget Function(Color tileForeground)` builder), which `SHARED_REQUEST.md` §2b
  still asks the design system to grow.

Both glyphs sit in the same 24 px box inside the same 40 px `radius: 12` tile,
so the tile rects are unchanged.

### 3. A11y regression the icons nearly caused (caught, fixed)

`child_profile_theme_size_test.dart` → *every icon/image node is labelled*
went red while the icons were in flight: a `Stack` of two `NestIcon`s, and a
`SvgPicture` dropped straight into the tile's loose constraints, each stopped
merging into the row's own `Semantics` node and surfaced as a **separate image
node with an empty label** — VoiceOver would have announced a nameless image
on every Quests / Pocket-money row. Both glyphs are now single icons inside a
`SizedBox.square(24)` (the box `NestIcon` uses), and the semantics tree is
byte-identical to iteration 1's:

```
Pip → "Maya's Pip, a fledgling / Pip · Fledgling / …"     (1 image node)
Kid PIN       → row text + tile icon, merged (24)
Quests        → row text + tile icon, merged (26)
Pocket money  → row text + tile icon, merged (28)
tab bar       → Today / Quests / Money / Family (8, 10, 12, 14)
```

8 image nodes, every one labelled, in both themes.

## Tests

`child_profile_view_test.dart` (mine) gains one test, *P15 remove failure: a
failing removeChild toasts and keeps the profile*: mock repository
(`removeChild` throws), real remove flow (tap `p15-remove` → confirm `Remove`),
then `NestToast` on screen with the repository's message, `ChildProfileBody`
still mounted, no `Try again`, and `verify(() => repo.removeChild('maya'))`. The
other two branches review finding 10 named (loading spinner, failure + retry)
are already covered by `child_profile_states_test.dart`, written after that
review.

### Gates (in `app/`)

```
$ dart format --set-exit-if-changed lib/features/family test/features/family
Formatted 30 files (0 changed) in 0.64 seconds.          # clean

$ flutter analyze lib/features/family test/features/family
No issues found! (ran in 32.2s)

$ flutter test --no-pub test/features/family/
00:58 +230: All tests passed!
```

All three previously-red test-stage proofs this stage owned
(`P15-BUG-2` states, `P15-BUG-4` copy, `P15-BUG-5` theme/size) are green and
were **not** skipped, weakened or reworded; `p15_bugs_test.dart`'s skipped
logic proofs were un-skipped and fixed by the logic builder. No whole-app
`flutter test` and no simulator — those are the integrator's stage.

Not run here: `shot.sh` + `compare.py` for the light/dark UI pass (stage 5).
The band geometry is unchanged from iteration 1, whose `5_ui.md` measured every
edge within ±2 px, so only the two icon glyphs and the three subtitle strings
need re-measuring.

## LEFT FOR NEXT ITERATION

* **Stage 5 must re-shoot both themes.** Expected deltas: the Quests tile now
  shows the circled check and the Pocket-money tile the gold coin (5_ui
  deviations 2 and 3 gone), and the three subtitles render in full instead of
  ending in `…` (deviation 1 gone). No new band should move.
* `presentation/widgets/child_profile_row.dart` is temporary — delete it and
  pass `NestListRow` again once `SHARED_REQUEST.md` §1 lands on `main`
  (§2b's `leadingWidget` would then be needed for the coin).
* `SHARED_REQUEST.md` §1 / §2b / §3 are still open shared asks (row flex, a
  `leadingWidget` on `NestListRow`, a `NestPip.rowSlot = 84` token). None of
  them blocks the screen now.
* Not mine, but visible in this feature's suite: the orchestrator should ratify
  the cross-feature anchor swap in `app/test/features/today/today_view_test.dart`
  (review finding 9).

VERDICT: PASS