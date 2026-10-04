import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_event.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_state.dart';

/// K09 is read-only: a single load subscribes to [KidJarRepository.watchJar]
/// and every snapshot emission replaces the state. Retry re-adds
/// [KidJarLoadRequested]; `emit.forEach` cancels the prior subscription.
class KidJarBloc extends Bloc<KidJarEvent, KidJarState> {
  new({required this._repository}) : super(const KidJarState()) {
    on<KidJarLoadRequested>(_onLoadRequested);
  }

  final KidJarRepository _repository;

  Future<void> _onLoadRequested(
    KidJarLoadRequested event,
    Emitter<KidJarState> emit,
  ) async {
    emit(state.copyWith(status: KidJarStatus.loading));
    await emit.forEach<JarSnapshot>(
      _repository.watchJar(),
      onData: (snapshot) => state.copyWithLoaded(
        childId: snapshot.childId,
        items: snapshot.items,
        owedPence: snapshot.summary.owedPence,
        goalTitle: snapshot.summary.goalTitle,
        goalSavedPence: snapshot.summary.goalSavedPence,
        goalTargetPence: snapshot.summary.goalTargetPence,
        nextPayoutDay: snapshot.summary.nextPayoutDay,
      ),
      onError: (error, _) => state.copyWith(
        status: KidJarStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
