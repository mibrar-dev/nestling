# K02 Kid PIN — QA code review (Stage 4, iteration 2)

Scope: feature `kid_home`, route `/kid-pin`, kid mode, designs
`design/screens/{light,dark}/K02-pin.png` (1170×2532 @3x). Reviewed
`git diff main...HEAD` (4 lib files, 5 test files, `docs/screens/K02/**`) against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K02,
`docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, `1_plan.md`, `ORCHESTRATOR_NOTES.md` (07:13 keypad
mandate), `SHARED_REQUEST.md`, and the stage notes 1→6 of both iterations.

**This stage edited no product code** — only this file. **No simulator was booted,
installed on, screenshot or driven** (SIMULATORS rule: only stage 5 may).

## Gates (run in `app/`)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none .` | ✅ `Formatted 524 files (0 changed)` |
| analyze | `flutter analyze` | ✅ **No issues found!** (whole package, tests included) |
| test (whole app) | `flutter test` | ✅ **`+2978 ~2: All tests passed!`** |
| suppressed | `grep skip:` / `ignore_for_file` / `// ignore:` in the 5 K02 test files | ✅ none — the only skip in the feature is the pre-existing K01-BUG-7 park at `k01_bugs_test.dart:569`, which the diff does not touch |
| analysis_options | `git diff main...HEAD --name-only` | ✅ untouched, not weakened |
| fonts | `grep google_fonts\|GoogleFonts lib/features/kid_home test/features/kid_home` | ✅ none in code (two assertions in `kid_pin_view_test.dart:1163-1164` *check* for their absence) |
| scope | `git diff main...HEAD --name-only` | ✅ only `app/lib/features/kid_home/presentation/{bloc,views}`, `app/test/features/kid_home/**`, `docs/screens/K02/**` — no `core/`, no `app/`, no other feature, no `tools/screens/` |

**Load note (honest scope of the gates).** This stage ran while several other
screen loops were running their own `flutter test` suites on the same machine, and
a sibling K02 stage added uncommitted test work to the working tree during the
review (`kid_pin_view_test.dart` +222 lines appended after line 1234, plus
`5_ui.md` and an untracked `zz_k02_scratch2_test.dart` scratch probe — none of it
in `git diff main...HEAD`, and per the loop's own rule an untracked sibling scratch
file is a process item, not a K02 finding). Consequences, stated plainly:

* The **whole-app** `flutter test` above did complete green (`+2978 ~2`) and is
  the test evidence this review relies on; it includes every
  `test/features/kid_home` test, the K02 ones among them.
* `flutter analyze` was **re-run after** the sibling edit, on the current working
  tree (uncommitted tests included): still **No issues found!**
* A feature-only re-run (`flutter test test/features/kid_home`) was attempted
  twice and could not finish inside 15 and then 25 minutes — the box was running
  four or five sibling suites at once (`P17`, `quests`, `shared_batch6`, and
  another K02 test stage), so it was starved rather than hanging. It is therefore
  **not** reported as a result, in either direction.
* The line numbers cited in this review are the current working tree's, and none
  of them falls in the region the sibling edit appended.

## Independently verified (measured/re-read, not taken on trust)

* **RULES §1 scope** — every path in the diff is on the allow-list. Nothing in
  `app/lib/core/**`, `app/lib/app/**`, `tools/screens/**` or another feature.
* **RULES §2** — `SHARED_REQUEST.md` now exists with three items, and every
  `TODO(K02)`/`NOTE(K02)` in the code cites it (`kid_pin_view.dart:233`, `:254`,
  `:279`). Status accuracy is finding 6 below.
* **ARCHITECTURE** — feature-first intact: `domain/` and `data/` untouched
  (`KidHomeRepository.verifyPin` already existed, `kid_home_repository_impl.dart:122`),
  no new repo method, no DI/schema/seed change, routes untouched. One bloc per
  feature, one view per route (`KidPinView` for `/kid-pin`). The three new state
  fields are purely additive and threaded through **every** constructor plus
  `props` (`kid_home_state.dart:71`, `:76`, `:81`, `:305-307`) — no rename, so
  the sibling K01/K03/K04/K05 screens in the same feature cannot break.
