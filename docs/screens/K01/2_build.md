# K01 · Who's playing? — Stage 2 (INTEGRATE, iteration 1)

Job: make the 2a (logic) + 2b (UI) halves compile and pass together. Smallest
change only — no redesign, no re-implementation, no scope creep.

## 1. Summary of 2a (logic) — `2a_build_logic.md`

Feature `kid_home` non-UI layer, all additive and exactly per `1_plan.md` §2.

- **Entity** `KidChild.ageBand` (required; DB stores `7-9`, the view renders
  `7–9` U+2013). Every existing constructor in feature tests updated.
- **Repo** `KidHomeRepository.setActiveChild(childId)` — writes
  `app_state.activeChildId`, repo owns the write like `completeQuest`; no
  `AppSession` dependency. `_toChild` maps `row.ageBand`.
- **Bloc** 4 new events (`KidHomeProfilesRequested`, `KidHomeProfileSelected`,
  `KidHomeProfilesReceived`, `KidHomeProfilesFailed`); state gains `profiles`
  (creation order) + `selectedProfileId` (nullable one-shot); a guarded
  `_profilesSub` mirrors the K03-BUG-15 pattern so the error path really
  releases and Try-again reloads. Every `copyWith`/`withCompletion*` carries
  both new fields (a dropped `profiles` would blank the picker after any quest
  emit). No navigation in the bloc.
- **Tests** `kid_home_bloc_test.dart` extended (roster Maya-first, selection
  writes + emits, retry keeps ONE home subscription, action-error path);
  new `kid_home_repository_test.dart` (DB-backed over `Seed.demo`).

## 2. Summary of 2b (UI) — `2b_build_ui.md`

- `views/profile_picker_view.dart` — placeholder replaced by the real screen.
- `widgets/profile_tile.dart` (new) — the `.k1-tile` card: surface fill, 3 px
  ink border, r32, `kidShadow`, min-height 336; `NestAvatar` 96 → name
  (28/32 w900) → `Age 7–9` → 132 pet circle → `PipAvatar` 112 driven by the
  child's own `pip_style/skin/accessory/stage` (PIP rule; no v1
  `pip_stage_*.svg`). Compact metrics under 150 px tile width (320 px @1.3).
- `widgets/kid_style_helpers.dart` (new) — `avatarColorOf`/`pipStyleOf`/
  `pipSkinOf`/`pipAccessoryOf`/`pipStageName` extracted from `kid_home_view.dart`
  so the pip switch is not duplicated.
- Tiles in `state.profiles` order (CHILD ORDER ruling), selection via
  `BlocListener(selectedProfileId)` → `/kid-pin` or `/kid-home`, tile-local
  busy guard. Failure/loading/empty states, dark mode with zero branches.
- **Tests** `k01_profile_picker_view_test.dart` (13) and
  `k01_profile_picker_geometry_test.dart` (4).

### Integration quality of the merge

The two halves did **not** collide: 2a touched no view/widget and 2b touched no
bloc/event/entity/repository member, so there were no mismatched BLoC states,
events, imports or renamed members to reconcile. The shared `avatarColorOf` /
`pipStyleOf` helper extraction in 2b was the only seam, and it de-duplicated
rather than duplicated. The only genuine breakage was a **stale cross-feature
test anchor** (FIX-1 below).

## 3. FIXES

### FIX-1 — DONE · 4 lint infos blocked `flutter analyze`

`flutter analyze` did **not** print "No issues found" on the merged result:
`prefer_single_quotes` × 4 in `test/features/kid_home/k01_profile_picker_view_test.dart`
(lines 128, 295, 304, 318) — `find.text("Who’s playing?")` written with double
quotes.

Smallest change: switched the delimiters to single quotes. The string contains
U+2019, which is **not** an ASCII `'`, so the literal does not need escaping —
and the character is preserved byte-for-byte. Verified after the edit with a
codepoint dump: all four lines still contain exactly `0x2019` and no ASCII
apostrophe. No copy change, no assertion change.

