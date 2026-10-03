Data model: a child's note on a quest completion (shown on P11 Approvals).

DESIGN: design/screens/light/P11-*.png and design/html-source/screens/P11-*.html. Each waiting card shows the child's quote under the meta line, e.g. Maya · Empty the dishwasher → "I stacked everything neatly!" and Leo · Make your bed → "I did the pillows too.". Cards without a note show no quote line.
PROBLEM: the `completions` table has no note column (only ledger_entries has `note`), so P11 cannot show the quotes.
DO:
1. Schema v6: add `completions.kid_note TEXT NULL` (nullable: no note means NULL), with a migration test (v5 → v6 keeps every row and kid_note is NULL).
2. Seed (_completionsDemo, ~line 336): set kid_note "I stacked everything neatly!" on maya/q-dishwasher pending and "I did the pillows too." on leo/q-bed pending. Leave q-table (Lay the table) without a note.
   - Use the exact typographic quotes and apostrophes as plain text. The UI adds the curly quote marks per the HTML: check whether the HTML puts the “ ” in the text or in CSS, and store accordingly. Document it in the report.
3. Expose kid_note in the core completion row and any core query P11 uses (grep app/lib/core/data for the pending-completions watcher). Do NOT edit feature code (P11 will adopt it).
4. Tests: the seed has the two notes; the migration test; the watcher returns kid_note.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/completion_note_REPORT.md (field name P11 must use, and the quote-mark decision), committed.
