import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_state.dart';

class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  new({required this._repository}) : super(const RewardsState()) {
    on<RewardsLoadRequested>(_onLoadRequested);
  }

  final RewardsRepository _repository;

  Future<void> _onLoadRequested(
    RewardsLoadRequested event,
    Emitter<RewardsState> emit,
  ) async {
    emit(state.copyWith(status: RewardsStatus.loading));
    await emit.forEach<List<Reward>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: RewardsStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: RewardsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
