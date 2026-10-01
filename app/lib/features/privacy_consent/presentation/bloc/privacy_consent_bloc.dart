import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_event.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_state.dart';

class PrivacyConsentBloc
    extends Bloc<PrivacyConsentEvent, PrivacyConsentState> {
  new({required this._repository}) : super(const PrivacyConsentState()) {
    on<PrivacyConsentLoadRequested>(_onLoadRequested);
  }

  final PrivacyConsentRepository _repository;

  Future<void> _onLoadRequested(
    PrivacyConsentLoadRequested event,
    Emitter<PrivacyConsentState> emit,
  ) async {
    emit(state.copyWith(status: PrivacyConsentStatus.loading));
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: PrivacyConsentStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: PrivacyConsentStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
