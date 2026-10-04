import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';

enum KidShopStatus { initial, loading, loaded, failure }

final class KidShopState extends Equatable {
  const new({
    this.status = KidShopStatus.initial,
    this.childId = '',
    this.coins = 0,
    this.items = const <ShopReward>[],
    this.requestingIds = const <String>{},
    this.notice,
    this.noticeSeq = 0,
    this.errorMessage,
  });

  final KidShopStatus status;

  /// The active child the shop is showing ('' until the first stream
  /// emission, so a request can never fire without a resolved child).
  final String childId;

  /// The active child's current coin balance (drives the pill + footer).
  final int coins;

  /// Rewards in creation order with per-item affordability.
  final List<ShopReward> items;

  /// Ids with a `requestReward` write in flight — those cards show the
  /// button spinner. Also the double-tap guard.
  final Set<String> requestingIds;

  /// One-shot toast copy for the last completed request, consumed via
  /// `noticeSeq` by the view's `BlocListener` (then cleared by the
  /// notice-shown event). Survives stream emissions so a coin update
  /// landing mid-toast never swallows it.
  final String? notice;

  /// Bumps on every completed request so two identical notices are still
  /// distinct states: without it the second emit is `==`-equal and the view
  /// never toasts again.
  final int noticeSeq;

  final String? errorMessage;

  bool get isLoaded => status == KidShopStatus.loaded;

  KidShopState copyWith({
    KidShopStatus? status,
    String? childId,
    int? coins,
    List<ShopReward>? items,
    Set<String>? requestingIds,
    String? notice,
    int? noticeSeq,
    String? errorMessage,
  }) {
    return KidShopState(
      status: status ?? this.status,
      childId: childId ?? this.childId,
      coins: coins ?? this.coins,
      items: items ?? this.items,
      requestingIds: requestingIds ?? this.requestingIds,
      notice: notice ?? this.notice,
      noticeSeq: noticeSeq ?? this.noticeSeq,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Loaded emission from the shop stream. Built explicitly so a healthy
  /// emission also clears a stale load error; in-flight requests and the
  /// pending notice ride through untouched.
  KidShopState copyWithLoaded({
    required String childId,
    required int coins,
    required List<ShopReward> items,
  }) {
    return KidShopState(
      status: KidShopStatus.loaded,
      childId: childId,
      coins: coins,
      items: items,
      requestingIds: requestingIds,
      notice: notice,
      noticeSeq: noticeSeq,
    );
  }

  /// A request started: the card spins. The pending notice (if any) rides
  /// through — a second tap finishing while an earlier toast is unshown must
  /// not eat it.
  KidShopState copyWithRequestStarted(String rewardId) {
    return KidShopState(
      status: status,
      childId: childId,
      coins: coins,
      items: items,
      requestingIds: <String>{...requestingIds, rewardId},
      notice: notice,
      noticeSeq: noticeSeq,
      errorMessage: errorMessage,
    );
  }

  /// A request finished: the spinner stops and the toast copy is announced
  /// with a bumped [noticeSeq] so repeats are distinct states.
  KidShopState copyWithRequestFinished(String rewardId, String nextNotice) {
    final next = Set<String>.of(requestingIds)..remove(rewardId);
    return KidShopState(
      status: status,
      childId: childId,
      coins: coins,
      items: items,
      requestingIds: next,
      notice: nextNotice,
      noticeSeq: noticeSeq + 1,
      errorMessage: errorMessage,
    );
  }

  /// The view showed the toast: forget the copy, keep the sequence so the
  /// listener does not refire.
  KidShopState copyWithNoticeCleared() {
    return KidShopState(
      status: status,
      childId: childId,
      coins: coins,
      items: items,
      requestingIds: requestingIds,
      noticeSeq: noticeSeq,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    childId,
    coins,
    items,
    requestingIds,
    notice,
    noticeSeq,
    errorMessage,
  ];
}
