# K09 · My jar — QA code review (stage 4, iteration 2)

Scope: `git diff main...HEAD` (51 files; the code under review is
`app/lib/features/kid_jar/{data,domain,presentation}/**` + the six tracked
`app/test/features/kid_jar/*.dart`) against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K09 (`DESIGN_SPEC.md:206`),
`docs/design/SPACING_SPEC.md`, `1_plan.md`, the orchestrator rules in the stage
brief (incl. `ORCHESTRATOR_NOTES.md` 18:47) and the design sources
(`design/html-source/screens/K09-jar.html`, `components.css`,
`design/screens/{light,dark}/K09-jar.png` and the already-captured stage-5 shots
`ui/app_{light,dark}_2.png`).
**No code was edited in this stage.** **No simulator was booted, installed on,
screenshot or driven** — every measurement below comes from a pixel probe I ran
myself over the design PNGs and the stage-5 shots (÷3 to logical px; no image
attached) and from `flutter test`.

**Result: no blocker, no major — nine minor findings, none of which needs
shared code.**

Iteration 1's six findings: **1 fixed** (the K09-BUG-3 proof's GetIt ordering —
it now pumps first and uses the database that pump returns) and **5 still open**,
re-proven here under new numbers: glyph size → finding 4, subscription guard →
finding 1, formatter layering → finding 5, `NestProgress` gloss hand-off →
finding 6, unbounded row value → finding 2. Two **new** defects are filed as
findings 3 (`moveToSavings` on an unresolvable goal) and 8 (stale weekday
label).

## Gates run in this stage

| gate | command | result |
|---|---|---|
| scope | `git diff main...HEAD --name-only` | only `app/lib/features/kid_jar/**`, `app/test/features/kid_jar/**`, `docs/screens/K09/**` — inside RULES §1 |
| shared code | `git log main..HEAD --name-only -- app/lib/core app/lib/app` | **empty** — no shared file is committed on this branch |
| format | `dart format --output=none --set-exit-if-changed lib/features/kid_jar test/features/kid_jar` | every tracked file clean (only the four untracked `_probe_h*` scratch files would change; they have since been deleted) |
| analyse (lib) | `flutter analyze lib/features/kid_jar` | **No issues found!** |
| analyse (tests) | `flutter analyze test/features/kid_jar` | 74 issues at first reading — 72 in untracked `_probe*` scratch files, **2 in the committed `k09_bugs_test.dart`** → finding 7. Re-run at the end of this stage: **No issues found!** — the concurrent stage had already fixed it (see finding 7) |
| tests | `flutter test --timeout 120s` on the six tracked files | **`00:05 +124 ~2: All tests passed!`** |
| bug proofs | `flutter test --timeout 120s --run-skipped` on the parked proofs | K09-BUG-7 and K09-BUG-8 run **red** → findings 1 and 3 |
| suppressions | `grep -rn "ignore_for_file\|// ignore:" lib/features/kid_jar` | none |
| fonts | `grep -rn "google_fonts\|GoogleFonts" lib/features/kid_jar test/features/kid_jar` | none |
| tracking | `grep -rn "letterSpacing" lib/features/kid_jar` | none — `NestType`'s 0 default untouched |
| clock | `grep -rn "DateTime.now()" lib/features/kid_jar` | none — `appNowUtc()` / `londonWeekStartUtc()` only |
| children's code | `grep -rn "print(\|debugPrint\|analytics\|http\|Socket\|Uri.parse" lib/features/kid_jar` | none — nothing leaves the device |

## Independent measurements (my own pixel probe, design vs stage-5 shot)

