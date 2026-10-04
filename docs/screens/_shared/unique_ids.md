Unique ids: never derive a primary key from the clock.

BUG (P09 BUG-P09-14, read-only: ../nestling-screens/P09/docs/screens/P09/6_bugs.md lines 47-80): ids built as `'q-${appNowUtc().millisecondsSinceEpoch}'` collide whenever two inserts happen in the same millisecond. That always happens under the pinned test clock, and can happen in production on a fast double-tap or a restart. Drift throws a UNIQUE violation and the raw SQL error reaches the toast.
Same pattern on main (merged screens):
- app/lib/features/rewards/data/rewards_repository_impl.dart:64 `'reward-${clock.now()…millisecondsSinceEpoch}'`
- app/lib/features/family/data/family_repository_impl.dart:318 `'child-…'` and :446 `'coparent-…'`
DO:
1. Add a shared id generator in core (e.g. core/data/ids.dart): `newId(String prefix) => '$prefix-${uuid v4}'`, using the `uuid` package (add it to pubspec) or a crypto-random 128-bit hex. It must be unique regardless of the clock.
2. Replace every clock-derived id in app/lib (grep millisecondsSinceEpoch / microsecondsSinceEpoch used in ids) with newId. This task explicitly allows that mechanical edit in app/lib/features/** for rewards and family. Do NOT touch P09's unmerged branch: P09 adopts it itself.
3. Never show raw SQL / exception text to users. Where a repository insert can fail, map it to the screen's existing parent-safe error copy. Just report any place where raw exception text reaches a toast; don't redesign.
4. Tests:
   - Under the pinned clock, creating two rewards, two children and two co-parents in a row succeeds with distinct ids.
   - newId returns 10k distinct values.
5. Add to docs/screens/RULES.md: "Ids are newId(prefix) (uuid); never derive ids from the clock."
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/unique_ids_REPORT.md, committed.
