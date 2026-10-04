# P16 Settings — QA code review (iteration 6)

Reviewed `git diff main...HEAD` and the iteration-5→6 delta (`afe1161..7189047`)
against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, the design system in
`app/lib/core/design_system/`, `docs/DESIGN_SPEC.md` §5 P16,
`docs/design/SPACING_SPEC.md`, `design/html-source/screens/P16-settings.html`,
`docs/screens/P16/1_plan.md` and `docs/screens/P16/ORCHESTRATOR_NOTES.md`
(including the 12:52 iteration-6 mandate).

No code was edited. No simulator was booted, installed on, screenshotted or
driven. Gates re-run by this stage:

```
$ dart format --output=none --set-exit-if-changed lib/features/settings test/features/settings
  Formatted 28 files (0 changed) in 0.12 seconds.
$ flutter analyze lib + the 9 settings test files and p16_test_support.dart
  No issues found! (ran in 13.9s)
$ flutter test --timeout 120s  (the 9 committed settings test files)
  00:58 +151: All tests passed!
$ flutter test --run-skipped --timeout 120s (same 9 files)
  00:49 +151: All tests passed!      # zero skip-marked proofs remain
$ flutter test --timeout 120s test/core/data/repositories_test.dart test/core/family_time_test.dart
  44: All tests passed!       # the shared suite P16's repo signature touches
$ flutter test --timeout 120s test/features/today/today_view_test.dart
  51: All tests passed!       # the one 2-line carry outside the feature
$ flutter test --timeout 120s            # whole tree, 7m19s
  07:19 +3534 ~2: All tests passed!      # the ~2 skips are K01's and P12's
```

Whole-tree `flutter analyze` reports 6 issues; **all 6 are in
`test/features/settings/probe_w_test.dart`**, an untracked file the concurrent
5_ui stage is writing right now (it declares itself *"TEMPORARY probe W
(iteration 6) — deleted before the stage ends"*, and `probe_x_test.dart` /
`zz_probe_test.dart` came and went during this run). Analysis of the committed
tree is clean.

## Iteration-5 findings — disposition

| # | finding | status |
|---|---|---|
| 1 | major — hand-rolled avatar initials instead of `nestAvatarInitial` | **CLOSED** — `settings_view.dart:434` and `:455` now call the shared helper; `package:characters` is no longer imported by the feature; `settings_a11y_test.dart:445-507` (T04) is **un-skipped and green** |
| 2 | major — the tap guard swallowed switch flips | **CLOSED** — the three `NestToggle.onChanged` callbacks (`settings_view.dart:275`, `:286`, `:296`) no longer route through `P16TransientGuard`; `SHARED_REQUEST.md` §8 files the shared fix, as RULES §2 requires; pinned live by `settings_view_test.dart:341` `[review 2]` |
| 3 | minor — "Manage subscription" painted no ripple | **CLOSED** — `settings_view.dart:211-242` gives the link row its own ink surface (`Material(color: Colors.transparent) > InkWell`); `SHARED_REQUEST.md` §3's status line is corrected; pinned by `settings_view_test.dart:406` `[review 3]` |
| 4 | minor — `.chip` label reused as hint copy | **CLOSED (interim)** — one documented call site `settingsHintStyle()` (`settings_rows.dart:132`) replaces the two hand-cancelled `chipLabel` weights, and `SHARED_REQUEST.md` §9 asks for a real `NestType.hint` |
| 5 | minor — `watchMembers` duplicated the shared query | **CLOSED** — `settings_repository_impl.dart:71` is now `_db.watchMembers()`, raw SQL gone (see finding 4 below for the residual nit) |
| 6 | minor — the repository built its own `FamilyZoneService` | **CLOSED** — injected (`settings_repository_impl.dart:16-24`, wired in `settings_di.dart:20`); the fallback keeps `test/core/*`'s `SettingsRepositoryImpl(db: db)` compiling |
| 7 | minor — `SettingsItem` / `watchItems()` / `getItems()` dead | **OPEN, but re-characterised** → finding 5. The iteration-5 claim "nothing in `lib/` or `test/` reads `watchItems()`" was wrong: `test/core/data/repositories_test.dart:362` calls it, and that file is outside RULES §1, so P16 cannot delete the trio alone |
| 8 | minor (tracked) — `_linkRowMinHeight`, `SettingsRow` | still filed as `SHARED_REQUEST.md` §7 / §6 — no action, see observations |

