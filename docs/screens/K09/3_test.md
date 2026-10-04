# K09 · My jar — Stage 3 (TEST, iteration 1)

Route `/my-jar` · feature `kid_jar` · branch `screen/K09` · base `444e085`
("K09: checkpoint after build (iteration 1)"). In-memory Drift via
`test_scope.dart` + `Seed.demo` / `Seed.empty`, plus a swapped-in fake
repository for the states the database cannot produce on demand.

**No simulator was booted, installed on, screenshot or driven** (stage rule —
only `5_ui` may, and only `E7D5555E…`). No `flutter clean`, no interactive
`flutter run`, no image attached. No production code edited: every finding is
recorded, not patched (RULES §1 keeps this stage inside
`app/test/features/kid_jar/**` + `docs/screens/K09/**`).

## Headline

| gate | result |
|---|---|
| `dart format --output=none --set-exit-if-changed` (my 3 files) | `Formatted 3 files (0 changed)` — exit 0 |
| `flutter analyze lib/features/kid_jar` + my 3 test files | **No issues found!** |
| `flutter test --timeout 120s` (the five K09 files) | **`+77 -5`** |
| `flutter test --timeout 120s` (whole repo) | **`03:34 +4137 ~7 -5`** — the 5 failures are exactly the K09 bug proofs below; no other feature is red |

**Three real bugs found, five red proofs, left red on purpose** (§3):

