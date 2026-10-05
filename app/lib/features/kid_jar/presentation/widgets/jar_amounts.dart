/// K09 money formatting — the only kid screen that shows real pounds
/// (`docs/screens/RULES.md` §4).
///
/// The database stores integer pence; the history row's own amount string is
/// the domain's `formatJarAmount`
/// (`domain/entities/jar_snapshot.dart`), and
/// this file holds only the two "£x.xx" figures the design writes on their own
/// — the hero amount (`K09-jar.html:68`) and the goal's saved / target / left
/// figures (`:76-77,80`).
///
/// Both always print two decimals (`toStringAsFixed(2)`): the design shows
/// `£4.20` and `£9.49` side by side, so a pence amount never drops a zero.
library;

/// `£4.20` from 420 pence; `£9.49` from 949.
String jarPounds(int pence) => '£${(pence.abs() / 100).toStringAsFixed(2)}';