* **The check is the bloc's, the entry is the view's** — `_onKey`
  (`kid_pin_view.dart:38-55`) owns digit accumulation only; the verdict is
  `KidHomePinSubmitted` → `_onPinSubmitted` (`kid_home_bloc.dart:258-287`).
  Navigation stays in `BlocListener`s; the bloc emits no route pushes.
* **DATA OVER MOCKS** — `Hi $nickname!` and the avatar initial both come from
  the child's row; nothing from the design PNG is pasted in. `1234` is a
  database fact pinned by `kid_home_repository_test.dart` (`verifyPin('maya','1234')`).
  No `£`, no coins, no money of any kind on a kid screen.
* **Geometry re-derived by hand from the code** (no simulator): 47 status →
  47–103 top bar (+6) → 109 → avatar 128 → 237 → +20 → 257 pill (16/22 + 2+2)
  → 283 → +2 → 285 say (20/26) → 311 → +20 → 331 dots (8+18+8) → 365 → +20 →
  keypad +8 → 393 / 475 / 557 / 639 (72 keys, 10 pitch) → 711 → +20 → 731 caption
  (15/20) → 751 → +32 scroll pad → transparent inset spacer. Horizontal: dots
  4×18 + 3×12 = 108 → x 141–249; keypad `contentWidth` 284 (3×72 + 2×10 + 2×24)
  centred → keys x 77–313. Every value lands exactly on the `1_plan.md` anchors
  and inside the ±2 px rule, with 20 px gutters throughout (ALIGNMENT owner rule).
* **ORCHESTRATOR_NOTES (07:13), keypad** — honoured: `main`'s grid pitch now
  governs, and K02 opts in with `fit: NestKeypadFit.shrinkWrap`
  (`kid_pin_view.dart:287`) instead of re-spacing keys locally.
* **COPY, character-by-character vs `K02-pin.html`** — `NESTLING`,
  `Hi {nickname}! Enter your secret code` (no trailing period), `Forgot it? Just
  ask a grown-up.`, `aria-label` `Back` / `Grown-ups` / `Delete`. All ASCII, UK
  spelling, and `kid_pin_view_test.dart:1174-1218` parses the HTML source file
  and asserts the rendered strings byte-for-byte, plus that the source carries
  no error copy (so the app-only toast can never be mistaken for design copy).
* **LETTER SPACING** — only `.mark` tracks, `1.28` at the call site
  (`kid_pin_view.dart:241`); the greeting pins `0`. A test sweeps the whole
  visible `Text` tree and asserts the set of tracking values is exactly
  `{0, 1.28}` (`kid_pin_view_test.dart:1295-1312`).
* **BALANCED HEADINGS / CHIP ROWS** — K02's CSS has no `text-wrap: balance` and
  the screen has no chip row; `NestBalancedText`/`NestChipWrap` correctly absent.
* **KID BACKGROUND / BOTTOM EDGE** — all four states (body, loading, failure,
  no-child) wrap in the shared `KidScope` with default 136 px meadow at bottom 0;
  no local hills anywhere. No bar on this screen, and the trailing spacer
  (`kid_pin_view.dart:300`) paints nothing, so the meadow runs to the physical
  edge (no coloured strip under the home indicator).
* **SHAPES, not only text** — `kid_pin_view_test.dart:971-1043` pins the pill's
  `lilacTint` background + pill radius + 26 height, and every one of the 11 key
  discs as a 72 circle with the kid ink border; `:1089-1129` pins filled/empty dot
  tones and the disc tint per theme. This closes iteration-1 finding 3.
* **ACCESSIBILITY ACTIONS** — every control advertises `SemanticsAction.tap`
  (`Digit 0-9`, `Delete`, `Back`, `Grown-ups`), the dots node deliberately has
  none, and `performAction(tap)` drives real state (a digit moves the label to
  `1 of 4 entered`; Back by VoiceOver lands on `/who-is-playing`). The only
  `excludeSemantics` wrap is the non-interactive awaiting dots label, so no
  `onTap` is owed there. Tap targets: keys 72, back/lock 56 ≥ kid 56 minimum.
