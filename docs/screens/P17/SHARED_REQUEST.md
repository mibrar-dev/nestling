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

---

# Shared request — P17 kid-mode + expired-trial redirect loop (/paywall ↔ /parental-gate)

Need: with the 14-day trial aged out (`AppSession.trialExpired == true`,
shared_batch3) in **kid mode**, `app/lib/app/router.dart` sends every
location to `/paywall`. `/paywall` is parent-only in kid mode, so the same
redirect sends it to `/parental-gate`; the gate then hits the trial-expired
branch again — `GoException: redirect loop detected /paywall =>
/parental-gate => /paywall`. The app renders go_router's error page
(`Page Not Found`), so kid mode cannot be used at all after expiry: the
gate, kid home and every kid route are stuck. Reproduced with the demo DB
row flipped to an aged trial in `P17-BUG-1` of
`app/test/features/parental_gate/p17_bugs_test.dart` (skip-marked;
unskipping shows the error-page text). `router.dart` is identical on `main`,
so this is live independent of P17.

Suggested fix (router.dart, shared): do not apply the paywall redirect in
kid mode (`if (!appMode.isKid && onboarded && session.trialExpired &&
location != PaywallRoutePaths.paywall) …`), or exempt
`ParentalGateRoutePaths.gate` from the trial-expired branch exactly as the
onboarding branch already exempts it. Kids cannot pay; the gate is the only
route to parent mode, where the paywall then fires correctly.

Files: `app/lib/app/router.dart` (shared — P17 may not edit under RULES §1).

Blocks: no — P17 lands with the proof skip-marked and the screen itself is
unaffected while the trial is live (demo seed is `active`).

---

# Shared request — P17 NestKeypad gaps do not match either design (24/16 vs the CSS grid)

Need: `NestKeypad` (`app/lib/core/design_system/components/nest_keypad.dart`)
hard-codes a 24 px **column** gap and a 16 px **row** gap. The CSS it mirrors
(`components.css:193`) is
`.keypad { display:grid; grid-template-columns: repeat(3,1fr); gap:10px;
padding:8px 24px 0; justify-items:center }`, so the rendered **column pitch is
container-driven** and the **row pitch is always 82** (72 + gap 10). Measured
from the design PNGs (÷3, ink bands):

| Design | key columns (x) | column pitch | key rows (y) | row pitch |
|---|---|---|---|---|
| P17 (`P17-parental-gate.png`, card content 302 wide) | 71 / 159 / 247 | **88** | 344 / 426 / 508 / 590 | **82** |
| K02 (`K02-pin.png`, wider container) | 77 / 159 / 241 | **82** | 393 / 475 / 557 / 639 | **82** |

`NestKeypad` produces column pitch 96 and row pitch 88 at every width, so it
matches **neither** screen. The in-code comment ("the K02/P17 renders this
fixes measure 24px columns / 16px rows") is not what those renders show.

Consequence on P17 (all measured, all in
`app/test/features/parental_gate/parental_gate_geometry_test.dart`, which now
pins the HTML pitches): keys drift +8 px horizontally on the outer columns,
+6 px per row; the card grows from the design's 712 px to 738 px, so the card
top sits 13 px high and `Back to Pip` + the caption land 26 px low.

Files: `app/lib/core/design_system/components/nest_keypad.dart` (shared — P17
may not edit under RULES §1).

Suggested fix: reproduce the CSS grid instead of a fixed gap — three equal
flex columns per row with the 72 px key centred (`Expanded` + `Center`, or
`Row` with `Expanded` children), row gap `NestSpacing.gap10` (10) and the
design's `padding: EdgeInsets.only(top: 8)`. That makes the column pitch fall
out of the available width, which is what P17 (88) and K02 (82) each need.

Blocks: yes for the P17 design pins in ORCHESTRATOR_NOTES items 5/2 — the card
cannot return to its 712 px design height while the keypad is 26 px too tall.
P17 can fix the screen-local half (anchor the card at the design top 66 and
restore the CSS vertical gaps) without this, but the keypad drift stays.
