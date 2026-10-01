import 'package:equatable/equatable.dart';

sealed class PaywallEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class PaywallLoadRequested extends PaywallEvent {
  const new();
}
