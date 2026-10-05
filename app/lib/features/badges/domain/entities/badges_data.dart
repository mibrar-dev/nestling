import 'package:equatable/equatable.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart';

// One emission of the K11 badges stream
// (`BadgesRepository.watchActiveBadges`): the active child plus their badge
// shelf in DB insertion order (never sorted) with the happy-week count
// (0..7, a stored count — no period math on this screen, no clock use).
class BadgesData extends Equatable {
  const BadgesData({
    required this.childId,
    required this.items,
    required this.happyDays,
  });

  final String childId;
  final List<Badge> items;
  final int happyDays;

  @override
  List<Object?> get props => <Object?>[childId, items, happyDays];
}
