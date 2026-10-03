# Fix list after iteration 4

## From 4_review.md
# K03 Kid home — QA code review (Stage 4, iteration 4)

Scope: `kid_home` / `/kid-home`, kid mode. Reviewed `git diff main...HEAD`
(committed) **plus** the current working tree, so the verdict reflects the
code as it stands. Per the orchestrator rule, uncommitted work / merge state
are **not** findings and are not reported.

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → 349 files, 0 changed.
- `flutter analyze` → **No issues found!** (no ignores, `analysis_options.yaml` untouched).
- `flutter test` → **`+476 ~1: All tests passed!`** (1 conditional skip, finding 10).
- RULES §1: only `app/lib/features/kid_home/**`, `app/test/features/kid_home/**`,
  `docs/screens/K03/**` are touched. No `core/`, no `app/`, no other feature,
  no `tools/`. ✅
- Bottom edge (owner rule): fixed and verified — `kid_home_view.dart:471-478`
  puts the dock's surface `Container` **outside** `SafeArea(top: false)`, so
  the inset is painted with the bar's own colour; `ui/app_dark_6.png` reads
  `(31,28,46)` at x=5/195/1165 from y=716 to the physical edge y=843 (no
  meadow strip), and 4 new tests assert `left 0 / right 390 / bottom 844` in
  both themes. ✅
- Mandates: PIP identity — no `pip_stage_*.svg` anywhere in the feature
  (`PipAvatar` in the pet slot, empty and failure states); PERIODS ruling —
  `countsForCurrentPeriod` applied in `kid_home_repository_impl.dart:40`
  (status) and `:118` (write guard), day-boundary proof un-skipped and green;
  coins only, no `£`; UK spelling ("Mum", "colour"-class words, curly
  apostrophes) ✅.
- ARCHITECTURE: domain stays entities + abstract repository; one bloc per
  feature (`KidHomeBloc`, one file, `emit.forEach` streams, no re-add load
  events); routes/DI untouched and still per feature. ✅
- Children's Code: no analytics/ads/SDK/network calls, no child identifiers
  beyond nickname/coins/Pip look, no location/chat, parental gate reachable
  from the loaded home. ✅

## Findings

### 1. [major] Design-system components re-implemented in the feature view, with no SHARED_REQUEST / TODO trail
`kid_home_view.dart:593-639` (`_KidPetStage`), `:643-689` (`_SpeechBubble`),
`:691-720` (`_TailPainter`), `:728-746` (`_HeartIcon`), `:748-777`
(`_HeartPainter`), `:792-815` (`_MeadowPainter`).

- `_SpeechBubble`/`_TailPainter` are a line-for-line fork of the shared
  `_SpeechBubble`/`_TailPainter` in
  `app/lib/core/design_system/components/nest_pet_stage.dart:169` and `:217`
  (same `maxWidth 260`, `r18`, `gap14`/`s2` padding, 3 px border,
  Nunito 16/24 w800, `Size(18, 10)` tail, identical tail path), and
  `_KidPetStage` re-does the nest+Pip scene that `NestPetStage:19`/`_PetScene:87`
  already owns.
- `_HeartIcon`/`_HeartPainter` copy the 24-space heart path out of the shared
  `assets/icons/ic_heart.svg` / `ic_heart_outline.svg` (`NestIcons.heart` /
  `heartOutline`, `nest_icon.dart:65-66`) because the asset bakes fill and
  stroke into one `currentColor`. Icon updates will not propagate.
- `_MeadowPainter` draws a second, in-flow hill while `KidScope`
  (`kid_scope.dart:47-58`) already owns the meadow art (token colour is
  correct now — `tokens.kidHorizon` — but the geometry is screen-local).

