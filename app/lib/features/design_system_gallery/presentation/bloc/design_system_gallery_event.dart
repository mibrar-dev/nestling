import 'package:equatable/equatable.dart';

sealed class DesignSystemGalleryEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class DesignSystemGalleryLoadRequested extends DesignSystemGalleryEvent {
  const new();
}
