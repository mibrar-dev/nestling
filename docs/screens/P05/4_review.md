# P05 · Add children — QA code review (STAGE 4, iteration 4)

Scope reviewed: `git diff main...HEAD` + the working tree for `screen/P05`
(RULES §1 paths only). No product code was edited in this stage.

Reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P05, `docs/design/SPACING_SPEC.md`, the design system
(including the `NestChip` shrink-wrap fix that landed from main in `7eaa1f7`),
both design PNGs, the HTML source, and
`docs/screens/P05/ORCHESTRATOR_NOTES.md` (all items checked below).

Gates re-run independently in this stage:

```
dart format --set-exit-if-changed .   → 362 files, 0 changed
flutter analyze                        → No issues found!   (full app)
flutter test test/features/family     → 00:05 +116: All tests passed!
flutter test (full suite)              → 00:12 +642 -1: the one failure is the
                                         shared app/test/app/router_push_test.dart
                                         (see "Shared gate status" — outside RULES §1)
grep -c "skip:" test/features/family/*.dart → 0 / 0
git status → features/family/{presentation,data}, test/features/family,
             docs/screens/P05   (all RULES §1; nothing in core, app/ or app/test/app)
```

**Result: 0 blocker, 0 major, 3 minor against the P05 diff. Every iteration-3
finding is closed and proved, and the mandatory CHILD ORDER item is satisfied
inside RULES §1. VERDICT: PASS.**

The one red test in the full run is in a shared file this worktree may not
edit, arrived from main, and predates every P05 iteration — it is reported
below for the orchestrator but is not counted against this diff (the loop and
the orchestrator own shared batching and merge order).

---

## Findings

### 1. MINOR — the rowid interim carries a `VACUUM` caveat worth one line of documentation

`app/lib/features/family/data/family_repository_impl.dart:50-62`
(`_watchChildrenInAddedOrder`).

The interim is correct for every path the app exercises: `Seed.demo()` /
`Seed.onboardingKids()` insert Maya then Leo (rowid order → `[Maya, Leo]`), a
child added at runtime takes `max(rowid)+1` and therefore sorts last, and a
deleted child does not disturb the survivors' relative order. The one caveat is
SQLite's documented behaviour for tables without an `INTEGER PRIMARY KEY`:
`VACUUM` **may** renumber rowids. Drift does not run `VACUUM`, so this is
theoretical today — and the filed durable fix (`createdAt`) removes it
entirely.

Fix: one clause in the doc comment, e.g. *"rowid is the insertion proxy; the
durable fix is the shared `createdAt` column — see SHARED_REQUEST.md, which
also retires the VACUUM-renumbering caveat"*. Then delete this helper in the
same commit that lands the durable fix.

### 2. MINOR — the chip row now depends entirely on the shared component, and the design's single row is still only provable on-device

`app/lib/features/family/presentation/widgets/add_child_form_card.dart:75-86`.

Removing the four `IntrinsicWidth` wrappers was right (the shared `NestChip`
shrink-wraps by construction since `7eaa1f7`, and the wrapper's "until the
shared fix lands" comment had become false). The consequence is that P05's
chip geometry is now whatever the design system produces: the BUG-1 proofs
assert the *mechanism* — no box claims the `Wrap` run, at most two rows, the
block stays ≤100 px — which is font-robust but stops short of the design's
single row, because the test fallback font is ~30 % wider than Nunito.

What is still owed, and by whom: the shared chip's tap box is 44 tall against
the design's 32 visual pill (`nest_chip.dart` — `Padding(vertical: 4.5)` around
a 35 px pill), which the iteration-2 UI check measured as a +12 px row drift.
That is core, it is already in `SHARED_REQUEST.md` #3, and P05 must not patch
it. The width half of that request is marked LANDED ✓.

Fix: none in P05. The iteration-4 UI check re-asserts the single row on the
simulator, which is the only place it can be asserted.

