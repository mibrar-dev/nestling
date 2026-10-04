# Shared request — P16 time-zone / settings shared items

Filed by the **stage-2 integrator**, not by a builder: review finding 3 asked for
a `SHARED_REQUEST.md` and none existed, and four "LEFT" items from
`FIXES_1.md` had no carrier. Docs only — no code in this branch depends on any
of it landing.

> **Status after shared batch 6 (iteration 5):** §§1–5 all LANDED and are
> closed. §1 → the shared `NestListRow` keeps 56 with a 51×31 toggle and
> hit-forwards the 44 px slop. §2 → `NestSectionLabel` is 13/16. §3 →
> `NestCard(radius:, padding:)`. §4 → `members.email` (schema v7). §5 → IANA
> links resolve to canonical. P16's local `_P16Sect`, the subcard fork and the
> `SizedBox(width: 51, height: 44)` switch wrappers are deleted, and both
> remaining proofs (B09, T03) run un-skipped. **§6 is the one open request** —
> it is what still keeps `SettingsRow` alive on this screen.

## 1. `NestToggle` / `NestListRow` cannot deliver a 44 px tap target (P16-T02, major) — LANDED (batch 6)

Need: a switch row's live hit area is ~36 px (measured `track.top − 2` →
`track.bottom + 2`), below the owner 44 px rule. Iteration 2 re-measured with
the 3_test report's suggested screen-local fix (render the switch rows at 6 px
vertical padding so the content box is 44 px) and it does **not** work:
`_RenderToggleHitSlop` inside `NestToggle` only registers inside its own box,
and an ancestor `Padding` does not enlarge that box, so `track.top − 5` still
flips nothing. The same slop pattern is used by `NestChip`, which is why
`NestChipWrap` exists as a shared wrapper — `NestToggle` has no equivalent. Fix
belongs in the shared row/toggle: either apply the slop at a box that spans the
row, or give `NestListRow` a row-native minimum tap height of 44.
Files: `app/lib/core/design_system/components/nest_toggle.dart`,
`nest_list_row.dart` (possibly a `nest_chip_wrap.dart`-style wrapper).
Blocks: **no** — P16's a11y proof stays `skip: true` with its writeup until it
lands; nothing else waits on it.

## 2. `NestSectionLabel`'s 18 px line box vs the browser's natural line height — LANDED (batch 6)

Need: the shared section label pins an 18 px line box while the design CSS lets
a 13 px Inter label take its natural line height (~15.7 px). `5_ui` measured
the cumulative effect on P16 as progressive drift of ~+1–2 px per section
(children card top +4, subscription subcard top +6), which breaches the ±2 px
UI verdict rule. P16 worked around it with a local `_P16Sect` that measures
Inter's natural height with a one-off `TextPainter`. Making the shared label
match its font's natural height would let every screen drop the local copy.
Files: `app/lib/core/design_system/components/nest_section_label.dart` (or the
typography token it pins).
Blocks: no.

## 3. `NestCard` has no radius override — LANDED (batch 6)

Need: `NestCard.standard` always decorates with `NestRadii.allL` (24 px), but
the design's `.subcard` pins `border-radius: var(--r-m)` (16 px,
`tokens.css:77`). P16's subscription card is therefore a local surface
container rather than the shared component. A radius variant (or a `radius`
parameter) on `NestCard` would let P16 use the shared card again.

**The fork is not style-only — it costs a `Material`.** `NestCard` wraps its
child in `Material(borderRadius: …)` (`nest_card.dart:71`); P16's local
`Container` does not, so the `Manage subscription` `InkWell`'s ripple resolves
to the Scaffold's `Material` **behind** the card instead of on it (bug-stage
observation 2 in `FIXES_2.md`). A `radius` parameter removes the fork *and* that
defect together.
Files: `app/lib/core/design_system/components/nest_card.dart`.
Blocks: no.

## 4. `members` has no email column (review 6) — LANDED (batch 6)

Need: P16's owner row renders `sarah@example.co.uk` as hard-coded copy because
`members` is `id, familyId, name, role, inviteStatus` — there is nothing to
read. DATA-OVER-MOCKS cannot be honoured without the column. Either add
`members.email` (schema + seed) or agree a role-derived subtitle (e.g. `Owner`)
and drop the copy.
Files: `app/lib/core/data/` schema + migration, `Seed`, and P16's
`SettingsMemberEntry`/`watchMembers` (feature-owned, will follow).
Blocks: no.

**Iteration 4 measured this, because `ORCHESTRATOR_NOTES` (08:12) ruled "the
parent's email must come from the DB … the seed holds that value" — and the
seed does not.** `grep -i email` over `app_database.g.dart` and
`lib/core/data/*.dart` returns **0 hits**: no table in the schema has an email
column. The omission is deliberate and already documented by the auth feature:
`auth_repository_impl.dart:38` states *"the members table has no
email/password columns"* and `:41` uses the submitted email **only** to derive
the owner display name (that derivation is how `Sarah` exists at all).
`auth_repository.dart:9-17` repeats it and asks the orchestrator to migrate
the shared test to `email:`.

So `sarah@example.co.uk` exists in the codebase in exactly two places: P16's
hard-coded row subtitle (`settings_view.dart:468`) and the design-system
gallery as a form `hintText` (`gallery_forms.dart:21`) — i.e. it is placeholder
copy in both, seeded nowhere.

