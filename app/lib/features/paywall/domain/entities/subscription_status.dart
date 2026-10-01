import 'package:equatable/equatable.dart';

// Trial/subscription state from `app_state`: `trial | active | expired`.
class SubscriptionStatus extends Equatable {
  const new({required this.status, required this.trialStart});

  final String status;
  final DateTime? trialStart;

  bool get expired => status == 'expired';

  @override
  List<Object?> get props => <Object?>[status, trialStart];
}
