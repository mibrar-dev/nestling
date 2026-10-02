# P05 · Add children — bug hunt (STAGE 6, iteration 1)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on
`screen/P05` at `90cb27c` (main merged mid-stage: compact nav 44 → 52 px,
`onboarding_kids` seed, P05 feature code unchanged).

Proofs: `app/test/features/family/p05_bugs_test.dart` — **8 tests, all
`skip: true`** with the bug id in the test name, so the normal suite stays
green. Verified failing with
`flutter test --run-skipped test/features/family/p05_bugs_test.dart`
→ **8/8 fail for the recorded reason**.

Gates on this build: `dart format .` 357 files clean · `flutter analyze`
No issues found! · `flutter test` **552 passed, 8 skipped, 0 failed** ·
no file outside RULES §1 touched.

**Result: 1 major (P05-BUG-1, still open), 5 minor, 1 observation.
VERDICT: FAIL** — the major defect makes the form unusable without scrolling
and lets a tap meant for a swatch land on the bottom CTA.

---

## P05-BUG-1 — MAJOR — age chips render as 4 stacked full-width rows; the swatch row (and `10–12`/`13+`) sits under the bottom CTA

**Where:** call site `app/lib/features/family/presentation/widgets/add_child_form_card.dart:70-82`
(chips) and `:91-106` (swatches); root cause
`app/lib/core/design_system/components/nest_chip.dart:74` — the interactive
branch is `ConstrainedBox(min 44×44) → Center → …`, and a factorless `Center`
takes `constraints.biggest`, so inside a `Wrap` run every chip claims the whole
card content width and the `Wrap` breaks after each one.

**Repro (390×844, demo seed, current build):**

```
ageChip-4-6   322×44 box at y 535–579
ageChip-7-9   322×44 box at y 587–631
ageChip-10-12 322×44 box at y 639–683   ← centre 661 is under the CTA (top 658)
ageChip-13+   322×44 box at y 691–735
swatch-sky    y 765–809                 ← below the scroll viewport (bottom 658)
```

* Design (`.chip-row { display:flex; gap:8px }`): one row of four pills; form
  card ≈298 px; every swatch on screen above the CTA.
* App: form card ≈470+ px; `10–12` and `13+` are clipped behind the CTA and all
  five swatches are off-screen.
* Tapping where a swatch is (`tester.tap(swatch-sky)`, no scroll) hits the
  **bottom CTA**, not the swatch; selection never changes. With the pre-merge
  44 px nav the same tap navigated to `/pocket-money-setup` instead.
* After the mid-stage main merge (nav 52 px) the `10–12` chip centre also falls
  under the CTA: a plain tap on `10–12` hits the CTA and the chip is never
  selected.

**Proofs:** `[P05-BUG-1] the four age chips render in one row at 390`
(4 distinct tops `{535, 587, 639, 691}`, expected 1);
`[P05-BUG-1] the avatar swatches are visible and selectable without scrolling`
(swatch bottom 809 > viewport 658; tap leaves peach selected).

**Suggested fix:** the shared `nest_chip.dart` fix already filed in
`SHARED_REQUEST.md` #3 — replace the greedy `Center` with
`Center(widthFactor: 1, heightFactor: 1)` (keeping the 44-min on the pill) or
wrap the pill in `Stack(alignment: Alignment.center)` inside the 44-min
`ConstrainedBox`; or P05-local `IntrinsicWidth(child: NestChip(...))` per the
stage-4 measurement (1 row at 390, ≤2 rows and no overflow at 320/1.3). The
skipped proofs un-skip into the regression test once either lands.

*Note (not a separate finding):* because of this bug the merge of the 52 px
nav pushed `10–12` under the CTA and broke two existing tests
(“age chips are single-select”, “a saved child lands in the database…”). Both
were updated with the same documented scroll workaround the sibling tests
already use; the assertions are unchanged. They pass again, and BUG-1’s own
proofs still fail until the layout is fixed.

---

