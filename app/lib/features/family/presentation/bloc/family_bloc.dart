import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  new({required this._repository}) : super(const FamilyState()) {
    on<FamilyLoadRequested>(_onLoadRequested);
  }

  final FamilyRepository _repository;

  Future<void> _onLoadRequested(
    FamilyLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(status: FamilyStatus.loading));
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: FamilyStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
