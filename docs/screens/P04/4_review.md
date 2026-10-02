# P04 · Privacy consent — QA code review (STAGE 4, iteration 4)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Reviewed surface: `git diff main...HEAD` plus the uncommitted working-tree build.
`main` is fully merged (`HEAD..main` empty) — the orchestrator's shared batch
`7eaa1f7` ("trash icon, themed shield, first-run settings …") arrived in merge
`ce89889`.

Production code changed this iteration: `privacy_consent_view.dart` (promise rows
as a single `NestList` child + a zero-height separator overlay) and
`privacy_consent_repository_impl.dart` (the first-run upsert wrapped in a
transaction).

Checks run for this review:

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent        → 17 files, 0 changed
flutter analyze                            → No issues found! (ran in 3.6s)
flutter test test/features/privacy_consent/ → 00:02 +118 ~2: All tests passed!
flutter test  (whole app)                  → 00:15 +645 ~2: All tests passed!
tools/screens/compare.py vs ui/app_light_4.png → mean diff 4.10%
     bands 1.59 / 6.02 / 1.98 / 7.94 / 5.78 / 4.19 / 0.40 / 4.84 %
tools/screens/compare.py vs ui/app_dark_4.png  → mean diff 5.15%
     bands 1.56 / 8.50 / 9.14 / 7.87 / 5.75 / 4.44 / 0.39 / 3.55 %
```

Mean diff improved again: light 4.49% → **4.10%**, dark 5.61% → **5.15%**.
Skipped proofs dropped 3 → 2 (`[P04-4]` and `[P04-9]` un-skipped and green).

Pixel probes (logical px, PNG ÷ 3), design vs `ui/app_{light,dark}_4.png`:

| probe | design | app it. 4 | it. 3 | verdict |
|---|---|---|---|---|
| back-chevron glyph band | 66–80 | 66–80 | 66–80 | Δ0 |
| h1 glyph band | 113–138 | 113–138 | 113–138 | Δ0 |
| subtitle glyph band | 156–170 | 156–170 | 156–170 | Δ0 |
| promise-list card | 288–509 | **288–509** | 288–512 | **Δ0 — the +3 px drift is gone** |
| opt card | 532–616 | **532–616** | 535–619 | **Δ0** |
| bottom-CTA surface | 674–809 | 675–**843** | 675–843 | runs to the edge ✓ |
| strip below CTA (light / dark) | `#FBF7F0` / `#15131F` | `#FFFFFF` / `#1F1C2E` | same | ✓ OWNER rule |
| row-4 tile ink, light | `#B44A1F` | absent | absent | **finding 1** |
| shield disc, dark | `#1A2A4A` | `#E6EFFE` | `#E6EFFE` | **finding 2** |

`tokens.peachTint` = `#FFEDE4` and `tokens.aPeach` = `#B44A1F` match the design's
row-4 tile and glyph ink exactly, so `NestTileTint.peach` +
`NestIcons.trash` reproduces the design's red-ink glyph with no new tokens.
`ic_trash.svg` is a 24×24 `stroke="currentColor"` line icon matching the HTML
path, so `NestIcon` tints it like the other three rows.

---

## Findings

### 1. MAJOR — row 4 still renders an empty peach tile although `NestIcons.trash` is now in the worktree

- **Where:** `privacy_consent_view.dart:123-135` — `_PromiseRow(title:
  _promiseTitles[3], subtitle: …, tint: NestTileTint.peach, showDivider: true)`
  with **no `leadingAsset`**, and a `TODO(P04)` at `:128-133` stating
  "`ic_trash.svg` + `NestIcons.trash`" are pending.
- **Evidence:** `app/assets/icons/ic_trash.svg` exists;
  `nest_icon.dart:49` defines `NestIcons.trash`; `nestling_assets.dart:171` maps
  it to `assets/icons/ic_trash.svg`; `app/assets/icons/` is in the pubspec asset
  list, so it bundles. `grep -rn "NestIcons.trash" app/lib` returns exactly one
  hit — P04's own stale TODO comment. There is no consumer anywhere.
  The design's row-4 glyph ink is `#B44A1F` (= `tokens.aPeach`) on a `#FFEDE4`
  tile (= `tokens.peachTint`), i.e. exactly what `NestTileTint.peach` produces
  once an asset is supplied.
