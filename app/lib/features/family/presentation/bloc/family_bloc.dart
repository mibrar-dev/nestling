import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/core/design_system/components/nest_avatar.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';

/// Maps a stored `avatar_colour` token to its design-system colour.
NestAvatarColor avatarColourFor(String raw) => switch (raw) {
  'lilac' => NestAvatarColor.lilac,
  'peach' => NestAvatarColor.peach,
  'sky' => NestAvatarColor.sky,
  'leaf' => NestAvatarColor.leaf,
  'coin' => NestAvatarColor.coin,
  _ => NestAvatarColor.neutral,
};

/// Seed rows store bands with a hyphen (`7-9`); the design shows an en-dash
/// (`7–9`). `13+` has no hyphen and passes through unchanged.
String displayAgeBand(String band) => band.replaceAll('-', '\u2013');

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  new({required this._repository}) : super(const FamilyState()) {
    on<FamilyLoadRequested>(_onLoadRequested);
    on<FamilyChildrenRequested>(_onChildrenRequested);
    on<FamilyDraftChanged>(_onDraftChanged);
    on<FamilyAddChildRequested>(_onAddChildRequested);
  }

  final FamilyRepository _repository;

  /// Single subscription covering both streams (RULES §4: blocs subscribe
  /// with `emit.forEach`). A second `emit.forEach` in another handler would
  /// never run while this one is open, so the children roster rides along
  /// here instead of in a separate subscription; `FamilyChildrenRequested`
  /// exists for focused tests and stays undispatched in production.
  Future<void> _onLoadRequested(
    FamilyLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(status: FamilyStatus.loading));
    await emit.forEach<List<dynamic>>(
      combineLatest2(_repository.watchItems(), _repository.watchChildren()),
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

  Future<void> _onChildrenRequested(
    FamilyChildrenRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(status: FamilyStatus.loading));
    await emit.forEach<List<FamilyChild>>(
      _repository.watchChildren(),
      onData: (children) =>
          state.copyWith(status: FamilyStatus.loaded, children: children),
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
      // The roster stream emits the new card on its own; only the nickname
      // draft clears (age band and avatar colour stay for the next child).
      emit(
        state.copyWith(
          saveInProgress: false,
          draftNickname: '',
          nicknameError: null,
        ),
      );
      event.onSaved();
    } on Exception catch (_) {
      emit(
        state.copyWith(
          saveInProgress: false,
          nicknameError: 'Something went wrong \u2014 try again',
        ),
      );
    }
  }
}
