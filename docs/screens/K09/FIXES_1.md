# Fix list after iteration 1

## From 3_test.md
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


## From 5_ui.md
# K09 · My jar — 5 UI CHECK (iteration 1)

Route `/my-jar`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Seed `demo`, mode `kid`, child `maya`. No code edited.

Shots: `docs/screens/K09/ui/app_light_1.png`, `app_dark_1.png`.
Comparisons: `cmp_light_1.png`, `cmp_dark_1.png` (vs
`design/screens/light|dark/K09-jar.png`, 1170×2532 @3x → logical ÷3).

## Mean diff

- Light: **1.31%** (bands: 0–105: 1.59 · 105–211: 0.18 · 211–316: 0.16 ·
  316–422: 0.19 · 422–527: 1.39 · 527–633: 0.81 · 633–738: 2.21 ·
  738–844: 3.97)
- Dark: **1.34%** (bands: 0–105: 1.60 · 105–211: 0.19 · 211–316: 0.13 ·
  316–422: 0.44 · 422–527: 1.30 · 527–633: 1.12 · 633–738: 2.14 ·
  738–844: 3.80)

Band 0 is the OS status bar (18:38 + real glyphs vs mock 9:41 — ignored per
STATUS BAR rule). Bands 6–7 are dominated by the DB-driven first history row
(see 3) and the mock home-indicator pill (design) vs OS-drawn indicator
(absent in sim screenshots — same class as the status bar, ignored).

## Measured geometry, design vs app (logical px, ±2 px rule)

All script-measured on 390×844 downscales; identical unless stated:

| element | design | app | Δ |
|---|---|---|---|
| back chevron glyph box | x 43–51, y 67–82 | same | 0 |
| lock glyph box | x 334–349, y 66–83 | same | 0 |
| “My jar” glyph top | y 113 | y 113 | 0 |
| jar lid top (col x=195) | y 154 | y 153 | 1 ✓ |
| jar glass sides (y 200/250/350) | x 127–262 / 126–263 / 143–246 | same | 0 |
| hero “£4.20” glyph top | y 384 | y 384 | 0 |
| goal card top border | y 465–467 | y 465–467 | 0 |
| progress bar borders | y 557–558, 571–572 | same | 0 |
| goal card bottom border | y 615–617 | y 615–617 | 0 |
| “What went in” glyph top | y 639 | y 640 | 1 ✓ |
| history card top border | y 676–678 | y 676–678 | 0 |
| divider | y 739–740, x 89–367 (inset 66) | same | 0 |
| jar fill / coins / gloss / sparkle / shadow | — | pixel-identical in crops | 0 |
| progress fill 62% + gloss | — | pixel-identical in crops | 0 |

Copy (visible viewport): “My jar”, “£4.20”, “coming on Saturday”,
“Lego Friends set”, “£15.50”, “£9.49 to go”, “of £24.99”, “62% there!”,
“What went in”, “Pocket money”, “Put the bins out”, “Quest bonus”, “+12p”
all match the HTML character-for-character. Gutters 20 px both sides; both
cards share the same edges. No overflow/clipping/ellipsis issues.
Dark mode: sky, meadow, coin-tint card, disc tints, borders and shadows all
match the dark design. Bottom edge: no bar on this screen; shared meadow
runs to the physical edge in both themes — owner rule satisfied. Hero weight
ruling (Bold w700, `2_build.md`) confirmed: hero band diff 0.19% is noise.
Jar-fill ruling (fraction × interior) confirmed: jar crops identical.

## Numbered deviations

1. **History row-1 disc glyph wrong** (light + dark). Design
   (`K09-jar.html:85`): circle r8 + vertical stroke `M12 8v8` + two
   horizontal ticks `M9.5 9.5h5` / `M9.5 14.5h5` — a geometric coin-slot
   mark, NOT a £. App renders `NestIcons.poundCoin`, a curved £ letterform
   in the circle (crop `_tmp_*_r1`: straight double-tick mark vs £).
   Element: `.k9-ico` row 1, 22 px glyph in 40 px disc. Design value: HTML
   inline SVG; app value: shared pound-coin asset. Fix: `jarEntryGlyph`
   (`app/lib/features/kid_jar/presentation/widgets/jar_history_card.dart:10`)
   maps pocket-money rows to the shared icon; transcribe the HTML:85 SVG
   feature-private (jar-illustration precedent) or file a SHARED_REQUEST if
   the shared asset is meant to change. Note the mapping lives in feature
   code but the asset is shared (`core/design_system`), so the builder
   cannot just swap the asset.
