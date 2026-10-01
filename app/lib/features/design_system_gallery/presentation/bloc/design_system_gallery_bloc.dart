import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/design_system_gallery/domain/design_system_gallery_repository.dart';
import 'package:nestling/features/design_system_gallery/presentation/bloc/design_system_gallery_event.dart';
import 'package:nestling/features/design_system_gallery/presentation/bloc/design_system_gallery_state.dart';

class DesignSystemGalleryBloc
    extends Bloc<DesignSystemGalleryEvent, DesignSystemGalleryState> {
  new({required this._repository}) : super(const DesignSystemGalleryState()) {
    on<DesignSystemGalleryLoadRequested>(_onLoadRequested);
  }

  final DesignSystemGalleryRepository _repository;

  Future<void> _onLoadRequested(
    DesignSystemGalleryLoadRequested event,
    Emitter<DesignSystemGalleryState> emit,
  ) async {
    emit(state.copyWith(status: DesignSystemGalleryStatus.loading));
    try {
      final items = await _repository.getItems();
      emit(
        state.copyWith(status: DesignSystemGalleryStatus.loaded, items: items),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: DesignSystemGalleryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
