# Fix list after iteration 2

## From 4_review.md
# P04 · Privacy consent — QA code review (STAGE 4, iteration 2)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Reviewed surface: `git diff main...HEAD` **plus** the uncommitted working-tree
build and the untracked `app/test/features/privacy_consent/**` (the loop commits
each iteration). `main` has been merged twice since iteration 1, so this review
also re-baselines against the merged shared components.

`docs/screens/P04/ORCHESTRATOR_NOTES.md` exists, so its items (with the 12:03
UPDATE) are treated as mandatory — status table at the end.

Checks run for this review:

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent        → 16 files, 0 changed
flutter analyze                            → No issues found! (ran in 3.7s)
flutter test test/features/privacy_consent/ → 00:02 +95 ~3: All tests passed!
flutter test  (whole app)                  → 00:11 +582 ~3: All tests passed!
tools/screens/compare.py vs ui/app_light_2.png → mean diff 4.48%
     bands 1.55 / 6.02 / 1.98 / 7.86 / 7.31 / 6.52 / 0.40 / 4.17 %
tools/screens/compare.py vs ui/app_dark_2.png  → mean diff 5.61%
     bands 1.54 / 8.50 / 9.14 / 7.76 / 7.12 / 6.69 / 0.39 / 3.67 %
```

Pixel probes of `design/screens/{light,dark}/P04-privacy.png` vs
`docs/screens/P04/ui/app_{light,dark}_2.png` (logical px, PNG ÷ 3):

| probe | design | app (it. 2) | it. 1 |
|---|---|---|---|
| back-chevron glyph band | 66–80 | **66–80** | 61–76 |
| h1 glyph band | 113–138 | **113–138** | 97–122 |
| subtitle glyph band | 156–170 | **156–170** | 140–154 |
| promise-list card (top) | 289 | **289** | 273 |
| promise-list card (bottom) | 509 | **512** | 490 |
| opt card (top → bottom) | 532–616 | **535–619** | 527–594 |
| bottom-CTA surface | 674–809 | **675–843** | 675–843 |
| strip below CTA, light | `#FBF7F0` | **`#FFFFFF`** ✓ owner rule | ✓ |
| strip below CTA, dark | `#15131F` | **`#1F1C2E`** ✓ owner rule | ✓ |

Mean diff improved 7.52% → **4.48%** (light) and 8.12% → **5.61%** (dark).

---

## Iteration 1 findings — disposition

| # | Finding | Status |
|---|---|---|
| 1 | BLOCKER first-run opt-in dropped / red test | **FIXED** — upsert in `setCrashConsent`; repository test green; `[P04-1]` un-skipped |
| 2 | MAJOR 16 px header offset (shared `NestNavBar`) | **FIXED by the shared merge** (compact bar now 60 px) — probes above confirm the header is pixel-exact; `[P04-3]` un-skipped and green |
| 3 | MINOR `2_build.md` UI claim contradicted by pixels | Superseded — see finding 5 |
| 4 | MINOR magic numbers where tokens exist | **FIXED** for `12/7/16/40` (`s3`/`gap7`/`s4`/`s10`); the token-less literals (`84`, `13`, `56`, `22 / 16`, `decorationThickness`) match `NestListRow` and stay |
| 5 | MINOR bare `'crash'` literal | **FIXED** — `ConsentOptionIds.crash` in the domain entity, used in impl, bloc and tests |
| 6 | MINOR `errorMessage` could never be cleared | **FIXED** — `_unset` sentinel + `errorMessage: null` on fresh stream data |
| 7 | MINOR notice dialog ran the promises together | **FIXED** — four centred lines from a shared `_promiseTitles` const |
| 8 | MINOR dead placeholder widget | **FIXED** — `privacy_consent_placeholder_card.dart` deleted |

New defects found by Stage 6 were also addressed in scope: `P04-5` (double-tap
lost the second tap → optimistic emit) and `P04-6` (a failed OFF write claimed
"it stays off" → state-aware caption). RULES §1 is still respected: `git diff
main --name-only | grep -v 'features/privacy_consent\|test/features/privacy_consent\|docs/screens/P04'`
returns nothing.

---

## Findings

### 1. MAJOR — promise row 4 still ships an empty peach tile (ORCHESTRATOR_NOTES item 1, mandatory)

