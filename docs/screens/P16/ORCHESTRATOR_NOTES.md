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