```
info • Unnecessary use of double quotes … • k01_profile_picker_view_test.dart:128:29
info • … :295:22   info • … :304:22   info • … :318:22
4 issues found.
```
→ `No issues found!`

### FIX-2 — DONE · the only NEW test failure: stale K01 placeholder anchor

`test/features/today/today_view_test.dart` *hand-off button opens
who-is-playing* asserted the K01 **placeholder** title:

```
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "K01 Who is playing": []>
   at today_view_test.dart:271
```

This is the expected consequence of 2b replacing the placeholder view, and it
is the **only** failure the merge introduced (see §4). It is P08's test, not
K01's, and `1_plan.md` did not anticipate it.

Fix = assert the route instead of the placeholder copy, which is the pattern
the codebase already mandates. `test/test_scope.dart:75-77` states it
explicitly: *"Assertions on a pushed screen MUST use this helper and never the
view's title text: screen agents replace placeholder views, but they must not
change the route path."* `pushedPath(tester)` is already used by 4 assertions in
this same file, and shared_batch4 §4 applied exactly this treatment to the
`/quests` hand-off after P10 landed. `main` also already applied it to the P15
anchor in this file (`find.byKey(const Key('p15-hero'))`); K01 was simply the
last placeholder anchor left.

```dart
-      expect(find.text('K01 Who is playing'), findsOneWidget);
-      expect(
-        _currentUri(tester, find.text('K01 Who is playing')).path,
-        '/who-is-playing',
-      );
+      // K01 is a real screen now, so the old `K01 Who is playing` placeholder
+      // anchor is gone. Assert the route only — same treatment shared_batch4
+      // §4 gave the `/quests` hand-off: K01 owns the picker's copy, P08 only
+      // owns the route it pushes.
+      expect(pushedPath(tester), '/who-is-playing');
```

Verified green in isolation. No production code touched — K01's route path is
unchanged, which is the invariant that helper protects.

**Rules note for the orchestrator:** this edit is in
`app/test/features/today/**`, i.e. outside the RULES §1 owned set for `kid_home`.
I made it because (a) leaving it red fails this stage's hard gate, (b) it is a
pure test-hygiene edit caused by K01's own screen landing, (c) shared_batch4
§4 explicitly authorised edits to `app/test/features/today/**` for this exact
stale-anchor class, and (d) `main` carries the identical P15 fix. Flagging it
for confirmation rather than burying it.

### FIXES left / not done

- **None outstanding.** Nothing was deferred.
- Rejected as out of scope (deliberately not "fixed"): no redesign of the
  tiles band (2b's fixed header/footer deviation from the plan's invalid
  `Expanded`-inside-`SingleChildScrollView` tree is documented in `2b` and
  yields the same box positions at design size); no re-sorting of `profiles`;
  no touching the pre-existing red tests in §4.

## 4. The 35 other failures — not K01's, proven by differential baseline

The merged branch reports 35 failures. I did **not** take 2a's word for it; I
built two throwaway worktrees and measured.

| Tree | Result |
|---|---|
| Clean HEAD `6653e2e` (pre-builders), the 7 affected files | **35 failures** |
| Clean `main` `6feb877`, the same 7 files | **0 failures** |
| Merged branch, the 7 files | 35 failures |

`comm` diff of the two failing-test lists:

```
=== new vs clean HEAD ===   (empty)
=== fixed vs clean HEAD === (empty)
```

The 35 are **byte-identical to clean HEAD** — the merge introduced none and
fixed none. They are the stale-base date-skew 2a reported: this branch sits
behind `main`, which carries shared commit `72b703b` *"Pin one app clock to the
seed story day"* (`test/flutter_test_config.dart` now wraps the run in
`Clock.fixed(2026-10-03 08:41Z)`, and `today`/`seed`/`kid_home_repository_impl`
moved off `DateTime.now()` onto `clock.now()`/`appNowUtc()`). Without that
commit the tests compute against the real wall clock (4 Oct) while the seed is
pinned to 3 Oct, so daily completions fall out of period. Per the
orchestrator's PROCESS-ITEMS rule, being behind main is the loop's to handle,
not a finding.

