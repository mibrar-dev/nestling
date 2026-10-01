import 'package:equatable/equatable.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';

enum SettingsStatus { initial, loading, loaded, failure }

final class SettingsState extends Equatable {
  const new({
    this.status = SettingsStatus.initial,
    this.items = const <SettingsItem>[],
    this.errorMessage,
  });

  final SettingsStatus status;
  final List<SettingsItem> items;
  final String? errorMessage;

  SettingsState copyWith({
    SettingsStatus? status,
    List<SettingsItem>? items,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