- **Timing (stated so this is not read as a build failure):** the build edited
  the view at 14:36:31 and wrote `2_build.md` at 14:40:52; `main` had been merged
  into the branch at 14:32:13 and did not yet contain the batch (committed
  14:42:37, merged into the branch 14:43:57). The build's own claim —
  "`ic_trash.svg` / `NestIcons.trash` still absent from this worktree (verified)"
  was true when written and is false now. So this is not a merge-order
  complaint: the 13:42 UPDATE's precondition ("when main contains
  `NestIcons.trash` … use it with the design's red-ink colour") is satisfied as of
  merge `ce89889`, and the orchestrator's mandatory item 1 is therefore live and
  unmet.
- **Fix (one line plus cleanup):**
  1. `privacy_consent_view.dart:126` — add
     `leadingAsset: NestIcons.trash,` to the row-4 `_PromiseRow`.
  2. Delete the `TODO(P04)` block at `:128-133`; it now states a falsehood.
  3. `p04_bugs_test.dart` — drop `skip: true` from `[P04-2]`
     (`findsNWidgets(4)` for both `NestIcon` and `SvgPicture` already asserts
     exactly what the asset gives).
  4. `privacy_consent_view_contract_test.dart` — the "row 4 is the gap" test
     asserts `findsNothing` for row 4's `NestIcon`; flip it to `findsOneWidget`
     with `assetName == NestIcons.trash` and `color == tokens.aPeach`, and let
     the light+dark tint loop cover four rows instead of three.
- **Severity rationale:** a blank coloured tile where the design draws a glyph is
  the defect the orchestrator named by name and that 5_ui.md called "a designer
  would reject"; it is the last visible difference on the screen's main content.

### 2. MAJOR — dark mode still renders the light-baked shield SVG although the shared themed component exists and has no consumer

- **Where:** `privacy_consent_view.dart:74-86` — `Center(child: Semantics(label:
  …, image: true, child: ExcludeSemantics(child: SvgPicture.asset(
  NestlingIllustrations.privacyShield, width: 84, height: 84))))`.
- **Evidence:** the batch added
  `app/lib/core/design_system/components/nest_privacy_shield.dart` —
  `NestPrivacyShield({size = 84, semanticLabel})`, painted from tokens
  (`skyTint` disc, `surface` body, `leaf` heart, `ink` stroke) and wrapping itself
  in `Semantics(image: true, label: …)` when a label is given. `grep -rn
  "NestPrivacyShield" app/lib` returns **no consumer**; only
  `app/test/design_system/shared_batch1_test.dart` references it. The batch
  commit message names P04 as its intended consumer.
  Probe of the disc at (165, 229): design dark `#1A2A4A`, app dark `#E6EFFE` —
  unchanged from iteration 3. Dark band 2 (211–316) is 9.14 %, the worst band in
  the app, and it is entirely this disc.
- **Fix:** replace the `SvgPicture` block with
  `NestPrivacyShield(size: 84, semanticLabel: 'A shield with a leaf and a heart, protecting your family')`
  and drop the manual `Semantics`/`ExcludeSemantics` wrapper — the component
  already emits `image: true` with that label, so the semantics test in
  `privacy_consent_copy_test.dart` (`find.bySemanticsLabel(shieldAlt)`) keeps
  passing unchanged. Then drop `skip: true` from `[P04-7]`, rewriting it against
  the component: assert the painted disc colour is `nest.skyTint` in dark mode
  rather than grepping the SVG XML for `#E6EFFE` (the component no longer reads
  that asset at all). The `SIZING_SPEC`/`84` literal disappears with the change.
- **Severity rationale:** a glaring light disc on a dark surface is the most
  visible remaining design deviation (worst band in the dark sheet), and the
  fix is now in scope and one line.

### 3. MINOR — the feature-local separator overlay now duplicates the shared `NestList` overlay that arrived in the same batch

- **Where:** `privacy_consent_view.dart:88-95` (the four rows passed as a single
  `Column` child so `NestList` injects no dividers), `:231-250` (`showDivider`
  flag + doc comment), `:320-338` (`Stack` + `Positioned(top: 0, left: 72,
  right: 0, height: 1, Divider(height: 1, thickness: 1, color: tokens.line))`).