* **Error handling** — a `verifyPin` throw maps to the wrong-code path (list
  stays usable, no failure card); a stream error only becomes a card when there
  is no child (`kid_home_bloc.dart:225`, `:142`), so the raw `error.toString()`
  in `errorMessage` can never reach a child — the view renders fixed copy only.
* **Lifecycle / streams** — the bloc still owns exactly the two long-lived
  subscriptions (K01's, untouched); K02 adds no subscription and `close()`
  cancels both. The handler builds its outcome from `state` at completion time,
  so an interleaved home emission cannot swallow a pending verdict (two pinned
  bloc tests), and re-entry is dropped by `state.pinChecking`.
* **Performance** — one `BlocBuilder` + three `listenWhen`-narrow listeners;
  `_entered` is a ≤4-item local list, so keypad taps never round-trip a stream;
  the keypad subtree is shared/stateless; no `Timer`/`AnimationController`.
* **Children's Code** — no analytics, ads, network or identifiers; no
  `print`/`debugPrint`; no `DateTime.now()` anywhere in the feature; unlimited
  retries, no lockout, no shaming copy, gate reachable from every state.
* **Iteration-1 findings all genuinely closed**: SHARED_REQUEST file exists;
  the 4th digit reverts when `child == null` (`:43-49`); pill/key shapes are
  pinned; `_BottomInset` honours the real inset with a 34 floor (`:315-327`).
  The four `K02-BUG-*` proofs are now un-skipped and assert the fixed behaviour
  (`k02_bugs_test.dart:327-424`).

## Findings

### 1. [minor] The `.mark` pill hard-codes `999` instead of `NestRadii.allPill`

`app/lib/features/kid_home/presentation/views/kid_pin_view.dart:229`

```dart
borderRadius: BorderRadius.circular(999),
```

`NestRadii.pill = 999` and `NestRadii.allPill` exist
(`app/lib/core/design_system/tokens/radii.dart:13`, `:23`), and this is the
**only** `circular(999)` left in `lib/` — every other pill in the app
(`nest_coin_pill`, `nest_segmented`, `nest_fab`, `nest_badge_count`,
`nest_bottom_sheet`, …) uses `NestRadii.allPill`. Breaks the "tokens only" rule
and creates a one-off local copy of a shared token.

**Fix:** `borderRadius: NestRadii.allPill,`. Then update the five test
predicates that mirror the literal to the token, or they will fail:
`kid_pin_view_test.dart:938`, `:989`, `:1012`, `:1057` (finders) and `:998`
(the `decoration.borderRadius` assertion) → compare against `NestRadii.allPill`.

### 2. [minor] `_noPinHandled` is a widget-lifetime latch, so a later no-PIN child spins forever

`app/lib/features/kid_home/presentation/views/kid_pin_view.dart:36`, `:71-83`,
with the builder branch at `:116-120`

The no-PIN listener sets `_noPinHandled = true` **before** the post-frame
re-check that K02-BUG-3's fix added, and never clears it. Two branches must stay
in sync — the listener navigates, the builder renders `_KidLoading` "auto-advance
is scheduled by the listener above" — and the latch breaks that sync:

1. a no-PIN child (Leo) is emitted, and within the same frame a PIN'd child
   (Maya) replaces it → the post-frame re-check declines (correct), but the latch
   is now spent;
2. the stream later emits a no-PIN child again → `listenWhen` fires, the listener
   returns at `:72`, and the builder at `:116-120` renders `_KidLoading` with no
   navigation scheduled: **a permanent spinner** with only Back and the gate
   available.

Same reachability class as K02-BUG-3 (a latent active-child swap mid-frame, no
shipped flow does it today — hence minor, not major), but the fix for BUG-3 is
what introduced the latch, so it should not ship as-is.

**Fix:** make the guard about the *in-flight hop*, not the widget lifetime — set
it when scheduling, clear it in the callback, and navigate only if the child is
still no-PIN:

```dart
void listener(...) {
  if (_noPinScheduled) return;
  _noPinScheduled = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _noPinScheduled = false;
    if (!mounted) return;
    final child = context.read<KidHomeBloc>().state.child;
    if (child != null && !child.pinSet) context.go(KidHomeRoutePaths.home);
  });
}
```

A repeated emission for the same no-PIN child then re-schedules harmlessly
(the first hop already navigated away), and the Maya→Leo path recovers. Add a
regression test to `k02_bugs_test.dart` beside K02-BUG-3: emit Leo, then Maya,
then Leo again in three turns; the third emission must land on `/kid-home`.

### 3. [minor] Keys stay live while a check is in flight — ripple and a semantics tap that do nothing

`app/lib/features/kid_home/presentation/views/kid_pin_view.dart:38-39`
(`if (_awaiting || …) return;`), call site `:283-288`

`awaiting` only reaches the dots. `NestKeypad`'s keys wrap an `InkWell(onTap: …)`,
so during the check a tap still paints a key press and `Semantics(button: true,
onTap: …)` still advertises an action that resolves to an early `return` in
`_onKey`. RULES §8 says a disabled control "passes no tap and reports
`enabled: false`". The window is one local Drift read (milliseconds) and
`1_plan.md` §(c) consciously chose the callback-guard approach, so this is minor —
but the visible ripple is a lie the child can see.

**Fix:** `AbsorbPointer(absorbing: awaiting, child: NestKeypad(…))` at the call
site — one line, kills the ripple and hit-testing without touching `core/`. For
semantics honesty add a `NestKeypad(enabled: …)` flag to
`SHARED_REQUEST.md` (mirroring `NestIconButton`, which already renders
`enabled: onPressed != null`), and have `_Key` pass `onTap: null` +
`enabled: false` when disabled; K02 then passes `enabled: !awaiting`.

### 4. [minor] The 128 px avatar disc is an inline literal

`app/lib/features/kid_home/presentation/views/kid_pin_view.dart:207-208`

`width: 128, height: 128` is `.k2-ava`'s size and the only bare dimension left
in the view (everything else goes through `NestSpacing` / `NestDevice` /
`NestAvatarSize`), but two unexplained magic numbers inside the tree are exactly
what the tokens rule is guarding against, and the tests then pin `128` again
(`kid_pin_view_test.dart:208-209`).

**Fix:** hoist it to one named constant carrying its provenance, e.g.
`static const double _avatarDisc = 128; // .k2-ava (K02-pin.html:22)` on
`_KidPinBody`, and use it for `width`/`height`; the geometry test can then keep
asserting the literal `128` against the *design* rather than against an anonymous
inline number. If another screen needs the same tinted disc, request a
`NestDevice`-style token in `SHARED_REQUEST.md` instead.

### 5. [minor] `k02_bugs_test.dart`'s header still says the four proofs are parked

`app/test/features/kid_home/k02_bugs_test.dart:3-10`

"Four proofs in this file FAIL against the current build. They are parked with
`skip: true` …" — none of them is skipped any more; they run in the plain suite
and now assert the *fixed* behaviour (`:327-424`). A future stage reading only
the header would either re-park passing tests or duplicate the work.

**Fix:** rewrite the header to state that the four `K02-BUG-*` tests are live
regression proofs for the iteration-2 fixes (`runes` initial, `maxLines: 3`,
post-frame child re-check, `hideCurrentSnackBar`), and that no `skip: true`
remains in this file.

### 6. [minor] `SHARED_REQUEST.md`'s status line is stale, and item #2's follow-ups are done

`docs/screens/K02/SHARED_REQUEST.md:9-11` still reads "**#2 landed on `main`,
K02 follow-up pending**" with a three-step "Remaining K02 follow-up" list
(`:62-72`) whose steps have all happened: `main` is merged here
(`c094fd5`), the call site passes `fit: NestKeypadFit.shrinkWrap`
(`kid_pin_view.dart:287`), and `5_ui.md` (iteration 2) re-measured the grid at
x 77–313 with Δ 0 and passed. Item #3's call-site table
(`:98-103`) also points at `kid_pin_view.dart:140`, which moved to `:156-158`
when the `runes` fix landed.

**Fix:** set the status line to "**#1 and #3 open, #2 done** (merged `c094fd5`;
call site uses `NestKeypadFit.shrinkWrap`; `5_ui.md` iteration 2 measured Δ 0)",
replace #2's follow-up list with its outcome, and refresh #3's line numbers
(`kid_pin_view.dart:156-158`; the other six sites unchanged).

