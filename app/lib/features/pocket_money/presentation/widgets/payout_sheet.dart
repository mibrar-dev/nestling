// P13 · payout sheet (`.pay`) — the feature-local bottom sheet for `/payout`.
//
// `NestBottomSheet` is deliberately NOT used here: its title is a left-aligned
// h3 with a close button and its max-height is 92 %, while the design's `.pay`
// is a 88 %-tall sheet with a centred 24/30 w900 title, a 40×5 grabber and no
// close affordance (`design/html-source/screens/P13-payout.html:3-15`).
//
// Every metric below is measured off `design/screens/light/P13-payout.png`
// (÷3) so the rendered rects match the design to the pixel:
//
// ```text
// 343  .pay top                          (= 844 − 501, bottom-anchored)
// +8  padding-top                        → 351
// +21 grabber block (4 margin + 5 pill + 12 margin) → 372
// +30 .pay h2 (Nunito 24/30 w900)        → 402
// +4  .pay .sub margin-top               → 406
// +20 .pay .sub (Inter 14/20)            → 426
// +14                                  → 440
// +76 child row 1 (14 + 48 check + 14) → 516
// +10                                  → 526
// +76 child row 2                     → 602
// +10                                  → 612
// +72 .saverow (14 + 44 + 14)         → 684
// +14                                  → 698
// +52 .btn-primary min-height         → 750
// +8                                   → 758
// +36 caption (13/18 × 2 lines)      → 794
// +50 padding-bottom (home-h + 16)   → 844
// ```
//
// The `.child` rows are 76 tall because the 48×48 `.check` IS the row's
// tallest item (the avatar is 44 and `.who` is 22 + 18) — the check must stay
// exactly 48 px or the row collapses to 72 and every card below it drifts.

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_pounds.dart';

/// `--r-xl` grabber pill: 40×5, `--line`, fully rounded.
class _PayoutGrabber extends StatelessWidget {
  const _PayoutGrabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `.pay::before { margin: 4px auto 12px }`.
      padding: const EdgeInsets.only(
        top: NestSpacing.s1,
        bottom: NestSpacing.s3,
      ),
      child: Center(
        child: Container(
          width: NestSpacing.s10,
          // `.pay::before { height: 5px }` — the same token the shared
          // `NestBottomSheet` grabber uses (review finding 8).
          height: NestSpacing.gap5,
          decoration: BoxDecoration(
            color: context.nest.line,
            borderRadius: NestRadii.allPill,
          ),
        ),
      ),
    );
  }
}

/// Full weekday names, index 0 = Monday. `families.payout_day` is 1…7 with
/// 6 = Saturday (the seeded default), so the label is
/// `kPayoutWeekdayNames[payoutDay - 1]`.
const List<String> kPayoutWeekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// The child the `.saverow` belongs to: the first child in creation order
/// that has a savings goal, or null when nobody has one (the row is hidden
/// and no money can move to savings).
String? payoutSaveChildId(MoneyLedgerData data) {
  for (final child in data.children) {
    if (data.goalFor(child.id) != null) return child.id;
  }
  return null;
}

/// `Saturday payout` — the design's `.pay h2` title. Out-of-range days fall
/// back to the first name instead of throwing (a hand-written fixture, never
/// the seeded database).
String payoutSheetTitle(int payoutDay) {
  final index = payoutDay - 1;
  if (index < 0 || index >= kPayoutWeekdayNames.length) {
    return '${kPayoutWeekdayNames.first} payout';
  }
  return '${kPayoutWeekdayNames[index]} payout';
}

/// `.pay` — grabber, `<Weekday> payout`, sub, one row per child (creation
/// order), the savings row and the CTA.
class PayoutSheet extends StatelessWidget {
  const PayoutSheet({
    required this.data,
    required this.ticked,
    required this.saveOn,
    required this.onToggled,
    required this.onSaveChanged,
    required this.onSubmit,
    this.busy = false,
    super.key,
  });

