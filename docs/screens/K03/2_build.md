# K03 Kid home — build notes (Stage 2 INTEGRATE, iteration 13)

Two builders worked in parallel on `kid_home`. This stage is the integrator:
it confirmed the merged tree compiles and passes, and checked that the two
halves did not contradict each other or re-introduce a workaround the shared
commits on `main` had just made obsolete.

**Gate: PASS** — `dart format .` → *0 changed* · `flutter analyze` →
*No issues found!* · `flutter test` → *`+3273 ~3: All tests passed!`*

**Integration breakage: none.** No BLoC state/event mismatch, no import
break, no renamed member, no failing test. Not one fix was needed to get the
combined result green — the halves were disjoint by construction and the shared
commits they both read had already landed before either builder started.

## 1. The halves as delivered

### 2a — logic (`2a_build_logic.md`)

**No code change, correctly.** FIXES_12 held exactly one item, K03-BUG-16, and
its pixel (hero art 9–10 px high) is a *view/geometry* defect:
`PipNestFallback._explicitBleed` is private in `core/`, which RULES §1 forbids
touching, so nothing in `domain/**`, `data/**` or `presentation/bloc/**` can
move it. 2a verified the mandated logic-side items still hold and changed
nothing:

- PERIODS — `countsForCurrentPeriod(...)` in
  `kid_home_repository_impl.dart:82,162` (zone-aware form, London fallback), so
  a stale-period completion ⇒ "to do" again.
- CHILD ORDER — profiles stream straight from `watchChildren` (creation order).
- CLOCK — `appNowUtc()` only; IDS — no clock-derived ids.
- Contract changes: **none**, so the UI half could not desynchronise from it.

### 2b — UI (`2b_build_ui.md`)

One file changed (`kid_home_view.dart`, −201/+… net mostly deletions) plus the
three view/widget test files. Both mandated items landed and measured:

1. **`bubbleGap: NestSpacing.gap14`** on `NestPetStage` and `_kStageToHearts`
   reverted `21 → NestSpacing.s4` (`ORCHESTRATOR_NOTES` 15:02). The 30-line
   workaround comment is deleted — what is left is the HTML's own arithmetic.
   Measured at the design's real fonts: bubble `125…169`, pet box `183…419`,
   hearts centre `448.0`, progress `527…542`, first card `559`, dock `720`, all
   at ±0.5.
2. **K03's feature-local meadow is gone** (`ORCHESTRATOR_NOTES` 02:45):
   `_MeadowPainter`, the four `_kCrest*` constants, the `CustomPaint` wrapper
   and its `TODO(K03)` are deleted; the lower area is now the shared
   `KidScope` background (four-stop gradient, hard stop at 62 %, shared
   390×136 hills at the bottom) — the KID BACKGROUND rule says K03 paints no
   hill or meadow of its own, and now it provably does not
   (`expect(localBand, findsNothing)`).

### The one design decision I checked rather than assumed

The two halves disagreed about who owns K03-BUG-16: 2a wanted the parked proof
un-skipped in its layer, 2b wanted it left parked. **2b is right, and the
reason is in the rules.** The proof is a widget/geometry test, not a
bloc/repository/data test, so it is not 2a's file; and un-skipping it would
fail *by design* until the shared `_explicitBleed` fix lands, which 2a also
cannot reach. It stays parked, holding the **design's** value (rim 278) so the
4 px residual cannot silently re-base. `ORCHESTRATOR_NOTES` 07:40 item 3 is
explicit: if the shared component cannot produce it without editing `core/`,
write the request with the numbers and stop — do not hack around it. That is
what SHARED_REQUEST #18 now says.

## 2. FIXES_12 items — done / left

| Item | Status |
|---|---|
| K03-BUG-16 — hero art 9–10 px high | **Partly fixed by 2b**: `bubbleGap: 14` closed the reachable half. Rim 269 → **274.0** (design 278), feet 292 → **297.0** (301), head 190 → **194.4** (199). Residual **4 px** is `_explicitBleed` 31.4 → 27.4, one private line in `core/`. Proof parked on the design value. **Left: SHARED_REQUEST #18(b)**, option **(c)** additionally restores the design's ~108 px bowl height (`_explicitBleed → 0` + `nestHeight: 236`); the four K03 pins then move to 278 / 364 / 301 / 198 by changing four constants. |

