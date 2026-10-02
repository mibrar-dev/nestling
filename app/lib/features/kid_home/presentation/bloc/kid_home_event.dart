import 'package:equatable/equatable.dart';

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
