import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
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

/// K01 picker load. The picker route sends `KidHomeLoadRequested` (which
/// starts both subscriptions); this event restarts just the profiles
/// subscription — e.g. a profiles-only retry.
final class KidHomeProfilesRequested extends KidHomeEvent {
  const new();
}

/// K01 tile tap. The view dispatches it with the tapped profile; the bloc
/// persists the choice via `setActiveChild` and emits `selectedProfileId`
/// for the view's `BlocListener` to push on (`pinSet` → `/kid-pin`, else
/// `/kid-home`, extra `{'childId': id}`). NO navigation in the bloc.
final class KidHomeProfileSelected extends KidHomeEvent {
  const new({required this.childId, required this.pinSet});

  final String childId;
  final bool pinSet;

  @override
  List<Object?> get props => <Object?>[childId, pinSet];
}

/// Bloc-internal: a fresh emission from the profiles stream. Views never
/// send this; the bloc raises it from its own subscription so a reload can
/// guard on the live subscription instead of stacking handlers.
final class KidHomeProfilesReceived extends KidHomeEvent {
  const new(this.profiles);

  final List<KidChild> profiles;

  @override
  List<Object?> get props => <Object?>[profiles];
}

/// Bloc-internal: the profiles stream errored. Views never send this.
final class KidHomeProfilesFailed extends KidHomeEvent {
  const new(this.error);

  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
