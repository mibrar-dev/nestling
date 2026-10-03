import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/components/nest_list_row.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';

/// Tile art + tint for one reward (P14 `.icon-tile`).
///
/// The map keys are the `icon` strings `Seed.demo()` writes to the
/// `rewards` table (`app/lib/core/data/seed.dart`); the values follow the
/// `nestling_assets.dart` P14 annotations:
///
/// * `moon` → [NestIcons.clock] — the catalog names `clock` "Reward: stay up
///   15 min later (P14)" and `moon` the K08 glyph, so the P14 card paints the
///   clock the design draws.
/// * `plate` → [NestIcons.pizza] and `cake` → [NestIcons.chefHat] are the
///   closest glyphs in the 24 px line catalog.
///
/// Unknown strings (a reward created on another device) fall back to a
/// neutral gift tile rather than dropping the art slot.
class RewardIconSpec {
  const RewardIconSpec(this.asset, this.tint);

  final String asset;
  final NestTileTint tint;
}

const Map<String, RewardIconSpec> rewardIconSpecs = <String, RewardIconSpec>{
  'tv': RewardIconSpec(NestIcons.screenTime, NestTileTint.sky),
  'film': RewardIconSpec(NestIcons.film, NestTileTint.lilac),
  'moon': RewardIconSpec(NestIcons.clock, NestTileTint.peach),
  'cake': RewardIconSpec(NestIcons.chefHat, NestTileTint.coin),
  'coffee': RewardIconSpec(NestIcons.cafe, NestTileTint.leaf),
  'plate': RewardIconSpec(NestIcons.pizza, NestTileTint.leaf),
};

/// Neutral fallback tile (P14 §1): `NestIcons.gift` on `surface-2`/`ink`.
const RewardIconSpec rewardIconFallback = RewardIconSpec(
  NestIcons.gift,
  NestTileTint.neutral,
);

RewardIconSpec rewardIconSpec(String icon) =>
    rewardIconSpecs[icon] ?? rewardIconFallback;

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
}
