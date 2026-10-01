import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';

enum KidJarStatus { initial, loading, loaded, failure }

final class KidJarState extends Equatable {
  const new({
    this.status = KidJarStatus.initial,
    this.items = const <JarEntry>[],
    this.errorMessage,
  });

  final KidJarStatus status;
  final List<JarEntry> items;
  final String? errorMessage;

  KidJarState copyWith({
    KidJarStatus? status,
    List<JarEntry>? items,
    String? errorMessage,
  }) {
    return KidJarState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