  final MoneyLedgerData data;

  /// Child ids whose cash the parent ticked as handed over.
  final Set<String> ticked;
  final bool saveOn;

  /// A payout write is in flight: the CTA is disabled and spins, so a second
  /// tap inside the Drift round-trip window cannot dispatch the same payout
  /// twice (P13-BUG-01 / review finding 2).
  final bool busy;

  /// Flips one child's ticked state. A `.check` button is a toggle, so the
  /// sheet never needs to know the new value.
  final ValueChanged<String> onToggled;
  final ValueChanged<bool> onSaveChanged;
  final VoidCallback onSubmit;

  /// The design-fixed £1.00 savings option (`.saverow`).
  static const int savingsMovePence = 100;

  /// First child in creation order that has a savings goal — the one the
  /// `.saverow` belongs to. Null when no child has a goal (row hidden).
  String? get saveChildId => payoutSaveChildId(data);

  /// The child behind the `.saverow` copy — the first child in creation
  /// order that has a savings goal. Null when no child has one (the row is
  /// then hidden).
  MoneyChild? get saveChild {
    final id = saveChildId;
    if (id == null) return null;
    return data.childById(id);
  }

  OwedSummary owedFor(String childId) =>
      data.owedFor(childId) ??
      OwedSummary(
        childId: childId,
        totalPence: 0,
        basePence: 0,
        questsPence: 0,
      );

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final title = payoutSheetTitle(data.payoutDay);
    final saveRowChild = saveChild;
    final canSubmit =
        !busy &&
        ticked.isNotEmpty &&
        ticked.any((id) => owedFor(id).totalPence > 0);

