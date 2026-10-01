import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_event.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_state.dart';

class KidShopBloc extends Bloc<KidShopEvent, KidShopState> {
  new({required this._repository}) : super(const KidShopState()) {
    on<KidShopLoadRequested>(_onLoadRequested);
  }

  final KidShopRepository _repository;

  Future<void> _onLoadRequested(
    KidShopLoadRequested event,
    Emitter<KidShopState> emit,
  ) async {
    emit(state.copyWith(status: KidShopStatus.loading));
    await emit.forEach<List<ShopReward>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: KidShopStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: KidShopStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
