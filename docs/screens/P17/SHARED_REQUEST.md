# Shared request — P17 K03 tests still assert the placeholder gate title

Need: P17 replaced the v1 scaffold screen (`AppBar(title: Text('P17 Parental gate'))`,
`'No items yet'`) with the real gate (design copy `Grown-ups only`). Seven K03
(`kid_home`) tests still assert the scaffold string after tapping the lock, so
they now fail. They must assert real gate copy instead — e.g.
`find.text('Grown-ups only')` plus `find.text('Type the answer in numbers:')` —
which also proves the real gate rendered rather than a stub. P17 may not edit
`app/test/features/kid_home/**` (RULES §1), so this is orchestrator/K03 work.
Do NOT restore the placeholder title in the view: it is not design copy and it
would fail P17's own copy test.

Failing tests (all `app/test/features/kid_home/`):
- `k03_bugs_test.dart` — `performAction(tap) on the lock opens the gate` (line 1534)
- `k03_bugs_test.dart` — `K03-BUG-9: double-tapping the lock stacks two gate routes` (line 1062)
- `kid_home_view_test.dart` — `K03 navigation lock opens the parental gate` (line 1988)
- `kid_home_view_test.dart` — `K03 grown-ups lock (every kid state) loaded home: the lock opens the parental gate` (line 1242)
- `kid_home_view_test.dart` — `… loading state: the lock is reachable and opens the gate` (line 1258)
- `kid_home_view_test.dart` — `… failure state: the lock still opens the parental gate` (line 1274)
- `kid_home_view_test.dart` — `… no active child: the lock still opens the parental gate` (line 1289)

Failure text: `Expected: exactly one matching candidate / Actual:
_TextWidgetFinder:<Found 0 widgets with text "P17 Parental gate": []>`.

Files: `app/test/features/kid_home/k03_bugs_test.dart`,
`app/test/features/kid_home/kid_home_view_test.dart` (tests only — no product
code change needed anywhere).

Blocks: yes for `flutter test` on main once P17 lands; the P17 screen itself is
complete and its own 38 tests pass.
