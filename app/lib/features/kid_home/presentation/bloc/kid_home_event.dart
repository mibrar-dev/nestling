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

/// K01 selection consumed by the view (K01-BUG-3). The picker's
/// `BlocListener` dispatches this right after it starts the pushed route;
/// the bloc clears the pending `selectedProfileId` so tapping the SAME
/// tile after coming back emits a distinct state and navigates again.
/// Without it the re-selection is `==`-equal, the bloc drops it and the
/// tile looks dead. No-op when nothing is pending. The next home-stream
/// emission still clears as a backstop.
final class KidHomeSelectionHandled extends KidHomeEvent {
  const new();
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

/// K02 PIN submit. The view keeps the entered digits locally (max 4) and
/// dispatches this with the full 4-digit code; the bloc checks it via
/// `KidHomeRepository.verifyPin` and emits `pinPassed` or bumps
/// `pinWrongNonce`. NO navigation in the bloc — the view's `BlocListener`
/// pushes `/kid-home` on `pinPassed` false→true and clears + toasts on a
/// `pinWrongNonce` bump. Unlimited retries, no lockout (kind motivation).
final class KidHomePinSubmitted extends KidHomeEvent {
  const new({required this.childId, required this.pin});

  final String childId;
  final String pin;

  @override
  List<Object?> get props => <Object?>[childId, pin];
}