## P05-BUG-2 — MINOR — two taps delivered in one frame double-submit the same draft

**Where:** `app/lib/features/family/presentation/views/add_children_view.dart:116-126`
(the only guard is `onPressed: null` / `loading: true`, i.e. one frame late);
handlers `bloc/family_bloc.dart:86-124` run concurrently (bloc’s default
transformer), so both read the same `draftNickname`.

**Repro:** with `addChild` gated on a `Completer`, dispatch two taps before any
pump — both `Add another child` ×2 and `Add another child` + `Continue` call
`repo.addChild` **twice**. Against the real repository the two concurrent
inserts produce either **two duplicate child rows** (measured ids
`child-…391` / `child-…395`, both inserted) or, when both land in the same
millisecond, a primary-key collision on `child-<ms>`
(`family_repository_impl.dart:62`) surfaced as a spurious “Something went
wrong — try again” after the first child was in fact saved.

**Proofs:** `[P05-BUG-2] two "Add another child" taps save once`,
`[P05-BUG-2] "Add another child" then "Continue" in one frame saves once`
(both expected 1 call, actual 2).

**Suggested fix:** first line of `_onAddChildRequested` →
`if (state.saveInProgress) return;` (or register the event with
`transformer: droppable()`); optionally make the id collision-proof
(`child-<ms>-<counter>`).

---

## P05-BUG-4 — MINOR — “Try again” leaks the failed load’s watchers

**Where:** `bloc/family_bloc.dart:44-55` (and `:63-72`). `emit.forEach` with an
`onError` callback deliberately does **not** cancel the subscription, so after
a stream error the first `combineLatest2(watchItems, watchChildren)` keeps its
Drift watchers alive; each retry starts another set. P08 fixed the identical
defect with `_closeOnError` (`features/today/presentation/bloc/today_bloc.dart:78-88`).

**Repro / proof:** `[P05-BUG-4] Try again releases the failed load before
re-subscribing` — first `watchItems` subscription errors, “Try again” is tapped;
`watchItems` is called twice but the first subscription’s `onCancel` never runs
(cancels 0, expected 1).

**Suggested fix:** copy the P08 `_closeOnError` stream transform and apply it to
`combineLatest2(...)` in `_onLoadRequested` and to `watchChildren()` in
`_onChildrenRequested`.

---

## P05-BUG-5 — MINOR — typing during an in-flight save is silently discarded

**Where:** `views/add_children_view.dart:66-73` — the save-success
`BlocListener` clears the controller unconditionally, and
`bloc/family_bloc.dart:108-115` emits `draftNickname: ''` unconditionally, so a
nickname typed while the spinner is up (field stays enabled) is wiped from both
the controller and the bloc draft.

**Repro / proof:** `[P05-BUG-5] text typed while the save spinner runs is
preserved` — gated `addChild`; enter “Ollie”, tap Add another, type “Ada” while
saving, complete the insert → field is `''`, expected `'Ada'`.

**Suggested fix:** capture the saved nickname; only clear the controller/draft
when the field still holds that nickname (`state.draftNickname.trim() ==
saved`), or disable the nickname field while `saveInProgress`.

---

## P05-BUG-6 — MINOR — new children always store `ageYears = 7`, whatever band was chosen

**Where:** `data/family_repository_impl.dart:56-75` — `addChild` never writes
`ageYears`, so the schema default 7 (`core/data/app_database.dart:57`) stands
even for a `13+` child (seeded children carry real ages: Maya 9, Leo 6). P08
orders the family “eldest first” by `ageYears`
(`features/today/data/today_repository_impl.dart:82-87`), so every newly added
child sorts as a 7-year-old.

**Repro / proof:** `[P05-BUG-6] a 13+ child stores age years inside its band` —
add “Zara” with the `13+` chip → row `ageBand='13+'`, `ageYears=7` (expected
≥13).

