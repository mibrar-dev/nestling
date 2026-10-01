import 'package:equatable/equatable.dart';

sealed class FamilyEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class FamilyLoadRequested extends FamilyEvent {
  const new();
}
