import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
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
    on<FamilyRemoveChildRequested>(_onRemoveChildRequested);
  }

  final FamilyRepository _repository;

  /// The route dispatches exactly one load event; its single `emit.forEach`
  /// subscription covers the members, the children roster AND the P15
  /// selected-child profile (RULES §4: blocs subscribe with `emit.forEach`
  /// — never re-add load events). The profile stream nests inside the same
  /// combine so there is still exactly one subscription.
  Future<void> _onLoadRequested(
    FamilyLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(status: FamilyStatus.loading));
    await emit.forEach<List<dynamic>>(
      combineLatest2(
        combineLatest2(_repository.watchItems(), _repository.watchChildren()),
        _repository.watchProfile(),
      ).transform(_closeOnError),
      onData: (parts) {
        final roster = parts[0] as List<dynamic>;
        return state.copyWith(
          status: FamilyStatus.loaded,
          items: (roster[0] as List<FamilyMember>).toList(),
          children: (roster[1] as List<FamilyChild>).toList(),
          profile: parts[1] as ChildProfile?,
        );
      },
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

  /// P15 remove flow: the delete goes through the repository; the
  /// `watchProfile`/`watchChildren` streams re-emit on their own (selection
  /// falls through to the next child in creation order, or null). No new
  /// status values — failures surface as an error message on the loaded
  /// state and the view shows them via `NestToast`.
  Future<void> _onRemoveChildRequested(
    FamilyRemoveChildRequested event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      await _repository.removeChild(event.childId);
    } on Exception catch (error) {
      debugPrint('P15 removeChild failed: $error');
      emit(state.copyWith(errorMessage: error.toString()));
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
