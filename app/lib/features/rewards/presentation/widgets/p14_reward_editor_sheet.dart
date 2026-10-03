import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_meta.dart';

/// Create/edit form for one reward, shown in the P14 bottom sheet.
///
/// There is no `/rewards/editor` route, so this lives in the feature's
/// widgets. [reward] is null for the `+ New reward` case (defaults: price 50,
/// `Needs my OK` on, `gift` icon); otherwise the sheet opens prefilled and
/// also offers `Delete`.
///
/// The sheet reports intent through callbacks and pops itself — the view owns
/// the BLoC. [onSave] is awaited: while it is in flight Save is disabled, and
/// if it throws the sheet stays open with an inline danger caption above Save
/// so the typed name, price and switch are not lost (plan §4, P14-B03).
/// `Delete` needs no route back: the first tap arms it and the second
/// confirms, so a destructive write can never be one stray tap away.
class RewardEditorSheet extends StatefulWidget {
  const RewardEditorSheet({
    required this.onSave,
    required this.onDelete,
    this.reward,
    super.key,
  });

  final Reward? reward;

  /// Runs the Save write and completes when it resolves; throwing keeps the
  /// sheet open and paints [RewardCopy.saveError] above Save.
  final Future<void> Function(Reward edited) onSave;

  /// Runs the confirmed Delete write; same contract as [onSave].
  final Future<void> Function() onDelete;

  /// Price granularity and floor (coins). UK coin steps of 5 reproduce the
  /// 50/60/80/90/100/150 seeds.
  static const int step = 5;
  static const int minPrice = 5;
  static const int defaultPrice = 50;

  @override
  State<RewardEditorSheet> createState() => _RewardEditorSheetState();
}

class _RewardEditorSheetState extends State<RewardEditorSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.reward?.title ?? '',
  );
  late int _price = widget.reward?.coinPrice ?? RewardEditorSheet.defaultPrice;
  late bool _needsOk = widget.reward?.needsOk ?? true;
  bool _confirmingDelete = false;
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _submit() async {
    final title = _name.text.trim();
    if (title.isEmpty || _saving) return;
    final existing = widget.reward;
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(
        Reward(
          // An empty id is how the repository recognises a create
          // (`rewards_repository_impl.dart` stamps `reward-{ms}`).
          id: existing?.id ?? '',
          title: title,
          detail: '$_price coins',
          icon: existing?.icon ?? 'gift',
          coinPrice: _price,
          needsOk: _needsOk,
        ),
      );
      if (!mounted) return;
      _close();
    } on Object catch (error) {
      if (!mounted) return;
      // Plan §4: keep the sheet open and show the error above Save — the
      // typed input stays on screen and the parent can retry.
      setState(() {
        _saving = false;
        _errorText = RewardCopy.saveError(error);
      });
    }
  }

  Future<void> _delete() async {
    if (!_confirmingDelete) {
      setState(() => _confirmingDelete = true);
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.onDelete();
      if (!mounted) return;
      _close();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _confirmingDelete = false;
        _errorText = RewardCopy.deleteError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // `showNestBottomSheet` positions the sheet at the screen bottom and
    // never reads `MediaQuery.viewInsets`, so on iOS — where the keyboard
    // floats over the Flutter view instead of resizing it — Save, Cancel and
    // Delete end up behind it (P14-B01). Padding the form by the inset lifts
    // the whole sheet above the keyboard, and capping it at the space that
    // is left keeps it inside the modal's own max height so the body scrolls
    // when there is not enough room (P14-B01).
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        // `NestBottomSheet` hands its body the *whole* column budget, so the
        // form reserves the sheet's own chrome itself. Without this the form
        // pushes that Column past its cap and Flutter reports a `RenderFlex`
        // overflow, and — worse — the controls that end up "overflowing" are
        // the ones a parent is trying to tap.
        final titleStyle = NestType.h3(color: context.nest.ink);
        final chrome =
            NestSpacing.s2 + // sheet top pad
            NestSpacing.gap5 + // grabber
            NestSpacing.s3 + // grabber gap
            (titleStyle.fontSize ?? 0) * (titleStyle.height ?? 1) + // title
            NestSpacing.s2 + // title gap
            NestDevice.homeH +
            NestSpacing.s4; // sheet bottom pad
        final screen = MediaQuery.sizeOf(context).height;
        // No keyboard: the resting 92 % cap — identical to `showNestBottomSheet`
        // and to the design. Keyboard up: the whole screen, because the inset
        // is trailing space inside the sheet (the `Padding` below) and the
        // sheet is bottom-anchored; capping it any lower would push Save,
        // Cancel and Delete back under the keyboard.
        final available = math
            .max(0, (keyboard > 0 ? screen : screen * 0.92) - chrome - keyboard)
            .toDouble();
        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: available),
            // Bounded above, so the form shrink-wraps as before and only
            // becomes a scroll view when the keyboard leaves too little room.
            child: SingleChildScrollView(child: _form()),
          ),
        );
      },
    );
  }

  Widget _form() {
    final tokens = context.nest;
    final editing = widget.reward != null;
    final canSave = _name.text.trim().isNotEmpty && !_saving;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NestTextField(
          key: const ValueKey('p14_name_field'),
          label: RewardCopy.nameLabel,
          controller: _name,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpacing.s4),
        Text(
          RewardCopy.priceLabel,
          style: NestType.fieldLabel(color: tokens.ink2),
        ),
        const SizedBox(height: NestSpacing.gap6),
        NestStepper(
          valueText: '$_price coins',
          decreaseSemanticLabel: RewardCopy.decreasePrice,
          increaseSemanticLabel: RewardCopy.increasePrice,
          onDecrease: _price > RewardEditorSheet.minPrice
              ? () => setState(() => _price -= RewardEditorSheet.step)
              : null,
          onIncrease: () => setState(() => _price += RewardEditorSheet.step),
        ),
        const SizedBox(height: NestSpacing.gap6),
        Text(
          RewardCopy.payoutHint(_price),
          style: NestType.caption(color: tokens.ink2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: NestSpacing.s4),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  RewardCopy.needsOkLabel,
                  style: NestType.fieldLabel(color: tokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              NestToggle(
                value: _needsOk,
                semanticLabel: RewardCopy.needsOkLabel,
                onChanged: (next) => setState(() => _needsOk = next),
              ),
            ],
          ),
        ),
        if (_errorText != null) ...<Widget>[
          const SizedBox(height: NestSpacing.s2),
          Text(_errorText!, style: NestType.fieldLabel(color: tokens.danger)),
        ],
        const SizedBox(height: NestSpacing.s4),
        NestButton(
          key: const ValueKey('p14_save'),
          label: RewardCopy.save,
          onPressed: canSave ? _submit : null,
        ),
        const SizedBox(height: NestSpacing.s2),
        NestButton(
          key: const ValueKey('p14_cancel'),
          label: RewardCopy.cancel,
          variant: NestButtonVariant.ghost,
          onPressed: _close,
        ),
        if (editing) ...<Widget>[
          const SizedBox(height: NestSpacing.s2),
          NestButton(
            key: const ValueKey('p14_delete'),
            label: _confirmingDelete
                ? RewardCopy.confirmDelete
                : RewardCopy.delete,
            variant: NestButtonVariant.dangerGhost,
            onPressed: _delete,
          ),
        ],
      ],
    );
  }
}
