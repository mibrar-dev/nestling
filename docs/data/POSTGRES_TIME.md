# Nestling — Postgres time-zone DDL (Supabase, when the backend is set up)

Local-first rule (mirrors Drift schema v2 in `app/lib/core/data/`):
every event instant is `timestamptz` (UTC) + a `TEXT` IANA zone id column
stamped at write time; calendar rules are floating local values evaluated
in `families.time_zone`.

## Rules

1. **Event instants**: `timestamptz NOT NULL` (or nullable where the local
   column is nullable) + `<col>_tz TEXT NOT NULL DEFAULT 'Europe/London'`.
   Writers stamp the device zone when valid, else the family zone, else
   `'Europe/London'`. Validate with a lookup, never a fixed offset.
2. **Calendar rules**: `families.time_zone TEXT NOT NULL DEFAULT
   'Europe/London'`; quest `due_time_local TEXT NULL` (`HH:MM` wall-clock,
   no conversion); `payout_day SMALLINT` stays a floating weekday (1 = Mon).
3. **History renders in its stored `<col>_tz`**; "today / this week / payout
   day / due" use the CURRENT `families.time_zone`.
4. Never silently rewrite stored zones on a move — only future periods
   follow the new zone.

## Mirror DDL

```sql
-- Family zone (floating-rule anchor) + update audit.
alter table families
  add column if not exists time_zone text not null default 'Europe/London',
  add column if not exists updated_at timestamptz null,
  add column if not exists updated_at_tz text not null default 'Europe/London';

alter table settings
  add column if not exists time_zone text not null default 'Europe/London',
  add column if not exists updated_at timestamptz null,
  add column if not exists updated_at_tz text not null default 'Europe/London';

-- Floating local due time (HH:MM wall-clock, evaluated in families.time_zone).
alter table quests
  add column if not exists due_time_local text null;

-- Event instants + their write-time zones.
alter table quest_completions
  add column if not exists created_at_tz text not null default 'Europe/London',
  add column if not exists decided_at_tz text not null default 'Europe/London';

alter table ledger_entries
  add column if not exists date_tz text not null default 'Europe/London';

alter table reward_redemptions
  add column if not exists created_at_tz text not null default 'Europe/London';

alter table earned_badges
  add column if not exists earned_at_tz text not null default 'Europe/London';

alter table app_state
  add column if not exists trial_start_tz text not null default 'Europe/London';
```

## Migration notes (Supabase)

- Run the `ALTER TABLE`s in one migration; existing rows backfill to
  `'Europe/London'` via the column defaults (same as Drift v1 → v2).
- `timestamptz` columns keep storing UTC instants — do NOT convert existing
  `timestamp` values; if a column is `timestamp without time zone`, first
  verify every value is UTC, then `alter column … type timestamptz`.
- Future RLS/policies are unaffected (no policy reads clocks).
- Server-side writers (edge functions, cron payout reminders) must send
  `…_tz` explicitly; notification send-times are floating rules evaluated
  in the family's zone at fire time.
