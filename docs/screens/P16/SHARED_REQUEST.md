# Shared request — P16 time-zone / settings shared items

Filed by the **stage-2 integrator**, not by a builder: review finding 3 asked for
a `SHARED_REQUEST.md` and none existed, and four "LEFT" items from
`FIXES_1.md` had no carrier. Docs only — no code in this branch depends on any
of it landing.

## 1. `NestToggle` / `NestListRow` cannot deliver a 44 px tap target (P16-T02, major)

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

## 2. `NestSectionLabel`'s 18 px line box vs the browser's natural line height

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

## 3. `NestCard` has no radius override

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

## 4. `members` has no email column (review 6)

Need: P16's owner row renders `sarah@example.co.uk` as hard-coded copy because
`members` is `id, familyId, name, role, inviteStatus` — there is nothing to
read. DATA-OVER-MOCKS cannot be honoured without the column. Either add
`members.email` (schema + seed) or agree a role-derived subtitle (e.g. `Owner`)
and drop the copy.
Files: `app/lib/core/data/` schema + migration, `Seed`, and P16's
`SettingsMemberEntry`/`watchMembers` (feature-owned, will follow).
Blocks: no.

## 5. IANA link ids are rejected by `isKnownZoneId` (P16-B09, minor)

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

## Also worth the orchestrator's attention (not requested here)

- Review 3: `app/test/features/today/today_view_test.dart` lines 525-526 are
  carried in `screen/P16` and asserted `find.text('P16 Settings')` on `main`.
  The branch's 2-line swap to `pushedPath(tester), '/settings'` 3-way merges
  into `main` with no conflict (verified), so the loop's merge delivers it; it
  does not need a separate batch. Flagged only so it is not reverted later.
- `5_ui` shared observation 4 (money tab icon differs from the design) is shell
  chrome and still unresolved.