### Proof that the combined result is green on the real base

Because "35 red" would otherwise be indistinguishable from "K01 broke
something", I replayed the loop's merge in an isolated worktree at `main`,
applied the full WIP diff with `git apply --3way` (**all 12 modified files
applied cleanly, no conflicts, no manual resolution**) plus the 5 new files,
and ran the whole suite:

```
Analyzing app...
No issues found! (ran in 5.2s)

01:07 +2736 ~1: All tests passed!
```

2736 pass / 1 skipped / **0 fail** on top of `main`. So once the loop merges
main — which it does before each build — the combined 2a+2b result is fully
green. All scratch worktrees were removed afterwards (`git worktree list` shows
only the loop's own trees).

## 5. Verification tails

Run in `app/` on the merged result:

```
$ dart format .
Formatted 489 files (0 changed) in 1.34 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.5s)

$ flutter test
00:51 +2408 ~1 -35: Some tests failed.
```

That last line is the stale-base set of §4 — 0 new vs clean HEAD, 0 failures on
top of `main`. The K01-owned suites are green on this branch as well:

```
$ flutter test test/features/kid_home/k01_profile_picker_view_test.dart \
                  test/features/kid_home/k01_profile_picker_geometry_test.dart \
                  test/features/kid_home/kid_home_bloc_test.dart \
                  test/features/kid_home/kid_home_repository_test.dart
00:03 +57: All tests passed!

# and on top of main:
01:07 +2736 ~1: All tests passed!
```

## 6. Rule spot-checks (no findings)

- **google_fonts** — none in `lib/features/kid_home` or
  `test/features/kid_home` (the single hit is the word inside a comment in
  `k03_bugs_test.dart:34` asserting its absence).
- **letterSpacing** — none added in `profile_picker_view.dart` /
  `profile_tile.dart`; `NestBalancedText` used for the `.kid-title` heading as
  the BALANCED HEADINGS rule requires.
- **CHILD ORDER** — tiles render `state.profiles` in repo creation order; no
  sort anywhere in the new code.
- **PIP** — per-child `PipAvatar` from DB `pip_style/skin/accessory/stage`
  (Maya mochi·sunny·3, Leo bolt·sky·2); no `pip_stage_*.svg`.
- **ACCESSIBILITY** — tile, lock and Try-again expose `SemanticsAction.tap`;
  `performAction` proven to write `activeChildId`. Unchanged by me.
- **CLOCK** — the two `DateTime.now()` calls in
  `kid_home_repository_impl.dart:70,158` are pre-existing K03 lines that
  `main` already converts to `appNowUtc()`; not K01 code, nothing to do here.
- **No simulator** used (stage 2 is not 5_ui); no `flutter clean`; no
  `analysis_options` change; no skipped tests; no images attached.

### Copy note (observation, not a fix)

The orchestrator COPY rule says to use curly `’` and to compare with the HTML
source character-by-character. `K01-profile-picker.html:42` in fact contains an
**ASCII** apostrophe (`Who's playing?`, U+0027), while the app uses U+2019 per
`1_plan.md` §0. So the HTML source and the plan disagree with each other.
Checked house convention: all 30 HTML sources contain **zero** U+2019, yet
merged features (P02/P03/P04/P07) all ship U+2019 in Dart copy — i.e. the
established convention is "render typographically, whatever the raw HTML has".
The app is right and `2a`'s plan is right; the HTML source is just unpolished
fixture text. Left as-is (changing it to ASCII would break the plan, the tests
and every other screen's convention). The `Age 7–9` / `Age 4–6` en dashes,
`Grown-ups` hyphen, and the `’` all verified against the source.

## 7. Files changed by this stage

- `app/test/features/kid_home/k01_profile_picker_view_test.dart` — FIX-1
  (4 quote delimiters; U+2019 preserved).
- `app/test/features/today/today_view_test.dart` — FIX-2 (placeholder anchor →
  `pushedPath`), flagged in §3 for orchestrator confirmation.

Nothing else touched. No production code changed in this stage.

VERDICT: PASS
