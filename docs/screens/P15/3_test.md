# P15 · Child profile — Stage 3 TEST (iteration 3)

Route `/child-profile` · feature `family` · parent mode · light+dark designs.
Tree: branch `screen/P15` at `422e41e8` ("P15: checkpoint after build
(iteration 3)"), `main` merged through `b2a8b8f`.

Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md` (iteration 3), `2a_build_logic.md`, `2b_build_ui.md`,
`3_test.md` (iterations 1–2), `4_review.md`, `5_ui.md`, `6_bugs.md`,
`FIXES_1.md`, `FIXES_2.md`, `SHARED_REQUEST.md` and
**`ORCHESTRATOR_NOTES.md`** (unchanged since 18:13; all four items still
mandatory and re-verified below).

**No simulator was booted, installed on, driven or screenshotted** (stage 3
must not). No `flutter clean`. No production file was touched: this stage's
diff is `app/test/features/family/**` plus `docs/screens/P15/**`.

---

## 1. Iteration 2 → 3: the red proof is green

The iteration-2 repro stays exactly as written and now passes —
`child_profile_view_test.dart` → *BUG P15-BUG-9: a SECOND deep link must switch
the profile*: `/today` → Leo → Today → Maya now really lands on Maya. The
whole feature suite is green apart from the one new repro in §4.

What iteration 3 changed, and where it is now proved:

| Iteration-3 change | New proof (this stage) |
|---|---|
| `_ChildProfileRoute.didUpdateWidget` + `ChildProfileView.didChangeDependencies` follow the live `?childId=` (P15-BUG-9) | the repro above, plus three lifecycle tests: no re-dispatch on rebuilds/re-entry, a stale `?childId=` cannot resurrect a removed child, dropping the query keeps the chosen child |
| `watchProfile` claims the ledger slot synchronously; only the newest run re-subscribes (review 3) | two real-DB tests: a cascading remove leaves one live subscription (a later ledger write still reaches the profile), and emptying/refilling the family re-subscribes cleanly |
| cross-feature `moneyPounds` import → the barrel's `formatPounds` (per-feature boundary, `ARCHITECTURE.md:75`) | a copy test pinning the exact rendering across magnitudes, zero, and negative balances, with no float noise |
| `ProfileRow` literals → `NestSpacing` tokens | the tile/padding test now also asserts the tokens equal the design's numbers and the padding is exactly `12/10/16/10` |
| repoint query repeats the roster ordering (review 4/5, `SHARED_REQUEST.md` §5) | a three-child test where the answer is only correct if the order is *createdAt, rowid* |
| `kDebugMode`-gated `debugPrint` (review 5) | not observable from a widget test — code-hygiene only, no proof possible |

---

## 2. Tests added this iteration (7 new + 1 strengthened)

### `child_profile_view_test.dart` — +5

* **the selection lifecycle** (the new P15-BUG-9 machinery):
  * *the same id is not re-dispatched on rebuilds or re-entry* — with a mock
    repository counting `selectChild`: a cold entry with `?childId=leo`
    dispatches at most twice (route + view, documented as idempotent), and a
    **theme flip, a text-scale change and a Today→Family round-trip add
    zero** calls. This is the guard that keeps `didChangeDependencies` from
    turning every rebuild into a write;
  * *a stale `?childId=` cannot resurrect a removed child* — deep-link to Leo,
    delete him through the UI, then re-enter the same stale URL: the screen
    falls through to Maya (ADDED order) and stays there;
  * *dropping the query keeps the child the deep link chose* — the Family tab
    root has no `?childId=`; the persisted selection wins, no reset, no crash.
* **the route still guards** — *kid mode still sends the profile to the
  parental gate*: `/child-profile?childId=leo` in kid mode redirects to
  `/parental-gate` and never builds the view (the shell's parent-only
  redirect, `router.dart:85-109`, must survive the new stateful wrapper).

### `child_profile_selection_test.dart` — +3

* *a cascading remove leaves one live subscription for the new child* — one
  transaction across five tables lands several base emissions while the
  handler awaits `cancel()`; after it the profile has switched to Leo with
  **his** money (210p, not Maya's leftovers) and a fresh `quest_bonus` row
  for Leo still reaches the profile (owed 460p). That is the observable proof
  the subscription was neither orphaned nor duplicated.
* *emptying and refilling the family re-subscribes cleanly* — the
  `selected == null` branch emits null, and a newly added child comes back
  with an empty ledger and zero quests (no stale rows from the deleted ones).
* *with three children the repoint picks the FIRST added survivor* — Maya, Leo,
  Robin (roster order asserted); remove Maya ⇒ `leo`, not `robin`; remove the
  never-selected Robin ⇒ the selection does not move.

### `child_profile_copy_test.dart` — +1

* *the `formatPounds` swap keeps the ledger's exact rendering* — £29.99 /
  £0.01 / £0.09 / £9.99 / £1000.00 / £2500.00, negative balances rendered as
  magnitudes (never `-£`, matching the ledger), and a regex sweep over eight
  magnitudes proving two decimals with no float artefacts.

### `child_profile_row_test.dart` — 1 strengthened

* the tile test now also pins `NestSpacing.s10 == 40`, `s3 == 12`, `s4 == 16`,
  `gap10 == 10` and the rendered padding `EdgeInsets.fromLTRB(12, 10, 16, 10)`
  — i.e. the token refactor did not move the design's geometry.

---

## 3. Gates (run in `app/`)

```
$ dart format .
Formatted 496 files (0 changed) in 3.62 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.4s)

$ flutter test test/features/family
00:11 +280 -1: Some tests failed.        # the one red is P15-BUG-10

$ flutter test
01:26 +2561 ~1 -2: Some tests failed.
```

| File | Result |
|---|---|
| `child_profile_view_test.dart` | **+29 −1** (red = P15-BUG-10) |
| `child_profile_selection_test.dart` | +20 |
| `child_profile_row_test.dart` | +15 |
| `child_profile_copy_test.dart` | +21 |
| `child_profile_bloc_test.dart` | +23 |
| `child_profile_states_test.dart` | +12 |
| `child_profile_theme_size_test.dart` | +17 |
| `p15_bugs_test.dart` (stage 6) | +8, no skips |
| `add_children_test.dart` / `p05_bugs_test.dart` / `p05_view_metrics_test.dart` | +119 / +12 / +4 |
| **family total** | **+280 −1** |

Nothing was skipped, deleted or weakened; no `analysis_options.yaml` change;
no `google_fonts`; `grep -rn "skip" test/features/family/` returns no
markers.

### The other suite failure is not P15's

```
test/core/family_time_test.dart › seed + repository zone plumbing
    › kid_home completions are stamped with the family zone
    Bad state: Too many elements
```

Evidence that it is outside this screen (and that I did not touch it):

```
$ git diff main...HEAD --stat -- app/test/core app/lib/core     → (empty)
$ git diff main HEAD --stat -- app/test/core/family_time_test.dart \
      app/lib/core/data/seed.dart                                 → (empty)
```

Both files are byte-identical to `main`; the branch edits no `core/**` file at
all. The cause is the shared demo seed pre-creating a `to_do` completion for
`q-plants`, which that pre-existing test predates — `2_build.md` §"The one
blocking failure" and `SHARED_REQUEST.md` §6 carry the diagnosis and the
one-line fix intent. RULES §1 forbids this screen from editing
`app/test/core/**`, so it is recorded here, **not** patched and **not**
counted as a P15 finding. The single `~` skip is `p12_bugs_test.dart`
(feature `pocket_money`, pre-existing).

---

## 4. Bug found

### P15-BUG-10 — minor — the view can no longer be mounted on its own

`app/lib/features/family/presentation/views/child_profile_view.dart:57` (the
`didChangeDependencies` added in iteration 3):

```dart
final requested = GoRouterState.of(context).uri.queryParameters['childId'];
```

`GoRouterState.of` **asserts** when there is no router ancestor, and
`didChangeDependencies` runs on every mount. So `ChildProfileView` throws

```
GoError: There is no GoRouterState above the current context.
This method should only be called under the sub tree of a RouteBase.builder.
```

whenever it is mounted outside a `RouteBase.builder` — a bare `MaterialApp`
pump in a widget test, a preview/storybook harness, or the design-system
gallery if it ever shows a feature view. Inside the app nothing is broken
(the only builder is `childProfileRoute`), so this is a fragility introduced
by the P15-BUG-9 fix, not a regression a parent can see. Classified **minor**
for that reason; it is still a trap, because the view used to be
self-contained.

**Proof.** `child_profile_view_test.dart` → *BUG P15-BUG-10: the view mounts
without a GoRouter* (red: `GoError` where `null` is expected). The same test
also asserts the screen still shows Maya once it builds, so a fix cannot
cheat by rendering nothing.

**Fix direction (P15-local, one line).** Read the router optionally while
keeping the dependency registration:

```dart
final requested = GoRouter.maybeOf(context)?.state.uri.queryParameters['childId'];
```

`GoRouter.of`/`maybeOf` look the router up through the inherited widget, so
`maybeOf` still re-fires `didChangeDependencies` on a router-state change —
the P15-BUG-9 behaviour survives — while a router-less mount simply skips the
selection, which is what a route-less screen wants anyway.

---

## 5. Re-verified (no findings)

* **`Seed.demo()` / `Seed.empty()`**, with and without a `?childId=`; every
  empty/loading/failure branch; the retry; the remove flow and its toast
  (including a repeated identical failure).
* **Light + dark, 320/390/430, text scale 1.0/1.3**: 20 px gutters, the
  stat grid `1fr 1fr 1fr` + 10 gap, token-only surfaces and type, the five
  design bands unmoved, no overflow anywhere, the danger card reachable by
  scrolling, the scaler clamped at 1.3.
* **Copy**: character-exact against the HTML source (U+2013 / U+00B7 / U+203A /
  U+00A3) including the new `formatPounds` path; no ASCII `-` in the age
  band; `NestType` tracking untouched; no hard-coded colours.
* **Accessibility**: every control exposes `SemanticsAction.tap`; the hero
  name is a heading; every `isImage` node is labelled in both themes;
  `performAction(tap)` drives the real navigation, modal and DB write; tap
  targets ≥ 56 rows / ≥ 44 the rest.
* **Design ellipsis**: at the design's 390 × scale 1.0 nothing in the rows is
  cut, and the column is the CSS arithmetic (`row − 12 − 16 − 40 − 24 −
  trail`); the remaining cuts at 320 and at scale 1.3 are the design's own
  `nowrap` + `ellipsis` fallback where the string cannot fit — recorded, not
  a finding.

## 6. ORCHESTRATOR_NOTES.md — all four items, re-verified in code and tests

1. **Subtitles in full; the trail takes only its intrinsic width** — nothing
   is cut at 390 × 1.0, the trail is its intrinsic 70.71 px and the PIN row's
   column is exactly 187.29 px (`child_profile_row_test.dart`), and the
   `2_build.md` citation in `child_profile_theme_size_test.dart` is green.
2. **Row icons** — `NestIcons.quests` is proven to be the design's circled
   check (read off disk) and the Pocket-money tile is the untinted
   `assets/illustrations/coin.svg`; both glyphs are 24 px boxes centred in
   their 40 px tiles.
3. **Pronoun "their"** — unchanged, per the note.
4. **DB quest counts** — unchanged, per the note.

---

## 7. Verdict

`dart format` clean, `flutter analyze` **No issues found**, P15's own feature
suite **280 tests, 1 red**, and the full suite **2561 pass / 1 skip / 2
fail** — one failure is the shared core test this screen may not edit, the
other is a new **minor** bug this stage found (P15-BUG-10: `ChildProfileView`
throws `GoError` when mounted outside a `RouteBase.builder`, a fragility
introduced by the iteration-3 deep-link fix). The brief's PASS bar is "all
tests pass and no bugs were found".

VERDICT: FAIL