RULES §2 says shared work goes in `SHARED_REQUEST.md` and that a screen may
build "against the foundation as-is behind a `TODO(<ID>)` comment".
`SHARED_REQUEST.md` has 5 items (tile tint, stale copy, router guard,
periods ruling, motion flag) and covers none of these; there is no
`TODO(K03)` marker anywhere. The PIP mandate does genuinely block
`NestPetStage` (its fallback is the forbidden v1 art), so a local composition
is defensible — it just has to be *claimed* so the orchestrator can land the
shared fix once instead of per screen (K06/K07 need the same slot).

Fix (cheapest, keeps the visuals): add to `SHARED_REQUEST.md` —
(a) `NestPetStage` gains `style` / `skin` / `accessory` (or a
`PipAvatar`-backed mode) + `pipSize`; (b) a two-tone heart asset or
`NestIcon(fill:, stroke:)`; (c) a `KidScope` meadow-band inset/height param —
and mark the three local classes `// TODO(K03): replace with <shared component>`
with the request id. Alternative: delete `_SpeechBubble`/`_TailPainter` and
call `NestPetStage(speech: …, pipSize: …)` with only a `PipAvatar` overlay,
then re-measure the slot.

### 2. [minor] Hard-coded geometry in the pet slot and painters
`kid_home_view.dart:609-610, 616-617, 622-623` (`260 × 236`, `left 54`,
`bottom 96`, `size 152`), `:655` (`maxWidth: 260`), `:658` (`r18`),
`:684` (`Size(18, 10)`), `:742` (`Size(26, 26)`), `:748-777`
(`strokeWidth = 2 * s` off a copied path), `:796-797` (curve points
`24`, `w*0.45`, `2`, `20`). None are `NestSpacing` / `NestDevice` /
`NestRadii` values, and the stage rule is tokens only. Fix: these numbers
belong to the shared component's parameters (finding 1); if the screen must
own them, hoist them into one `private const` block with the
`.k3-pet` spec citation (as `1_plan.md` §(a) already does for the type
sizes) so there is a single place to change.

### 3. [minor] Typography forked past `NestType`; kid body copy below the spec minimum
`kid_home_view.dart:325, 337, 386, 670` and
`widgets/kid_status_chip.dart:31` call `GoogleFonts.nunito(fontSize: 22 / 15 /
16, …)` directly instead of `NestType` (`tokens/typography.dart:10`), so the
type scale is bypassed for this screen only. The 15 px `.k3-sub` / `.kcap` /
`.kchip` copy is also below DESIGN_SPEC §0.9's "body text ≥ 17 px kid"
minimum (the K03 HTML uses 15 px, so the design and the a11y rule disagree).
Fix: file the missing styles as a shared request — `NestType.kidName`
(22/26 w900), `kidCaption` (15/20 w700), `kidChipLabel` (15/15 w800) — and
either move to them or record the sub-17 px kid-copy exemption in
`SHARED_REQUEST.md`. (Colours, radii and spacing in the same widgets are
correctly tokenised.)

### 4. [minor] Mandatory `ORCHESTRATOR_NOTES` #1 asks for `PipAvatar(..., inNest true)`; the screen leaves it false
`kid_home_view.dart:614-630` composes `nest.svg` + a standalone `PipAvatar`
(`inNest` defaults to `false`), so the shared `PipStage` artboard's
"front rim biting the feet" z-order is not used. I measured the slot against
both design PNGs: app Pip box 152 with a ~92-100 px silhouette at y≈214-300
vs design ~94 px at y≈198-288, nest rim y≈294-300 vs design ≈288-294 — i.e.
the *measurable* part of the note ("keep the design's size and position") is
met, and the UI stage accepted the result twice (5_ui A3). Fix for the
traceability gap only: either pass `inNest: true` and drop the separate nest
SVG (then re-measure the slot), or record the waiver against note #1 in
`SHARED_REQUEST.md` so the deviation from a mandatory note is on the record.