## Findings

### 1. major — the move banner states a false fact about history once the family zone is not London

`app/lib/features/settings/presentation/views/settings_view.dart:478` and
`:494-495` (`_MoveBanner`):

```dart
final short = shortZoneLabel(zone);          // the DEVICE zone
...
'Looks like you’re in $short now. Switch the family time zone? '
'History keeps London times; future days follow $short.',
```

"London" is hard-coded where the sentence means *"the zone your history is
already recorded in"* — i.e. the **family** zone, which the widget is never
told. In the seeded demo that coincidence is invisible (family zone ==
Europe/London), but the screen can produce the wrong sentence with two taps of
its own:

1. tap **Time zone** → pick `Asia/Dubai` in the picker → the family zone is now
   Dubai (this is the orchestrator-mandatory picker, and `Europe/London` is in
   the same list, so a UK device hits this immediately);
2. the device zone (London) now differs, so the banner appears and reads
   *"Looks like you're in London now. Switch the family time zone? History
   keeps **London** times; future days follow London."* — it names the wrong
   zone twice and contradicts itself;
3. same after **Switch**: family Dubai, device Karachi →
   *"History keeps **London** times; future days follow Karachi."* History is
   in fact kept in Dubai — `FamilyZoneService.setFamilyTimeZone`
   (`core/data/family_zone_service.dart:95-107`) rewrites the stored zone and
   never touches existing instants' `dateTz`, which is exactly the behaviour
   the sentence is meant to describe.