| element | design | app | Δ |
|---|---|---|---|
| goal card top border | y 465.0–467.7 | y 465.0–467.7 | 0 |
| progress track borders | 557.0–558.7 / 571.0–572.7 | same | 0 |
| goal card bottom border | 615.0–617.7 | 615.0–617.7 | 0 |
| history card top border | 676.0–678.7 | 676.0–678.7 | 0 |
| “What went in” ink rows | 640.0–652.7 | 641.3–653.7 | 1.3 ✓ |
| “coming on …” ink colour (light) | `#1E1B3A` | `#1E1B3A` | 0 |
| “coming on …” ink colour (dark) | `#28316B` | `#272F69` | ≤1 per channel (antialias) |
| `.kcap` goal captions (light) | `#4A4668` | `#4A4668` | 0 |
| jar lid / glass / coin / outline (light **and** dark designs) | `#7C6CF2` / `#F2FAFF` / `#F4B400` / `#1E1B3A` | identical in both app shots | 0 |

The caption line measuring `#4A4668` (`--ink-2`) while the “coming on” line
measures `#1E1B3A` (`--ink`) is independent confirmation of the cascade ruling
behind K09-BUG-2, and the four identical jar samples in *both* themes confirm
that keeping the transcribed palette fixed (rather than re-theming it) is exactly
what the dark design does. The title band differs only inside the OS status-bar
strip (excluded by the STATUS BAR rule).

## Findings

No blocker. No major. Nine minor.

### 1. minor — K09-BUG-7: a load dispatched in the same tick as `close()` leaks the subscription and then throws inside the stream callback

`app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart:35-47`

```dart
final previous = _jarSub;
_jarSub = null;
await previous?.cancel();                      // ← the handler suspends here
emit(state.copyWith(status: KidJarStatus.loading));
_jarSub = _repository.watchJar().listen(        // ← subscribes, possibly after close()
  (snapshot) => add(KidJarSnapshotReceived(snapshot)), …);
```

The K09-BUG-1 guard (`await` the old subscription *before* subscribing) opened
a suspension point. If `close()` lands inside that `await`, it cancels nothing
(`_jarSub` is already null) and the handler then subscribes to `watchJar()`
**after** the bloc is closed: the four-query Drift fan-out is never released and
its first emission calls `add(…)` on a closed bloc.

**Proof (mine, run red):**
`flutter test --timeout 120s --run-skipped --plain-name "K09-BUG-7: add-then-close releases the subscription" test/features/kid_jar/k09_bugs_test.dart`
→ `Expected: <0> Actual: <1>` (one live subscription left behind), and the
companion proof throws `Bad state: Cannot add new events after calling close`.

**Fix (three lines, keeps the K09-BUG-1 behaviour):**

```dart
await previous?.cancel();
if (isClosed) return;
final sub = _repository.watchJar().listen(…);
if (isClosed) { unawaited(sub.cancel()); return; }
_jarSub = sub;
```

Then drop the two `skip:` markers on `K09-BUG-7` / `K09-BUG-7b`.

### 2. minor — the history row's amount is laid out unbounded, so a large amount overflows the card instead of ellipsising

`app/lib/features/kid_jar/presentation/widgets/jar_history_card.dart:224-230`

`Row(children: [disc, gap, Expanded(Column), gap, Text(value, softWrap: false)])`
— Flutter lays non-flexible `Row` children out with an **unbounded** main-axis
width, so the value never shrinks. The sibling goal card already does this
correctly with `Flexible` + ellipsis (`jar_goal_card.dart:98-118`).

**Proof (mine, reproduced from the stage-6 scratch probe):** one
`gift`/`123456789`p row renders `+£1234567.89`; at 320 px × 1.3 scale the
screen reports `A RenderFlex overflowed by 95 pixels on the right`. (At 390 ×
1.0 it happens to fit, and the goal card with the same magnitude at 320 × 1.3
is clean — so this is the row, not the card.)

**Fix:** wrap it like the goal card —
`Flexible(child: Text(formatJarAmount(entry.amountPence), style: valueStyle(tokens.leafInk), maxLines: 1, overflow: TextOverflow.ellipsis))`,
dropping `softWrap: false`.

### 3. minor — K09-BUG-8: `moveToSavings` writes a `savings_move` row when the goal cannot be resolved, so the pence silently vanish

