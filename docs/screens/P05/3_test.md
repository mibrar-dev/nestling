# P05 · Add children — test notes (STAGE 3, iteration 1)

Route `/add-children`, feature `family`, parent mode. Tests live in
`app/test/features/family/add_children_test.dart` (28 → **65** tests, all
green). No screen code was changed in this stage.

**Result: one real, screenshot-verified bug blocks the UI gate
(P05-BUG-1, design-system root cause), plus two smaller findings. The suite
passes and `flutter analyze` is clean, but a bug was found — see
`SHARED_REQUEST.md` and *Bugs found* below.**

## Test inventory (65)

`bloc_test` / unit — every event and state path:

| Area | Covered |
|---|---|
| `FamilyState` defaults | `initial`, empty draft, `7-9`, `peach`, no error, not saving |
| `copyWith` | keeps `nicknameError` when omitted (sentinel), clears on explicit `null`, leaves other fields, equals original |
| `FamilyLoadRequested` | loading → loaded (members **and** children), stream error → failure |
| `FamilyChildrenRequested` | loaded with roster, stream error → failure |
| roster re-emission | `StreamController` pushes `[]` → kids → one kid; each replaces the cards |
| `FamilyDraftChanged` | each field, partial change leaves others, empty change emits nothing, nickname edit clears the error, age-band change does **not** clear it |
| `FamilyAddChildRequested` | empty → error + `addChild` never called; whitespace-only → same; >24 chars → length error; 24 chars → accepted; valid → trimmed nickname + draft band/colour; `onSaved` called once on success, **not** called when the repository throws; repo failure → inline error, form preserved; success clears the nickname draft only; second save reuses band/colour |
| helpers | `avatarColourFor` all 5 + fallback, `displayAgeBand` en-dash + `13+` passthrough |

Widget tests:

| Area | Covered |
|---|---|
| Light + dark | full content in both; failure state in dark too; **bottom-edge rule in both** |
| Widths | 320 / 390 / 430 × text scale 1.0 and 1.3 (6 combinations) — no overflow, CTA intact, scroll-through of every form label |
| Empty | `Seed.fresh` (form only, no cards) and `Seed.empty` (onboarded parent, no children → no grid, Continue still advances) |
| Loading | full-body spinner, head not shown |
| Error | message + `Try again` recovers to the loaded screen |
| Save states | both buttons disabled + Continue spinner while saving; the next-frame tap cannot re-submit; failed save keeps the text and re-enables; empty/whitespace and 25-char rejections are inline, never reach the DB |
| Real DB | saved row is trimmed and carries the selected band/colour, roster repaints from the stream, no navigation; 5 children → 3 rows of the computed tile height; roster order == DB order |
| Navigation | Back → `/privacy`; each pencil → `/child-profile?childId=<id>`; Continue (empty) → `/pocket-money-setup`; Continue (with text) saves then → `/pocket-money-setup`; add-another / chip / swatch taps stay put |
| Semantics | `Back`, `Edit <name>` (merged node, regex match), 5 `Avatar colour <name>` labels, nickname field labelled + `TextInputAction.done`, chip + swatch `selected` state, pencil node label read from the semantics tree and tapped through it |
| Tap targets | back 44×44, both pencils ≥44×44, 4 chips ≥44×44, 5 swatches exactly 44×44, Add another ≥48, Continue ≥52 |
| Alignment (owner rule) | head / kid grid / form card / CTA button / caption all on `left = 20` and `right = W − 20` at 320, 390, 430; form card edges == CTA button edges; grid column width computed (`(W − 40 − 10)/2`, 135 at 320); pencil stays inside its card |
| Bottom edge (owner rule) | `NestBottomCta` bottom == the physical screen height, full-bleed 0…W, panel colour == `tokens.surface`, Scaffold == `tokens.paper`, and the two differ so a short bar would be visible |

Every test that pumps the app ends with `disposeApp(tester)` (RULES §7).

## Results

```
dart format .        clean
flutter analyze      No issues found!            (full app)
flutter test         00:11 +544: All tests passed!   (full suite, 65 of them P05)
```

Probe scaffolding used to measure geometry was deleted; the only test file is
`add_children_test.dart`.

## Bugs found (recorded, not patched)

### P05-BUG-1 — age chips render as 4 stacked full-width rows, and the swatches
### end up under the bottom CTA (major, design-system root cause)

`NestChip`'s interactive branch
(`app/lib/core/design_system/components/nest_chip.dart:69-90`) is
`ConstrainedBox(min 44×44) → Center → …`. `Center` is an `Align` without
factors, so it takes `constraints.biggest` — inside a `Wrap` run that is the
full available width, so every chip claims a 322×44 box at 390 px and the
`Wrap` breaks after each one.

Repro (widget geometry, demo seed, 390×844):

