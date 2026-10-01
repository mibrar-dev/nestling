import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_event.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_state.dart';

class BadgesBloc extends Bloc<BadgesEvent, BadgesState> {
  new({required this._repository}) : super(const BadgesState()) {
    on<BadgesLoadRequested>(_onLoadRequested);
  }

  final BadgesRepository _repository;

  Future<void> _onLoadRequested(
    BadgesLoadRequested event,
    Emitter<BadgesState> emit,
  ) async {
    emit(state.copyWith(status: BadgesStatus.loading));
    await emit.forEach<List<Badge>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: BadgesStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: BadgesStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