`app/lib/features/kid_jar/data/kid_jar_repository_impl.dart:142-174`

The K09-BUG-4 cap kept the old `goal == null → remainder = requested` branch:

```dart
final goal = await (…where((g) => g.id.equals(goalId))).getSingleOrNull();  // id only
final remainder = goal == null ? requested : goal.targetPence - goal.savedPence;
if (remainder <= 0) return;
await _db.into(_db.ledgerEntries).insert(… type: 'savings_move', amountPence: move …);
if (goal != null) { …credit the goal… }
```

With an unresolvable `goalId` the insert still runs and nothing is credited: a
`savings_move` is in neither `_moneyInTypes` nor `_summarize`'s totals, so the
money leaves the jar and appears nowhere — no figure moves, no row appears, no
error is raised. The lookup filters on `id` alone, so a goal id belonging to
**another child** credits that child's goal with this child's money.

**Proof (mine, run red):** `moveToSavings(childId: 'maya', goalId:
'goal-does-not-exist', amountPence: 500)` inserts
`LedgerEntry(type: savings_move, amountPence: 500)` and leaves `goal-lego`
untouched at 1550.

**Fix:** one guard before any write —
`if (goal == null || goal.childId != childId) return;` — and then let
`remainder` be `targetPence - savedPence` unconditionally. Latent: the method has
no caller yet (it is the K10 hand-off), which is why this is minor and not
major — but K10 will call it.

### 4. minor — the history disc glyphs render at `NestIcon`'s default 24 px, not the design's 22 px

