import 'package:equatable/equatable.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';

enum ParentalGateStatus { initial, loading, loaded, failure }

final class ParentalGateState extends Equatable {
  const new({
    this.status = ParentalGateStatus.initial,
    this.items = const <ParentalGateChallenge>[],
    this.errorMessage,
    this.entered = '',
    this.attempts = 0,
    this.unlocked = false,
  });

  final ParentalGateStatus status;
  final List<ParentalGateChallenge> items;
  final String? errorMessage;

  /// Digits typed on the keypad so far (display-only boxes mirror this).
  final String entered;

  /// Wrong full-length submissions this session (kind retry, no red styling).
  final int attempts;

  /// One-shot: true once the correct answer is typed. The view navigates
  /// then adds the unlock-acknowledged event to reset it.
  final bool unlocked;

  /// The live challenge, or null when the gate is disabled (`items` empty).
  ParentalGateChallenge? get challenge => items.isEmpty ? null : items.first;

  /// Digits the answer needs (design shows 2 boxes for 7×6=42).
  int get expectedLength => challenge?.answer.toString().length ?? 0;

  /// True once every box is filled. Guarded by `expectedLength > 0` so a
  /// disabled gate (`[]`, length 0, entry '') never reads as complete.
  bool get isComplete => expectedLength > 0 && entered.length == expectedLength;

  ParentalGateState copyWith({
    ParentalGateStatus? status,
    List<ParentalGateChallenge>? items,
    String? errorMessage,
    String? entered,
    int? attempts,
    bool? unlocked,
    bool clearError = false,
  }) {
    return ParentalGateState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      entered: entered ?? this.entered,
      attempts: attempts ?? this.attempts,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    errorMessage,
    entered,
    attempts,
    unlocked,
  ];
}