### 3. MINOR — stage-note counts have drifted between stages (documentation only)

`docs/screens/P05/2_build.md:79` says "110/110 in `test/features/family/`";
the test stage's later run and mine both report **116** (the build stage wrote
its number before the test stage added its own proofs). `3_test.md:56` is
correct.

Fix: one number in the build notes; nothing else.

### Carried, accepted with stated reasons (unchanged this iteration — listed so the delta stays explicit)

* **Dropped "Continue" in the save frame** — intended: the buttons disable for
  the whole save, the window is one frame, and the design has no "still
  saving" state.
* **`FamilyAddChildRequested.onSaved`** still carries navigation into the bloc —
  deferred until P15 lands (changing the signature would touch a member two
  features share). The double-fire path stays closed by the
  `saveInProgress` guard.
* **`presentation/widgets/child_display.dart` holds no widgets** — accepted: a
  feature-private mapper; ARCHITECTURE forbids extra *folders*, not files.
* **Failure panel shows `error.toString()`** — app-wide pattern (P08
  identical); an orchestrator decision if it should change.
* **`Positioned(top: 1, right: 1)`** — signed off as a faithful mirror of
  `.edit { top: 1px }`; no 1 px step exists in `NestSpacing`.

---

## Iteration-3 findings — all closed

| # | Finding | State |
|---|---|---|
| 2 | MAJOR · CHILD ORDER ruling unsatisfied; interim feasible in `data/**` | **fixed** — `FamilyRepositoryImpl.watchChildren` now runs its own rowid-ordered query (`family_repository_impl.dart:38-41, 50-62`), exactly the shape I verified, keeping the repository interface untouched. Proved by two decisive tests: `the seeded roster reads Maya, then Leo` (via the `onboarding_kids` seed the UI check uses, with the note that alphabetical would put Leo first) and `a child added in this session appends to the end` — `'Ollie'` sorts *between* Leo and Maya alphabetically, so that test can only pass on insertion order. The `TODO(P05)` deferral in the grid is replaced by a comment stating the ruling is satisfied. The shared `createdAt` request stays open as the durable fix. |
| 3 | MINOR · dead `IntrinsicWidth` wrappers + stale comment | **fixed** — all four removed, comment replaced; the BUG-1 geometry proofs still pass against the fixed component. |
| 4 | MINOR · a test pinned the alphabetical order | **fixed** — flipped to the ruling (`maya.left < leo.left`), so it now proves the fix; a rename test ("rowid order survives a rename; nickname order would flip") guards it. |
| 5 | MINOR · `cardH` reserved 10 px the design does not have | **fixed** — `cardH = 22 + 44 + 2 + 24 + 6 + 18 = 116` at scale 1.0, matching the design's measured 116 (the trailing `gap10` pencil clearance is gone — the 44 px pencil is absolutely positioned and adds no height) and the name→age gap is now the HTML's `gap: 2 + margin-top: 4 = 6` via the existing `gap6` token. Proved by an un-skipped BUG-10 bound (≤118) and the kept pencil-containment assertion, at 1.0 and 1.3×, 320–430 px. |
| 6 | MINOR · stage notes claimed the interim was impossible | **fixed** — corrected in `2_build.md` and `3_test.md`. |
| 1 | BLOCKER (shared) · `router_push_test` red | unchanged — see below. |

---

## Orchestrator items (`ORCHESTRATOR_NOTES.md` — all mandatory)

1. **Children order — fix in this feature's repository (order by
   creation/rowid) and add a test asserting Maya is first.** Done, inside
   `features/family/data/**` (RULES §1), with two decisive order proofs (see
   the table above). The grid now renders `Maya | Leo`, matching both the
   ruling and the design PNG.
2. **"Add a child" card top ≈ y 399 (app was ≈ 407); the gap between the
   kid-card row and the card must be 12 px.** Satisfied by construction: the
   116 px card (`kid_card_grid.dart:26-35`) is exactly 8 px shorter than the
   previous 124, and the gap stays the HTML's `margin-top: 12`
   (`NestSpacing.s3`, `add_children_view.dart:214`). No new magic value was
   introduced to hit the number.
