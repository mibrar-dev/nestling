Shared batch 6 (from P16 Settings). READ FIRST (read-only): ../nestling-screens/P16/docs/screens/P16/SHARED_REQUEST.md §1–§5, and ../nestling-screens/P16/docs/screens/P16/3_test.md §4 (the measured cost of each revert). Design: design/screens/light/P16-settings.png ÷3 and design/html-source (components.css + P16 HTML).

1. NestListRow with a NestToggle trailing (§1): the row must stay at the design height (56 for a one-line title + caption, per `.row`/`.list-row` CSS) while the toggle keeps a 44×44 tap target.
   - Today a 44-high trailing plus the row's 10 px padding grows the row to 64.
   - Let the trailing's hit area overhang the row padding (hit slop, like NestChip/NestToggle) instead of adding layout height.
   - Tests: row height 56 ±0.5 with a toggle; a tap 5 px above/below the track toggles it; semantics have the toggle action.
2. NestSectionLabel line box (§2): match the browser's natural line height for `.section-label` (13 px Inter w700, letter-spacing .78, no line-height set → 16 px line box at 1.0 per P16's measurement).
   - Change the shared style; check every merged screen that uses NestSectionLabel against its design PNG (grep), and update a merged test only when the new value equals its design. List each in the report.
3. NestCard radius and padding (§3): add optional `radius` and `padding` parameters (defaults unchanged). The P16 subcard needs radius 16 and padding 14/16 (vertical/horizontal), per the HTML; read the P16 HTML for the exact class.
4. members.email (§4): the parent's email must come from the DB.
   - Add `members.email TEXT NULL` in a schema v7 migration (with a migration test).
   - Seed the demo owner with "sarah@example.co.uk" and the co-parent (James) with NULL or the invite address per the design.
   - Expose it in the core member row / query that P16 uses.
5. isKnownZoneId and IANA links (§5, P16-B09): link ids such as `Europe/Belfast` and `GB` must resolve. The bundled tz data (latest_10y) lacks links, so either add a small canonical alias map or use the timezone package's links if available.
   - Test that `Europe/Belfast` → `Europe/London`, and that `Asia/Calcutta` is accepted (→ `Asia/Kolkata`).
Do NOT edit feature code. The report must say exactly what P16 must change: the revert list, the field names, and the NestCard params.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/shared_batch6_REPORT.md, committed.