### 5. [minor] `copyWithLoaded` keeps a stale `errorMessage` after a successful retry
`kid_home_state.dart:115` passes `errorMessage: errorMessage` (the old
value) into the loaded state, so after failure → "Try again" → success the
state is `loaded` while still carrying the previous failure string. No
visible effect on K03 (the failure branch is status-gated) and
`3_test.md` recorded it, but K03b/K04/K05 share this state object.
Fix: `errorMessage: null` — a healthy stream has no error.

### 6. [minor] A silent no-op write can leave the card's completion latch stuck
`kid_home_bloc.dart:72` adds to `_awaitingCelebration`, which is only
cleared on the flip (`:52`) or on a thrown write (`:81`).
`kid_home_repository_impl.dart:95` returns **silently** when the quest row
has disappeared, so in that race no flip and no error arrive: the map entry
lingers (a later completion of the same id would celebrate unexpectedly) and
`_QuestCardState._busy` (`kid_home_view.dart:835-846`) never resets, leaving
a dead check until a status/token change. Fix: treat "no flip, no error" as a
terminal outcome (evict the pending entry and surface `actionError` after a
bounded wait), or reset `_busy` in the listener when
`justCompletedQuestId == item.questId`.

### 7. [minor] Hand-rolled `SnackBar` instead of the design-system toast
`kid_home_view.dart:121-125` calls
`ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:
Text(…)))`. The shared helper `showNestToast`
(`components/nest_toast.dart:39`) is the sanctioned path: it keeps the token
palette, floats above the dock inset, and — the part that matters here —
wraps the message in `Semantics(liveRegion: true)`, which the inline version
drops, so a screen-reader user is not guaranteed the failure message.
Fix: `showNestToast(context, 'Hmm, that did not work. Try again.')`.