No other FIXES_12 items existed, so nothing else was in scope.

## 3. Gates (tails, verbatim)

```
$ dart format .
Formatted 546 files (0 changed) in 1.73 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.4s)

$ flutter test --timeout 120s --reporter expanded
01:39 +3273 ~3: All tests passed!

$ flutter test --timeout 120s test/features/kid_home/
00:17 +342 ~2: All tests passed!
```

### The `~3` are all parked shared/other-screen proofs — none is a regression

`grep -rn "skip: " app/test/` returns three hits:

1. `test/features/kid_home/k03_bugs_test.dart:1649` — **K03-BUG-16**, K03's own,
   deliberate, documented above and in `6_bugs.md` / SHARED_REQUEST #18. It is
   the suite's *only* design-value proof of the hero rows, and it is parked
   precisely so it cannot be satisfied by re-basing.
2. `test/features/kid_home/k01_bugs_test.dart:566` — K01's parked proof. K01 is
   a **different screen** (`/who-is-playing`) sharing this feature folder
   because RULES §3 forbids running two `kid_home` screens in parallel.
3. `test/features/pocket_money/p12_bugs_test.dart:321` — another screen's, from
   `main`.

Every other K03 proof runs un-skipped: K03-BUG-1…15, the a11y action suite, the
geometry pins, the shared-background group, bloc 31/31 and repository 40/40
inside the 342.

## 4. Owner / orchestrator rules re-checked in the merged tree

Verified by reading the combined diff and grepping the feature, not assumed:

- **PIP** — the child's own `PipAvatar` (Maya: Mochi · sunny · stage 3) through
  `NestPetStage(pip: …)` in the normal, failure and empty states.
- **KID BACKGROUND / BOTTOM EDGE** — no local painter remains in the feature
  (`grep _MeadowPainter` → nothing); the dock's own
  `Container(color: tokens.surface)` still wraps its `SafeArea(top: false)`, so
  the bar runs y 720 → the physical edge in both themes with no strip under it,
  and the painted grade at (10, 600)/(10, 700) is pinned in both themes.
- **ALIGNMENT** — 20 px gutters unchanged; the removed band's 4 px inset was
  absorbed into the section→progress gap, so no card, bar or edge moved.
- **COPY / FONTS / LETTER SPACING / CHIP ROWS / BALANCED HEADINGS / SHAPES /
  TRIAL / ACCESSIBILITY ACTIONS / PERIODS / CLOCK / CHILD ORDER /
  DATA OVER MOCKS** — `grep` for `GoogleFonts` in `lib/` and `test/` returns
  only a comment; no `DateTime.now()` and no `name[0]` anywhere in the feature;
  `nestAvatarInitial` is used at both avatar sites.
- No `analysis_options.yaml` change, no `flutter clean`, no `flutter run`, no
  simulator booted, installed on, driven or screenshotted (SIMULATORS rule —
  stage 5 only), no image attached to this report.

## 5. LEFT FOR NEXT ITERATION

- **SHARED_REQUEST #18(b)** — `_explicitBleed` 31.4 → 27.4 closes the last
  4 px; option **(c)** (`_explicitBleed → 0` + `nestHeight: 236`) also restores
  the design's bowl height. K03's four pins then move to the design's numbers.
- **SHARED_REQUEST #17b(b)** — the tail's 3 px padding-box offset (no layout
  impact) and **#16(b)** — `_kQuestCardShadowRoom` (`.k3-quests` gap 12 vs the
  card's 6 px shadow reserve) — both unchanged and still open.
- A device UI check (stage 5) to re-measure the band table now that the bubble,
  the pet box and every row below are exact and the meadow is the shared
  background: bands 3–5 should drop and the hero band should shrink to the 4 px
  plus the bowl's height.
- **K03-BUG-16 stays parked** until #18 lands; un-skip it and put 278 / 364 /
  301 / 198 back in `kid_home_geometry_test.dart` in the same pass.

VERDICT: PASS