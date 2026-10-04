import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/settings/domain/entities/app_settings.dart';
import 'package:nestling/features/settings/domain/entities/settings_child_entry.dart';
import 'package:nestling/features/settings/domain/entities/settings_member_entry.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_session_store.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_state.dart';

/// `GMT+4` / `GMT+0` label for [zoneId] at [nowUtc] (BST renders `GMT+1`).
/// The P16 time-zone row shows the short label plus this offset, e.g.
/// `Dubai (GMT+4)`. Half-hour zones render `GMT+5:30`.
String gmtOffsetLabel(String zoneId, DateTime nowUtc) {
  final minutes = toFamilyZone(nowUtc.toUtc(), zoneId).timeZoneOffset.inMinutes;
  final sign = minutes < 0 ? '-' : '+';
  final abs = minutes.abs();
  final hours = abs ~/ 60;
  final rest = abs % 60;
  if (rest == 0) return 'GMT$sign$hours';
  return 'GMT$sign$hours:${rest.toString().padLeft(2, '0')}';
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  new({
    required this._repository,
    required this._zoneService,
    SettingsSessionStore? sessionStore,
  }) : _sessionStore = sessionStore ?? _lookupSessionStore(),
       super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsNotificationsChanged>(_onNotificationsChanged);
    on<SettingsTimeZonePicked>(_onTimeZonePicked);
    on<SettingsMoveConfirmed>(_onMoveConfirmed);
    on<SettingsMoveDismissed>(_onMoveDismissed);
  }

  final SettingsRepository _repository;
  final FamilyZoneService _zoneService;

  /// Session-scoped dismissal store (P16-B02): every `/settings` visit builds
  /// a new bloc, but "Not now" hides the prompt for the whole session.
  final SettingsSessionStore _sessionStore;

  /// The DI-registered session store when present (the app and every
  /// `setUpTestScope` harness register one), otherwise a fresh store — so
  /// direct constructions in unit tests stay hermetic while route-built
  /// blocs share the session.
  static SettingsSessionStore _lookupSessionStore() {
    final sl = GetIt.instance;
    if (sl.isRegistered<SettingsSessionStore>()) {
      return sl<SettingsSessionStore>();
    }
    return SettingsSessionStore();
  }

  /// The route dispatches exactly one load event; its single `emit.forEach`
  /// subscription covers settings, the family zone, both roster streams and
  /// the one-shot move input (RULES §4: blocs subscribe with `emit.forEach`
  /// — never re-add load events to refresh).
  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    // Merge session dismissals first: a rebuilt bloc (new `/settings` visit)
    // inherits "Not now" zones from the session store (P16-B02).
    emit(
      state.copyWith(
        status: SettingsStatus.loading,
        dismissedZones: <String>{
          ...state.dismissedZones,
          ..._sessionStore.dismissedZones,
        },
      ),
    );
    await emit.forEach<List<dynamic>>(
      combineLatest3(
        combineLatest2(
          _repository.watchSettings(),
          _repository.watchFamilyTimeZone(),
        ),
        combineLatest2(_repository.watchRoster(), _repository.watchMembers()),
        _watchMoveInput(),
      ).transform(_closeOnError),
      onData: (parts) {
        final head = parts[0] as List<dynamic>;
        final roster = parts[1] as List<dynamic>;
        final settings = head[0] as AppSettings;
        final familyZoneId = head[1] as String;
        final move = parts[2] as ({String? device, String? pending});
        final visible =
            move.pending == null || state.dismissedZones.contains(move.pending)
            ? null
            : move.pending;
        // Built directly (not via copyWith) so the banner clears to null
        // explicitly; session dismissals are preserved across re-emits.
        return SettingsState(
          status: SettingsStatus.loaded,
          settings: settings,
          familyRoster: (roster[0] as List<SettingsChildEntry>).toList(),
          memberRows: (roster[1] as List<SettingsMemberEntry>).toList(),
          familyZoneId: familyZoneId,
          deviceZoneId: move.device,
          pendingZone: visible,
          dismissedZones: state.dismissedZones,
        );
      },
      onError: (error, _) => state.copyWith(
        status: SettingsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  // Write handlers never emit on success: the watched streams re-emit after
  // every write and the load subscription delivers the new state (house
  // pattern: RewardsBloc). Only the session-local dismiss emits — no stream
  // backs it, so nothing would re-emit on its behalf.
  Future<void> _onNotificationsChanged(
    SettingsNotificationsChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setNotifications(
      approvals: event.approvals,
      payout: event.payout,
      summary: event.summary,
    );
  }

  Future<void> _onTimeZonePicked(
    SettingsTimeZonePicked event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setFamilyTimeZone(event.zoneId);
  }

  Future<void> _onMoveConfirmed(
    SettingsMoveConfirmed event,
    Emitter<SettingsState> emit,
  ) async {
    await _zoneService.confirmPendingMove();
  }

  void _onMoveDismissed(
    SettingsMoveDismissed event,
    Emitter<SettingsState> emit,
  ) {
    _sessionStore.dismissedZones.add(event.zone);
    emit(
      state.copyWith(
        dismissedZones: <String>{...state.dismissedZones, event.zone},
        clearPendingZone: state.pendingZone == event.zone,
      ),
    );
  }

  /// One-shot device-zone read, re-evaluated against every family-zone
  /// emission. `device` is the raw device zone (the picker's first row,
  /// P16-B01) while `pending` is non-null only while it differs from the
  /// stored family zone (the banner input).
  Stream<({String? device, String? pending})> _watchMoveInput() async* {
    final device = await _zoneService.deviceZoneId();
    await for (final family in _zoneService.watchFamilyZone()) {
      yield (
        device: device,
        pending: device == null || device == family ? null : device,
      );
    }
  }
}

/// Errors are terminal: forward the first error, then close — otherwise the
/// failed load's watchers stay subscribed and every "Try again" leaks
/// another full set (same construction as P08-B08 in `today_bloc.dart`).
final _closeOnError =
    StreamTransformer<List<dynamic>, List<dynamic>>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        sink
          ..addError(error, stackTrace)
          ..close();
      },
    );