    return Semantics(
      // `role="dialog" aria-modal="true" aria-label="Saturday payout"`. The
      // label is NOT repeated here: the header text below is the single
      // announcement (review finding 9 — a container label plus a header
      // child announced "Saturday payout" twice on entry).
      container: true,
      explicitChildNodes: true,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.paper,
          borderRadius: NestRadii.topXl,
        ),
        // `.pay { padding: 8px 20px calc(home-h + 16px) }` — the bottom pad
        // runs the paper to the physical screen edge (owner bottom-edge
        // rule), so no coloured strip shows under the home indicator.
        padding: const EdgeInsets.fromLTRB(
          NestSpacing.padSide,
          NestSpacing.s2,
          NestSpacing.padSide,
          NestDevice.homeH + NestSpacing.s4,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFactor,
        ),
        child: SingleChildScrollView(
          // `.pay { max-height: 88% }` — at 320×568 / text scale 1.3 the
          // stack is taller than the sheet, so the body scrolls instead of
          // overflowing.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _PayoutGrabber(),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: _titleStyle(tokens.ink),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: NestSpacing.s1),
              Text(
                "Tick once you've handed over the cash",
                style: _subStyle(tokens.ink2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpacing.gap14),
              // Creation order (Maya, then Leo) — never alphabetical.
              for (var i = 0; i < data.children.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: NestSpacing.gap10),
                PayoutChildRow(
                  child: data.children[i],
                  owedPence: owedFor(data.children[i].id).totalPence,
                  ticked: ticked.contains(data.children[i].id),
                  avatarColour: _avatarColourFor(data, data.children[i].id, i),
                  onToggled: () => onToggled(data.children[i].id),
                ),
              ],
              if (saveRowChild != null) ...<Widget>[
                const SizedBox(height: NestSpacing.gap10),
                PayoutSaveRow(
                  child: saveRowChild,
                  goalTitle: data.goalFor(saveRowChild.id)?.title,
                  value: saveOn,
                  onChanged: onSaveChanged,
                ),
              ],
              const SizedBox(height: NestSpacing.gap14),
              // `.pay .btn-primary { min-height: 52px }` — the shared
              // `NestButton` default. `loading` disables it while the write is
              // in flight (P13-BUG-01) without changing the pill geometry.
              NestButton(
                label: 'Mark as paid & start the celebration',
                onPressed: canSubmit ? onSubmit : null,
                loading: busy,
              ),
              const SizedBox(height: NestSpacing.s2),
              Text(
                'Your children will see a payout celebration next time they'
                ' open Nestling.',
                style: NestType.caption(color: tokens.ink2),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `.pay { max-height: 88% }`.
  static const double _maxHeightFactor = 0.88;

  /// `.pay h2`: Nunito 24/30 w900. `h2` is the 22/28 w800 token, so the
  /// override is pinned at the call site (shared styles stay untouched).
  static TextStyle _titleStyle(Color ink) =>
      NestType.h2(color: ink)
          .copyWith(fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w900);

  /// `.pay .sub`: Inter 14/20 `--ink-2`.
  static TextStyle _subStyle(Color ink2) =>
      NestType.body(color: ink2).copyWith(fontSize: 14, height: 20 / 14);

  /// Avatar tint: the child's own `avatar_colour` from the setup (Maya
  /// lilac, Leo peach), falling back to the seeded creation-order palette
  /// when a hand-built fixture carries no setup.
  static NestAvatarColor _avatarColourFor(
    MoneyLedgerData data,
    String childId,
    int index,
  ) {
    final colour = data.setup?.childById(childId)?.avatarColour;
    if (colour != null && colour.isNotEmpty) return _avatarColor(colour);
    return index.isOdd ? NestAvatarColor.peach : NestAvatarColor.lilac;
  }

  static NestAvatarColor _avatarColor(String colour) {
    return switch (colour) {
      'lilac' => NestAvatarColor.lilac,
      'peach' => NestAvatarColor.peach,
      'sky' => NestAvatarColor.sky,
      'leaf' => NestAvatarColor.leaf,
      'coin' => NestAvatarColor.coin,
      _ => NestAvatarColor.neutral,
    };
  }
}

/// `.child` — 44 avatar, name + `Weekly + quests · £4.20`, 48×48 check.
class PayoutChildRow extends StatelessWidget {
  const PayoutChildRow({
    required this.child,
    required this.owedPence,
    required this.ticked,
    required this.avatarColour,
    required this.onToggled,
    super.key,
  });

  final MoneyChild child;
  final int owedPence;
  final bool ticked;
  final NestAvatarColor avatarColour;
  final VoidCallback onToggled;

  /// `.child .nm`: Inter 16/22 w700 — a call-site 22 px line box on top of
  /// `bodyStrong` (16/24).
  static TextStyle _nameStyle(Color ink) =>
      NestType.bodyStrong(color: ink).copyWith(height: 22 / 16);

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final name = child.nickname;
    return Container(
      // `.child { background: surface; border-radius: r-m; padding: 14px }`.
      // `NestCard` is fixed at `--r-l` (24), so the row is built from tokens
      // directly — same surface + `--sh-1`, `--r-m` radius.
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        boxShadow: tokens.cardShadow,
      ),
      padding: const EdgeInsets.all(NestSpacing.gap14),
      child: Row(
        children: <Widget>[
          // `.avatar.s44` — `NestAvatar`'s default size.
          NestAvatar(initial: nestAvatarInitial(name), color: avatarColour),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  style: _nameStyle(tokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: 'Weekly + quests $kMoneyDot ',
                        style: NestType.caption(color: tokens.ink2),
                      ),
                      TextSpan(
                        text: moneyPounds(owedPence),
                        // `.child .who .caption` holds a `<span class="money">`:
                        // 13 px bold tabular, `--ink-2`, INLINE after the
                        // middle dot. The page rule `.child .am { font-size:
                        // 18px }` belongs to markup this screen never emits,
                        // and the design PNG agrees — the rendered digits are
                        // 9.4 px tall (a 13 px cap) in the caption's
                        // `--ink-2`, not 18 px in `--ink`. Rendering it as a
                        // separate 18 px number also made the `.who` block
                        // 44 tall instead of 40, which pushed the name and the
                        // subtitle 2 px above the design's centred position.
                        style: NestType.money(color: tokens.ink2)
                            .copyWith(fontSize: 13, height: 18 / 13),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          PayoutCheck(name: name, ticked: ticked, onToggled: onToggled),
        ],
      ),
    );
  }
}

/// `.saverow` — "Move £1.00 of Maya's to their Lego Friends set fund" +
/// `NestToggle`.
class PayoutSaveRow extends StatelessWidget {
  const PayoutSaveRow({
    required this.child,
    required this.value,
    required this.onChanged,
    this.goalTitle,
    super.key,
  });

