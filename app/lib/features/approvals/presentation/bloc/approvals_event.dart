import 'package:equatable/equatable.dart';

sealed class ApprovalsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class ApprovalsLoadRequested extends ApprovalsEvent {
  const new();
}

final class ApprovalsApproveRequested extends ApprovalsEvent {
  const new({required this.completionId});

  final int completionId;

  @override
  List<Object?> get props => <Object?>[completionId];
}

final class ApprovalsNotYetRequested extends ApprovalsEvent {
  const new({required this.completionId});

  final int completionId;

  @override
  List<Object?> get props => <Object?>[completionId];
}

final class ApprovalsApproveAllRequested extends ApprovalsEvent {
  const new();
}

final class ApprovalsActionErrorConsumed extends ApprovalsEvent {
  const new();
}
