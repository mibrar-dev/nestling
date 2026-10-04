import 'package:nestling/core/design_system/components/audience.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';

/// Shared reward glyphs — the single source for `rewards.icon` keys.
///
/// Each screen matches its OWN design (orchestrator audience ruling):
///
/// * kid (`NestAudience.kid`): exact `K08-shop.html` `.k8-art` glyphs
///   (`ic_reward_*`).
/// * parent (`NestAudience.parent`): exact `P14-rewards.html` glyphs —
///   `screenTime` (P14 TV `rect 2/4/20/13 rx 2`, 0.5 px from the K08 TV),
///   `film` (P14 play triangle `rect 3/5/18/14 rx 3 + m10 9…`),
///   `clock` (P14 clock `circle r 9 + M12 7v5l3 2`),
///   `chefHat` (P14 three-lobe hat, byte-identical to `ic_chef_hat.svg`
///   modulo syntax),
///   `rewardCoffeeParent` (P14 dome + box + legs, new file — neither the
///   K08 takeaway cup nor the old `ic_cafe.svg` sit-down mug matches it).
///
/// `plate` (Choose dinner) has only ONE design source: P14's HTML lists
/// five rewards then `+ New reward` (no dinner row), so K08's plain
/// triangle + three stroked dots is used for BOTH audiences.
///
/// P14 keeps its own per-key tile tints in
/// `features/rewards/presentation/widgets/p14_reward_meta.dart`; this map
/// owns the ART only. K08's art disc is always `coinTint`/`coinInk`, so it
/// needs no tint map.
///
/// Unknown keys (a reward created on another device) fall back to the
/// neutral gift glyph, matching the P14 fallback contract.
String rewardIconFor(String key, {required NestAudience audience}) {
  if (audience == NestAudience.parent) {
    return switch (key) {
      'tv' => NestIcons.screenTime,
      'film' => NestIcons.film,
      'moon' => NestIcons.clock,
      'cake' => NestIcons.chefHat,
      'coffee' => NestIcons.rewardCoffeeParent,
      'plate' => NestIcons.rewardPlate,
      _ => NestIcons.gift,
    };
  }
  return switch (key) {
    'tv' => NestIcons.rewardTv,
    'film' => NestIcons.rewardFilm,
    'moon' => NestIcons.rewardMoon,
    'cake' => NestIcons.rewardCake,
    'coffee' => NestIcons.rewardCoffee,
    'plate' => NestIcons.rewardPlate,
    _ => NestIcons.gift,
  };
}

/// Every `rewards.icon` key the demo seed writes.
const Set<String> rewardIconKeys = <String>{
  'tv',
  'film',
  'moon',
  'cake',
  'coffee',
  'plate',
};
