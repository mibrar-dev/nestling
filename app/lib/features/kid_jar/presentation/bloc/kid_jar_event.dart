import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';

sealed class KidJarEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class KidJarLoadRequested extends KidJarEvent {
  const new();
}

/// View event for K10: subscribe to the latest-payout celebration stream.
/// `payoutDayRoute` dispatches this INSTEAD of [KidJarLoadRequested].
final class KidJarPayoutRequested extends KidJarEvent {
  const new();
}

/// Internal: a [JarSnapshot] arrived on the live jar subscription. Re-enters
/// the bloc from the guarded subscription (K09-BUG-1, same shape as
/// K03-BUG-15); views must never dispatch it — [KidJarLoadRequested] is the
/// only view event.
final class KidJarSnapshotReceived extends KidJarEvent {
  const new(this.snapshot);

  final JarSnapshot snapshot;

  @override
  List<Object?> get props => <Object?>[snapshot];
}

/// Internal: the live jar subscription errored and was released. Views must
/// never dispatch it; retry via [KidJarLoadRequested].
final class KidJarStreamFailed extends KidJarEvent {
  const new(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Internal: a [PayoutCelebration] (or null = no payout yet) arrived on the
/// live payout subscription. Re-enters the bloc from the guarded subscription
/// (K09-BUG-1, same shape as K03-BUG-15); views must never dispatch it —
/// [KidJarPayoutRequested] is the only K10 view event.
final class KidJarPayoutReceived extends KidJarEvent {
  const new(this.celebration);

  final PayoutCelebration? celebration;

  @override
  List<Object?> get props => <Object?>[celebration];
}
