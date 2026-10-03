import 'package:equatable/equatable.dart';

sealed class PaywallEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class PaywallLoadRequested extends PaywallEvent {
  const new();
}

final class PaywallTrialStarted extends PaywallEvent {
  const new();
}

final class PaywallRestoreRequested extends PaywallEvent {
  const new();
}
