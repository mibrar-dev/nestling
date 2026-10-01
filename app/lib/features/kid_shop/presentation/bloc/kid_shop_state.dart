import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';

enum KidShopStatus { initial, loading, loaded, failure }

final class KidShopState extends Equatable {
  const new({
    this.status = KidShopStatus.initial,
    this.items = const <ShopReward>[],
    this.errorMessage,
  });

  final KidShopStatus status;
  final List<ShopReward> items;
  final String? errorMessage;

  KidShopState copyWith({
    KidShopStatus? status,
    List<ShopReward>? items,
    String? errorMessage,
  }) {
    return KidShopState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
