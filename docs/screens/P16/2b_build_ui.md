# P16 Settings — 2b build, UI chunk (iteration 6)

Scope: `app/lib/features/settings/presentation/views/**` +
`presentation/widgets/**`, widget/view tests, and every **UI/layout/copy** item
in `FIXES_5.md`. `main` is merged into this branch (`HEAD..main` = 0), so
`nestAvatarInitial` is now in the worktree — the iteration-5 blocker on P16-T04
is gone.

## CONTRACT CHANGES (from 2a, re-read before finishing)

`2a_build_logic.md` reports one additive change: `SettingsRepositoryImpl` takes
an optional `FamilyZoneService? zoneService` (defaults to a local instance).
No state/event/entity/interface shape changed, so nothing in the view layer had
to move. Verified by compiling and running the whole settings suite against
their tree, not by reading.

## FIXES_5 triage — what I own and what landed

| item | severity | outcome |
|---|---|---|
| **P16-T04** (from 3_test) | minor | **FIXED** — both call sites now call the shared `nestAvatarInitial`; proof **un-skipped** and green |
| **Review 1** — avatar initials re-implemented | **major** | **FIXED** — same change as P16-T04 (they are the same defect seen from two stages) |
| **Review 2** — the guard silently swallows switch flips | **major** | **FIXED** — `P16TransientGuard.run` removed from all three `NestToggle.onChanged`; row fences kept; **SHARED_REQUEST §8** filed |
| **Review 3** — "Manage subscription" paints no ripple | minor | **FIXED** — the link row supplies its own ink surface; **§3's status line corrected** (it was the wrong claim that let this ship) |
| **Review 4** — `.chip` label reused as hint body copy | minor | **FIXED as far as a screen can** — one documented `settingsHintStyle()` instead of two hand-cancelled chip labels; **SHARED_REQUEST §9** filed for a real `NestType.hint` |
| Review 5 — `watchMembers` duplicates the shared query | minor | logic chunk — **done by 2a** |
| Review 6 — repository builds its own `FamilyZoneService` | minor | logic chunk — **done by 2a** |
| Review 7 — legacy `SettingsItem` / `watchItems()` | minor | **not mine** (domain/data); 2a re-verified the shared `repositories_test` still calls them |
| Review 8 — `_linkRowMinHeight` / `SettingsRow` metrics | minor | filed as §6/§7 already; **no action**, deliberately not re-reported |
| 3_test obs 2 (Family list announces as one node) | observation | shared `NestListRow`'s no-`onTap` branch; a local label broke the tappable-node contract, so still not a screen fix |
| 3_test obs 4 (`.ptitle` has no `text-wrap: balance`) | observation | plain `Text` + `NestType.h1` is correct as the CSS is written — unchanged |
| 3_test obs 5/6 | observation | 300 ms fence is defensible; dialog Cancel wrap is shared `NestButton` padding |

### 1. P16-T04 / review finding 1 — shared `nestAvatarInitial` (2 lines)

`_MemberRow` and `_ChildRow` each hand-rolled `name.isEmpty ? '?' :
name.characters.first.toUpperCase()`. Both now pass
`nestAvatarInitial(member.name)` / `nestAvatarInitial(child.nickname)` straight
into `NestAvatar`. The helper trims first and owns the `'?'` fallback, so
`' Maya'` renders `M` and `'   '` renders `?` instead of a blank avatar. It also
removes the last undeclared use of `package:characters` in this feature (it
resolved only as a transitive Flutter dep; `main` declares it now).

`settings_a11y_test.dart` `[P16-T04]` flips `skip: true → skip: false` and its
comment is rewritten from "OPEN BUG … not fixable in this worktree" to what the
code now does. The expectation stays computed **independently** of the helper
(hand-written trim + first grapheme), so the proof still fails if the screen's
behaviour drifts rather than agreeing with itself.

### 2. Review finding 2 — the switches are no longer fenced

Three `NestToggle.onChanged` callbacks wrapped their write in
`P16TransientGuard.run`, and the window is armed by any sheet/modal close.
Notifications sits **immediately below** the zone picker sheet, so the natural
sequence (open picker → pick a zone → tap a switch) put the user's very next tap
inside the 300 ms window: the switch did not move and gave no feedback. A
switch flip cannot re-trigger itself, so the double-tap fall-through the guard
exists for (P16-B08/B10) can never apply to it — the same reasoning that
already exempted the move banner's buttons (and the file's own comment at
`p16_transient_guard_test.dart:181` said exactly this, applied to the banner but
never to the toggles).

Three `P16TransientGuard.run(` wrappers deleted; the guard itself stays for the
rows that *do* open a modal or route, which is what `SHARED_REQUEST.md` **§8**
(new) now asks the orchestrator to fix once at the source.

### 3. Review finding 3 — the subscription link row's ink surface

`NestCard`'s `Material` only exists on its **tappable** branch
(`nest_card.dart:88-98`). This card is not tappable as a card — the design's
`.linkrow` is a link *inside* it — so it took the plain `Container` branch, which
carries no `Material`, and the nested `InkWell` resolved its ink to the
Scaffold's `Material`, i.e. **behind** the card's opaque `surface`: zero press
feedback. `SHARED_REQUEST.md` §3 and iteration 5's `2b_build_ui.md` both
claimed the opposite, and that wrong claim is why the defect survived the
un-fork; both are corrected.

