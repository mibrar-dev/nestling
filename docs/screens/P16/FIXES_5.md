# Fix list after iteration 5

## From 3_test.md
# P16 Settings — Stage 3 TEST (iteration 5)

Job: re-prove the screen after the iteration-5 un-fork, and serve the two new
mandatory rules in this brief (AVATAR INITIALS, TEST TIMEOUTS).

**Outcome: FAIL — every gate is green, the screen now has **zero** skip-marked
tests in its own file except the one I added this stage, and iteration 5's
un-fork is verified metric-preserving by my existing tests. One minor defect
remains open (P16-T04: the two hand-rolled avatar initials), and it is a
**mandatory rule the tree cannot apply yet** — not a choice.**

Numbers: **+2 tests** (141 in `test/features/settings`, 1 of them a skip-marked
proof), **0 new failures**, **1 new minor bug**, **the iteration-4 finding and
mandate items 1–3 all closed by the build**.

---

## 1. What iteration 5 changed (the shared-request arc closed)

Shared batch 6 landed on this branch and made every previously-blocked item
buildable, so this build is mostly consumption:

| shared batch 6 item | what it unblocked |
|---|---|
| `NestListRow._TrailingSlop` + `_RowSlopForwarder` | T02 / T03 **without** local wrappers |
| section label line box 13/16 | `_P16Sect` revert |
| `members.email` (schema v7, nullable) + seeded | DATA OVER MOCKS owner row |
| `NestCard(radius:)` parameter | subcard revert |
| IANA backward links resolved | P16-B09 |

1. **All three forks are gone** — `NestSectionLabel` ×7, `NestCard` ×2, plain
   `NestListRow` for the switch and picker rows, every `SizedBox` wrapper
   deleted. `SettingsRow` survives narrowed to the five rows the shared row
   still cannot express (owner, co-parent, two children, the danger row).
2. **DATA OVER MOCKS is real** — the owner subtitle reads
   `SettingsMemberEntry.email` ← `members.email`; `sarah@example.co.uk` is gone
   from the view; a NULL e-mail falls back to the role-derived `Owner`.
3. **T03 and B09 un-skipped and green** — so, with my T02 proof from iteration 3
   and the B11 proof from iteration 3, **every tap-target and zone finding of
   the last three iterations is closed with a live guard**.
4. Token literals replaced (`gap2`, `gap14`, `NestType.chipLabel`).
5. The build corrected its own iteration-4 finding: "the seed holds that parent
   email" is true *now* — the ruling described the destination and the integrator
   measured the tree it was written against.

## 2. What I verified this iteration (no new test needed — the old ones did it)

The build claims the reverts are "metric-preserving". My geometry and design
tests, written against the forks in iterations 2–4, now pass against the shared
components — which is the verification:

| contract | assertion (which file) | measured now |
|---|---|---|
| section label line box | typography + scaling, both themes/scales (`settings_responsive_test.dart`) | **16 px** at scale 1.0, 21 px at 1.3 — identical to the fork |
| subcard radius / padding | `subscriptionCard()` decoration (`settings_responsive_test.dart`) | **16 px** radius, **16 × 14** padding, `surface` + `sh-1` |
| switch track flush right | B11 proof, 320/390/430 × light/dark | track **303–354** at 390 (= 370 − 16) |
| 44 px target | T02 proof: content box ≥ 44 + taps ±5 px flip the DB | content box **44** (row padding box 56 − 12) |
| 4 px horizontal slop | T03 proof: taps 4 px left AND right of the track | both flip |
| gutter / ALIGNMENT | full sweep at three widths × two scales × two themes | one 20 px gutter everywhere |

**One number I re-pinned because it was only ever a prediction:** iteration 4
measured that un-forking `SettingsRow` → `NestListRow` *without* batch 6 would
grow the switch rows 56 → **64 px** (+8 × 3 rows). Batch 6's `_TrailingSlop` is
what prevents it, so "the reverts are metric-preserving" was a claim until now.
The T02 proof now asserts the row is **56 px** — like every other row on the
page — so the claim is testable rather than trusted.

