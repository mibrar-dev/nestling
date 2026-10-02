# Nestling datetime storage — research decision

Date: 2026-10-02 · Scope: Drift/SQLite now, Supabase Postgres later · Current code: `app/lib/core/data/app_database.dart` (all timestamps UTC), `london_time.dart` (hard-coded Europe/London), `seed.dart`.

## 1. Production best practice (relocating families)

Three different things are routinely confused — store each differently:

- **Event instants** (something *happened*): store the **UTC instant + the IANA zone id where it happened**. The instant gives global ordering and "how long ago"; the zone id preserves what the clock on the wall said. A fixed offset (`+01:00`) is not a substitute: offsets change with DST and law, zone ids track the rules ([IANA theory](http://www.iana.org/time-zones/theory); [why abbreviations/offsets are ambiguous](https://www.workmate.com/blog/timezone-defaults-assumption-rules-expert-guide-2025)).
- **Calendar rules / floating times** ("reset at midnight", "due before 5pm", "payout Saturday"): store a **local wall-clock rule with no instant** (`HH:MM`, weekday, `daily/weekly`) and evaluate it in the family's *current* zone at read time. There is nothing to convert — "5pm" means 5pm wherever the family now lives ([store civil time + zone for wall-clock behaviour](https://prachub.com/resources/calendar-system-design-interview-guide-recurrence-time-zones-conflicts-and-notifications); [UTC-only breaks future times](https://codeopinion.com/just-store-utc-not-so-fast-handling-time-zones-is-complicated/)).
- **Pure dates** (birthdays): `DATE` with no time and no zone. Confirmed: Nestling has none today — `Children` carries only `ageBand`/`ageYears`, no birthdate column — so no action needed; use `DATE` if one is ever added.

The owner's instinct is correct and matches the industry pattern: **never store UTC alone for user-visible times; store UTC instant + original IANA zone id** ([discussion](https://www.reddit.com/r/programming/comments/toui47/saving_time_in_utc_doesnt_work_and_offsets_arent/); [SO best-practice thread](https://stackoverflow.com/questions/2532729/daylight-saving-time-and-time-zone-best-practices)). Never store a fixed offset as the region — `+01:00` cannot tell BST from CEST and goes stale on every rule change.

**DST edge cases (Europe/London).** BST 2026 runs 29 Mar 01:00 GMT → 25 Oct 02:00 BST ([GOV.UK](https://www.gov.uk/when-do-the-clocks-change), [RMG](https://www.rmg.co.uk/stories/time/uk-time-british-summer-time-bst-daylight-saving), [timeanddate](https://www.timeanddate.com/time/change/uk/london?year=2027)). Spring forward: local times 01:00–01:59 on 29 Mar **do not exist** — resolve by shifting forward to 02:00 (never silently back). Autumn back: 01:00–01:59 on 25 Oct **occur twice** — resolve by keeping the *first* occurrence (BST, pre-transition) for period membership and recording the offset actually used. All tz math must go through the IANA database, never the hand-rolled `isLondonSummerTime` in `london_time.dart` (correct for London-only, wrong the day the family leaves it).

**Postgres.** `timestamptz` stores an 8-byte UTC instant and converts at the session boundary; `timestamp` stores a wall-clock reading; **neither persists a zone string** ([Postgres docs](https://www.postgresql.org/docs/current/datatype-datetime.html), [monpg.app](https://monpg.app/blog/postgresql-timestamp-vs-timestamptz), [schemity](https://schemity.com/blog/postgres-timestamp-vs-timestamptz/)). So: `timestamptz` for every instant **plus** a `TEXT` column for the IANA id (`…_tz`, CHECK against a short allowlist or just validate in app code). Use plain `timestamp` only for floating rule times if they ever need a column; avoid `time with time zone` ([Postgres discourages it](https://www.postgresql.org/docs/current/datatype-datetime.html)).

**SQLite/Drift.** SQLite has no tz-aware type; Drift `DateTimeColumn` stores UTC (Unix epoch/millis; see [Drift datetime-migration guide](https://drift.simonbinder.eu/guides/datetime-migrations/) and known UTC/local footguns [#286](https://github.com/simolus3/drift/issues/286), [#3135](https://github.com/simolus3/drift/issues/3135)). Same pattern: UTC `DateTimeColumn` + adjacent `TEXT` zone column. Always insert `DateTime.now().toUtc()` / `TZDateTime.toUtc()`.

**Interchange.** Use RFC 9557 extended form `2026-10-03T09:00:00+01:00[Europe/London]` on API boundaries (offset for instant readability, bracketed IANA id as the authority) ([RFC 9557](https://www.rfc-editor.org/info/rfc9557/), [SO summary](https://stackoverflow.com/questions/42194571/identifying-time-zones-in-iso-8601)). Store the two halves in separate columns; reassemble for the wire.

## 2. Concrete Nestling data model

One new family setting drives everything shared: `families.time_zone TEXT NOT NULL DEFAULT 'Europe/London'` (Drift `text().withDefault(Constant('Europe/London'))`; Postgres `TEXT`). "Today / this week / payout day" are **always computed in `families.time_zone`**, never the device zone.

| Kind of time | Store (Drift → Postgres) | Rule on zone change |
|---|---|---|
| Completion `createdAt`, approval `decidedAt` | `DateTimeColumn` UTC + `created_tz` / `decided_tz` `TEXT` (default family zone at write) → `timestamptz` + `TEXT` | History row renders in its **stored** zone (`Sat 3 Oct, 8:12am BST`); period membership ("counts today?") uses **current** family zone |
| `ledger_entries.date` (+ payout batches) | `date` UTC + `entry_tz TEXT` → `timestamptz` + `TEXT` | Same as above; weekly owed/payout aggregates bucket by current family zone |
| `earned_badges.earnedAt`, `reward_redemptions.createdAt` | instant UTC + `…_tz TEXT` → `timestamptz` + `TEXT` | Display original local time; streaks/counts use current family zone |
| `app_state.trialStart` | instant UTC + `trial_tz TEXT` | Trial length is elapsed time (14 days from instant); *display* the start in stored zone, countdown in current zone |
| Daily reset / weekly Mon–Sun / `payoutDay` (int 1–7) / `due "before 5pm"` / notification times | No new instant. Add optional `due_time_local TEXT` (`HH:MM`, nullable) on `quests`; keep `repeatRule`, `days`, `payoutDay` as-is — they are already zone-agnostic rules | Evaluated in current `families.time_zone`: day bounds = midnight→midnight, week = Mon 00:00, payout = next `payoutDay` weekday, "before tea" = `due_time_local` on the zoned day |
| Birthdays | None exist (confirmed — no birthdate/DATE column). If added: `DATE`, no tz | N/A |

**London → Dubai example.** Family moves, `families.time_zone` becomes `Asia/Dubai` (UTC+4, no DST). A completion stored as `2026-10-03T07:12Z[Europe/London]` still displays "3 Oct, 8:12am BST" — history is immutable. But Saturday's quest period, payout-day countdown and "due before 5pm" now run on Dubai midnights: 5pm means 17:00 GST. **A period straddling the move is cut at the move instant**: completions before the move keep old-zone membership for display, while the *current* period is recomputed from the new zone's day/week start — the child never loses earned credit (rows are append-only), but "today" may legitimately show a short or long day once. Record the move itself as an event (`settings/family updated_at` instant) so support can explain the seam.

## 3. Device zone vs family zone

- **Source of truth is `families.time_zone`**, not any device. Read the device zone once via `FlutterTimezone.getLocalTimezone()` (see §4); if it parses as IANA and differs from the family zone, prompt once: *"You're in Asia/Dubai — move Nestling times to Dubai?"* Owner confirms → update `families.time_zone`. Never silently follow the device.
- **Multiple parents in different zones** (Mum in London, Dad travelling): shared periods still use the family zone, so both see the same "today" and payout day; per-event rows show their stored zone. Dad's completions are stamped with the device zone at write time (`created_tz`), not forced to London.
- **Kid device in another zone** (holiday tablet): identical rule — kid sees family-zone periods; taps are recorded as UTC + the device's zone id. No per-member zone column v1; add `members.preferred_tz` only if display personalisation is ever requested.
- Validate every incoming zone string with `getLocation()` before persisting; fall back to `families.time_zone`, then `Europe/London`, then UTC — never crash on an unknown id.

## 4. Flutter/Dart libraries (2026) and testing

- **`timezone` `^0.11.1`** — IANA database + `TZDateTime` (bundled tz data currently 2025c; variants `latest` / `latest_all` / `latest_10y`; refresh via `tool/refresh.sh`) ([pub.dev](https://pub.dev/packages/timezone)). This replaces all of `london_time.dart`'s arithmetic. Dependabot keeps it fresh; each IANA release is a version bump + test run, not code.
- **`flutter_timezone` `^5.1.0`** — maintained fork of `flutter_native_timezone` for reading the OS zone id on Android/iOS/macOS/Linux/Windows/Web ([pub.dev](https://pub.dev/packages/flutter_timezone)).
- Alternatives only if needed: `iana_time_zone` (lighter zone-id read), `timezone_provider`, `tz_datetime` / `easy_date_time` (smaller APIs), `time_machine2` (Noda-Time-style API with embedded tz data). Default to the two above; they are the boring, hireable choice and already cover Drift (`^2.35.1` in tree) + Supabase.
- **Testing DST and moves:** unit-test with pinned instants — 2026-03-29T00:30Z (pre-gap), 2026-03-29T01:30Z (gap), 2026-10-25T00:30Z/01:30Z (ambiguous hour) asserting gap-shifts-forward / first-occurrence; a London→Dubai move test asserting history display unchanged while `dayStart`/`weekStart`/payout shift; a Drift migration test (v1→v2) asserting backfilled `…_tz = 'Europe/London'`; golden-format tests (`Sat 3 Oct`, `8:12am`) extended with zone suffix.

## 5. Migration plan + implementation brief

**Migration (Drift v1 → v2):** `ALTER TABLE` each event table to add `…_tz TEXT NOT NULL DEFAULT 'Europe/London'`; add `families.time_zone` (default `'Europe/London'`) and `quests.due_time_local` (nullable); backfill existing rows to `'Europe/London'` (they were all London by construction). Mirror in Postgres migration (`timestamptz` + `TEXT`, `SET timezone = 'UTC'` server-side, convert at edge). `seed.dart`: stamp every `utc(…)` with its zone id and set `families.time_zone = 'Europe/London'`. Replace `london_time.dart` with `family_time.dart` (`toFamilyZone(instant, zone)`, `dayStartUtc`, `weekStartUtc`, `countsForCurrentPeriod`, `formatDay/Time` with zone label); keep old functions as `@deprecated` shims until callers migrate. Repositories (`pocket_money_repository_impl`, approvals, quests) write `toUtc() + familyZone` on every insert.

**Coding-agent brief:** (1) add `timezone` + `flutter_timezone` to `app/pubspec.yaml`; init tz db at startup (`latest_10y` to save ~75% size); (2) schema v2 + migration test; (3) `family_time.dart` + unit tests (DST gap/ambiguous, move, formatting); (4) family-zone setting UI (auto-detect prompt + manual IANA picker, owner-only); (5) update `seed.dart` + add zone-move fixture; (6) Postgres migration file mirroring Drift; (7) widget test: device zone ≠ family zone still shows family "today". Acceptance: all existing London tests pass unchanged (they are the `Europe/London` special case), new move tests pass, `london_time.dart` deleted.

## Recommendation

Approve the **UTC instant + IANA zone id on every event, floating local rules evaluated in a single `families.time_zone`, history immutable and future periods following the new zone**: it satisfies the owner's move-region requirement with the smallest possible schema change (one `TEXT` column per timestamp, one family setting), matches Postgres/tz best practice, and makes the London→Dubai story explainable to parents.

VERDICT: PASS