Fixed screen-side with `Material(color: Colors.transparent, child: InkWell(…))`
— the same ink surface `NestListRow` and `SettingsRow` already give every other
row. **Geometry-neutral**: a `Material` wrapper adds no padding and no height, so
the subcard rects the UI stage measured (593.0 top / 712.7 bottom) are untouched.

### 4. Review finding 4 — `.lockhint` copy is one token-shaped call site

The lock hint and the move banner both rendered `.lockhint` copy
(`.lockhint { font-size:14px; line-height:20px }`) as
`NestType.chipLabel(…).copyWith(fontWeight: w400)` — the right line box from the
wrong token. The numbers are unchanged, but a chip-label weight/tracking change
would silently move hint text on two screens. The literal now lives once, in
`settingsHintStyle(context)` in `settings_rows.dart`, documented with its CSS
line; **SHARED_REQUEST.md §9** (new) asks for a proper `NestType.hint` so even
that one goes away.

## Tests (2 new, 1 un-skipped) — and proof they are not vacuous

Both new proofs were run against the **pre-fix** source to confirm they fail:

```
# with the switch re-fenced and the Material removed:
[review 2] all three switches still flip while the guard is armed
    Expected: <false>   Actual: <true>
[review 3] "Manage subscription" paints its ripple on the card, not behind it
    Expected: non-empty   Actual: WhereIterable<Widget>:[]
```

- `[review 2]` arms the guard fresh per switch (pumping between taps would
  expire the first window and prove nothing), asserts `suppressing` is **true**
  before *and* after the tap, and reads the `settings` row — not the optimistic
  widget — so a swallowed tap fails on the database.
- `[review 3]` intersects the link row's `Material` ancestors with the
  `Material`s **inside** the `NestCard`. Ancestors alone would be satisfied by
  the Scaffold's `Material`, which is precisely the defect being pinned.
- `[P16-T04]` is live again: `flutter test test/features/settings --run-skipped`
  now selects no test in this feature.

## Verification

```
dart format lib/features/settings test/features/settings   → 0 changed
flutter analyze lib/features/settings test/features/settings → No issues found!
flutter test --timeout 120s test/features/settings          → +145: All tests passed!
flutter test --timeout 120s test/features/settings --run-skipped → no test selected
```

+145 passed, **0 skipped** (iteration 5: +141 with 1 skip) — 2 new proofs, 1
un-skipped, +3 from the logic builder's `settings_repository_test.dart` work.
No simulator booted, installed on, screenshotted or driven; no whole-app
`flutter test`; no `flutter clean`.

## Layout and copy: unchanged, deliberately

No geometry moved. The three fixes are an expression swap (avatar initials), a
wrapper removal (three `P16TransientGuard.run(`), a zero-cost `Material`
wrapper, and a style call with identical metrics — so the y positions, 20 px
gutters, row heights and the subcard's 16 px radius / 14×16 padding the iteration-5
UI stage measured still stand. Copy is still character-exact against
`P16-settings.html` (`Family & settings`, `Sarah — you`, `Invited · awaiting
reply`, `Maya · 7–9`, `Pip: Fledgling · 120 coins`,
`Nestling Annual · £29.99/year`, `Kid mode needs parent gate — On`, `›`), the
live `Looks like you’re in …` banner keeps its curly apostrophe, and the
DB-driven e-mail still comes from `members.email`.

## Files changed (mine only)

- `app/lib/features/settings/presentation/views/settings_view.dart`
- `app/lib/features/settings/presentation/widgets/settings_rows.dart`
- `app/test/features/settings/settings_view_test.dart` (+2 proofs)
- `app/test/features/settings/settings_a11y_test.dart` — **un-skip `[P16-T04]`**
- `docs/screens/P16/SHARED_REQUEST.md` (§3 corrected, §8 + §9 new, status block)
- `docs/screens/P16/2b_build_ui.md` (this file)

One note for the integrator: `dart format lib/features/settings` (the repo's own
formatter, run per RULES §7) also normalised
`data/settings_repository_impl.dart` while the logic builder was writing it. That
is whitespace only, on their file, and `flutter analyze` is clean.

## LEFT FOR NEXT ITERATION

1. **`SettingsRow` still exists for five rows** (four avatar-leading + the
   danger row) — needs **SHARED_REQUEST §6** (`NestListRow.leading` widget +
   danger `titleColor`/`titleStyle`). One shared change, then delete the widget
   and its five call sites. Not re-doable screen-side.
2. **`_linkRowMinHeight = 52`** — **§7**; moves to a token when the grid grows
   one.
3. **`settingsHintStyle()`** — **§9**; becomes `NestType.hint` when it lands.
   One documented literal, deliberately not two, and the review explicitly
   warned against re-landing it silently elsewhere.
4. **`P16TransientGuard` itself** — **§8**; needs the shared modal/sheet fence.
   Its process-wide static lifetime (review 6) is unchanged and still the only
   shared-behaviour workaround left in this feature.
5. **The UI stage (5) must re-measure** and re-issue `cmp_*_6.png`. The three
   fixes are geometry-neutral by construction and the layout is otherwise
   untouched, but the ±2 px verdict has to be re-earned on the new tree. The
   known open deviation is the subcard bottom edge at +2.0 px (at tolerance,
   tracked, invisible side-by-side).
6. **Not this chunk:** review finding 7 (dead `SettingsItem` / `watchItems()` /
   `getItems()`) stays with the logic layer until the shared
   `test/core/data/repositories_test.dart` settings group stops calling it.

VERDICT: PASS