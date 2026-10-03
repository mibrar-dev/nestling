import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

sealed class FamilyEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class FamilyLoadRequested extends FamilyEvent {
  const new();
}

final class FamilyDraftChanged extends FamilyEvent {
  const new({this.nickname, this.ageBand, this.avatarColour});

  final String? nickname;
  final String? ageBand;
  final String? avatarColour;

  @override
  List<Object?> get props => <Object?>[nickname, ageBand, avatarColour];
}

final class FamilyAddChildRequested extends FamilyEvent {
  const new({required this.onSaved});

  final VoidCallback onSaved;

  @override
  List<Object?> get props => <Object?>[onSaved];
}

final class FamilyRemoveChildRequested extends FamilyEvent {
  const new({required this.childId});

  final String childId;

  @override
  List<Object?> get props => <Object?>[childId];
}
