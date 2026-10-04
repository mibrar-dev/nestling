import 'package:equatable/equatable.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/features/settings/domain/entities/app_settings.dart';
import 'package:nestling/features/settings/domain/entities/settings_child_entry.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';
import 'package:nestling/features/settings/domain/entities/settings_member_entry.dart';

enum SettingsStatus { initial, loading, loaded, failure }

final class SettingsState extends Equatable {
  const new({
    this.status = SettingsStatus.initial,
    this.items = const <SettingsItem>[],
    this.settings,
    this.familyRoster = const <SettingsChildEntry>[],
    this.memberRows = const <SettingsMemberEntry>[],
    this.familyZoneId = defaultFamilyZoneId,
    this.pendingZone,
    this.dismissedZones = const <String>{},
    this.errorMessage,
  });

  final SettingsStatus status;

  /// Legacy placeholder rows (kept so the pre-redesign view compiles while
  /// the P16 UI builder replaces it).
  final List<SettingsItem> items;

  /// Live settings row (toggles, kid gate, subscription status).
  final AppSettings? settings;

  /// Children roster in creation order (Maya then Leo).
  final List<SettingsChildEntry> familyRoster;

  /// Family `members` rows in insertion order (Sarah then James).
  final List<SettingsMemberEntry> memberRows;

  /// Stored family zone id (`families.time_zone`, London default).
  final String familyZoneId;

  /// The device zone when it differs from the family zone and has not been
  /// dismissed this session — the one-time move banner input. Null means no
  /// banner.
  final String? pendingZone;

  /// Zones dismissed via "Not now" this session (bloc-local, never the DB).
  final Set<String> dismissedZones;

  final String? errorMessage;

  SettingsState copyWith({
    SettingsStatus? status,
    List<SettingsItem>? items,
    AppSettings? settings,
    List<SettingsChildEntry>? familyRoster,
    List<SettingsMemberEntry>? memberRows,
    String? familyZoneId,
    String? pendingZone,
    bool clearPendingZone = false,
    Set<String>? dismissedZones,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      settings: settings ?? this.settings,
      familyRoster: familyRoster ?? this.familyRoster,
      memberRows: memberRows ?? this.memberRows,
      familyZoneId: familyZoneId ?? this.familyZoneId,
      pendingZone: clearPendingZone ? null : (pendingZone ?? this.pendingZone),
      dismissedZones: dismissedZones ?? this.dismissedZones,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    settings,
    familyRoster,
    memberRows,
    familyZoneId,
    pendingZone,
    dismissedZones,
    errorMessage,
  ];
}
