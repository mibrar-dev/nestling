# P16 Settings — time-zone setting + move prompt (for the P16 screen agent)

The shared `shared/family_time_zone` branch already landed the data layer.
P16 only needs to RENDER it — no schema or repository work.

## What exists (do not rebuild)

- `FamilyZoneService` (`app/lib/core/data/family_zone_service.dart`,
  registered in `app/lib/app/di.dart` as a lazy singleton):
  - `watchFamilyZone()` → `Stream<String>` of the stored family zone
    (`families.time_zone`, IANA id, London default).
  - `familyZoneId()` → one-shot read.
  - `pendingMove()` → `Future<String?>`: the device zone when it is known
    AND differs from the family zone; null otherwise. This is the ONLY
    trigger for the move prompt. The service NEVER switches silently.
  - `confirmPendingMove()` → stores the device zone (history keeps its
    stored zones; future periods follow the new zone).
  - `setFamilyTimeZone(id)` → stores a validated IANA id (unknown ids
    ignored). Mirrors into `settings.time_zone` + stamps `updatedAt`.
- `SettingsRepository.setFamilyTimeZone(zoneId)` /
  `watchFamilyTimeZone()` (same behaviour, for blocs already holding the
  settings repo).
- `shortZoneLabel(id)` in `family_time.dart`: `'Asia/Dubai'` → `'Dubai'`
  for display.

## What P16 must build

1. **Time-zone row** in Settings (next to payout day): title `Time zone`,
   detail = current family zone's short label + GMT offset note, e.g.
   `Dubai (GMT+4)`. Tapping opens a picker with a short curated list
   (`Europe/London`, `Asia/Dubai`, …) plus the device zone first when it
   differs. On pick → `setFamilyTimeZone(id)`.
2. **One-time move banner/prompt**: when `pendingMove()` returns non-null,
   show exactly once (until confirmed or dismissed for the session):
   `Looks like you're in Dubai now. Switch the family time zone? History
   keeps London times; future days follow Dubai. [Switch] [Not now]`.
   `Switch` → `confirmPendingMove()`. `Not now` → never auto-prompt again
   for that zone (keep local dismissal state in the bloc, not the DB).
3. **Copy rules**: never show raw IANA ids except in the picker subtitle;
   never switch without the confirm tap; kid mode never sees this setting.

## Test hooks (for P16 tests)

- Construct `FamilyZoneService(db, deviceZoneReader: () async => '…')`
  to fake the device zone without platform channels.
- `Seed.movedToDubai(db)` flips a seeded DB to Dubai without touching
  stored instants (mirror of `confirmPendingMove`).

## UPDATE (02:20, orchestrator QA of cmp_light_1, 3.58%)
The early subtitle ellipsis, the mid-row chevron and the ≈ 2 px taller rows are a SHARED NestListRow bug: trailing is `Flexible`, which halves the text width. shared/list_row_trailing is fixing it. Do not work around it locally. Once main has it (merged before your build), re-check that every row matches the design (rows at y 221/281/341…) and that subtitles are full. Fix the other local findings now.

## UPDATE (06:58) — iteration 3
1. Do NOT fork shared components. Revert `_P16Sect` to the shared `NestSectionLabel`, and the subcard to `NestCard`. If the shared label or card does not match the design, write SHARED_REQUEST.md with the measured numbers and the orchestrator will fix the shared one.
2. P16-T02: the switch must have a 44×44 tap target. NestToggle on main now has a 51×31 track plus hit slop, so give it room: no tight parent that clips the hit area. Prove taps 4 px outside the track toggle it.
3. Close P16-B08/B09 (un-skip them; they must pass).

## UPDATE (08:12) — iteration 4 (LAST pass)
1. Fix P16-B11 (switch alignment regression from iteration 3): the NestToggle track must sit at the design rect, using the shared NestToggle as-is with no offsets. Then fix B09 and B10, and un-skip all four proofs.
2. DATA OVER MOCKS: the parent's email must come from the DB (the signed-in parent / members table), not the hard-coded "sarah@example.co.uk". The seed holds that value. If the DB lacks a field, write SHARED_REQUEST.md.
3. The forks `_P16Sect`, the subcard and `SettingsRow` must use the shared NestSectionLabel / NestCard / NestListRow. If they really differ from the design, record the numbers in SHARED_REQUEST.md and keep the shared ones. Do not fork.
