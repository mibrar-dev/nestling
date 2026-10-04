import 'package:equatable/equatable.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

// One emission of Pip's nest (K06): the active child's Pip profile plus
// their wardrobe in design order (Scarf, Sun hat, Wellies, Crown — never
// alphabetical). Null (as a stream value, not this type) means kid mode
// has no active child yet.
class PipNest extends Equatable {
  const new({required this.profile, this.items = const <PipStage>[]});

  final PipProfile profile;
  final List<PipStage> items;

  /// Growth towards Songbird, 0…1 (175/250 = 0.7 in the demo seed).
  double get growthFraction {
    if (PipProfile.evolveAtCoins <= 0) return 0;
    return (profile.totalCoins / PipProfile.evolveAtCoins).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => <Object?>[profile, items];
}

/// Display name for a Pip stage. Pip's own copy — do NOT import the
/// kid_home/family helpers: 1 Egg, 2 Hatchling, 3 Fledgling, 4 Songbird.
String pipStageName(int stage) {
  return switch (stage) {
    1 => 'Egg',
    2 => 'Hatchling',
    4 => 'Songbird',
    _ => 'Fledgling',
  };
}
