# Fix list after iteration 1

## From 3_test.md
# K10 · Payout day — 3 TEST (iteration 1)

Feature `kid_jar`, route `/payout-day` (`KidJarRoutePaths.payoutDay`), kid
mode. Per-test timeout `120s` throughout; no simulator was booted, installed on
or driven (only `5_ui` may use one, and only
`604697A9-11DA-462F-9837-396E9CA2493A`). No screen file was patched: the one
real defect this stage found is recorded below, not fixed (stage rule), and no
file outside `app/test/features/kid_jar/**` and `docs/screens/K10/**` was
touched.

## Headline

| gate | command | result |
|---|---|---|
| format | `dart format test/features/kid_jar/payout_day_matrix_test.dart` | `Formatted 1 file (0 changed)` |
| analyze (this stage's file) | `flutter analyze test/features/kid_jar/payout_day_matrix_test.dart` | **No issues found!** |
| analyze (whole package) | `flutter analyze` | 1 issue, **not mine**: `k10_bugs_test.dart:264` `avoid_escaping_inner_quotes` — the concurrent bugs stage's live file (§5) |
| tests (this stage's file) | `flutter test --timeout 120s test/features/kid_jar/payout_day_matrix_test.dart` | **`+76 ~1`** — 76 pass, 1 skipped (the parked bug proof) |
| tests (whole feature) | `flutter test --timeout 120s test/features/kid_jar` | **`+255 ~10`, All tests passed!** |
| tests (whole app) | `flutter test --timeout 120s` | **`+4509 ~16`, All tests passed!** — the first parallel run showed `+4505 ~16 -4`, all four in `paywall/paywall_coparent_test.dart` on a missing `libsqlite3.dylib`; a clean re-run is green and that file also passes standalone (`+7`). Not K10, not reproducible (§5) |
| bug proofs | `flutter test --timeout 120s --run-skipped --plain-name 'K10-BUG-3' …` | passes = the defect is present (§3) |

**One real bug found (K10-BUG-3, major):** at **320 px / 1.3×** two strings
render with an ellipsis — the savings note loses the goal's last word
(`£5.50 went into your Lego Friends…`) and the **`£9.49 to go` money string is
ellipsized mid-word**. The design truncates nothing. Proof parked with
`skip: true` (repo convention) so the suite stays green; repro in §3.

## 1. Baseline on arrival

The build stages left a real, passing suite, so this stage extended rather than
rewrote:

```
flutter test --timeout 120s test/features/kid_jar → +170 ~6, All tests passed!
```

Per file, as inherited:

| file | tests | what it already owned |
|---|---|---|
| `payout_celebration_test.dart` | 12 | `watchLatestPayout` contract (demo Maya 380/550/Lego 1550·2499/62 %, `recordPayout` re-render, no-move → null, no-payout → null, `Seed.empty`, live active-child switch, entity equality + clamps) |
| `kid_jar_bloc_test.dart` | 34 | every event/state path for both screens: load, payout, failure, retry, reload guard, `close()`, internal events, `copyWithPayout`/sentinel `copyWith`/`copyWithLoaded`, `props` |
| `payout_day_view_test.dart` | 9 | seeded copy, a recorded payout re-render, the Pip look, the four navigation destinations, tap-action semantics, empty + failure frames |
| `payout_day_view_geometry_test.dart` | 3 | design bands at 390/1.0/light (title 107/34, rain 180×270@141, notes 427/509, fund 613/143, progress 695, bar to 844), gutters at 320/390/430 |
| `k09_bugs_test.dart` | 17 ~6 | K09 regressions (untouched by this stage) |

## 2. Tests added

One new file, `app/test/features/kid_jar/payout_day_matrix_test.dart`
(**77 tests: 76 live + 1 parked**). It exists because the stage prompt's matrix
was only partly covered, and every real hole was invisible to the inherited
suite.

### 2.1 The device matrix — 320/390/430 × light/dark × 1.0/1.3 (48 tests)

12 cells × 4 assertions:

- **the whole celebration renders and nothing overflows** — every design string
  (`It's payout day!`, both receipt lines and subs, the goal title, `£15.50`,
  `£9.49 to go`, `of £24.99`, `62% there!`, `Thanks Mum!`), the jar-rain box,
  both `PayoutNote`s, the `PayoutFundCard`; the scroll is then dragged so the
  **below-the-fold Pip row** is measured too (`tester.takeException()` is null —
  catches RenderFlex overflow, unbounded constraints and painter assertions).
- **20 px gutters, cards aligned to one edge set** (owner ALIGNMENT rule) — both
  notes and the fund card share `20 … width−20`; the back button, the lock and
  the CTA share the same two edges; the title and the illustration are centred
  on the same axis; and after scrolling, **no drawn string escapes either
  gutter** (the K01 matrix idiom).
- **the bar surface runs to the physical edge** (owner BOTTOM EDGE rule) — the
  rect (`left 0`, `right width`, `bottom 844`) *and* a **painted-raster probe**:
  every row from 4 px under the bar's ink border to the last physical row, at
  x = 2 and x = width−2, plus the full width under the CTA box. A rect
  assertion cannot see a strip painted *inside* the bar's surface box, so the
  raster is the only honest check (§4 proves it).
- **every control meets the 56 px kid floor** — the back `NestIconButton`, the
  `NestLockButton` and the `NestKidButton` are all ≥ `NestDevice.tapKid` wide
  and tall (the parent floor of 44 is implied). The floor itself had never been
  asserted on this screen — only the incidental 390/light numbers.

Plus `a 34px home inset is absorbed by the bar surface, both themes` — with a
real OS home inset the bar grows to 89 + 34 and every probed row at
`y = 843, bar.bottom−33, bar.bottom−1` is the bar's own surface, so nothing
meadow- or sky-coloured shows around the home indicator in either theme.

### 2.2 Dark mode actually had no content coverage (2 tests)

`dark is the light layout: same rects, only the tokens differ` measures **11
surfaces** (back, lock, title, rain, note 1, note 2, fund, progress, caption,
bar, CTA) in both themes and demands exact rect equality — dark may flip
tokens, never padding, border width or spacing. A token guard
(`surface`/`ink`/`coinTint` must differ between the themes) keeps that test from
passing vacuously. Before this, nothing pinned the dark LAYOUT at all.

`every surface on the screen paints from the live theme tokens` (both themes)
reads the real `BoxDecoration`s: both notes = `surface` + a 3 px `ink` border on
all four sides + `NestRadii.allM`; the fund card = `coinTint` + 3 px `ink` +
`NestRadii.allL`; the two `.k10-ico` discs = `leafTint` then `lilacTint` (in
that order); the bar = `surface` + a 3 px `ink` **top-only** border. This is
the "never hard-code colours" rule measured, not assumed.

### 2.3 States — loading had no test at all (6 tests)

- **loading** at 320/1.3: `Loading payout day` semantics node with
  `isLiveRegion`, the spinner, the chrome (back/lock/status bar) still present,
  and no title/notes — then a late emission swaps the celebration in.
- **empty (no payout yet)** at 320/1.3 in **both themes**: copy, no notes, no
  fund card, no CTA, the button ≥ 56 px, no overflow, and `Back home` → really
  navigates to `/kid-home` (semantics tap, not just `tester.tap`).
- **empty under `Seed.empty()`** (no children at all) at 1.3 → the same frame,
  no crash.
- **failure**: copy + ≥ 56 px `Try again` + no overflow at 320/1.3, and the
  lock is still the escape hatch (a kid can never be stranded on the failure
  card: the tap really reaches `/parental-gate`). `Try again` really
  re-subscribes (a **second** `watchLatestPayout()` stream controller exists
  after the retry) and recovers onto the celebration, both by tap and by
  `performAction(SemanticsAction.tap)`.

### 2.4 Accessibility actions and labels (6 tests)

- The two icon buttons carry the design's `aria-label`s verbatim — `Back` and
  `Grown-ups` — with `isButton` **and** `SemanticsAction.tap`, and the lock's
  `performAction` really navigates.
- `the lock tap action opens the gate (only one route)`: after the semantic tap
  a **single** pop must land back on `/payout-day` (no stacked gate).
- `a double tap on the lock pushes exactly one gate`: two down/up **pairs**
  (not two simultaneous pointers — the gesture arena gives a tap to one pointer,
  so a burst would prove nothing), then one pop back to `/payout-day`. This is
  the only coverage of `_GateLockButton._busy`.
- `back pops the route payout day was pushed onto`: the `canPop()` branch the
  inherited suite could not reach (start at `/kid-home`, `context.push`
  `/payout-day`, tap back → `/kid-home`). The `canPop() == false` fallback is
  already covered in `payout_day_view_test.dart`.
- `the title is a header and the illustration is an image`: `It's payout day!`
  is a header; the jar-rain node carries the SVG `aria-label` **verbatim** as an
  image; the progress node carries `62% of the Lego Friends set saved`; each
  receipt is ONE spoken sentence (`<title>. <sub>`); Pip is an image labelled
  `Pip cheering`; and none of them advertises a tap (no phantom buttons).
- `the child's own Pip is rendered, never a v1 stage SVG`: `PipAvatar`
  `mochi · sunny · stage 3 · happy · 72` (the seeded row), and **no `Image` with
  a `pip-stage` asset is mounted anywhere** (PIP rule).

### 2.5 Copy audit, copy fit and the kid background (12 tests + 1 parked)

- `every visible string is ASCII-punctuated like the design` — the twelve
  visible strings are all present; `_title.codeUnitAt(2) == 0x27` (the HTML
  byte at `K10-payout-day.html:39` is U+0027, confirmed by hexdump, not
  U+2019); and no string on the screen contains `’ “ ”`.
- **copy fit, 10 green cells** — `didExceedMaxLines` is false for all twelve
  strings at 320@1.0, 390@1.0, 390@1.3, 430@1.0, 430@1.3 in light **and** dark.
  320@1.3 is deliberately absent: that cell is the bug (§3).
- `the shared KidScope sky and meadow are mounted exactly once` — one `KidScope`,
  one `NestMeadow` **inside** it (a local hill would move the count), and the
  painted sky at y = 8 is the live theme's `kidSkyTop` (±1 per channel, because
  y = 8 is inside the gradient).

### 2.6 Bloc / repository layer — no gaps found, nothing added

The brief asks for "bloc_test for every event/state path". I audited the
inherited coverage event by event (`KidJarPayoutRequested`,
`KidJarPayoutReceived`, `KidJarStreamFailed`, `KidJarLoadRequested`,
`KidJarSnapshotReceived` × the states `initial / loading / loaded / failure`, the
reload guard, `close()`, `copyWithPayout`, the sentinel `copyWith`,
`copyWithLoaded`, `props`) and against `payout_celebration_test.dart`'s
repository contract: **every path is already covered, and duplicating it would
only add noise.** So this stage added **zero** bloc tests — a deliberate,
audited decision, not an omission.

## 3. Bug found — K10-BUG-3 (major): copy is truncated at 320 px / 1.3×

**Not patched** (stage rule: "If a test exposes a real bug in the screen, do
NOT patch the screen — record it").

### 3.1 What is wrong

At the narrowest supported width (320 px) with the app's own maximum text scale
(1.3, `SPACING_SPEC` §10.1 "clamp app `textScaler` to **1.0–1.3**"), two strings
render with an ellipsis:

| string | where | measured | result |
|---|---|---|---|
| `£5.50 went into your Lego Friends set` | `payout_note.dart:64` — `maxLines: 2` on `.k10-t` | natural single-line width **404.5 px** in a **200 px** text column → needs **3** lines | renders `£5.50 went into your Lego Friends…` — the goal's last word is lost |
| `£9.49 to go` | `payout_fund_card.dart:104` — `maxLines: 1` on `.k10-amts b` | natural **121.4 px**, the `spaceBetween` row offers **117.0 px** | renders `£9.49 to g…` — a **money** string cut mid-word |

File:line anchors:
`app/lib/features/kid_jar/presentation/widgets/payout_note.dart:62-68`
(the `.k10-t` `maxLines: 2, overflow: ellipsis`) and
`app/lib/features/kid_jar/presentation/widgets/payout_fund_card.dart:96-119`
(the two `maxLines: 1` amount rows).

### 3.2 Why it is a bug and not a mock artefact

- **The design truncates nothing.** `K10-payout-day.html` sets no `max-lines`,
  no `line-clamp` and no `text-overflow` anywhere on this screen; in the browser
  the note title would wrap to a third line and grow the card, and the amounts
  row would wrap rather than eat a character.
- **Money must never be truncated.** `SPACING_SPEC` §10.11 puts `.money`
  strings on the `softWrap:false` + parent-ellipsis path — cutting
  `£9.49 to go` into `£9.49 to g…` in a money app is the worst case on the
  screen.
- **The configuration is supported.** 320 px and 1.3× are both first-class (the
  app clamps to 1.3 precisely so content still fits; this screen's own matrix
  must cover them).
- **It is not caused by the mock→DB string swap alone.** The seeded goal title
  `Lego Friends set` is the database's truth (DATA OVER MOCKS) and a longer real
  goal name is worse; the fix must be layout, not shorter copy.

Severity split for the fix: the money row is **major**; the note title is the
same defect class (**major** if the fix is one pass over both `maxLines`).

### 3.3 Repro (one command, bug present ⇒ the proof passes)

```
cd app && flutter test --timeout 120s --run-skipped \
  --plain-name 'K10-BUG-3' test/features/kid_jar/payout_day_matrix_test.dart
# → +1: All tests passed!  (the two didExceedMaxLines == true expectations hold)
```

Behaviour matrix measured with a temporary probe (deleted again):

| cell | truncated |
|---|---|
| 320 @ 1.0 | no |
| 320 @ 1.3 | **yes — `£5.50 went into your Lego Friends set`, `£9.49 to go`** |
| 390 @ 1.0 / 1.3 | no |
| 430 @ 1.0 / 1.3 | no |

### 3.4 Suggested fix (for the next build stage — not applied here)

Let the note title wrap as the design does (drop the 2-line cap or raise it to
3 at 320 px, keeping `Flexible` so it can never overflow), and give the amounts
row room instead of capping it at one line — e.g. keep `maxLines: 1` but wrap
the row in a `FittedBox(fit: BoxFit.scaleDown)`, or let the right-hand amount
wrap to two lines under the 1.3× clamp. Then flip this proof from `skip: true`
to live. The green cells in §2.5 will then cover 320 @ 1.3 too.

## 4. The tests are not vacuous — three mutation probes, all reverted

Each probe patched `payout_day_view.dart` temporarily, ran the new file, and was
reverted with `git checkout --` (final `git status`: **no tracked file
modified**):

| # | temporary mutation | result |
|---|---|---|
| 1 | `_GateLockButtonState._open`: `if (_busy) return;` → `if (false) return;` (`payout_day_view.dart:153`) | the double-tap test **fails**: `Expected '/payout-day'`, `Actual '/parental-gate'` — two gates stacked. The `_busy` guard is genuinely covered. |
| 2 | a `Container(height: 34, color: tokens.kidMeadow)` injected **inside** the bar's surface box (`payout_day_view.dart:236-261`) | the raster probe **fails** in light (`[191,232,176]` vs the white surface) **and** dark (`[30,74,58]` vs `#1F1C2E`) — the BOTTOM EDGE check sees what a rect assertion cannot. |
| 3 | removed `FittedBox(fit: BoxFit.scaleDown)` around the title | **nothing failed.** Recorded as an observation in §6, not as a bug: the title's natural width is 207.5 px at 1.0× and 269.8 px at 1.3×, inside the 280 px content box even at 320 px, so the scale-down path is simply never exercised at a supported cell. |

## 5. Suite hygiene, and what is *not* a K10 finding

- `dart format` clean; `flutter analyze` on the added file → **No issues found!**
- The one whole-package analyze issue, `k10_bugs_test.dart:264`
  `avoid_escaping_inner_quotes`, is in the **concurrent bugs stage's live
  file** (it appeared while this stage ran; that file is being rewritten right
  now). I did not touch it — editing another stage's live file is exactly the
  collision RULES §1 exists to prevent.
- The 4 whole-suite reds seen in the first parallel run
  (`paywall/paywall_coparent_test.dart`, all `readCoParentName`) are an
  **environment race**, not a product failure: the error is
  `Couldn't resolve native function 'sqlite3_initialize' … libsqlite3.dylib
  (no such file)` — a native-asset file that concurrent `flutter test` /
  `flutter analyze` processes in this same worktree delete/regenerate while a
  suite is running. Proof: the clean re-run is `+4509 ~16: All tests passed!`
  and that file on its own is `+7: All tests passed!`. Not K10, not
  reproducible, and not something a screen agent can act on.
- No simulator was booted, installed on, screenshot or driven. No
  `google_fonts`, no `DateTime.now()`, no wall-clock assertion (the clock is
  pinned to Sat 3 Oct 2026 09:41 Europe/London by
  `test/flutter_test_config.dart`); every pumped app ends with `disposeApp`
  (test_scope.dart).

## 6. Observations recorded, not bugs

1. **The title's `FittedBox(scaleDown)` is unexercised** (§4 probe 3): the
   longest design title fits even at 320/1.3×, so removing it changes nothing at
   any supported cell. Harmless belt-and-braces; if a future data-driven title
   is longer it becomes load-bearing.
2. **Note 2 is 88 px tall with the database's goal name**, so the fund card top
   reads 613 instead of the mock's 591 (already flagged by 2b/2_build). This is
   DATA OVER MOCKS (`£5.50 went into your Lego Friends set` is longer than the
   mock's `£1.00 went into your Lego fund`) and the UI VERDICT RULE excludes
   DB-driven content; `5_ui.md` PASSed on that basis. K10-BUG-3 is the same
   content pressure showing up as *truncation* at 320/1.3×.

## 7. Coverage against the stage brief

| Required | Where | Status |
|---|---|---|
| bloc_test for every event/state path | audited in `kid_jar_bloc_test.dart` (34) + `payout_celebration_test.dart` (12) — already complete, nothing added (§2.6) | ✅ |
| light + dark | all 12 matrix cells; dark rect equality + token paint in §2.1–2.2 | ✅ |
| widths 320 / 390 / 430 | matrix cells + the inset test at 390 | ✅ |
| text scale 1.0 and 1.3 | matrix cells + the copy-fit group (10 green cells) | ✅ |
| empty / loading / error | §2.3 — 6 tests, loading had **zero** coverage before | ✅ |
| every tap → right route | `Thanks Mum!` → `/kid-home`, back → pop when stacked / home otherwise, lock → `/parental-gate`, `Try again` → real re-subscribe, `Back home` → `/kid-home`, and the lock from the failure frame | ✅ |
| semantics labels on icon buttons | `Back` / `Grown-ups` labels, `isButton`, `hasAction(tap)`, `performAction` drives real navigation; plus header/image/value labels on the title, rain, progress, notes, Pip | ✅ |
| tap targets ≥ 44 parent / ≥ 56 kid | the 56 px kid floor on back, lock, CTA, `Try again` and `Back home`, in all 12 cells | ✅ |
| in-memory Drift, `Seed.demo` / `Seed.empty` | `setUpTestScope()` (demo) + `Seed.empty(db)` for the no-children path + a feature-local fake repository for the loading/error paths | ✅ |
| every pumped test drains Drift | `disposeApp(tester)` in all 77 | ✅ |

## 8. Hand-off

- **Next build stage:** fix K10-BUG-3 (§3.4) and flip its proof from
  `skip: true` to live.
- **Registry:** this stage owns **K10-BUG-3**. The concurrent bugs stage already
  allocated K10-BUG-1 and K10-BUG-2 in `k10_bugs_test.dart`; if it later claims
  `-3` as well, the orchestrator must renumber one of them.
- No `SHARED_REQUEST`: every fix above lives inside
  `app/lib/features/kid_jar/**`.

## 9. Verdict

All 76 live tests of this stage pass, `flutter analyze` is clean for every file
this stage owns, and the whole `kid_jar` suite is green (`+255 ~10`). **But a
real screen defect was found and, per the stage rule, not patched:** at
320 px / 1.3× the savings note loses the goal's last word and the `£9.49 to go`
money string is ellipsized mid-word (K10-BUG-3, major, §3). The brief allows
`VERDICT: PASS` only when all tests pass **and** no bugs were found — one of the
two conditions is not met, so the verdict is FAIL and the loop's next iteration
fixes the two `maxLines`.


## From 6_bugs.md
# K10 · Payout day — bug hunt (Stage 6, iteration 1)

Adversarial pass over the `/payout-day` screen, its BLoC and its repository
path (`watchLatestPayout`), against the demo seed. **No screen code was
changed in this stage.** No simulator was booted, installed on, screenshot or
driven (only stage 5 may, and only `604697A9…`). No image was attached or
uploaded; the design PNGs were only read with the file reader. No
`google_fonts`, no `DateTime.now()`, no wall-clock assertion — the clock is
pinned to Sat 3 Oct 2026 09:41 Europe/London by `test/flutter_test_config.dart`.

**This stage found two new defects and independently confirmed a third:**

| id | severity | status | proof |
|---|---|---|---|
| `K10-BUG-1` | minor (latent) | **open** | 2 skipped proofs, red |
| `K10-BUG-2` | minor | **open** | 1 skipped proof, red |
| `K10-BUG-3` | **major** | **open** — owned by the concurrent `3_test` stage | its proof re-run red; independently reproduced |

Verdict is **FAIL**: `K10-BUG-3` is a major, deterministic truncation of the
seeded money copy at a supported device cell (320 px / 1.3×), and it is
present in this build. The two new findings are one-line fixes for the next
build.

- New proofs: `app/test/features/kid_jar/k10_bugs_test.dart` — **11 green,
  3 skipped** (`K10-BUG-1`, `1b`, `2`). Run them red with:
  `cd app && flutter test --timeout 120s --run-skipped \
  --plain-name 'K10-BUG' test/features/kid_jar/k10_bugs_test.dart`
- `dart format` clean; `flutter analyze --no-pub
  test/features/kid_jar/k10_bugs_test.dart` → **No issues found!**
- K10-BUG-3's proof lives in the stage-3 matrix file (its registry, its id);
  this stage re-ran it and reproduced both measurements with an independent
  scratch probe (since deleted).
- Scope: only `app/test/features/kid_jar/k10_bugs_test.dart` and this file.
  No `app/lib/**`, no core, no other feature, no `tools/screens/**` touched.
  The scratch `_k10_verify_bug3_test.dart` this stage created was deleted; no
  other stage's files were edited.

## Bugs found by this stage

### K10-BUG-1 — a payout request + `close()` in the same tick leaks a live subscription and throws on its first emission (Minor, latent — the K09-BUG-7 defect's exact twin)

**Where:** `app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart:88-105`
(`_onPayoutRequested`). The `await previous?.cancel()` at line 94, the
subscription at 96, the `add` at 97.

**What.** The handler opens with `await previous?.cancel()`. Even with
`previous == null` (the first load) that await suspends the handler for a
microtask, so a `close()` landing in the window finds `_payoutSub` still
`null` and cancels nothing; the handler then subscribes to
`watchLatestPayout()` **after the bloc is closed**. The subscription is never
cancelled, and the first emission calls
`add(KidJarPayoutReceived(…))` on the closed bloc, which throws
`Bad state: Cannot add new events after calling close` from inside the stream
callback (an unhandled async error).

This is the same defect K09 registered as `K09-BUG-7` for the jar half of
this bloc; the payout half (`_onPayoutRequested`) never received the guard.
Both handlers live in the same file, so one fix covers both.

**Repro (the proofs):**

```dart
final repo = _CountingPayoutRepository();
final bloc = KidJarBloc(repository: repo)
  ..add(const KidJarPayoutRequested());
await bloc.close();
await Future<void>.delayed(const Duration(milliseconds: 20));
// K10-BUG-1  → Expected: <0>  Actual: <1>        (live payout subscriptions)
// then emit on the leaked controller:
// K10-BUG-1b → Bad state: Cannot add new events after calling close
```

| | expected | app |
|---|---|---|
| live subscriptions after `add` + `close` | 0 | **1** (leaked, never cancelled) |
| first emission on the leak | dropped | **throws** from `kid_jar_bloc.dart 97:24` |

**Latent:** no user gesture can unmount the route inside the microtask window
(the first frame must render before any control exists), so only programmatic
same-tick teardown — a future caller or a test harness — reaches it. That is
exactly why it is minor, like K09-BUG-7.

**Failing tests:** `K10-BUG-1: a payout request then close releases the
subscription` (`Expected: <0> / Actual: <1>`) and `K10-BUG-1b: the leaked
payout subscription cannot emit after close` (`Bad state: Cannot add new
events after calling close`).

**Suggested fix** (the K09-BUG-7 shape — apply to both handlers):
```dart
await previous?.cancel();
if (isClosed) return;
final sub = _repository.watchLatestPayout().listen(…);
if (isClosed) { unawaited(sub.cancel()); return; }
_payoutSub = sub;
```

### K10-BUG-2 — a goal saved past its target reads "142% there!" beside a full bar and "£0.00 to go" (Minor)

**Where:** `app/lib/features/kid_jar/domain/entities/payout_celebration.dart:61-64`
(`goalPercent`), consumed by `payout_fund_card.dart:84` (progress semantics)
and `:102` (the caption).

**What.** `goalFraction` is clamped to 0…1 (the bar is honest) and
`goalRemainingPence` is clamped at 0 (`£0.00 to go`), but `goalPercent`
divides the **raw** saved amount:

```dart
return ((goalSavedPence * 100) / goalTargetPence).round();
```

Saved past the target therefore renders a percent over 100 — "142% there!"
under a 100%-full progress bar, next to "£0.00 to go" — and the same figure is
announced by the progress semantics ("142% of the Lego Friends set saved").
K09's sibling card clamps first (`JarGoalCard.percent` is
`(fraction * 100).round()` with `fraction` clamped), so the same data reads
"100% there!" there.

**Reachable through the real product API:** `PocketMoneyRepositoryImpl.recordPayout`
caps the move at the payout but never at the goal's remainder — it writes
`savedPence: Value(goal.savedPence + movePence)` unbounded
(`pocket_money_repository_impl.dart:381-389`), the same hole K09-BUG-4 fixed
in `moveToSavings`. The proof uses exactly that API.

**Repro (the proof):** demo seed; then
`recordPayout(childId: 'maya', amountPence: 2000, savingsMovePence: 2000,
goalId: 'goal-lego')`.

| | expected | app |
|---|---|---|
| saved figure | £35.50 | £35.50 |
| "to go" | £0.00 to go | £0.00 to go (clamped) |
| percent caption | ≤ `100% there!` | **`142% there!`** |
| progress bar | full | full (clamped) |

**Failing test:** `K10-BUG-2: a goal saved past its target never reads over
100% there` (`Expected: empty / Actual: WhereIterable<String>:['142%
there!']`).

**Suggested fix** (exactly K09's clamp):
```dart
int get goalPercent {
  if (goalTargetPence <= 0) return 0;
  return (goalFraction * 100).round();
}
```

## K10-BUG-3 (major) — confirmed: 320 px / 1.3× truncates the seeded money copy

Owned by the concurrent `3_test` stage (`3_test.md` §3, proof parked in
`payout_day_matrix_test.dart`, `skip: true`). **Verified independently by this
stage**, not re-filed:

- Re-ran the stage-3 proof:
  `flutter test --timeout 120s --run-skipped --plain-name 'K10-BUG-3'
  test/features/kid_jar/payout_day_matrix_test.dart` → **`+1: All tests
  passed!`** (the defect is present).
- Independent scratch probe (deleted after) pumped the seed at 320 px / 1.3×
  and read the real `RenderParagraph`s:

| string | paragraph box | `didExceedMaxLines` |
|---|---|---|
| `£5.50 went into your Lego Friends set` | 200.0 × 58.0 | **true** |
| `£9.49 to go` | 117.0 × 30.0 | **true** |

The money string is ellipsized mid-word (`£9.49 to g…`) and the savings note
loses the goal's last word. Both are deterministic with the demo seed at a
supported cell (the app intentionally clamps text scale to 1.0–1.3). The fix
is the two `maxLines`/amount-row layout sites the stage-3 note names
(`payout_note.dart:62-68`, `payout_fund_card.dart:96-119`); this stage hands
that to the next build and does not duplicate the id.

## Verified clean this stage (new probes, stay green)

| Category | Probe | Result |
|---|---|---|
| rapid double tap | `Thanks Mum!` tapped twice in one frame | one `/kid-home`, no exception |
| rapid double tap | lock tapped twice in one frame | exactly one `/parental-gate` push; one pop returns to `/payout-day` |
| data edge | longest UK nickname + 7-figure goal + £9,999,999.99 payout at **320 × 1.3** | no overflow, no crash (copy truncation at this cell is K10-BUG-3, above) |
| data edge | Pip look out of range (`stage 9`, bogus style/skin/accessory) | stage clamps to 4, style→mochi, skin→sunny, accessory→none, no crash |
| data edge | active-child switch Maya → Leo while the screen is open | the whole celebration swaps atomically; note 2 hidden; no Maya string survives |
| data edge | no-payout child / `Seed.empty` | empty frame (owned by the stage-3 matrix, re-checked in passing) |
| timezone / instant | companion `Jar →` move 1 s **before** vs **at** the payout instant | before → `movedPence` null; at → attributed (P13 writes both rows with one `now`) |
| persistence | file DB: `recordPayout(420, move 100)`, close, reopen | paid 420, moved 100, saved 1650, nickname Maya |
| money rounding | `jarPounds` 0…300,000 plus 99,999,999 | exact integer-pence strings, no float drift |
| dark contrast | 10 K10 text pairs × light/dark, WCAG formula | all ≥ 4.5:1 (incl. `ink2`/`coinTint`, `ink`/`lilacTint`, `onLeaf`/`leaf`) |
| async gap | dispose the screen mid-load, then write payout + goal | no emit after close, no exception |
| mode guard | `/payout-day` deep link in **parent** mode | renders (kid routes are deliberately not mode-guarded — the K02 convention; the router's parent-only redirect in kid mode is the guard that matters) |
| back nav | deep-linked back (`canPop() == false`) | falls through to `/kid-home` (the pushed-route branch is the stage-3 matrix's) |

Not re-probed because stages 3–5 already own them with evidence: copy bytes,
geometry ±2 px in both themes, semantics labels, tap-target floor, loading /
failure / retry frames, dark token paints, the bottom-edge raster, the KidScope
sky/meadow mount.

## Recorded, not filed

1. **No in-product entry point reaches `/payout-day`.** `grep` over `app/lib`
   finds no navigation to `KidJarRoutePaths.payoutDay` (only the route
   definition; `kid_home` imports the feature for its `My jar` button only).
   DESIGN_SPEC's kid flow lists K10 after K09, and P13's own caption promises
   "Your children will see a payout celebration next time they open
   Nestling." — but there is no unseen-payout concept in the schema and no
   screen that navigates to K10, so the celebration is currently reachable
   only by deep link (which is how the loop screenshots it). This is a
   cross-screen integration gap: the fix touches `kid_home`/`pocket_money`
   and possibly the schema, all outside K10's editable scope (RULES §1). Left
   for the orchestrator / a SHARED_REQUEST rather than a K10 bug id.
2. **A torn frame can pair a new payout note with the old goal figure.** The
   `combineLatest3` stream re-emits per changed table, so the first emission
   after `recordPayout`'s transaction can carry the new ledger rows with the
   old goal figure — already acknowledged and drained in
   `payout_celebration_test.dart`. Unreachable as a visible frame on one
   device (the parent records in parent mode; the child's K10 run starts
   fresh), so recorded, not filed. Same behaviour as K09's accepted
   per-source emission.
3. **The concurrent stage-4 review findings 1–4** (`_PayoutPip` comment
   truncation, the write-only `_PayoutFailure.message`, the stale
   `errorMessage` during a payout reload, and the
   newest-vs-oldest companion-move hardening) are **not re-filed**: none is
   reachable today and none is a K10-BUG-1/2/3 duplicate. Finding 3 is the
   only one a next build might sweep up in the same edit as K10-BUG-1.

## Open registry

| id | severity | status |
|---|---|---|
| **`K10-BUG-1`** | minor (latent) | **open** — same-tick payout request + close leaks a subscription; 2 skipped proofs |
| **`K10-BUG-2`** | minor | **open** — overshoot goal reads "142% there!" under a full bar; 1 skipped proof |
| **`K10-BUG-3`** | **major** | **open** — 320 × 1.3 truncates the money string and the goal name; owned by `3_test`, confirmed here |
| `4_review.md` findings 1–4 | minor | open; cosmetic/invisible/hardening (see above) |
| `5_ui.md` D1–D5 | — | PASS, all DB-driven or owner-rule (no fix) |

## Process items (loop-owned, explicitly NOT findings)

- The concurrent `3_test` / `4_review` / `5_ui` stages were writing and
  running in this worktree while this stage ran. Two early suite reds were
  theirs, not K10's: the combined run that flashed
  `k10_probe_tmp_test.dart` `(setUpAll)` (a scratch file that appeared and
  was deleted mid-run — the file no longer exists) and a transient
  `No space left on device` during one compile. `payout_day_matrix_test.dart`
  alone is green (`+76 ~1`), and this stage's file is green (`+11 ~3`).
- The untracked `payout_day_matrix_test.dart` and the `3_test`/`4_review`/
  `5_ui` notes are other stages' work-in-flight; the loop owns committing
  them and the branch/merge order.
- `dart format` on this stage's file: clean; `flutter analyze
  test/features/kid_jar/k10_bugs_test.dart`: No issues found.

## Verdict

Two minor defects are new (`K10-BUG-1`, the payout handler's missing
same-tick close guard — the twin of K09-BUG-7; `K10-BUG-2`, the unclamped
`goalPercent`), and the stage-3 **major** truncation at 320 × 1.3 is
independently reproduced here. Per the stage rule — PASS only when no major
bugs — the verdict is **FAIL**, and the next build should fix all three:
guard both `*Requested` handlers against close, clamp `goalPercent` to the
clamped fraction, and let the note title / amounts row render whole at
320 × 1.3 (the stage-3 fix note names the two sites). Everything else this
stage probed is clean.

