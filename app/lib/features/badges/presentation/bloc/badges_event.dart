import 'package:equatable/equatable.dart';
import 'package:nestling/features/badges/domain/entities/badges_data.dart';

sealed class BadgesEvent extends Equatable {
  const BadgesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class BadgesLoadRequested extends BadgesEvent {
  const BadgesLoadRequested();
}

/// Bloc-internal: a fresh emission from `watchActiveBadges`. Views never send
/// this; the bloc raises it from its own subscription so a reload can guard
/// on the live subscription instead of stacking handlers.
final class BadgesDataReceived extends BadgesEvent {
  const BadgesDataReceived(this.data);

  final BadgesData data;

  @override
  List<Object?> get props => <Object?>[data];
}

/// Bloc-internal: the badges stream errored. Views never send this.
final class BadgesStreamFailed extends BadgesEvent {
  const BadgesStreamFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