## Carried, shared-owned, deliberately NOT counted against K02

* **The two local type styles** (`kid_pin_view.dart:236-242` mark, `:256-263`
  say) hard-code `fontFamily: 'Nunito'` + weight + size + line-height. K02
  cannot fix this: `NestType.kidMark` / `kidSay` do not exist and `core/` is
  off-limits (RULES §1). The metrics are exact, the tracking is correctly applied
  at the call site, both sites carry `TODO(K02)`, and item #1 of
  `SHARED_REQUEST.md` is the fix. Rendered pixels are already correct
  (`5_ui` measured Δ 0). **When #1 lands:** delete both local `TextStyle`s and
  both TODOs, use `NestType.kidMark(color: tokens.ink).copyWith(letterSpacing:
  1.28)` for the pill and `NestType.kidSay(color: tokens.ink)` for the greeting.
  The test at `kid_pin_view_test.dart:1295-1312` keeps guarding both.
* **K02-BUG-1's class** (non-BMP nickname initial) is only closed *for this
  screen* (`nickname.runes.first`, `:156-158` — no longer throws). The other six
  call sites listed in `SHARED_REQUEST.md` #3 still use `[0]`. Shared, filed.
* **The failure card's Pip** (`PipAvatar(style: mochi, stage: 1, size: 140)`,
  `:426-430`) cannot be the child's own Pip: the bloc only enters `failure` when
  `state.child == null` (`kid_home_bloc.dart:225`, `:142`), so no child row
  exists to read the look from. Same fallback shape as K03, and no
  `pip_stage_*.svg` anywhere (PIP rule satisfied as far as it can be here).