Consequence: the 08:12 ruling is **unsatisfiable as written**, and its own
fallback ("if the DB lacks a field, write SHARED_REQUEST.md") is what this
section is. Two ways to close it, cheapest first:
1. **Agree a role-derived subtitle** (`Owner`, or the stored `name`) and drop
   the email copy — no schema change, no migration, and it removes a hard-coded
   string that DATA-OVER-MOCKS can never satisfy.
2. **Persist the email** — add `members.email`, migrate, seed it, and change
   `AuthRepository.createAccount` to store it instead of discarding it (the
   email is already in hand at signup, so the write is free; only the schema
   and the auth contract change).

Note the ruling also affects four P16 tests that assert the literal string
(`settings_view_test.dart:113`, `settings_responsive_test.dart:365`), so
whichever way it goes, those follow the shared decision.

**RESOLVED (shared batch 6) — option 2 above is what shipped.** `members.email`
now exists (schema v7, nullable) and `Seed` writes `sarah@example.co.uk`
(`seed.dart:83,127,180`). The measurement above is kept as the record of how the
gap was found: the 08:12 ruling was written against a tree that had no email
column anywhere, and batch 6 made its premise true. Nothing here suggests the
ruling was mistaken — only that it described the destination, not the tree it
was written on. P16 now reads the address from the database and falls back to
the role/invite copy when it is NULL, so no address is ever invented.

## 5. IANA link ids are rejected by `isKnownZoneId` (P16-B09, minor) — LANDED (batch 6)

Need: the bundled `package:timezone` `latest_10y` dataset has 341 locations
and **no IANA backward links**, so a phone that reports a link id
(`Europe/Amsterdam` → `Europe/Brussels`, `Asia/Calcutta`, `US/Pacific`,
`Europe/Kiev`, `Asia/Saigon`, …) reads as an unknown zone:
`FamilyZoneService.deviceZoneId()` returns null, and the family gets no move
prompt and no picker “Current location” row (measured: with a reader returning
`Europe/Amsterdam`, the picker lists London→Sydney only). Resolve links to
their canonical zone inside `isKnownZoneId`/`normalizeZoneId` (a small alias
map or a links-complete dataset). No feature-side workaround exists — the raw
id never reaches the bloc.
Files: `app/lib/core/data/family_time.dart` (and/or the tz data source).
Blocks: no.

## 6. `NestListRow` has no custom `leading` slot and no title-colour override — OPEN (the last fork)

Need: two optional params on the shared row, both of which P16's design already
uses and both of which the row cannot express today.

**(a) `leading` widget.** The design's Family and Children rows carry a 32 px
avatar as the leading slot —
`<span class="avatar s32 a-leaf">S</span>` (`P16-settings.html:18-20, 24-25`),
avatar 32, 12 px gap, row min-height 56 (which a 32 leading leaves at 56: 32 +
20 padding < 56, so nothing shifts). `NestListRow` only builds its leading from
`leadingAsset` as a **40 px icon tile** (`NestTileTint`), so four rows (Sarah,
James, Maya, Leo) cannot use it. `NestQuestCard` already solves exactly this
with `final Widget? leading` + `?leadingWidget` in its `Row`
(`nest_quest_card.dart:41,61`) — the same two-line change in
`nest_list_row.dart` covers it.

**(b) danger title.** `.dangerlink { color:var(--danger); font-weight:700 }`
(`P16-settings.html:40`) for `Delete family account`; the shared row pins
`bodyStrong` w600 in `ink`. A `titleColor` (or `titleStyle`) override does it.

Measured cost of not having them: P16 keeps `SettingsRow`
(`presentation/widgets/settings_rows.dart`), a 100-line mirror of the shared
row's metrics that now has **one** job — the four avatar rows and the one
danger row. When (a) and (b) land, `SettingsRow` and its 4 call sites delete
and P16 uses `NestListRow` everywhere, like the 11 other shared-row screens.
Nothing blocks on this (the screen is correct and its tests are green); it is
fork debt, and every future design-system change to `NestListRow` silently
diverges from those five rows until it is paid.

Files: `app/lib/core/design_system/components/nest_list_row.dart`.
Blocks: no.

## 7. The 4pt grid has no 52 (`.linkrow` min-height) — OPEN, cosmetic

Need: `.linkrow { min-height:52px }` (`P16-settings.html:9`) has no token.
P16 uses a documented screen-local `const double _linkRowMinHeight = 52` in
`settings_view.dart`. `NestPager.stage` is also 52 but is a different metric
(P02's progress-stage circle), so reusing it would be a lie. One line in
`spacing.dart` (`static const double gap52 = 52;`, or a named
`NestLinkRow.minHeight`) would let the value move to the token layer.
Blocks: no.

## Also worth the orchestrator's attention (not requested here)

- Review 3: `app/test/features/today/today_view_test.dart` lines 525-526 are
  carried in `screen/P16` and asserted `find.text('P16 Settings')` on `main`.
  The branch's 2-line swap to `pushedPath(tester), '/settings'` 3-way merges
  into `main` with no conflict (verified), so the loop's merge delivers it; it
  does not need a separate batch. Flagged only so it is not reverted later.
- `5_ui` shared observation 4 (money tab icon differs from the design) is shell
  chrome and still unresolved.