**Suggested fix:** derive `ageYears` from the band inside `addChild`
(monotonic mapping, e.g. 4-6→6, 7-9→9, 10-12→12, 13+→13) or extend the
repository interface with an `ageYears` parameter and pass it from the bloc.

---

## P05-BUG-7 — MINOR — “Who’s in your nest?” is not a header landmark

**Where:** `views/add_children_view.dart:192-197` — raw `Text`; every other
screen heading is wrapped in `Semantics(header: true)` (e.g.
`features/onboarding/presentation/views/welcome_view.dart:235`,
`features/today/presentation/widgets/today_loaded_body.dart:375`), so P05’s h1
is the only heading with no header landmark for screen-reader navigation.

**Proof:** `[P05-BUG-7] Who's in your nest? is exposed as a header`
(`flagsCollection.isHeader` false, expected true).

**Suggested fix:** `Semantics(header: true, child: Text(...))`.

---

## P05-BUG-3 — OBSERVATION — roster order: DB sorts by nickname, the mock shows Maya first

`core/data/app_database.dart:291-296` orders `watchChildren` by `nickname`
(BINARY collation: uppercase before lowercase, accents after ASCII), so the
grid shows Leo (left) then Maya (right); the design mock shows Maya first
(seed insertion order). This is **not a P05 defect** — the screen consumes the
DB order as required by RULES §4, and the existing test locks the behaviour.
No skipped proof: the mock-vs-DB call belongs to the orchestrator (align the
mocks, or switch the shared ordering to creation order). Mixed-case nicknames
(`ada` vs `Zoe`) sort case-sensitively today.

---

## Verified sound (adversarial probes, not findings)

| Area | Result |
|---|---|
| Data edge cases | 0 children → form-only layout; 1 child → one 170 px card; 6 children → 3 rows of the computed tile height, no overflow; empty `watchChildren` list → no grid, CTA intact |
| Long UK names | “Maximilian-Alexander” (20 chars) + 5 more children at 320 px / 1.3× → no exception, ellipsis on the cards; 24-char boundary accepted, 25 rejected inline |
| Money edge cases | P05 renders no coins/£ — £0.00, £999.99, 9999 coins N/A by construction (no money widgets in the diff) |
| Rapid double taps | next-frame re-tap already cannot resubmit (existing test); sub-frame window = P05-BUG-2 |
| Back / deep links | Back → `/privacy`, double-tap idempotent; direct `/add-children` launch lands on the screen; edit → `/child-profile?childId=<id>` per card |
| Kid-mode guard | kid mode deep-link to `/add-children` → `/parental-gate` (onboarding locations are parent-only in `router.dart:96-117`) |
| Restart / Drift persistence | a child added, then a fresh app launch over the same DB → card present |
| Dark mode | token contrast on the dark surface: `ink2` 9.82:1, `ink3` 6.19:1 (≥4.5/3); dark-mode widget tests pass |
| Text scale 1.3 × width 320 | 320/390/430 × 1.0/1.3 matrix green; six children + long names at 320/1.3 no overflow |
| Async gaps / emit after close | closing the bloc mid-save drops late emits cleanly (bloc 9.2.1); `onSaved` callbacks are `mounted`-guarded |
| Timezone / money rounding | P05 has no dates or money — N/A by construction |
| Bottom edge / alignment (owner rules) | `NestBottomCta` surface to the physical edge, 20 px gutters, form card == CTA edges — existing owner-rule tests pass on the merged build |

### Cleanup notes for the fix pass (not findings)

* `NestNavBar` now supports `title: null` after the shared nav fix, so the
  `title: ''` + `TODO(P05)` workaround in `add_children_view.dart:88-92` can be
  simplified.
* Review findings not re-proved here (code quality, no functional defect):
  duplicate `displayAgeBand`/`_displayBand` helpers, presentation helpers
  exported from the bloc file, `onSaved` navigation callback carried on the
  event, swatches on a raw `GestureDetector` (no press feedback/focus stop),
  age-chip group semantics missing, swallowed error log.

VERDICT: FAIL
