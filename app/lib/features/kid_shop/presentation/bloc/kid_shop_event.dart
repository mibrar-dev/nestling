import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_shop/domain/entities/kid_shop_data.dart';

sealed class KidShopEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class KidShopLoadRequested extends KidShopEvent {
  const new();
}

/// Bloc-internal: a fresh emission from `watchActiveShop`. Views never send
/// this; the bloc raises it from its own subscription so a reload can guard
/// on the live subscription instead of stacking handlers.
final class KidShopDataReceived extends KidShopEvent {
  const new(this.data);

  final KidShopData data;

  @override
  List<Object?> get props => <Object?>[data];
}

/// Bloc-internal: the shop stream errored. Views never send this.
final class KidShopStreamFailed extends KidShopEvent {
  const new(this.error);

  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}

/// Kid "Get it" tap on an affordable card. The bloc guards unaffordable,
/// unknown and already-requesting ids (the unaffordable button is disabled in
/// the view; this is the backstop so a stray event never writes). NO
/// navigation in the bloc — the view toasts the one-shot notice via the
/// state's notice sequence and the coin pill/footer follow the stream.
final class KidShopRewardRequested extends KidShopEvent {
  const new(this.rewardId);

  final String rewardId;

  @override
  List<Object?> get props => <Object?>[rewardId];
}

/// The view's `BlocListener` showed the toast for the current notice, so the
/// bloc forgets it. No-op when nothing is pending.
final class KidShopNoticeShown extends KidShopEvent {
  const new();
}
