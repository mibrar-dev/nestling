import 'package:nestling/features/pip/domain/entities/pip_profile.dart';

// K05 growth maths (pure): lifetime coins → remaining / fraction / copy.
//
// The threshold is canonical ([PipProfile.evolveAtCoins], 250) — never a
// hard-coded design number, and never `DateTime.now()` (no clock needed:
// a static celebration plus DB values). The next-stage NAME
// (`Next: Songbird`) comes from `pipStageName` in the UI layer's
// `kid_style_helpers.dart`; this file stays in the domain layer so it never
// imports presentation.

/// Coins still needed to reach Songbird, clamped to `0..evolveAtCoins`.
int kidPipCoinsRemaining(int totalCoins) =>
    (PipProfile.evolveAtCoins - totalCoins).clamp(0, PipProfile.evolveAtCoins);

/// Growth progress as `0.0..1.0` (Maya's 175 → 0.7).
double kidPipGrowthFraction(int totalCoins) =>
    (totalCoins / PipProfile.evolveAtCoins).clamp(0.0, 1.0);

/// Growth-card headline. Seed values (Maya 75, Leo 190) take the plural
/// path; the singular (`1 more coin`) is correct English for completeness.
String kidPipGrowthCopy(int totalCoins) {
  final remaining = kidPipCoinsRemaining(totalCoins);
  if (remaining == 0) return 'Pip is ready to grow!';
  return 'Pip needs $remaining more coin${remaining == 1 ? '' : 's'} to grow';
}

/// Count line under the headline (`175 of 250 coins`).
String kidPipGrowthCount(int totalCoins) =>
    '$totalCoins of ${PipProfile.evolveAtCoins} coins';
