import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';

sealed class KidHomeEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class KidHomeLoadRequested extends KidHomeEvent {
  const new();
}

/// K03 check tap on a `to_do`/`not_yet` card. The stream re-emits and the
/// card flips to `done_pending`; [coins] is carried for the K05 extra.
final class KidHomeQuestCompleted extends KidHomeEvent {
  const new({
    required this.childId,
    required this.questId,
    required this.coins,
  });

  final String childId;
  final String questId;
  final int coins;

  @override
  List<Object?> get props => <Object?>[childId, questId, coins];
}

/// Bloc-internal (K03-BUG-15): a fresh emission from the home stream. Views
/// never send this; the bloc raises it from its own subscription so a reload
/// can guard on the live subscription instead of stacking handlers.
final class KidHomeDataReceived extends KidHomeEvent {
  const new(this.home);

  final KidHomeData home;

  @override
  List<Object?> get props => <Object?>[home];
}

/// Bloc-internal (K03-BUG-15): the home stream errored. Views never send this.
final class KidHomeStreamFailed extends KidHomeEvent {
  const new(this.error);

  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
