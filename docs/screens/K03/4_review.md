# K03 Kid home — QA code review (Stage 4, iteration 6)

Scope: feature `kid_home`, route `/kid-home`, kid mode. Reviewed
`git diff main...HEAD` **plus the current working tree**, so the verdict
reflects the code as it stands (per the orchestrator rule, "uncommitted
work / behind main / merge order" are not findings and are not reported).

## Gates run (in `app/`, this iteration)

| gate | result |
|---|---|
| `dart format --set-exit-if-changed .` | ✅ 381 files, 0 changed |
| `flutter analyze` | ❌ **6 issues** — all `test/features/kid_home/probe_temp_test.dart` (finding 3) |
| `flutter test` | ❌ **`+986 -1: Some tests failed`** — `k03_bugs_test.dart: a double tap across frames still completes exactly once` (finding 1) |

Neither gate is green, so the screen cannot pass review this iteration.

## Verified clean (no finding)

- **RULES §1** — the diff touches only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**`, `docs/screens/K03/**`. No `core/`, no
  `app/`, no other feature, no `tools/`. ✅
- **ARCHITECTURE** — feature-first; `domain/` = entities (`kid_child`,
  `kid_quest`, `kid_home_data`) + the abstract repository only; one bloc per
  feature; `kid_home_di.dart` / `kid_home_routes.dart` untouched from the
  foundation. ✅
- **PIP rule** — the feature renders the child's own `PipAvatar`
  (`kid_home_view.dart:686`, `:258`, `:849`) driven by the DB row; no
  `pip_stage_*.svg`, no `PipRive`/`riveEnabled` anywhere in the feature. ✅
- **PERIODS ruling** — `countsForCurrentPeriod(...)` is applied on both read
  (`kid_home_repository_impl.dart:81`) and write (`:161`) paths, with the
  family zone; the day/week/once proofs run un-skipped. ✅
- **COPY** — compared with `design/html-source/screens/K03-kid-home.html`:
  the source uses **straight** apostrophes (verified: zero U+2019 in the
  file) in `Let's do some quests!`, `Today's quests`, `Waiting for Mum`, so
  the screen's straight `'` is correct; `Reading &ndash; 20 minutes` renders
  a real U+2013, matching the seed title asserted in the test. ✅
- **CHILD ORDER** — `watchProfiles()` passes the shared `watchChildren`
  order straight through, no local re-sort; the six-children proof runs
  un-skipped. ✅
- **Bottom edge (owner rule)** — measured on the current captures: at
  x=10/380 the pixels from logical y 800…843 are the dock surface in both
  themes (light `#FFFFFF`, dark `#1F1C2E`) — no meadow/sky strip under the
  dock and none around the home indicator. ✅
- **Gutters (owner rule)** — dock buttons span x 20.0…369.7 in the app and
  x 20.0…369.7 in the design; the header, cards and dock all use
  `NestSpacing.padSide` (20). ✅ (except the pet stage — finding 2)
- **Accessibility** — `NestLockButton` is 56 px (`NestDevice.tapKid`,
  design `.lock-btn.lg`), the quest check is a 28 px ring + 8 px padding =
  44 px hit area, hearts/pet-stage/header/card all carry composed
  `Semantics` labels, no raw error strings are shown to a child. ✅
- **Children's Code** — no analytics, ads, SDK or network in the feature;
  only nickname/coins/Pip look are exposed, the active child only. ✅
- **Error handling** — load failure renders a retryable `_KidFailure` with
  the known child's Pip; a failed completion keeps the list and announces
  through `showNestToast` with kid-safe copy; the repository write is
  idempotent inside one transaction. ✅

---

## Findings

### 1. [blocker] `flutter test` fails: the new "double tap across frames" test cannot find its target
`app/test/features/kid_home/k03_bugs_test.dart:1198` (fails at `:1209`).

```
StateError: Bad state: No element
#7 WidgetController._maybeViewOf  (finders.dart:1383  Iterable.first)
#8 WidgetController.tap          (k03_bugs_test.dart:1209)
```

The test taps the check, pumps one frame, then taps the *same* finder again:

```dart
await tester.tap(check);
await tester.pump();            // releases the per-card latch (K03-BUG-11)
await tester.tap(check);        // ← finder matches nothing any more
```

That single `pump()` is enough for the write to land, the stream to flip the
card (`Mark done` → `Done` in the shared card) and the `BlocListener` to
push `/quest-complete`, so the home's semantics leave the tree and the
second tap throws. Reproduced deterministically:
`flutter test test/features/kid_home/k03_bugs_test.dart --plain-name "a double tap across frames still completes exactly once"` → `+0 -1`.

Fix (test-only, no product change): the intent — *the post-frame latch
release must not allow a second completion row* — belongs at the bloc level,
which is where a "second event after a frame" can actually happen. Dispatch
the event twice with a pump between and keep the row assertion:

```dart
final bloc = BlocProvider.of<KidHomeBloc>(tester.element(find.byType(KidHomeView)));
bloc.add(const KidHomeQuestCompleted(childId: 'maya', questId: 'q-reading', coins: 10));
await tester.pump();
bloc.add(const KidHomeQuestCompleted(childId: 'maya', questId: 'q-reading', coins: 10));
await _settle(tester);
// then assert exactly one done_pending row for q-reading
```

The "one celebration route only / one back press leaves it" half of the
test duplicates `K03-BUG-6: double-tapping the check stacks two celebration
routes` (`:488`), which already passes — drop that half rather than
re-covering it. Whatever the fix, the suite must be green before review.

### 2. [blocker] The pet slot is off-centre by ~35 px and pushes everything below the nest 46–56 px down
`kid_home_view.dart:685-697` (`nestWidth: _kNestWidth, fixedPipHeight: _kPipSlotSize`)
→ shared `nest_pet_stage.dart:105` and `pip_rive.dart:461,469,470`.

`ORCHESTRATOR_NOTES` #1 asks for the design's own slot, and SHARED_REQUEST
#11 landed the API for it — but in explicit-size mode
`stageW = nestW / 0.62 = 419.35`, which is **wider than the 350 px the
content column actually has** (390 − 2 × 20 gutter). `PipNestFallback`
still computes `nestLeft = (stageW - nestW) / 2 = 79.67` and
`stageH = nestTop + nestH(= nestW) + shadowBleed = 276`, so the nest is
laid out as if it were centred in a 419 px box that starts at x=20 — i.e.
**+34.7 px right of centre**, and 40 px taller than the design's 236 px
`.k3-pet`. Measured on the current capture vs the design PNG (logical px):

| landmark | design | app (iter 6) | Δ |
|---|---|---|---|
| pet stage centre x (bubble *and* nest) | 194.8 | **229.6** | **+34.8** |
| speech-bubble bottom border | 300 | 322 | +22 |
| hearts row (coin fill) | 443–454 | 489–500 | +46 |
| section title ink | 489–492 | 535–538 | +46 |
| meadow band top | 523 | 578 | +55 |
| progress bar top→bottom | 527–542 | 583–598 | +56 |
| first quest card top border | 568 | 624 | +56 |
| dock top border | 719 | 719 | 0 ✅ |

`app_light_5.png` (legacy sizing) and `app_dark_10.png` both measure a
centre of 194.7–194.8, so this is a **regression introduced this
iteration**, and it also breaks the `ORCHESTRATOR_NOTES` iteration-5 QA
targets (hearts ≈ 443, title ≈ 490, progress ≈ 520, card ≈ 560). The band
table agrees: `compare.py` band 3 went **7.79 % → 22.84 %** (b5 22.33 %,
b6 18.37 %), mean 11.99 % → 12.52 %. The hero of the screen — bubble, nest
and Pip — visibly sits right of the axis, and the quest column is 56 px
lower than the design, i.e. the owner ALIGNMENT rule ("nothing a few px
off") is broken.

Root cause is shared, so K03 cannot fix it in `core/`:

1. File/extend a SHARED_REQUEST: in explicit-size mode `NestPetStage` must
   clamp `stageW` to the incoming `maxWidth`
   (`stageW = min(nestW / 0.62, maxW)`), or accept an explicit
   `stageWidth:`; and `PipNestFallback` needs a `nestHeight:` (it assumes
   `nestH == nestW`, so it cannot express the design's 260×236 nest at
   all). Files: `core/design_system/components/nest_pet_stage.dart`,
   `core/design_system/motion/pip_rive.dart`. Blocks: yes for the hero slot.
2. Interim, in K03-editable code, centre the over-wide stage box so the
   visible geometry lands on the design axis while the shared fix is pending
   — wrap the stage in the slot padding, e.g.
   `Center(child: NestPetStage(…))` in `_KidPetStage` (a `Center` gives an
   over-wide child a −34.7 px offset and puts bubble+nest back on x=195),
   and pin the block height with a `SizedBox`/`Transform` only once
   `nestHeight:` exists — do **not** re-introduce negative margins.
3. Re-measure with `tools/screens/compare.py` (bands 3–6 must drop back to
   iteration-5 levels) before this is considered closed.

### 3. [major] `flutter analyze` is not clean: a scratch probe test is left in the feature tree
`app/test/features/kid_home/probe_temp_test.dart:10, 40, 45, 49, 53, 65`
(untracked; header: "Temporary probe … (deleted after use)").

6 infos: one `unnecessary_import` plus five `document_ignores` (bare
`// ignore:` suppressions, which RULES §7.1 forbids: *"No issues found (no
ignores)"*). It is a scratch probe — it prints `NestPetStage`/`PipNestFallback`
props and rects — and the leftover `PROBE … centreX=` prints are almost
certainly how the finding-2 offset was discovered. It is not reported as
"uncommitted work": the issue is that a dead file with lint suppressions
sits inside `app/test/features/kid_home/**` and makes the analyze gate
fail; the loop commits each iteration, so it would land on the branch and
on `main`.

Fix: delete `app/test/features/kid_home/probe_temp_test.dart`. If any of its
measurements are worth keeping, land them as real assertions in
`kid_home_view_test.dart` (e.g. "the pet slot is centred on the content
axis" — which would have caught finding 2) with no `ignore:` comments.

### 4. [major] The `.kid-title` heading is not rendered with `NestBalancedText`
`kid_home_view.dart:474-481` (copy at `:476`, style at `:477`).

`design/html-source/components.css:36` gives `.kid-title`
`text-wrap: balance`, and the K03 markup uses exactly that class
(`K03-kid-home.html:61`, `<h2 class="kid-title">Today's quests</h2>`). The
mandatory BALANCED HEADINGS rule requires those headings to be rendered
with `NestBalancedText`; this one is a plain `Text`. Impact is small at
scale 1.0 (the title fits on one line) but grows once the chip and the
title compete in the `Expanded` at larger text scales, and the rule is
explicit.

Fix: after the branch picks up main (which now ships
`core/design_system/components/nest_balanced_text.dart`), swap in

```dart
NestBalancedText(
  "Today's quests",
  style: NestType.kidTitle(color: tokens.ink),
  textAlign: TextAlign.start,   // keep the left edge (owner ALIGNMENT rule)
  maxLines: 2,
)
```

(`NestBalancedText` defaults to `TextAlign.center`, so `textAlign` must be
passed explicitly here.) Never on `.h2`/`.h3`/`.body`/`.caption` — the
failure/empty headings in this file (`kid_home_view.dart:271`, `:276`,
`:332`) correctly stay plain `Text`.

### 5. [minor] Two SHARED_REQUEST entries are stale: the shared API now exists but K03 does not use it
`kid_home_view.dart:815` (quest tile) and `:569-620` (dock labels);
`SHARED_REQUEST.md` #1 and #9.

- **#1** `NestKidQuestCard` grew `tileBackground` and its own doc comment
  says "K03 passes the per-quest tint … from
  `design/html-source/screens/K03-kid-home.html`" — but the view still
  passes only `NestIcon(_iconFor(...), size: 28, color: tokens.ink)`, so
  every tile falls back to `surface2` while the design tints them
  (sky-tint dishwasher, lilac-tint reading, peach-tint tidy). Fix: map
  `item.icon` → `tokens.skyTint / lilacTint / peachTint` and pass
  `tileBackground:`; mark #1 DONE in the file.
- **#9** `NestKidButton` grew `wrapLabel`, documented for exactly this
  screen ("Pass false for narrow slots / large text scales (K03 dock
  'My jar' under fallback fonts)"), and the three dock buttons do not pass
  it, so "My jar" can still wrap to two lines and grow the dock. Fix:
  `wrapLabel: false` on all three; mark #9 DONE.

### 6. [minor] Retrying a failed load stacks live subscriptions
`kid_home_bloc.dart:22-31` + `kid_home_view.dart:286-288`.

`emit.forEach(_repository.watchHome())` never completes, and bloc's default
transformer is concurrent, so the `_KidFailure` "Try again" button starts a
*second* never-ending handler while the first is still subscribed — one
extra fan-out of five Drift watch queries per tap, never cancelled until
the bloc closes. Fix: track the subscription explicitly (e.g. keep a
`StreamSubscription<KidHomeData>? _sub`, use `emit.onEach`, and cancel it
at the top of `_onLoadRequested`), or early-return in `_onLoadRequested`
while a subscription is live.

### 7. [minor] `switchMapStream` lives in the domain layer
`app/lib/features/kid_home/domain/kid_home_repository.dart:54-82`.

A generic stream combinator is plumbing, not a domain abstraction;
`ARCHITECTURE.md` keeps `domain/` to "entities + abstract repository ONLY"
and forbids utils dumping grounds, and `core/data/stream_combine.dart`
already owns `combineLatest2/3/4` for every feature. Fix: move
`switchMapStream` next to them (K03 may not edit `core/` → one line in
SHARED_REQUEST.md), or keep it and mark the request.

### 8. [minor] The hearts caption is 2 px closer to the hearts than the design
`kid_home_view.dart:450-461`.

`K03-kid-home.html:58` puts `style="margin-left:2px"` on the
`Pip is happy today` caption, so the design's gap after the fifth heart is
8 + 2 = 10 px; the row uses `spacing: NestSpacing.s2` (8) with no extra
inset. Fix: wrap the caption in
`Padding(padding: EdgeInsets.only(left: NestSpacing.gap2))` — `gap2` (2)
already exists as a token.

---

## Verdict

The design-system migration, PIP identity, PERIODS ruling, COPY,
Children's Code, bottom-edge and gutter discipline all hold, and the
architecture matches the docs. But three gate/defect items block this
iteration: the suite is **red** (finding 1), `flutter analyze` is **not
clean** because of a leftover probe file (finding 3), and the mandated
pet-slot sizing change has knocked the screen's hero **35 px off the
centre axis** with the whole quest column 46–56 px low (finding 2) — a
regression against iteration 5, whose captures measure a correct centre.
Fix 1 and 3 in this branch, raise the shared request in 2, and re-run the
band table before review again.

VERDICT: FAIL