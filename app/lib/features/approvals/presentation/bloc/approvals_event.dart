import 'package:equatable/equatable.dart';

sealed class ApprovalsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class ApprovalsLoadRequested extends ApprovalsEvent {
  const new();
}