- **Where:** `app/lib/features/privacy_consent/presentation/views/privacy_consent_view.dart:115-125`
  — `_PromiseRow(title: _promiseTitles[3], subtitle: …, tint: NestTileTint.peach)`
  with no `leadingAsset`; `TODO(P04)` at `:118-123`.
- **Mandatory requirement:** "It must show the red-ink bin glyph like the design,
  light + dark. Add a widget test that all four row icons find their SvgPicture/Icon."
- **Current state:** rows 1–3 now have a real proof
  (`privacy_consent_view_contract_test.dart` — asset name, size 24, tile ink and
  `colorFilter != null` in light and dark, `NestIcon`/`SvgPicture` counts), so
  the orchestrator's second half is done for three rows. Row 4 remains the one
  row with no glyph, and the test now *pins the wrong behaviour*
  (`findsNothing` for row 4). `[P04-2]` stays skipped.
- **Not fixable inside RULES §1, and that is now proven, not assumed:** the
  57 files in `app/assets/icons/` contain no trash can. `ic_bin.svg` is a
  wheelie bin (lid + body + two wheel dots) and `ic_basket.svg` a laundry
  basket; neither matches the HTML glyph
  `M4 7h16M9.5 7V5h5v2M6.5 7l1 13h9l1-13`. `NestIcons`
  (`core/design_system/components/nest_icon.dart:11`) is a core alias of
  `NestlingIcons`, so the entry must be added there too. RULES §1 puts
  `app/lib/core/**` and `app/assets/**` off limits.
- **What the orchestrator must land to close it:**
  1. `app/assets/icons/ic_trash.svg` — 24×24, `stroke="currentColor"`,
     `stroke-width="2"`, round caps, the path above, peach ink via
     `NestTileTint.peach` → `tokens.aPeach`.
  2. `NestlingIcons.trash` + `NestIcons.trash`.
  Then P04 needs exactly one line: `leadingAsset: NestIcons.trash` on row 4,
  the `TODO(P04)` deleted, `[P04-2]` un-skipped, and the
  `findsNothing` assertion flipped to `findsOneWidget`.
  Already filed as `SHARED_REQUEST.md` item 1 (from iteration 1) and still
  unanswered — `git log main -- app/lib/core/design_system/assets/` shows only the
  baseline commit.
- **Severity rationale:** visible design deviation the orchestrator has called
  out by name and 5_ui.md itself calls "a designer would reject". It is major
  because the screen is not visually complete, not because P04 has work left it
  can perform.

### 2. MAJOR — the promise list is 3 px taller than the design, drifting every row after the first (ORCHESTRATOR_NOTES item 3, mandatory)

- **Where:** shared `NestList` inserts real `Divider(height: 1, thickness: 1)`
  widgets between children
  (`app/lib/core/design_system/components/nest_list_row.dart:131-135`), consumed
  by `privacy_consent_view.dart:94`.
- **Evidence:** list card 289→512 in the app vs 289→509 in the design — same top,
  **+3 px** at the bottom; the opt card sits at 535 vs 532; rows are 57 px apart
  where the design is 56 px (`compare.py` bands 3–5 remain the worst:
  7.86 / 7.31 / 6.52 %). The design draws the separators as absolutely
  positioned 1 px `::before` overlays (`.list-row + .list-row::before`), so
  4 × 56 px rows stay 224 px; with real dividers the list is 227 px.
- **Mandatory requirement:** "match row height and divider insets exactly from
  the HTML … so the 'Optional: help improve' card top lands at ≈ y 528 and
  Continue at ≈ y 690."
- **Partly satisfied:** the row heights themselves are now exactly right (56 px,
  40 px tiles at r12, divider indent 72, no padding drift) — the residual is
  purely the 3 divider pixels, so the opt card lands at 530.5 rather than 528.
- **Not fixable inside RULES §1:** the separators come from the shared
  `NestList`. P04 cannot add a flag to it, and rebuilding the list in the
  feature layer to overlay the separators would (a) re-implement a
  design-system component and (b) need `NestCard`, whose `standard` variant is
  `NestRadii.allL` (24) instead of the list's `allM` (16) — the card would
  change shape. Correctly filed as `SHARED_REQUEST.md` item 6 with the exact fix
  (paint the separator over the row boundary — Stack/overlay/negative offset —
  keeping `indent: 72` and the `line` token). `[P04-4]` stays skipped and pins
  `NestList.height == sum(row heights)`.
