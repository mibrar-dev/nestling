# P05 · Add children — build plan (STAGE 1)

Route `/add-children` (feature `family`, parent mode). Sources measured:
`design/html-source/screens/P05-add-children.html` (+ its `<style>` block),
light/dark PNGs (÷3 = logical px), `DESIGN_SPEC.md` §5 P05,
`docs/design/SPACING_SPEC.md` §§1–3, 8 (P05 values), 10–11.
No Pip slot on this screen (avatar initials only) → PIP orchestrator rule N/A.
`NestStatusBar` reserves height only (OS draws glyphs) → ignore status-bar drift.

## (a) Widget tree, top → bottom (tokens only, no hard-coded colours/sizes)

`Scaffold(backgroundColor: tokens.paper)` body = `Column`:
1. `NestStatusBar.new()` — height reserve 47 (`NestDevice.statusH`).
2. `NestNavBar.new(compact: true, onBack: pop, backSemanticLabel: 'Back', title: null)` —
   min-height 52, horizontal padding `NestSpacing.s3` (12), back button 44×44
   (`NestIcons.back`, 24px, `tokens.ink`). No title (design shows back chevron only).
3. Scroll: `ListView(padding: EdgeInsets.fromLTRB(20, 0, 20, 32))` (`padSide` 20,
   bottom `s8` 32; no fab/tab on this screen so base bottom wins):
   - Head block: `Text("Who's in your nest?", style: NestType.h1(ink))` (Nunito
     28/34 w900, maxLines 3) + `SizedBox(8)` + `Text("Nicknames only — no photos,
     no email.", style: NestType.body(ink2))` (Inter 16/24). (HTML `.head p`
     margin-top 8.)
   - `SizedBox(14)` (HTML `.scroll > .kid-grid` margin-top 14 — screen wins over base 16).
   - Kid grid (only if `children.isNotEmpty`, else `SizedBox.shrink()`):
     `GridView.builder(shrinkWrap, neverScrollable, gridDelegate:
     SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,
     crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: <tuned so card
     hugs content>))`. Column width MUST be computed: `colW = (W − 40 − 10) / 2`
     (170 at W=390, 135 at W=320 — never fixed 170; SPACING_SPEC §10.2).
     Card = `NestCard.new(padding: EdgeInsets.fromLTRB(10, 12, 10, 10))`
     (HTML `.kid-card` padding `12px 10px 10px`), child `Column(gap 2,
     center)`: `Stack`? No — edit button is `Positioned(top: 1, right: 1)`:
     implement card child as `Stack(children: [Center-column, Positioned(edit)])`.
     Column: `NestAvatar.new(initial: first letter, size: s44, color: mapped)`
     (Maya → lilac, Leo → peach; mapping `avatarColour` string → `NestAvatarColor`:
     lilac/peach/sky/leaf/coin, fallback neutral) + `Text(nickname,
     Nunito 18/24 w800 ink, maxLines 1, ellipsis)` (HTML `.kid-name`) +
     `SizedBox(4)` + `Text("Age 7–9", Inter 13/18 ink2)` (HTML `.kid-age`
     margin-top 4; display bands with en-dash: `4–6, 7–9, 10–12, 13+`;
     seed stores `4-6, 7-9, 10-12, 13+`). Edit button: 44×44 transparent,
     `NestIcon(NestIcons.edit, size: 20, color: tokens.ink3)`,
     Semantics `Edit <nickname>`, key `editChild-<id>`.
   - `SizedBox(12)` (HTML `.scroll > .form-card` margin-top 12).
   - Form card: `NestCard.new(padding: EdgeInsets.all(14))` (HTML `.form-card`
     padding 14), child `Column(crossAxisStart)`:
     `Text("Add a child", NestType.h3)` (Nunito 18/24 w800) +
     `SizedBox(10)` + `NestTextField.new(key: nicknameField, label: "Nickname",
     hintText: "e.g. Ollie", controller/focusNode owned by a stateful form
     widget, textInputAction: done, errorText: state.nicknameError)` (HTML
     `.form-card .field` margin-top 10; label 13/18 w600 ink2; input h52 r16
     border line, focus leaf ring — all inside `NestTextField`) +
     `SizedBox(8)` + `Text("Age band", NestType.fieldLabel)` (HTML `.lbl`
     margin-top 8) + `SizedBox(4)` + age chips `Wrap(spacing: 8, runSpacing: 8)`
     (HTML `.chip-row` margin-top 4, gap 8): 4 × `NestChip.new(label, selected,
     onSelected, key: ageChip-<band>)` bands `4–6 / 7–9 (default selected) /
     10–12 / 13+`; `NestChip` already wraps interactive chips in 44-min tap
     area (SPACING_SPEC §3) + `SizedBox(8)` + `Text("Avatar colour",
     NestType.fieldLabel)` + `SizedBox(4)` + swatches `Wrap(spacing: 8)`:
     5 × 44px circles, fills `tokens.lilac / peach / sky / leaf / coin`
     (HTML `.sw` solid brand fills), selected ring
     `BoxDecoration(border: Border.all(ink, 3))` outside the fill
     (HTML `.sw.on` 3px ink ring; design PNG shows dark ring on peach) +
     `Semantics(label: "Avatar colour <name>", selected)` per swatch,
     keys `swatch-<colour>`, default selected `peach` (design) +
     `SizedBox(6)` + `Text("We only ask for an age range so quests suit them.",
     NestType.caption(ink2))` (HTML `.form-note` margin-top 6, 13/18).