  final MoneyChild child;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// The child's savings-goal title from the database (Maya: "Lego Friends
  /// set"). Null in hand-built fixtures with no goal row. Interpolated
  /// verbatim — DATA OVER MOCKS decides the exact noun.
  final String? goalTitle;

  /// `.saverow .t` copy.
  ///
  /// Orchestrator decision (23:25) — after P13-I2-01 / P13-BUG-06, there is
  /// ONE ungendered, data-driven sentence for every goal-bearing child: the
  /// child is named, then the database's own goal title is interpolated
  /// verbatim. The design's "… to her Lego fund" hard-codes a feminine
  /// pronoun and must never leak into product code branching on seed ids
  /// (there is no gender column in the database to derive it from). A
  /// whitespace-only or missing title reads as plain savings.
  static String label(String name, String? goalTitle) {
    final amount = moneyPounds(PayoutSheet.savingsMovePence);
    final title = goalTitle?.trim() ?? '';
    if (title.isEmpty) {
      return "Move $amount of $name's money to savings";
    }
    return "Move $amount of $name's to their $title fund";
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final name = child.nickname;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        boxShadow: tokens.cardShadow,
      ),
      padding: const EdgeInsets.all(NestSpacing.gap14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label(name, goalTitle),
              // `.saverow .t`: Inter 15/22 w600 — `bodySmallStrong` exactly.
              style: NestType.bodySmallStrong(color: tokens.ink),
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          NestToggle(
            value: value,
            onChanged: onChanged,
            semanticLabel: "Move one pound of $name's money to savings",
          ),
        ],
      ),
    );
  }
}

/// `.check` — 48×48, `--r-m` (14) radius, 2 px border, filled `--leaf` when
/// ticked and `--surface`/`--line` when not.
///
/// The 24 px tick stays mounted in both states (tinted `--surface` on
/// `--surface` when unticked, exactly the CSS's `color: transparent`) so the
/// button's rect can never change between ticks.
class PayoutCheck extends StatelessWidget {
  const PayoutCheck({
    required this.name,
    required this.ticked,
    required this.onToggled,
    super.key,
  });

  /// The child's display name, used for the `'{name} paid in cash'` label.
  final String name;
  final bool ticked;

  /// Flips the ticked state (a `.check` is a toggle, never a setter).
  final VoidCallback onToggled;

  /// `.check { width: 48px; height: 48px; min-width: 48px }` — the row's
  /// height driver (see the file header).
  static const double size = 48;

  /// `.check { border-radius: 14px; border: 2px solid }`.
  static const double radius = 14;
  static const double borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final toggle = onToggled;
    return Semantics(
      container: true,
      button: true,
      checked: ticked,
      enabled: true,
      label: '$name paid in cash',
      onTap: toggle,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: toggle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: ticked ? tokens.leaf : tokens.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: ticked ? tokens.leaf : tokens.line,
              width: borderWidth,
            ),
          ),
          child: Center(
            // 24 px is `NestIcon`'s default size.
            child: NestIcon(
              NestIcons.check,
              // `.check { color: var(--surface) }` when ticked and
              // `transparent` when not — `surface` on a `surface` fill is
              // the token-only way to spell "invisible", and it flips with
              // the palette in dark mode.
              color: tokens.surface,
            ),
          ),
        ),
      ),
    );
  }
}
