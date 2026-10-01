import 'package:equatable/equatable.dart';

sealed class KidJarEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class KidJarLoadRequested extends KidJarEvent {
  const new();
}
