// P12 money formatting (`/money`) — the ledger's own copy helpers.
//
// The P12 history amounts are NOT rendered with the shared `NestMoney`
// widget: signs differ per ledger row type (a payout prints no sign, a spend
// prints U+2212, a bonus prints U+002B), so the glyph is part of the row's
// copy and is composed here instead of inside a shared component.

/// The design's minus sign — U+2212 MINUS SIGN (the `&minus;` in the P12
/// HTML source, `design/html-source/screens/P12-money.html`: `−£2.00`).
/// Never ASCII U+002D HYPHEN-MINUS.
const String kMoneyMinus = '−';

/// U+00B7 MIDDLE DOT, the P12 hero/row separator (`·`).
const String kMoneyDot = '·';

/// U+2014 EM DASH — the P12 goal title / footer dash, with single spaces.
const String kMoneyEmDash = '—';

/// `£4.20` — absolute value, two decimals, tabular at the call site.
String moneyPounds(int pence) => '£${(pence.abs() / 100).toStringAsFixed(2)}';

/// `+£3.00` — U+002B plus the absolute value.
String moneyPlus(int pence) => '+${moneyPounds(pence)}';

/// `−£2.00` — U+2212 minus plus the absolute value.
String moneyMinus(int pence) => '$kMoneyMinus${moneyPounds(pence)}';

/// `12p` — the quest-bonus subtitle (`+12p · Approved`).
String moneyPence(int pence) => '${pence.abs()}p';
