import 'package:equatable/equatable.dart';

sealed class KidShopEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class KidShopLoadRequested extends KidShopEvent {
  const new();
}
