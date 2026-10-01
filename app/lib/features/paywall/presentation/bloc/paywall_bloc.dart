import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_state.dart';

class PaywallBloc extends Bloc<PaywallEvent, PaywallState> {
  new({required this._repository}) : super(const PaywallState()) {
    on<PaywallLoadRequested>(_onLoadRequested);
  }

  final PaywallRepository _repository;

  Future<void> _onLoadRequested(
    PaywallLoadRequested event,
    Emitter<PaywallState> emit,
  ) async {
    emit(state.copyWith(status: PaywallStatus.loading));
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: PaywallStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: PaywallStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