This is a parent-facing correctness statement in a pocket-money app (it tells a
parent where their child's history is recorded), it is reachable without any
other screen, and it is the orchestrator's own mandated feature. The sentence
that `ORCHESTRATOR_NOTES.md` (02:20 update, item 2) gives is the London
instance of a sentence with a placeholder; `settings_responsive_test.dart:534`
pins exactly that London instance, so the fix below keeps it green.

Fix: pass the family zone into the banner (it is already in state) and
interpolate it —

```dart
_MoveBanner(zone: state.pendingZone!, fromZone: state.familyZoneId)   // settings_view.dart:139
...
final from = shortZoneLabel(fromZone);                                // _MoveBanner
'History keeps $from times; future days follow $short.',
```

`shortZoneLabel('Europe/London') == 'London'`, so the seeded default renders
the mandated sentence byte-for-byte (`settings_responsive_test.dart:534` stays
green and the design/UI check is untouched), and a second test —
family zone `Asia/Dubai`, device `Asia/Karachi` → *"History keeps Dubai
times; future days follow Karachi."* — pins the new case.

### 2. minor — the `.lockhint` lock glyph is painted one token too light

`app/lib/features/settings/presentation/views/settings_view.dart:556`:

```dart
NestIcon(NestIcons.lock, color: tokens.ink2),
```

`P16-settings.html:42` draws the glyph with `stroke="currentColor"` inside
`.lockhint`, which sets no `color`, so it inherits `var(--ink)` from `.screen`
(`components.css:26`) — the same colour as the row's own text, which the app
does render as ink (`settingsHintStyle` → `tokens.ink`). The app draws it
`ink-2`, i.e. the subtitle grey.

Fix: `color: tokens.ink`. (Below the fold in both design PNGs, so this costs
the UI check nothing; it is visible the moment the row is on screen.)

### 3. minor — the `›` chevron uses a display-heading token, and the design's trail is Inter

`app/lib/features/settings/presentation/widgets/settings_rows.dart:119-120`:

```dart
Widget settingsChevron(BuildContext context) =>
    Text('›', style: NestType.h3(color: context.nest.ink3));
```

`.list-trail` (`components.css:119`) declares only `color: var(--ink-3);
font-weight: 600`, so the glyph inherits **Inter 16 w600** from `body`; inside
P16's own `.linkrow` (`P16-settings.html:9`, `font-weight: 600; font-size:
15px`) it is **Inter 15 w600**. `NestType.h3` is **Nunito 18 w800** — the wrong
family, size and weight for a UI affordance. Measured on the light design vs
`ui/app_light_6.png`, Maya's chevron ink box:

| | x | y | w | h |
|---|---|---|---|---|
| design | 348.0–353.3 | 392.3–400.0 | **5.33** | **7.67** |
| app | 349.3–353.0 | 392.7–399.7 | **3.67** | **7.00** |

Same centre and right edge (within 0.3 px), so it is inside the ±2 px rule and
the UI stage's PASS stands — but the glyph shape differs (angular Inter vs round
Nunito, visible in a 5× crop) and 1.7 px of width is spent on the wrong type.

P16 must not fix this alone: `design_system_gallery/…/gallery_parent_a.dart:128`
renders the same chevron the same way, so the choice is a system-wide
convention. Fix: add **SHARED_REQUEST §10** for a shared trail-chevron token
(Inter 16 w600 `ink-3`, 15 w600 inside `.linkrow`) and move both call sites to
it. P09 already uses the closer `NestType.bodySmallStrong` for its `›`
(`quest_editor_view.dart:1099`), which is itself evidence the convention is
unsettled.

### 4. minor — `watchMembers()` leans on core's implicit `'fam1'` while every sibling stream names `Seed.familyId`

`app/lib/features/settings/data/settings_repository_impl.dart:71`:

```dart
return _db.watchMembers().map((rows) => rows.map(_toMemberEntry).toList());
```

`_db.watchMembers([String familyId = 'fam1'])` (`app_database.dart:650`) is the
only P16 stream that does not pass `Seed.familyId` explicitly; `watchRoster`
(`:61`), `watchSettings` (`:37`) and `_write` (`:119`) all do. The values are
equal today (`seed.dart:23`), so this is latent, not live — but if the seed's
family id ever changes, `watchMembers()` silently diverges from every other
stream on the feature and the Family section empties. Fix: pass
`Seed.familyId` and keep the comment to the ordering rationale.

### 5. minor — `SettingsItem` / `watchItems()` / `getItems()` have no production consumer, and only a test P16 may not edit keeps them

`settings_repository.dart:9-10`, `settings_repository_impl.dart:26-32`,
`domain/entities/settings_item.dart` (70 lines) and the untouched foundation
model `data/models/settings_item_model.dart` (zero references). Nothing in
`lib/` reads `watchItems()`; the sole live caller is
`test/core/data/repositories_test.dart:362`
(`expect(rows.firstWhere((r) => r.id == 'notif-approvals').detail, 'Off')`),
which lives outside RULES §1's `app/test/features/<feature>/**` and therefore
cannot be edited by a screen agent.

So the honest state is: *dead in production, pinned by a shared test*, not
"dead" as iteration 5 recorded. `settings_item.dart:25-27` now documents this
correctly, which is why this drops to minor. Fix: file a **SHARED_REQUEST §11**
to drop that one shared assertion (and the unused `SettingsItemModel` with it),
then delete the entity, the two repository methods and the model in one
follow-up. Until then the surface is honest and harmless — flagged so the next
iteration does not re-report it as newly discovered.

### 6. minor — the two static Family rows still have no semantics node of their own, and the "shared component" excuse no longer applies

The screen-reader announcement for the Family section is one node: the two
static rows' text folds into the **Invite co-parent** button's node, so a
VoiceOver user hears *"Sarah — you / sarah@example.co.uk / James — co-parent /
Invited · awaiting reply / Invite co-parent, button"* and cannot tell which line
belongs to which row. This has been carried as an observation for five
iterations, always attributed to "the shared `NestListRow`'s no-`onTap` branch".

That attribution is now wrong: since the iteration-5 un-fork those two rows
(and the danger row) are rendered by **P16's own `SettingsRow`**
(`settings_rows.dart:104-114`), which returns the bare row with no wrapper when
`onTap == null`. P16 therefore owns the fix and can take it without touching the
shared row: `if (tap == null) return Semantics(container: true, child: row);`
— a plain container node, no `excludeSemantics`, no label and **no `onTap`**, so
the owner's ACCESSIBILITY-ACTIONS rule (every interactive node keeps its tap
action) is untouched, and each static row announces as its own group. A test
asserting two distinct non-tappable nodes carrying `'Sarah — you'` and
`'James — co-parent'` (and `hasLength(0)` for tap actions on them) would pin it.

An earlier attempt at this "broke the tappable-node contract for the whole
section" (`3_test.md` observation 2), which is why the container-node form
matters: no `Semantics(label:)` on a non-interactive row.

### 7. minor — a stale bug narrative inside a green, un-skipped test

`app/test/features/settings/settings_a11y_test.dart:511-540` (the `[P16-T03]`
block) still opens with *"**OPEN BUG (minor)** — pinned skip-marked so
`flutter test` stays green; run with `--run-skipped` to prove it. Do NOT patch
the screen here"*, then describes the iteration-4 `SizedBox(width: 51,
height: 44)` fork that iteration 5 deleted — while `skip: false` at `:567` runs
it live and green. A reader (or the next stage) gets contradictory instructions
from the same test. Fix: delete the stale narrative and keep the closing
comment, as `settings_view_test.dart:333-340` does for review 2.

## Verified clean this iteration

* **Orchestrator 12:52 mandate.** Both avatar initials now call the shared
  `nestAvatarInitial` (`settings_view.dart:434`, `:455`); the feature no longer
  imports `package:characters`; T04 runs un-skipped (`settings_a11y_test.dart:445`,
  `skip: false` at `:506`) and asserts the expected value *independently* of the
  helper. `characters` is now a declared dependency (`pubspec.yaml:32`).
  FIXES_5 review findings 1–6 are closed; finding 7 is finding 5 above.
* **Architecture** (`ARCHITECTURE.md`): feature-first; `domain/` is entities +
  the abstract repository only; one bloc per screen (`SettingsBloc`,
  `registerFactory` in `settings_di.dart`, dispatched once by
  `settings_routes.dart:21-22`); DI and routes inside the feature;
  `git diff main...HEAD` touches only `app/lib/features/settings/**`,
  `app/test/features/settings/**`, one small carry (4 lines replaced by 7) in
  `app/test/features/today/today_view_test.dart` (declared in SHARED_REQUEST and
  green) and `docs/screens/P16/**`. No `app/lib/core/**` or `app/lib/app/**`
  edits; the one deleted file (`settings_placeholder_card.dart`) is a
  feature-owned placeholder with zero references.
* **Design system**: no hard-coded colours — every colour is a token (finding 2
  is a wrong *choice* of token, not a literal); spacing is `NestSpacing.*`
  throughout (`s2/s3/s4/s6/padSide/gap2/gap10/gap14`); radii `NestRadii.*`;
  `SettingsRow` and `zone_picker_sheet` reference `NestListRow.trailMaxWidth`
  rather than a private 120; `NestAvatar`/`NestToggle`/`NestCard`/`NestList`/
  `NestListRow`/`NestSectionLabel`/`NestButton`/`NestModal`/`NestToast`/
  `NestBottomSheet`/`NestIcon` used as shipped. `.ptitle` declares no
  `text-wrap: balance` (`P16-settings.html:3`), so the plain `Text` with
  `NestType.h1` is correct and `NestBalancedText` is correctly unused here.
  `NestCard(radius: NestRadii.m, padding: 14/16)` matches `.subcard`
  (`P16-settings.html:7`); `SettingsRow` stays only for the 4 avatar rows and
  the danger row, exactly what `SHARED_REQUEST.md` §6 filed.
* **Copy** is character-exact against the HTML: `Family & settings` (`&`),
  `Sarah — you`, `James — co-parent` (em dash), `Invited · awaiting reply`,
  `Share the load`, `Maya · 7–9` / `Leo · 4–6` (en dash via
  `ageBand.replaceAll('-', '–')`), `Pip: Fledgling · 120 coins` (middle dot),
  `Nestling Annual · £29.99/year`, `Renews 18 Oct 2027 · Covers the whole
  family`, `Nickname + age band only`, `Friday before Saturday payout`,
  `Download our data`, `Privacy Notice`, `Delete family account`,
  `Kid mode needs parent gate — On`, `Help & feedback`,
  `Made in the UK · No ads, ever`, chevron `›`, curly `’` in `you’re` and
  `can’t`. DESIGN_SPEC §5 P16 lists every element and all are present.
  Subscription copy stays static because the schema has no plan/price/renewal
  field (`app_database.dart:252-292`: the `Settings` table carries only
  `subscriptionStatus`, and `AppState` holds no renewal date), which is what
  the plan recorded.
* **DATA OVER MOCKS**: the owner subtitle is `members.email`
  (`settings_repository_impl.dart:143-151`, `settings_view.dart:419-426`) with
  an invite-status/role fallback; `sarah@example.co.uk` appears nowhere in
  `lib/`. Children come from `watchRoster` (DB coins + `pip_stage`), so the
  design's `120 coins` / `Fledgling` come from the seed, not from copy.
* **Rules**: CLOCK — no `DateTime.now()`; `appNowUtc()` / `clock.now()` only.
  CHILD ORDER — `watchChildren` (createdAt, rowid) and the shared
  `watchMembers` (rowid). TRIAL — `subscription_status` is read, never written.
  IDS — no rows are created here. PIP / KID BACKGROUND — N/A (no Pip slot, no
  kid surface). BOTTOM EDGE — the tab bar and home edge belong to
  `ParentShell`; this view paints only the list column.
  CHIP ROWS — no chips on this screen. LETTER SPACING — every `NestType` style
  keeps its 0 default; the only `.copyWith` calls are weight/height, never
  tracking.
* **Accessibility**: 15 controls announce a name and expose
  `SemanticsAction.tap` (`settings_a11y_test.dart:78`); the
  `Semantics(excludeSemantics: true)` wrapper on the subscription link passes
  `onTap` (`settings_view.dart:218-222`) and activation pushes `/paywall`;
  switches carry `semanticLabel` + `toggled` and `performAction` writes the
  real row; 44 px minimum including the ±5 px toggle slop (T02/T03 live);
  section labels announce as headings; the delete confirm exposes both buttons
  before acting.
* **Performance**: one `BlocBuilder` over a single `emit.forEach` on a combined
  5-stream (`settings_bloc.dart:81-118`); write handlers never emit, so a
  toggle write causes exactly one emission driven by the DB (no rebuild storm,
  no load-event ping-pong); terminal errors close the subscription
  (`_closeOnError`, `:180-187`) so each "Try again" does not leak another full
  set of watchers; every static child is `const`; no `setState`, `Timer` or
  `AnimationController` in the feature.
* **Error handling**: `_SettingsFailure` renders a message plus a Retry button
  that re-dispatches the single load event (`settings_view.dart:97-104`);
  `NestModal` confirm for the destructive row and a toast only afterwards
  (`TODO(P16)`, `:398-400`) — nothing wipes the DB; toasts for the two
  placeholders. **Children's Code**: `/settings` is in the router's
  `parentOnly` list (`router.dart:85-92`), so kid mode lands on the parental
  gate; no analytics, ads, network calls, `print`/`debugPrint` or `dart:io`
  anywhere in the feature, and no child data leaves the device.

## Observations (not findings)

1. **Tracked in SHARED_REQUEST, no action this iteration**: `P16TransientGuard`
   as a process-wide static (§8, the blast radius is now the row handlers only);
   the `.lockhint` type literal (§9, one call site); `_linkRowMinHeight = 52`
   (§7); `SettingsRow`'s two remaining slots (§6). All filed as RULES §2 asks,
   none blocking.
2. Process items (uncommitted `.brief_*.md`, branch state, merge order) are
   excluded per the orchestrator rules.
3. A concurrent 5_ui stage is running in this worktree: `probe_w_test.dart`
   (and briefly `probe_x_test.dart`, `zz_probe_test.dart`) are untracked
   temporary probes that come and go during this run, and `ui/app_*_6.png` /
   `cmp_*_6.png` are being written. The test/bugs stages have also added
   uncommitted proofs to five `test/features/settings/*.dart` files during this
   review (315 added lines, including two more `[review finding 2]` proofs in
   `p16_transient_guard_test.dart` — they corroborate the disposition above).
   None of it is in the committed diff; the committed tree analyses clean.
4. `_SettingsLoaded` calls `settingsZoneSummary(state.familyZoneId,
   appNowUtc())` in `build` (`:121`). Correct under the pinned clock and cheap
   (`toFamilyZone` + offset), but it is one clock read per rebuild — if a future
   change starts rebuilding this list at high frequency, hoist it into the
   bloc's state. Not a defect today.

## Verdict

One major finding: the move banner tells a parent their history is kept in
London times once the family zone is anything else — reachable in two taps
using this screen's own picker, and fixed by interpolating
`state.familyZoneId` (the mandated sentence stays byte-identical in the seeded
default, so no design or UI-check risk). Six minors: the `.lockhint` glyph
colour, the chevron type token, the implicit `fam1`, the `SettingsItem` trio,
the static-row announcement merge, and a stale test comment.

VERDICT: FAIL
