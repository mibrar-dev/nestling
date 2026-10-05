import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';

sealed class KidJarEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class KidJarLoadRequested extends KidJarEvent {
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
