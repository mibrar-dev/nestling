# Shared completion_note — REPORT (branch `shared/completion_note`)

Scope: P11 approvals — child's note on a quest completion (the quote under
the meta line). Minimal, backward-compatible, additive only: one nullable
column + migration, two seed values, one new test file, three one-line
fixture stubs in older migration tests. No route/DI changes, no feature
presentation code touched. Screen branches merge without edits.

Evidence read first: `design/screens/light/P11-approvals.png`,
`design/html-source/screens/P11-approvals.html` (see quote-mark decision),
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/design/SPACING_SPEC.md`, `tools/screens/stages/common.md` (owner
rules), plus `app/lib/core/data/app_database.dart`, `seed.dart`,
`app/lib/features/approvals/data/approvals_repository_impl.dart` (P11
query), and the v4→v5 / v3→v4 / v2→v3 migration tests.

## Files changed

- `app/lib/core/data/app_database.dart` (+ regenerated
  `app_database.g.dart`) — `QuestCompletions.kidNote`
  (`text().nullable()`, SQL `quest_completions.kid_note TEXT NULL`),
  `schemaVersion` 5 → 6, v5 → v6 migration
  (`if (from < 6) await m.addColumn(questCompletions, ...)`). Nullable
  `ADD COLUMN` backfills existing rows to NULL, so no data migration.
- `app/lib/core/data/seed.dart` — `_completionsDemo` helper gains an
  optional `kidNote` positional (`[DateTime? decided, String? kidNote]`);
  `q-dishwasher`/`maya` pending inserts `I stacked everything neatly!`,
  `q-bed`/`leo` pending inserts `I did the pillows too.`, `q-table`
  omits the field (NULL → no quote line). All other completions NULL.
- Tests: new `app/test/core/data/completion_note_test.dart` (4 tests, see
  below); one-line `quest_completions` PK-only stubs in
  `children_order_test.dart` (v2 DDL), `quest_order_test.dart` (v3 DDL),
  `rewards_order_test.dart` (v4 DDL) — real v2–v4 databases always have
  the table and the v6 open now runs the v6 step on those fixtures (same
  rationale as the pre-v5 `rewards` table in those fixtures).
- `app/lib/features/approvals/**`: untouched (per task — P11 adopts the
  core field itself). No core query change was needed: P11's query is
  `AppDatabase.watchPendingApprovals` (`select(quest_completions) WHERE
  family_id + status = done_pending`), which returns the full
  `QuestCompletion` row, so `kidNote` flows through automatically.

## Field name P11 must use

- Dart: `QuestCompletion.kidNote` (`String?`).
- SQL: `quest_completions.kid_note` (`TEXT NULL`).
- Core stream: `AppDatabase.watchPendingApprovals(familyId)`
  (`app/lib/core/data/app_database.dart:521`) — returns
  `List<QuestCompletion>` with `kidNote` populated. P11 should read
  `c.kidNote` (NULL = hide the quote line).

## Quote-mark decision

- The HTML puts the curly quotes **inline in the text**, not in CSS:
  `<div class="qn">“I stacked everything neatly!”</div>`, and the only
  `.qn` rule (`.appr .qn{font-weight:700;...}`) sets font/spacing — no
  `content:` / `::before` / `::after` anywhere in `P11-approvals.html`,
  `tokens.css`, or `components.css` (grepped).
- Stored accordingly as **raw note text WITHOUT the surrounding “ ”**:
  `I stacked everything neatly!` and `I did the pillows too.` (plain
  ASCII; neither note contains an apostrophe, so no ’ question arises).
- P11 must render as `“$kidNote”` (U+201C … U+201D) and hide the `.qn`
  line entirely when `kidNote == null` (q-table case).

## Tests added (`app/test/core/data/completion_note_test.dart`)

1. `seed sets the two P11 quotes, q-table has no note` — dishwasher/maya
   and bed/leo carry the exact strings, table/maya is NULL.
2. `every other seeded completion has a NULL kid_note` — 12 rows total;
   only the two above are non-NULL.
3. `watchPendingApprovals returns kid_note (P11 query)` — the pending
   watcher returns the two notes + one NULL.
4. `v5 → v6 migration keeps every row and kid_note is NULL` — raw-sql v5
   DB (2 rows, `user_version = 5`) opens under v6: rows kept,
   status/coins intact, both `kidNote` NULL; a new write with `kidNote`
   then reads back.

## Follow-up screens must do

- **P11 must adopt `QuestCompletion.kidNote`**: map it into the approval
  card (suggest `kidNote` on `Approval`/`ApprovalModel`, or read the
  completion row directly), render `“$kidNote”` under the meta line, no
  quote line when NULL. Note the design HTML's third card
  (`Tidy your bedroom` / `Toys are all in the box.`) is illustrative —
  the seed's third pending is `q-table` with NULL, so P11 will show two
  quotes + one quoteless card until a note is added.
- No other screen needs changes. Future writers (e.g. K05 quest-complete
  input) can set `kidNote` via `QuestCompletionsCompanion(kidNote:
  Value(...))`; omitting it stays NULL.

Verification: `cd app && dart format .` clean (0 changed),
`flutter analyze` → `No issues found!`, `flutter test` → all 2136 pass.

VERDICT: PASS