- **Why:** shared `NestList`
  (`core/design_system/components/nest_list_row.dart:131-151`) now paints
  separators as exactly the same zero-height overlay (`Positioned(top: 0,
  left: 72, right: 0, child: Container(height: 1, color: tokens.line))`) for the
  normal multi-child case. P04's local copy exists only because the shared
  component was still broken when iteration 3's finding was written; the batch
  fixed it. The result is correct and pixel-exact (probes: list 288–509,
  opt card 532–616, both Δ0), but the feature layer now carries its own copy of
  the shared mechanism and its literals (`left: 72`, `height: 1`), which is the
  duplication the design-system rule exists to prevent.
- **Fix:** delete `showDivider`, the `Stack` wrapper and the single-`Column`
  wrapper, and pass the four `_PromiseRow`s back as four `NestList` children.
  The shared overlay renders identically, the feature layer keeps no divider
  literals, and `[P04-4]` ("list height == sum of row heights") still passes
  because it asserts the *result*, not the mechanism. Keep SHARED_REQUEST item 6
  filed only as the record of the shared fix.

### 4. MINOR — one contract assertion pins the local mechanism instead of the result

- **Where:** `privacy_consent_view_contract_test.dart` — inside "each row after
  the first paints one line":
  `expect(find.ancestor(of: rowOf(0), matching: find.byType(Stack)), findsNothing,
  reason: 'the first row is not wrapped, so it cannot paint a line')`.
- **Why:** every other assertion in that block is a rendered-result check
  (separator `dy ==` row top, `dx` offset 72, right edge, height 1, colour =
  `palette.line`, ownership per row). This one is the only mechanism check, and
  it would fail for the simplification in finding 3 even though the output is
  identical.
- **Fix:** replace it with the mechanism-independent equivalent —
  `expect(dividerOf(0), findsNothing, reason: 'the first row is the card's top edge')`
  — which states the actual contract ("row 1 paints no separator") and passes
  under either implementation.

### 5. MINOR — the build note re-justifies a misquote of the test runner's output

- **Where:** `docs/screens/P04/2_build.md` — Finding 3 is now answered with the
  claim that "`All other tests passed!` is what `flutter test` prints when skips
  exist (0 failures, N skipped), not a failure", and the note quotes
  `00:04 +107 ~2: All other tests passed!` and `00:22 +594 ~2: All other tests
  passed!` as verbatim tool output.
- **Evidence:** I re-ran both suites this review: the runner prints
  `All tests passed!` — `00:15 +645 ~2: All tests passed!` (whole app) and
  `00:02 +118 ~2: All tests passed!` (P04). With skips present the string is
  still "All tests passed!". `~2` / `~3` in the counter already convey the skips,
  so the line reads as a failure without adding information.
- **Fix:** quote the real string. Also refresh the stale claim that
  "`ic_trash.svg` / `NestIcons.trash` still absent from this worktree" — it was
  true at 14:40 and false from merge `ce89889` onward; see findings 1 and 2.

---

## Verified correct (no action)

- **Iteration-3 findings 1 and 2 — both closed.** The promise list is now exactly
  4 × 56 = 224 px with the opt card top at 528 in design terms (probes: list
  288–509, opt card 532–616, both Δ0), and `[P04-4]` is un-skipped and green. The
  first-run upsert now runs inside `_db.transaction`, so two overlapping writes
  serialise and the last one wins; `[P04-9]` is un-skipped with a
  `Future.wait` two-write test at 320/430 style determinism (`privacy_consent_repository_test.dart`
  — both `lastWins` directions, one row, correct stored value), and the
  iteration-2 first-run double-tap guard still passes.
- **The single-`Column` restructure was checked for the risk it introduces:**
  shared `NestList`'s inner `Column` is `CrossAxisAlignment.center`, so a single
  child could have been centred and narrower than the card — a gutter regression
  against the OWNER ALIGNMENT rule. The new
  "320/390/430.dp: the promise rows fill the list card edge" test asserts every
  row's left edge equals the list's, and passes at all three widths; the
  screenshots confirm 20 px gutters. `MainAxisSize.min` keeps the column
  unbounded inside the scroll view.
- **Architecture:** unchanged and compliant — `domain/` holds the entity (plus
  `ConsentOptionIds`) and the abstract repository only; one bloc per feature with
  `LoadRequested` and initial/loading/loaded/failure; DI and routes per feature,
  untouched. `analysis_options.yaml` untouched;
  `git diff main --name-only` filtered for RULES §1 paths returns nothing.