## 3. Tests added (2) — the new AVATAR INITIALS rule

`nestAvatarInitial(name)` lives on `main` but is **absent from this worktree**
(the branch is 25 commits behind `main`), so importing it here would break
`flutter analyze`. Both P16 call sites
(`settings_view.dart`, member row and child row) still hand-roll
`characters.first` — which is grapheme-safe and so does **not** violate the
rule's actual prohibition (`name[0]`), but also does not do two of the things
the shared helper does.

- **Live: an emoji nickname yields ONE grapheme.** `'🌟Zoe'` renders initial
  `'🌟'`, whole, with no exception — the guard against anyone "simplifying" the
  call site back to `name[0]`, which would throw on an unpaired surrogate and
  take the frame with it. Addressed through *the row's own* avatar: my first
  draft asserted "some avatar contains '🌟'", which a different child could
  satisfy — the same false-pass shape the loop's rules warn about, caught by
  tightening it.
- **Skip-marked `[P16-T04]`: the initial trims and falls back.** The helper
  trims first and returns its `fallback` (`'?'`) for empty or whitespace-only
  names; the hand-rolled version does neither. Measured: a nickname of
  `' Maya'` renders a **space** as its avatar initial, and `'   '` also renders
  a space instead of `'?'` — a blank avatar where a parent expects a letter.
  Unfixable in this tree (the helper does not exist here); the fix is the two
  one-line swaps the integrator already identified.

Also satisfied this stage: **TEST TIMEOUTS** — every run above used
`--timeout 120s`, foreground, none over 10 minutes. **IDS** — the screen mints
no ids, nothing to check.

## 4. Results

```
$ dart format .
Formatted 553 files (0 changed) in 3.21 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 14.2s)

$ flutter test test/features/settings --timeout 120s
00:31 +141 ~1: All tests passed!

$ flutter test --timeout 120s
02:29 +3278 ~3: All tests passed!
```

Zero failures. The full suite's `~3` is **one** P16 skip (my T04), K01's
`k01_bugs_test.dart` skip (from `Merge screen/K09`/main) and P12's pre-existing
one. P16's own skip count went 2 (iteration 4) → 1 (this stage).

**Skip honesty.** `flutter test test/features/settings --run-skipped --timeout
120s` fails on exactly the one open proof:

```
settings_a11y_test.dart  [P16-T04] the initial trims a leading space and falls
                                   back to "?" for a whitespace-only name
        Expected: 'M'   Actual: ' '     (nickname <space>Maya)
```

## 5. Bugs

### Closed this iteration (build, verified by my tests)
P16-T03 (4 px horizontal slop), P16-B09 (linked IANA ids), P16-B11 (switch
alignment), P16-B10 (guard coverage), and — via the un-fork and batch 6 — the
three mandatory `ORCHESTRATOR_NOTES` items 1 and 3, plus item 2 (DATA OVER
MOCKS). Nothing regressed: T02 and B11 still pass on the new layout.

### Open — P16-T04 (minor) — mine

`app/lib/features/settings/presentation/views/settings_view.dart` — the member
row and the child row build their `NestAvatar` initial from
`name.characters.first.toUpperCase()` (with an `isEmpty ? '?'` guard) instead of
`nestAvatarInitial(name)`. Effect: a leading space or a whitespace-only
nickname renders a space (or nothing) in the avatar; the shared helper would
render `M` and `?`.

**Repro:** real app at `/settings`, rename a child to `' Maya'` → the Children
row's avatar shows a blank where `M` belongs. Proof:
`flutter test test/features/settings --run-skipped --timeout 120s`.

**Blocked here:** the helper is on `main`, absent from this branch (25 commits
behind); importing it fails `flutter analyze`. Fix after the merge: two
one-line swaps. `SHARED_REQUEST.md` already carries the rest of the arc; this
one needs no schema or shared work, only the merge.

