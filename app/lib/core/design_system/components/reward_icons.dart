import 'package:nestling/core/design_system/components/nest_icon.dart';

/// Shared reward glyphs — the single source for `rewards.icon` keys.
///
/// Every seeded reward key (`Seed.demo` in `app/lib/core/data/seed.dart`:
/// `tv`, `film`, `moon`, `cake`, `coffee`, `plate`) resolves here to the
/// design's EXACT glyph, taken verbatim from
/// `design/html-source/screens/K08-shop.html` (`.k8-art`).
///
/// Where K08 and P14 disagree, the kid design wins (task ruling) and BOTH
/// screens use it — P14's parent cards adopt the K08 drawing:
///
/// * `tv`: same TV concept; K08 `rect 2.5/4/19/13 rx 2.5` vs P14
///   `rect 2/4/20/13 rx 2`. Trivial 0.5 px coord difference; kid wins.
/// * `film`: K08 film-strip (side sprockets) vs P14 play triangle.
///   Different concept; kid wins.
/// * `moon`: K08 crescent moon vs P14 clock (circle + hands).
///   Different concept; kid wins.
/// * `cake` (Baking together): K08 basket/bucket (arch handle + trapezoid
///   body + top tick) vs P14 three-lobe chef hat. Different object;
///   kid wins.
/// * `coffee` (park café): K08 takeaway cup (domed lid + tapered body, no
///   handle/steam/saucer) vs P14 dome + box + legs storefront/cloche.
///   Different drawing; kid wins. Neither matches the old `ic_cafe.svg`
///   sit-down mug (handle + steam + saucer) — that file is untouched.
/// * `plate` (Choose dinner): only K08 draws it — plain triangle + three
///   stroked outline dots. P14's HTML has no dinner row; the seed `plate`
///   key uses this K08 glyph on both screens. Distinct from the old
///   `ic_pizza.svg` (crust band + filled dots) — that file is untouched.
///
/// P14 keeps its own per-key tile tints in
/// `features/rewards/presentation/widgets/p14_reward_meta.dart`; this map
/// owns the ART only. K08's art disc is always `coinTint`/`coinInk`, so it
/// needs no tint map.
///
/// Unknown keys (a reward created on another device) fall back to the
/// neutral gift glyph, matching the P14 fallback contract.
String rewardIconFor(String key) {
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
