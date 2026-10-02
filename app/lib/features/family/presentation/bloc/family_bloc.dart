import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  new({required this._repository}) : super(const FamilyState()) {
    on<FamilyLoadRequested>(_onLoadRequested);
    on<FamilyDraftChanged>(_onDraftChanged);
    on<FamilyAddChildRequested>(_onAddChildRequested);
  }

  final FamilyRepository _repository;

  /// The route dispatches exactly one load event; its single `emit.forEach`
  /// subscription covers both the members and the children roster (RULES §4:
  /// blocs subscribe with `emit.forEach` — never re-add load events).
  Future<void> _onLoadRequested(
    FamilyLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(status: FamilyStatus.loading));
    await emit.forEach<List<dynamic>>(
      combineLatest2(
        _repository.watchItems(),
        _repository.watchChildren(),
      ).transform(_closeOnError),
      onData: (parts) => state.copyWith(
        status: FamilyStatus.loaded,
        items: (parts[0] as List<FamilyMember>).toList(),
        children: (parts[1] as List<FamilyChild>).toList(),
      ),
      onError: (error, _) => state.copyWith(
        status: FamilyStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  void _onDraftChanged(FamilyDraftChanged event, Emitter<FamilyState> emit) {
    var next = state.copyWith(
      draftNickname: event.nickname ?? state.draftNickname,
      draftAgeBand: event.ageBand ?? state.draftAgeBand,
      draftAvatarColour: event.avatarColour ?? state.draftAvatarColour,
    );
    if (event.nickname != null) {
      next = next.copyWith(nicknameError: null);
    }
    emit(next);
  }

  Future<void> _onAddChildRequested(
    FamilyAddChildRequested event,
    Emitter<FamilyState> emit,
  ) async {
    // P05-BUG-2: the button disables one frame after the bloc emits, so two
    // taps in the same frame both reach this handler. The second save is a
    // no-op while the first is in flight.
    if (state.saveInProgress) return;
    final nickname = state.draftNickname.trim();
    if (nickname.isEmpty) {
      emit(state.copyWith(nicknameError: 'Give them a nickname'));
      return;
    }
    if (nickname.length > 24) {
      emit(state.copyWith(nicknameError: 'Keep it under 24 characters'));
      return;
    }
    emit(state.copyWith(saveInProgress: true, nicknameError: null));
    try {
      await _repository.addChild(
        nickname: nickname,
        ageBand: state.draftAgeBand,
        avatarColour: state.draftAvatarColour,
      );
      // The roster stream emits the new card on its own. P05-BUG-5: only
      // clear the nickname draft when it still holds the saved nickname —
      // typing that started mid-save belongs to the next child.
      final typedMore = state.draftNickname.trim() != nickname;
      emit(
        state.copyWith(
          saveInProgress: false,
          draftNickname: typedMore ? state.draftNickname : '',
          lastSavedNickname: nickname,
          nicknameError: null,
        ),
      );
      event.onSaved();
    } on Exception catch (error) {
      debugPrint('P05 addChild failed: $error');
      emit(
        state.copyWith(
          saveInProgress: false,
          nicknameError: 'Something went wrong \u2014 try again',
        ),
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