## 6. Observations (not bugs)

1. **The email tripwire did its job and was correctly flipped.** My iteration-4
   tripwire asserted "no `email` column exists"; when batch 6 landed it failed,
   which is exactly what it was for. The builders replaced it with the positive
   form (column present, row reads it) plus a NULL-fallback case — the right
   resolution, and a good demonstration of why a tripwire is worth writing when
   a ruling cannot yet be honoured.
2. **The Family list still announces as one node.** Its two static rows (Sarah,
   James) have no semantics node of their own, so a screen reader announces
   `"Sarah — you / … / James — co-parent / … / Invite co-parent"` as a single
   button. Unchanged across five iterations; the shared `NestListRow`'s
   no-`onTap` branch is where it lives, and the integrator records that a local
   label broke the tappable-node contract for the whole section.
3. **The shared `Semantics(label:) > InkWheel` wart** — blast radius still
   pinned by `settings_a11y_test.dart`: the only unlabelled tappable nodes are
   the three switch tracks.
4. `.ptitle` declares no `text-wrap: balance`, so the plain `Text` with
   `NestType.h1` is correct by the CSS as written.
5. **A fenced tap ripples but does nothing** (the 300 ms guard) — defensible,
   but a silent dead tap if the window is ever widened.
6. The dialog Cancel still wraps at 320 × 1.3 (shared `NestButton` padding).

## 7. Harness notes

- **A row's type is not stable across a fork/revert.** `NestAvatar` lives under
  `NestListRow` for some rows and under P16's `SettingsRow` for the member and
  child rows; after the un-fork the child rows are `SettingsRow`. Address rows
  with `find.byWidgetPredicate((w) => w is SettingsRow || w is NestListRow)` so
  a proof survives either shape — the same reasoning that made the T02 proof
  shell-agnostic.
