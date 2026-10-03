# K03 Kid home — QA code review (Stage 4, iteration 12)

Scope: feature `kid_home`, route `/kid-home`, kid mode. Reviewed
`git diff main...HEAD` (merge-base `c8adbe8`, 7 ahead / 20 behind) against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K03
(`docs/DESIGN_SPEC.md:192`), `docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, `docs/screens/K03/1_plan.md` and **every item in
`ORCHESTRATOR_NOTES.md`**, including its 10:14 (pet seating) and 14:37
(iteration-12 verification-only) mandates.

**This stage edited no code** — only this file. **No simulator was booted,
installed on, screenshot or driven** (SIMULATORS rule: only stage 5 may). Pixel
numbers below come from reading the design PNGs with a PIL probe (÷3 to logical
px) and from `flutter test` runs — no device was used by me.

## What is in this iteration's diff

```
 app/lib/features/kid_home/presentation/views/kid_home_view.dart |  40 +-
 app/test/features/kid_home/k03_bugs_test.dart                    |   7 +
 app/test/features/kid_home/kid_home_geometry_test.dart           | 357 +++-
 app/test/features/kid_home/kid_home_view_test.dart               |  56 +
 docs/screens/K03/**                                              | notes only
```

**One `lib/` change**: `_kStageToHearts` 10.75 → 21 plus its rewritten doc
comment (`kid_home_view.dart:84-113`). That constant exists because
`shared/speech_tail` (b1137f3) took the speech bubble's 10.25 px tail out of
flow, so the shared pet block became 10.25 px shorter and dragged every row below
it up; the constant is K03's only lever and puts hearts 448 / title 494 /
progress 527…542 / card 1 559 / dock 720 back on the design's rows. It is the
lever `ORCHESTRATOR_NOTES` 09:52 sanctions ("fix by sizing the `NestPetStage`
box … not by negative margins"; the box is shared-owned now, so the gap carries
the difference).

The rest of the diff is test work: a new real-font geometry group for the whole
column, a painted-pixel speech-tail proof, the absolute-row meadow colour pins,
and a shared dark-pet-glow group.

## Gates

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none .` | ✅ `Formatted 438 files (0 changed)` |
| analyze (whole worktree) | `flutter analyze` | ✅ `No issues found!` |
| analyze (K03 tree) | `dart analyze lib/features/kid_home test/features/kid_home` | ✅ clean for every **tracked** file (see *Process items* for the untracked scratch probe a sibling stage had on disk at 15:31) |
| test (whole app) | `flutter test` | ✅ **`+1935 ~1: All tests passed!`** |
| test (feature) | `flutter test test/features/kid_home` | ✅ **`+186 ~1: All tests passed!`** |
| skipped proofs **in the committed diff** | `git show HEAD:…/k03_bugs_test.dart \| grep "skip:"` | ✅ none — the one skip is uncommitted (see *Process items*) |
| suppressions | `grep -rn "ignore_for_file\|// ignore:" lib/features/kid_home test/features/kid_home` | ✅ none in tracked files |
| fonts | `grep -rn "google_fonts\|GoogleFonts" lib/features/kid_home test/features/kid_home` | ✅ none (one comment mention only) |
| tracking | `grep -rn "letterSpacing" lib/features/kid_home/` | ✅ none |
| colours | `grep -rn "0x[0-9A-Fa-f]\{6\}\|Colors\." lib/features/kid_home/` | ✅ only `Colors.transparent` ×4 (the `Scaffold` backgrounds under `KidScope`) |
| `print`/`debugPrint` | `grep -rn "print(" lib/features/kid_home` | ✅ none |

## Independently measured

**Design PNG, re-measured by me** (`design/screens/light/K03-kid-home.png`,
ink = mean channel < 130, ÷3): the nest block's ink runs **down to y 384**;
rows 385…439 carry no ink at all, and the next ink in the column is the hearts
row at 440. This corroborates iteration 11's finding 2 and **contradicts the
wording of the committed pin** at `kid_home_geometry_test.dart:233`
("the design paints an 86 px tall bowl (y 278…364)") — 278…364 is the number
`ORCHESTRATOR_NOTES` 10:14 mandated, not what the PNG shows. See finding 7.

**Hero-block deviation, reproduced at real fonts by me** (this is the
iteration-12 open bug, `K03-BUG-16`, filed by stage 6 and independent of it):

```
cd app && flutter test --run-skipped --plain-name K03-BUG-16
→ Expected: a numeric value within <2> of <278>
  Actual: 269.01666666666665   (the design's nest rim; −9.0)
```

Its root cause is in `core/` (the shared `NestPetStage` puts `NestSpacing.s2`
= 8 between the bubble and the pet scene, where the design's `.k3-pet` has
`margin: 14px auto 0`), which RULES §1 forbids K03 from editing, and **the
shared half of the fix has already landed on `main`** — see *Carried,
shared-owned* below. It is not counted against K03.

## Rule-by-rule

| rule | verdict | evidence |
|---|---|---|
| RULES §1 (paths) | ✅ | `git diff main...HEAD --name-only` = `app/test/features/kid_home/**` + `app/lib/features/kid_home/presentation/**` + `docs/screens/K03/**`. No `core/`, no `app/app/**`, no other feature, no `tools/screens/`, no `analysis_options.yaml`. |
| ARCHITECTURE (feature-first) | ✅ | `kid_home_di.dart` / `kid_home_routes.dart` untouched this iteration; DI + routes stay per-feature; one bloc with `initial/loading/loaded/failure`; `domain/` = entities + abstract repo (+ finding 9). |
| PIP | ✅ | Every Pip is the active child's own `PipAvatar` from the DB row: `kid_home_view.dart:776` (stage), `:321`/`:329` (failure), `:965` (empty). No `pip_stage_*.svg`, no `PipRive`, no local fork of `NestPetStage`. |
| PERIODS | ✅ | `countsForCurrentPeriod(q.repeatRule, c.createdAt, now, zone)` on the read path (`kid_home_repository_impl.dart:81`) and inside the write transaction (`:161`); no hard-coded dates in `lib/`. |
| DATA OVER MOCKS | ✅ | Counts, coins, happiness and the quest set all come from the stream; the design's stale "3 of 6 done" (`K03-kid-home.html:62`) is correctly **not** hard-coded — the screen renders the DB's 4 of 6. |
| CHILD ORDER | ✅ | Children come from the shared `watchChildren` (createdAt, then rowid); K03 never re-sorts children. |
| BOTTOM EDGE (owner) | ✅ | `kid_home_view.dart:626-720` — `Container(color: tokens.surface)` wraps its `SafeArea(top: false)`, so the inset sits *inside* the surface box. |
| ALIGNMENT (owner) | ✅ | 20 px gutters on header, pet stage, hearts, section row, progress, cards and dock; the new geometry group pins `dock.bottom == NestDevice.height` and card-2 peeking above the dock. |
| COPY | ✅ | Checked character-by-character against `design/html-source/screens/K03-kid-home.html`: "Today's quests" (l.61), "Let's do some quests!", "Pip is happy today", "Waiting for Mum" (l.72 chip), "Waiting for Mum's thumbs-up" (l.72 `aria-label`), "Pip" / "Shop" / "My jar" (l.93-95), "No quests today", "Enjoy playing with Pip!", "Who's playing?", "Oh no! Pip got lost.", "Let's try again." — all use the ASCII `'` (U+0027) the HTML uses; UK spelling "Mum"; coins only, never `£`. The only non-ASCII in `presentation/` is inside comments. |
| FONTS / LETTER SPACING / CHIP ROWS | ✅ | No `google_fonts`/`GoogleFonts`, no `letterSpacing`, no interactive chip rows (both chips are display-only, so `NestChipWrap` does not apply). |
| BALANCED HEADINGS | ✅ | `.kid-title` renders through `NestBalancedText` (`kid_home_view.dart:546`) and nowhere else; no `.h2/.h3/.body/.caption` uses it. |
| TRIAL | ✅ | No `subscription_status` anywhere in the feature. |
| ACCESSIBILITY ACTIONS | ✅ | The header (`kid_home_view.dart:454`) and hearts (`:503`) are the only `Semantics(excludeSemantics: true)` nodes and both are display-only, so neither needs an action; every actual control (lock, card body, card check, three dock buttons, retry, choose) is asserted `hasAction(SemanticsAction.tap)` with `performAction(tap)` changing real state — DB row + pushed route — by the suite (all green). |
| Performance | ✅ | One `BlocBuilder` over a ≤6-item list; `_MeadowPainter.shouldRepaint` compares its two colours only; no `Timer`/`AnimationController`/`Future.delayed` in the feature (RULES §6); `const` where the subtree is constant; `showNestToast` is the shared toast. |
| Error handling | ✅ | `errorMessage` is never rendered on K03 — `_KidFailure` uses fixed child-safe copy and a failed completion shows the fixed `showNestToast` line, so `error.toString()` cannot reach a child. |
| Streams disposed | ✅ | One `StreamSubscription<KidHomeData>` per load, guarded against stacking, released on stream error and in `close()`; the suite's mid-session-error and dispose probes are green. |
| Children's Code | ✅ | No analytics, ads, SDK, network or logging in `lib/features/kid_home`; only the **active** child is read (`watchAppState().activeChildId` → `watchChild(id)`), the quest list is filtered to that child, and writes touch only that child's completion rows. |

---

## Findings

### 1. [minor] `_kStageToHearts = 21` is the screen's only un-tokenised gap, and `main` now owns the fix

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:113`

Every other gap on this screen is a token or a design slot passed as a
component parameter. `21` is neither: it is a 5 px compensation for the shared
`NestPetStage` painting a 8 px bubble→pet gap (the design has 14) and a 1 px
taller bubble. The measurement behind it is reproducible and the doc comment
(`:84-112`) is the best-documented constant on the screen — it names the
shared commit, the arithmetic, and the exact revert.

**The compensation is nonetheless already obsolete.** `main` (20 commits ahead,
`2d69988` / `shared/pet_bubble_gap`) grew `NestPetStage.bubbleGap` and its
report's "Follow-ups screens must do" section says, for K03 specifically:
pass `bubbleGap: NestSpacing.gap14` and set `_kStageToHearts` back to
`NestSpacing.s4` (16). That change cannot be made in this diff — `bubbleGap`
does not exist in this branch's `core/` (verified: no `bubbleGap` in
`nest_pet_stage.dart`), so the call site would not compile — which is why the
branch is behind.

**Fix:** the moment `main` merges, apply both halves together — add
`bubbleGap: NestSpacing.gap14` to the `NestPetStage` call (`:775-787`) and
`_kStageToHearts = NestSpacing.s4`. Then delete the compensation paragraph; if
the hero rim lands at ≈274 against the design's 278 (the shared
`_explicitBleed`, open request #16(a)) leave that to the shared batch and do
not re-pin it here.

### 2. [minor, carried] The dock's ink border spells `3` where `context.nestKid.borderWidth` exists

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:629`

```dart
border: Border(top: BorderSide(color: tokens.ink, width: 3)),
```

`NestKidTheme.borderWidth` is documented as "Chunky ink outline width on kid
surfaces" (`core/design_system/tokens/nest_tokens.dart:105,114-115`) and every
other kid surface reads it (`nest_pet_stage.dart:359`, `nest_keypad.dart:90,135`,
`nest_quest_card.dart:181,330`). This is the only `Border(top: BorderSide(…))`
in `lib/` that hard-codes the width.

**Fix:** `BorderSide(color: tokens.ink, width: context.nestKid.borderWidth)` —
identical pixels (the token is 3), one line, and the probe finder
(`kid_home_geometry_test.dart:166-176`) keeps matching because it reads the
*painted* width, not the literal.

### 3. [minor, carried] Quest cards are built without a key

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:604-609`

`_QuestCard` is a `StatefulWidget` whose `State` carries the tap latch `_busy`
and whose `didUpdateWidget` only resets it when `status` or `completionToken`
changes. Without a key, `State` matches **by position**: if the list ever
reorders (a parent renames a quest, so the repository's title sort changes, or a
quest disappears and the gap closes) the latch migrates to a different quest and
`didUpdateWidget` sees an unchanged status and leaves it there.

**Fix:** `key: ValueKey(item.questId)` on `_QuestCard` — one line, no visual
change, and the list becomes identity-correct for the whole pipeline.

### 4. [minor, carried] `kid_home_di.dart` documents a file that does not exist

`app/lib/features/kid_home/kid_home_di.dart:7-8`

> Registers the KidHome feature. The repository is Drift-backed; the old
> in-memory fake data source is kept on disk for reference but is NOT wired
> into the app.

`grep -rn "kid_home_fake_data_source" app/lib/` returns **nothing** — there is
no such file. The comment sends the next reader looking for a file that is not
there and implies a dead-code risk that does not exist.

**Fix:** delete the second clause, e.g. "Registers the KidHome feature: the
Drift-backed repository as a lazy singleton and `KidHomeBloc` as a factory."

### 5. [minor] Duplicated comment block in the meadow pin

`app/test/features/kid_home/kid_home_geometry_test.dart:417-426`

The copy/paste left two consecutive paragraphs that both start "The regression
this pins: flat navy" — the first (417-420) was superseded by the second
(421-426) and never deleted. This is the file that carries the orchestrator's
10:52 item-1 proof, so a reader has to work out which half is current.

**Fix:** delete the first paragraph (4 lines); keep the second.

### 6. [minor] The pixel probe does not emulate the device's bottom inset

`app/test/features/kid_home/kid_home_geometry_test.dart:112-118`
(`_pumpForPixels`)

It sets `physicalSize` and `devicePixelRatio` but not `tester.view.padding` /
`viewPadding`, so the probe runs on a 0 px bottom inset, while the sibling
geometry group in the same file emulates 34 px (`:304-305`) and the design —
and the dock-top-720 pin — assume 34. The assertions hold today only because
the painter's gradient is expressed in absolute rows (`gradeSpan / h`).

**Fix:** add the two `FakeViewPadding(bottom: 34 * 3)` lines to
`_pumpForPixels`, so both geometry groups emulate the same device.

### 7. [minor] The committed hero pins state the mandated numbers as if they were the design's

`app/test/features/kid_home/kid_home_geometry_test.dart:232-233, 250, 257-258,
266, 269`

```
reason: 'the design paints an 86 px tall bowl (y 278…364)'
expect(rimY, closeTo(269, 2), reason: "the design's rim is 278 — 10 px high …")
reason: 'the design paints the bowl bottom at 364 (#18)'
```

Re-measured on `design/screens/light/K03-kid-home.png` just now, the nest ink
runs to **y 384** and nothing is inked between 385 and 439 — so the design's
bowl is neither 86 px tall nor floored at 364. The values themselves are
**not** K03's doing: `git show main:…/kid_home_geometry_test.dart` already
pins 269 / 355 / 292 / 190 (the shared batch re-based them on purpose, per
`pet_bubble_gap_REPORT.md`'s "intentionally untouched"). What K03 added is the
`reason:` text — and that text now asserts the mandate's number as the design's.

**Fix (docs-in-a-comment only, no core edit):** correct the two reason strings
to what the PNG shows — the design's nest ink spans y 265…384 — and keep the
shared component's 269/355/292/190 as the current app values with the shared
owner named. Do **not** move the pins here; the shared batch owns them, and
finding 1's revert will move them anyway.

### 8. [minor] The new column-geometry test hard-codes the seeded card count

`app/test/features/kid_home/kid_home_geometry_test.dart:325`
(`expect(cards, 6)`)

A geometry test should fail for a geometry reason. This line fails whenever the
demo seed's quest count for the active child changes, with a geometry-shaped
error message. (DATA OVER MOCKS makes the count the seed's business, not this
screen's.)

**Fix:** derive the count instead —
`final cards = find.byType(NestKidQuestCard).evaluate().length; expect(cards, greaterThanOrEqualTo(2));`
(the loop below already walks `0..cards`, and "card 2 peeks above the dock"
needs ≥2).

### 9. [minor, carried, shared] `switchMapStream` lives in `domain/`

`app/lib/features/kid_home/domain/kid_home_repository.dart:54-82`

A generic stream combinator, not a domain abstraction; `ARCHITECTURE.md:71`
restricts `domain/` to "entities + abstract `<feature>_repository.dart` ONLY",
and `core/data/stream_combine.dart` already owns `combineLatest2/3/4`. The
explanatory comment (why `asyncExpand` cannot be used) is good and must travel
with the function. Already filed as SHARED_REQUEST #14; the three call sites
(`kid_home_repository.dart:24`, `kid_home_repository_impl.dart:23,38`) are
mechanical import swaps. Nothing is available inside K03.

### 10. [minor, docs in a K03-owned file] `SHARED_REQUEST` #17 is stale and #18 is already fixed on `main`

`docs/screens/K03/SHARED_REQUEST.md` #17, #17b(b), #18

* **#17** ("design white y 152→174 (23 px), app white y 152→164 (13 px)", asking
  the owner to "make the tail's inner fill reach the tail's tip") is the
  inverted wording iteration 11 flagged, and it describes a tail that no longer
  exists: `shared/speech_tail` (b1137f3) made it a solid 18×9 ink overflow, so
  there is no interior fill to extend.
* **#17b(b)** (tail 3 px low: CSS `bottom: -9px` resolves against the padding
  box, Flutter's `Positioned(bottom: -tailHeight)` against the border box) is
  still open and still valid — one line in core, cosmetic, zero layout impact.
* **#18** ("the shared pet stage's speech→pet gap is 8 px where the design has
  14", `Blocks: **yes for the hero block**`) has been **fixed on `main`**:
  `2d69988` / `79d82c5` `shared/pet_bubble_gap` grew `NestPetStage.bubbleGap`,
  and its report names K03's exact follow-up. The remaining hero residual is
  the `_explicitBleed` 31.4 → 27.4 (option (b) of #18), which is already the
  subject of open request #16(a).

**Fix (docs only — `SHARED_REQUEST.md` is K03's own file):** mark #18 LANDED
with the commit and the two-line K03 follow-up (finding 1), strike #17's
inverted wording, and keep #17b(b) plus #16(a) as the only open hero items.
Leaving #18 filed as blocking is misleading: the orchestrator should not
re-dispatch work that is already merged.

---

## Carried, shared-owned, deliberately NOT counted against K03

* **The hero block's 9 px shift** (nest rim 269 vs 278, Pip head/feet −9).
  Root cause is the shared `NestPetStage` bubble→pet gap — `core/`, which RULES
  §1 forbids this screen to edit — and `main` has already shipped the fix with
  K03's follow-up written down. K03 could not make the call-site change in this
  diff because `bubbleGap` does not exist on this branch; that is the
  branch-behind-main process item, not a code defect. Reproduced above so the
  next stage can re-verify it after the merge.
* **The bowl squash** (`nestHeight: 188` painting a 236×234 art into 236×188,
  so the floor is short) — the value is mandated by `ORCHESTRATOR_NOTES` 10:14
  and the only way to paint the art's own aspect is in `core/`.
* **The dark pet glow** — shared, owned by `shared/pet_glow`; the new group in
  `kid_home_view_test.dart:647+` pins that K03 renders the shared fade (ends
  fully transparent) and paints no local disc, so the regression cannot land
  here either.
* **The feature-local `_MeadowPainter`** (`kid_home_view.dart:802-845`) stays
  behind SHARED_REQUEST #6's two missing `KidScope` gradient stops, and the
  absolute-row colour pins added this iteration (`(10,600)`/`(10,700)`,
  light + dark, derived from the two tokens) keep it honest until then.
* **The five baseline placeholder views** of this feature still render
  `state.errorMessage` verbatim into child-facing UI (`kid_pin_view.dart:21`,
  `profile_picker_view.dart:21`, `quest_detail_view.dart:21`,
  `quest_complete_view.dart:21`, `kid_home_done_view.dart:21`). None is in this
  diff and K03's own view never renders it, so it is not a K03 finding — but
  K03 owns the bloc that fills that field with `error.toString()`, and it is a
  Children's Code issue the moment those screens go live. Unchanged from
  iteration 9's cross-screen note.

## Recorded, not raised

* **Alphabetical quest sort** (`kid_home_repository_impl.dart:73`) — mandated by
  `1_plan.md` §(a), and the orchestrator ruled at 10:52 that quest order comes
  from the database. The design's own card 2 is creation order, so this stays a
  deliberate, documented difference.
* **`KidQuestModel`** has no references in `lib/` or `test/` — but all 18
  features carry the same ARCHITECTURE-mandated `fromJson`/`toJson` model, so it
  is the foundation's shape, not K03's debt.
* **`verifyPin` returns `true` when a child has no PIN hash** (Leo in the demo
  seed). Deliberate foundation behaviour on `main`, consumed by K02; noted for
  the gate screens.

## Process items (explicitly not findings)

* **A sibling stage has uncommitted work in this worktree right now** (15:31):
  `k03_bugs_test.dart` and `kid_home_geometry_test.dart` modified,
  `probe_temp_test.dart` untracked again (the same scratch probe stage 5/6 has
  created and deleted repeatedly — it produced 2 `document_ignores` infos in a
  targeted `dart analyze` while I ran it; `flutter analyze` on the whole
  worktree a minute earlier was clean), and `5_ui.md` / `6_bugs.md` /
  `ORCHESTRATOR_NOTES.md` modified with the iteration-12 `ui/*_12.png`
  captures landing. Per the PROCESS ITEMS rule none of this is blocker/major.
* **One important warning about that in-flight work, not a finding against the
  diff.** The uncommitted `k03_bugs_test.dart` adds
  `testWidgets('K03-BUG-16: the pet hero art sits on the design rows', …)`
  with `}, skip: true);`. `HEAD` has no skip, so this is not in the reviewed
  diff — but if it is committed it breaks two rules: the brief's "NEVER … skip
  tests", and that file's own header ("The suite has NO skipped tests: every
  proof below runs in the plain suite. (If you add one, do not park it to get
  green — see RULES.)"). It will also **still fail after `main` merges**:
  `pet_bubble_gap` alone moves the rim to ≈274, and the design's 278 needs
  #18 option (b) / #16(a) (`_explicitBleed` 27.4), which is not merged. So the
  skip buys nothing and hides a 4 px residual. Preferred handling: apply
  finding 1's two halves after the merge, then set the pin to whatever the
  shared component paints, with the design's number in the `reason` and
  `SHARED_REQUEST` #16(a) named — do not park it.
* The branch is 20 commits behind `main`; the loop owns the commit/merge order.

## Verdict

No blocker or major finding in K03-owned code in `main...HEAD`. The diff is one
documented compensation constant plus test work that tightens the geometry,
pixel and colour proofs; the shipped screen meets `ARCHITECTURE.md`, RULES
§1/§6/§7/§8, `DESIGN_SPEC.md` §5 K03 character-for-character, the design
system's tokens-only rule and the Children's Code bar, and format, analyze and
both test runs are green. Findings 1–8 are small and local (or, for 1, a
merge-gated revert the constant's own comment already prescribes); 9 and 10 are
docs/shared work.

The one open UI-rule deviation — the hero block 9 px above the design — is
rooted in `core/`, was already fixed on `main`, and is reproduced and escalated
above with the exact follow-up so the next stage can close it on merge rather
than re-derive it.

VERDICT: PASS
