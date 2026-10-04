CRASH: an emoji (or other non-BMP) first character in a child's nickname crashes avatar initials across the app.

READ (read-only): ../nestling-screens/K02/docs/screens/K02/SHARED_REQUEST.md #3 (the full call-site table) and ../nestling-screens/K02/docs/screens/K02/3_test.md K02-TEST-BUG-A.
- `nickname[0].toUpperCase()` takes a UTF-16 code unit. For "🐝 Bee" that is an unpaired surrogate, and toUpperCase throws "string is not well-formed UTF-16". The whole frame fails (/who-is-playing, /kid-home, …).
- P05 Add children accepts such nicknames.
DO:
1. Add a shared helper in app/lib/core/design_system (e.g. `String nestAvatarInitial(String name)`) that returns the first GRAPHEME (package:characters, which Flutter already ships: `name.characters.first`), upper-cased only when that is safe (letters). Empty or whitespace-only names → '?' or the design's fallback.
2. Replace EVERY `name[0]` / `nickname[0]` / `.substring(0, 1)` initial in app/lib (grep it; SHARED_REQUEST #3 lists 7 sites across kid_home, family, settings, today, …) with the helper. This task explicitly allows that edit in merged feature code. Do NOT touch unmerged branches.
3. Input: P05's nickname field should still accept emoji (a valid nickname), so do NOT block it. Just make every display safe.
4. Tests:
   - The helper returns the right grapheme for "🐝 Bee", "Émile", "maya", "👨‍👩‍👧 Fam" (ZWJ sequence), "" and " ".
   - Widget tests: /who-is-playing and /kid-home render with a child named "🐝 Bee" (seed a temp DB row) without exceptions.
   - grep shows no remaining `[0]` initials.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/avatar_initial_REPORT.md, committed.