2. **History row-2 (quest bonus) disc glyph wrong** (light + dark). Design
   (`K09-jar.html:90`): bins glyph — lid trapezoid `M6 3h12l-2 5H8Z` over a
   straight body with U bottom. App renders `NestIcons.questBins`, a
   handled box/briefcase shape with a dash (crop `_tmp_*_div`: test-tube/bin
   vs handled box — unmistakably different silhouettes). Element: `.k9-ico`
   row 2. Design value: HTML:90 bins SVG; app value: shared questBins asset
   via `jarEntryGlyph` (`jar_history_card.dart:11`). Fix: same as 1 —
   transcribe the HTML:90 bins SVG feature-private (and check the fallback
   claim in `2_build.md`, which asserted the fallback “is the design”: the
   rendered pixels prove it is not) or SHARED_REQUEST.
3. **Row-1 sub-copy + amount differ — NOT a finding (DB wins).** Design:
   “Last Saturday” / “+£3.80”. App: “This Sunday” / “+£3.00”. The demo seed
   is anchored to today (Sun 4 Oct 2026): the newest `weekly_base` entry is
   300p dated this week → “This Sunday” per the `1_plan.md` §b relative-day
   rule, and 300p formats as “+£3.00”. Correct per DATA OVER MOCKS; do not
   “fix” toward the mock. (Same reason the app shows 9 money-in rows vs the
   design’s 3 example rows; viewport rows 1–2 otherwise align exactly.)
4. **Gift-row glyph unverified (below the fold).** Rows 3+ (“Birthday money
   / From Mum”) are cut off at the viewport bottom in both the design and
   the app shot, so `NestIcons.gift` vs `K09-jar.html:95` could not be
   compared. Given deviations 1–2, the builder must crop-compare the gift
   glyph the same way before signing off (scroll or widget-level capture).

## Verdict reasoning

Geometry, copy, colours, radii, shadows, progress, jar art, alignment,
gutters, dark mode and bottom edge all pass with zero measurable drift.
Deviations 1–2 are icon-choice mismatches on two of the two visible history
rows — explicitly listed in the stage-5 checklist (“icon choice”) and
covered by the ICONS orchestrator rule (“each screen matches its own
design’s glyphs exactly”). A designer would reject either glyph swap, so
the check cannot pass despite the low mean diff.


## From 6_bugs.md
# K09 · My jar — bug hunt (Stage 6, iteration 1)

Adversarial pass over `kid_jar` K09 after the iteration-1 build and the
concurrent stages 3–5: data edges, rapid double taps, back navigation and
deep links, parent/kid mode guards, restart persistence, dark contrast,
320 px + 1.3 scale, async gaps, Europe/London + BST, integer-pence money,
owner rules and the ORCHESTRATOR_NOTES (18:47). **No screen code was changed
in this stage.** **No simulator was booted, installed on, screenshot or
driven** (stage 5 only, and only `E7D5555E…`). No image was attached.

- New proofs: `app/test/features/kid_jar/k09_bugs_test.dart` — 12 tests:
  **9 run green**, **3 skipped** (`K09-BUG-4`, `K09-BUG-5`, `K09-BUG-6`; all
  open). Run them red with:
  `cd app && flutter test --timeout 120s --run-skipped test/features/kid_jar/k09_bugs_test.dart`
- `dart format` clean; `flutter analyze` → **No issues found!**
- Scope: only `app/test/features/kid_jar/k09_bugs_test.dart` and this file.
  No `app/lib/**`, no core, no another feature, no `tools/screens/**`.
- **Numbering continues the registry opened by stages 3–5**, which already
  own `K09-BUG-1`…`K09-BUG-3` (`3_test.md` §3). This stage adds
  `K09-BUG-4`…`K09-BUG-6`.

At the time of writing the feature suite is `+86 ~3 -5`: the 5 red tests are
stage 3's deliberate K09-BUG-1..3 proofs (`kid_jar_bloc_test.dart` ×2,
`my_jar_view_test.dart` ×3); the 3 skips are this file's proofs. The repo-wide
run therefore stays red until the fix stage lands.

## Bugs found by this stage

### K09-BUG-4 — a reached savings goal still asks the child for money (Major)

**Where:** `app/lib/features/kid_jar/presentation/widgets/jar_goal_card.dart:37`
(`int get remainingPence => targetPence - savedPence;`) plus
`app/lib/features/kid_jar/presentation/widgets/jar_amounts.dart:16`
(`jarPounds` applies `.abs()`).

**What:** once `savedPence > targetPence`, `remainingPence` is negative but
`jarPounds` drops the sign, so the card claims a **positive amount is still
missing** — while the same card clamps the progress to `100% there!`.

**Repro (the proof):** demo seed; goal saved 3150p of 2499p (a writer credited
past the target). `/my-jar` renders:

| element | app | should be |
|---|---|---|
| saved figure | `£31.50` | `£31.50` |
| progress caption | `100% there!` | `100% there!` |
| remainder | **`£6.51 to go`** | no positive remainder (`£0.00 to go`) |

