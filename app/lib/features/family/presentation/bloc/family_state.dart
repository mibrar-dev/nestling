import 'package:equatable/equatable.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';

enum FamilyStatus { initial, loading, loaded, failure }

final class FamilyState extends Equatable {
  const new({
    this.status = FamilyStatus.initial,
    this.items = const <FamilyMember>[],
    this.errorMessage,
  });

  final FamilyStatus status;
  final List<FamilyMember> items;
  final String? errorMessage;

  FamilyState copyWith({
    FamilyStatus? status,
    List<FamilyMember>? items,
    String? errorMessage,
  }) {
    return FamilyState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