- **Orchestrator action needed:** one change in `nest_list_row.dart`, e.g.
  `separatorsAsOverlay: true` (default off so no other screen moves), then
  un-skip `[P04-4]`.
- **Severity rationale:** a cumulative 1 px-per-row offset is exactly the
  "nothing a few px off" case of the OWNER ALIGNMENT rule, and the orchestrator
  asked for the exact targets.

### 3. MINOR — the `title: ''` workaround and its `TODO(P04)` are now stale and false

- **Where:** `privacy_consent_view.dart:37-42`.
- **Why:** the comment claims "compact with null title nests Spacer (Expanded)
  inside Expanded and throws ParentDataWidget … Empty title renders the same
  back-only row until core is fixed". The shared merge fixed exactly that —
  `nest_nav_bar.dart:69` now returns `SizedBox.shrink()` for a null **or empty**
  title. `SHARED_REQUEST.md` item 3 even flags the leftover ("the workaround and
  its comment can go"). A stale comment that misdescribes shared code is worse
  than no comment: it will mislead the next agent into "fixing" a bug that does
  not exist.
- **Fix:** delete the `TODO(P04)` comment and the `title: ''` argument; pass
  `NestNavBar(compact: true, onBack: …)` with a null title. Add
  `backSemanticLabel` only if the default ever changes.

### 4. MINOR — the failure revert can restore a value that was never persisted

- **Where:** `presentation/bloc/privacy_consent_bloc.dart:52` —
  `final previous = state.crashConsent;` then `:60` `crashConsent: previous`.
- **Why:** with the new optimistic emit, `state.crashConsent` can be a value
  that is in flight rather than stored. Interleaving: tap ON (optimistic `true`,
  write 1 in flight) → tap OFF (`previous` = the optimistic `true`, optimistic
  `false`, write 2 in flight) → **write 2 fails first**. The revert emits
  `crashConsent: true` while the database still holds `false`, the caption says
  "Crash reports are still on", and because `status == failure` disables the
  toggle the parent cannot correct it until the next stream emission. The
  double-failure path (both writes fail) settles the same way with no stream
  emission to heal it. Narrow — it needs two rapid taps plus an interleaved
  failure — and self-heals in the common cases, so it is minor, not major.
- **Fix:** revert to the *stored* value, which the state already carries and
  which always mirrors the database:
  `final previous = _crashFrom(state.items);` (the existing static helper), or
  expose a `storedCrashConsent` getter. One line; also makes the intent explicit
  next to the optimistic emit.

### 5. MINOR — three claims in `2_build.md` are stale after the shared merge

- **Where:** `docs/screens/P04/2_build.md` — "P04-3 … `[P04-3]` stays skipped"
  (the proof is un-skipped and green, `p04_bugs_test.dart:248-272`); "Residual
  drift is … the −16 px header offset (§5, bands 1/3)" (that offset no longer
  exists — the probes above show the chevron, h1 and subtitle bands identical to
  the design, and the note's own 4.48% figure is post-fix); the test tail
  "`00:11 +568 ~4: All other tests passed!`" (the suite is now `+582 ~3`, and
  "All other tests passed!" reads like a failure).
- **Fix:** correct the three lines. The residual-drift sentence should read:
  the empty row-4 tile (§1), the 3 px divider rhythm (§6) and the light-baked
  dark shield disc (§2), plus font edges and the ignored status-bar clock.

### 6. MINOR — three bug proofs stay `skip`-marked pending shared fixes

- **Where:** `app/test/features/privacy_consent/p04_bugs_test.dart` —
  `[P04-2]` (`:244`), `[P04-4]` (`:315`), `[P04-7]` (`:413`).
- **Why it is not a blocker:** the brief forbids *skipping tests to dodge a
  failure*; these are red-by-design proofs of defects owned by `lib/core/**`,
  each annotated with its repro, its reason and the shared change that turns it
  green, and each runnable with
  `flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart`.
  The alternative — leaving them unskipped — would break the RULES §7
  done-criteria for the whole app.
- **Fix / obligation:** flip each `skip: true` off the moment its shared fix
  lands (`[P04-2]` ← item 1, `[P04-4]` ← item 6, `[P04-7]` ← item 2) and delete
  the `[P04-2]` `findsNothing` assertion in the contract test at the same time.
  Until then the orchestrator must not read "all tests pass" as "no defects
  open" — findings 1 and 2 above are the open ones.

---

## Verified correct (no action)

- **Architecture:** unchanged shape and still compliant — `domain/` holds the
  entity (+ the new `ConsentOptionIds` const) and the abstract repository only;
  one bloc per feature with `LoadRequested` and initial/loading/loaded/failure;
  DI (`registerPrivacyConsent`, GetIt factory) and `privacy_consent_routes.dart`
  untouched. `analysis_options.yaml` untouched; nothing outside RULES §1.
- **Design-system usage:** `NestStatusBar`, `NestNavBar`, `NestList`, `NestCard`,
  `NestToggle`, `NestButton`, `NestBottomCta`, `NestIcon`, `showNestModal` all
  reused; the only feature-private widgets are the promise row and the
  underlined notice link, both justified in the code. Colours come from
  `context.nest` / `context.nestText` only — no hex, no raw `Colors.*` in the
  view; type styles come from `NestType`; every literal that now has a token is
  a token. Nothing re-implements a shared component.
- **DESIGN_SPEC §5 P04:** all elements present in order, copy identical to
  `design/html-source/screens/P04-privacy.html` (curly apostrophes, em dashes,
  UK spelling), single equal-weight primary `Continue` (ICO nudge rule), opt-in
  toggle OFF by default, footnote link present.
- **Accessibility:** unchanged and still green — header on the h1, shield as an
  `image` node with the HTML alt text, promise rows as containers (never
  buttons), toggle exposing label + `toggled` + `enabled`, labelled buttons for
  Back / Continue / notice link, every target ≥ 44 px, no `maxLines` anywhere so
  rows wrap (SPACING_SPEC §9.3/§9.4), 320/390/430 × scale 1.0/1.3 matrix still
  passing. Contrast on token pairs: sky link 5.42:1 light / 7.21:1 dark, danger
  caption 4.73:1 light / 7.37:1 dark.
- **Performance:** `const` widgets throughout; `BlocBuilder` outside the scroll
  view so scroll offset survives; the optimistic emit adds one rebuild per tap
  and the toggle is disabled after a failure, so there is no rebuild storm;
  `emit.forEach` is cancelled when `BlocProvider` disposes the bloc on
  `go`/`pop` — the "write fails after leaving" proof confirms no emit escapes.
- **Error handling:** `Continue` is never disabled, the failure caption is
  state-aware, and the message is now cleared by the next successful stream
  emission (finding 6 of iteration 1 closed).
- **Children's Code:** no analytics, ads, trackers or child data anywhere in the
  diff; the only write is an optional, parent-only, default-OFF consent flag;
  the failure copy now tells the truth about the stored value (P04-6); the
  kid-mode guard redirects `/privacy` to `/parental-gate` (proof green).
- **OWNER BOTTOM-EDGE rule: correct.** The CTA surface runs to the physical edge
  in both themes (probe: `#FFFFFF` / `#1F1C2E` at y 820 and 838), while the
  design PNGs show a cream/near-black strip there because the HTML
  `.home-indicator` sits outside `.bottom-cta`. The app is the intended
  behaviour — do not "fix" it toward the PNG.
- **OWNER ALIGNMENT:** 20 px gutters shared by headline, list, opt card and CTA
  at 320/390/430; the header is now pixel-exact against the design
  (chevron/h1/subtitle bands all Δ0).

## ORCHESTRATOR_NOTES status

| Item | Status |
|---|---|
| 1 — row-4 bin glyph + a test that all four rows find a glyph | **Unmet.** Rows 1–3 proven; row 4 blocked on `ic_trash.svg` + `NestIcons.trash` (SHARED_REQUEST item 1). Fix not available in RULES §1 → finding 1 |
| 2 — 16 px header offset | **Met** by the shared merge; probes confirm Δ0. The 12:03 UPDATE was honoured — P04 moved nothing locally |
| 3 — row heights / 1 px dividers → opt card ≈528, Continue ≈690 | **Partly met.** Row heights and indent are exact; the residual +3 px is `NestList`'s real dividers → finding 2 |
| 4 — bottom panel to the edge, perfect alignment | **Met** in both themes |


## From 5_ui.md
# P04 · Privacy consent — UI check (STAGE 5, iteration 2)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_2.png`, `docs/screens/P04/ui/app_dark_2.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_2.png`, `docs/screens/P04/ui/cmp_dark_2.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md` (items 1–4 + update override).

## Mean diff

- Light: **4.57%** (was 7.52%) — bands: 0 (0–105) 1.56% · 1 (105–211) 6.02% ·
  2 (211–316) 1.98% · 3 (316–422) 7.86% · 4 (422–527) 7.31% · 5 (527–633) 6.52% ·
  6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **5.61%** (was 8.12%) — bands: 0 (0–105) 1.54% · 1 (105–211) 8.50% ·
  2 (211–316) 9.14% · 3 (316–422) 7.76% · 4 (422–527) 7.12% · 5 (527–633) 6.69% ·
  6 (633–738) 0.39% · 7 (738–844) 3.67%

Band 6 ≈ 0.4% confirms pipeline alignment. Status-bar glyphs (mock `9:41` vs OS clock)
ignored per STATUS BAR rule; bottom-edge strip is the OWNER-rule override (app correct).

## Fixed since iteration 1

- Header offset gone: shared compact-nav fix (main `fc981bc`, 44→60 px) landed and merged.
  Probed logical y: back-chevron top 66 design / 66 app; H1 cap top 113 design / 113 app.
  Bands 1–2 dropped 13.18%→6.02% / 6.97%→1.98% (light). Orchestrator item 2 resolved without
  any local move, per the update override.

## Verified matching (no action)

- Presence/order/copy: chevron, H1, sub, 84 px shield, 4 promise rows with exact titles/subs,
  opt card copy, toggle OFF 51×31, primary `Continue`, underlined sky footnote link.
- 20 px side gutters; tile 40/r12; divider indent 72; opt-card 13 v/16 h; CTA bottom-anchored
  at design y; surface-to-edge bottom panel both themes; no overflow/clipping/ellipsis.
- No Pip on this screen → PIP rule N/A.

## Deviations

1. Row-4 tile still has no trash glyph (both themes) — ORCHESTRATOR_NOTES item 1, still open.
   Design value: rust glyph pixels `#BA562E`/`#B9542B` inside the peach tile (col x=52,
   y≈478/490, logical).
   App value: plain `#FFEDE4` across the whole tile — blank.
   Fix (P04 scope): render the bin/trash glyph in `a-peach`/rust at 24 px centred in the
   40×40 tile (SHARED_REQUEST item 1 asset if landed, else the agreed local path) + the
   widget test asserting all four row icons render. Designer-visible; blocks PASS.
2. Dark-mode shield disc still renders light (dark only).
   Design value: disc `#1A2A4A` (patch (160,228)).
   App value: disc `#E6EFFE` — `privacy_shield.svg` bakes the light hex.
   Fix (shared, SHARED_REQUEST item 2): themed shield asset. Designer-visible in dark mode.
3. Residual row-text drift, bands 3–5 ≈ 6.5–7.9% light / ≈ 6.7–7.8% dark (ORCHESTRATOR_NOTES
   item 3, still open).
   Design value: row text lines land exactly; opt card top ≈ y 528, Continue ≈ y 690.
   App value: row titles/subs show ~1 px doubling in the heat-map, accumulating down the list
   (rows ~1–2 px taller than the HTML); header and CTA both anchor correctly so this is purely
   intra-list height (row pad-v / title-sub gap / divider).
   Fix (P04 scope): match row heights and divider insets exactly from
   `design/html-source/screens/P04-privacy.html` (SPACING_SPEC §9: pad-v 7, wrap, indent 72).
   Sub-visible-threshold per row but accumulates; fix alongside deviation 1.

No code edited in this stage (UI check is read-only).


## From 6_bugs.md
# P04 · Privacy consent — bug hunt (Stage 6, iteration 2)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run (empty DB). **No screen code was changed.** Re-hunted the
iteration-2 tree after the build fixes and the shared compact-nav merge
(`main` `fc981bc` via `b93ad6d`/`bccbde8`).

`app/test/features/privacy_consent/p04_bugs_test.dart` now has **15 proofs:
11 green + 4 skipped** (P04-2/P04-4/P04-7 shared-blocked, P04-8 new). Run the
skipped ones with:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 11 passed, 4 failed (the four open defects, by design)
```

Method: re-read the iteration-2 view/bloc/repository plus the shared component
diffs; measured the new simulator shots (`ui/app_{light,dark}_2.png`) against
the design PNGs with pixel probes; probed every edge class in the brief with
throwaway tests before writing anything (first-run upsert races, rapid
double/triple taps, interleaved write failures, async gaps, guards,
persistence); every claim below is reproduced by a committed test.

**New finding this iteration: P04-8 (minor).** Four iteration-1 findings are
fixed and pinned; two majors and one minor remain open, all shared-owned.
The screen still cannot pass: `VERDICT: FAIL`.

## Iteration-1 findings — disposition

| Id | Sev | Finding | Status |
|---|---|---|---|
| P04-1 | major | first-run opt-in silently dropped | **FIXED** — upsert in `setCrashConsent` (`data/privacy_consent_repository_impl.dart:63-87`); `[P04-1]` green; two new first-run guards below |
| P04-2 | major | row 4 empty peach tile (no trash glyph) | **OPEN — shared** (`ic_trash.svg` + `NestIcons.trash` still absent; `SHARED_REQUEST` §1) |
| P04-3 | major | compact nav bar 16 px short | **FIXED by the shared merge** — 60 px bar, chevron centre 69→73, h1 91→107; `[P04-3]` green |
| P04-4 | major | real 1 px dividers inflate the list by 3 px | **OPEN — shared** (`NestList` draws layout-height `Divider`s; §6) |
| P04-5 | minor | rapid double-tap wrote the same value twice | **FIXED** — optimistic emit; `[P04-5]` green |
| P04-6 | major | failed OFF write claimed "it stays off" | **FIXED** — state-aware caption; `[P04-6]` green |
| P04-7 | minor | dark mode renders the light-baked shield | **OPEN — shared asset** (§2) |
| P04-8 | minor | double-failed rapid toggle reverts to an unpersisted value | **NEW** (below) |

## New finding

### P04-8 — a double-failed rapid toggle reverts to a value that was never persisted — MINOR

- **Where:** `app/lib/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart:52`
  (`final previous = state.crashConsent;`) + `:60` (`crashConsent: previous`).
  With the iteration-2 optimistic emit, `state.crashConsent` can be another
  event's **in-flight optimistic** value, not the stored one. (Also flagged by
  the iteration-2 review, finding 4.)
- **Why it matters:** interleaving ON → OFF with both writes failing, the
  first failure reverts to the stored OFF, then the second failure reverts to
  the first tap's optimistic ON: nothing was persisted, yet the switch shows
  ON, the caption says "Crash reports are still on", and `status == failure`
  disables the toggle, so the parent cannot correct it without leaving the
  screen. A never-persisted consent being announced as ON is the wrong
  direction for this control (same root cause can strand other orderings,
  e.g. a failed first tap after a later successful tap).
- **Repro (test):** `--run-skipped … --plain-name '[P04-8]'` — fake repository
  whose ON write fails at 10 ms and OFF write at 50 ms (items stream never
  re-emits); tap twice → expected `NestToggle.value == false` and no "still
  on" caption, actual `true` + caption. Bloc-level probe confirmed
  `state.crashConsent == true`, `status == failure`, stored value `false`.
- **Failing test:** `[P04-8] a double-failed rapid toggle reverts to the
  stored value`.
- **Fix (one line, feature-local):** revert to the stored value the state
  already carries — `final previous = _crashFrom(state.items);` (the existing
  static helper; `items` mirrors the database) instead of
  `state.crashConsent` — or expose a `storedCrashConsent` getter. Review
  finding 4 has the same fix.

## Remaining defects — all shared-owned, none fixable in RULES §1

| Id | Sev | Defect | Evidence (iteration-2 shots) | Action needed |
|---|---|---|---|---|
| P04-2 | major | row 4 "Delete everything anytime" renders an empty peach tile; the design draws the trash glyph | `ui/app_light_2.png` x=52: peach tile 466–505.7 continuous `#FFEDE4` (no glyph pixels); design 463–502.7 with rust glyph | add `app/assets/icons/ic_trash.svg` (path `M4 7h16M9.5 7V5h5v2M6.5 7l1 13h9l1-13`, 24×24, `currentColor`, 2 px, round caps) + `NestlingIcons.trash`/`NestIcons.trash`; then P04 adds `leadingAsset: NestIcons.trash` and `[P04-2]` goes green (one line) |
| P04-4 | major | `NestList`'s real 1 px `Divider`s make the list 227 px instead of 224; every row after the first drifts 1 px and everything below +3 px | app tile tops **295 / 352 / 409 / 466** (57 px apart) vs design **295 / 351 / 407 / 463** (56 px apart); opt card top 530 vs 527; `compare.py` bands 3–5 stay the worst (7.86 / 7.31 / 6.52 % light) | one shared change in `nest_list_row.dart`: paint the separator over the row boundary (Stack/overlay/negative offset) keeping `indent: 72` + `line`; then `[P04-4]` goes green |
| P04-7 | minor | dark mode shows `#E6EFFE` disc + `#FFFFFF` shield body instead of the design's `#1A2A4A` + `#1F1C2E` | dark shot probes: disc `(165,229)` design `#1A2A4A` vs app `#E6EFFE`; body `(195,250)` design `#1F1C2E` vs app `#FFFFFF` | themed shield asset (light + dark variant or token-coloured layers); then `[P04-7]` asserts the dark artwork |

**Mandatory `ORCHESTRATOR_NOTES.md` status:** item 1 **unmet** (P04-2,
blocked on the shared asset); item 2 **met** (shared merge, probes Δ0);
item 3 **partly met** (row heights/indent exact, residual is the 3 divider
px — P04-4); item 4 **met** (bottom panel to the edge both themes, 20 px
gutters, header/CTA aligned).

## Adversarial checks this iteration (cleared, proofs in the file)

- **First-run upsert races — clean.** An ON→OFF double tap on an empty DB
  persists the last tap (`false`) across 5 consecutive runs, so the
  `insertOrIgnore` fallback does not drop the later overlapping write in
  practice; pinned as a new guard test. A first-run opt-in also survives a
  route close/reopen (new guard). Single-tap upsert was already P04-1.
- **Interleaved write outcomes — only the double-failure ordering is wrong.**
  First-fails-then-second-succeeds and first-succeeds-then-second-fails both
  settle on the last successful write's value; captured as P04-8.
- **Async gap:** unchanged — a write failing after the parent leaves the
  screen is caught (bloc 9.2 drops emits after close); proof still green.
- **Guard / deep link:** kid mode still redirects `/privacy` →
  `/parental-gate`; back with no history still lands on `/create-account`.
- **Visual owner rules on the iteration-2 shots:** gutters 20 px on headline,
  list, opt card and CTA; bottom CTA surface runs to the physical edge in both
  themes (`#FFFFFF` / `#1F1C2E` at y 838); header and CTA are pixel-exact
  (h1 113–138, chevron 66–80, Continue 690). The three shared deviations are
  the only visual gaps.
- **Unchanged / N/A for this screen:** text scale 1.3 at 320 px (matrix still
  green), dark contrast on token pairs, Pip rule (no Pip), children/money/
  timezone edge classes (P04 reads no child, quest or ledger data, no dates).
- **New cleanup obligations only (not defects):** the contract test still pins
  row 4's *missing* glyph (`findsNothing`) — flip it with P04-2; the view's
  `title: ''` + obsolete `TODO(P04)` should be dropped now that `NestNavBar`
  handles a null title (review finding 3); `2_build.md` has three stale
  sentences (review finding 5). The next build stage owns these.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → 357 files, 0 changed.
- `flutter analyze` → No issues found.
- `flutter test test/features/privacy_consent/` → **97 passed, 4 skipped,
  0 failed**.
- `flutter test` (whole app) → **584 passed, 4 skipped, 0 failed**.
- `--run-skipped` on the bug file → 11 passed, **4 failed** (P04-2/P04-4/
  P04-7 shared-blocked, P04-8 new), each with its own repro above.

## Verdict

The iteration-1 in-scope bugs are fixed and pinned, the shared nav fix closed
the header offset, and the first-run upsert holds under overlap probes. But
two majors remain visibly open on this screen — the empty row-4 tile (P04-2)
and the +3 px list/row drift (P04-4) — plus the dark shield artwork (P04-7)
and the new double-failure revert (P04-8, minor). The three visual defects are
owned by `lib/core`/assets and need orchestrator action (items 1 and 3 of the
mandatory notes are not met); "all tests pass" must not be read as "no
defects open".

