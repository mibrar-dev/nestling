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

  /// `£5.00`, `5`, `5.5` → pence. Anything else → null.
  static int? _parsePence(String raw) {
    final cleaned = raw.replaceAll(RegExp('[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null) return null;
    return (value * 100).round();
  }

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
    final note = _note.text.trim();
    widget.onSubmit(
      pence,
      note.isEmpty ? (_isAdd ? 'Added money' : 'Something else') : note,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final error = _error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NestTextField(
          label: 'Amount',
          hintText: '£0.00',
          controller: _amount,
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
        if (error != null) ...<Widget>[
          const SizedBox(height: NestSpacing.s3),
          Text(
            error,
            style: NestType.caption(color: tokens.danger),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: NestSpacing.s4),
        NestButton(label: _ctaLabel, onPressed: _submit),
      ],
    );
  }
}