| id | what | severity |
|---|---|---|
| **K09-BUG-1** | `emit.forEach` does not cancel the prior subscription, so "Try again" stacks live subscriptions and a stale one can overwrite the recovered screen | minor (same defect as K03's K03-BUG-15) |
| **K09-BUG-2** | `coming on Saturday` is painted `--ink-2`; the design inherits `.screen`'s `--ink` and the app's line is visibly lighter | **minor, orchestrator-mandated** |
| **K09-BUG-3** | every quest-bonus row shows the bins glyph instead of `questIconFor(key, audience: kid)` for the quest the row names | **major, orchestrator-mandated** |

Nothing else regressed. The `~7` skips are pre-existing and belong to other
features (`k01_bugs_test.dart`, `k03_bugs_test.dart` ×2, `p12_bugs_test.dart`,
plus the three the concurrent stage 6 parked while this stage ran).
**No `kid_jar` test is skipped.**

---

## 1. ORCHESTRATOR_NOTES (18:47) — all three items, all mandatory

The note landed *during* this stage (`docs/screens/K09/ORCHESTRATOR_NOTES.md`,
18:47), so it is covered here in full.

| item | status |
|---|---|
| *"Quest-bonus rows must use `questIconFor(key, audience: NestAudience.kid)`, not the parent `NestIcons.questBins`"* | **Checked, and the screen violates it → K09-BUG-3** (§3.3). Proof added: `my_jar_view_test.dart`, *"K09-BUG-3: a quest-bonus row shows the quest's own kid glyph"* (red). |
| *"The pocket-money and gift glyphs are being added on shared/jar_glyphs (`NestIcons.jarPocketMoney` / `jarGift`). Use them once on main."* | **BLOCKED on main, nothing to test yet.** `grep -rn "jarPocketMoney\|jarGift" app/` → no hits; neither constant exists on `screen/K09`, so a proof naming them would not compile. The intended proof is written out as a comment next to K09-BUG-3's so it can be pasted verbatim once main lands them. `jarEntryGlyph` currently returns `NestIcons.poundCoin` for `weekly_base` and `NestIcons.gift` for `gift` (`jar_history_card.dart:10-14`) — the two call sites to change. |
| *"Check that the 'coming on Saturday' colour matches the HTML (the app looks lighter)."* | **Checked — the app IS lighter, and the design says so → K09-BUG-2** (§3.2). Proof added for light **and** dark, both red. |

---

## 2. Tests added (41 new; feature suite 40 → 82)

| file | was → is | added |
|---|---|---|
| `my_jar_view_states_test.dart` | — → **30** | new file: loading, failure, retry recovery, the REAL `Seed.empty` jar, tap targets, a11y labels |
| `kid_jar_bloc_test.dart` | 9 → **12** | +1 `blocTest` for the failure path, +2 K09-BUG-1 proofs (red), +`_CountingKidJarRepository` |
| `my_jar_view_test.dart` | 17 → **26** | the layout matrix gains the **dark** dimension (6 → 12), +3 note-driven proofs (K09-BUG-2 ×2 themes, K09-BUG-3) |

### 2.1 `my_jar_view_states_test.dart` — the states a healthy seed hides

The demo database can only ever show the happy path, so the states are staged
the way `reward_shop_view_test.dart` (K08) does it: `KidJarRepository` is a
lazy singleton and `KidJarBloc` a factory, so a fake is swapped into GetIt
(`_useFakeRepository`) before the route builds its bloc. `Seed.empty` needs the
opposite order — seed **before** `configureDependencies`, because `Seed.empty`
calls `db.clearAll()` and that never completes on a database `AppSession` is
already watching.

| test | what it pins |
|---|---|
| a stalled jar shows the spinner with its own label | `Loading your jar` on the `CircularProgressIndicator`; **nothing** from the loaded body leaks into the first frame (no title, no goal card, no list, no exception) |
| the kid sky and meadow survive the stall | `KidScope` is mounted behind the spinner — a slow database never flashes a bare scaffold |
| exactly one shared meadow, mounted by `KidScope` | KID BACKGROUND as a **count**, not an absence (the meadow legitimately lives *inside* `KidScope`): one `KidScope`, one `NestMeadow`, and the hills are where the HTML pins them — x 0…390, 136 tall, bottom = 844 (BOTTOM EDGE: K09 has no bar, so the meadow reaches the physical edge) |
| a stalled jar can still go back / still reach a grown-up | the chrome works while the spinner animates (both pump explicitly — `pumpAndSettle` would spin until its own timeout) |
| a failed jar offers a kid-voice retry | `Oh no! Something went wrong.` + `Try again`, no stale `£4.20`, no spinner, no jar art, no goal card, both chrome controls present |
| the failure state reads the same in dark mode | dark copy parity |
| **Try again really reloads and the jar comes back** | `repo.watches == 2`; the failure copy, spinner and error state all go; `My jar` / `£4.20` / `Lego Friends set` / `+£3.00` return (the seed's 300p weekly base, not the design's `+£3.80` — DATA OVER MOCKS) |
| **VoiceOver/TalkBack can press the retry too** | the `Try again` node advertises `SemanticsAction.tap`, and `performAction` reaches the real outcome (`watches == 2`, screen loaded) |
| failure state × 320/390/430 × 1.0/1.3 × light/dark (12 cases) | no overflow, no exception; the retry stays ≥ 56 px tall **and** wide at every size and never exceeds the viewport |
| **`Seed.empty`: nothing owed, no goal and the one empty row** (light + dark) | driven by the real database, not a fake: `£0.00`, `coming on Saturday`, **no** `JarGoalCard`, **no** `NestProgress`, no `to go`; the design's empty row `Nothing here yet` / `Finish a quest to fill your jar`; no `+` amount anywhere; the jar's `percentLabel == 0` |
| the empty jar announces itself at 0% | `A glass money jar about 0% full of coins` and the merged `£0.00 coming on Saturday` |
| the empty jar still goes back and still reaches a grown-up | no dead end with no children |
| no overflow at 320 px / 1.3x on the empty jar | the short column still keeps 20 px gutters |
| **every control is at least the kid minimum of 56 px** | back, lock (and the retry, above) — the RULES §7 "≥ 56 kid" rule, asserted against `NestDevice.tapKid` rather than a magic number |
| a tap well away from the glyph still works | tap at `left + 5`, level with the centre — outside the 26 px chevron, inside the 56 px box. (Note: `NestIconButton`'s `InkWell` is bounded by a `CircleBorder`, so the box *corners* sit outside the circle by design — Material behaviour shared with every other screen's icon button. Recorded, not a finding.) |
| both icon buttons carry the design aria-labels | `K09-jar.html:45` `aria-label="Back"` / `aria-label="Grown-ups"`: exact label, `isButton`, tap action; `Back` also reports `isEnabled` |
| tapping a history row changes nothing | a ledger row is display-only: no navigation, no exception, no state change (`1_plan.md` §e) |

### 2.2 `kid_jar_bloc_test.dart` — every event/state path

`KidJarLoadRequested` is the only event, so "every path" is
`initial → loading → {loaded, failure}` plus recovery. Added:

- a `blocTest` for the **failure** path (previously only a hand-rolled
  `expectLater` covered it), pinning that a failed load reports `failure`,
  carries the error message and leaks **no** data (`items` empty, `owedPence`
  0, `goalTargetPence` 0);
- `_CountingKidJarRepository` — keeps every stream it hands out so a test can
  count **live** listeners, the only way to answer "was the previous
  subscription released?" for a stream that never completes;
- the two `K09-BUG-1` proofs (§3.1), deliberately left red.

State-object semantics (`initial` defaults, `copyWithLoaded` replacing every
jar field and clearing the error, `copyWith` leaving the rest, Equatable
equality) were already covered by 2a and still pass unchanged.

### 2.3 `my_jar_view_test.dart` — loaded matrix gains dark, plus the note proofs

The matrix was light-only. It is now **widths 320/390/430 × textScale
1.0/1.3 × light/dark (12 cases)**, each scrolling to the footer, asserting no
exception and the presence of the title, the goal card and the history card.
The 6 pre-existing light cases are unchanged. Three note-driven proofs were
added in two new groups (K09-BUG-2, K09-BUG-3) — see §1 and §3.

---

## 3. BUGS FOUND

### 3.1 K09-BUG-1 [minor, OPEN] a reload stacks a live subscription

**Where:** `app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart:22`
(`await emit.forEach<JarSnapshot>(_repository.watchJar(), …)`), reached from
`app/lib/features/kid_jar/presentation/views/my_jar_view.dart:325` — the
failure state's `Try again` dispatches `KidJarLoadRequested` again.

**The code documents an invariant it does not have.** `kid_jar_bloc.dart:7-9`
says: *"Retry re-adds `KidJarLoadRequested`; `emit.forEach` cancels the prior
subscription."* `1_plan.md` §b and `2_build.md` repeat it. It does not: bloc
9.2.1 processes events **concurrently** by default
(`bloc-9.2.1/lib/src/bloc.dart:32` — "By default events are processed
concurrently"), so each dispatch starts another never-ending handler while the
previous one is still subscribed.

**Why it is reachable:** `emit.forEach` with an `onError` callback does not
cancel its subscription on an error, and a Drift watch stream that errors does
not close. So at the moment the child taps `Try again`, the failed handler is
*still subscribed* — the exact path the failure state exists for.

**Measured (the two red proofs):**

1. *"K09-BUG-1: retry does not stack live stream subscriptions"* →
   `Expected: <1> Actual: <2>` after the second load, 3 after the third.
2. *"K09-BUG-1: a stale subscription can overwrite the reloaded state"* → the
   current subscription speaks last and the state is right (`maya` / 420p);
   then the **abandoned first** subscription emits Leo's snapshot and the bloc
   adopts it → `Expected: 'maya' Actual: 'leo'`.

**Blast radius:** each stacked subscription is a live fan-out of **three**
Drift queries (`watchLedger` + `watchGoals` + `watchSetting`,
`kid_jar_repository_impl.dart:43-46`), so three taps on `Try again` leave nine
live watch queries until the bloc closes, and every ledger write then notifies
all of them. With the real repository both subscriptions read the same tables,
so the child's screen still shows correct numbers — the defect is duplicated
work, a comment that invites a future "fix" on a false premise, and the latent
ability of an abandoned stream to overwrite the state the recovered screen is
showing.

**Same defect, already ruled on for K03:** `docs/screens/K03/FIXES_7.md:94`
files *K03-BUG-15* — "retrying a load stacks live subscriptions", rated
moderate, with the same cause and the same suggested fix:

> keep a `StreamSubscription<T>?` and cancel it at the top of the load handler
> (or guard with a `_streaming` flag), released on error and on `close()`.

K03's fix landed as a guarded subscription with the stream output re-entering
the bloc as internal events (`docs/screens/K03/k03_bugs_test.dart`, header,
iteration 8). K09 has the identical load handler and none of that.

**Left red on purpose.** The proof is **not** parked with `skip:`: the stage
rule is "record it, do not patch it", and a parked proof would let the loop see
a green suite with an open defect. Both tests are named `K09-BUG-1`, sit in
their own group with the diagnosis in the group header, and go green the moment
the bloc cancels-before-reload.

### 3.2 K09-BUG-2 [minor, OPEN, orchestrator-mandated] the payout weekday is the wrong ink

**Where:** `app/lib/features/kid_jar/presentation/views/my_jar_view.dart:231`
— `NestType.kidBody(color: tokens.ink2)` on `coming on Saturday`
(`K09-jar.html:69`).

**The rule:** `.k9-when` is a bare `<p class="kid-body k9-when">`. Neither
`.kid-body` (`components.css:35`) nor `.k9-when` (`K09-jar.html:23`) sets a
colour, so the line INHERITS `.screen { color: var(--ink) }`
(`components.css:23`) — **full ink, not `--ink-2`**.

**Measured off both design PNGs** (I sampled the pixels; this is not a reading
of the CSS alone):

| line | light | dark | token |
|---|---|---|---|
| `coming on Saturday` | **4001 px of exactly `#1E1B3A`** | **4001 px of exactly `#F3F0FA`** | `--ink` |
| goal captions `.kcap` (`of £24.99`, `62% there!`) | exactly `#4A4668` | exactly `#C9C4DC` | `--ink-2` |

The app renders the first line in `#4A4668` / `#C9C4DC` — the second row's
token. The orchestrator's 18:47 note ("the app looks lighter") is correct.

**Measured (the two red proofs, one per theme):**
light `Expected 0.1176/0.1059/0.2275 (#1E1B3A) Actual 0.2902/0.2745/0.4078
(#4A4668)`; dark `Expected #F3F0FA Actual #C9C4DC`. Each proof also asserts
the rendered colour is *not* `tokens.ink2`, so it cannot pass by accident on a
theme where the two tokens coincide.

**Fix (bugs stage):** `tokens.ink2` → `tokens.ink` at that one call site. The
other three `ink2` uses on this screen are correct: `.kcap` footer
(`K09-jar.html:100`), `.k9-s` row sub (`:37`) and `.kcap` goal captions
(`:15`) really are `--ink-2` — the PNG measurement above pins the difference,
so do not blanket-replace.

### 3.3 K09-BUG-3 [major, OPEN, orchestrator-mandated] one glyph for every quest bonus

**Where:** `app/lib/features/kid_jar/presentation/widgets/jar_history_card.dart:10-14`
— `jarEntryGlyph` maps `'quest_bonus' => NestIcons.questBins` for every row,
ignoring which quest the row is for. The 18:47 rule: *"Quest-bonus rows must
use `questIconFor(key, audience: NestAudience.kid)`, not the parent
`NestIcons.questBins`."*

**Why it cannot be fixed in the widget alone:** `jarEntryGlyph` only receives
the entry *type*. `ledger_entries` has no quest reference — the schema
(`app/lib/core/data/app_database.dart:157-170`) carries `type`, `note`,
`amountPence`, `date`, `dateTz` only — so the icon key has to be resolved from
the quest the `note` names, in `KidJarRepositoryImpl`. That means: a new
`JarEntry.iconKey` (feature domain, in scope), a `watchQuests`-backed title →
icon lookup in `_jarFor` (`kid_jar_repository_impl.dart:39-59`), and
`jarEntryGlyph` taking the key.

**Measured (the red proof reads the seeded quests out of the database and
demands the kid glyph):**

| row title | seeded `icon` | expected kid glyph | rendered | verdict |
|---|---|---|---|---|
| `Put the bins out` | `bins` | `questBins` | `ic_quest_bins.svg` | accidentally right (that key is shared by both audiences) |
| `Hoover the stairs` | `hoover` | `questHoover` | `ic_quest_bins.svg` | **wrong** |
| `Tidy your bedroom` | `bed` | `questBedKid` | `ic_quest_bins.svg` | **wrong** (the kid bed, not the parent bed) |
| `Help with the washing` | `shirt` | `washingMachine` | `ic_quest_bins.svg` | **wrong** |

So 3 of Maya's 4 distinct quest rows show the wrong artwork. The proof stops
at the first mismatch (`Expected … ic_quest_hoover.svg Actual …
ic_quest_bins.svg`); fixing `hoover` alone will not make it green.

Note this is a case where the mandatory rule and `K09-jar.html:90` disagree —
the design's example row *does* draw the bins glyph — and the note wins.

---

## 4. Also verified, clean

| area | evidence |
|---|---|
| Copy parity | `My jar`, `coming on Saturday`, `What went in`, `Lego Friends set`, `£15.50`, `£9.49 to go`, `of £24.99`, `62% there!`, the footer, `Back` / `Grown-ups` — character-exact against `K09-jar.html:45-100` |
| Jar / progress semantics | `62% of the Lego Friends set saved` (`K09-jar.html:79`), `A glass money jar about N% full of coins` (`:48`), `£4.20 coming on Saturday` merged into one node |
| Navigation | back → `/kid-home` (and it POPS when pushed from `/kid-home` rather than `go`-ing), lock → `/parental-gate`; every tap asserted to the right destination |
| Geometry (real bundled faces) | back/lock 20…76 & 314…370 at y 47, title y 107, jar 186×220 at 151, amount 377, "coming on" 423, goal card 465 (350×153), progress 39,557,312×16, heading 634, list 676, row disc 689, divider inset 66 — all within ±2 (UI VERDICT RULE), 20 px gutters at 320/390/430 |
| Repository / seed truth | `owed 420p`, goal `Lego Friends set` 1550/2499, `Saturday`; Leo 210p with no goal; `Seed.empty` empty/0; live child switch; a new money-in row lands at the head with `owed 440`; a `spend` row moves nothing |
| PERIODS / CLOCK | no `DateTime.now()` in my tests (the one date literal is pinned to the test clock's Sat 3 Oct 2026); row copy `This {weekday}` / `Last {weekday}` comes from `londonWeekStartUtc` |
| FONTS | no `google_fonts` import or `GoogleFonts.*` call anywhere in the feature tests |
| Harness | every pumped app ends with `disposeApp(tester)`; every run used `--timeout 120s`; the whole feature suite runs in ~10 s |
| Scope (RULES §1) | only `app/test/features/kid_jar/**` and `docs/screens/K09/**` touched. No `app/lib/**`, no `app/lib/core/**`, no `app/lib/app/**`, no other feature, no `tools/screens/**` |

---

## 5. Observations — checked, deliberately NOT filed as findings

1. **The scroll's tail padding counts the home indicator twice.**
   `my_jar_view.dart:266-271` pads the scroll by `NestDevice.homeH + NestSpacing.s8`
   (34 + 32 = 66) *and* wraps everything in `SafeArea(top: false)` (`:69`),
   which already consumes the device's bottom inset. The design has
   `.scroll { padding: 0 20px var(--s8) }`
   (`design/html-source/components.css:65`) with `.home-indicator` as a
   **sibling** (`K09-jar.html:102`, `components.css:51`, 34 tall), so the
   design's total tail is 66 and the app's is 100: 34 px more scroll at the
   very end. Not filed: the design PNG is at scroll-top where the tail is
   invisible (the footer sits below the fold in the design), nothing can be
   clipped, no element moves, and the meadow fills the extra room, so no owner
   rule (BOTTOM EDGE / ALIGNMENT) is touched. Worth the UI stage's eye if the
   max-scroll position is ever shot. (K08/K06 use the same padding *without* a
   `SafeArea`, which is why the copied pattern landed here twice.)
2. **`NestLockButton` does not set `enabled: true`** on its `Semantics` node
   (shared component, `app/lib/core/design_system/components/nest_lock_button.dart:24-28`
   — outside RULES §1). RULES §8 only requires the flag for *disabled*
   controls, and every platform reads an unset flag as enabled; the tap action
   is present and asserted. Noted so the next reader does not "fix" it here.
3. **`find.bySemanticsLabel` is the way in, `getSemantics(byType(...))` is not**
   for these two buttons: the `NestIcon` child leaves the label node as a
   sibling, so the widget-level `getSemantics` returns an empty label (K01's
   notes hit the same trap).
4. **Stages 4, 5 and 6 are running concurrently in this worktree** (K01's
   iteration-3 note says the same). `test/features/kid_jar/_probe_probe*_test.dart`
   and the concurrent stage's `k09_bugs_test.dart` are not mine — I did not
   touch any of them. The probes currently account for most of the
   `flutter analyze` infos in the feature directory and for extra passing tests
   when the *directory* is run, which is why every number above comes from an
   explicit five-file run.

---

## 6. Defects in my own tests (recorded so they are not mistaken for findings)

Three, all found and fixed inside this stage, none of which touched `lib/`:

1. A 5 px corner tap on the back button did not navigate. Cause:
   `NestIconButton`'s `InkWell` uses `customBorder: CircleBorder()`, so the box
   corners are outside the hit circle. My assertion was wrong, not the screen;
   the test now taps 5 px in from the left edge level with the centre (§2.1).
2. `tester.getSemantics(find.byType(NestIconButton)).label` came back `''`
   (see observation 3).
3. `data.hasFlag(SemanticsFlag.isButton)` is deprecated in this SDK
   (`deprecated_member_use`); switched to `data.flagsCollection.isButton`,
   the API `test/core/design_system/semantics_actions_test.dart` already uses.

## 7. Left for the next iteration

1. **The bugs stage owns all three** (§3): K09-BUG-1 (cancel-before-reload in
   `KidJarBloc._onLoadRequested`, release on error and on `close()`, and fix
   the comment at `kid_jar_bloc.dart:9`), K09-BUG-2 (`tokens.ink2` → `tokens.ink`
   at `my_jar_view.dart:231`), K09-BUG-3 (carry the quest's `iconKey` through
   `JarEntry` and render `questIconFor(key, audience: NestAudience.kid)`).
   Five proofs go green with no test edit.
2. **`NestIcons.jarPocketMoney` / `jarGift`** land on `main` via
   `shared/jar_glyphs`; the next build swaps the two `jarEntryGlyph` branches
   and pastes the proof from the comment in `my_jar_view_test.dart`.
3. `5_ui`: the ±2 px table in `2_build.md` still applies (the geometry file is
   green and my changes add no layout assertions to the loaded screen), but
   **K09-BUG-2 will show up as a real band-drift on the `coming on Saturday`
   line** — measure that line against the design PNG's `#1E1B3A`, not the app's
   `#4A4668`. Observation 1 is the only other thing I would add to the shot
   list, and only if the UI stage shoots the scrolled-to-bottom frame.
4. Nothing else is blocking: with the three fixed the whole repo is expected
   green at `+4142 ~7 -0`.
## 8. Verdict

`dart format` clean, `flutter analyze` clean on everything I touched, 77 of the
82 `kid_jar` tests green, and the whole repo's only 5 failures are the proofs
of the three defects above — every one of them re-confirms a mandatory
orchestrator rule or a code comment that is provably false. The stage rule is
explicit: *PASS only if all tests pass and no bugs were found*. Three bugs were
found, none of them mine to patch, so the suite is left red on purpose and the
bugs stage has three ready-made proofs, file:line references and repro commands.

VERDICT: FAIL
