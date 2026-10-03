import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';
import 'package:nestling/features/family/presentation/widgets/add_child_form_card.dart';
import 'package:nestling/features/family/presentation/widgets/kid_card_grid.dart';
import 'package:nestling/features/pocket_money/pocket_money_routes.dart';
import 'package:nestling/features/privacy_consent/privacy_consent_routes.dart';

/// P05 · Add children (`/add-children`, parent mode, feature `family`).
///
/// Real roster from [FamilyBloc] (Drift via the family repository); the form
/// draft lives in the bloc, the [TextEditingController]/[FocusNode] live here
/// so the bottom CTA can read the field and restore focus after a save.
class AddChildrenView extends StatefulWidget {
  const new({super.key});

  @override
  State<AddChildrenView> createState() => _AddChildrenViewState();
}

class _AddChildrenViewState extends State<AddChildrenView> {
  late final TextEditingController _nicknameController =
      TextEditingController();
  late final FocusNode _nicknameFocus = FocusNode();

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  void _onAddAnother() {
    context.read<FamilyBloc>().add(
      FamilyAddChildRequested(
        onSaved: () {
          if (!mounted) return;
          _nicknameFocus.requestFocus();
        },
      ),
    );
  }

  void _onContinue() {
    void go() {
      if (!mounted) return;
      context.go(PocketMoneyRoutePaths.setup);
    }

    // The bloc draft is the source of truth (every keystroke forwards here);
    // the controller below is only the field's text surface.
    if (context.read<FamilyBloc>().state.draftNickname.trim().isNotEmpty) {
      context.read<FamilyBloc>().add(FamilyAddChildRequested(onSaved: go));
    } else {
      go();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: BlocListener<FamilyBloc, FamilyState>(
        // P05-BUG-5: mirror the cleared draft into the field only while the
        // field still holds the saved nickname — typing that started
        // mid-save belongs to the next child and must survive.
        listenWhen: (previous, current) =>
            previous.saveInProgress &&
            !current.saveInProgress &&
            current.nicknameError == null,
        listener: (context, state) {
          if (_nicknameController.text.trim() ==
              (state.lastSavedNickname ?? '')) {
            _nicknameController.clear();
          }
        },
        child: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            final loaded = state.status == FamilyStatus.loaded;
            return Column(
              children: [
                const NestStatusBar(),
                // The funnel navigates with `go` (P01 precedent): `push`
                // from a top-level route is a silent no-op in this router
                // setup, and the funnel keeps a depth-1 stack so `pop`
                // could not return to P04 anyway.
                NestNavBar(
                  compact: true,
                  onBack: () => context.go(PrivacyConsentRoutePaths.privacy),
                ),
                Expanded(
                  child: _Body(
                    state: state,
                    nicknameController: _nicknameController,
                    nicknameFocus: _nicknameFocus,
                    onRetry: () => context.read<FamilyBloc>().add(
                      const FamilyLoadRequested(),
                    ),
                  ),
                ),
                if (loaded)
                  NestBottomCta(
                    caption: 'You can change any of this later in Family.',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NestButton(
                          key: const Key('addAnotherButton'),
                          label: 'Add another child',
                          variant: NestButtonVariant.secondary,
                          leading: const NestIcon(NestIcons.plus),
                          minHeight: 48,
                          onPressed: state.saveInProgress
                              ? null
                              : _onAddAnother,
                        ),
                        const SizedBox(height: NestSpacing.s2),
                        NestButton(
                          key: const Key('continueButton'),
                          label: 'Continue',
                          loading: state.saveInProgress,
                          onPressed: state.saveInProgress ? null : _onContinue,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.nicknameController,
    required this.nicknameFocus,
    required this.onRetry,
  });

  final FamilyState state;
  final TextEditingController nicknameController;
  final FocusNode nicknameFocus;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case FamilyStatus.initial:
      case FamilyStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case FamilyStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ?? 'Something went wrong',
                  style: NestType.body(color: context.nest.ink2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NestSpacing.s4),
                NestButton(
                  label: 'Try again',
                  variant: NestButtonVariant.secondary,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        );
      case FamilyStatus.loaded:
        final tokens = context.nest;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.padSide,
            0,
            NestSpacing.padSide,
            NestSpacing.s8,
          ),
          children: [
            Semantics(
              header: true,
              // `.h1 { text-wrap: balance }` in components.css, so the
              // heading renders through `NestBalancedText` (same copy, style
              // and maxLines; the break moves earlier so no line orphans a
              // single word).
              child: NestBalancedText(
                'Who\u2019s in your nest?',
                style: NestType.h1(color: tokens.ink),
                textAlign: TextAlign.left,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: NestSpacing.s2),
            Text(
              'Nicknames only \u2014 no photos, no email.',
              style: NestType.body(color: tokens.ink2),
            ),
            const SizedBox(height: NestSpacing.gap14),
            if (state.children.isNotEmpty)
              KidCardGrid(children: state.children)
            else
              const SizedBox.shrink(),
            const SizedBox(height: NestSpacing.s3),
            AddChildFormCard(
              nicknameController: nicknameController,
              nicknameFocus: nicknameFocus,
              draftAgeBand: state.draftAgeBand,
              draftAvatarColour: state.draftAvatarColour,
              nicknameError: state.nicknameError,
              onNicknameChanged: (value) => context.read<FamilyBloc>().add(
                FamilyDraftChanged(nickname: value),
              ),
              onAgeBandSelected: (band) => context.read<FamilyBloc>().add(
                FamilyDraftChanged(ageBand: band),
              ),
              onAvatarColourSelected: (colour) => context
                  .read<FamilyBloc>()
                  .add(FamilyDraftChanged(avatarColour: colour)),
            ),
          ],
        );
    }
  }
}