The false figure **grows with every overshoot**. Reachable through the merged
P13 flow: `payout_view.dart` `_submit` clamps the savings move to the payout
amount but never to the goal's remainder, and
`pocket_money_repository_impl.dart` `recordPayout` then writes
`savedPence: goal.savedPence + movePence` unbounded. This feature's own
`moveToSavings` has the same blind spot. (Stage 4 filed the same defect as
`4_review.md` finding 2, rated minor there; this stage rates it **major**
because the wrong money figure is reachable today, persists, and contradicts
the card's own `100% there!`.)

**Failing test:** `K09-BUG-4: a reached goal never asks for more money`
(`Expected: empty / Actual: ['£6.51 to go']`).

**Suggested fix:** clamp in the card —
`int get remainingPence => targetPence > savedPence ? targetPence - savedPence : 0;`
— keep `.abs()` (stage 4 is right that a negative hero would break the
`£x.xx` contract), and cap savings moves at the remainder
(`moveToSavings`, P13's `recordPayout`) so the data cannot drift over target
in the first place.

### K09-BUG-5 — a negative owed is announced as positive money coming (Minor, latent)

**Where:** `kid_jar_repository_impl.dart:79-101` (`_summarize` sums signed
`weekly_base` + `quest_bonus` rows and can go below zero) plus `jarPounds`'s
`.abs()` on the hero (`my_jar_view.dart:185,218`).

**What:** the ledger is signed (`LedgerEntries.amountPence` — "Signed pence")
and the K09 list renders a negative row correctly as `−£5.00` (U+2212), but
the hero amount drops the sign: with a `−500p` correction in the current
period Maya is owed `−80p` and the screen says **`£0.80 coming on Saturday`**.

**Repro:** insert `quest_bonus` `−500, 'Correction'` for Maya (owed
420 − 500 = −80); the list shows `−£5.00`, the hero shows `£0.80`.

**Repro / failing test:** `K09-BUG-5: a negative owed is never shown as money
coming` (`Found 1 widget with text "£0.80"`).

**Suggested fix:** clamp the owed total at the repository —
`owedPence: max(0, base + quests)` (a child can never be "owed" a negative
amount; stage 4's "no negative hero" direction agrees) — or, if negative
balances must be visible, render them with U+2212 rather than `.abs()`.

No current screen writes a negative bonus, so this is a robustness defect,
not a flow the seed reaches.

### K09-BUG-6 — the scroll tail counts the home indicator twice (Minor)

**Where:** `app/lib/features/kid_jar/presentation/views/my_jar_view.dart:69`
(`SafeArea(top: false)` — bottom insets) **and** `:266-271`
(scroll tail `NestDevice.homeH + NestSpacing.s8`).

**What:** the design keeps the 34 px home indicator as a flex sibling *after*
the scroll (`.home-indicator`, `components.css:51`) whose own tail is just
`--s8` = 32 (`.scroll`, `components.css:65`) — total 66 above the edge. The
app's `SafeArea` consumes the same 34 px inset **and** the scroll tail adds
`34 + 32 = 66`, so at max scroll the last content sits 34 px higher than the
design. K08/K06 use the tail padding without a bottom `SafeArea`, which is
why the pattern arrived doubled here.

**Repro (the proof):** pump `/my-jar` with a real 34 px bottom inset
(`tester.view.padding` + `viewPadding`), scroll to the end: footer bottom
**744.0** vs the design's **778** (`810 − 32`), Δ 34.

**Failing test:** `K09-BUG-6: the footer keeps the design row at max scroll`
(`Expected: a numeric value within <2> of <778> / Actual: <744.0>`).

**Suggested fix:** drop `NestDevice.homeH` from the scroll's tail padding
(the design's own `.scroll` is `--s8`; `SafeArea` already reserves the inset)
or drop the bottom `SafeArea` and keep the tail — both land on 778.

**Context:** stage 3 logged this as Observation 1 and deliberately did not
file it (the design PNG is at scroll-top, so no screenshot shows it). This
stage keeps it as a minor finding with a proof so the registry does not lose
it; it clips nothing and moves no element of the initial frame.

## Open bugs inherited from stages 3–5 (cross-ref, not re-filed)

| id / source | what | severity | proof |
|---|---|---|---|
| `K09-BUG-1` (3_test §3.1) | retry stacks live `emit.forEach` subscriptions; a stale stream can overwrite the reloaded screen | minor | `kid_jar_bloc_test.dart` ×2, red |
| `K09-BUG-2` (3_test §3.2, ORCHESTRATOR_NOTES 18:47) | `coming on Saturday` painted `--ink-2`; the HTML inherits `--ink` (PNG-measured `#1E1B3A`/`#F3F0FA`) | minor | `my_jar_view_test.dart` ×2, red |
| `K09-BUG-3` (3_test §3.3, ORCHESTRATOR_NOTES 18:47) | every quest-bonus row shows one fixed glyph instead of `questIconFor(key, audience: kid)` | **major** | `my_jar_view_test.dart`, red |
| `5_ui.md` dev. 1–2 | row-1 and row-2 disc glyphs match neither the HTML inline SVGs nor the shared assets (`poundCoin` vs coin-slot mark; `questBins` vs the bins SVG); gift row unverified below the fold | major (UI verdict) | stage-5 crops |
| `4_review.md` findings 1–6 | `NestProgress` kid gloss spans the whole track (shared); over-saved "to go" (= this stage's `K09-BUG-4`); formatter split across layers; `watchJar` comment; `watchItems` contract change for K10; loading label not a live region | minor | review notes |
| ORCHESTRATOR_NOTES `shared/jar_glyphs` | `NestIcons.jarPocketMoney` / `jarGift` land on main; swap the two `jarEntryGlyph` branches when they do | blocked on main | stage-3 §1 item 2 |
| 2_build `LEFT FOR NEXT ITERATION` | failure-state art choice (`NestIcons.jar` vs `JarIllustration`) | cosmetic | build notes |

## Verified clean this stage (new probes)

| Category | Probe | Result |
|---|---|---|
| rapid double tap | back tapped twice in one frame after a `/kid-home` push | exactly one pop → `/kid-home` |
| rapid double tap | lock tapped twice in one frame | exactly one `/parental-gate` push (one pop returns to `/my-jar`) |
| data edge | active child Maya → Leo while the screen is open | atomic swap: `£2.10`, Maya's `£4.20` gone, no goal card (one snapshot) |
| async gap | dispose the screen mid-load, then write to the DB | no emit-after-close, no exception |
| data edge | goal title `Maximilian-Alexander’s Nintendo Switch 2 game`, saved `£9,999,999.99` of `£19,999,999.99` at **320 px × 1.3** | no overflow, no exception |
| data edge | `Seed.empty` deep link (0 children): `£0.00`, empty row, no goal card | renders, no exception (stage 3 also covers) |
| data edge | 1 child (demo) / 2 children (Maya→Leo switch); 6 children, long UK child names, 9999 coins | N/A on K09 — the screen lists no children and shows no child name or coins, only the active child's jar; the child-switch probe above is the only relevant shape |
| data edge | `£0.00` / pence thresholds (`+12p` vs `+£1.00`) / huge amounts | exact integer formats |
| money rounding | `jarPounds` 0…300,000p vs integer arithmetic + `formatJarAmount` thresholds | 0 mismatches |
| timezone / BST | rows at the London week boundary either side of the 25 Oct 2026 fall-back | `This Monday` / `Last Sunday` correct in both BST and GMT |
| persistence | file DB: seed, `moveToSavings(100)`, close, reopen | owed 420, saved 1650, 9 rows intact |
| dark contrast | 11 K09 text pairs × light/dark, WCAG formula | all ≥ 4.5:1 (min 5.92 dark `ink-2`/meadow; title 12.9/13.5) |
| mode guard | parent-mode `/my-jar` deep link; kid-mode `/my-jar` | parent-mode kid deep link is the accepted K02 convention; kid→parent-only remains router-guarded (no K09 bypass) |
| re-emission | a money-in write while the jar is open (existing tests) | list + owed move together (atomic snapshot) |

Not re-probed here because stages 3–5 already own them with evidence: copy
parity, geometry (±2 px), semantics labels, tap-target sizes, the loading /
failure / retry frames, the empty seed, and the two icon deviations.

## Summary

| id | severity | status |
|---|---|---|
| K09-BUG-1 | minor | open — stage 3's red proofs |
| K09-BUG-2 | minor | open — stage 3's red proofs |
| K09-BUG-3 | **major** | open — stage 3's red proof (mandatory note) |
| **K09-BUG-4** | **major** | **open — proof skipped in `k09_bugs_test.dart`** |
| K09-BUG-5 | minor (latent) | open — proof skipped |
| K09-BUG-6 | minor | open — proof skipped |
| 5_ui deviations 1–2 | major (UI) | open — glyph transcriptions |

The screen cannot pass: it still tells a child who has reached their goal that
money is missing (`K09-BUG-4`), the orchestrator-mandated glyph and ink fixes
have not landed yet (`K09-BUG-1..3`), and the UI check fails on the two
visible row glyphs. The three proofs added here are parked with `skip:` (per
this stage's brief) so the suite stays green apart from the deliberately red
stage-3 proofs; they go green without edits once the fixes land.

