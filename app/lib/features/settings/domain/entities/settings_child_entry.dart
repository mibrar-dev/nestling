import 'package:equatable/equatable.dart';

// One child row for P16 Settings (Children section): raw database values in
// creation order (Maya then Leo — CHILD ORDER ruling, never alphabetical).
// Display copy (en-dash age bands, "Pip: Fledgling") is the view's job.
class SettingsChildEntry extends Equatable {
  const new({
    required this.id,
    required this.nickname,
    required this.ageBand,
    required this.pipStageName,
    required this.coins,
    required this.avatarColour,
  });

  final String id;
  final String nickname;

  /// Raw band token (`7-9`); the view renders the en-dash (`7–9`).
  final String ageBand;

  /// Capitalised Pip stage (`Egg`, `Hatchling`, `Fledgling`, `Songbird`).
  final String pipStageName;
  final int coins;
  final String avatarColour;

  @override
  List<Object?> get props => <Object?>[
    id,
    nickname,
    ageBand,
    pipStageName,
    coins,
    avatarColour,
  ];
}

/// Capitalised Pip stage name for a stored `pip_stage` (1–4). Unknown values
/// fall back to `Fledgling` (the most common stage) rather than throwing.
String settingsPipStageName(int stage) => switch (stage) {
  1 => 'Egg',
  2 => 'Hatchling',
  3 => 'Fledgling',
  4 => 'Songbird',
  _ => 'Fledgling',
};
