import 'package:nestling/core/design_system/components/nest_icon.dart';

/// K08 card glyph per `Reward.icon` (the seed writes `tv`, `film`, `moon`,
/// `cake`, `coffee`, `plate`).
///
/// This map is deliberately SCREEN-PRIVATE and differs from the parent P14
/// `rewardIconSpecs` (`features/rewards/presentation/widgets/p14_reward_meta.dart`):
/// the K08 HTML draws the film-strip (side sprockets) and the crescent moon
/// for those two rewards, and `nestling_assets.dart` annotates
/// `NestlingIcons.filmStrip` / `NestlingIcons.moon` as the K08 glyphs. P14's
/// parent cards use `film` / `clock` instead. Both maps stay; unifying them
/// would break one screen's fidelity (documented in `1_plan.md` §a).
///
/// Fallback is `gift` (the generic reward glyph), matching the P14 fallback.
String shopRewardIcon(String raw) {
  return switch (raw) {
    'tv' => NestIcons.screenTime,
    'film' => NestIcons.filmStrip,
    'moon' => NestIcons.moon,
    'cake' => NestIcons.chefHat,
    'coffee' => NestIcons.cafe,
    'plate' => NestIcons.pizza,
    _ => NestIcons.gift,
  };
}