3. **Inside-card cumulative drift (+4 Nickname, +8 field, +13 chips, +20
   Avatar colour).** Diagnosed correctly and escalated as shared, and it is not
   P05-fixable: every P05 gap and row height is a literal `SizedBox` or a DS
   token measured exactly at the HTML value, so none of them can grow on
   device. The residual is Flutter applying `TextStyle.height` to the *font's*
   natural line height (Inter ≈ 1.21 em, Nunito ≈ 1.3 em) rather than to a fixed
   CSS box — which is why the test fallback font (1.0 em) measures exact while
   the runtime-fetched families are ~+4–5 px per row and the ladder compounds
   down the card. Filed in `SHARED_REQUEST.md` ("residual band drift … shared
   typography, app-wide", blocks: no for P05) with the three real options
   (`TextHeightBehavior`/strut, bundled families with matching metrics, or
   accept the delta). I re-derived the arithmetic and agree with it.
4. **Earlier mandatory items still hold**: chips in one left-aligned row with
   8 px gaps; header not patched locally (the shared compact nav is consumed);
   bottom panel to the physical edge and 20 px gutters aligned across
   head/grid/form/CTA/caption; curly `’` (U+2019) copy pinned by a code-unit
   guard; focused-ring tokens pinned by test; the field still launches
   unfocused (no autofocus invented).

---

## Confirmed clean (no action)

* **RULES §1 scope.** Only `features/family/presentation/**`,
  `features/family/data/**` (the rowid query — allowed, and the data layer is
  the right owner for ordering), `test/features/family/**` and
  `docs/screens/P05/**`. Nothing in `app/lib/core/**`, `app/lib/app/**`,
  `app/test/app/**`, another feature, or `tools/screens/**`;
  `analysis_options.yaml` untouched; no test skipped, ignored or weakened.
* **ARCHITECTURE.md.** Feature-first layout intact; one bloc per feature; one
  view per route; feature-private widgets; no use-case classes and no new
  folders. The repository interface is untouched (ordering is an
  implementation detail, exactly where `ARCHITECTURE.md` puts it), DI is
  unchanged (`family_di.dart:13` still passes the same database), and the
  shared bloc surface stays additive (`lastSavedNickname` only) with no
  renames or signature changes — so P15 still merges cleanly.
* **Design-system usage.** The new code *consumes* the fixed shared `NestChip`
  instead of fighting it, and the only raw value in the diff is the accepted
  `rowid` identifier (a SQLite built-in, not a colour or size). Colours from
  `context.nest`, sizes from `NestSpacing` / `NestDevice` /
  `NestAvatarSize`, type from `NestType`; `EdgeInsets.zero` on the grid is the
  documented fix for P05-BUG-8, not a spacing value.
* **Copy / UK spelling / spec §5 P05.** Re-verified character-by-character
  against the HTML entities: h1 with U+2019, subtitle with U+2014, bands and
  card ages with U+2013 (composed from the stored hyphen via
  `displayAgeBand`), "Avatar colour" never "color", no ASCII hyphen or
  apostrophe anywhere on screen. No copy changed this iteration and the guards
  still hold.
* **DATA OVER MOCKS + CHILD ORDER.** Age bands, avatar colours and age text
  come from the seeded rows; the roster order comes from the repository and is
  now creation order. The screen invents nothing.
* **Owner rules.** Bottom edge: `NestBottomCta` last in the column with its own
  `SafeArea(top: false)` and `tokens.surface` over a `tokens.paper` Scaffold —
  no strip under the bar or around the home indicator in light or dark.
  Alignment: one `NestSpacing.padSide` gutter on the `ListView`, so head, cards,
  form card, CTA buttons and caption share the same left/right edges at
  320/390/430; the grid column is computed `(W − 40 − 10)/2`
  (`SPACING_SPEC` §10.2) and the pencil stays inside its own card now that the
  card is 116.
* **Accessibility.** h1 exposed as a header landmark; `Edit <nickname>` per
  pencil; chip and swatch groups are labelled containers with reachable
  children; swatches are `Material` + `InkWell(CircleBorder)` with `selected`
  semantics (no raw `GestureDetector` left in product code); the nickname
  field's focus ring is token-driven and pinned; tap targets 44/44/44/48/52.
* **Error handling.** Spinner for `initial|loading`; failure panel + `Try again`
  that releases the failed load before re-subscribing (`_closeOnError`); empty
  nickname and >24 chars rejected inline with no repository call; repository
  throw → inline message + `debugPrint` with the form preserved; typing during
  a save survives the conditional clear.
* **Resource hygiene / performance.** `TextEditingController` + `FocusNode`
  disposed; the only stream is `emit.forEach` and its error path terminates the
  subscription; no `Timer`, `AnimationController` or manual `Listener`. One
  `BlocBuilder` over a short list per keystroke; all `const`-able widgets are
  `const`; this iteration *removes* an intrinsic-layout pass per chip, and the
  rowid query replaces rather than adds to the core watch it was already
  paying for.
* **Children's Code.** Parent-only screen; no analytics, ads, telemetry or
  network calls; no child data logged (the one `debugPrint` logs an
  unrecognised *colour token*, never a name); nothing crosses into kid mode and
  kid-mode deep links to `/add-children` redirect to the parental gate. Pip is
  correctly N/A — the design shows initial-letter avatars marked `aria-hidden`,
  not Pip.
* **Tests.** 116 in `test/features/family/`, zero skips, no tautological bodies
  (the two order proofs discriminate insertion order from alphabetical on
  purpose), every app-pumping test ends with `disposeApp`. The BUG-9/BUG-10
  proofs this iteration are un-skipped and green, and the pre-existing
  chip/owner-rule/semantics/navigation suites are unaffected.

---

## Shared gate status (not a P05 finding — needs an orchestrator batch)

`app/test/app/router_push_test.dart:104` passes `showsFrom: 'P05 Add children'`,
the title P05's *placeholder* rendered. The real screen shows
`Who’s in your nest?`, so the assertion at `router_push_test.dart:37` fails and
the full run stays red (`00:12 +642 -1`, reproduced here independently).

* `'P05 Add children'` appears nowhere in `app/lib` — only in that test.
* The file arrived from **main** in `7eaa1f7`, written while P05 was still a
  placeholder; it is not a P05 regression.
* `app/test/app/**` is outside RULES §1, so no screen agent can fix it.

Fix is one string: `showsFrom: 'Who’s in your nest?'` (`showsTo: 'P06 Pocket
money setup'` is still correct). Filed as BLOCKING in `SHARED_REQUEST.md`
since iteration 3 and untouched since. It does not count against this diff —
shared batching and merge order are the loop's and the orchestrator's — but
the branch cannot land green until it is applied.

Also still owed by the design system (both filed, neither P05's to patch):
the chip tap box 44 tall against the design's 32 visual pill (~+12 px row
drift), and the app-wide typography line-box delta (~+4–5 px per text row on
device) that bounds every screen's achievable drift percentage.

## For the next stages (not findings)

* **Iteration-4 UI check**: re-shoot with `SEED=onboarding_kids`; expect band
  2–5 drift to drop materially now that the cards are 116 and the form card
  top lands at ≈399. What remains should be the two shared items above.
* **Do not chase the inside-card ladder in P05**: every gap is already a
  literal and spec-exact; further nudging would mean hard-coding pixel offsets
  against a shared type-scale effect.
* **When the shared `createdAt` fix lands**, delete
  `_watchChildrenInAddedOrder` in the same change (finding 1).

VERDICT: PASS