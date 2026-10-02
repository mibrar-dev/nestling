import 'package:equatable/equatable.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';

enum FamilyStatus { initial, loading, loaded, failure }

/// Sentinel default for [FamilyState.copyWith]'s `nicknameError`: passing
/// `null` explicitly clears the error, omitting it keeps the current value.
const _keepNicknameError = Object();

/// Same pattern for `lastSavedNickname`, which copyWith would otherwise keep
/// forever once set.
const _keepLastSavedNickname = Object();

final class FamilyState extends Equatable {
  const new({
    this.status = FamilyStatus.initial,
    this.items = const <FamilyMember>[],
    this.children = const <FamilyChild>[],
    this.draftNickname = '',
    this.draftAgeBand = '7-9',
    this.draftAvatarColour = 'peach',
    this.nicknameError,
    this.saveInProgress = false,
    this.lastSavedNickname,
    this.errorMessage,
  });

  final FamilyStatus status;
  final List<FamilyMember> items;
  final List<FamilyChild> children;

  /// Add-child form draft (P05). The design defaults are the 7–9 age chip
  /// and the peach swatch.
  final String draftNickname;
  final String draftAgeBand;
  final String draftAvatarColour;
  final String? nicknameError;
  final bool saveInProgress;

  /// Nickname written by the most recent successful save. The view clears
  /// its field only while the field still holds this value, so typing that
  /// started mid-save is never wiped (P05-BUG-5).
  final String? lastSavedNickname;

  final String? errorMessage;

  FamilyState copyWith({
    FamilyStatus? status,
    List<FamilyMember>? items,
    List<FamilyChild>? children,
    String? draftNickname,
    String? draftAgeBand,
    String? draftAvatarColour,
    Object? nicknameError = _keepNicknameError,
    bool? saveInProgress,
    Object? lastSavedNickname = _keepLastSavedNickname,
    String? errorMessage,
  }) {
    return FamilyState(
      status: status ?? this.status,
      items: items ?? this.items,
      children: children ?? this.children,
      draftNickname: draftNickname ?? this.draftNickname,
      draftAgeBand: draftAgeBand ?? this.draftAgeBand,
      draftAvatarColour: draftAvatarColour ?? this.draftAvatarColour,
      nicknameError: identical(nicknameError, _keepNicknameError)
          ? this.nicknameError
          : nicknameError as String?,
      saveInProgress: saveInProgress ?? this.saveInProgress,
      lastSavedNickname: identical(lastSavedNickname, _keepLastSavedNickname)
          ? this.lastSavedNickname
          : lastSavedNickname as String?,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    children,
    draftNickname,
    draftAgeBand,
    draftAvatarColour,
    nicknameError,
    saveInProgress,
    lastSavedNickname,
    errorMessage,
  ];
}
