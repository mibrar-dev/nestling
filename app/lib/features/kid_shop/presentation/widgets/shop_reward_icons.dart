import 'package:nestling/core/design_system/components/audience.dart';
import 'package:nestling/core/design_system/components/reward_icons.dart';

/// K08 card glyph per `Reward.icon` (the seed writes `tv`, `film`, `moon`,
/// `cake`, `coffee`, `plate`).
///
/// Thin forwarder to the SHARED `rewardIconFor(key, audience: kid)`
/// (`core/design_system/components/reward_icons.dart`, landed with
/// `shared/audience_glyphs` after iteration 1). The kid branch is the exact
/// `K08-shop.html` `.k8-art` set — `ic_reward_tv` / `ic_reward_film` /
/// `ic_reward_moon` / `ic_reward_cake` / `ic_reward_coffee` /
/// `ic_reward_plate` — which superseded this screen's earlier local map:
///
/// * `cake` used to map to `chefHat` (a chef's hat) where the design draws a
///   covered basket/bowl — the stage-4 UI check caught it (`icon_r2c2_bake`).
/// * `coffee` used to map to the old `cafe` sit-down mug (handle, steam,
///   saucer) where the design draws a domed takeaway cup — also caught by the
///   UI check (`icon_r3c1_cafe`).
/// * `film`, `moon` and `plate` now use the exact design drawings rather than
///   the old look-alikes (`filmStrip`, `moon`, `pizza`).
///
/// The parent P14 screen keeps its own audience branch via
/// `rewardIconFor(key, audience: NestAudience.parent)`; this forwarder exists
/// so the card has one call site and the audience is stated where it belongs
/// (kid).
String shopRewardIcon(String raw) =>
    rewardIconFor(raw, audience: NestAudience.kid);
