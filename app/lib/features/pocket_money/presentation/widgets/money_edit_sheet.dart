import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Which ledger row the sheet writes.
enum MoneyEditSheetMode { addMoney, recordSpending }

/// P12 add-money / record-spending sheet (`/money` row buttons).
///
/// Pounds → pence parsing and the inline validation live here (UI only);
/// the caller writes the row through its bloc event. Copy follows the
/// design's own wording: labels `Amount` / `Note`, hints `£0.00` and
/// `e.g. Birthday money`.
class MoneyEditSheet extends StatefulWidget {
  const MoneyEditSheet.addMoney({required this.onSubmit, super.key})
    : mode = MoneyEditSheetMode.addMoney;

  const MoneyEditSheet.recordSpending({required this.onSubmit, super.key})
    : mode = MoneyEditSheetMode.recordSpending;

  final MoneyEditSheetMode mode;

  /// Called with validated pence + the note, then the sheet pops itself.
  final void Function(int amountPence, String note) onSubmit;

  @override
  State<MoneyEditSheet> createState() => _MoneyEditSheetState();
}

class _MoneyEditSheetState extends State<MoneyEditSheet> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _isAdd => widget.mode == MoneyEditSheetMode.addMoney;

  String get _ctaLabel => _isAdd ? 'Add money' : 'Record spending';

  /// One ledger row may not exceed £1,000,000.00 (P12-BUG-01: an unbounded
  /// numpad mashtroke was stored as int64 max and printed as
  /// `+£92233720368547760.00`, overflowing the history row).
  static const int maxPence = 100000000;

  /// Pounds → pence in **integer** maths, validating instead of stripping.
  ///
  /// P12-BUG-01/02/03 (all three reproducers are in `p12_bugs_test.dart`):
  ///
  /// * the old `replaceAll(RegExp('[^0-9.]'), '')` deleted any separator, so
  ///   `1,50` recorded £150.00 (100×), `-5` recorded +£5.00 and `5 5` recorded
  ///   £5.50 — a silent rewrite of the amount the parent typed;
  /// * `(value * 100).round()` lost half a penny (`1.005` → 100p, because
  ///   `1.005 * 100 == 100.49999999999999`) and overflowed to int64 max.
  ///
  /// Accepted: an optional leading `£`, optional spaces, an optional whole
  /// part, and **at most two** decimals (`5.00`, `£5`, `.5`, `0.01`,
  /// `1.15`, `999.99`). Everything else returns null and never reaches the
  /// bloc. The whole part is capped at 9 digits so `int.parse` cannot
  /// overflow before [maxPence] is applied.
  static int? _parsePence(String raw) {
    final match = _amountPattern.firstMatch(raw);
    if (match == null) return null;
    final cleaned = raw.replaceAll(_strip, '');
    final dot = cleaned.indexOf('.');
    final whole = dot < 0 ? cleaned : cleaned.substring(0, dot);
    final fraction = dot < 0 ? '' : cleaned.substring(dot + 1);
    return (whole.isEmpty ? 0 : int.parse(whole)) * 100 +
        int.parse(fraction.padRight(2, '0'));
  }

  static final RegExp _amountPattern = RegExp(
    r'^\s*£?\s*(?:\d{1,9}(?:\.\d{1,2})?|\.\d{1,2})\s*$',
  );

  /// Leading `£` and the spaces around it are the only non-digit characters
  /// the pattern lets through, so exactly those are removed before parsing.
  static final RegExp _strip = RegExp(r'[£\s]');

  void _submit() {
    final pence = _parsePence(_amount.text);
    if (pence == null) {
      setState(() => _error = 'Enter an amount like £1.00');
      return;
    }
    if (pence <= 0) {
      setState(() => _error = 'Enter an amount above 0');
      return;
    }
    if (pence > maxPence) {
      setState(() => _error = 'Enter an amount up to £1,000,000.00');
      return;
    }
    final note = _note.text.trim();
    widget.onSubmit(
      pence,
      note.isEmpty ? (_isAdd ? 'Added money' : 'Something else') : note,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Finding 2 (iteration 2 review): the rejection belongs to the
        // shared `NestTextField.errorText`, which paints the 2 px danger
        // border on the field itself and a gutter-aligned error row below
        // **it** — announced through a live region, which is what finding 5
        // needed. The hand-rolled copy used to render under the Note field,
        // spatially detached from the input it is about (and it bypassed the
        // design system entirely). Same three strings, still cleared on
        // change.
        NestTextField(
          label: 'Amount',
          hintText: '£0.00',
          controller: _amount,
          errorText: _error,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: NestSpacing.s4),
        NestTextField(
          label: 'Note',
          hintText: 'e.g. Birthday money',
          controller: _note,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: NestSpacing.s4),
        NestButton(label: _ctaLabel, onPressed: _submit),
      ],
    );
  }
}