### 8. [minor] The child stream is watched twice per load
`kid_home_bloc.dart:29-30` combines `watchActiveChild()` with
`watchItems()`, but `watchItems()` itself opens `watchActiveChild()`
(`kid_home_repository_impl.dart:22`). Every `app_state` / `children` change
therefore drives two subscriptions, `combineLatest2` emits twice per change
(the duplicate is swallowed by `Bloc`'s equal-state check), and on a child
switch there is one frame where `child` is the new child while `items` are
still the old child's quests. Fix: one combined stream from the repository
(`Stream<KidHomeData> watchHome()`), so the screen subscribes once and child
+ items can never disagree.

### 9. [minor] The failure state ignores an available child
`kid_home_view.dart:199-205` renders `const PipAvatar(style: mochi, stage: 1,
size: 140)` even when `state.child` is populated (a stream error after a
successful load), so a child with e.g. Bolt/sky/stage 2 sees a different bird
on the error card than everywhere else. Fix: read `state.child` and reuse the
same `_pipStyle`/`_pipSkin`/`_pipAccessory` mapping as the pet slot, falling
back to the neutral look only when `child == null`.

### 10. [minor] One test is conditionally skipped; the underlying bug is shared and still open
`test/features/kid_home/k03_bugs_test.dart:943` —
`skip: !const bool.hasEnvironment('DISABLE_ANIMATIONS')` for K03-BUG-7.
`core/data/env_flags.dart` reads
`bool.fromEnvironment('DISABLE_ANIMATIONS')`, which parses `"1"` as **false**,
so the documented launch flag (RULES §5, `tools/screens/shot.sh`) does not
disable motion: `ui/` captures are live-animation frames and `shot.sh`
prints "frame never stabilised". Fix is shared (`SHARED_REQUEST.md` #5 —
accept `"1"` as true, or set `MediaQueryData.disableAnimations` at the app
root); K03 cannot edit `core/`. Until it lands, treat the `ui/` PNGs as
non-deterministic evidence and keep the skip visible.

### 11. [minor] No parental-gate lock in the loading / failure / no-child states
DESIGN_SPEC §5 Group C: a small lock button on **every** kid screen.
`kid_home_view.dart:149-175` (loading), `:177-238` (failure), `:240-279`
(no active child) render no `NestLockButton`, and
`test/features/kid_home/kid_home_view_test.dart:352` asserts its absence —
i.e. the gap is locked in by a test. The no-child state still routes to
K01 (which has its own lock), so this is not a dead end. Fix: render the
`NestLockButton(semanticLabel: 'Grown-ups')` in all three states and flip that
assertion.

### 12. [minor] Pet-stage semantics label is generic
`kid_home_view.dart:607` announces `"Pip in the nest"`; the design's alt text
is `"Pip the Fledgling"` (HTML l.53) and `NestPetStage` previously fell back
to the bubble text. Fix: include the child's stage name
(`'Pip the Fledgling, stage 3 of 4'`) so a screen-reader user gets the same
information the artwork carries.

### 13. [minor] Dock labels can wrap (no `FittedBox`)
`1_plan.md` §(e) asked for `FittedBox(scaleDown)` inside the dock buttons;
`NestKidButton` wraps the label in `Flexible` + `Text` only, so with a wider
fallback font "My jar" wraps to two lines and the dock grows (the iteration-4
test notes already flag this and skip the height comparison). On device with
real Nunito at 390 px it fits, and the 320 px × 1.3 matrix is green, so this
is cosmetic. Fix: add `softWrap: false` + `FittedBox` (or a
`NestKidButton` param) in the shared component.

### 14. [minor] Card-count difference vs the design is undocumented
The design shows three sample cards; the screen renders every active quest
(6 under the demo seed, `kid_home_view.dart:449-457`). Data wins per RULES §4
/ DATA OVER MOCKS, so this is correct behaviour — but `SHARED_REQUEST.md` #2
only records the "3 of 6" copy, so a future compare note could read the extra
cards as a defect. Fix: extend SHARED_REQUEST #2 (or `2_build.md`) with the
card-count note.

## Verdict

Blockers from the previous iterations are closed: the bottom-edge violation is
fixed in code, on device and in tests; the suite is green (`+476 ~1`);
`dart format` and `flutter analyze` are clean; the PIP identity, PERIODS and
data-over-mocks mandates are satisfied; and no file outside RULES §1 is
touched. One major finding remains — the three unrequested design-system
forks in the feature view (finding 1) — whose only defect is the missing
SHARED_REQUEST / `TODO(K03)` trail that RULES §2 prescribes; it is cleared by
filing that request and marking the classes, with no visual change. The other
13 findings are minor.


## From 5_ui.md
# K03 Kid home — UI check (Stage 5, iteration 4)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_4.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_4.png` (1170x2532). Same with `dark` -> `app_dark_4.png`.
- NOTE: absolute OUT paths used (`shot.sh` cds to `$APP_DIR`). Both runs again printed `WARNING — frame never stabilised in 25 s`, exit 1; frames usable and theme-consistent.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_4.png docs/screens/K03/ui/cmp_light_4.png` (and dark). Read both sheets. Logical px (PNG/3), tolerance ±2px.
- Rules applied: PIP (`PipAvatar` Mochi/sunny/stage 3), STATUS BAR (ignore), DATA OVER MOCKS + PERIODS (in-period counts win; seed anchored to today), BOTTOM EDGE owner rule (bar surface to the physical edge — FAIL any coloured strip; overrides the design), ALIGNMENT owner rule (20px gutters, nothing visibly off), ORCHESTRATOR_NOTES (all items incl. the OWNER FEEDBACK reversal: meadow ENDS at dock top, dock surface fills to the edge), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 13.37% — bands: 0: 2.98% · 1: 4.85% · 2: 10.84% · 3: 13.18% · 4: 13.20% · 5: 23.28% · 6: 25.80% · 7: 12.80%
- dark mean diff: 12.13% — bands: 0: 3.01% · 1: 4.47% · 2: 8.97% · 3: 9.71% · 4: 12.90% · 5: 23.12% · 6: 23.37% · 7: 11.49%
- Band 7 rose (~9.5% → ~12%) for the RIGHT reason: the home strip is now dock-surface (white/navy) while the outdated PNG still shows green there — that delta is required by the BOTTOM EDGE override. Bands 2-6 heat is dominated by accepted diffs (mandated PipAvatar art, 4-vs-3 counts + fill, Hoover/Done vs Reading/+10 sample order).

Fixed since iter3 (verified):
- F1 bottom edge (was must-FAIL): below-dock rows y810-842 are now dock surface — light WHITE (255,255,255), dark NAVY (31,28,46). No green strip in either theme. Meadow ends at the dock top; light green band still present behind the cards (x=10 green y562-699).
- Dock top back at design height (light border rows 713-715 vs design 719-721, i.e. −6, see #3).

Accepted / overridden (NOT defects):
- A1 counts "4 done today" / "4 of 6 done" / ~66.7% vs PNG 3/50% — correct per DATA + PERIODS + notes #2.
- A2 2nd card "Hoover the stairs" (approved → "Done") vs PNG "Reading" sample — repo alphabetical order wins per `1_plan.md` §(a); same peek-above-dock presentation as the PNG.
- A3 Pip drawing vs v1 SVG — MANDATED `PipAvatar`; slot kept. A4 status bar (OS time only) — ignored. A5 tiles `surface2` vs tints — SHARED_REQUEST #1. A6 title ≈17/22 vs 18/24 — pre-declared token. A7 no OS pill in captures — expected (`simctl screenshot` never captures the OS indicator).
- A8 band-7 white/navy-vs-green delta vs the PNG home strip — REQUIRED by the BOTTOM EDGE override, not a defect.

Deviations (design value → app value + fix):
1. Dark lower-content background missing the meadow tint (moderate, dark-only). Design dark x=10: (37,52,88) at y540 grading to teal (33,64,72) at y700 behind progress/cards. App dark x=10: flat navy (38,46,102) → (37,51,89) — no meadow visible, while light renders its green band correctly. Fix: check the dark meadow fills (dark `--kid-meadow`/`--horizon`, `hill-front` bake per SPACING §9.14) so the meadow shows behind the lower content in dark as it does in light. For the iteration-5 builder; do not touch in this stage.
2. Upper-stack residuals (minor, unchanged from iter3): hearts +12 (443-452 vs 455-464); progress ≈+8 (541 vs 549-550); card-1 top +4 (559-561 vs 563-564); light green start +38 (524 vs 562). Fix: trim pet-stage bottom gap toward the mandated Pip slot (nest top ≈y300, Pip ≈152).
3. Dock top −6px (minor, ALIGNMENT): light 713-715 vs 719-721. Fix: land the dock top exactly on y≈720 when owning the bottom inset.

Otherwise correct: header row, bubble, hearts 4/5 stroked + caption, section title + chip, kid progress geometry, card geometry/chips/checks per status, dock buttons (glyphs, labels, colours both themes), 20px gutters edge-aligned, no overflow/ellipsis issues, coins-only, all other dark token flips correct.

Iteration-5 fixes (local): #1 dark meadow behind lower content; #2 upper-stack trim; #3 dock top to y≈720. Shared/pre-declared: tile tint, title size.


## From 6_bugs.md
# K03 Kid home — bug hunt (Stage 6, iteration 4)

Adversarial pass over `kid_home` K03 after the iteration-4 bottom-chrome fix:
data edges, rapid double taps, back navigation, deep links, restart
persistence, mode guards, dark contrast, 320px + 1.3 scale, async gaps,
Europe/London periods (daily/weekly/once, BST edges), integer money, and the
owner rules (bar surface to the screen edge, 20px alignment).
No screen code was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 39 tests:
  37 run green, 2 skipped (`K03-BUG-7` needs its flag-specific run,
  `K03-BUG-11` is open).
- Run the open proofs:
  `cd app && flutter test --run-skipped --plain-name "K03-BUG-11"` and
  `flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"`.
- Full-suite state: `flutter test` → `+477 ~2, All tests passed!` (the two
  skips are the proofs above).

## Iteration-4 result: K03-BUG-10 is fixed

The dock's surface `Container` now wraps `SafeArea(top: false)`
(`kid_home_view.dart` bottom chrome), so the inset is painted with the bar's
own colour. Both proofs run un-skipped and pass:
- `K03-BUG-10: the dock surface must run to the physical bottom edge` (light)
- `K03-BUG-10 dark: the dock surface must also reach the edge in dark mode`
- Independently: the two stage-3 view tests ("light/dark: the dock owns the
  OS bottom inset") now pass, and UI iteration 4 measures dock surface from
  y≈810 to the physical edge, no green strip.

## Open bugs

### K03-BUG-7 — `DISABLE_ANIMATIONS=1` still parses as false

**Severity: Major (shared; motion rule + screenshot determinism).**
`5eea2ad` wired `kDisableAnimations` into `MediaQuery.disableAnimations` at
the app root, but `kDisableAnimations` itself is still
`bool.fromEnvironment('DISABLE_ANIMATIONS')`
(`app/lib/core/data/env_flags.dart:9`), which only understands `"true"`.
With the documented `=1` the flag stays false, the MediaQuery wiring never
fires, the Rive `PipAvatar` keeps animating and `shot.sh` still warns
"frame never stabilised in 25 s" (iterations 1–4 captures).

Repro:
- `cd app && flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7" test/features/kid_home/k03_bugs_test.dart`
  → `Expected: true, Actual: <false>` (asserts both `kDisableAnimations` and
  `MediaQuery.disableAnimationsOf` at the home).
- Control: passes with `--dart-define=DISABLE_ANIMATIONS=true`, proving the
  app-root wiring itself is correct.

Failing test (skipped in the plain suite):
- `K03-BUG-7: the documented DISABLE_ANIMATIONS=1 flag must disable motion`

Suggested fix (shared, SHARED_REQUEST #5): parse `"1"` as true in
`env_flags.dart`, e.g.
`bool.fromEnvironment('DISABLE_ANIMATIONS') || String.fromEnvironment('DISABLE_ANIMATIONS') == '1'`,
mirror in `launch_flags.dart`, or pass `=true` from `shot.sh` / RULES.

### K03-BUG-11 — A silent no-op completion leaves the check latched

**Severity: Minor (feature-local).**
Where: `kid_home_repository_impl.dart` `completeQuest` returns **silently**
when the quest row has vanished (`if (quest == null) return;`), while
`kid_home_view.dart` `_QuestCardState._busy` only resets on a status flip or
a `completionToken` (failure) change. A silent no-op produces neither, so
the check stays dead and the bloc's `_awaitingCelebration` entry lingers
(a later stream flip of that quest id would then celebrate a write this tap
did not make). Also recorded as review finding #6.

Repro: fake repository whose `completeQuest` records the call and returns
without error and without flipping anything; tap the "Mark done" check
twice. The second tap must reach the repository (retry), but the latch
swallows it.

Failing test (skipped so the suite stays green):
- `K03-BUG-11: a silent no-op completion leaves the check latched`
  (expected 2 recorded calls, actual 1).

Suggested fix: treat "write returned without a flip" as a terminal outcome —
e.g. after `await _repository.completeQuest(...)`, verify the quest is done
in the next emission and otherwise evict the pending entry plus bump
`actionNonce` (so the card's latch resets and the SnackBar shows); or throw
a not-found error from the repository so the existing failure path handles
it. The card could also reset `_busy` when the bloc clears that quest's
pending celebration.

## Carried open items (owned by other stages, not re-proven here)

| Source | Severity | Item | Owner |
|---|---|---|---|
| 4_review finding 1 | Major | local forks (`_KidPetStage`, `_SpeechBubble`, `_HeartIcon`, `_MeadowPainter`) must be replaced by the new shared `NestPetStage(pip:)` / `NestSpeechBubble` / `NestHeart` / `KidScope` meadow (mandatory in ORCHESTRATOR_NOTES) | iteration-5 build |
| 4_review finding 10 | Major | K03-BUG-7 above | shared |
| 5_ui iteration 4 dev 1 | Moderate (dark only) | dark lower-content meadow band missing behind progress/cards (flat navy; light renders green) | iteration-5 build |
| 5_ui iteration 4 dev 2/3 | Minor | upper-stack residuals (hearts +12, progress +8, card-1 +4, green start +38) and dock top −6px vs target y≈720 | iteration-5 build |

## Verified clean (probes in the same file)

| Category | Probe | Result |
|---|---|---|
| bottom edge | light + dark: a surface-filled box spans full width to the physical edge under the 34px inset | pass |
| alignment | 20px gutters: progress bar, first card, dock buttons share x=20 / x=370 | pass |
| state art | failure and empty-quests states render `PipAvatar`, no `pip_stage_*.svg` | pass |
| mandated Pip | Maya = mochi/sunny/none/stage 3; Leo = bolt/sky/stage 2, `2 done today` / `2 of 4 done` (seed `e972b46`); pipStage 0/9 clamped | pass |
| periods | day/week starts inclusive; daily/weekly/once; BST/GMT switch days | pass |
| period + repo | daily just before the start → to_do, at the start → approved; weekly outside → to_do; once 400 days → approved | pass |
| retry | failed completion → SnackBar, no K05; retry → K05 | pass |
| data edges | 0 / 1 / 6 children; "Maximilian-Alexander" + 9999 coins at 320/1.3; `+0` coins, no `£` | pass |
| back nav | check → K05 → back → home, card flipped to "Waiting for Mum" | pass |
| deep links | `/kid-home` kid mode with/without active child | pass |
| restart | Drift file DB closed/reopened: completion still `done_pending` | pass |
| guard | `/today`, `/today-empty`, `/quest-editor`, `/add-children`, `/pocket-money-setup` → gate in kid mode | pass |
| dark contrast | 16 K03 token pairs ≥ 4.5:1 in both themes | pass |
| async gap | late `completeQuest` failure after `bloc.close()` does not throw | pass |
| money | integer coins only on this screen | pass |

## Observations (checked, not raised as bugs)

1. **Period rollover without a DB change.** Status computes at stream-map
   time; at London midnight a daily completion stops counting only on the
   next stream emission or reload. No injectable clock, so not provable here.
2. **Test-suite wall-clock coupling.** The seed anchor is pinned
   (`flutter_test_config.dart`) but `DateTime.now()` (the period filter) is
   not; the demo counts stay deterministic only while the machine clock is
   in the pinned anchor's day/week.
3. **`inNest` note vs composition** — review finding 4; slot measurements
   met, stage 5 accepted twice; needs a waiver on record or the shared
   `NestPetStage(pip:)` migration (finding 1).
4. **Parent mode → `/kid-home`** reachable by deep link; PIN not enforced
   (K01/K02 placeholders); debug gallery routes unguarded.
5. **Accessories in the static `PipAvatar` fallback** are not drawn (no seed
   child equips one today).

## Summary

| ID | Severity | Area | Status |
|---|---|---|---|
| K03-BUG-7 | **Major** | `DISABLE_ANIMATIONS=1` parses false → Rive never still, screenshots never stabilise | **open (shared, SHARED_REQUEST #5)** |
| K03-BUG-10 | Major (owner) | dock surface to the screen edge | **fixed iteration 4, light+dark proofs green** |
| K03-BUG-11 | Minor | silent no-op write leaves the check latched | **open (feature-local)** |
| K03-BUG-1..6, 8, 9 | — | earlier defects | fixed, proofs green |

The iteration-4 bottom-edge fix is real and verified in both themes, and the
whole verified-clean table still passes. The iteration can still not close
PASS: the documented `DISABLE_ANIMATIONS=1` major (K03-BUG-7) remains open,
the review's major component-fork mandate is not yet applied, and the dark
meadow deviation is still on the UI side.

