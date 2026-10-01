import 'package:equatable/equatable.dart';
import 'package:nestling/features/design_system_gallery/domain/entities/design_system_item.dart';

enum DesignSystemGalleryStatus { initial, loading, loaded, failure }

final class DesignSystemGalleryState extends Equatable {
  const new({
    this.status = DesignSystemGalleryStatus.initial,
    this.items = const <DesignSystemItem>[],
    this.errorMessage,
  });

  final DesignSystemGalleryStatus status;
  final List<DesignSystemItem> items;
  final String? errorMessage;

  DesignSystemGalleryState copyWith({
    DesignSystemGalleryStatus? status,
    List<DesignSystemItem>? items,
    String? errorMessage,
  }) {
    return DesignSystemGalleryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