- **Design-system usage:** `NestStatusBar`, `NestNavBar`, `NestList`, `NestCard`,
  `NestToggle`, `NestButton`, `NestBottomCta`, `NestIcon`, `showNestModal` all
  reused; only the promise row and the notice link are feature-private, each
  justified inline. Colours only from `context.nest` / `context.nestText`, type
  only from `NestType`, spacing from `NestSpacing`. The one new literal pair
  (`left: 72`, `height: 1`) has no token and mirrors the shared component's own
  values — see finding 3.
- **DESIGN_SPEC §5 P04 / COPY rule:** every element present in order; copy
  re-verified code point by code point against the HTML source (`Your family’s
  privacy` U+2019, `Exactly what we store — and nothing else.` U+2014,
  `No ads or tracking — ever` U+2014, the four titles/subs, opt title/sub,
  `Continue`, the footnote and the three `aria-label`s), no straight quotes,
  ASCII hyphens or zero-width characters; single equal-weight primary
  `Continue` (ICO nudge rule); opt-in toggle OFF by default; UK spelling.
  `CHILD ORDER` is not applicable — P04 reads and renders no children.
- **Accessibility:** h1 is a header; the four promise rows remain `Semantics`
  containers and are never announced as buttons; the toggle exposes label +
  `toggled` + `enabled`; Back / Continue / notice link are labelled buttons with
  ≥ 44 px targets; the shield keeps its `image` node with the HTML alt text; no
  `maxLines` anywhere, so rows wrap (SPACING_SPEC §9.3/§9.4) and the
  320/390/430 × scale 1.0/1.3 matrix plus 320×568 short screen all pass. The
  added `Divider`s introduce no semantics. Contrast unchanged: sky link 5.42:1
  light / 7.21:1 dark, danger caption 4.73:1 light / 7.37:1 dark.
- **Performance:** `const` widgets throughout; `BlocBuilder` outside the scroll
  view so scroll position survives; one rebuild per toggle tap, none on success
  beyond the stream reconciliation, and the toggle is disabled after a failure so
  there is no rebuild storm; the extra `Stack` layers are paint-only and add no
  layout passes; `emit.forEach` is cancelled when `BlocProvider` disposes the
  bloc on `go`/`pop`.
- **Error handling:** `Continue` is never disabled, the caption is state-aware,
  a stale message is cleared by the next successful stream emission, and the
  first-run write is now atomic and last-write-wins.
- **Children's Code:** no analytics, ads, trackers or SDKs in the diff; no child
  data read; the single write is an optional, parent-only, default-OFF consent
  flag; the kid-mode guard redirects `/privacy` to `/parental-gate` (proof
  green).
- **OWNER BOTTOM-EDGE rule: correct** — the CTA surface reaches the physical edge
  in both themes (`#FFFFFF` / `#1F1C2E` at y 820 and 838) while the design PNGs
  show a cream/near-black strip there, because the HTML `.home-indicator` sits
  outside `.bottom-cta`. The app is the intended behaviour.
- **OWNER ALIGNMENT rule: met except for the divider** — 20 px gutters at
  320/390/430, header block pixel-exact, list and opt card now at design
  positions; findings 1 and 2 are the remaining visual gaps.

## Remaining skipped proofs

`[P04-2]` (trash glyph) and `[P04-7]` (dark shield) are still `skip`-marked.
Both preconditions are now met by merge `ce89889`, so both must be un-skipped in
the same build that lands findings 1 and 2. Until then "all tests pass" does not
mean "no defects open".

## ORCHESTRATOR_NOTES status

| Item | Status |
|---|---|
| 1 — row-4 bin glyph + a test that all four rows find a glyph | **Unmet and now actionable**: `NestIcons.trash` is in the tree (the build could not use it — main merged 14:32, the batch landed 14:42/14:43). Fix is one line → finding 1 |
| 2 — 16 px header offset | **Met**; probes show Δ0 on chevron, h1 and subtitle, nothing moved locally |
| 3 — row heights / dividers → opt card ≈528 | **Met**: list 288–509 and opt card 532–616 are both Δ0 against the design; `[P04-4]` green |
| 4 — bottom panel to the edge, perfect alignment | **Met** (both themes; gutters verified at three widths) |
| 13:42 UPDATE — fix "everything else" (row heights/alignment, review findings, bug findings) | **Met** — findings 1–6 of the previous review all addressed |
| COPY rule | **Met** — verified code point by code point and locked by `privacy_consent_copy_test.dart` |
| CHILD ORDER rule | N/A — no children on this screen |

VERDICT: FAIL