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
/// the BLoC. `Delete` needs no route back: the first tap arms it and the
/// second confirms, so a destructive write can never be one stray tap away.
class RewardEditorSheet extends StatefulWidget {
  const RewardEditorSheet({
    required this.onSave,
    required this.onDelete,
    this.reward,
    super.key,
  });

  final Reward? reward;
  final ValueChanged<Reward> onSave;
  final VoidCallback onDelete;

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

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _submit() {
    final title = _name.text.trim();
    if (title.isEmpty) return;
    final existing = widget.reward;
    widget.onSave(
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
    _close();
  }

  void _delete() {
    if (!_confirmingDelete) {
      setState(() => _confirmingDelete = true);
      return;
    }
    widget.onDelete();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final editing = widget.reward != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NestTextField(
          key: const ValueKey('p14_name_field'),
          label: 'Name',
          controller: _name,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpacing.s4),
        Text('Price in coins', style: NestType.fieldLabel(color: tokens.ink2)),
        const SizedBox(height: 6),
        NestStepper(
          valueText: '$_price coins',
          decreaseSemanticLabel: 'Decrease price',
          increaseSemanticLabel: 'Increase price',
          onDecrease: _price > RewardEditorSheet.minPrice
              ? () => setState(() => _price -= RewardEditorSheet.step)
              : null,
          onIncrease: () => setState(() => _price += RewardEditorSheet.step),
        ),
        const SizedBox(height: 6),
        Text(
          '= $_price p at payout',
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
        const SizedBox(height: NestSpacing.s4),
        NestButton(
          key: const ValueKey('p14_save'),
          label: RewardCopy.save,
          onPressed: _name.text.trim().isEmpty ? null : _submit,
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