```
add_child_form_card.dart:70  Wrap(spacing: 8, runSpacing: 8, NestChip × 4)
  ageChip-4-6   box 34,519 → 356,563   (322 × 44)
  ageChip-7-9   box 34,571 → 356,615   (322 × 44)
  ageChip-10-12 box 34,623 → 356,667
  ageChip-13+   box 34,675 → 356,719
  visible pill (Ink) ≈ 74–102 wide, centred in each 322-wide row
```

The design (`design/screens/light/P05-add-children.png`) shows **one row of
four** chips (`components.css` `.chip-row { display:flex; gap:8px;
flex-wrap:wrap }`), so every chip should sit on the same `dy`.

Impact, all reproduced:

1. The form card grows from ≈298 to ≈470+ px.
2. Only `4–6` and `7–9` are on screen; `10–12`, `13+` and all five avatar
   swatches sit **underneath** the `NestBottomCta` (chips at y 519/571/623/675
   vs the CTA top at y 658).
3. A tap at a swatch's position lands on the CTA's **Continue** button:
   `tester.tap(find.byKey(Key('swatch-sky')))` without scrolling navigates to
   `/pocket-money-setup` instead of choosing a colour (this is what broke my
   first draft of two navigation tests — the tests had to scroll the swatches
   clear of the CTA to exercise them).
4. Screenshot proof: `docs/screens/P05/ui/bug_evidence_chips_light.png`
   (`shot.sh /add-children`, demo seed, light, 390×844 @3x) — chips stacked
   and centred, `10–12`/`13+` clipped behind the bar.

Not a P05 workaround: `Row` typesets the widths correctly but the chip box
fills the row height (560 px) and the four chips overflow by 32 px at 390/1.3×
and 102 px at 320/1.3×, which `SPACING_SPEC` §10 forbids. Fix filed in
`SHARED_REQUEST.md` with a suggested construction and the regression test to
add once it lands.

### P05-BUG-2 — "Add another child" can save twice inside one frame (minor)

`add_children_view.dart:116-125` guards the double submit by rebuilding with
`onPressed: null` / `loading: true`, i.e. one frame after the bloc emits. Two
taps delivered in the same frame both reach `_onAddAnother`, and with bloc's
default concurrent transformer both handlers read the same draft nickname.

Repro (deterministic — repository gated on a `Completer`, one insert counted
per call):

```dart
await tester.tap(find.text('Add another child'));
await tester.tap(find.text('Add another child'));   // no pump between
await tester.pump();
// → repo.addChild called 2×; in production: two children rows, onSaved twice
```

Real-world window is one frame (a real double-tap lands ~6 frames later, and
that path *is* covered — "a tap in the next frame cannot submit a second
time" asserts `addChild` called exactly once). Recorded as-is; a bloc-level
guard (ignore `FamilyAddChildRequested` while `saveInProgress`, or a
`droppable()`/sequential transformer on that event) would close it.

### P05-BUG-3 — roster order: Leo first, Maya second (design order differs)

`app/core/data/app_database.dart:291-296` orders `watchChildren` by
`nickname`, so "Leo" < "Maya" and the grid shows Leo in the left column; the
design mock shows Maya first (seed insertion order). Not a P05 defect — every
roster screen inherits the same order — but the design mocks and the DB
disagree, and with mixed-case or accented names the order gets worse. Locked
into a test ("roster order comes from the database (nickname order)") so the
behaviour is explicit rather than accidental. Orchestrator call: align the
mocks, or switch the ordering to creation order.

## Observations for the UI stage (not bugs)

* The compact `NestNavBar` renders 44 px tall; `SPACING_SPEC` (lines 83, 88)
  specifies 52. The app screenshot's h1 ink sits at y 96.3 vs 112.3 in the
  design. Filed as a shared request (one-line `minHeight` change).
* Kid card tile: app 124 px vs the design's auto-height 116 px
  (`cardH` = padding 22 + avatar 44 + 2 + 24 + 4 + 18 + 10 pencil clearance).
  The 8 px is deliberate pencil headroom; compare.py will show it as a
  uniform band drift on the form card below.
* Measured gutters are exact: 20 px everywhere, form card edges == CTA button
  edges at 320/390/430, and the CTA surface runs white to the physical bottom
  edge in light **and** dark. The design PNG is the one that breaks the owner's
  bottom-edge rule: it is `#FBF7F0` (page tint) from y≈810 to y=843, i.e. a
  34 px cream strip under the CTA, while the app screenshot is `#FFFFFF` at
  y = 800/820/838/843 — the app is the correct one.
* `flutter_test` uses a fallback font (wider than Inter/Nunito), so in-test
  line counts are pessimistic. The 320 + 1.3× overflow tests are therefore
  conservative; real-text wrapping is shorter.

VERDICT: FAIL