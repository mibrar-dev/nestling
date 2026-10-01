import 'package:equatable/equatable.dart';

// The P17 grown-ups-only challenge: a small multiplication whose answer is
// typed on the keypad ("seven times six" → 42). Deterministic per day so
// tests and screenshots are stable.
class ParentalGateChallenge extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.a,
    required this.b,
  });

  final String id;
  final String title;
  final String detail;
  final int a;
  final int b;

  int get answer => a * b;

  /// "Type the answer in numbers: seven times six".
  String get question => '${_word(a)} times ${_word(b)}';

  bool verify(int value) => value == answer;

  static String _word(int n) {
    const words = <int, String>{
      2: 'two',
      3: 'three',
      4: 'four',
      5: 'five',
      6: 'six',
      7: 'seven',
      8: 'eight',
      9: 'nine',
    };
    return words[n] ?? '$n';
  }

  @override
  List<Object?> get props => <Object?>[id, title, detail, a, b];
}
