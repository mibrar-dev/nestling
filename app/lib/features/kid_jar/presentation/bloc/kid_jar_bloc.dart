import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_event.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_state.dart';

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
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: KidJarStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: KidJarStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