- **"Some element contains X" is a weak assertion** when the tree holds several
  similar nodes: my first avatar draft passed for the wrong reason (another
  child's `M`). Address the node's own row and read that row's value.
- Unchanged from iterations 1–4: Drift streams need `settleSettings`
  (`runAsync`); `bloc.close()` must be `unawaited` in a widget test;
  `scrollUntilVisible` walks down only (`scrollSettingsUpTo` walks up); a
  semantics-tree walk misses un-passed nodes (`getSemantics` does not);
  `testWidgets(skip: …)` takes a bool; never settle before asserting a
  time-windowed guard; `PRAGMA table_info(t)` reads the live schema.

---


## From 4_review.md
# P16 Settings — QA code review (iteration 5)

Reviewed `git diff main...HEAD` (plus the iteration-4→5 delta `bf1772a...d5a05fa`)
against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, the design system in
`app/lib/core/design_system/`, `docs/DESIGN_SPEC.md` §5 P16,
`docs/design/SPACING_SPEC.md`, `design/html-source/screens/P16-settings.html`,
`docs/screens/P16/ORCHESTRATOR_NOTES.md` (09:22 update) and
`docs/screens/_shared/shared_batch6_REPORT.md` "Follow-ups for screens".

No code was edited. No simulator was booted, installed on, screenshotted or
driven. Gates re-run by this stage:

```
$ flutter analyze lib + all 9 committed app/test/features/settings files
  No issues found! (ran in 14.2s)
$ flutter test --timeout 120s test/features/settings/settings_view_test.dart \
    settings_a11y_test.dart p16_bugs_test.dart settings_states_test.dart \
    settings_responsive_test.dart p16_transient_guard_test.dart
  00:17 +82: All tests passed!
$ flutter test --timeout 120s test/features/settings/settings_bloc_test.dart \
    settings_navigation_test.dart settings_repository_test.dart
  00:11 +58: All tests passed!
```

140 settings tests green, **0 skipped** (B09 and T03 both run). Whole-tree
`flutter analyze` also reports 9 issues, but **all 9 are in the untracked,
self-declared temporary `app/test/features/settings/probe_u_test.dart`** that
the 5_ui stage is writing concurrently right now (see observation 1) — not in
committed code.

## Iteration-4 findings — disposition

| # | finding | status |
|---|---|---|
| 1 | major — forks `_P16Sect`, subcard, `SettingsRow`/toggle rows | **CLOSED for the three the batch-6 report names.** `_P16Sect` deleted (shared `NestSectionLabel`), subcard is `NestCard(radius: NestRadii.m, padding: 14/16)`, the three toggle rows are shared `NestListRow` with no `SizedBox(width:51,height:44)` wrapper, and the zone-picker rows moved to `NestListRow` too. `SettingsRow` survives only for the 4 avatar rows + the danger row, which is exactly what `SHARED_REQUEST.md` §6 filed and what the batch-6 report left open. |
| 2 | minor — B11 comments stale | CLOSED |
| 3 | minor — B10 comment stale | CLOSED |
| 4 | minor — B09 still skipped | **CLOSED** — un-skipped, green (shared batch 6 §5 landed the IANA alias resolution) |
| 5 | minor — hard-coded `sarah@example.co.uk` | **CLOSED** — read from `members.email` (`settings_repository_impl.dart:146-152`, `settings_view.dart:407-417`) with the role/invite fallback |
| 6 | minor — `P16TransientGuard` process-wide static | **STILL OPEN, and it now causes a user-visible defect → major (finding 2)** |
| new | — | The iteration-4 "literal sizes" minor is resolved: `SizedBox(2)`→`NestSpacing.gap2`, `fromLTRB(14,12,…)`→`NestSpacing.gap14`/`s3`, `fontSize: 14` override gone (see finding 4 for the replacement nit) |

## Findings

### 1. major — avatar initials re-implemented instead of the shared `nestAvatarInitial`

`app/lib/features/settings/presentation/views/settings_view.dart:418-420`
(`_MemberRow`) and `:440-442` (`_ChildRow`):

```dart
final initial = member.name.isEmpty
    ? '?'
    : member.name.characters.first.toUpperCase();
```

The owner rule in force for this loop is *"AVATAR INITIALS: use
`nestAvatarInitial(name)` (grapheme-safe). Never `name[0]`"*, and the shared
helper is on `main` (`79b0160`, `core/design_system/components/nest_avatar_initial.dart`,
exported from `design_system.dart`). P16 re-implements it twice inline instead
of calling it, which is also a RULES/design-system violation ("never
re-implement components"). It is not merely a duplicate — it has already
diverged from the shared contract:

* the helper `trim()`s first, so a whitespace-only nickname renders `?`; the
  inline version checks `isEmpty` only, so a nickname that trims to empty
  paints a blank avatar;
* `package:characters/characters.dart` is imported without being declared in
  `app/pubspec.yaml` (it resolves only as a transitive Flutter dependency).
  main's commit adds it explicitly; this branch does not have it yet.

Fix: after main merges, delete both expressions and pass
`nestAvatarInitial(member.name)` / `nestAvatarInitial(child.nickname)` straight
into `NestAvatar(initial: …)` (that is the whole change — both call sites
already have an `isEmpty` guard only for the `'?'` fallback the helper provides).

### 2. major — the modal-close tap guard silently swallows taps on the three notification switches

`app/lib/features/settings/presentation/widgets/p16_transient_guard.dart:11-41`
(w300 ms window, `:17`) fences **every** handler on the screen, including the
three switches at `settings_view.dart:260`, `:273`, `:285`:

```dart
onChanged: (v) => P16TransientGuard.run(
  () => context.read<SettingsBloc>().add(SettingsNotificationsChanged(approvals: v)),
),
```

The window is armed by any modal or sheet close — `zone_picker_sheet.dart:35`
(`.whenComplete`) and `:99` (synchronously in the row's `onTap`), and
`settings_view.dart:387` for the delete modal. Reachable, and easy to hit:

1. tap **Time zone** → picker sheet opens over the Notifications section;
2. tap a zone row → the sheet pops and arms the guard;
3. the Notifications section is immediately below where the sheet was — the
   user's very next tap on **Approvals waiting** (or either other switch)
   lands inside the 300 ms window: the switch does not move and gives no
   feedback of any kind.

The file's own reasoning ("fencing them would strand the prompt", see
`p16_transient_guard_test.dart:178-183`) was applied to the move-banner buttons
— which correctly bypass the guard — but never to the toggles, which are the
nearest neighbour of the dismissed sheet. No test covers the toggle case, which
is why 140 green tests do not see it. The double-tap fall-through the guard
exists for (P16-B08/B10) can only ever re-fire a control that *opens* a modal
or route; a switch flip cannot re-trigger itself, so the switch needs no fence
at all.

Second half of the finding: this is a **screen-local workaround for a shared
component behaviour** (the shared modal/sheet helpers stop absorbing taps
before their exit animation ends). RULES §2 requires such fixes to go to
`SHARED_REQUEST.md`, and §1–7 do not cover it — the guard has been carried as
"review finding 6" for three iterations instead.

Fix:
* remove `P16TransientGuard.run` from the three `NestToggle.onChanged`
  callbacks (3 deletions, restores the toggles; the banner precedent at
  `settings_view.dart:502,514` is the model);
* add **SHARED_REQUEST §8**: `showNestModal` / `showNestBottomSheet` should
  keep their barrier hit-testable for the reverse animation (or ship a shared
  `NestModalCloseFence`), after which `P16TransientGuard` and its static
  delete. Until that lands the row-level fence is defensible; the switches
  never were.

### 3. minor — "Manage subscription" paints no ripple (and §3 of the shared request claims otherwise)

`settings_view.dart:183` renders the subcard as `NestCard(radius: NestRadii.m,
padding: …)` **without** `onTap`, so `NestCard` takes its non-tap branch —
`nest_card.dart:98` — which is a plain `Container` with no `Material`. The
nested `InkWell` at `settings_view.dart:204` therefore resolves its ink to the
Scaffold's `Material`, i.e. *behind* the card's opaque `surface` background:
tapping "Manage subscription" gives zero press feedback.

`SHARED_REQUEST.md` §3 asserts the opposite ("`NestCard` wraps its child in
`Material(borderRadius: …)` … A `radius` parameter removes the fork *and* that
defect together") and `2b_build_ui.md` repeats it. Both are wrong: the `Material`
only exists on the `onTap != null` path, and this card is not tappable as a card.

Fix: give the link row its own ink surface —
`Material(color: Colors.transparent, child: InkWell(…))` — and correct §3's
status line so the next screen does not rely on it.

### 4. minor — the `.chip` label type is reused as body copy for the hint row and the move banner

`settings_view.dart:491-492` (`_MoveBanner`) and `:555-556` (`_LockHint`) both
render `.lockhint` copy as
`NestType.chipLabel(color: …).copyWith(fontWeight: FontWeight.w400)`.
`NestType.chipLabel` is Inter 14/20 **w600** — the `.chip` label — and both
sites undo the weight to get the design's `font-size:14px; line-height:20px`
regular text. The metrics are correct today, but a chip-label change (weight,
letter spacing) silently moves hint text, which is precisely the drift the
design-system rule exists to prevent. There is no shared token for Inter 14/20
w400.

Fix: add **SHARED_REQUEST §9** for a shared `hint` (14/20 w400) in
`typography.dart` and use it in both places. Interim, the documented call-site
override (`NestType.body(…).copyWith(fontSize: 14, height: 20 / 14)`) is
acceptable but reintroduces a literal — do not re-land it silently.

### 5. minor — `watchMembers` duplicates the shared query

`settings_repository_impl.dart:61-70` re-implements
`AppDatabase.watchMembers([familyId])` (`app/lib/core/data/app_database.dart:650-658`,
added by shared batch 6) with the identical
`OrderingTerm(expression: CustomExpression<int>('rowid'))` ordering — including
raw SQL inside a feature that has no need for it. Fix:
`_db.watchMembers(Seed.familyId).map((rows) => rows.map(_toMemberEntry).toList())`.

### 6. minor — the repository builds its own `FamilyZoneService`

`settings_repository_impl.dart:107` — `FamilyZoneService(_db).setFamilyTimeZone(zoneId)`
constructs a second instance instead of using the DI singleton, so the
registered service's configuration (the injectable `deviceZoneReader`, and
anything added later) is bypassed on this path. Fix: take `FamilyZoneService` as
a constructor argument and wire it in `settings_di.dart` (both files are
feature-owned, §1).

### 7. minor (carried, 3rd iteration) — legacy `SettingsItem` / `watchItems()` / `getItems()` are dead

`settings_repository.dart:9-10`, `settings_repository_impl.dart:21-26` and the
70-line `domain/entities/settings_item.dart` have **no consumer**: nothing in
`lib/` or `test/` reads `watchItems()` for settings (quests keeps the same
shape but with a live consumer in its bloc). Dead code that the abstract repo —
which the bloc holds — is forced to carry. Fix: delete all three, or drop the
two repo methods and keep the entity file annotated as foundation reference.

### 8. minor (tracked, no action) — screen-local values already filed

`settings_view.dart:23` (`_linkRowMinHeight = 52`) and
`presentation/widgets/settings_rows.dart` (the `NestListRow` mirror with its own
`EdgeInsets.fromLTRB(12, 10, 16, 10)`) are the only remaining local values.
Both are documented and filed as `SHARED_REQUEST.md` §7 and §6, which is what
RULES §2 asks for; they stay open until the orchestrator batches them. Flagged
only so the next iteration does not re-report them as new.

## Verified clean this iteration

* **Orchestrator 09:22 / batch-6 follow-ups: all four done.** `_P16Sect`
  deleted → shared `NestSectionLabel` (`settings_view.dart:142,161,178,237,251,295,325`);
  subcard → `NestCard(radius: NestRadii.m, padding: 14/16)` (`:183-188`);
  switch rows → shared `NestListRow` with the bare `NestToggle` trailing and the
  `width: 51 / height: 44` wrappers deleted; `members.email` read from the DB
  with the role/invite fallback; B09 un-skipped and green. The mandatory
  geometry still holds — the T02/T03 proofs (44 px slop, 56 px rows) pass.
* **Copy is character-exact** against the HTML: `Family & settings` (&, not
  "and"), `Sarah — you`, `James — co-parent` (em dash), `Invited · awaiting
  reply`, `Maya · 7–9` / `Leo · 4–6` (en dash via `ageBand.replaceAll('-', '–')`),
  `Pip: Fledgling · 120 coins` (middle dot), `Nestling Annual · £29.99/year`,
  `Renews 18 Oct 2027 · Covers the whole family`, `Nickname + age band only`,
  `Share the load`, `Made in the UK · No ads, ever`, `Kid mode needs parent
  gate — On`, chevron `›`; curly `’` in `Looks like you’re in …` and in the
  delete modal. DESIGN_SPEC §5 P16 elements all present.
* **Architecture** (`docs/ARCHITECTURE.md`): feature-first layout, `domain/` is
  entities + abstract repository only, one bloc per screen (`SettingsBloc`,
  `registerFactory` in `settings_di.dart`), routes and DI inside the feature.
  `git diff main...HEAD` touches only `app/lib/features/settings/**`,
  `app/test/features/settings/**`, one 2-line carry in
  `app/test/features/today/today_view_test.dart` (declared in
  SHARED_REQUEST, pre-verified as a clean 3-way merge) and `docs/screens/P16/**`.
  No `app/lib/core/**` or `app/lib/app/**` edits.
* **Design-system usage**: no hard-coded colours (every colour is a token),
  no raw geometry left un-tokenised except the two filed in §8 above,
  `SettingsRow`/`zone_picker_sheet` reference `NestListRow.trailMaxWidth`
  instead of a private 120, `NestAvatar`/`NestToggle`/`NestCard`/`NestList`/
  `NestButton`/`NestModal`/`NestToast`/`NestBottomSheet`/`NestSectionLabel` all
  used as shipped. No `google_fonts`, no `GoogleFonts.*` anywhere.
* **Accessibility**: every control exposes `SemanticsAction.tap`
  (`settings_a11y_test.dart:74`), the `Semantics(excludeSemantics: true)`
  wrapper at `settings_view.dart:208-214` passes `onTap`, switches carry
  `semanticLabel` + toggled state and `performAction` writes the real row,
  child-row navigation activates through semantics, section labels announce as
  headings, 44 px parent tap minimum including the ±5 px toggle slop, the
  delete confirm exposes both buttons before acting.
* **Performance**: one `BlocBuilder` + a single `emit.forEach` over a combined
  4-stream (`settings_bloc.dart:66-118`); write handlers never emit (the watched
  streams drive refresh — no load-event ping-pong); terminal errors close the
  subscription (`_closeOnError`, no leaked watchers per retry); every static
  child is `const`; no `setState`, `Timer` or animation controller in the
  feature; no rebuild storm on toggle writes (one emission per write).
* **Error handling**: `_SettingsFailure` renders a message plus a Retry button
  that re-dispatches the single load event; `NestModal` confirm for the
  destructive row; toasts for the two placeholders; nothing wipes the DB
  (`TODO(P16)` at `settings_view.dart:389`).
* **Rules**: CLOCK — no `DateTime.now()` in the feature, the guard reads
  `clock.now()`; TRIAL — `subscription_status` is only read
  (`settings_repository_impl.dart:44-45`), never written; CHILD ORDER —
  `watchRoster` uses the shared `_db.watchChildren` (createdAt, rowid) so Maya
  precedes Leo, members by rowid so Sarah precedes James; IDS — no new rows are
  created on this screen; BOTTOM EDGE / KID BACKGROUND — not this screen's
  surface (tab bar and home edge belong to `ParentShell`); PIP — no Pip slot on
  this screen, so the `PipAvatar` rule is N/A.
* **Children's Code**: `/settings` is in the router's `parentOnly` list, so kid
  mode lands on the parental gate; no analytics, ads, network calls or logging
  anywhere in the feature (no `print`/`debugPrint`), and no child data leaves
  the device.

## Observations (not findings)

1. **Concurrent stage in this worktree.** `app/test/features/settings/probe_u_test.dart`
   is untracked, was created at 12:30 by the 5_ui stage that is running right
   now, and declares itself *"TEMPORARY probe U (iteration 5) — deleted before
   the stage ends"*. It currently holds one compile error
   (`probe_u_test.dart:94 undefined_named_parameter: dark`) plus 8 lints, which
   is what a whole-tree `flutter analyze` reports. It is in-flight, untracked and
   outside the committed diff, so it is not a P16 finding — flagged only so the
   loop's final gate is run after that stage deletes it. Analysis of the
   committed tree (all of `lib/` + all nine settings test files) is clean.
2. Process items (uncommitted `.brief_*.md`, branch behind `main`) are excluded
   per the orchestrator rules.
3. The concurrent 5_ui stage is also writing `ui/app_light_5.png` /
   `ui/app_dark_5.png`; the iteration-5 UI verdict belongs to stage 5 and was
   not pre-empted here.

## Verdict

Two major findings (1: shared `nestAvatarInitial` not used; 2: the tap guard
silently kills switch flips after any sheet/modal close, with no SHARED_REQUEST
behind it). Everything else is closed, filed or cosmetic.