* **The advisory nature of the PIN** — `verifyPin` only gates this route's
  navigation; `/kid-home` itself carries no guard, so the PIN is a soft,
  sibling-resisted gate rather than a lock. That is the foundation's routing
  design (RULES §3; P17 is the real gate) and K02's diff adds no route, so it is
  recorded for the orchestrator, not counted here.
* **The pre-existing bloc-lifetime quirk** — every kid route does
  `BlocProvider(create: (_) => GetIt.instance<KidHomeBloc>())` over the same DI
  singleton, so popping one kid route can close the bloc under another. Routes
  are foundation code; K02 adds no new instance.
* **Iteration-1 stage notes** (`3_test.md`, `5_ui.md`, `6_bugs.md`, `FIXES_1.md`)
  are superseded where they conflict with this file: `5_ui.md` is already the
  iteration-2 PASS, and `k02_bugs_test.dart`'s four proofs are no longer skipped.

## Verdict

No blocker and no major finding. Scope is clean against RULES §1, the
architecture is intact (domain/data/DI/routes untouched, additive bloc fields
threaded through every constructor so the sibling `kid_home` screens cannot
break), the design system is reused throughout with no re-implemented component,
copy is byte-exact against the HTML source, the geometry re-derives to the
design anchors on the nose, accessibility actions drive real state, error paths
never surface raw exceptions to a child, and every gate is green
(`dart format` clean, `flutter analyze` **No issues found!**, `flutter test`
**+2978 ~2: All tests passed!**, no skips or ignores added, no `google_fonts`).
The Children's Code posture is right: no analytics, no ads, no network, no clock
reads, no `£`, unlimited kind retries, gate reachable from every state.

The six findings above are all minor: two are one-line token fixes (`999` →
`NestRadii.allPill`, `128` → named constant), two are narrow state-machine /
dead-control hardenings on paths this stage could not reach through any shipped
flow, and two are documentation accuracy in files the rules require to be
trustworthy. None blocks the screen; all should be swept by the FIXES iteration.

VERDICT: PASS
