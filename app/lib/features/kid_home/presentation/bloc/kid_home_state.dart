import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';

enum KidHomeStatus { initial, loading, loaded, failure }

final class KidHomeState extends Equatable {
  const new({
    this.status = KidHomeStatus.initial,
    this.items = const <KidQuest>[],
    this.errorMessage,
  });

  final KidHomeStatus status;
  final List<KidQuest> items;
  final String? errorMessage;

  KidHomeState copyWith({
    KidHomeStatus? status,
    List<KidQuest>? items,
    String? errorMessage,
  }) {
    return KidHomeState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