`app/lib/features/kid_jar/presentation/widgets/jar_history_card.dart:201`
(`NestIcon(_glyph, color: tint.$2)`) and `:102-106` (the empty row). `NestIcon`
defaults to `size = 24`; all three `.k9-ico` glyphs in
`K09-jar.html:85,90,95` are `<svg viewBox="0 0 24 24" width="22" height="22">`
and `1_plan.md` §a says the same (“Size 22 in 40 disc”). Measured on the light
shots: row-1 disc ink 17×17 design vs 18×18 app, row-2 bins ink 13×19 vs 14×21.
Inside the ±2 px UI tolerance (stage 5's PASS stands) but a real deviation from
the design and from the screen's own plan; the app gets it right elsewhere
(`kid_home/…/quest_detail_view.dart:825`, `kid_shop/…/shop_reward_card.dart:201`).

**Fix:** `NestIcon(_glyph, size: _glyphSize, color: tint.$2)` with
`static const double _glyphSize = 22;` beside `_discSize = 40`, documented with
`K09-jar.html:34/85`. Centred in a 40 px disc, so nothing else moves.

### 5. minor — the money formatter is split across two layers, one of them in the wrong folder

- `app/lib/features/kid_jar/domain/entities/jar_snapshot.dart:30-37` —
  `formatJarAmount` is presentation formatting (`+£3.80` / `+12p`) in a
  **domain entity** file. `ARCHITECTURE.md:71`: `domain/` is “entities +
  abstract `<feature>_repository.dart` ONLY”.
- `app/lib/features/kid_jar/presentation/widgets/jar_amounts.dart` — a file
  under `presentation/widgets/` (`ARCHITECTURE.md:75` “feature-private
  widgets”) that contains **no widget**; its only member is `jarPounds`, the
  sibling formatter doing the same job for `£x.xx`.

**Fix:** one feature-private `JarMoney` (both methods) beside the entity that
produces the pence, delete `jar_amounts.dart`, update the five call sites
(`my_jar_view.dart:185`, `jar_goal_card.dart:100,111,132`,
`jar_history_card.dart:226`). Pure refactor. Both format shapes must stay — the
row says `+12p`, the card says `£0.00`.

### 6. minor — the `NestProgress` kid-gloss hand-off is only half-filed, and the spec says both halves

`app/lib/core/design_system/components/nest_progress.dart:44-62` (shared — K09
may not edit it; RULES §1) against `components.css:160` and
`SPACING_SPEC.md:229-230`, which put the gloss **inside the fill**
(`.progress.kid > span::after { top: 2px; left/right: 4px; height: 4px }`).
The shared component puts it in a `Stack` over the **track**, so:

| | design | app |
|---|---|---|
| gloss rows (dark shots) | 561–564 (2 px below the fill's top) | 559–562 (2 px below the *bar's* top) |
| gloss x span | 43…229 (inside the 62 % fill) | 43…341 (whole track) |

`SHARED_REQUEST.md` describes only the horizontal half (“stop at the fill's
right edge”), so a fix applied straight from it leaves the 2 px vertical offset
in place. `5_ui.md:45` also records “progress fill 62% + gloss — pixel-identical
in crops”, which the probe contradicts for the gloss (the fill itself is
identical). Not a K09 defect and not fixable here — a documentation gap in a file
K09 *may* edit.

**Fix:** add the vertical dimension to `SHARED_REQUEST.md` — “measure `top: 2`
from the **fill**, not from the bar; putting the gloss inside the fill’s
`Container` as a `Positioned(top: 2, left: 4, right: 4, height: 4)` fixes both
deltas and is clipped by the pill radius” — and correct the `5_ui.md` row.

### 7. minor — `flutter analyze` was not clean on the branch's own test path (fixed in flight while this stage ran)

`app/test/features/kid_jar/k09_bugs_test.dart:330` and `:348` as committed —
two `cascade_invocations` infos (`await (db.update(db.savingsGoals)..where(…))
.write(…)` duplicates the `db` receiver), which fails RULES §7’s “`flutter
analyze` → No issues found (no ignores)” gate. `flutter analyze
test/features/kid_jar` reported 74 issues when I started; 72 were in the then
untracked `_probe*` scratch files, these 2 were not. **A concurrent stage
corrected both while this review was running and
`flutter analyze test/features/kid_jar` now reports “No issues found!”**, so
this is closed as long as the loop commits that change. Recorded because the
defect was in the committed file, not in uncommitted work, when I found it.

### 8. minor — the row's weekday sub-line is time-dependent but only recomputed on a database emission

`app/lib/features/kid_jar/data/kid_jar_repository_impl.dart:63` —
`londonWeekStartUtc(appNowUtc())` is evaluated inside the `map` of
`combineLatest4`, so “This Saturday” / “Last Saturday” only refreshes when the
ledger, goals, setting or quests change. Nothing re-emits when the London week
rolls over.

**Proof (mine):** with the pinned anchor moved from Sat 3 Oct to Mon 5 Oct and
**no** DB write, the list still reads “This Saturday” for the 3 Oct pocket-money
row, where `londonWeekStartUtc` says it must read “Last Saturday”; the label only
corrects on the next write. A fresh open is always correct, so this is latent and
minor — but it is a kid-facing statement about when money arrives, and two
screens can disagree depending on whether a write happened.

**Fix:** compute the week start where the label is read (a getter on the state,
or re-emit on resume / on a clock tick), so the copy cannot go stale.

### 9. minor — an unsourced magic size in the failure frame

`app/lib/features/kid_jar/presentation/views/my_jar_view.dart:316` —
`NestIcon(NestIcons.jar, size: 96, color: tokens.ink3)`. `96` is not a token and
has no CSS source (the design has no failure frame), so it is the one literal in
the feature that is neither design-derived nor documented. Cosmetic.

**Fix:** either name it as a documented constant the way the other per-frame
sizes are (`_failureArtSize`, with a comment saying the design has no error
frame), or follow `1_plan.md` §d and drop the art for the kid-voice line plus the
retry control.

## Verified correct (no finding)

- **The three mandatory ORCHESTRATOR_NOTES items (18:47), re-derived by me.**
  1. Quest-bonus rows go through `questIconFor(iconKey, audience: NestAudience.kid)`
     (`jar_history_card.dart:13`), and the kid table maps `bins` → `questBinsKid`,
     the K09-exact lidded bin (`quest_icons.dart:54`) — not the parent
     `NestIcons.questBins`. The repository supplies `iconKey` by joining the
     ledger `note` to `quests.title` in creation order
     (`kid_jar_repository_impl.dart:54-60, 206-208`).
  2. Pocket money uses `NestIcons.jarPocketMoney`; the gift uses
     `NestIcons.gift`, whose asset I read: `ic_gift.svg` draws
     `rect 3/9/18/12 rx2` + `M3 13h18` + `M12 9v12` + both bow loops — exactly
     `K09-jar.html:95` — so the note's “no `jarGift` file” is satisfied.
  3. “coming on Saturday” paints `--ink` (`my_jar_view.dart:232-238`), proven in
     pixels above, and the `.kcap` captions still use `--ink-2`.
- **Architecture / layering.** One bloc per screen; `BlocProvider` +
  `KidJarLoadRequested` at the route, DI in `kid_jar_di.dart` (both untouched by
  this diff and both correct); `domain/` = three entities + the abstract
  `KidJarRepository` only, with `watchJar()` on the interface rather than
  smuggled past it; no use-case classes, no extra folders, all imports
  `package:nestling/…`. (Finding 5 is the only layering slip.)
- **Design-system reuse; no re-implementation.** `KidScope` (with exactly one
  shared `NestMeadow`, asserted as a *count* in
  `my_jar_view_states_test.dart:221-248`, pinned 0…390 × 136 at the bottom),
  `NestStatusBar`, `NestIconButton`, `NestLockButton`, `NestProgress`,
  `NestKidButton`, `NestIcon`, `NestBalancedText`, `questIconFor`,
  `NestIcons.jarPocketMoney` / `gift`, `SvgPicture.asset(NestlingIllustrations.coin)`.
  Every colour and size is a token (`NestSpacing`, `NestDevice`, `NestRadii`,
  `context.nest` / `.nestKid`, `tokens.kidShadow`, `NestType.*`); the only
  literals are per-design geometry constants (`_backIconSize = 26`, `_artSize =
  34`, `_rowMinHeight = 60`, `_discSize = 40`, `_dividerInset = 66`, the 2 px
  divider via `NestSpacing.gap2`, the `fontSize`/`height` `copyWith`s), each
  carrying its `K09-jar.html:NN` line. `Colors.transparent` on the back button
  matches `kid_home_view.dart:166` and `kid_pin_view.dart:190`. The six
  transcribed `_JarPalette` colours are the inline SVG's own fills and have
  precedent in shared illustration code (`pip_avatar.dart:60-63`); only
  `groundShadow` follows the theme token, which my probe confirms is what the
  dark design shows.
- **Geometry** (`my_jar_view_geometry_test.dart`, ±2 per the UI VERDICT RULE,
  0.01 for edge alignment — not weakened): back `(20,47,56,56)`, lock
  `(314,47,56,56)`, title `(20,107,350,34)`, jar `(102,151,186,220)`, amount
  top 377 h 44 centred, “coming on” top 423 h 26, goal card `(20,465,350,153)`,
  progress `(39,557,312,16)`, heading `(20,634,350,26)`, list top 676, disc
  `(37,689,40,40)`, divider `(89,739,278,2)` (= card left 20 + border 3 + the
  design's 66), gutters 20 at 320/390/430 with cards and headings on one left
  edge. My probe above agrees with every one of these.
- **Spacing.** The 10 px title→jar gap is the design’s `.jar { margin: 10px auto 0 }`
  beating `.scroll > * + *`, not an off-by-six; every other separator comes from
  the same box model; 20 px gutters on both sides, cards on one edge (owner
  ALIGNMENT rule). The scroll tail is the design’s `--s8` alone because
  `SafeArea` already consumes the 34 px home inset (K09-BUG-6's fix, proved with
  a real inset: footer bottom 778 = 810 − 32).
- **Copy — character-exact** against `K09-jar.html:45-101`: `My jar`, `Back`,
  `Grown-ups`, `coming on Saturday`, `What went in`, `Lego Friends set`,
  `£15.50`, `£9.49 to go`, `of £24.99`, `62% there!`, `Pocket money`,
  `Quest bonus`, `From Mum`, `+12p`, `Mum keeps the real money. This jar just
  shows how well you have done.` — no straight quotes, no substituted dashes or
  ellipsis, no US spelling (UK `Mum`, UK `colour` in the tests). Non-design copy
  (loading / error / retry / empty) is kid-voice UK English. The gift note parse
  `(added by Mum)` → `From Mum` matches the seed’s real note.
- **Cascade rulings hold.** `.money` (`components.css:155`) sits after
  `.kid-hero` (`:37`) at equal specificity, so the hero is **w700** (implemented);
  `.k9-amts b` (0,1,1) beats `.money` so the card figures are w900 (implemented);
  `.k9-v` (screen `<style>`, loaded after `components.css`) wins over `.money`
  at equal specificity → w900 (implemented). `.k9-when` sets no colour and
  inherits `.screen`’s `--ink` — the pixel evidence above is what proves it.
- **Balanced headings / tracking.** `NestBalancedText` on both `.kid-title`
  headings; plain `Text` on the goal card’s bare `h2`, on the hero number (the
  house pattern for a single-token amount, cf. `money_ledger_view.dart:361-370`)
  and on `.kid-body`/`.kcap` — never on a body or caption. No `letterSpacing`
  anywhere.
- **DATA OVER MOCKS.** Seed wins on every number: `+£3.00` where the design’s
  example row says `+£3.80`, nine rows where the design shows three, “This
  Saturday” where the design says “Last Saturday”. The seed ledger order was
  dumped and checked by hand: owed = 300 + 12 + 40 + 40 + 28 = **420p = £4.20**,
  goal 1550/2499 → 62 % and `£9.49 to go`, `payoutDay` 6 → `Saturday`, and
  `_summarize`’s `break` on the first `payout` correctly excludes the rows older
  than 26 Sep. Only `{weekly_base, quest_bonus, gift}` reach the list
  (`_moneyInTypes`), `watchLedger` is already date-desc so newest-first holds, and
  the demo seed has no duplicate timestamps (checked) so the `break` is
  unambiguous.
- **Robustness already fixed.** Owed is floored at 0 so a signed correction can
  never be shown as positive money coming; `remainingPence` is clamped so a
  reached goal reads `£0.00 to go` and never contradicts its own `100% there!`;
  `moveToSavings` caps at the goal remainder inside the transaction, with the
  ledger row and the goal write agreeing on `move`.
- **Accessibility.** Both controls expose `SemanticsAction.tap`, are 56 × 56,
  keep their `aria-label`s, and the tests `performAction` them (the lock really
  pushes `/parental-gate`). History rows and the empty row correctly claim **no**
  tap (asserted `isFalse`). The three `excludeSemantics: true` nodes in the diff
  are all non-controls (the amount+weekday sentence, the jar `image: true` label,
  the shared progress bar) — none wraps a control, so the
  “must pass `onTap:`” rule is satisfied. The title is a header, the loading frame
  is a `liveRegion`, the failure frame’s `Try again` reaches the real reload
  (`repo.watches == 2`).
- **Performance.** `BlocBuilder` sits inside `Expanded`, so an emission rebuilds
  the body only — chrome and `KidScope` never re-run; equal states compare equal.
  One `watchJar()` subscription per load, released on error, on reload and in
  `close()` (except finding 1’s window); `_switchMap` cancels the inner stream on
  `onCancel` and documents why `asyncExpand` cannot be used with never-closing
  Drift streams; the painter repaints only on fill/theme change; the list is a
  `Column` inside a `SingleChildScrollView` over ≤ a few dozen rows; `const`
  where `const` (`NestStatusBar`, `_JarTopRow`, `_GateLockButton`, the spacer and
  separator `SizedBox`es). No rebuild storms.
- **Error handling.** The failure frame keeps the chrome and the sky/meadow,
  shows kid copy plus a working retry, and `copyWithLoaded` clears a stale error
  on the first healthy emission while the retry keeps it visible. No error text,
  id or stack ever reaches the child.
- **Children’s Code.** No analytics, ads, tracking, network, logging or PII
  output anywhere in the diff; nothing leaves the device; no red, no nagging, no
  streak/loss framing; the failure copy is a plain “Try again”, never blame.

## Hand-off note for K10 (not a finding)

`/payout-day` (`PayoutDayView`) still reads `KidJarState.items`, and both
`KidJarState.items` and `KidJarRepository.watchItems()` are now the **money-in**
list (`{weekly_base, quest_bonus, gift}`) for the *active* child, derived from
`watchJar()`. K10 needs the full ledger (including `payout` rows) for a chosen
child, so its loop will need its own stream — either a `watchLedgerFor(childId)`
on the interface or a `KidJarState` field carrying the payout rows. Flagged so
K10 is not surprised by the narrowed contract; nothing to change here.

## Process items (loop-owned, explicitly NOT findings)

Per the PROCESS ITEMS rule these are uncommitted-work facts, recorded so the
loop does not trip over them — none is a blocker or a major:

- A concurrent **stage 3 / stage 6** was editing the tree throughout this
  review: five tracked test files are modified and six `_probe*_test.dart`
  scratch files were present when I started. **They have since been deleted**
  (the directory is back to the six tracked files) and `flutter analyze` and
  `dart format` are both clean again — but the loop must confirm nothing
  `_probe*`/`_scratch*` is committed: four of those probes were red on purpose
  and, between them, they were 72 of the 74 analyze issues.
- Stage 6 has parked four red proofs with `skip:` (K09-BUG-7 ×2, K09-BUG-8 ×2).
  That is its documented pattern; findings 1 and 3 say to un-skip them with the
  fixes. Note that `flutter test test/features/kid_jar` ran past 15 minutes at
  one point during this stage — if that is not just contention with the
  concurrent agent, it is a hanging test and the TEST TIMEOUTS rule applies
  (“a test that can hang is a bug, so fix it”).
- The branch is behind `main` past the loop’s own merge at `532ba70`; the loop
  owns commit and merge order.
- `5_ui.md` records simulator `E7D5555E-…`; the brief now names only
  `604697A9-11DA-462F-9837-396E9CA2493A` for stage 5. Noted for the
  orchestrator, not a code finding.

## Verdict

The iteration-2 diff does what it was asked to do. The three orchestrator-mandated
items in `ORCHESTRATOR_NOTES.md` (18:47) are implemented and now proven three ways
— code, tests and my own pixel probe. The design structure, the copy and the
layout are faithful: my independent measurement puts the goal card, the progress
bar, the goal card’s bottom border and the history card’s top border on the
design’s exact rows in both themes, and the heading within 1.3 px. The layering is
feature-first, every colour and size is a token, streams are released, and the
child-facing copy is character-exact UK English with no analytics, no red and
nothing leaving the device.

Nothing found rises above minor, and every one of the nine is fixable inside
`app/lib/features/kid_jar/**` or `docs/screens/K09/**` — finding 6 is itself the
hand-off for the one shared-code defect it reports. None of them contradicts the
design’s structure, the copy, the architecture or the Children’s Code rules. The
next iteration should take findings 1–4 (one `isClosed` guard, one `Flexible`, one
goal-lookup guard, one `size: 22`), un-skip the K09-BUG-7/8 proofs with those
fixes, tighten finding 6's request with its vertical dimension, and make the
weekday label refresh (finding 8).

VERDICT: PASS
