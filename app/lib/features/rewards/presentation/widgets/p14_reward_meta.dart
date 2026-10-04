import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/components/nest_list_row.dart';
import 'package:nestling/core/design_system/components/reward_icons.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';

/// Tile art + tint for one reward (P14 `.icon-tile`).
///
/// The ART is the shared single source `rewardIconFor` in
/// `core/design_system/components/reward_icons.dart` — exact `K08-shop.html`
/// `.k8-art` glyphs, kid wins where K08 and P14 disagree (see that file).
/// The TINT stays screen-private (P14 `.icon-tile tint-*`); K08 paints every
/// disc `coinTint`/`coinInk` instead.
///
/// Unknown strings (a reward created on another device) fall back to a
/// neutral gift tile rather than dropping the art slot.
class RewardIconSpec {
  const RewardIconSpec(this.asset, this.tint);

  final String asset;
  final NestTileTint tint;
}

const Map<String, NestTileTint> _rewardIconTints = <String, NestTileTint>{
  'tv': NestTileTint.sky,
  'film': NestTileTint.lilac,
  'moon': NestTileTint.peach,
  'cake': NestTileTint.coin,
  'coffee': NestTileTint.leaf,
  'plate': NestTileTint.leaf,
};

/// Legacy per-key art map, kept for backward compatibility (screen agents may
/// still import it). Values equal `rewardIconFor(key)` — the single source is
/// `rewardIconFor`; do not extend this map, add keys there instead.
final Map<String, RewardIconSpec> rewardIconSpecs = <String, RewardIconSpec>{
  for (final entry in _rewardIconTints.entries)
    entry.key: RewardIconSpec(rewardIconFor(entry.key), entry.value),
};

/// Neutral fallback tile (P14 §1): `NestIcons.gift` on `surface-2`/`ink`.
const RewardIconSpec rewardIconFallback = RewardIconSpec(
  NestIcons.gift,
  NestTileTint.neutral,
);

RewardIconSpec rewardIconSpec(String icon) {
  final tint = _rewardIconTints[icon];
  if (tint == null) return rewardIconFallback;
  return RewardIconSpec(rewardIconFor(icon), tint);
}

/// `aria-label` subject for each seeded row, copied verbatim from
/// `P14-rewards.html`'s `aria-label="Needs approval for …"` attributes.
///
/// The design shortens these (e.g. the row titled "Stay up 15 min later" is
/// announced as "staying up later"), so the mapping is keyed by reward id and
/// never derived from the title. Rows outside the seed fall back to the title.
const Map<String, String> rewardApprovalSubjects = <String, String>{
  'r-screen': 'screen time',
  'r-film': 'Friday film',
  'r-bedtime': 'staying up later',
  'r-baking': 'baking',
  'r-cafe': 'park cafe',
  'r-dinner': 'dinner',
};

/// Screen-reader label for a row's approval switch.
String rewardApprovalLabel(Reward reward) {
  final subject = rewardApprovalSubjects[reward.id];
  return 'Needs approval for ${subject ?? reward.title}';
}

/// Edit-button labels. Two rows are shortened by the design
/// (`aria-label="Edit Stay up later"` / `"Edit Trip to the park cafe"` — note
/// the ASCII "cafe" without the accent, unlike the visible row title), so
/// these are copied verbatim rather than composed from the title.
const Map<String, String> rewardEditLabels = <String, String>{
  'r-bedtime': 'Edit Stay up later',
  'r-cafe': 'Edit Trip to the park cafe',
};

String rewardEditLabel(Reward reward) =>
    rewardEditLabels[reward.id] ?? 'Edit ${reward.title}';

/// P14 screen copy. Characters are copied from
/// `design/html-source/screens/P14-rewards.html` (em dash U+2014, `é`
/// U+00E9) — never retyped.
abstract final class RewardCopy {
  const new _();

  static const String navTitle = 'Reward shop';

  static const String intro =
      'Things coins can buy — you decide. Children spend coins, never pounds.';

  static const String needsOkLabel = 'Needs my OK';
  static const String newReward = '+ New reward';
  static const String newRewardLabel = 'New reward';
  static const String editRewardLabel = 'Edit reward';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String confirmDelete = 'Confirm delete';
  static const String emptyTitle = 'No rewards yet';
  static const String emptyMessage =
      'Add something coins can buy — a film night, extra screen time, a trip out.';
  static const String tryAgain = 'Try again';
  static const String loadError = 'Something went wrong';

  // Editor sheet copy. The sheet has no design reference (the HTML and both
  // PNGs are the list screen), so these are the builder's own strings — kept
  // here with the rest of the screen copy so the whole file can be diffed
  // against the HTML in one place (stage 4, finding 5).
  static const String nameLabel = 'Name';
  static const String priceLabel = 'Price in coins';
  static const String decreasePrice = 'Decrease price';
  static const String increasePrice = 'Increase price';

  /// `= 50 p at payout` — the stepper's helper line.
  static String payoutHint(int coins) => '= $coins p at payout';

  /// Inline caption above Save when the write fails (plan §4): the friendly
  /// sentence first, then the technical detail. The raw exception never
  /// reaches the full-screen failure surface (`loadError`).
  static String saveError(Object error) => 'Could not save the reward: $error';

  /// Inline caption above the Delete button when the delete write fails.
  static String deleteError(Object error) =>
      'Could not delete the reward: $error';

  /// Toast for a failed write that has no surface of its own (a `Needs my OK`
  /// flip). Same wording as the reviewed `kid_home_view.dart` action failure.
  static const String actionFailed = 'Hmm, that did not work. Try again.';
}
