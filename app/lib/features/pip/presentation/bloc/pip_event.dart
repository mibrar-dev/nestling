import 'package:equatable/equatable.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';

sealed class PipEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class PipLoadRequested extends PipEvent {
  const new();
}

/// Which K06 care button was tapped: feed (5 coins), play (free) or
/// bathe (3 coins). The bloc resolves the active child from the last
/// [PipNest] emission; taps with no active child are ignored.
enum PipCareKind { feed, play, bathe }

/// K06 care tap (Feed / Play / Bath). The stream re-emits the new profile
/// automatically; only a thrown write surfaces on the action-error channel.
final class PipCareRequested extends PipEvent {
  const new(this.kind);

  final PipCareKind kind;

  @override
  List<Object?> get props => <Object?>[kind];
}

/// K06 locked wardrobe tile tap (`scarf | sunhat | wellies | crown`).
/// Buys at the DB price when affordable; an unaffordable buy never touches
/// the DB and surfaces the kind "not enough coins" toast instead.
final class PipWardrobeBuyRequested extends PipEvent {
  const new(this.item);

  final String item;

  @override
  List<Object?> get props => <Object?>[item];
}

/// K06 owned wardrobe tile tap. `scarf` equips the scarf accessory,
/// `sunhat` equips the cap; `wellies`/`crown` have no accessory node and
/// change nothing (no DB write).
final class PipWardrobeEquipRequested extends PipEvent {
  const new(this.item);

  final String item;

  @override
  List<Object?> get props => <Object?>[item];
}

/// Bloc-internal: a fresh emission from the nest stream. Views
/// never send this; the bloc raises it from its own subscription so a
/// reload can guard on the live subscription instead of stacking handlers
/// (same K03-BUG-15 pattern as the kid_home bloc).
final class PipNestReceived extends PipEvent {
  const new(this.nest);

  final PipNest? nest;

  @override
  List<Object?> get props => <Object?>[nest];
}

/// Bloc-internal: the nest stream errored. Views never send this.
final class PipNestFailed extends PipEvent {
  const new(this.error);

  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