4. `NestBottomCta.new(caption: "You can change any of this later in Family.",
   child: Column(mainAxisSize.min, children: [
     NestButton.new(key: addAnotherButton, label: "Add another child",
       variant: secondary, leading: NestIcon(NestIcons.plus), minHeight: 48),
     SizedBox(8),
     NestButton.new(key: continueButton, label: "Continue", variant: primary,
       minHeight: 52, loading: state.saveInProgress),
   ]))` — surface bg + top hairline + `16/20` padding via `NestBottomCta`
   (owner bottom-edge rule: bar runs to physical edge through its internal
   `SafeArea(top: false)`; NEVER wrap in extra containers). Column gap 8
   matches `.bottom-cta` gap 8; caption centred 13/18 ink2.
5. No `NestHomeIndicator` widget in product code (OS draws it; `NestHomeIndicator`
   renders `SizedBox.shrink()` when mock glyphs off).

Dark mode: identical geometry; all colours via `context.nest` tokens
(surface #1F1C2E cards on paper #15131F; swatch fills use dark tokens).

## (b) BLoC events / states / repository calls (Drift via existing repo)

One bloc per feature (`FamilyBloc`); ADDITIVE changes only (P15 shares this
bloc/file — no renames, no signature changes to existing members).
`FamilyRepository` already exposes everything P05 needs — no repo changes.

State additions (`family_state.dart`, all defaulted so P15 unaffected):
- `children: List<FamilyChild>` (default `[]`) — from `watchChildren()`.
- `draftNickname: String` (default `''`), `draftAgeBand: String` (default `'7-9'`),
  `draftAvatarColour: String` (default `'peach'`) — design defaults (7–9 chip +
  peach swatch selected).
- `nicknameError: String?` (default null), `saveInProgress: bool` (false).

Events (`family_event.dart`):
- Keep `FamilyLoadRequested` as-is (route already adds it).
- ADD `FamilyChildrenRequested` — subscribes `emit.forEach(_repository.watchChildren())`
  → `status loaded` + `children`; onError → `failure` + message. (RULES §4:
  blocs subscribe with `emit.forEach`, never re-add load events.)
- ADD `FamilyDraftChanged({String? nickname, String? ageBand, String? avatarColour})` —
  sync event updating draft fields, clearing `nicknameError` on nickname edit.
- ADD `FamilyAddChildRequested({required VoidCallback onSaved})` — validates
  `nickname.trim()`: empty → `nicknameError: "Give them a nickname"`; >24 chars →
  `"Keep it under 24 characters"`; else `saveInProgress: true` →
  `await _repository.addChild(nickname: trim, ageBand: draftAgeBand,
  avatarColour: draftAvatarColour)` (existing signature, `weeklyBasePence: 0`
  default) → `saveInProgress: false`, clear nickname draft (keep age/colour),
  call `onSaved`. Repo stream emits the new card automatically.

Form `TextEditingController` lives in a stateful `_AddChildForm` widget
(presentation/widgets/, feature-private per ARCHITECTURE) and forwards
`onChanged` → `FamilyDraftChanged`; bloc is source of truth for validation.

## (c) Interactions → navigation (route constants)

- Back (`NestNavBar` onBack) → `context.pop()` → P04 `/privacy`
  (`PrivacyConsentRoutePaths.privacy`).
- Edit pencil per card → `context.push(FamilyRoutePaths.childProfile,
  extra: {'childId': child.id})`. `childProfileRoute` currently takes no params;
  P15 (same feature) reads `state.extra`; until then it falls back to first child.
  Contract is intra-feature — no SHARED_REQUEST (see §g).
- Age chip tap → `FamilyDraftChanged(ageBand: band)` (single-select; tapping the
  selected chip keeps it selected).
- Swatch tap → `FamilyDraftChanged(avatarColour: colour)`.
- "+ Add another child" → `FamilyAddChildRequested(onSaved: keep focus on
  nickname field)`. Empty nickname → inline error, no save, no navigation.
- "Continue" → if `nicknameController.text.trim().isNotEmpty`: dispatch
  `FamilyAddChildRequested(onSaved: go)` (button shows `loading`), else go
  directly; `go() = context.push(PocketMoneyRoutePaths.setup)`
  (`/pocket-money-setup`, P06). Never blocked by empty form (children already in
  grid persist via the stream).
- Nickname field submit (done action) → same as "+ Add another child".

## (d) Empty / loading / error states

- `SEED=fresh` (onboarding entry): `children == []` → grid is `SizedBox.shrink()`;
  only head + form card + bottom CTA. (Design shows 2 cards because the mock is
  mid-flow; the empty form-only layout IS the P05 empty state — no illustration
  in spec.)
- `initial/loading` → `Center(CircularProgressIndicator)` full-body (existing pattern).
- `failure` → centred `Text(errorMessage)` + `NestButton.secondary("Try again")`
  re-adding `FamilyLoadRequested` + `FamilyChildrenRequested`.
- Save failure (addChild throws) → `nicknameError: "Something went wrong — try
  again"` on the field; form preserved.

## (e) Accessibility

- Semantics: nav Back (built into `NestNavBar`); `Edit <nickname>` per pencil;
  `Nickname` label on field (`NestTextField` wraps `Semantics(textField)`);
  chips `NestChip` exposes selected state; swatch group `Semantics(label: "Avatar
  colour", container)` + per-swatch selected; Continue/Add-another are labelled buttons.
- Tap targets ≥ 44: edit 44×44, chips 44-min (built-in), swatches 44, buttons 48/52.
- Text scale 1.0–1.3 (app clamp, SPACING_SPEC §10.1): names `maxLines: 1 ellipsis`
  inside `Flexible`; chips `Flexible + ellipsis` (built into `NestChip`); form
  labels single-line ellipsis; verify at 1.3 with `shot.sh` — no overflow.
- Width 320: computed `colW` (135); chips + swatches in `Wrap` (5×44+4×8 = 252 ≤
  280 content width ✓); scroll vertical only, never horizontal.
- Contrast from tokens (≥4.5:1 body); focus ring on field/buttons built into DS.

## (f) Test plan (`app/test/features/family/`, existing scope only)

`flutter test` must stay green; widget tests pumping the app MUST end with
`disposeApp(tester)` (`test_scope.dart`, RULES §7 — Drift deferred timer).
`GoogleFonts.config.allowRuntimeFetching = false` in widget tests.
- Bloc: demo stream emits Maya+Leo (mock `FamilyRepository.watchChildren`);
  `FamilyDraftChanged` updates each draft field; empty nickname → error, repo
  `addChild` NOT called; valid → repo called with trimmed nickname + draft
  band/colour; save clears nickname draft only.
- Widget (pump `AddChildrenView` under test `FamilyBloc` + `MaterialApp.router`
  or direct Scaffold harness): fresh/empty → no kid cards, form visible;
  demo → Maya "Age 7–9" + Leo "Age 4–6" cards with edit buttons; tapping age chip
  selects it (7–9 default); tapping swatch moves ring; add-another with "Ollie"
  → repo called + field cleared; continue with empty field → navigates to
  `/pocket-money-setup`; back pops; failure state shows retry.
- Robustness: textScaler 1.3 + W=320 harness → no overflow exceptions.
- Visual: `shot.sh /add-children` light + dark (SEED=fresh AND demo) +
  `compare.py` vs design PNGs; fix drift or file SHARED_REQUEST.

## (g) SHARED_REQUEST needed?

NONE. Route paths exist (`FamilyRoutePaths.childProfile`,
`PocketMoneyRoutePaths.setup`, pop→`/privacy`); `FamilyRepository.addChild` /
`watchChildren` exist; every visual maps to existing DS components
(`NestNavBar, NestCard, NestAvatar, NestTextField, NestChip, NestButton,
NestBottomCta, NestIcon, NestStatusBar`). `extra {'childId'}` contract with P15
is intra-feature (`features/family/**` is editable per RULES §1); P15 reads it
when built — P05 implementation must tolerate P15-absent (push works regardless).
Note for orchestrator: P15 shares `family/` — merge P05 bloc/state changes
additively (no renames) to avoid conflicts.

---
Files the builder may touch (RULES §1 only):
`app/lib/features/family/presentation/views/add_children_view.dart`,
`app/lib/features/family/presentation/widgets/` (new form/grid widgets),
`app/lib/features/family/presentation/bloc/family_{bloc,event,state}.dart`,
`app/test/features/family/**`, `docs/screens/P05/**`.

VERDICT: PASS
